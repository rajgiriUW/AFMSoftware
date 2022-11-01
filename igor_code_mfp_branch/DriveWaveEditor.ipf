#pragma rtGlobals=1		// Use modern global access method.

Function VoltageWaveEditor()
// Call this function to open to function editor and edit the voltage wave that is sent to the tip during the Point Scan Experiment.

	Struct ARFEDriveParms InfoStruct

	InitARFEDriveParmsGL(InfoStruct)
	InfoStruct.Handle = "Default"
	InfoStruct.NumOfSegments = 3
	InfoStruct.SampleRate = 50000
	InfoStruct.UnitsScaleValues[0] = 1

	// DRAW THE VOLTAGE WAVE

	InfoStruct.SegmentParms[0].StartPos = 0 //starting voltage
	InfoStruct.SegmentParms[0].EndPos =0 // ending voltage
	InfoStruct.SegmentParms[0].Length = 1/1000 //duration in seconds

	InfoStruct.SegmentParms[1].StartPos = 10
	InfoStruct.SegmentParms[1].EndPos = 10
	InfoStruct.SegmentParms[1].Length = 14/1000

	InfoStruct.SegmentParms[2].StartPos = 0
	InfoStruct.SegmentParms[2].EndPos = 0
	InfoStruct.SegmentParms[2].Length = 1/1000

// 2-13ms 10V tip 8-14ms
	InfoStruct.IsLocked = 1
	InfoStruct.DestWave = "root:Packages:trEFM:WaveGenerator:gentipwaveTemp"
	InitARFE(InfoStruct, ForceIt=1)
	
	ARFEGetParms(InfoStruct)
	MakeFEGraph(InfoStruct.Handle)

	SetVariable SegmentLengthSetVar format="%.4f s"

End

Function TriggerWaveEditor()
// Call this function to edit the wave that will be sent to the trigger LED box
	Struct ARFEDriveParms InfoStruct

	InitARFEDriveParmsGL(InfoStruct)
	InfoStruct.Handle = "Default"
	InfoStruct.NumOfSegments = 3
	InfoStruct.SampleRate = 50000
	// DRAW THE VOLTAGE WAVE
	// First Segment
	InfoStruct.SegmentParms[0].StartPos = 0 //starting voltage
	InfoStruct.SegmentParms[0].EndPos = 0 // ending voltage
	InfoStruct.SegmentParms[0].Length = 5/1000 //duration in seconds
	// Second Segment
	InfoStruct.SegmentParms[1].StartPos = 5 
	InfoStruct.SegmentParms[1].EndPos = 5
	InfoStruct.SegmentParms[1].Length = 8/1000
	// Third Segment
	InfoStruct.SegmentParms[2].StartPos = 0
	InfoStruct.SegmentParms[2].EndPos = 0
	InfoStruct.SegmentParms[2].Length = 3/1000

	InfoStruct.IsLocked = 1
	InfoStruct.DestWave = "root:Packages:trEFM:WaveGenerator:gentriggerwaveTemp"
	
	InitARFE(InfoStruct, ForceIt=1)
	
	ARFEGetParms(InfoStruct)

	MakeFEGraph(InfoStruct.Handle)
	
	SetVariable SegmentLengthSetVar format="%.4f s"

End

Function LightWaveEditor()
// Call this function to edit the wave that will be sent to the trigger LED box
	Struct ARFEDriveParms InfoStruct

	InitARFEDriveParmsGL(InfoStruct)
	InfoStruct.Handle = "Default"
	InfoStruct.NumOfSegments = 3
	InfoStruct.SampleRate = 50000
	// DRAW THE VOLTAGE WAVE
	// First Segment
	InfoStruct.SegmentParms[0].StartPos = 0 //starting voltage
	InfoStruct.SegmentParms[0].EndPos = 0 // ending voltage
	InfoStruct.SegmentParms[0].Length = 5/1000 //duration in seconds
	// Second Segment
	InfoStruct.SegmentParms[1].StartPos = 5 
	InfoStruct.SegmentParms[1].EndPos = 5
	InfoStruct.SegmentParms[1].Length = 5/1000
	// Third Segment
	InfoStruct.SegmentParms[2].StartPos = 0
	InfoStruct.SegmentParms[2].EndPos = 0
	InfoStruct.SegmentParms[2].Length = 6/1000

	InfoStruct.IsLocked = 1
	InfoStruct.DestWave = "root:Packages:trEFM:WaveGenerator:genlightwaveTemp"
	
	InitARFE(InfoStruct, ForceIt=1)
	
	ARFEGetParms(InfoStruct)

	MakeFEGraph(InfoStruct.Handle)
	
	SetVariable SegmentLengthSetVar format="%.4f s"

