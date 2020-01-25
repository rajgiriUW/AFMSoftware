#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ImageScanSKPM(xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed)
	
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
	
	
	Make/O/N = (scanpoints, scanlines) Topography, CPDImage

	if (XFastEFM == 1 && YFastEFM == 0)
		SetScale/I x, ScanFrameWork[0][0], ScanFramework[0][2], "um", Topography, CPDImage
		if(scanlines==1)
			SetScale/I y, ypos, ypos, Topography, CPDImage
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, CPDImage
		endif
	

	elseif (XFastEFM == 0 && YFastEFM == 1)
		SetScale/I x, ScanFrameWork[0][2], ScanFramework[0][0], "um", Topography, CPDImage
		if(scanlines==1)
			SetScale/I y, ypos, ypos, Topography, CPDImage
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, CPDImage
		endif
	
	endif

	if(mod(scanpoints,32) != 0)									//Scan aborts if scanpoints is not divisible by 32 PC 4/29/14
		abort "Scan Points must be divisible by 32"
	endif
	
	Make/O/N = (scanpoints) ReadWaveZ, ReadWaveZback, Xdownwave, Ydownwave, Xupwave, Yupwave
	Make/O/N = (scanpoints, scanlines, 4) XYupdownwave
	ReadWaveZ = NaN

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

	GPIBsetup()
	
	Variable lockinsens=GetLockinSens()
	
	SetLockinTimeC(LockinTimeConstant/1000) //the user specifies the Lockin time constant, and this call sets it, making sure 
	setLPslope(2) // 0 is 6dB, 1 is 12dB, 2 is 18dB, and 3 is 24 dB
	setSync(0) // 0 is off and 1 is on
	setFloat0orGround1(1) //0 is float and 1 is ground
	setNotch(0) //0 is neither, 1 is 60hz, 2 is 120hz, and 3 is both
	setReserve(0) //0 is high, 1 is normal, 2 is low
	setChanneliOutputtoj(1,1) //output x on channel 1
	setChanneliDisplayj(1, 0) //display x on channel 1
	//setLockinPhase(-9) //this phase is selected for a frequency of 1000 hz
	setLockinPhase(-100)
	setLockinSensitivity(LockinSensitivity) // 17 sets the sensitivity of the lockin to 1mv/na //20 is a good value
	sendLockinString("FMOD0") //sets source to external 

	if (gWGDeviceAddress != 0)
		Setvf(0, ACFrequency,"WG")
	else
		TurnOffAWG()
	
	endif
	
	Make/O/N=(scanpoints) CPDTrace, CPDTraceBefore
	Variable pointsPerPixel = timeperpoint * samplerate * 1e-3
	Variable pointsPerLine = pointsPerPixel * scanpoints
	make/o/n=(pointsPerPixel) CPDWaveTemp
	
	variable lastvoltage, lk, ll
	make/o/n=(pointsPerPixel) CPDWaveLastPoint
	
	Variable timeofscan = timeperpoint * 1e-3 * scanpoints
	Upinterpolation = (timeofscan * samplerate) / (scanpoints)
	print timeofscan, upinterpolation, lockintimeConstant, lockinsensitivity

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
		
	// HStrEFM needs no FBL on the LIA phase angle	

	SetPassFilter(1,q=EFMFilters[%KP][%q],i=EFMFilters[%KP][%i],a=EFMFilters[%KP][%A],b=EFMFilters[%KP][%B])
	
	SetFeedbackLoop(5, "Always", LockinString+"theta", td_rv(LockinString+"theta"), freq_PGain, freq_IGain, freq_DGain, "Output.A", 0)
	SetFeedbackLoop(4, "Always", "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], 0, "Output.B", 0)	
	SetFeedbackLoop(3, "Always",  "ZSensor", ReadWaveZ[scanpoints-1] - liftheight * 1e-9 / GV("ZLVDTSens"), 0, EFMFilters[%ZHeight][%IGain],0, "Output.Z",0)
	
	//stop all FBLoops again now that they have been initialized
	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
	
	// Set all DAC outputs to zero initially
	td_wv("Output.A", 0)
	td_wv("Output.B", 0)	
	//******************  EEEEEEEEEEEEEEEEEEE *******************************//	
	
	//******************  FFFFFFFFFFFFFFFFFFFFFF *******************************//
	
	//pre-loop initialization, done only once
	//move to initial scan point
	if (XFastEFM == 1 && YFastEFM == 0)	
		MoveXY(ScanFramework[0][0], ScanFramework[0][1])
	elseif (XFastEFM == 0 && YFastEFM == 1)
		MoveXY(ScanFramework[0][1], ScanFramework[0][0])
	endif

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
		
		td_xSetInWave(0,"Event.0", "ZSensor", ReadWaveZ,"", Downinterpolation)	
			
		td_xSetOutWavePair(0, "Event.0", "PIDSLoop.0.Setpoint", Xdownwave, "PIDSLoop.1.Setpoint", Ydownwave , -DownInterpolation)

		
		SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","Ground","DDS")

		SetPassFilter(1, q = ImagingFilterFreq, i = ImagingFilterFreq)

		td_wv(LockinString + "Amp", CalHardD) 
		td_wv(LockinString + "Freq", CalEngageFreq) //set the frequency to the resonant frequency
		td_wv(LockinString + "FreqOffset", 0)
		td_wv("Output.A", 0)
		td_wv("Output.B", 0)

		if (gWGDeviceAddress != 0)
			setvf(0, ACFrequency,"WG")
		else
			TurnOffAWG()
		endif
		
		// START TOPOGRAPHY SCAN
		print "Topo linescan starts"
		error+= td_WriteString("Event.0", "Once")
	
		starttime3 = StopMSTimer(-2) //Start timing the raised scan line

		CheckInWaveTiming(ReadWaveZ) // Waits until the topography trace has been fully collected.
		print "Topo linescan finished"
		Sleep/S .05
		
		//ReadWaveZback is the drive wave for the z piezo		
		ReadWaveZback[] = ReadwaveZ[scanpoints-1-p] - liftheight * 1e-9 / GV("ZLVDTSens")
		ReadWaveZmean = Mean(ReadwaveZ) * ZLVDTSens
		Topography[][i] = -(ReadwaveZ[p] * ZLVDTSens-ReadWaveZmean)
		DoUpdate
	
		//****************************************************************************
		//*** SET DATA COLLECTION STUFF.
		//*****************************************************************************		
		td_stopInWaveBank(-1)
		td_stopOutWaveBank(-1)
		td_xSetInWave(1, "Event.2", "Output.B", CPDWave,"", -1) 
		 
		heightbefore = td_rv("Zsensor")*td_rv("ZLVDTSens")
		 
		//stop amplitude FBLoop and 
		StopFeedbackLoop(2)		
		SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","In0","DDS")
		
		// to keep tip from being stuck
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-500*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
		sleep/s .5

		//start height FB for retrace
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"), 0, EFMFilters[%ZHeight][%IGain], 0, "Output.Z", 0)
		sleep/s .5
		
		heightafter = td_rv("Zsensor")*td_rv("ZLVDTSens")
		print "The lift height is", (heightbefore-heightafter)*1e9, " nm"
		
		td_wv((LockinString + "Amp"), calsoftd) //set the amplitude from the grab tune function
		td_wv((LockinString + "Freq"), CalResFreq) //set the frequency to the resonant frequency
		td_wv((LockinString + "PhaseOffset"), CalPhaseOffset)  // phase offset also comes from calibration panel
		
		error+= td_xsetoutwavePair(1, "Event.2", "ARC.PIDSLoop.0.Setpoint", Xupwave, "ARC.PIDSLoop.1.Setpoint", Yupwave, -UpInterpolation)	
		error+= td_xsetoutwave(2, "Event.2", "ARC.PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)

		SetPassFilter(1, q = EFMFilters[%KP][%q], i = EFMFilters[%KP][%i])
		
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
			td_wv("Output.B", lastvoltage) //get the intial tip voltage close to where it was before
		endif
		
		SetFeedbackLoop(5, "Always", LockinString+"theta", td_rv(LockinString+"theta"), freq_PGain, freq_IGain, freq_DGain, "Output.A", 0)

		if (gWGDeviceAddress != 0)
			setvf(ACVoltage, ACFrequency,"WG")		
		else
			loadarbwave(ACFrequency, ACVoltage)	
		endif

		sleep/S 1/4
		
		//auto set LIA phase
		if (i == 0)
				td_wv("Output.B", 3) 
				setLockinTimeC(100/1000) //Tc100ms
				sleep/S 1/4
				setAutoPhase()
				sleep/S 1.0
				setLockinTimeC(LockinTimeConstant / 1000)
				td_wv("Output.B", 0) 
				sleep/S 1/4
		endif
		
		sleep/S 1/4

		SetFeedbackLoop(4, "always",  "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], EFMFilters[%KP][%DGain], "Output.B", 0) 
		sleep/S 1/4
		
		print "CPD linescan starts"
		
		//Fire retrace event here
		error += td_WriteString("Event.2", "Once")
		
		//abort
		
		CheckInWaveTiming(CPDWave)
	
		print "CPD linescan finished"

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
			
			td_wv(LockinString + "Amp", CalHardD) 
			td_wv(LockinString + "Freq", CalEngageFreq)
			td_wv(LockinString + "FreqOffset", 0)	
				
			SetFeedbackLoop(2, "Always", "Amplitude", Setpoint, -PGain, -IGain, -SGain, "Height", 0)	
				
		endif 
	
		scantimes[i] = (StopMSTimer(-2) -starttime2)*1e-6
		print "Time for last scan line (seconds) = ", scantimes[i], " ; Time remaining (in minutes): ", scantimes[i]*(scanlines-i-1) / 60
		i += 1
		
		//Reset the primary inwaves to Nan so that gl_checkinwavetiming function works properly
		CPDWaveLast[] = CPDWave[p]
		ReadWaveZ[] = NaN
		CPDWave[] = NaN
				
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

	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	
	if (useLineNUm != 0)
	
		display ScanTimes
		Label left "Scan time (s)";DelayUpdate
		Label bottom "Scan Line (#)"
	endif
	
	Beep
	doscanfunc("stopengage")
	setdatafolder savDF

End


Function PointScanSKPM(xpos, ypos, liftheight,dwelltime)

	Variable xpos, ypos, liftheight,dwelltime
	
	String  savDF = GetDataFolder(1)
	
	Wave timekeeper=root:Packages:trEFM:PointScan:timekeeper
	
	SetDataFolder root:Packages:trEFM
	Nvar pgain, sgain, igain, adcgain, setpoint, adcgain
	NVAR XLVDTSens, YLVDTSens, ZLVDTSens, XLVDToffset, YLVDToffset, ZLVDToffset
	NVAR xigain, yigain, zigain
	Svar LockinString
	Wave EFMFilters = root:packages:trEFM:EFMFilters
	GetGlobals()
	
	SetDataFolder root:Packages:trEFM:VoltageScan
	Nvar calsoftd, calresfreq, calphaseoffset, calengagefreq, calhardd
	ResetAll()

	SetDataFolder root:packages:trEFM:PointScan:SKPM
	variable/G freq_PGain
	variable/G freq_IGain 
	variable/G freq_DGain
	
	wave Bias
	//Bias=0
	
	//SetDataFolder root:packages:trEFM:WaveGenerator
	//Wave gentipwave, gentriggerwave
	//commitdrivewaves()
	SetDataFolder root:Packages:trEFM:PointScan:SKPM
	
	////////////////////////// CALC INPUT/OUTPUT WAVES \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	Variable SKPMInterpolation = 2
	Variable CPDWavePoints = dwelltime * (50000 / SKPMInterpolation)
	CPDWavePoints = CPDWavePoints- mod(CPDWavePoints,32)

	Make/O/N = (CPDWavePoints) CPDwave // 800 points = 16 milliseconds at 50kHz sample rate
	
	CPDwave = NaN // set to NaN so we can use a procedure to determine when it is filled.

	//////////////////////////    SETTINGS   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	
	ResetAll()

	// SKPM Variables.
	NVAR LockinTimeConstant
	NVAR LockinSensitivity
	NVAR ACFrequency
	NVAR ACVoltage
	NVAR TimePerPoint

	variable SKPpgain, SKPigain, lockinsens

	SetPassFilter(1,a=EFMFilters[%EFM][%A],b=EFMFilters[%EFM][%B],fast=EFMFilters[%EFM][%Fast],i=EFMFilters[%EFM][%i],q=EFMFilters[%EFM][%q])

	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)

	td_WriteValue("Output.A", 0)
	td_WriteValue("Output.B", 0)

	MoveXY(xpos, ypos) // move to xy position, though keep raised up
	
	////////////////////////// SET SKPM HARDWARE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	
	GPIBsetup()
	lockinsens = GetLockinSens()

	SetLockinTimeC(LockinTimeConstant/1000) //the user specifies the Lockin time constant, and this call sets it, making sure 
	setLPslope(3) // 0 is 6dB, 1 is 12dB, 2 is 18dB, and 3 is 24 dB
	setSync(1) // 0 is off and 1 is on
	setFloat0orGround1(0) //0 is float and 1 is ground
	setNotch(3) //0 is neither, 1 is 60hz, 2 is 120hz, and 3 is both
	setReserve(1) //0 is high, 1 is normal, 2 is low
	setChanneliOutputtoj(1,1) //output x on channel 1
	setChanneliDisplayj(1, 0) //display x on channel 1
	//setLockinPhase(-9) //this phase is selected for a frequency of 1000 hz
	
	setLockinSensitivity(LockinSensitivity) // 17 sets the sensitivity of the lockin to 1mv/na //20 is a good value
	sendLockinString("FMOD0") //sets source to external 

	Setvf(0, ACFrequency,"WG")
	
	SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","In0","DDS")
	
	// Keep x pos of tip constant for SKPM
	//SetFeedbackLoop(0, "Always", "XSensor", xpos / XLVDTsens / 10e5 + XLVDToffset, 0, xIgain, 0, "Output.X", 0)

	td_wv((LockinString + "Amp"), CalHardD) //set the frequency to the resonant frequency
	td_wv((LockinString + "Freq"), CalEngageFreq) //set the frequency to the resonant frequency
	
	// ALL SCAN MODES require the ampitude of the oscillation to remain constant by adjust the tip height above the sample
	SetFeedbackLoop(2, "Always", "Amplitude", Setpoint, -PGain, -IGain, -SGain, "Height", 0)
	Sleep/s .5

	//*********************** DO THE SCAN************//	
	Variable resetFreqOffset = td_rv((LockinString + "FreqOffset"))
	
	// Read the data from output.b
	td_xSetInWave(1,"Event.2", "Output.B", CPDwave, "", -2)

	Variable currentz = td_rv("Zsensor")*td_rv("ZLVDTSens")
	
	//stop amplitude FBLoop and 
	StopFeedbackLoop(2)	
	
	//Variable currentz = td_rv("Zsensor")*td_rv("ZLVDTSens")
	
	SetPassFilter(1, fast=EFMFilters[%KP][%fast], i=EFMFilters[%KP][%i], q=EFMFilters[%KP][%q])	
	
	Variable startTime = StopMSTimer(-2)
		
	// to keep tip from being stuck
	SetFeedbackLoop(3, "always",  "ZSensor", currentz-500*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0)
	sleep/s .5
	
	//raise up the amount specified in the Height box of the efm_sloth tab
	SetFeedbackLoop(3, "always",  "ZSensor", (currentz-(liftheight*1e-9))/GV("ZLVDTSens"), 0, EFMFilters[%ZHeight][%IGain], 0, "Output.Z", 0)
	sleep/s .5
	
	variable heightafter = td_rv("Zsensor")*td_rv("ZLVDTSens")
	sleep/s .5
	print "Lift value (nm)", (currentz-heightafter)*1e9
	

	td_wv((LockinString + "Amp"), calsoftd) //set the amplitude from the grab tune function
	td_wv((LockinString + "Freq"), CalResFreq) //set the frequency to the resonant frequency
	td_wv((LockinString + "PhaseOffset"), CalPhaseOffset)  // phase offset also comes from calibration panel
	
	wavestats/Q CPDwave
	td_writevalue("Output.B", V_avg) // set voltage
	
	// Wait this extra time for frequency to stablize, but note we have already waited some anyway
	startTime = StopMSTimer(-2)
	do 
	while((StopMSTimer(-2) - StartTime) < 10*1e3) 
	
	//Output a Sin wave with this voltage and frequency.
	setvf(ACVoltage, ACFrequency,"WG")
	
	Sleep/S .2 
	
	// Keep phase constant by manipulating output.A 
	SetFeedbackLoop(5, "Always", LockinString + "theta", td_RV(LockinString + "theta"), freq_PGain, freq_IGain, freq_DGain, "Output.A", 0)
	
	//auto set LIA phase
	td_wv("Output.B", 3) 
	setLockinTimeC(100/1000) //Tc100ms
	sleep/S 1/4
	setAutoPhase()
	sleep/S 1.0
	setLockinTimeC(LockinTimeConstant / 1000)
	td_wv("Output.B", 0) 
	sleep/S 1/4
		
	//Keep Input.B at 0 by manipulating Output.B
	SetFeedbackLoop(4, "always",  "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], EFMFilters[%KP][%DGain], "Output.B", 0) 

	Sleep/S .5

	// fire event that starts the data collection
	td_WriteString("Event.2", "Once")
	
//Abort
	
	// Wait until data has been collected
	CheckInWaveTiming(CPDwave)
			
	variable heightafterscan = td_rv("Zsensor")*td_rv("ZLVDTSens")
	sleep/s .5
	print "Lift drift (nm)", (heightafterscan-heightafter)*1e9
			
	//stop collecting data
	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)		
	
	td_wv("Output.A",0)
	td_wv("Output.B",0)
			
	DoUpdate
	
	//Turn off the sine wave that we were sending.
	SetEFMvf(0, ACFrequency, sleeptime=0)	
		
	td_wv((LockinString + "FreqOffset"), resetFreqOffset)	
	td_wv((LockinString + "Amp"), CalHardD) //set the frequency to the resonant frequency
	td_wv((LockinString + "Freq"), CalEngageFreq)
	td_wv((LockinString + "PhaseOffset"), CalPhaseOffset)
			
	SetPassFilter(1, fast = 1000, i = 1000, q = 1000)
	
	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
	
	td_wv((LockinString + "Freq"), CalResFreq)
	td_wv((LockinString + "FreqOffset"), 0)
	
	SetFeedbackLoop(2, "Always", "Amplitude", Setpoint, -PGain, -IGain, -SGain, "Height", 0)

	startTime = StopMSTimer(-2)	
	do  // waiting loop till we recontact surface
		doUpdate
	while((StopMSTimer(-2) - StartTime) < 1e6*.2)
	
	//***************  END SCAN *****************************//

	
	// ********************  NOW DISPLAY THE DATA **************************** ///
		
	//Display  root:packages:trEFM:PointScan:SKPM:CPDwave
		
	dowindow/f CPDvsTime
	if (V_flag==0)
	//	Display/K=1/n=CPDvsTime;Append root:packages:trEFM:PointScan:SKPM:CPDwave
	endif
	
	DoWindow/F CPDvsTIME
	if(v_flag == 0)
		display/l/K=1/b/N=CPDvsTIME  root:packages:trEFM:PointScan:SKPM:CPDwave
			
		Label/W=CPDvsTIME left "CPD (Volts)"
		Label/W=CPDvsTIME bottom "Time (s)"
					
		ModifyGraph/W=CPDvsTIME lsize=2,rgb=(0,39168,0)
		ModifyGraph/W=CPDvsTIME fStyle=1,fSize=14
		ModifyGraph/W=CPDvsTIME gbRGB = (65535,65535,65535)
		ModifyGraph/W=CPDvsTIME wbRGB = (65535,65535,65535)
	endif
	
	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	Beep
	doscanfunc("stopengage")
	setdatafolder savDF
	
End



Function PointScanSKPMVoltagePulse(xpos, ypos, liftheight,dwelltime, appliedbias, biasfreq)

	Variable xpos, ypos, liftheight,dwelltime, appliedbias, biasfreq
	
	String  savDF = GetDataFolder(1)
	
	Wave timekeeper=root:Packages:trEFM:PointScan:timekeeper
	
	SetDataFolder root:Packages:trEFM
	Nvar pgain, sgain, igain, adcgain, setpoint, adcgain
	NVAR XLVDTSens, YLVDTSens, ZLVDTSens, XLVDToffset, YLVDToffset, ZLVDToffset
	NVAR xigain, yigain, zigain
	Svar LockinString
	Wave EFMFilters = root:packages:trEFM:EFMFilters
	GetGlobals()
	
	SetDataFolder root:Packages:trEFM:VoltageScan
	Nvar calsoftd, calresfreq, calphaseoffset, calengagefreq, calhardd
	ResetAll()

	SetDataFolder root:packages:trEFM:PointScan:SKPM
	variable/G freq_PGain
	variable/G freq_IGain 
	variable/G freq_DGain
	
	//SetDataFolder root:Packages:trEFM:WaveGenerator
	//Wave gentipwave, gentriggerwave
	//commitdrivewaves()
	
	SetDataFolder root:Packages:trEFM:PointScan:SKPM
	
	////////////////////////// CALC INPUT/OUTPUT WAVES \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	Variable SKPMInterpolation = 2
	Variable CPDWavePoints = dwelltime * (50000 / SKPMInterpolation)
	CPDWavePoints = CPDWavePoints- mod(CPDWavePoints,32)

	Make/O/N = (CPDWavePoints) CPDwave // 800 points = 16 milliseconds at 50kHz sample rate
	
Make/O/N = (CPDWavePoints) Phase, Bias 
	
	CPDwave = NaN // set to NaN so we can use a procedure to determine when it is filled.

	//////////////////////////    SETTINGS   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	
	ResetAll()

	// SKPM Variables.
	NVAR LockinTimeConstant
	NVAR LockinSensitivity
	NVAR ACFrequency
	NVAR ACVoltage
	NVAR TimePerPoint

	variable SKPpgain, SKPigain, lockinsens

	SetPassFilter(1,a=EFMFilters[%EFM][%A],b=EFMFilters[%EFM][%B],fast=EFMFilters[%EFM][%Fast],i=EFMFilters[%EFM][%i],q=EFMFilters[%EFM][%q])

	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)

	td_WriteValue("Output.A", 0)
	td_WriteValue("Output.B", 0)
	td_WriteValue("Output.C", 0)

	MoveXY(xpos, ypos) // move to xy position, though keep raised up
	
	////////////////////////// SET SKPM HARDWARE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	
	GPIBsetup()
	lockinsens = GetLockinSens()

	SetLockinTimeC(LockinTimeConstant/1000) //the user specifies the Lockin time constant, and this call sets it, making sure 
	setLPslope(2) // 0 is 6dB, 1 is 12dB, 2 is 18dB, and 3 is 24 dB
	setSync(0) // 0 is off and 1 is on
	setFloat0orGround1(1) //0 is float and 1 is ground
	setNotch(0) //0 is neither, 1 is 60hz, 2 is 120hz, and 3 is both
	setReserve(0) //0 is high, 1 is normal, 2 is low
	setChanneliOutputtoj(1,1) //output x on channel 1
	setChanneliDisplayj(1, 0) //display x on channel 1
	//setLockinPhase(-9) //this phase is selected for a frequency of 1000 hz
	setLockinPhase(-100)
	setLockinSensitivity(LockinSensitivity) // 17 sets the sensitivity of the lockin to 1mv/na //20 is a good value
	sendLockinString("FMOD0") //sets source to external 

	Setvf(0, ACFrequency,"WG")
	
	SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","In0","DDS")
	
	// Keep x pos of tip constant for SKPM
	//SetFeedbackLoop(0, "Always", "XSensor", xpos / XLVDTsens / 10e5 + XLVDToffset, 0, xIgain, 0, "Output.X", 0)

	td_wv((LockinString + "Amp"), CalHardD) //set the frequency to the resonant frequency
	td_wv((LockinString + "Freq"), CalEngageFreq) //set the frequency to the resonant frequency
	
	// ALL SCAN MODES require the ampitude of the oscillation to remain constant by adjust the tip height above the sample
	SetFeedbackLoop(2, "Always", "Amplitude", Setpoint, -PGain, -IGain, -SGain, "Height", 0)
	Sleep/s .5

	//*********************** DO THE SCAN************//	
	Variable resetFreqOffset = td_rv((LockinString + "FreqOffset"))
	
	// Read the data from output.b
	td_xSetInWave(1,"Event.2", "Output.B", CPDwave, "", -2)
	
	//read the LIA output
	td_xSetInWave(2,"Event.2", "Input.B", Phase, "", -2)
	
	//apply a bias to the sample from output.C
	wavegeneratoroffset(appliedbias,biasfreq,"Output.C","Event.2,repeat",0)  //wavegenerator(amplitude,frequency,outputletter,event,bank)  //note with C%ouput we can't go faster than 78hz
	// read the applied bias
	td_xSetInWave(0,"Event.2", "Output.C", Bias, "", -2)
	
	Variable currentz = td_rv("Zsensor")*td_rv("ZLVDTSens")
		
	//stop amplitude FBLoop and 
	StopFeedbackLoop(2)	
	
	SetPassFilter(1, fast=EFMFilters[%KP][%fast], i=EFMFilters[%KP][%i], q=EFMFilters[%KP][%q])	
	
	// to keep tip from being stuck
	SetFeedbackLoop(3, "always",  "ZSensor", currentz-500*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0)
	sleep/s .5

	//raise up the amount specified in the Height box of the efm_sloth tab
	SetFeedbackLoop(3, "always",  "ZSensor", (currentz-(liftheight*1e-9))/GV("ZLVDTSens"), 0, EFMFilters[%ZHeight][%IGain], 0, "Output.Z", 0)
	sleep/s .5
	
	variable heightafter = td_rv("Zsensor")*td_rv("ZLVDTSens")
	sleep/s .5
	print "Lift value (nm)", (currentz-heightafter)*1e9
	

	td_wv((LockinString + "Amp"), calsoftd) //set the amplitude from the grab tune function
	td_wv((LockinString + "Freq"), CalResFreq) //set the frequency to the resonant frequency
	td_wv((LockinString + "PhaseOffset"), CalPhaseOffset)  // phase offset also comes from calibration panel
	td_writevalue("Output.B", 0) // set voltage
	
	// Wait this extra time for frequency to stablize, but note we have already waited some anyway
	 Variable startTime = StopMSTimer(-2)
	do 
	while((StopMSTimer(-2) - StartTime) < 10*1e3) 
	
	//Output a Sin wave with this voltage and frequency.
	setvf(ACVoltage, ACFrequency,"WG")
	sleep/S 1/4
	
	// Keep phase constant by manipulating output.A 
	SetFeedbackLoop(5, "Always", LockinString + "theta", td_RV(LockinString + "theta"), freq_PGain, freq_IGain, freq_DGain, "Output.A" , 0)
	
	//auto set LIA phase
	td_wv("Output.B", 3) 
	setLockinTimeC(100/1000) //Tc100ms
	sleep/S 1/4
	setAutoPhase()
	sleep/S 1.0
	setLockinTimeC(LockinTimeConstant / 1000)
	td_wv("Output.B", 0) 
	sleep/S 1/4
	
	//Keep Input.B at 0 by manipulating Output.B
	SetFeedbackLoop(4, "always",  "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], EFMFilters[%KP][%DGain], "Output.B", 0) 
	
	Sleep/S .5
	
	// fire event that starts the data collection
	td_WriteString("Event.2", "Once")
	
//Abort
	
	// Wait until data has been collected
	CheckInWaveTiming(CPDwave)
			
	variable heightafterscan = td_rv("Zsensor")*td_rv("ZLVDTSens")
	sleep/s .5
	print "Drift (nm)", (heightafterscan-heightafter)*1e9
			
	//stop collecting data
	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)		
	
	td_wv("Output.A",0)
	td_wv("Output.B",0)
td_wv("Output.C",0)
			
	DoUpdate
	
	//Turn off the sine wave that we were sending.
	SetEFMvf(0, ACFrequency, sleeptime=0)	
		
	td_wv((LockinString + "FreqOffset"), resetFreqOffset)	
	td_wv((LockinString + "Amp"), CalHardD) //set the frequency to the resonant frequency
	td_wv((LockinString + "Freq"), CalEngageFreq)
	td_wv((LockinString + "PhaseOffset"), CalPhaseOffset)
			
	SetPassFilter(1, fast = 1000, i = 1000, q = 1000)
	
	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
	
	td_wv((LockinString + "Freq"), CalResFreq)
	td_wv((LockinString + "FreqOffset"), 0)
	
	SetFeedbackLoop(2, "Always", "Amplitude", Setpoint, -PGain, -IGain, -SGain, "Height", 0)

	startTime = StopMSTimer(-2)	
	do  // waiting loop till we recontact surface
		doUpdate
	while((StopMSTimer(-2) - StartTime) < 1e6*.2)
	
	//***************  END SCAN *****************************//

	
	// ********************  NOW DISPLAY THE DATA **************************** ///
		
	//Display  root:packages:trEFM:PointScan:SKPM:CPDwave
		
	DoWindow/F CPDvsTIME
	if(v_flag == 0)
		display/l/K=1/b/N=CPDvsTIME  root:packages:trEFM:PointScan:SKPM:CPDwave
		appendtograph/W=CPDvsTIME /R Bias
				
		Label/W=CPDvsTIME left "CPD (Volts)"
		Label/W=CPDvsTIME bottom "Time (s)"
		Label/W=CPDvsTIME  right "Applied Bias"
					
		ModifyGraph/W=CPDvsTIME lsize=2,rgb=(0,39168,0)
		ModifyGraph/W=CPDvsTIME fStyle=1,fSize=14
		ModifyGraph/W=CPDvsTIME gbRGB = (65535,65535,65535)
		ModifyGraph/W=CPDvsTIME  rgb(Bias)=(65280,0,0)
		ModifyGraph/W=CPDvsTIME axRGB(right)=(65280,0,0)
		ModifyGraph/W=CPDvsTIME axRGB(left)=(0,39168,19712)
		ModifyGraph/W=CPDvsTIME axThick=2
		ModifyGraph/W=CPDvsTIME tick(bottom)=2,mirror(bottom)=1
	endif
	
	DoWindow/F PhasevsTIME
	if(v_flag == 0)
		display/l/K=1/b/N=PhasevsTIME  root:packages:trEFM:PointScan:SKPM:Phase
		appendtograph/W=PhasevsTIME /R Bias
				
		Label/W=PhasevsTIME left "Phase (Volts)"
		Label/W=PhasevsTIME bottom "Time (s)"
		Label/W=PhasevsTIME  right "Applied Bias"
					
		ModifyGraph/W=PhasevsTIME lsize=2,rgb=(0,39168,0)
		ModifyGraph/W=PhasevsTIME fStyle=1,fSize=14
		ModifyGraph/W=PhasevsTIME gbRGB = (65535,65535,65535)
		ModifyGraph/W=PhasevsTIME  rgb(Bias)=(65280,0,0)
		ModifyGraph/W=PhasevsTIME rgb(Phase)=(0,0,52224)
		ModifyGraph/W=PhasevsTIME axRGB(right)=(65280,0,0)
		ModifyGraph/W=PhasevsTIME axRGB(left)=(0,0,52224)
		ModifyGraph/W=PhasevsTIME axThick=2
		ModifyGraph/W=PhasevsTIME tick(bottom)=2,mirror(bottom)=1
	endif
	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	Beep
	doscanfunc("stopengage")
	setdatafolder savDF
	
End


Function PointScanIMFMSKPM(amplitude)

	variable amplitude
	
	string savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	
	Wave CPDwave
	
	Variable/G iteration_tracker
	iteration_tracker = 0
	
	String/G folder_path
	NewPath folder_path
	
	variable/G current_freq
	String/G skpm_path

	//////////////////////////////////////////////////////////
	Variable numberOfFreq= 25
	Make/O/N=(numberOfFreq) frequency_list
	variable lowfreq = 0.5
	variable firstfreq = 1
	variable lastfreq = 10000000
	/////////////////////////////////////////////////////////////
		
	variable interv=(lastfreq/firstfreq)^(1/(numberOfFreq-1))	
	variable i,j
	for(i=0; i<numberOfFreq; i+=1)
		frequency_list[i]=firstfreq*interv^(i)
	endfor	
		
	variable wave_points = DimSize(CPDwave,0)
	Make/O/N=(wave_points,numberOfFreq) IMWaves, MilliWaves
	IMWaves=0
	MilliWaves=0
	
	String savDF2 = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	Nvar DwellTime
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	SetDataFolder savDF2
	
	for(i=0; i<numberOfFreq; i+=1)
		
		SetVFSquBis(amplitude, lowfreq, "11" )
		print "the current frequency is:",lowfreq,"Hz"
		sleep/s .1
		PointScanSKPM(gxpos, gypos, liftheight, DwellTime)
		GetCurrentPosition()
		MilliWaves[][iteration_tracker] = CPDwave[p]
	
		SetVFSquBis(amplitude, frequency_list[i], "11" )
		print "the current frequency is:", frequency_list[i],"Hz (",i+1,"/",numberOfFreq,")"
		sleep/s .1
		PointScanSKPM(gxpos, gypos, liftheight, DwellTime)
		GetCurrentPosition()
		
		IMWaves[][iteration_tracker] = CPDwave[p]
		
		iteration_tracker+=1
		
		averageIMSKPMdata(numberOfFreq)
		NetAverageIMSKPMdata(numberOfFreq)
		NetAverageIMSKPMdata2(numberOfFreq)
		NormNetAverageIMSKPMdata(numberOfFreq)

	endfor
	
	//SetVFSquBis(0.01, 1, "11" )
	SetVFSquBis(5, 1, "11" )
	
	print "That's it, we're done."
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	Save/C/O/P=folder_path IMWaves as "IMWaves.ibw"
	Save/C/O/P=folder_path Milliwaves as "Milliwaves.ibw"
	Save/C/O/P=folder_path frequency_list as "frequency_list.ibw"
	
	SetDataFolder savDF
	
	variable iiiii
	for(iiiii = 0; iiiii <4;iiiii+=1)
	Beep
	Sleep/s 1/8	
	endfor
End

Function averageIMSKPMdata(numberOfFreq)

	variable numberOfFreq
	wave IMWaves, MilliWaves

//	string savDF = GetDataFolder(1)
//	SetDataFolder root:packages:trEFM:PointScan:SKPM
	
	Make/O/N=(numberOfFreq) IMWavesAVG, MilliWavesAVG, MilliWavesAVGsup, MilliWavesAVGinf
	variable wave_points = DimSize(IMWaves,0)
		
	variable i,j
	for(i = 0; i <numberOfFreq; i+=1)
	
		wavestats /Q /R=[i*wave_points, (i+1)*wave_points] MilliWaves
		MilliWavesAVG[i]=V_avg
		
		variable tempMax=0
		variable tempMin=0
		variable couterMax=0
		variable couterMin=0
		for(j = 0; j <wave_points; j+=1)
			if(MilliWaves[j][i] > V_avg+0.05*V_avg)
				tempMax+=MilliWaves[j][i]
				couterMax+=1
			elseif(MilliWaves[j][i] < V_avg-0.05*V_avg)
				tempMin+=MilliWaves[j][i]
				couterMin+=1
			endif
		endfor
		
		if(couterMax!=0)
		MilliWavesAVGsup[i]=tempMax/couterMax
		else
		MilliWavesAVGsup[i]=0
		endif
		if(couterMax!=0)
		MilliWavesAVGinf[i]=tempMin/couterMin
		else
		MilliWavesAVGinf[i]=0
		endif
				
		wavestats /Q /R=[i*wave_points, (i+1)*wave_points] IMWaves
		IMWavesAVG[i]=V_avg

	endfor
	
//	SetDataFolder savDF
End

Function NetAverageIMSKPMdata(numberOfFreq)

	variable numberOfFreq
	wave IMWaves, MilliWaves
	wave IMWavesAVG, MilliWavesAVG, MilliWavesAVGsup, MilliWavesAVGinf

//	string savDF = GetDataFolder(1)
//	SetDataFolder root:packages:trEFM:PointScan:SKPM
	
	Make/O/N=(numberOfFreq) netAvgSPV
		
	variable i,j
	for(i = 0; i <numberOfFreq; i+=1)
		NetAvgSPV[i]=(IMWavesAVG[i]-MilliWavesAVGsup[i])/(MilliWavesAVGinf[i]-MilliWavesAVGsup[i])
	endfor			
	
//	SetDataFolder savDF
End


Function NetAverageIMSKPMdata2(numberOfFreq)

	variable numberOfFreq
	wave IMWaves, MilliWaves
	wave IMWavesAVG, MilliWavesAVG, MilliWavesAVGsup, MilliWavesAVGinf, netAvgSPV

	string savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	
	Make/O/N=(numberOfFreq) netAvgSPV2
		
	variable i,j
	for(i = 0; i <numberOfFreq-1; i+=1)
		NetAvgSPV2[i]=(IMWavesAVG[i]-0.5*(MilliWavesAVGsup[i]+MilliWavesAVGsup[i+1]))/(0.5*(MilliWavesAVGinf[i]+MilliWavesAVGinf[i+1])-0.5*(MilliWavesAVGsup[i]+MilliWavesAVGsup[i+1]))
	endfor			
	NetAvgSPV2[numberOfFreq-1]=(IMWavesAVG[numberOfFreq-1]-MilliWavesAVGsup[numberOfFreq-1])/(MilliWavesAVGinf[numberOfFreq-1]-MilliWavesAVGsup[numberOfFreq-1])
	
	SetDataFolder savDF
End


Function NormNetAverageIMSKPMdata(numberOfFreq)

	variable numberOfFreq
	wave IMWaves, MilliWaves
	wave IMWavesAVG, MilliWavesAVG, MilliWavesAVGsup, MilliWavesAVGinf, NetAvgSPV2

	string savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	
	Make/O/N=(numberOfFreq) NormNetAvgSPV
		
	wavestats /Q netAvgSPV2 	
	variable i,j
	for(i = 0; i <numberOfFreq; i+=1)
		NormNetAvgSPV[i]=0.5+0.5*(netAvgSPV2[i]-V_min)/(v_max-v_min)
	endfor			
	
	SetDataFolder savDF
End

Function PointScanSKPMVoltagePulseTest(xpos, ypos, liftheight,dwelltime, appliedbias, biasfreq)

	Variable xpos, ypos, liftheight,dwelltime, appliedbias, biasfreq
	
	String  savDF = GetDataFolder(1)
	
	Wave timekeeper=root:Packages:trEFM:PointScan:timekeeper
	
	SetDataFolder root:Packages:trEFM
	Nvar pgain, sgain, igain, adcgain, setpoint, adcgain
	NVAR XLVDTSens, YLVDTSens, ZLVDTSens, XLVDToffset, YLVDToffset, ZLVDToffset
	NVAR xigain, yigain, zigain
	Svar LockinString
	Wave EFMFilters = root:packages:trEFM:EFMFilters
	GetGlobals()
	
	SetDataFolder root:Packages:trEFM:VoltageScan
	Nvar calsoftd, calresfreq, calphaseoffset, calengagefreq, calhardd
	ResetAll()

	SetDataFolder root:packages:trEFM:PointScan:SKPM
	variable/G freq_PGain
	variable/G freq_IGain 
	variable/G freq_DGain
	
	//SetDataFolder root:Packages:trEFM:WaveGenerator
	//Wave gentipwave, gentriggerwave
	//commitdrivewaves()
	
	SetDataFolder root:Packages:trEFM:PointScan:SKPM
	
	////////////////////////// CALC INPUT/OUTPUT WAVES \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	Variable SKPMInterpolation = 2
	Variable CPDWavePoints = dwelltime * (50000 / SKPMInterpolation)
	CPDWavePoints = CPDWavePoints- mod(CPDWavePoints,32)

	Make/O/N = (CPDWavePoints) CPDwave // 800 points = 16 milliseconds at 50kHz sample rate
	
Make/O/N = (CPDWavePoints) Phase, Bias 
	
	CPDwave = NaN // set to NaN so we can use a procedure to determine when it is filled.

	//////////////////////////    SETTINGS   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	
	ResetAll()

	// SKPM Variables.
	NVAR LockinTimeConstant
	NVAR LockinSensitivity
	NVAR ACFrequency
	NVAR ACVoltage
	NVAR TimePerPoint

	variable SKPpgain, SKPigain, lockinsens

	SetPassFilter(1,a=EFMFilters[%EFM][%A],b=EFMFilters[%EFM][%B],fast=EFMFilters[%EFM][%Fast],i=EFMFilters[%EFM][%i],q=EFMFilters[%EFM][%q])

	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)

	td_WriteValue("Output.A", 0)
	td_WriteValue("Output.B", 0)
	td_WriteValue("Output.C", 0)

	MoveXY(xpos, ypos) // move to xy position, though keep raised up
	
	////////////////////////// SET SKPM HARDWARE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	
	GPIBsetup()
	lockinsens = GetLockinSens()

	SetLockinTimeC(LockinTimeConstant/1000) //the user specifies the Lockin time constant, and this call sets it, making sure 
	setLPslope(3) // 0 is 6dB, 1 is 12dB, 2 is 18dB, and 3 is 24 dB
	setSync(1) // 0 is off and 1 is on
	setFloat0orGround1(1) //0 is float and 1 is ground
	setNotch(3) //0 is neither, 1 is 60hz, 2 is 120hz, and 3 is both
	setReserve(2) //0 is high, 1 is normal, 2 is low
	setChanneliOutputtoj(1,1) //output x on channel 1
	setChanneliDisplayj(1, 0) //display x on channel 1
	//setLockinPhase(-9) //this phase is selected for a frequency of 1000 hz
	setLockinPhase(-100)
	setLockinSensitivity(LockinSensitivity) // 17 sets the sensitivity of the lockin to 1mv/na //20 is a good value
	sendLockinString("FMOD0") //sets source to external 

	Setvf(0, ACFrequency,"WG")
	
