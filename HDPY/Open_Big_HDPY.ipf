//*********************************************************
//Some magic with opening HDPY (not made by me)
//*********************************************************

#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "Check_Latest_PSD"
#include <Extract Contours As Waves>
#include <All IP Procedures>
#include "circular_image_integration"
#include "BkgSubst"
#include "CT_ColorTable"


Function HDPY_get_dimensions(HDF5name,dim)
	string HDF5name
	variable dim
	STRUCT HDF5DataInfo di	
	InitHDF5DataInfo(di)	
	Variable fileID
	HDF5OpenFile /R fileID as HDF5name
	HDF5DatasetInfo(fileID, "/data/data", 0, di)
	HDF5CloseFile fileID
	return di.dims[dim]
End

Function HDPY_get_num_dimensions(HDF5name)
	string HDF5name
	STRUCT HDF5DataInfo di	
	InitHDF5DataInfo(di)	
	Variable fileID
	HDF5OpenFile /R fileID as HDF5name
	HDF5DatasetInfo(fileID, "/data/data", 0, di)
	HDF5CloseFile fileID
	return di.ndims
End

Function/s HDPY_open_slice(HDF5name,slab,SliceName)
	string HDF5name
	Wave slab
	String SliceName
	
	variable fileID
	HDF5OpenFile /R fileID as HDF5name
	HDF5LoadData /N=$SliceName /O /SLAB=slab fileID, "/data/data"
	HDF5CloseFile fileID		
	return SliceName
end

Function HDPYP_setup_IGORfolders()
	NewDataFolder /O  root:HDPYP
end


Function HDPYP_gen_slap(HDF5name,semislab)
	string HDF5name
	wave semislab
	variable i

	variable/G root:HDPYP:ndims = HDPY_get_num_dimensions(HDF5name)
	NVAR ndims = root:HDPYP:ndims
	Make/O/N=(ndims) root:HDPYP:dims	
	wave slap_dims = root:HDPYP:dims

	for (i=0;i<ndims;i+=1)
		slap_dims[i] = HDPY_get_dimensions(HDF5name,i)
	endfor
End

Function/s HDPYP_open_Frameblock(HDF5name,slab,FrameName)
	string HDF5name
	wave slab
	String FrameName
	variable i,j,ch
		
	wave dummy = $HDPY_open_slice(HDF5name,slab,FrameName+"_sl")

		make/N=(slab[1][3] - slab[1][0], slab[2][3] - slab [2][0], slab[2][3] - slab [2][0]) $FrameName
		Wave Frame = $FrameName
	
	for (i=0; i < (slab[0][3] - slab[0][0]); i+=1)
		for (i=0; i < (slab[1][3] - slab[1][0]); i+=1)
			for (j=0; j < (slab[2][3] - slab [2][0]); j+=1)
				Frame[i][j] = dummy[0][i][j]	
			endfor
		endfor
	endfor
	
	Killwaves/Z dummy
	return FrameName
End

Function sortit(test,frameout)
	wave test
	string frameout
	variable i,j,l

	make/O/N=(2000,720) $frameout
	wave frame = $frameout 
	
	//for (l=0; l < 1; l+=1)
		for (i=0; i < 720; i+=1)
			for (j=0; j < 2000; j+=1)
				frame[j][i]= test[0][i][j]	
			endfor
		endfor
	//endfor

end

//*********************************************************
//End of magic
//*********************************************************