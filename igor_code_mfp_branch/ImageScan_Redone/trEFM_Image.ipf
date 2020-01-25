#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ImageScantrEFM_new(xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, numavgsperpoint, xoryscan, fitstarttime, fitstoptime)
	Variable xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, numavgsperpoint,xoryscan, fitstarttime, fitstoptime
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
	SetDataFolder root:Packages:trEFM
	NVAR interpval
	Svar LockinString
	
	String savDF = GetDataFolder(1) // locate the current data folder
	SetDataFolder root:Packages:trEFM:WaveGenerator
	Wave gentipwaveTemp, gentriggerwaveTemp, genlightwaveTemp, genDriveWaveTemp

	SetDataFolder root:Packages:trEFM:ImageScan:trEFM

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

	Variable XLVDTSens = GV("XLVDTSens")
	Variable XLVDToffset = GV("XLVDToffset")
	Variable YLVDTSens  = GV("YLVDTSens")
	Variable YLVDToffset = GV("YLVDToffset")
	Variable ZLVDTSens = GV("ZLVDTSens")

	Nvar xigain, yigain, zigain
		
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
	Variable samplerate = 50000 / interpolation
	Variable totaltime = 16 * interpval //
	//*******************  AAAAAAAAAAAAAAAAA **************************************//	
	
	ResetAll()	

	Downinterpolation = ceil((50000 * (scansizex / scanspeed) / scanpoints))      //Moved this up here so it actually can calculate gheightscantime PC 4/29/14
	samplerate = 50000 / interpval
	PSlength = 800 // (samplerate) * 16e-3
	
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

	// INITIALIZE in and out waves
	//downinterpolation, scanspeeds will need to be adjusted to account for multiple cycles per point on the retrace
	// should leave downinterpolation, psvoltsloth, pslightsloth as they are and create new variables that are only used for the high speed
	//trEFM experiment that uses the existing vars and waves as a template	
	
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
		CycleTime[k]=k * (1/samplerate) * interpolation              
		k += 1
	while (k < PSchunkpointssmall)
	
	variable starttimepoint = fitstarttime
	variable stoptimepoint = fitstoptime

	PSlength = scanpoints * cyclepoints
	PStimeofscan = (scanpoints * cyclepoints) / (samplerate) // time per line
	Upinterpolation = (PStimeofscan * samplerate) / (scanpoints)
	
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

	SetCrosspoint ("FilterOut","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Defl","OutC","OutA","OutB","Ground","OutB","DDS")
	
	//stop all FBLoops except for the XY loops
	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
	
	variable error = 0
	td_StopInWaveBank(-1)
		
	SetPassFilter(1,q=EFMFilters[%EFM][%q],i=EFMFilters[%EFM][%i],a=EFMFilters[%EFM][%A],b=EFMFilters[%EFM][%B])
	
	if (stringmatch("ARC.Lockin.0." , LockinString))
		SetFeedbackLoop(4, "always", LockinString +"theta", NaN, EFMFilters[%trEFM][%PGain], EFMFilters[%trEFM][%IGain], 0, LockinString+"FreqOffset",  EFMFilters[%trEFM][%DGain])
	else
		SetFeedbackLoopCypher(1, "always", LockinString +"theta", NaN, EFMFilters[%trEFM][%PGain], EFMFilters[%trEFM][%IGain], 0, LockinString+"FreqOffset",  EFMFilters[%trEFM][%DGain])
	endif	
		
	SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0)

	//stop all FBLoops again now that they have been initialized
	//StopFeedbackLoop(3)
	//StopFeedbackLoop(4)
	//StopFeedbackLoop(5)

	// Set all DAC outputs to zero initially
	td_wv("Output.A", 0)
	td_wv("Output.B",0)	
	//******************  EEEEEEEEEEEEEEEEEEE *******************************//	
	
	//******************  FFFFFFFFFFFFFFFFFFFFFF *******************************//
	//pre-loop initialization, done only once
	NVAR gxpos= root:packages:trEFM:gxpos
	NVAR gypos = root:packages:trEFM:gypos
	//move to initial scan point, read location, and print some beginning of experiment data
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
	
	SetCrosspoint ("FilterOut","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Defl","OutC","OutA","OutB","Ground","OutB","DDS")
	variable currentX = td_ReadValue("XSensor")
	variable currentY = td_ReadValue("YSensor")

	//************************************* XYupdownwave is the final, calculated, scaled values to drive the XY piezos ************************//	
	SetupXYUpDown(ScanFramework, FastScanDelta, XFastEFM, YFastEFM)
	
	print (XYupdownwave[0][LineNum][0] - XLVDTOffset) * 10e5 * XLVDTSens
	
	//Set up the tapping mode feedback
	td_wv(LockinString + "Amp",CalHardD) 
	td_wv(LockinString + "Freq",CalEngageFreq) //set the frequency to the resonant frequency
	SetFeedbackLoop(2,"Always","Amplitude", Setpoint,-PGain,-IGain,-SGain,"Output.Z",0)	
	
	Sleep/S 1.5
	
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
			if (error != 0)
				print i, "error1", error
			endif
		error+= td_xSetOutWavePair(0,"Event.0", "$outputXLoop.Setpoint", Xdownwave,"$outputYLoop.Setpoint",Ydownwave ,-DownInterpolation)
			if (error != 0)
				print i, "error2", error
			endif

		SetPassFilter(1,q = ImagingFilterFreq, i = ImagingFilterFreq)

		td_wv(LockinString + "Amp",CalHardD) 
		td_wv(LockinString + "Freq",CalEngageFreq) //set the frequency to the resonant frequency
		td_wv(LockinString + "FreqOffset",0)
		td_wv("Output.A",0)
		td_wv("Output.B",0)

		// *******  END SET TRACE VALUES   ************************ //

		
		//****************** This event starts the first pass (imaging)	

		error+= td_WriteString("Event.0", "Once")
			if (error != 0)
				print i, "error3", error
			endif
		
		starttime3 =StopMSTimer(-2) //Start timing the raised scan line

		CheckInWaveTiming(ReadWaveZ)
		
		Sleep/S .05
		//*********** End of the 1st scan pass

		
		//******************* now we prep for the 2nd scan pass ***********//
		// in this pass the previous z height data is fed to PISloop 2
		// which is mapped to ZSensor, 
		// simply put, the 2nd pass is the measured height plus the lift height
		// the x and y values are from the exact same wave as the first pass
		
		//ReadWaveZback is the drive wave for the z piezo		
		ReadWaveZback[] = ReadwaveZ[scanpoints-1-p] - liftheight * 1e-9 / GV("ZLVDTSens")
		ReadWaveZmean = Mean(ReadwaveZ) * ZLVDTSens
		Topography[][i] = -(ReadwaveZ[p] * ZLVDTSens)//-ReadWaveZmean)
		DoUpdate
	
		//****************************************************************************
		//*** SET RETRACE VALUES HERE (EXPERIMENTAL MEASUREMENT)
		//*****************************************************************************		
		td_stopInWaveBank(-1)
		td_stopOutWaveBank(-1)

		error+= td_xSetInWave(1,"Event.2", LockinString + "FreqOffset", ReadwaveFreq,"",interpval) // getting read frequency offset	
		error+= td_xsetoutwavepair(0,"Event.2,repeat", "Output.B", voltagewave,"Output.A", lightwave,-1*interpval)
		
		NVAR Cutdrive = root:packages:trEFM:cutDrive