//	SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","In0","DDS")
SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","DDS","OutC","OutB","Ground","In0","DDS")	

	// Keep x pos of tip constant for SKPM
	//SetFeedbackLoop(0, "Always", "XSensor", xpos / XLVDTsens / 10e5 + XLVDToffset, 0, xIgain, 0, "Output.X", 0)

	td_wv((LockinString + "Amp"), CalHardD) //set the frequency to the resonant frequency
	td_wv((LockinString + "Freq"), CalEngageFreq) //set the frequency to the resonant frequency
	
	// ALL SCAN MODES require the ampitude of the oscillation to remain constant by adjust the tip height above the sample
	SetFeedbackLoop(2, "Always", "Amplitude", Setpoint, -PGain, -IGain, -SGain, "Height", 0)
	Sleep/s .5

	//*********************** DO THE SCAN************//	
	Variable resetFreqOffset = td_rv((LockinString + "FreqOffset"))
	
	// Read the data from output.b
	td_xSetInWave(1,"Event.2", "Output.B", CPDwave, "", -2)
	
	//read the LIA output
	td_xSetInWave(2,"Event.2", "Input.B", Phase, "", -2)
	
	//apply a bias to the sample from output.C
	wavegenerator(appliedbias,biasfreq,"Output.C","Event.2,repeat",0)  //wavegenerator(amplitude,frequency,outputletter,event,bank)  //note with C%ouput we can't go faster than 78hz
	// read the applied bias
	td_xSetInWave(0,"Event.2", "Output.C", Bias, "", -2)
	
	Variable currentz = td_rv("Zsensor")*td_rv("ZLVDTSens")
		
	//stop amplitude FBLoop and 
	StopFeedbackLoop(2)	
	
	SetPassFilter(1, fast=EFMFilters[%KP][%fast], i=EFMFilters[%KP][%i], q=EFMFilters[%KP][%q])	
	
	// to keep tip from being stuck
	SetFeedbackLoop(3, "always",  "ZSensor", currentz-500*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0)
	sleep/s .5

	//raise up the amount specified in the Height box of the efm_sloth tab
	SetFeedbackLoop(3, "always",  "ZSensor", (currentz-(liftheight*1e-9))/GV("ZLVDTSens"), 0, EFMFilters[%ZHeight][%IGain], 0, "Output.Z", 0)
	sleep/s .5
	
	variable heightafter = td_rv("Zsensor")*td_rv("ZLVDTSens")
	sleep/s .5
	print "Lift value (nm)", (currentz-heightafter)*1e9
	

	td_wv((LockinString + "Amp"), calsoftd) //set the amplitude from the grab tune function
