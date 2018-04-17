#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "Check_Latest_PSD"
#include <Extract Contours As Waves>
#include <All IP Procedures>
#include "circular_image_integration"
#include "BkgSubst"
#include "CT_ColorTable"


//*********************************************************
//Functions for mapping scans from .h5 archive
//*********************************************************





//*********************************************************
Function ExtractScansH5(HDF5_path_name, slab, num)

	//TODO
	//Extracts all the slices from .h5 archive into binary files in order to make mapping faster.

	variable num
	String HDF5_path_name
	Wave slab

	variable i
	i = 0
		do
			slab[0][0]=i
			HDPY_open_slice(HDF5_path_name,slab, "tmp_slice_in")
			sortit(tmp_slice_in,  "tmp_slice_out")

			Duplicate tmp_slice_out, tmp //I don't know why this works only this way
			Save/C/P=home tmp as "integrated_" +Num2Str(i)+".ibw"
			i+=1
		while(i<num)
	
	KillWaves tmp_slice_out, tmp_slice_in, tmp 
End





//*********************************************************
Function MakeSumH5(HDF5_path_name, slab, min_num, max_num)

	//Sums all the scans from .h5 archive into one wave image. The image is used then to look up for peaks that need to be mapped.

	variable min_num, max_num
	String HDF5_path_name
	Wave slab

	variable i
	i = min_num

	// make a sum template (data type unsigned long)
	Make/O/N=(2000,720)/D SumWave
	SumWave[][]=0

		do
			slab[0][0]=i
			HDPY_open_slice(HDF5_path_name,slab, "tmp_slice_in")
			sortit(tmp_slice_in,  "tmp_slice_out")
			Duplicate tmp_slice_out, tmp //I don't know why this works only this way
			tmp=tmp[p][q]==-10 ? Nan : tmp[p][q]
			tmp = tmp/100000
			SumWave+= tmp
			print i
			i+=1
		while(i<max_num)
	
	KillWaves tmp_slice_out, tmp_slice_in, tmp
End





//*********************************************************
Function MakeSimpleMapH5(HDF5_path_name, slab, n0, m0, x1, x2, y1, y2)

	//Picks up a small segment (defined by its coordinates x1,x2,y1,y2) from all the integrated scans 
	//in the experiment, counts mean intensity and assembles intensities from all the scans into one picture. The picture consists of total 
	//n0*m0 segments. n0 and m0 are the numbers of areas of a sample scanned along and across
	//during the experiment.
	//Scans are extracted from an .h5 archive as slices

	variable  x1, x2, y1, y2, n0, m0
	String HDF5_path_name
	Wave slab


	variable i, x, y, x_i, y_i, n, m, end_num, total_intensity, mean_intensity
	i = 0
	end_num=n0*m0
	x = x2-x1
	y = y2-y1


	// make a map template (data type unsigned long)
	Make/O/N=(m0,n0)/D Map
	Map[][]=0
	//m0 -  rows in scans array
	//n0 - columns in scans array
	//x - segment size x
	//y - segment size y
	do
		slab[0][0]=i
		HDPY_open_slice(HDF5_path_name,slab, "tmp_slice_in")
		sortit(tmp_slice_in,  "tmp_slice_out")
		Duplicate tmp_slice_out, tmp //I don't know why this works only this way
		
		m = mod(i, m0)
		n = (i-m)/m0

		//picking up a segment and unifying its intensity
		
		//setting iterators
		x_i=x1
		y_i=y1
		
		//default intensity valiues
		total_intensity = 0
		mean_intensity = 0
		
		do 
				do 
					if (tmp[x_i][y_i] !=-10)
					total_intensity +=tmp[x_i][y_i]
					endif
					y_i+=1
				while (y_i<=y2)
	
			x_i+=1
		while (x_i<=x2)
		
		mean_intensity = total_intensity/(x*y)

		//inserting segment into the map	
		
		Map[m][n]=mean_intensity
		print i
		i+=1
	while(i<end_num)
	
	KillWaves tmp_slice_out, tmp_slice_in, tmp
End




//*********************************************************
Function MakeMapH5(HDF5_path_name, slab, n0, m0, x1, x2, y1, y2)

	//Old version of mapping function

	//Picks up a small segment (defined by its coordinates x1,x2,y1,y2) from all the integrated scans 
	//in the experiment and concatenates all the segments into one picture which consists of total 
	//n0*m0 segments. n0 and m0 are the numbers of areas of a sample scanned along and across
	//during the experiment.
	//Scans are extracted from an .h5 archive as slices

	variable  x1, x2, y1, y2, n0, m0
	String HDF5_path_name
	Wave slab


	variable i, x, y, n, m, end_num
	String tmp_slice_name
 	tmp_slice_name = "tmp_slice_out"
	i = 0
	end_num=n0*m0
	x = x2-x1
	y = y2-y1


	// make a map template (data type unsigned long)
	Make/O/N=(m0*x,n0*y)/I/U Map
	Map[][]=0
	//m0 -  rows in scans array
	//n0 - columns in scans array
	//x - segment size x
	//y - segment size y
	do
		slab[0][0]=i
		HDPY_open_slice(HDF5_path_name,slab, "tmp_slice_in")
		sortit(tmp_slice_in,  "tmp_slice_out")
	
		m = mod(i, m0)
		n = (i-m)/m0

		//carving the segment out
		//x
		DeletePoints x2,2000-x2, tmp_slice_out
		DeletePoints 0,x1, tmp_slice_out
		//y
		DeletePoints/M=1 y2,720-y2, tmp_slice_out
		DeletePoints/M=1 0,y1,tmp_slice_out


		//adjusting to future position on the map
		//x
		InsertPoints 0,m*x,$tmp_slice_name
		InsertPoints (m+1)*x,(m0-m-1)*x,tmp_slice_out
		//y
		InsertPoints/M=1 0,n*y, tmp_slice_out
		InsertPoints/M=1 (n+1)*y,(n0-n-1)*y, tmp_slice_out

		//inserting segment into the map	
		Duplicate tmp_slice_out, tmp //I don't know why this works only this way
		Map = Map + tmp
		print i
		i+=1
	while(i<end_num)
	
	KillWaves tmp_slice_out, tmp_slice_in, tmp
End

