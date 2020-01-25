#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ImageScanFFtrEFM_new(xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, xoryscan,fitstarttime,fitstoptime, DigitizerAverages, DigitizerSamples, DigitizerPretrigger)
	
	Variable xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, xoryscan, fitstarttime, fitstoptime, DigitizerAverages, DigitizerSamples, DigitizerPretrigger
	Variable saveOption = 0
	
	Prompt saveOption, "Do you want to save the raw frequency data for later use?"
		DoPrompt ">>>",saveOption
			If(V_flag==1)
				GetCurrentPosition()
				Abort			//Aborts if you cancel the save option
			endif
	if(saveoption == 1)	
		NewPath Path
	endif

//////// for looping through with wrapper, to fix comment this and uncomment the above section
//	SaveOption = 1
//	SVAR Pathname = root:packages:trEFM:subfolder
//	Newpath/O/Q/C Path, Pathname
////////
	
	String savDF = GetDataFolder(1) // locate the current data folder
	SetDataFolder root:packages:trEFM
	Svar LockinString
	
	Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
	Wave CSACQUISITIONCONFIG = root:packages:GageCS:CSACQUISITIONCONFIG
	Wave CSTRIGGERCONFIG = root:packages:GageCS:CSTRIGGERCONFIG
	
	SetDataFolder root:packages:trEFM:ImageScan
	Nvar numavgsperpoint
	
	DigitizerAverages = scanpoints * numavgsperpoint
	
	CSACQUISITIONCONFIG[%SegmentCount] = DigitizerAverages
	CSACQUISITIONCONFIG[%SegmentSize] = DigitizerSamples
	CSACQUISITIONCONFIG[%Depth] = DigitizerPretrigger 
	CSACQUISITIONCONFIG[%TriggerHoldoff] =  DigitizerPretrigger 
	CSTRIGGERCONFIG[%Source] = -1 //External Trigger
	
	GageSet(-1)
	
	SetDataFolder root:Packages:trEFM:WaveGenerator
	Wave gentipwaveTemp, gentriggerwaveTemp, genlightwaveTemp, genDriveWaveTemp

	SetDataFolder root:Packages:trEFM:ImageScan:FFtrEFM

	//*******************  AAAAAAAAAAAAAAAAA **************************************//
	//*******  Initialize all global and local Variables that are shared for all experiments ********//

	// check all sloth wave generator vars and ensure they are referenced here properly
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
	NVAR xigain, yigain, zigain
	Variable XLVDTSens = GV("XLVDTSens")
	Variable XLVDToffset = GV("XLVDToffset")
	Variable YLVDTSens  = GV("YLVDTSens")
	Variable YLVDToffset = GV("YLVDToffset")
	Variable ZLVDTSens = GV("ZLVDTSens")
	
	WAVE EFMFilters=root:Packages:trEFM:EFMFilters
	//local Variables
	Variable V_FitError=0	
	Wave W_Sigma
	if(!WaveExists(W_sigma))
		Make/O W_sigma
	else
		wave W_sigma
	endif	
	Variable starttime,starttime2,starttime3
	Variable PSlength
	Variable PStimeofscan
	Variable PSchunkpoints, PSchunkpointssmall
	Variable baseholder
	Variable InputChecker
	Variable Downinterpolation, Upinterpolation
	Variable ReadWaveZmean
	Variable multfactor //avgs per pt
	Variable cycles
	Variable Interpolation = 1 // sample rate of DAQ banks
	Variable samplerate = 50000/interpolation
	Variable totaltime = 16 //
	//*******************  AAAAAAAAAAAAAAAAA **************************************//	
	
	ResetAll()	

	Downinterpolation = ceil(scansizeX / (scanspeed * scanpoints * .00001))      //Moved this up here so it actually can calculate gheightscantime PC 4/29/14
	PSlength = (samplerate/interpolation) * 16e-3

	if (mod(PSlength,32)==0)	
	else
		PSlength= PSlength + (32 - mod(PSlength,32))
	endif
		
	Variable gheightscantime = (scanpoints * .00001 * downinterpolation) * 1.05
	Variable gPSscantime = (interpolation * .00001 * PSlength) * 1.05
	Variable scantime = (gheightscantime + gPSscantime)*scanlines			//fixed scantime to gPSscantime PC 4/29/14
	Variable gPSwavepoints = PSlength
	DoUpdate

	//******************  BBBBBBBBBBBBBBBBBB *******************************//
	//SETUP Scan Framework and populate scan waves 
	// Then initialize all other in and out waves
	//***********************************************************************
	
	SetupFramework(xpos, ypos, scansizeX, scansizeY, scanlines, scanpoints, XFastEFM, YFastEFM)
	Wave ScanFrameWork
	
	NVAR SlowScanDelta
	NVAR FastScanDelta
	

	Make/O/N = (scanpoints, scanlines) Topography, ChargingRate, FrequencyOffset, Chi2Image
	SetUpImages(XFastEFM, YFastEFM, ScanFramework, xpos, ypos)
	
	if(mod(scanpoints,32) != 0)									//Scan aborts if scanpoints is not divisible by 32 PC 4/29/14
			abort "Scan Points must be divisible by 32"
	endif
	
	Make/O/N = (scanpoints) ReadWaveZ, ReadWaveZback, Xdownwave, Ydownwave, Xupwave, Yupwave
	Make/O/N = (scanpoints, scanlines, 4) XYupdownwave
	ReadWaveZ = NaN

	//******************  BBBBBBBBBBBBBBBBBB *******************************//

	//******************  CCCCCCCCCCCCCCCCCC *******************************//
	//POPULATE Data/Drive waves by experiment, these settings should not change
	// from jump to jump, cycle to cycle, or between the trace and retrace
	// vars that do change are initialized below
	//***********************************************************************
							//got rid of multfactor
	if (numavgsperpoint == 0)	// accidental 0 avg case
		numavgsperpoint = 1
	endif
	print "Number of Averages per point:",numavgsperpoint

	totaltime = (totaltime * 1e-3) * (samplerate) 					//puts totaltime (16 ms) into point space (800)
	fitstarttime = round((fitstarttime * 1e-3) * (samplerate))
	fitstoptime = round((fitstoptime * 1e-3) * (samplerate))

	Variable Fitcyclepoints = totaltime 
	
	PSchunkpointssmall = (fitstoptime - fitstarttime)
	Make/O/N = (PSchunkpointssmall) CycleTime, ReadWaveFreqtemp	

	Variable cyclepoints = Fitcyclepoints
	cyclepoints *= numavgsperpoint	// Number of points per line	

	// this section creates the voltage and light waves, duplicates them and concatenates the results to a new ffPS wave		
	MakeLightWaves(gentipwaveTemp, genlightwaveTemp, gentriggerwaveTemp, genDriveWaveTemp, fitcyclepoints, numavgsperpoint)
	Wave VoltageWave, LightWave, TriggerWave, DriveWave

	variable k = 0
	do
		CycleTime[k]=k * (1/samplerate) * interpolation               //Fixed this equation, used to be k * 0.00001 * interpolation. Sample rate is 0.00002 microseconds, though.
		k += 1
	while (k < PSchunkpointssmall)
	
	variable starttimepoint = fitstarttime
	variable stoptimepoint = fitstoptime

	PSlength = scanpoints * cyclepoints
	PStimeofscan = (scanpoints * cyclepoints) / (samplerate) // time per line
	Upinterpolation = (PStimeofscan * samplerate) / (scanpoints)
	
	//******************  CCCCCCCCCCCCCCCCCC *******************************//
	
	Make/O/N =(scanpoints) tfp_wave, shift_wave
	Make/O/N = (DigitizerSamples, DigitizerAverages) data_wave
	Make/O/N = (scanpoints, scanlines) tfp_array, shift_array,rate_array

	//******************  DDDDDDDDDDDDDDDDDDD *******************************//	
	// trefm charge creation/delay/ff-trEFM

	MakePanels()
	
	//Set inwaves with proper length and instantiate to Nan so that inwave timing works
	Make/O/N = (PSlength) ReadwaveFreq, ReadWaveFreqLast
	ReadwaveFreq = NaN

	//******************  EEEEEEEEEEEEEEEEEEE *******************************//	
	//******************** SETUP all hardware, FBL, XPT and external hdwe settings that are common
	//*******************  to both the trace and retrace **************
	
	// crosspoint needs to be updated to send the trigger to the gage card	
	// Set up the crosspoint, note that KP crosspoint settings change between the trace and retrace and are reset below

	SetCrosspoint ("FilterOut","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","OutB","DDS")
	
	//stop all FBLoops except for the XY loops
	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
	
	variable error = 0
	td_StopInWaveBank(-1)
		
	SetPassFilter(1,q=EFMFilters[%EFM][%q],i=EFMFilters[%EFM][%i],a=EFMFilters[%EFM][%A],b=EFMFilters[%EFM][%B])

	SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0)

	// Set all DAC outputs to zero initially
	td_wv("Output.A", 0)
	td_wv("Output.B",0)	
	td_wv("Output.C",0)
	//******************  EEEEEEEEEEEEEEEEEEE *******************************//	
	
	//******************  FFFFFFFFFFFFFFFFFFFFFF *******************************//
	//pre-loop initialization, done only once

	//move to initial scan point
	NVAR gxpos= root:packages:trEFM:gxpos
	NVAR gypos = root:packages:trEFM:gypos
	PreLoopMove(XFastEFM, YFastEFM, ScanFramework, xpos, ypos, scansizeX, scansizeY, UseLineNum=UseLineNum)
	
	SetCrosspoint ("FilterOut","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","OutB","DDS")	
	
	variable currentX = td_ReadValue("XSensor")
	variable currentY = td_ReadValue("YSensor")

	//************************************* XYupdownwave is the final, calculated, scaled values to drive the XY piezos ************************//	
	SetupXYUpDown(ScanFramework, FastScanDelta, XFastEFM, YFastEFM)
	
	print (XYupdownwave[0][LineNum][0] - XLVDTOffset) * 10e5 * XLVDTSens
	
	//Set up the tapping mode feedback
	td_wv(LockinString + "Amp",CalHardD) 
	td_wv(LockinString + "Freq",CalEngageFreq) //set the frequency to the resonant frequency
	
	SetFeedbackLoop(2,"Always","Amplitude", Setpoint,-PGain,-IGain,-SGain,"Height",0)	
	
	Sleep/S 0.5
	
	//******************  FFFFFFFFFFFFFFFFFFFFFF *******************************//
	//*********************************************************************//
	///Starting imaging loop here
	
	variable i=0
	do
		starttime2 =StopMSTimer(-2) //Start timing the raised scan line
		print "line ", i+1
		
		if (UseLineNum == 0)	// single line scans
			LineNum = i
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
		
		TopoTrace(XDownWave, YDownWave, Downinterpolation, folder="FFtrEFM")
		
		Sleep/S .05
		//*********** End of the 1st scan pass
		
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

		// Outputs three signals from the ARC. If CutDrive is active, then "trigger" is replaced by the drive signal to the shake piezo
		//	Otherwise, the outputs are:
		//	BNC0 : triggerwave
		//	BNC1: light wave
		//	BNC2: voltage wave
		//	BNC1 needs to connect to the light box. It can ALSO connect to the trigger box. Or, if CutDrive is off, BNC0 could connect to it
		//
		// IMPORTANT: You CANNOT use cutdrive and triggerwave at the same time.
	
		NVAR Cutdrive = root:packages:trEFM:cutDrive

		error+= td_xsetoutwavepair(0,"Event.2,repeat", "Output.A", lightwave,"Output.B", voltagewave,-1)
		if (CutDrive == 0)	
			error += td_xsetoutwave(1,"Event.2,repeat", "Output.C", triggerwave, -1)
		elseif (CutDrive == 1)
			error += td_xsetoutWave(1, "Event.2,repeat", LockinString + "Amp",drivewave, -1)
		endif

		//stop amplitude FBLoop and start height FB for retrace
		StopFeedbackLoop(2)		

		// to keep tip from being stuck, raises 100 nm first
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-100*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
		sleep/S 0.5
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
		sleep/s 0.5
		
		// If not using the new trigger box with invertable output, uncomment these lines and comment the subsequent 2 setoutwave(pair) lines