//	td_wv((LockinString + "Freq"), CalResFreq) //set the frequency to the resonant frequency
td_wv((LockinString + "Freq"), calengagefreq)	
	td_wv((LockinString + "PhaseOffset"), CalPhaseOffset)  // phase offset also comes from calibration panel
	td_writevalue("Output.B", 0) // set voltage
	
	// Wait this extra time for frequency to stablize, but note we have already waited some anyway
	 Variable startTime = StopMSTimer(-2)
	do 
	while((StopMSTimer(-2) - StartTime) < 10*1e3) 
	
	//Output a Sin wave with this voltage and frequency.
	setvf(ACVoltage, ACFrequency,"WG")
	

	Sleep/S .5
	
	// Keep phase constant by manipulating output.A 
	//SetFeedbackLoop(5, "Always", LockinString + "theta", td_RV(LockinString + "theta"), freq_PGain, freq_IGain, freq_DGain, "Output.A" , 0)
//SetFeedbackLoopCypher(1, "always", LockinString +"theta", td_RV(LockinString + "theta"), freq_PGain, freq_IGain,  freq_DGain, "cypher.Output.A", 0)
//print LockinString
				
	//Keep Input.B at 0 by manipulating Output.B
	SetFeedbackLoop(4, "always",  "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], EFMFilters[%KP][%DGain], "Output.B", 0) 
	

	Sleep/S .5
	
	// fire event that starts the data collection
	td_WriteString("Event.2", "Once")
	
//Abort
	
	// Wait until data has been collected
	CheckInWaveTiming(CPDwave)
			
	variable heightafterscan = td_rv("Zsensor")*td_rv("ZLVDTSens")
	sleep/s .5
	print "Drift (nm)", (heightafterscan-heightafter)*1e9
			
	//stop collecting data
	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)		
	
