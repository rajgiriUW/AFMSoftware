#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ImageScanAMSKPM(xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed)
	
	Variable xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed
	
	String savDF = GetDataFolder(1) // locate the current data folder
	SetDataFolder root:packages:trEFM
	Svar LockinString
	
	SetDataFolder root:packages:trEFM:ImageScan
	Nvar numavgsperpoint
	
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	variable/G freq_PGain
	variable/G freq_IGain 
	variable/G freq_DGain

	SetDataFolder root:Packages:trEFM:ImageScan:SKPM

	//*******************  AAAAAAAAAAAAAAAAA **************************************//
	//*******  Initialize all global and local Variables that are shared for all experiments ********//

	GetGlobals()  //getGlobals ensures all vars shared with asylum are current
	
	//global Variables	
	if ((scansizex / scansizey) != (scanpoints / scanlines))
		abort "X/Y scan size ratio and points/lines ratio don't match"
	endif
	
	// SKPM Variables.
	NVAR LockinTimeConstant = root:Packages:trEFM:PointScan:SKPM:LockinTimeConstant 
	NVAR LockinSensitivity = root:Packages:trEFM:PointScan:SKPM:LockinSensitivity
	NVAR ACFrequency= root:Packages:trEFM:PointScan:SKPM:ACFrequency
	NVAR ACVoltage = root:Packages:trEFM:PointScan:SKPM:ACVoltage
	NVAR TimePerPoint = root:Packages:trEFM:PointScan:SKPM:TimePerPoint

	NVAR calresfreq = root:packages:trEFM:VoltageScan:Calresfreq
	NVAR CalEngageFreq = root:packages:trEFM:VoltageScan:CalEngageFreq
	NVAR CalHardD = root:packages:trEFM:VoltageScan:CalHardD
	NVAR CalsoftD = root:packages:trEFM:VoltageScan:CalsoftD
	NVAR CalPhaseOffset = root:packages:trEFM:VoltageScan:CalPhaseOffset
	
	// single line stuff
	NVAR UseLineNumforVoltage = root:packages:trEFM:PointScan:SKPM:UseLineNumforVoltage
	NVAR LineNumforVoltage = root:packages:trEFM:PointScan:SKPM:LineNumforVoltage
	NVAR VoltageatLine = root:packages:trEFM:PointScan:SKPM:VoltageatLine
	
	NVAR LineNumforVoltage2 = root:packages:trEFM:PointScan:SKPM:LineNumforVoltage2
	NVAR VoltageatLine2 = root:packages:trEFM:PointScan:SKPM:VoltageatLine2
	
	//Variable FreqOffsetNorm = 500
	
	NVAR Setpoint =  root:Packages:trEFM:Setpoint
	NVAR ADCgain = root:Packages:trEFM:ADCgain
	NVAR PGain = root:Packages:trEFM:PGain
	NVAR IGain = root:Packages:trEFM:IGain
	NVAR SGain = root:Packages:trEFM:SGain
	NVAR ImagingFilterFreq = root:Packages:trEFM:ImagingFilterFreq
	NVAR XFastEFM = root:packages:trEFM:ImageScan:XFastEFM
	NVAR YFastEFM = root:packages:trEFM:ImageScan:YFastEFM
	NVAR UseLineNum = root:packages:trEFM:ImageScan:UseLineNum
	NVAR LineNum = root:packages:trEFM:ImageScan:LineNum
	
	NVAR gWGDeviceAddress = root:packages:trEFM:gWGDeviceAddress
	
	Variable XLVDTSens = GV("XLVDTSens")
	Variable XLVDToffset = GV("XLVDToffset")
	Variable YLVDTSens  = GV("YLVDTSens")
	Variable YLVDToffset = GV("YLVDToffset")
	Variable ZLVDTSens = GV("ZLVDTSens")
	
	// Electric Tune
	variable EAmp = GV("NapDriveAmplitude")
	variable EFreq = GV("NapDriveFrequency")
	variable EOffset = GV("NapTipVoltage")
	variable EPhase = GV("NapPhaseOffset")
	Wave NapVariablesWave = root:packages:MFP3D:Main:Variables:NapVariablesWave
	Variable PotentialIGain = NapVariablesWave[%PotentialIGain][%Value]

	Nvar xigain, yigain, zigain
		
	WAVE EFMFilters=root:Packages:trEFM:EFMFilters
	
	//local Variables
	Variable starttime,starttime2,starttime3
	Variable Downinterpolation, Upinterpolation
	Variable ReadWaveZmean
	Variable Interpolation = 1 // sample rate of DAQ banks
	Variable samplerate = 50000/interpolation
	Variable totaltime = 16 //
	
	//*******************  AAAAAAAAAAAAAAAAA **************************************//	
	
	ResetAll()	
	Downinterpolation = ceil((50000 * (scansizex / scanspeed) / scanpoints))
	DoUpdate

	//******************  BBBBBBBBBBBBBBBBBB *******************************//
	//SETUP Scan Framework and populate scan waves 
	// Then initialize all other in and out waves
	//***********************************************************************
	
	Make/O/N = (scanlines, 4) ScanFramework
	
	// save time trace
	Make/O/N=(scanlines) ScanTimes = Nan
	
	variable SlowScanDelta
	variable FastscanDelta
	variable i,j,k,l
	// Set up scan Frameworks
	// 	ScanFramework[][0]: fastscan down (topo)
	//	ScanFramework[][1]: slowscan down (topo, only changes after each line)
	//	ScanFramework[][2]: fastscan up (efm)
	//	ScanFramework[][3]: slowscan up (efm, only changes after each line)
	// Note that images are confirmed correct on 6/20/2019 by Raj in both 0 deg and 90 deg, logic below is all valid
	// ScanSizeY is just the "width" in the panel, not physically the Y-scale (so for 90 degrees it's actually the X-size)	

	// 0 deg
	if (XFastEFM == 1 && YFastEFM == 0) //x direction scan
		ScanFramework[][0] = xpos - scansizeX / 2 //gPSscansizeX= fast width
		ScanFramework[][2] = xpos + scansizeX / 2
		SlowScanDelta = scansizeY / (scanlines - 1)
		FastscanDelta = scansizeX / (scanpoints - 1)
	
		i=0
		do
			if(scanlines > 1)
				ScanFramework[i][1] = (ypos - scansizeY / 2) + SlowScanDelta*i
				ScanFramework[i][3] = (ypos - scansizeY / 2) + SlowScanDelta*i
			else
				ScanFramework[i][1] = ypos
				ScanFramework[i][3] = ypos
			endif
			i += 1
		while (i < scanlines)

	// 90 degree		
	elseif  (XFastEFM == 0 && YFastEFM == 1) //y direction scan
		ScanFramework[][0] = ypos + scansizeX / 2 //gPSscansizeX= fast width
		ScanFramework[][2] = ypos - scansizeX / 2
		SlowScanDelta = scansizeY / (scanlines - 1)
		FastscanDelta = scansizeX / (scanpoints - 1)
		i=0
		do
			if(scanlines>1)
				ScanFramework[i][1] = (xpos - scansizeY / 2) + SlowScanDelta*i
				ScanFramework[i][3] = (xpos - scansizeY / 2) + SlowScanDelta*i
			else
				ScanFramework[i][1] = xpos
				ScanFramework[i][3] = xpos
			endif
			i += 1
		while (i < scanlines)
	
	endif
	
	Make/O/N = (scanpoints, scanlines) Topography, CPDImage, TopographyRaw

	if (XFastEFM == 1 && YFastEFM == 0)
		SetScale/I x, ScanFrameWork[0][0], ScanFramework[0][2], "um", Topography, CPDImage, TopographyRaw
		if(scanlines==1)
			SetScale/I y, ypos, ypos, Topography, CPDImage, TopographyRaw
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, CPDImage, TopographyRaw
		endif
	

	elseif (XFastEFM == 0 && YFastEFM == 1)
		SetScale/I x, ScanFrameWork[0][2], ScanFramework[0][0], "um", Topography, CPDImage, TopographyRaw
		if(scanlines==1)
			SetScale/I y, ypos, ypos, Topography, CPDImage, TopographyRaw
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, CPDImage, TopographyRaw
		endif
	
	endif

	if(mod(scanpoints,32) != 0)									
		abort "Scan Points must be divisible by 32"
	endif
	
	Make/O/N = (scanpoints) ReadWaveZ, ReadWaveZback, Xdownwave, Ydownwave, Xupwave, Yupwave
	Make/O/N = (scanpoints, scanlines, 4) XYupdownwave
	ReadWaveZ = NaN
	
	// Interleaved voltage
	Make/O/N=(scanpoints) ReadWaveZInterleave = NaN // dummy wave
	Make/O/N=(scanpoints) ReadWaveZOffset = NaN // forward trace offset by liftheight

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//do this to desable the slow scan axis
	//i = 0
	//do
	//	if(scanlines > 1)
	//		ScanFramework[i][1] = ypos 
	//		ScanFramework[i][3] = ypos
	//	else
	//		ScanFramework[i][1] = ypos
	//		ScanFramework[i][3] = ypos
	//	endif
	//	i += 1
	//while (i < scanlines)
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


	//******************  BBBBBBBBBBBBBBBBBB *******************************//

	//******************  CCCCCCCCCCCCCCCCCC *******************************//
	//POPULATE Data/Drive waves by experiment, these settings should not change
	// from jump to jump, cycle to cycle, or between the trace and retrace
	// vars that do change are initialized below
	//***********************************************************************


	Make/O/N=(scanpoints) CPDTrace, CPDTraceBefore
	Variable pointsPerPixel = timeperpoint * samplerate * 1e-3
	Variable pointsPerLine = pointsPerPixel * scanpoints
	make/o/n=(pointsPerPixel) CPDWaveTemp
	
	variable lastvoltage, lk, ll
	make/o/n=(pointsPerPixel) CPDWaveLastPoint
	
	Variable timeofscan = timeperpoint * 1e-3 * scanpoints
