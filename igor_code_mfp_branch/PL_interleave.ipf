#pragma rtGlobals=3		// Use modern global access method and strict wave access.
Function LBICscan_interleave(xpos, ypos, scansizeX,scansizeY, scanlines, scanpoints)
	
	Variable xpos, ypos, scansizeX,scansizeY, scanlines, scanpoints
	
	String savDF = GetDataFolder(1) // locate the current data folder
	
	SetDataFolder root:packages:trEFM
	Svar LockinString
	NVAR Setpoint =  root:Packages:trEFM:Setpoint
	NVAR ADCgain = root:Packages:trEFM:ADCgain
	NVAR PGain = root:Packages:trEFM:PGain
	NVAR IGain = root:Packages:trEFM:IGain
	NVAR SGain = root:Packages:trEFM:SGain
	NVAR ImagingFilterFreq = root:Packages:trEFM:ImagingFilterFreq
	NVAR XFastEFM = root:packages:trEFM:ImageScan:XFastEFM
	NVAR YFastEFM = root:packages:trEFM:ImageScan:YFastEFM
	NVAR scanspeed = root:packages:trEFM:ImageScan:scanspeed
	Variable XLVDTSens = GV("XLVDTSens")
	Variable XLVDToffset = GV("XLVDToffset")
	Variable YLVDTSens  = GV("YLVDTSens")
	Variable YLVDToffset = GV("YLVDToffset")
	Variable ZLVDTSens = GV("ZLVDTSens")
	
	Nvar xigain, yigain, zigain
				
	SetDataFolder root:Packages:trEFM:ImageScan:LBIC
	NVAR LIAsens
	
	NVAR LineNumforVoltage = root:packages:trEFM:PointScan:SKPM:LineNumforVoltage
	NVAR PL_UseInterleaveVoltage =  root:packages:trEFM:ImageScan:LBIC:PL_UseInterleaveVoltage
	
	GetGlobals()  //getGlobals ensures all vars shared with asylum are current
	
	//global Variables	
	if ((scansizex / scansizey) != (scanpoints / scanlines))
		abort "X/Y scan size ratio and points/lines ratio don't match"
	endif

	NVAR LockinTimeConstant = root:Packages:trEFM:PointScan:SKPM:LockinTimeConstant 
	NVAR LockinSensitivity = root:Packages:trEFM:PointScan:SKPM:LockinSensitivity
	NVAR ACFrequency= root:Packages:trEFM:PointScan:SKPM:ACFrequency
	NVAR ACVoltage = root:Packages:trEFM:PointScan:SKPM:ACVoltage
	NVAR TimePerPoint = root:Packages:trEFM:PointScan:SKPM:TimePerPoint
	NVAR gWGDeviceAddress = root:packages:trEFM:gWGDeviceAddress
	
	NVAR VoltageAtLine =root:packages:trEFM:PointScan:SKPM:VoltageatLine
	
	NVAR calresfreq = root:packages:trEFM:VoltageScan:Calresfreq
	NVAR CalEngageFreq = root:packages:trEFM:VoltageScan:CalEngageFreq
	NVAR CalHardD = root:packages:trEFM:VoltageScan:CalHardD
	NVAR CalsoftD = root:packages:trEFM:VoltageScan:CalsoftD
	NVAR CalPhaseOffset = root:packages:trEFM:VoltageScan:CalPhaseOffset
	
	Nvar liftheight = root:Packages:trEFM:liftheight
	WAVE EFMFilters=root:Packages:trEFM:EFMFilters
	
	//local Variables
	Variable starttime,starttime2,starttime3
	Variable Downinterpolation, Upinterpolation
	Variable Interpolation = 1 // sample rate of DAQ banks
	Variable samplerate = 50000/interpolation
	Variable totaltime = 16 //
	
