#pragma rtGlobals=3		// Use modern global access method and strict wave access.


function FMSKPM_Loop(loops, [delx, dely])
	variable loops
	variable delx, dely
	
	NewPath/O/Z FMPath
	
	if (ParamIsDefault(delx))
		delx = 0
	endif
	if (ParamIsDefault(dely))
		dely = 0
	endif
	
	NVAR gxpos = root:packages:trEFM:gxpos
	NVAR gypos = root:packages:trEFM:gypos
	
	Wave ScanTimes = root:Packages:trEFM:ImageScan:SKPM:ScanTimes
	NVAR SaveKeithley = root:packages:trEFM:PointScan:SKPM:SaveKeithley
	Wave SMUCurrents =  root:Packages:trEFM:ImageScan:SKPM:SMUCurrents
	
	string numstring = "0000"
	string name = "FM_" 
	string savename = "FM_0000"	
	
	variable i = 0
	
	do
		
		// Crudely mimics hitting the button several times
		GetMFPOffset("")
		Sleep/S 1
		GetMFPOffset("")
		Sleep/S 1
		GetMFPOffset("")
		Sleep/S 1
		DoUpdate 
		
		gxpos = gxpos - delx
		gypos = gypos - dely		
		
		SKPMImageScanButton("")
		
		if (i < 10)
			numstring = "000"
		elseif (i < 100)
			numstring = "00"
		else
			numstring = "0"
		endif
		savename = name + numstring + num2str(i)
		
		SaveFMLoop(savename)
		Print savename, " saved"
				
		savename = name + numstring + num2str(i) + "_time.txt"
		Save/J/O/P=FMPath/M="\r\n"/W ScanTimes as savename
		
		savename = name + numstring + num2str(i) + "_current.txt"
		if (SaveKeithley == 1)
			Save/J/O/P=FMPath/M="\r\n"/W SMUCurrents as savename
		endif
		
		i += 1
	while ( i < loops)
	
	print "Done!"
	

end


Function SaveFMLoop(name)
	String name
	
	String savDF = GetDataFolder(1)
	
	Variable Layers
		SetDataFolder root:Packages:trEFM:ImageScan:SKPM
		Layers = 2

	Wave Topography, ChargingRate, FrequencyOffset, Chi2Image, CPDImage
	Wave ScanFrameWork

	SetDataFolder root:Packages:trEFM:ImageScan
	Nvar scanpoints, scanlines

	String/g DataTypeList
	DataTypeList = "HeightTrace;UserIn0ReTrace;UserIn1ReTrace;UserIn2ReTrace"

	Make/O/N = (scanpoints, scanlines, Layers) ImageWave
	
	if(scanlines == 1)
		setscale/I y, 0, (ScanFramework[0][2]-ScanFrameWork[0][0])*1e-6, "m", ImageWave
	else
		setscale/I x, 0, abs(ScanFramework[scanlines-1][2]-ScanFrameWork[0][0])*1e-6, "m",ImageWave
		setscale/I y, 0, abs(ScanFramework[scanlines-1][1]-ScanFrameWork[0][1])*1e-6, "m",ImageWave
	endif
	
	//Test function to save multiple layer waves as a single 3D AR Image wave.	
	//these are the lines I used to test this opit	

	DataTypeList = "HeightTrace;UserIn0ReTrace"
	ImageWave[][][0] = Topography[p][q]
	ImageWave[][][1] = CPDImage[p][q]
			
	String NoteStr = ""
	variable A
	
	for (A = 0;A < Layers;A += 1)
		SetDimLabel 2,A,$StringFromList(A,DataTypeList,";"),ImageWave		//set the layer label based on the string from DataTypeList
		//put in some values for the note
		//here you can make this considerably more complex, calculating starting values and whatnot.
		NoteStr = ReplaceNumberByKey("Display Range"+num2str(A),NoteStr,12e-6,":","\r")
		NoteStr = ReplaceNumberByKey("Display Offset "+num2str(A),NoteStr,0,":","\r")
		NoteStr = ReplaceStringByKey("Colormap"+num2str(A),NoteStr,"Inferno",":","\r")
		NoteStr = ReplaceNumberByKey("Planefit Offset "+num2str(A),NoteStr,0,":","\r")
		NoteStr = ReplaceNumberByKey("Planefit X Slope"+num2str(A),NoteStr,0,":","\r")
		NoteStr = ReplaceNumberByKey("Planefit Y Slope"+num2str(A),NoteStr,0,":","\r")	
	endfor
	
	Note/K ImageWave		//clear any existing note on the wave
	Note ImageWave,NoteStr		//put ours on
	
	duplicate/o ImageWave, $name
	
	gl_ResaveImageFunc($name,"SaveImage",0)		//call the function that will save the info

	SetDataFolder savDF //restore the data folder to its original location
End