//	timeofscan = 1e-3*scanpoints
	Upinterpolation = (timeofscan * samplerate) / (scanpoints)
	//print timeofscan, upinterpolation, lockintimeConstant, lockinsensitivity

	//******************  CCCCCCCCCCCCCCCCCC *******************************//
	
	//******************  DDDDDDDDDDDDDDDDDDD *******************************//	
	//***************** Open the scan panels ***********************************//
	
			// trefm charge creation/delay/ff-trEFM

	dowindow/f CPD
	if (V_flag==0)
		Display/K=1/n=CPD;Appendimage CPDImage
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan (um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(62000,65000,48600),expand=.7
		ColorScale/C/N=text0/E/F=0/A=MC image=CPDImage
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "V"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=CPDImage
	endif
	
	ModifyGraph/W=CPD height = {Aspect, scansizeY/scansizeX}		

	dowindow/f TopgraphyImage
	if (V_flag==0)
		Display/K=1/n=TopgraphyImage;Appendimage Topography
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan(um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(65000,60000,48600),expand=.7	
		ColorScale/C/N=text0/E/F=0/A=MC image=Topography
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "um"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=Topography
	endif	
	
	ModifyGraph/W=TopgraphyImage height = {Aspect, scansizeY/scansizeX}
	ModifyGraph/W=CPD height = {Aspect, scansizeY/scansizeX}
	dowindow/f CPDTraceWindow
	
	if (V_flag==0)
		Display/K=1/n=CPDTraceWindow CPDTrace
		appendtograph CPDTraceBefore
		ModifyGraph rgb(CPDTraceBefore)=(0,0,0)
	endif
	
	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=TopographyImage height = {Aspect, 1}
		ModifyGraph/W=CPDImage height = {Aspect, 1}
	endif

	//**************** End scan panel setup  ***************//
	//******************  DDDDDDDDDDDDDDDDDDD *******************************//

	//Set inwaves with proper length and instantiate to Nan so that inwave timing works
	Make/O/N = (pointsPerLine) CPDWave, CPDWaveLast
	CPDWave = NaN

	//******************  EEEEEEEEEEEEEEEEEEE *******************************//	
	//******************** SETUP all hardware, FBL, XPT and external hdwe settings that are common
	//*******************  to both the trace and retrace **************
	
	// crosspoint needs to be updated to send the trigger to the gage card	
	// Set up the crosspoint, note that KP crosspoint settings change between the trace and retrace and are reset below

	SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","In0","DDS")
		
	//stop all FBLoops except for the XY loops
	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
	
	variable error = 0
	td_StopInWaveBank(-1)
		
	SetPassFilter(1,q=EFMFilters[%KP][%q],i=EFMFilters[%KP][%i],a=EFMFilters[%KP][%A],b=EFMFilters[%KP][%B])
	
	// Load KP Gains from a text file
	
//	SetFeedbackLoop(5, "Always", LockinString+"theta", td_rv(LockinString+"theta"), freq_PGain, freq_IGain, freq_DGain, "Output.A", 0)
//	SetFeedbackLoop(4, "Always", "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], 0, "Output.B", 0)	
//	SetFeedbackLoop(4, "Always", "Input.B", 0, KPPgain, KPIgain, KPDGain, "Output.B", 0)	
	SetFeedbackLoop(3, "Always",  "ZSensor", ReadWaveZ[scanpoints-1] - liftheight * 1e-9 / GV("ZLVDTSens"), 0, EFMFilters[%ZHeight][%IGain],0, "Output.Z",0)
	
	Sleep/S 0.2
	//stop all FBLoops again now that they have been initialized
	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
	
	// Set all DAC outputs to zero initially
	td_wv("Output.A", 0)
	td_wv("Output.B", 0)	
	td_wv("Output.C", 0)	
	//******************  EEEEEEEEEEEEEEEEEEE *******************************//	
	
	//******************  FFFFFFFFFFFFFFFFFFFFFF *******************************//
	
	//pre-loop initialization, done only once
	//move to initial scan point
	if (XFastEFM == 1 && YFastEFM == 0)	
		if (UseLineNum == 0)
			MoveXY(ScanFramework[0][0], ScanFramework[0][1])
		else
			MoveXY(ScanFramework[0][0], (ypos - scansizeY / 2)  + SlowScanDelta*LineNum)
		endif
	elseif (XFastEFM == 0 && YFastEFM == 1)
		if (UseLineNum == 0)
			MoveXY(ScanFramework[0][1], ScanFramework[0][0])
		else
			MoveXY((xpos - scansizeY / 2)  + SlowScanDelta*LineNum, ScanFramework[0][0])
		endif
	endif
	
	SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","In0","DDS")
	variable currentX = td_ReadValue("XSensor")
	variable currentY = td_ReadValue("YSensor")
	
	//************************************* XYupdownwave is the final, calculated, scaled values to drive the XY piezos ************************//	
	if (XFastEFM == 1 && YFastEFM == 0)	//x  scan direction
		XYupdownwave[][][0] = (ScanFrameWork[q][0] + FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][1] = (ScanFrameWork[q][2] - FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][2] = (ScanFrameWork[q][1]) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][3] = (ScanFrameWork[q][3]) / YLVDTsens / 10e5 + YLVDToffset
	elseif (XFastEFM == 0 && YFastEFM == 1)	
		XYupdownwave[][][2] = (ScanFrameWork[q][0] - FastScanDelta*p) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][3] = (ScanFrameWork[q][2] + FastScanDelta*p) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][0] = (ScanFrameWork[q][1]) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][1] = (ScanFrameWork[q][3]) / XLVDTsens / 10e5 + XLVDToffset
	endif
	
	//Set up the tapping mode feedback
	td_wv(LockinString + "Amp",CalHardD) 
	td_wv(LockinString + "Freq",CalEngageFreq) //set the frequency to the resonant frequency
	td_wv(LockinString + "FreqOffset",0)
	
	SetFeedbackLoop(2, "Always", "Amplitude", Setpoint, -PGain, -IGain, -SGain, "Height", 0)	
	
	Sleep/S 1.5
	
	//******************  FFFFFFFFFFFFFFFFFFFFFF *******************************//
	//*********************************************************************//
	
	///Starting imaging loop here

	i = 0
	variable heightbefore, heightafter
	do
		starttime2 = StopMSTimer(-2) //Start timing the raised scan line
		print "line ", i+1

		if (UseLineNum == 0)	// single line scans
			LineNum = i
		endif
		
		if (UseLineNumForVoltage != 0)
		
			if (i == LineNumforVoltage)
				PsSetting(VoltageatLine, current=0.7)
			endif
			
			if (i == LineNumforVoltage2)
				PsSetting(VoltageatLine2, current=0.7)
			endif
						
		endif
		
		// these are the actual 1D drive waves for the tip movement
		Xdownwave[] = XYupdownwave[p][LineNum][0]
		Xupwave[] = XYupdownwave[p][LineNum][1]
		Ydownwave[] = XYupdownwave[p][LineNum][2]
		Yupwave[] = XYupdownwave[p][LineNum][3]
	
		//****************************************************************************
		//*** SET TRACE VALUES HERE
		//*****************************************************************************
		td_StopInWaveBank(-1)
		td_StopOutWaveBank(-1)
		
		error+= td_xSetInWave(0,"Event.0", "ZSensor", ReadWaveZ,"", Downinterpolation)// used during Trace to record height data		
		error+= td_xSetOutWavePair(0,"Event.0", "$outputXLoop.Setpoint", Xdownwave,"$outputYLoop.Setpoint",Ydownwave ,-DownInterpolation)
		SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","Ground","DDS")

		SetPassFilter(1, q = ImagingFilterFreq, i = ImagingFilterFreq)

		td_wv(LockinString + "Amp", CalHardD) 
		td_wv(LockinString + "Freq", CalEngageFreq) //set the frequency to the resonant frequency
		td_wv(LockinString + "FreqOffset", 0)
		td_wv("Output.A", 0)
		td_wv("Output.B", 0)
		td_wv("Output.C",0)

		
		// START TOPOGRAPHY SCAN
		error+= td_WriteString("Event.0", "Once")
		if (error != 0)
			print i, "error3", error
		endif
			
		starttime3 = StopMSTimer(-2) //Start timing the raised scan line

		CheckInWaveTiming(ReadWaveZ) // Waits until the topography trace has been fully collected.

		Sleep/S .05
		
		//ReadWaveZback is the drive wave for the z piezo		
		ReadWaveZback[] = ReadwaveZ[scanpoints-1-p] - liftheight * 1e-9 / GV("ZLVDTSens")
		ReadWaveZOffset[] = ReadWaveZ - liftheight*1e-9 / GV("ZLVDTSens")
		ReadWaveZmean = Mean(ReadwaveZ) * ZLVDTSens
		Topography[][i] = -(ReadwaveZ[p] * ZLVDTSens-ReadWaveZmean)
		TopographyRaw[][i] = -(ReadwaveZ[p] * ZLVDTSens)
		DoUpdate
		

		//*****************************************************************************
		//*** SET DATA COLLECTION STUFF.
		//*****************************************************************************		
		td_stopInWaveBank(-1)
		td_stopOutWaveBank(-1)

		error += td_xSetInWave(1, "Event.2", "Potential", CPDWave,"", -1) 
		heightbefore = td_rv("Zsensor")*td_rv("ZLVDTSens")
		 
		//stop amplitude FBLoop and 
		StopFeedbackLoop(2)		

		// to keep tip from being stuck
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-500*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0, name="OutputZ") // note the integral gain of 10000
		sleep/S 0.5
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0, name="OutputZ", arcZ=1) // note the integral gain of 10000
		sleep/s 0.5
		
		heightafter = td_rv("Zsensor")*td_rv("ZLVDTSens")
		print "The lift height is", (heightbefore-heightafter)*1e9, " nm"

		error+= td_xsetoutwavePair(1,"Event.2", "$outputXLoop.Setpoint", Xupwave,"$outputYLoop.Setpoint", Yupwave,-UpInterpolation)
		if (stringmatch("ARC.Lockin.0." , LockinString))
			error+= td_xsetoutwave(2, "Event.2", "ARC.PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)
		else
			error+= td_xsetoutwave(2, "Event.2", "Cypher.PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)
		endif

		td_wv((LockinString + "Amp"), calsoftd) //set the amplitude from the grab tune function
		td_wv((LockinString + "Freq"), CalResFreq) //set the frequency to the resonant frequency
		td_wv((LockinString + "PhaseOffset"), CalPhaseOffset)  // phase offset also comes from calibration panel

		SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","DDS","Ground")
		SetPassFilter(1, q = EFMFilters[%KP][%q], i = EFMFilters[%KP][%i])
		
		td_WriteValue("DDSAmplitude0",EAmp)	
		td_WriteValue("DDSFrequency0",EFreq)	

// Maybe have to comment this next line
		td_WriteValue("DDSDCOffset0",EOffset)	

		td_WriteValue("DDSPhaseOffset0",EPhase)
		
		SetFeedbackLoop(4, "always", LockinString + "q", 0, 0, PotentialIGain*1000, 0, "Potential", 0)

		// Use a decent initialization for feedback loop, second line onwards
		lastvoltage = 0
		if (i != 0)
			lk = 0
			ll = (scanpoints - 1) * pointsPerPixel
			do
				CPDWaveLastPoint[lk] = CPDWaveLast[ll]
				ll += 1
				lk += 1
			while (lk < pointsPerPixel)
			
			lastvoltage = mean(CPDWaveLastPoint)
			if (lastvoltage > 6 || lastvoltage < -6)
				lastvoltage = 0
			endif	
			printf "LastVoltage is %g\r", lastvoltage		
			error += td_wv("Output.B", lastvoltage) //get the intial tip voltage close to where it was before
		endif
		
//		SetFeedbackLoop(4, "always",  "Input.B", 0, KPPGain, KPIGain, KPDGain, "Output.B", 0) 
//		SetFeedbackLoop(4, "always",  "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], EFMFilters[%KP][%DGain], "Output.B", 0) 
		sleep/S 1/4
				
		//Fire retrace event here
		error += td_WriteString("Event.2", "Once")
		
		//abort
		
		CheckInWaveTiming(CPDWave)
	
		//**********************************************************************************
		//***  PROCESS DATA AND UPDATE GRAPHS
		//*******************************************************************************
		j = 0
		do
			CPDWaveTemp = 0
			k = 0
			l = j * pointsPerPixel
			
			do
				CPDWaveTemp[k] = CPDWave[l]
				
				k += 1
				l += 1
			while (k < pointsPerPixel)
		
			CPDImage[scanpoints-j-1][i] = mean(CPDWaveTemp)
			//CPDImage[scanpoints-j-1][i] = StatsMedian(CPDWaveTemp)
			j += 1
			
		while (j < scanpoints)

		if(i>0)
			CPDTraceBefore=CPDTrace
		endif
		CPDTrace = CPDImage[p][i]
		
		//**********************************************************************************
		//***  END OF PROCESS DATA AND UPDATE GRAPHS
		//*******************************************************************************		
		//*************************************************************
		//************ RESET FOR NEXT LINE **************** //
		//*************************************************************
		if (i < scanlines)//////////////
		
			DoUpdate 
			//stop height FBLoop, restart Amplitude FBLoop and move to starting point of next line
			StopFeedbackLoop(3)	
			StopFeedbackLoop(4)	
			StopFeedbackLoop(5)	
			
			td_stopInWaveBank(-1)
			td_stopOutWaveBank(-1)

			SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","Ground","DDS")
			
			td_wv(LockinString + "Amp", CalHardD) 
			td_wv(LockinString + "Freq", CalEngageFreq)
			td_wv(LockinString + "FreqOffset", 0)	
				
			SetFeedbackLoop(2, "Always", "Amplitude", Setpoint, -PGain, -IGain, -SGain, "Height", 0)	
				
		endif 
	
		scantimes[i] = (StopMSTimer(-2) -starttime2)*1e-6
		print "Time for last scan line (seconds) = ", scantimes[i], " ; Time remaining (in minutes): ?"
		i += 1
		
		//Reset the primary inwaves to Nan so that gl_checkinwavetiming function works properly
		CPDWaveLast[] = CPDWave[p]
		ReadWaveZ[] = NaN
		CPDWave[] = NaN
		ReadWaveZInterleave[] = NaN
				
		//ACVoltage = root:Packages:trEFM:PointScan:SKPM:ACVoltage
		//ACVoltage+=0.05
		//print "Vac= ", ACVoltage, " V"
		
	while (i < scanlines )	
	// end imaging loop 
	//************************************************************************** //
	
	if (error != 0)
		print "there was some setinoutwave error during this program"
	endif
	
	DoUpdate		
		
	StopFeedbackLoop(3)	
	StopFeedbackLoop(4)	
	StopFeedbackLoop(5)	

	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	
	
	Duplicate/O Topography, TopographyTempCheck
	Duplicate/O TopographyRaw, Topography
	
	if (useLineNUm != 0)
	
		display ScanTimes
		Label left "Scan time (s)";DelayUpdate
		Label bottom "Scan Line (#)"
	endif
	
	td_wv("Output.C", 0)

	Beep
	doscanfunc("stopengage")
	setdatafolder savDF

End