//	variable scanspeed = 1
	Downinterpolation = ceil((50000 * (scansizex / scanspeed) / scanpoints))  
	
	ResetAll()	
	DoUpdate

	Make/O/N = (scanlines, 4) ScanFramework
	variable SlowScanDelta
	variable FastscanDelta
	variable i,j,k,l
	NVAR XFastPL, YFastPL, PLLineNum, PL_UseLineNum

	if (XFastpl == 1 && YFastpl == 0) //x direction scan
		ScanFramework[][0] = xpos - scansizeX / 2 
		ScanFramework[][2] = xpos + scansizeX / 2
		SlowScanDelta = scansizeY / (scanlines - 1)
		FastscanDelta = scansizeX / (scanpoints - 1)

		i = 0
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
		
	elseif (XFastpl == 0 && YFastpl == 1)
		
		ScanFramework[][0] = ypos - scansizeX / 2 //gPSscansizeX= fast width
		ScanFramework[][2] = ypos + scansizeX / 2
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
	
	Make/O/N = (scanpoints, scanlines) LIBCurrent, LIBCurrentConverted, Topography
	Make/O/N = (scanpoints) Distance
	
	if(scanlines==1)
		SetScale/I y, ypos, ypos, LIBCurrent, LIBCurrentConverted, Topography
	else
		SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], LIBCurrent, LIBCurrentConverted, Topography
	endif

	if (XFastpl == 1 && YFastpl == 0) //x direction scan
		SetScale/I x, ScanFrameWork[0][0], ScanFramework[0][2], "um", LIBCurrent, LIBCurrentConverted, Topography
	elseif (XFastpl == 0 && YFastpl == 1) //y direction scan
		SetScale/I x, ScanFrameWork[0][2], ScanFramework[0][0], "um", LIBCurrent, LIBCurrentConverted, Topography
	endif
		
	if(mod(scanpoints,32) != 0)									
			abort "Scan Points must be divisible by 32"
	endif
	
	Make/O/N = (scanpoints)  Xdownwave, Ydownwave, Xupwave, Yupwave, ReadWaveZ, ReadWaveZback, ReadWaveZOffset
	Make/O/N=(scanpoints) ReadWaveZInterleave = NaN
	Make/O/N = (scanpoints, scanlines, 4) XYupdownwave
	ReadWaveZ = NaN

	NVAR TimePerPoint = root:Packages:trEFM:PointScan:SKPM:TimePerPoint
	Variable pointsPerPixel = timeperpoint * samplerate * 1e-3
	Variable pointsPerLine = pointsPerPixel * scanpoints
	Variable timeofscan = timeperpoint * 1e-3 * scanpoints
	Upinterpolation = (timeofscan * samplerate) / (scanpoints)

	dowindow/f LIBCurrentImage
	if (V_flag==0)
		Display/K=1/n=LIBCurrentImage;Appendimage LIBCurrent
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan(um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(65000,60000,48600),expand=.7	
		ColorScale/C/N=text0/E/F=0/A=MC image=LIBCurrent
		ModifyImage LIBCurrent ctab= {*,*,VioletOrangeYellow,0}
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "V"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=LIBCurrent
	endif		
	ModifyGraph/W=LIBCurrentImage height = {Aspect, scansizeY/scansizeX}
	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=LIBCurrentImage height = {Aspect, 1}
	endif
	
	dowindow/f LIBCurrentConvertedImage
	if (V_flag==0)
		Display/K=1/n=LIBCurrentConvertedImage;Appendimage LIBCurrentConverted
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan(um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(65000,60000,48600),expand=.7	
		ColorScale/C/N=text0/E/F=0/A=MC image=LIBCurrentConverted
		ModifyImage LIBCurrentConverted ctab= {*,*,VioletOrangeYellow,0}
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "pA"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=LIBCurrentConverted
	endif		
	ModifyGraph/W=LIBCurrentConvertedImage height = {Aspect, scansizeY/scansizeX}
	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=LIBCurrentConvertedImage height = {Aspect, 1}
	endif

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
	
	Make/o/n=(pointsPerPixel) LIBCurrentWaveTemp
	Make/O/N=(scanpoints) LIBCurrentTrace, LIBCurrentTraceBefore, LIBCurrentConvertedTrace
	LIBCurrentTrace = 0
	LIBCurrentTraceBefore = 0
	LIBCurrentConvertedTrace = 0
	
	SetScale/I x ScanFrameWork[0][0], ScanFramework[0][2],"um", LIBCurrentTrace, LIBCurrentTraceBefore, LIBCurrentConvertedTrace
	
	dowindow/f LIBCurrentTraceWindow
	if (V_flag==0)
		Display/K=1/n=LIBCurrentTraceWindow LIBCurrentTrace
		appendtograph LIBCurrentTraceBefore
		ModifyGraph rgb(LIBCurrentTraceBefore)=(0,0,0)
		ModifyGraph lsize=3
		ModifyGraph tick(left)=2,fStyle(left)=1,axThick(left)=2;DelayUpdate
		Label left "Voltage (V)"
		ModifyGraph tick=2,mirror(bottom)=1,fStyle=1,axThick=2;DelayUpdate
		Label bottom "Distance (um)"
		appendtograph /R LIBCurrentConvertedTrace
		ModifyGraph rgb(LIBCurrentConvertedTrace)=(65535,65535,65535)	
		ModifyGraph tick=2,fStyle=1,axThick=2;DelayUpdate
		Label right "Current (pA)"
		Legend/C/N=text1/A=RB
		Legend/C/N=text1/J "\\f01\\s(LIBCurrentTrace) LIBCurrentTrace\r\\s(LIBCurrentTraceBefore) LIBCurrentTraceBefore"
	endif
	
	Make/O/N = (pointsPerLine) LIBCurrentWave
	LIBCurrentWave = NaN


	SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","Ground","DDS")
		
	//stop all FBLoops except for the XY loops
	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
	
	variable error = 0
	td_StopInWaveBank(-1)
	
	SetFeedbackLoop(3, "Always",  "ZSensor", ReadWaveZ[scanpoints-1] - liftheight * 1e-9 / GV("ZLVDTSens"), 0, EFMFilters[%ZHeight][%IGain],0, "Output.Z",0)

	//stop all FBLoops again now that they have been initialized
	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
	
	// Set all DAC outputs to zero initially
	td_wv("Output.A", 0)
	td_wv("Output.B", 0)	
	td_wv("Output.C", 0)	

	if (XFastPL == 1 && YFastPL == 0)	
		if (PL_UseLineNum == 0)
			MoveXY(ScanFramework[0][0], ScanFramework[0][1])
		else
			MoveXY(ScanFramework[0][0], (ypos - scansizeY / 2)  + SlowScanDelta*PLLineNum)
		endif
	elseif (XFastPL == 0 && YFastPL == 1)
		if (PL_UseLineNum == 0)
			MoveXY(ScanFramework[0][1], ScanFramework[0][0])
		else
			MoveXY((xpos - scansizeY / 2)  + SlowScanDelta*PLLineNum, ScanFramework[0][0])
		endif
	endif

	//************************************* XYupdownwave is the final, calculated, scaled values to drive the XY piezos ************************//	
	if (XFastPL == 1 && YFastPL == 0)	//x  scan direction
		XYupdownwave[][][0] = (ScanFrameWork[q][0] + FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][1] = (ScanFrameWork[q][2] - FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][2] = (ScanFrameWork[q][1]) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][3] = (ScanFrameWork[q][3]) / YLVDTsens / 10e5 + YLVDToffset
	elseif (XFastPL == 0 && YFastPL == 1)	
		XYupdownwave[][][2] = (ScanFrameWork[q][0] + FastScanDelta*p) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][3] = (ScanFrameWork[q][2] - FastScanDelta*p) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][0] = (ScanFrameWork[q][1]) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][1] = (ScanFrameWork[q][3]) / XLVDTsens / 10e5 + XLVDToffset
	endif

	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	
	SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Defl","Ground","Ground","OutB","Ground","OutC","DDS")

	td_wv("Output.A", 0)
	td_wv("Output.B", 0)
	td_wv("Output.C", 0)

	td_wv(LockinString + "Amp",CalHardD) 
	td_wv(LockinString + "Freq",CalEngageFreq) //set the frequency to the resonant frequency
	td_wv(LockinString + "FreqOffset",0)
	
	SetFeedbackLoop(2, "Always", "Amplitude", Setpoint, -PGain, -IGain, -SGain, "Height", 0)	

	Sleep/S 1.5
	
	variable heightbefore, heightafter	
	
	///Starting imaging loop here
	i = 0
	
	do

		StopFeedbackLoop(3)	
	
		Sleep/S 1.5

		if (gWGDeviceAddress != 0)
			SetVFSqu(0, ACFrequency,"WG")
		endif

		starttime2 = StopMSTimer(-2) //Start timing the raised scan line
		print "line ", i+1

		if (PL_UseLineNum == 0)
			PLLineNum = i	// flag to scan a whole image, not just a line
		endif

		Xdownwave[] = XYupdownwave[p][PLLineNum][0]	
		Ydownwave[] = XYupdownwave[p][PLLineNum][2]

		// Note that the upwaves don't actually do anything in PL scans
		Xupwave[] = XYupdownwave[p][i][1]
		Yupwave[] = XYupdownwave[p][i][3]

		// ********** TOPO + INTERLEAVE SCAN ***********//
		td_StopInWaveBank(-1)
		td_StopOutWaveBank(-1)
		
		error+= td_xSetInWave(0,"Event.0", "ZSensor", ReadWaveZ,"", Downinterpolation)// used during Trace to record height data		
		error+= td_xSetOutWavePair(0,"Event.0", "$outputXLoop.Setpoint", Xdownwave,"$outputYLoop.Setpoint",Ydownwave ,-DownInterpolation)

		SetPassFilter(1, q = ImagingFilterFreq, i = ImagingFilterFreq)

		td_wv(LockinString + "Amp", CalHardD) 
		td_wv(LockinString + "Freq", CalEngageFreq) //set the frequency to the resonant frequency
		td_wv(LockinString + "FreqOffset", 0)
		td_wv("Output.A", 0)
		td_wv("Output.B", 0)
		td_wv("Output.C",0)
		
		error+= td_WriteString("Event.0", "Once")
		
		starttime3 = StopMSTimer(-2) //Start timing the raised scan line

		CheckInWaveTiming(ReadWaveZ) // Waits until the topography trace has been fully collected.

		Sleep/S .05
		
		//ReadWaveZback is the drive wave for the z piezo		
		ReadWaveZback[] = ReadwaveZ[scanpoints-1-p] - liftheight * 1e-9 / GV("ZLVDTSens")
		ReadWaveZOffset[] = ReadWaveZ - liftheight*1e-9 / GV("ZLVDTSens")
		Topography[][i] = -(ReadwaveZ[p] * ZLVDTSens-Mean(ReadwaveZ) * ZLVDTSens)
		DoUpdate
		
		//****************************************************************************
		//** INTERLEAVED VOLTAGE AT LIFT HEIGHT
		//****************************************************************************

		td_stopInWaveBank(-1)
		td_stopOutWaveBank(-1)
		heightbefore = td_rv("Zsensor")*td_rv("ZLVDTSens")		

		StopFeedbackLoop(2)		
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-500*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0, name="OutputZ") // note the integral gain of 10000
		sleep/S 0.5
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0, name="OutputZ", arcZ=1) // note the integral gain of 10000
		sleep/S 0.5
		heightafter = td_rv("Zsensor")*td_rv("ZLVDTSens")

		error+= td_xSetInWave(0,"Event.2", "ZSensor", ReadWaveZInterleave,"", Downinterpolation)// used during Trace to record height data	
		error+= td_xsetoutwavePair(1,"Event.2", "$outputXLoop.Setpoint", Xupwave,"$outputYLoop.Setpoint", Yupwave,-DownInterpolation)

		if (stringmatch("ARC.Lockin.0." , LockinString))
			error+= td_xsetoutwave(2, "Event.2", "ARC.PIDSLoop.3.Setpoint", ReadWaveZback, -DownInterpolation)
		else
			error+= td_xsetoutwave(2, "Event.2", "Cypher.PIDSLoop.3.Setpoint", ReadWaveZback, -DownInterpolation)
		endif			

		td_wv((LockinString + "Amp"), calsoftd) //set the amplitude from the grab tune function
		td_wv((LockinString + "Freq"), CalResFreq) //set the frequency to the resonant frequency
		td_wv((LockinString + "PhaseOffset"), CalPhaseOffset)  // phase offset also comes from calibration panel
		
		td_wv("Output.C", VoltageAtLine)

		error += td_WriteString("Event.2", "Once")
		
		CheckInWaveTiming(ReadWaveZInterleave)

		td_wv("Output.C", 0)
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[0]-500*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0, name="OutputZ", arcZ=1) // note the integral gain of 10000

		if (gWGDeviceAddress != 0)
			SetVFSqu(5, ACFrequency,"WG")
		endif
		Sleep/S 0.1
				
		//**********************************************************//
		//**************** PL SCAN *****************************//
		//**********************************************************//
		
		td_stopInWaveBank(-1)
		td_stopOutWaveBank(-1)
		
		MoveXY(ScanFramework[i][0], ScanFramework[i][1])

		td_xSetInWave(0, "Event.1", "Input.B", LIBCurrentWave,"", 1) 
		td_xSetOutWavePair(0, "Event.1", "PIDSLoop.0.Setpoint", Xdownwave, "PIDSLoop.1.Setpoint", Ydownwave , -UpInterpolation)
						
		Sleep/S .5	
				
		//Fire retrace event here
		error += td_WriteString("Event.1", "Once")

		CheckInWaveTiming(LIBCurrentWave)
		Sleep/S .05

		//**********************************************************************************
		//***  PROCESS DATA AND UPDATE GRAPHS
		//*******************************************************************************
		
		j = 0
		do
			LIBCurrentWaveTemp = 0
			k = 0
			l = j * pointsPerPixel
				do
					LIBCurrentWaveTemp[k] = LIBCurrentWave[l]
					k += 1
					l += 1
				while (k < pointsPerPixel)
		
			LIBCurrent[j][i] = mean(LIBCurrentWaveTemp)
			LIBCurrentConverted[j][i]=(LIBCurrent[j][i]*LIAsens/10.0)
			j += 1
		while (j < scanpoints)

		if(i>0)
			LIBCurrentTraceBefore=LIBCurrentTrace
		endif
		
		LIBCurrentTrace = LIBCurrent[p][i]
		LIBCurrentConvertedTrace  = LIBCurrentConverted[p][i]
		
		if (i < scanlines)		
			DoUpdate 
			td_stopInWaveBank(-1)
			td_stopoutwavebank(0)

			td_wv(LockinString + "Amp",CalHardD) 
			td_wv(LockinString + "Freq",CalEngageFreq) //set the frequency to the resonant frequency
			td_wv(LockinString + "FreqOffset",0)
			
			SetFeedbackLoop(2, "Always", "Amplitude", Setpoint, -PGain, -IGain, -SGain, "Height", 0)
		endif 
	
		i += 1
		
		LIBCurrentWave[] = NaN
		
			
	while (i < scanlines )	
	
	if (error != 0)
		print "there was some setinoutwave error during this program"
	endif
	
	DoUpdate		

	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	Beep
	setdatafolder savDF
End

