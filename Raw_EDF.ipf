#pragma rtGlobals=1		// Use modern global access method and strict wave access.
#include <All IP Procedures>
#include <Image Saver>


//*********************************************************
Function edfLoad(base_filename, StartNumber, EndNumber,PathNameStr)

	// EDF loader (written by Rodygin A.)
	// make the path through Misc - new path
	String base_filename,PathNameStr
	variable StartNumber, EndNumber

	variable i
	string CurrentFileName
	i=StartNumber
	Make /O/D/N=(2070,2167) waveSum


	do
		if(i<10)
			CurrentFileName=base_filename+Num2Str(0)+Num2Str(0)+Num2Str(0)+Num2Str(i)+".edf"
		endif
		
		if((i>=10) && (i<100))
			CurrentFileName=base_filename+Num2Str(0)+Num2Str(0)+Num2Str(i)+".edf"
		endif
		
		if((i>=100) && (i<1000))
			CurrentFileName=base_filename+Num2Str(0)+Num2Str(i)+".edf"
		endif
		
		if((i>=1000) && (i<10000))
			CurrentFileName=base_filename+Num2Str(i)+".edf"
		endif
		
		if(i>=10000)
			print "There are too large frame numbers here. Please, check the code"
		endif
		
		GBLoadWave/N=base/B/T={96,4}/S=1024/W=1/P=$PathNameStr CurrentFileName
		Redimension/N=(2070,2167) base0
		SetScale/I x 0.0002,0.28112,"q", base0
		Wave tmp = base0
		waveSum+=tmp
		
		i+=1
	while(i<=EndNumber)
End





//*********************************************************
Function makeMap(base_filename, StartNumber, EndNumber,PathNameStr, n0, m0, x1, x2, y1, y2)

	//Picks up a small segment (defined by its coordinates x1,x2,y1,y2) from all the integrated scans 
	//in the experiment and concatenates all the segments into one picture which consists of total 
	//n0*m0 segments. n0 and m0 are the numbers of areas of a sample scanned along and across
	//during the experiment.
	//Scans are raw EDF files, not archived.


	String base_filename,PathNameStr
	variable StartNumber, EndNumber, x1, x2, y1, y2, n0, m0
	string CurrentFileName

	variable i, x, y, n,m
	i=StartNumber
	x = x2-x1
	y = y2-y1


	// make a map template (unsigned long)
	Make/O/N=(m0*x,n0*y)/I/U Map
	//m0 -  rows in edf array
	//n0 - columns in edf array
	//x - segment size x
	//y - segment size y
	do
		if(i<10)
			CurrentFileName=base_filename+Num2Str(0)+Num2Str(0)+Num2Str(0)+Num2Str(i)+".edf"
		endif
		
		if((i>=10) && (i<100))
			CurrentFileName=base_filename+Num2Str(0)+Num2Str(0)+Num2Str(i)+".edf"
		endif
		
		if((i>=100) && (i<1000))
			CurrentFileName=base_filename+Num2Str(0)+Num2Str(i)+".edf"
		endif
		
		if((i>=1000) && (i<10000))
			CurrentFileName=base_filename+Num2Str(i)+".edf"
		endif
		
		if(i>=10000)
			print "There are too large frame numbers here. Please, check the code"
		endif
		
		GBLoadWave/N=base/B/T={96,4}/S=1024/W=1/P=$PathNameStr CurrentFileName
		Redimension/N=(2070,2167) base0
		SetScale/I x 0.0002,0.28112,"q", base0
		Wave tmp = base0

		m = mod(i, m0)
		n = (i-m)/m0

		//carving the segment out
		//x
		DeletePoints x2,2070-x2, tmp
		DeletePoints 0,x1, tmp
		//y
		DeletePoints/M=1 y2,2167-y2, tmp
		DeletePoints/M=1 0,y1, tmp


		//adjusting to map
		//x
		InsertPoints 0,m*x, tmp
		InsertPoints (m+1)*x,(m0-m-1)*x, tmp
		//y
		InsertPoints/M=1 0,n*y, tmp
		InsertPoints/M=1 (n+1)*y,(n0-n-1)*y, tmp

		//inserting segment into the map
		Map+=tmp
		
		i+=1
	while(i<=EndNumber)
End
