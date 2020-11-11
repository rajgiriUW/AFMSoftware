Function ImageScanGmode_old(xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed,  xoryscan,fitstarttime,fitstoptime,DigitizerAverages,DigitizerSamples,DigitizerPretrigger)
	Variable xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, xoryscan, fitstarttime, fitstoptime, DigitizerAverages, DigitizerSamples, DigitizerPretrigger
	
	Variable saveOption = 0
	Prompt saveOption, "Do you want to save the raw frequency data for later use?"
		DoPrompt ">>>",saveOption
			If(V_flag==1)
				GetCurrentPosition()
				abort			//Aborts if you cancel the save option
			endif
	
	if(saveoption == 1)	
		NewPath Path
	endif

	
	String savDF = GetDataFolder(1) // locate the current data folder
	SetDataFolder root:packages:trEFM
	Svar LockinString
	
	SetDataFolder root:Packages:trEFM:ImageScan:SKPM
	variable numavgsperpoint = 1
	//*******************  AAAAAAAAAAAAAAAAA **************************************//
	//*******  Initialize all global and local Variables that are shared for all experiments ********//

	GetGlobals()  //getGlobals ensures all vars shared with asylum are current
	
	//global Variables	
	if ((scansizex / scansizey) != (scanpoints / scanlines))
		abort "X/Y scan size ratio and points/lines ratio don't match"
	endif
	
	NVAR calresfreq = root:packages:trEFM:VoltageScan:Calresfreq
	NVAR CalEngageFreq = root:packages:trEFM:VoltageScan:CalEngageFreq
	NVAR CalHardD = root:packages:trEFM:VoltageScan:CalHardD
	NVAR CalsoftD = root:packages:trEFM:VoltageScan:CalsoftD
	NVAR CalPhaseOffset = root:packages:trEFM:VoltageScan:CalPhaseOffset
	Variable FreqOffsetNorm = 500
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
	
	NVAR OneOrTwoChannels = root:packages:trEFM:ImageScan:OneorTwoChannels	

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
	downinterpolation = ceil((50000 * (scansizex / scanspeed) / scanpoints))
	Variable downSamplerate =(ceil(50000 / downinterpolation))
	DoUpdate

	// GAGE ACQUISITION SETTINGS
	SetDataFolder root:packages:trEFM

	Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
	Wave CSACQUISITIONCONFIG = root:packages:GageCS:CSACQUISITIONCONFIG
	Wave CSTRIGGERCONFIG = root:packages:GageCS:CSTRIGGERCONFIG
	
	SetDataFolder root:packages:trEFM:ImageScan
	print downsamplerate
	// Figure out how many points we will need to capture for the whole line
	variable linetime = scanpoints/downSamplerate
	variable digiSampleRate = CSACQUISITIONCONFIG[%SampleRate]
	variable digiSamples = linetime * digiSampleRate 
	print linetime
	CSACQUISITIONCONFIG[%SegmentCount] = 1
	CSACQUISITIONCONFIG[%TriggerTimeOut] = 30*1e8 // 1e8 is equivalent to one second. scale is 100s of nanoseconds
	CSACQUISITIONCONFIG[%SegmentSize] = digiSamples
	CSACQUISITIONCONFIG[%Depth] = CSACQUISITIONCONFIG[%SegmentSize] 
	CSTRIGGERCONFIG[%Source] = -1 //External Trigger
	
	Make/O/N = (digiSamples, 1) data_wave
	Make/O/N = (digiSamples, 1) ch2_wave
	
	GageSet(-1)
	

	//******************  BBBBBBBBBBBBBBBBBB *******************************//
	//SETUP Scan Framework and populate scan waves 
	// Then initialize all other in and out waves
	//***********************************************************************
	
	Make/O/N = (scanlines, 4) ScanFramework
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
	
	
	Make/O/N = (scanpoints, scanlines) Topography

	if (XFastEFM == 1 && YFastEFM == 0)
		SetScale/I x, ScanFrameWork[0][0], ScanFramework[0][2], "um", Topography
		if(scanlines==1)
			SetScale/I y, ypos, ypos, Topography
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography
		endif
	

	elseif (XFastEFM == 0 && YFastEFM == 1)
		SetScale/I x, ScanFrameWork[0][2], ScanFramework[0][0], "um", Topography
		if(scanlines==1)
			SetScale/I y, ypos, ypos, Topography
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography
		endif
	
	endif

	if(mod(scanpoints,32) != 0)									//Scan aborts if scanpoints is not divisible by 32 PC 4/29/14
		abort "Scan Points must be divisible by 32"
	endif
	
	Make/O/N = (scanpoints) ReadWaveZ, ReadWaveZback, Xdownwave, Ydownwave, Xupwave, Yupwave
	Make/O/N = (scanpoints, scanlines, 4) XYupdownwave
	ReadWaveZ = NaN

	// Here we set the function generator to apply the required AC signal
	//Setvf(0, ACFrequency,"WG")
	
	//******************  DDDDDDDDDDDDDDDDDDD *******************************//	
	//***************** Open the scan panels ***********************************//
	
			// trefm charge creation/delay/ff-trEFM

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
	
	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=TopographyImage height = {Aspect, 1}
	endif

	//**************** End scan panel setup  ***************//
	//******************  DDDDDDDDDDDDDDDDDDD *******************************//


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
	
	variable EAmp = GV("NapDriveAmplitude")
	variable EFreq = GV("NapDriveFrequency")
	variable EOffset = GV("NapTipVoltage")
	variable EPhase = GV("NapPhaseOffset")

	td_WriteValue("DDSAmplitude0",EAmp)	
	td_WriteValue("DDSFrequency0",EFreq)	
	td_WriteValue("DDSDCOffset0",EOffset)	
	td_WriteValue("DDSPhaseOffset0",EPhase)
	print(Setpoint)
	SetFeedbackLoop(2, "Always", "Amplitude",Setpoint, -PGain, -IGain, -SGain, "Height", 0)	
	
	Sleep/S 1.5

	// Set up line triggers for Gage G-Mode Aquisition
	make/n=800/O linetrigger=0
	linetrigger[0,399] = 5
	
	///Starting imaging loop here
	i = 0
	variable heightbefore, heightafter
	do
		starttime2 = StopMSTimer(-2) //Start timing the raised scan line
		print "line ", i+1

		if (UseLineNum == 0)	// single line scans
			LineNum = i
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
		
		// Implement topography and G-mode Line trigger.
		td_xSetOutWavePair(0, "Event.0", "PIDSLoop.0.Setpoint", Xdownwave, "PIDSLoop.1.Setpoint", Ydownwave , -DownInterpolation)
		 td_xSetOutWave(1, "Event.0", "Output.A", linetrigger,1) // runs only once at the begining of a line
		
		SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutA","OutA","Ground","DDS","Ground")

		//DDS amplitudes
		//td_wv(LockinString + "Amp", CalHardD) 
		//td_wv(LockinString + "Freq", CalEngageFreq) //set the frequency to the resonant frequency
		//td_wv(LockinString + "FreqOffset", 0)
		//td_wv("Output.A", 0)
		//td_wv("Output.B", 0)

		//setvf(0, ACFrequency,"WG")
		
		// START TOPOGRAPHY SCAN
		print "Topo linescan starts"
		
		GageAcquire()
		
		error+= td_WriteString("Event.0", "Once")
		GageWait(600)
		Sleep/s 2
		starttime3 = StopMSTimer(-2) //Start timing the raised scan line

		print "Topo linescan finished"
		Sleep/S .05
		
		
		GageTransfer(1, data_wave)
		
		if (OneOrTwoChannels == 1)
			GageTransfer(2, ch2_wave)
		endif
		
		Topography[][i] = ReadwaveZ[p] - mean(ReadwaveZ)
		
		DoUpdate
	
		//****************************************************************************
		//*** SET DATA COLLECTION STUFF.
		//*****************************************************************************		
		td_stopInWaveBank(-1)
		td_stopOutWaveBank(-1)

		//**********************************************************************************
		//***  PROCESS DATA AND UPDATE GRAPHS
		//*******************************************************************************
		if(saveOption == 1)
			string name
			if (i < 10)		
				name = "GMODE_000" + num2str(i) + ".ibw"
			elseif (i < 100)
				name = "GMODE_00" + num2str(i) + ".ibw"
			else
				name = "GMODE_0" + num2str(i) + ".ibw"
			endif

			Save/C/O/P = Path data_wave as name
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
//				
			SetFeedbackLoop(2, "Always", "Amplitude", Setpoint, -PGain, -IGain, -SGain, "Height", 0)	
//					ErrorStr += num2str(td_WriteValue("DDSAmplitude0",EAmp))+","		//when switching to go through the HV op amp, we don't want massive
//		ErrorStr += num2str(td_WriteValue("DDSAmplitude1",EFreq))+","		//when switching to go through the HV op amp, we don't want massive
//		ErrorStr += num2str(td_WriteValue("DDSDCOffset0",EOffset))+","		//when switching to go through the HV op amp, we don't want massive
		
	SetFeedbackLoop(2, "Always", "Amplitude", 1.5e-3, -PGain, -IGain, -SGain, "Height", 0)	
		
		endif 
	
		print "Time for last scan line (seconds) = ", (StopMSTimer(-2) -starttime2)*1e-6, " ; Time remaining (in minutes): ", ((StopMSTimer(-2) -starttime2)*1e-6*(scanlines-i-1)) / 60
		i += 1

		
	while (i < scanlines)	
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