End

Function RingDownWaveEditor()
// Call this function to edit the wave that will be sent to the trigger LED box
	Struct ARFEDriveParms InfoStruct

	InitARFEDriveParmsGL(InfoStruct)
	InfoStruct.Handle = "Default"
	InfoStruct.NumOfSegments = 3
	InfoStruct.SampleRate = 50000
	
	nvar calsoftD = root:packages:trEFM:voltagescan:calsoftD
	
	// DRAW THE VOLTAGE WAVE
	// First Segment
	InfoStruct.SegmentParms[0].StartPos = calsoftD //starting voltage
	InfoStruct.SegmentParms[0].EndPos = calsoftD // ending voltage
	InfoStruct.SegmentParms[0].Length = 5/1000 //duration in seconds
	// Second Segment
	InfoStruct.SegmentParms[1].StartPos = 0
	InfoStruct.SegmentParms[1].EndPos = 0
	InfoStruct.SegmentParms[1].Length = 5/1000
	// Third Segment
	InfoStruct.SegmentParms[2].StartPos = calsoftD
	InfoStruct.SegmentParms[2].EndPos = calsoftD
	InfoStruct.SegmentParms[2].Length = 6/1000

	InfoStruct.IsLocked = 1
	InfoStruct.DestWave = "root:Packages:trEFM:WaveGenerator:gendrivewaveTemp"
	
	InitARFE(InfoStruct, ForceIt=1)
	
	ARFEGetParms(InfoStruct)

	MakeFEGraph(InfoStruct.Handle)
	
	SetVariable SegmentLengthSetVar format="%.4f s"

End

Function CutWaveEditor(checked)
// Call this function to edit the wave that will be sent to the drive to "cut" the drive
// This logic uses "trigger wave" as the point where the drive should be cut.
//	This allows us to do the equivalent of ringdown but at arbitrary locations

	variable checked
	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM:WaveGenerator

	NVAR cutDrive = root:packages:trEFM:cutDrive
	NVAR cutpreV = root:packages:trEFM:cutpreV // ms before voltage pulse to stop drive
	NVAR cutLength = root:packages:trEFM:cutLength
	NVAR calsoftD = root:packages:trEFM:voltagescan:calsoftD
	//NVAR interpval = root:packages:trEFM:interpval
	
	Wave gentriggerwavetemp = root:packages:trEFM:WaveGenerator:gentriggerwaveTemp
	Duplicate/O genTriggerWaveTemp, genDriveWaveTemp
	GenDriveWaveTemp = NaN
	
	// hard coded to assume 16 ms time since interp overridden in Point/Image Scans
	variable scale = dimdelta(gentriggerwaveTemp, 0)
	SetScale/P x, 0, 2e-5, genTriggerWaveTemp
	SetScale/P x, 0, 2e-5, genDriveWaveTemp

	PulseStats/Q/L=(0, 5) gentriggerwaveTemp
	variable trig = V_PulseLoc1 



	variable start = x2pnt(genDriveWaveTemp, trig - cutpreV*0.001)
	variable stop1 = x2pnt(genDriveWaveTemp, trig - cutpreV*0.001 + cutLength*0.001)
	if (checked == 1)
		
//		genDriveWaveTemp[0, x2pnt(genDriveWaveTemp, trig - cutpreV*0.001)] = calsoftD
//		genDriveWaveTemp[x2pnt(genDriveWaveTemp, trig - cutpreV*0.001), ] =  calsoftD*.95
//		genDriveWaveTemp[0, x2pnt(genDriveWaveTemp, trig - cutpreV*0.001)] = calsoftD
		genDriveWaveTemp[0, start] = calsoftD

		if (cutLength != -1)
			genDriveWaveTemp[start, stop1] = 0
			genDriveWaveTemp[stop1, *] = calsoftD
			
//			PulseStats/Q/L=(5, 0) gentipwaveTemp
//			trig = V_PulseLoc2 
//	
//			// turns drive back on once voltage turns off
//			genDriveWaveTemp[x2pnt(genDriveWaveTemp, trig), *] = calsoftD
		else
			genDriveWaveTemp[start, *] = 0
		endif
		

	else
		genDriveWaveTemp = calsoftD
	endif

	CleanDriveWave(genDriveWaveTemp)
	
	SetDataFolder savDF

End