//	td_wv("Output.A",0)
	td_wv("Output.B",0)
td_wv("Output.C",0)
			
	DoUpdate
	
	//Turn off the sine wave that we were sending.
	SetEFMvf(0, ACFrequency, sleeptime=0)	
		
	td_wv((LockinString + "FreqOffset"), resetFreqOffset)	
	td_wv((LockinString + "Amp"), CalHardD) //set the frequency to the resonant frequency
	td_wv((LockinString + "Freq"), CalEngageFreq)
	td_wv((LockinString + "PhaseOffset"), CalPhaseOffset)
			
	SetPassFilter(1, fast = 1000, i = 1000, q = 1000)
	
	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
//StopFeedbackLoop(5)
	
	td_wv((LockinString + "Freq"), CalResFreq)
	td_wv((LockinString + "FreqOffset"), 0)
	
	SetFeedbackLoop(2, "Always", "Amplitude", Setpoint, -PGain, -IGain, -SGain, "Height", 0)

	startTime = StopMSTimer(-2)	
	do  // waiting loop till we recontact surface
		doUpdate
	while((StopMSTimer(-2) - StartTime) < 1e6*.2)
	
	//***************  END SCAN *****************************//

	
	// ********************  NOW DISPLAY THE DATA **************************** ///
		
	//Display  root:packages:trEFM:PointScan:SKPM:CPDwave
		
	DoWindow/F CPDvsTIME
	if(v_flag == 0)
		display/l/K=1/b/N=CPDvsTIME  root:packages:trEFM:PointScan:SKPM:CPDwave
		appendtograph/W=CPDvsTIME /R Bias
				
		Label/W=CPDvsTIME left "CPD (Volts)"
		Label/W=CPDvsTIME bottom "Time (s)"
		Label/W=CPDvsTIME  right "Applied Bias"
					
		ModifyGraph/W=CPDvsTIME lsize=2,rgb=(0,39168,0)
		ModifyGraph/W=CPDvsTIME fStyle=1,fSize=14
		ModifyGraph/W=CPDvsTIME gbRGB = (65535,65535,65535)
		ModifyGraph/W=CPDvsTIME  rgb(Bias)=(65280,0,0)
		ModifyGraph/W=CPDvsTIME axRGB(right)=(65280,0,0)
		ModifyGraph/W=CPDvsTIME axRGB(left)=(0,39168,19712)
		ModifyGraph/W=CPDvsTIME axThick=2
		ModifyGraph/W=CPDvsTIME tick(bottom)=2,mirror(bottom)=1
	endif
	
	DoWindow/F PhasevsTIME
	if(v_flag == 0)
		display/l/K=1/b/N=PhasevsTIME  root:packages:trEFM:PointScan:SKPM:Phase
		appendtograph/W=PhasevsTIME /R Bias
				
		Label/W=PhasevsTIME left "Phase (Volts)"
		Label/W=PhasevsTIME bottom "Time (s)"
		Label/W=PhasevsTIME  right "Applied Bias"
					
		ModifyGraph/W=PhasevsTIME lsize=2,rgb=(0,39168,0)
		ModifyGraph/W=PhasevsTIME fStyle=1,fSize=14
		ModifyGraph/W=PhasevsTIME gbRGB = (65535,65535,65535)
		ModifyGraph/W=PhasevsTIME  rgb(Bias)=(65280,0,0)
		ModifyGraph/W=PhasevsTIME rgb(Phase)=(0,0,52224)
		ModifyGraph/W=PhasevsTIME axRGB(right)=(65280,0,0)
		ModifyGraph/W=PhasevsTIME axRGB(left)=(0,0,52224)
		ModifyGraph/W=PhasevsTIME axThick=2
		ModifyGraph/W=PhasevsTIME tick(bottom)=2,mirror(bottom)=1
	endif
	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	Beep
	doscanfunc("stopengage")
	setdatafolder savDF
	