//		error+= td_xsetoutwavePair(2,"Event.2", "ARC.PIDSLoop.0.Setpoint", Xupwave,"ARC.PIDSLoop.3.Setpoint", ReadWaveZback,-UpInterpolation)	
//		variable YIGainBack = td_rv("ARC.PIDSLoop.1.IGain")
//		SetFeedbackLoop(1, "Event.2", "Ysensor", Yupwave[0], 0, YIGainBack, 0, "Output.Y", 0)		//	hard-set Y position each line to free up an outwavebank
		
	//	error+= td_xsetoutwavePair(1,"Event.2", "ARC.PIDSLoop.0.Setpoint", Xupwave,"ARC.PIDSLoop.1.Setpoint", Yupwave,-UpInterpolation)	
	//	error+= td_xsetoutwave(2, "Event.2", "ARC.PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)

		error+= td_xsetoutwavePair(1,"Event.2", "$outputXLoop.Setpoint", Xupwave,"$outputYLoop.Setpoint", Yupwave,-UpInterpolation)
		error+= td_xsetoutwave(2, "Event.2", LockInString + ".PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)

		td_wv(LockinString + "Amp", CalSoftD) 
		td_wv(LockinString + "Freq", CalResFreq) //set the frequency to the resonant frequency	
		td_wv(LockinString + "FreqOffset", 0)
		
//		SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","OutB","DDS")
		SetPassFilter(1, q = EFMFilters[%trEFM][%q], i = EFMFilters[%trEFM][%i])

		GageAcquire()
		
		//Fire retrace event here
		error += td_WriteString("Event.2", "Once")
		GageWait(600) // Wait until data collection has finished.
		
		td_stopInWaveBank(-1)
		td_stopOutWaveBank(-1)
		
		td_writevalue("Output.A", 0)
		td_writevalue("Output.B", 0)
		td_writevalue("Output.C", 0)
		
		GageTransfer(data_wave)
		AnalyzeLineOffline(PIXELCONFIG, scanpoints, shift_wave, tfp_wave, data_wave)

		// ************  End of Retrace 		

		// Optional Save Raw Data

		if(saveOption == 1)
			string name
			if (i < 10)		
				name = "FFtrEFM_000" + num2str(i) + ".ibw"
			elseif (i < 100)
				name = "FFtrEFM_00" + num2str(i) + ".ibw"
			else
				name = "FFtrEFM_0" + num2str(i) + ".ibw"
			endif

			Save/C/O/P = Path data_wave as name
		endif
		//**********************************************************************************
		//***  PROCESS DATA AND UPDATE GRAPHS
		//*******************************************************************************
		FrequencyOffset[][i] = shift_wave[p]
		tfp_array[][i] = tfp_wave[p]
		ChargingRate[][i] = 1 / tfp_wave[p]

		variable counter
		for(counter = 0; counter < scanpoints;counter+=1)
			FrequencyOffset[counter][i] = shift_wave[scanpoints - counter - 1]
			tfp_array[counter][i] = tfp_wave[scanpoints-counter-1]
			ChargingRate[counter][i] = 1 / tfp_wave[scanpoints-counter-1]
		endfor
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
			
			td_wv(LockinString + "Amp",CalHardD) 
			td_wv(LockinString + "Freq",CalEngageFreq)
			td_wv(LockinString + "FreqOffset",0)	
				
			SetFeedbackLoop(2,"Always","Amplitude", Setpoint,-PGain,-IGain,-SGain,"Height",0)	
				
		endif   //if (i<gPSscanlines)
	
		print "Time for last scan line (seconds) = ", (StopMSTimer(-2) -starttime2)*1e-6, " ; Time remaining (in minutes): ", ((StopMSTimer(-2) -starttime2)*1e-6*(scanlines-i-1)) / 60
		i += 1
		
		//Reset the primary inwaves to Nan so that gl_checkinwavetiming function works properly
		ReadWaveFreqLast[] = ReadwaveFreq[p]
		ReadWaveZ[] = NaN
		ReadwaveFreq[] = NaN
		
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

	// Save Parameters file
	CreateParametersFile(PIXELCONFIG)
	Wave SaveWave
	Save/G/O/P=Path/M="\r\n" SaveWave as "parameters.cfg"

	setdatafolder savDF	

End