Function CutDriveProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			CutWaveEditor(checked)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function InitARFEDriveParmsGL(InfoStruct)
	Struct ARFEDriveParms &InfoStruct
	
	//simple function just to put something reasonable in the structure.
	//Then it is the specific initialize function's job to adjust things before calling InitARFE
	
	InfoStruct.Scale = 1
	InfoStruct.Offset = 0
	InfoStruct.Units = "V"
	InfoStruct.UnitsList = "V;m;"
	InfoStruct.UnitsScale = 1
	InfoStruct.UnitsScaleValues[0] = 1
	InfoStruct.UnitsScaleValues[1] = 1
	InfoStruct.SineAmp = 0
	InfoStruct.SinePhase = 0
	InfoStruct.SineFreq = 10
	InfoStruct.SampleRate = 50000
	InfoStruct.DriveOption0 = "UserOut1"
	InfoStruct.DriveOption1 = "UserOut2"
	InfoStruct.NumOfSegments = 1
	InfoStruct.SelectedIndex = "0,"
	InfoStruct.DestWave = ""
	InfoStruct.IsLocked = 0
	InfoStruct.Handle = ""
	InfoStruct.NumOfClipBoardSegments = 0
	InfoStruct.FEVersionNumber = cFEVersionNumber
	
	
End //InitARFEDriveParms

Function CleanDriveWave(drivewave)
// A (hopefully) temporary function that solves the problem of extra points being inserted
// at the end of our drive waves. 
	Wave drivewave
	DeletePoints 800, 87770, drivewave
End
	
Function AppendCycles(numcycles, [interpval])
// Input: an integer specifying the number of cycles of the drive wave that are desired
// output: WAves gentipwave and gentriggerwave, contain the waveforms created in the wave editor repeated 
// Use this to specify the number of collection cycles.
	Variable numcycles, interpval
	
	if (ParamIsDefault(interpval))
		interpval = 1
	endif
	
	Wave generatedwave
	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM:WaveGenerator
	Wave gentipwaveTemp, gentriggerwaveTemp, genlightwaveTemp, gendrivewaveTemp
	
	if (numcycles == 1)
		Make/O/N = (800) gentipwave
		Make/O/N = (800) gentriggerwave
		Make/O/N = (800) genlightwave
		Make/O/N = (800) gendrivewave
		
		gentipwave = gentipwaveTemp
		gentriggerwave = gentriggerwaveTemp
		genlightwave = genlightwaveTemp
		gendrivewave = gendrivewaveTemp
		
//		Resample/UP=(interpval) gentipwave
//		Resample/UP=(interpval) gentriggerwave
//		Resample/UP=(interpval) genlightwave
//		Resample/UP=(interpval) gendrivewave

	else
		Make/O/N = (800) gentipwave
		Make/O/N = (800) gentriggerwave
		Make/O/N = (800) genlightwave
		Make/O/N = (800) gendrivewave
		
		gentipwave = gentipwaveTemp
		gentriggerwave = gentriggerwaveTemp
		genlightwave = genlightwaveTemp
		gendrivewave = gendrivewaveTemp
	
//		Resample/UP=(interpval) gentipwave
//		Resample/UP=(interpval) gentriggerwave
//		Resample/UP=(interpval) genlightwave
//		Resample/UP=(interpval) gendrivewave
	
		Concatenate/NP = 0 /O {gentipwaveTemp}, gentipwave
		Concatenate/NP = 0 /O {gentriggerwaveTemp}, gentriggerwave
		Concatenate/NP = 0 /O {genlightwaveTemp}, genlightwave
		Concatenate/NP = 0 /O {gendrivewaveTemp}, gendrivewave

//		Duplicate/O genlightwave, genlightwavetemp
//		Duplicate/O gendrivewave, gendrivewavetemp
//		Duplicate/O gentriggerwave, gentriggerwavetemp
//		Duplicate/O gentipwave, gentipwavetemp
		
		Variable i = 0
		Variable j = 0
		for( j = 0; j < interpval; j += 1)
			for( i = 0; i < numcycles - 1; i += 1)
				Concatenate/NP = 0 {gentipwaveTemp}, gentipwave
				Concatenate/NP = 0 {gentriggerwaveTemp}, gentriggerwave
				Concatenate/NP = 0 {genlightwaveTemp}, genlightwave
				Concatenate/NP = 0 {gendrivewaveTemp}, gendrivewave
			endfor
		endfor
	endif

//	Resample/UP=(interpval) gentipwave
//	Resample/UP=(interpval) gentriggerwave
//	Resample/UP=(interpval) genlightwave
//	Resample/UP=(interpval) gendrivewave
	
	SetDataFolder savDF
End