End

Function test(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
		
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	Nvar DwellTime, AppliedBias, BiasFreq
	
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif

	PointScanSKPMVoltagePulseTest(gxpos, gypos, liftheight, DwellTime,  appliedbias, biasfreq)

	GetCurrentPosition()
	SetDataFolder savDF
	
End



#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ImageScanSKPMSPV(xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed)
	
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
	//Variable FreqOffsetNorm = 500
	
	NVAR Setpoint =  root:Packages:trEFM:Setpoint
	NVAR ADCgain = root:Packages:trEFM:ADCgain
	NVAR PGain = root:Packages:trEFM:PGain
	NVAR IGain = root:Packages:trEFM:IGain
	NVAR SGain = root:Packages:trEFM:SGain
	NVAR ImagingFilterFreq = root:Packages:trEFM:ImagingFilterFreq

	Variable XLVDTSens = GV("XLVDTSens")
	Variable XLVDToffset = GV("XLVDToffset")
	Variable YLVDTSens  = GV("YLVDTSens")
	Variable YLVDToffset = GV("YLVDToffset")
	Variable ZLVDTSens = GV("ZLVDTSens")

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
	variable SlowScanDelta
	variable FastscanDelta
	variable i,j,k,l

	ScanFramework[][0] = xpos - scansizeX / 2 //gPSscansizeX= fast width
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
	
	
	Make/O/N = (scanpoints, scanlines) Topography, CPDImage, CPDImage2, CPDdiff

	
	SetScale/I x, ScanFrameWork[0][0], ScanFramework[0][2], "um", Topography, CPDImage, CPDImage2, CPDdiff
	if(scanlines==1)
		SetScale/I y, ypos, ypos, Topography, CPDImage, CPDImage2, CPDdiff
	else
		SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, CPDImage, CPDImage2, CPDdiff
	endif
	
	if(mod(scanpoints,32) != 0)									//Scan aborts if scanpoints is not divisible by 32 PC 4/29/14
			abort "Scan Points must be divisible by 32"
	endif
	
	Make/O/N = (scanpoints) ReadWaveZ, ReadWaveZback, Xdownwave, Ydownwave, Xupwave, Yupwave
	Make/O/N = (scanpoints, scanlines, 4) XYupdownwave
	ReadWaveZ = NaN

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

	GPIBsetup()
	
	Variable lockinsens=GetLockinSens()

	SetLockinTimeC(LockinTimeConstant / 1000) //the user specifies the Lockin time constant, and this call sets it, making sure 
	setLPslope(3) // 0 is 6dB, 1 is 12dB, 2 is 18dB, and 3 is 24 dB
	setSync(1) // 0 is off and 1 is on
	setFloat0orGround1(0) //0 is float and 1 is ground
	setNotch(3) //0 is neither, 1 is 60hz, 2 is 120hz, and 3 is both
	setReserve(1) //0 is high, 1 is normal, 2 is low
	setChanneliOutputtoj(1,1) //output x on channel 1
	setChanneliDisplayj(1,0) //display x on channel 1
	//setLockinPhase(-9) //this phase is selected for a frequency of 1000 hz
	setLockinPhase(-100)
	setLockinSensitivity(LockinSensitivity) // 17 sets the sensitivity of the lockin to 1mv/na //20 is a good value
	sendLockinString("FMOD0") //sets source to external 
	Setvf(0, ACFrequency,"WG")
	Make/O/N=(scanpoints) CPDTrace, CPDTraceBefore, CPDTrace2
	Variable pointsPerPixel = timeperpoint * samplerate * 1e-3
	Variable pointsPerLine = pointsPerPixel * scanpoints
	make/o/n=(pointsPerPixel) CPDWaveTemp
	
	variable lastvoltage, lk, ll
	make/o/n=(pointsPerPixel) CPDWaveLastPoint
	
	Variable timeofscan = timeperpoint * 1e-3 * scanpoints
	Upinterpolation = (timeofscan * samplerate) / (scanpoints)
	print timeofscan, upinterpolation, lockintimeConstant, lockinsensitivity

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
		ModifyImage CPDImage ctab= {*,*,Mocha,0}
	endif
	ModifyGraph/W=CPD height = {Aspect, scansizeY/scansizeX}		
	
	dowindow/f CPD2
	if (V_flag==0)
		Display/K=1/n=CPD2;Appendimage CPDImage2
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan (um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(62000,65000,48600),expand=.7
		ColorScale/C/N=text0/E/F=0/A=MC image=CPDImage2
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "V"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=CPDImage2
		ModifyImage CPDImage2 ctab= {*,*,Mocha,0}
	endif
	ModifyGraph/W=CPD height = {Aspect, scansizeY/scansizeX}		

	dowindow/f CPDdifference
	if (V_flag==0)
		Display/K=1/n=CPDdifference;Appendimage CPDdiff
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan (um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(62000,65000,48600),expand=.7
		ColorScale/C/N=text0/E/F=0/A=MC image=CPDdiff
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "V"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=CPDdiff
		ModifyImage CPDdiff ctab= {*,*,Mocha,0}
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
		ModifyImage Topography ctab= {*,*,VioletOrangeYellow,0}
	endif	
	
	ModifyGraph/W=TopgraphyImage height = {Aspect, scansizeY/scansizeX}
	ModifyGraph/W=CPD height = {Aspect, scansizeY/scansizeX}
	ModifyGraph/W=CPD2 height = {Aspect, scansizeY/scansizeX}
	ModifyGraph/W=CPDdifference height = {Aspect, scansizeY/scansizeX}
	
	dowindow/f CPDTraceWindow
	if (V_flag==0)
		Display/K=1/n=CPDTraceWindow CPDTrace
		appendtograph CPDTraceBefore
		ModifyGraph rgb(CPDTraceBefore)=(0,0,0)
	endif
	
	dowindow/f CPDTraceWindow12
	if (V_flag==0)
		Display/K=1/n=CPDTraceWindow12 CPDTrace
		appendtograph CPDTrace2
		ModifyGraph rgb(CPDTrace2)=(0,0,0)
	endif
	

	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=TopographyImage height = {Aspect, 1}
		ModifyGraph/W=CPDImage height = {Aspect, 1}
		ModifyGraph/W=CPDImage2 height = {Aspect, 1}		
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
		
	// HStrEFM needs no FBL on the LIA phase angle	

	SetPassFilter(1,q=EFMFilters[%KP][%q],i=EFMFilters[%KP][%i],a=EFMFilters[%KP][%A],b=EFMFilters[%KP][%B])
	
	SetFeedbackLoop(5, "Always", LockinString+"theta", td_rv(LockinString+"theta"), freq_PGain, freq_IGain, freq_DGain, "Output.A", 0)
	SetFeedbackLoop(4, "Always", "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], 0, "Output.B", 0)	
	SetFeedbackLoop(3, "Always",  "ZSensor", ReadWaveZ[scanpoints-1] - liftheight * 1e-9 / GV("ZLVDTSens"), 0, EFMFilters[%ZHeight][%IGain],0, "Output.Z",0)
	
	//stop all FBLoops again now that they have been initialized
	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
	
	// Set all DAC outputs to zero initially
	td_wv("Output.A", 0)
	td_wv("Output.C", 0)
	td_wv("Output.B", 0)	
	//******************  EEEEEEEEEEEEEEEEEEE *******************************//	
	
	//******************  FFFFFFFFFFFFFFFFFFFFFF *******************************//
	
	//pre-loop initialization, done only once
	//move to initial scan point
	MoveXY(ScanFramework[0][0], ScanFramework[0][1])

	//************************************* XYupdownwave is the final, calculated, scaled values to drive the XY piezos ************************//	
	XYupdownwave[][][0] = (ScanFrameWork[q][0] + FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
	XYupdownwave[][][1] = (ScanFrameWork[q][2] - FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
	XYupdownwave[][][2] = (ScanFrameWork[q][1]) / YLVDTsens / 10e5 + YLVDToffset
	XYupdownwave[][][3] = (ScanFrameWork[q][3]) / YLVDTsens / 10e5 + YLVDToffset
	
	//Set up the tapping mode feedback
	td_wv(LockinString + "Amp",CalHardD) 
	td_wv(LockinString + "Freq",CalEngageFreq) //set the frequency to the resonant frequency
	
	SetFeedbackLoop(2, "Always", "Amplitude", Setpoint, -PGain, -IGain, -SGain, "Height", 0)	
	
	Sleep/S 1.5
	
	//******************  FFFFFFFFFFFFFFFFFFFFFF *******************************//
	//*********************************************************************//
	
	///Starting imaging loop here
	i = 0
	j=0
	variable heightbefore, heightafter
	do
	j=0
	do
		starttime2 = StopMSTimer(-2) //Start timing the raised scan line
		
		if(j==0)
		print "line ", i+1
		print "Light off"
		td_wv("Output.C", 0)
		elseif(j==1)
		print "Light on"
		td_wv("Output.C", 5)
		Sleep/S .25
		endif
		
		// these are the actual 1D drive waves for the tip movement
		Xdownwave[] = XYupdownwave[p][i][0]
		Xupwave[] = XYupdownwave[p][i][1]
		Ydownwave[] = XYupdownwave[p][i][2]
		Yupwave[] = XYupdownwave[p][i][3]
	
		//****************************************************************************
		//*** SET TRACE VALUES HERE
		//*****************************************************************************
		td_StopInWaveBank(-1)
		td_StopOutWaveBank(-1)
		
		td_xSetInWave(0,"Event.0", "ZSensor", ReadWaveZ,"", Downinterpolation)	
			
		td_xSetOutWavePair(0, "Event.0", "PIDSLoop.0.Setpoint", Xdownwave, "PIDSLoop.1.Setpoint", Ydownwave , -DownInterpolation)

		
		SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","Ground","DDS")

		SetPassFilter(1, q = ImagingFilterFreq, i = ImagingFilterFreq)

		td_wv(LockinString + "Amp", CalHardD) 
		td_wv(LockinString + "Freq", CalEngageFreq) //set the frequency to the resonant frequency
		td_wv(LockinString + "FreqOffset", 0)
		td_wv("Output.A", 0)
		td_wv("Output.B", 0)

		setvf(0, ACFrequency,"WG")
		
		// START TOPOGRAPHY SCAN
		//print "Topo linescan starts"
		error+= td_WriteString("Event.0", "Once")
	
		starttime3 = StopMSTimer(-2) //Start timing the raised scan line

		CheckInWaveTiming(ReadWaveZ) // Waits until the topography trace has been fully collected.
		//print "Topo linescan finished"
		Sleep/S .05
		
		//ReadWaveZback is the drive wave for the z piezo		
		ReadWaveZback[] = ReadwaveZ[scanpoints-1-p] - liftheight * 1e-9 / GV("ZLVDTSens")
		ReadWaveZmean = Mean(ReadwaveZ) * ZLVDTSens
		Topography[][i] = -(ReadwaveZ[p] * ZLVDTSens-ReadWaveZmean)
		DoUpdate
	
		//****************************************************************************
		//*** SET DATA COLLECTION STUFF.
		//*****************************************************************************		
		
		td_stopInWaveBank(-1)
		td_stopOutWaveBank(-1)
		td_xSetInWave(1, "Event.2", "Output.B", CPDWave,"", -1) 
		
		heightbefore = td_rv("Zsensor")*td_rv("ZLVDTSens")
		 
		//stop amplitude FBLoop and 
		StopFeedbackLoop(2)		
		SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","In0","DDS")
		
		// to keep tip from being stuck
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-500*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
		sleep/s .5

		//start height FB for retrace
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"), 0, EFMFilters[%ZHeight][%IGain], 0, "Output.Z", 0)
		sleep/s .5
		
		heightafter = td_rv("Zsensor")*td_rv("ZLVDTSens")
		print "The lift height is", (heightbefore-heightafter)*1e9, " nm"
		
		td_wv((LockinString + "Amp"), calsoftd) //set the amplitude from the grab tune function
		td_wv((LockinString + "Freq"), CalResFreq) //set the frequency to the resonant frequency
		td_wv((LockinString + "PhaseOffset"), CalPhaseOffset)  // phase offset also comes from calibration panel
		
		error+= td_xsetoutwavePair(1, "Event.2", "ARC.PIDSLoop.0.Setpoint", Xupwave, "ARC.PIDSLoop.1.Setpoint", Yupwave, -UpInterpolation)	
		error+= td_xsetoutwave(2, "Event.2", "ARC.PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)

		SetPassFilter(1, q = EFMFilters[%KP][%q], i = EFMFilters[%KP][%i])
		
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
			td_wv("Output.B", lastvoltage) //get the intial tip voltage close to where it was before
		endif
		
		SetFeedbackLoop(5, "Always", LockinString+"theta", td_rv(LockinString+"theta"), freq_PGain, freq_IGain, freq_DGain, "Output.A", 0)
		setvf(ACVoltage, ACFrequency,"WG")
		sleep/S 1/4
		
		//auto set LIA phase
		if (i == 0 && j==0)
				td_wv("Output.B", 3) 
				setLockinTimeC(100/1000) //Tc100ms
				sleep/S 1/4
				setAutoPhase()
				sleep/S 1.0
				setLockinTimeC(LockinTimeConstant / 1000)
				td_wv("Output.B", 0) 
				sleep/S 1/4
		endif
		
		sleep/S 1/4

		SetFeedbackLoop(4, "always",  "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], EFMFilters[%KP][%DGain], "Output.B", 0) 
		sleep/S 1/4
		
		//print "CPD linescan starts"
		
		//Fire retrace event here
		error += td_WriteString("Event.2", "Once")
		
		//abort
		
		CheckInWaveTiming(CPDWave)
	
		//print "CPD linescan finished"

		//**********************************************************************************
		//***  PROCESS DATA AND UPDATE GRAPHS
		//*******************************************************************************
		variable h = 0
		do
			CPDWaveTemp = 0
			k = 0
			l = h * pointsPerPixel
			
			do
				CPDWaveTemp[k] = CPDWave[l]
				
				k += 1
				l += 1
			while (k < pointsPerPixel)
		
			if(j==0)
				CPDImage[scanpoints-h-1][i] = mean(CPDWaveTemp)
			elseif(j==1)
				CPDImage2[scanpoints-h-1][i] = mean(CPDWaveTemp)
				CPDdiff[scanpoints-h-1][i]=CPDTrace2[p][i]-CPDTrace[p][i]
			endif
			
			h += 1
		while (h < scanpoints)

		if(i>0 && j==0)
			CPDTraceBefore=CPDTrace
		endif
		
		if(j==0)
			CPDTrace = CPDImage[p][i]
		elseif(j==1)
			CPDTrace2 = CPDImage2[p][i]
		endif
				
		
		
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
			
			td_wv(LockinString + "Amp", CalHardD) 
			td_wv(LockinString + "Freq", CalEngageFreq)
			td_wv(LockinString + "FreqOffset", 0)	
				
			SetFeedbackLoop(2, "Always", "Amplitude", Setpoint, -PGain, -IGain, -SGain, "Height", 0)	
				
		endif 
	
		print "Time for last scan line (seconds) = ", (StopMSTimer(-2) -starttime2)*1e-6, " ; Time remaining (in minutes): ", 2*((StopMSTimer(-2) -starttime2)*1e-6*(scanlines-i-1)) / 60

		
		//Reset the primary inwaves to Nan so that gl_checkinwavetiming function works properly
		CPDWaveLast[] = CPDWave[p]
		ReadWaveZ[] = NaN
		CPDWave[] = NaN
	j+=1
	while (j < 2 )	
	i += 1	
	while (i < scanlines )	
	// end imaging loop 
	//************************************************************************** //
	
	if (error != 0)
		print "there was some setinoutwave error during this program"
	endif
	
	DoUpdate		
		
	StopFeedbackLoop(3)	
	StopFeedbackLoop(4)	

	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	Beep
	doscanfunc("stopengage")
	setdatafolder savDF

End

Function SKPMSPVImageScanButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	
	SetDataFolder root:Packages:trEFM:ImageScan
	Nvar scansizex, scansizey, scanlines, scanpoints, scanspeed
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	
	Nvar WavesCommitted
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif

	ImageScanSKPMSPV(gxpos, gypos, liftheight, scansizeX, scansizeY, scanlines, scanpoints, scanspeed)
	GetCurrentPosition()
	SetDataFolder savDF
	
End

Function UseLineNumforVoltage(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	NVAR UseLineNumforVoltage = root:packages:trEFM:PointScan:SKPM:UseLineNumforVoltage

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			 UseLineNumforVoltage = checked
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End