//		error+= td_xsetoutwavepair(0,"Event.2,repeat", "Output.A", lightwave,"Output.B", voltagewave,-1)
//		print error
		if (CutDrive == 0)	
			error += td_xsetoutwave(1,"Event.2,repeat", "Output.C", triggerwave, -1)
		elseif (CutDrive == 1)
			error += td_xsetoutWave(1, "Event.2,repeat", LockinString + "Amp",drivewave, -1)
			if (error != 0)
				print i, "errorONB_cut", error
			endif
		endif

		
		//stop amplitude FBLoop and start height FB for retrace
		StopFeedbackLoop(2)		
//		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000

		// to keep tip from being stuck
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-500*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
		sleep/S 1
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
		sleep/s 1

		
		error+= td_xsetoutwavePair(1,"Event.2", "$outputXLoop.Setpoint", Xupwave,"$outputYLoop.Setpoint", Yupwave,-UpInterpolation)	
		if (error != 0)
			print i, "errorONB7", error
		endif
		
		if (stringmatch("ARC.Lockin.0." , LockinString))
			error+= td_xsetoutwave(2, "Event.2", "ARC.PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)
		else
			error+= td_xsetoutwave(2, "Event.2", "ARC.PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)
		endif
		
	
		if (error != 0)
			print i, "errorONB8", error
		endif

		td_wv(LockinString + "Amp", CalSoftD) 
		td_wv(LockinString+"Freq", CalResFreq) //set the frequency to the resonant frequency	
		td_wv(LockinString+"Freq", CalResFreq - FreqOffsetNorm)
		td_wv(LockinString+"FreqOffset", FreqOffsetNorm)

		if (stringmatch("ARC.Lockin.0." , LockinString))
			SetFeedbackLoop(4, "always", LockinString +"theta", NaN, EFMFilters[%trEFM][%PGain], EFMFilters[%trEFM][%IGain], 0, LockinString+"FreqOffset",  EFMFilters[%trEFM][%DGain])
		else
			SetFeedbackLoopCypher(1, "always", LockinString +"theta", NaN, EFMFilters[%trEFM][%PGain], EFMFilters[%trEFM][%IGain], 0, LockinString+"FreqOffset",  EFMFilters[%trEFM][%DGain])
		endif			
		
		SetPassFilter(1, q = EFMFilters[%trEFM][%q], i = EFMFilters[%trEFM][%i])

		//**********  END OF RETRACE SETTINGS

		//Fire retrace event here
		error += td_WriteString("Event.2", "Once")

		CheckInWaveTiming(ReadwaveFreq)	

		// ************  End of Retrace 		

		// Optional Save Raw Data
		
		if(saveOption == 1)
			string name
			if (i < 10)		
				name = "trEFM_000" + num2str(i) + ".ibw"
			elseif (i < 100)
				name = "trEFM_00" + num2str(i) + ".ibw"
			else
				name = "trEFM_0" + num2str(i) + ".ibw"
			endif

			Save/C/O/P = Path readWaveFreq as name
		endif
		//**********************************************************************************
		//***  PROCESS DATA AND UPDATE GRAPHS
		//*******************************************************************************
		variable V_FItOPtions = 4
		variable j=0
		variable l

		do
			V_FitError = 0
			V_FitOptions = 4
			readwavefreqtemp = 0
			k = 0
			l = j*cyclepoints

			Make/O/N = (PSChunkpointssmall, numavgsperpoint) ReadwaveFreqAVG
			variable avgloop = 0
			do
				Duplicate/O/R = [l + starttimepoint, l + stoptimepoint] ReadwaveFreq, Temp1
				ReadWaveFreqAvg[][avgloop] = Temp1[p] - 500

				avgloop += 1

				l += Fitcyclepoints
			while (avgloop < numavgsperpoint)
			
			MatrixOp/O readwavefreqtemp = sumrows(readwavefreqavg) / numcols(ReadWaveFreqAvg)

			make/o/n=3 W_sigma
			Make/O/N=3 W_Coef
			// Constraints added to improve fitting routines
			Make/O/T/N=1 T_Constraints
			//T_Constraints[0] = {"K1>0","K2>(1/100000)", "K2<10"}
			T_Constraints[0] = {"K2>(1/100000)", "K2<10"}
			
			curvefit/N=1/Q exp_XOffset, readwavefreqtemp  /x= CycleTime /C=T_Constraints
			FrequencyOffset[scanpoints-j-1][i]=W_Coef[1]
			ChargingRate[scanpoints-j-1][i]=1/(W_Coef[2]) 
			Chi2Image[scanpoints-j-1][i]=W_sigma[2]
	

			j+=1
		while (j < scanpoints)

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
			if (stringmatch("ARC.Lockin.0." , LockinString))
				StopFeedbackLoop(4)
			else
				StopFeedbackLoopCypher(1)
			endif	
			td_wv(LockinString+"Amp",CalHardD) 
			td_wv(LockinString+"Freq",CalEngageFreq)
			td_wv(LockinString+"FreqOffset",0)		
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

	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	
	Beep
	doscanfunc("stopengage")
	setdatafolder savDF
End