#pragma rtGlobals=1		// Use modern global access method.


Function ImageScantrEFM(xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, numavgsperpoint, xoryscan, fitstarttime, fitstoptime)
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
	
	Make/O/N = (scanlines, 4) ScanFramework
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
	
	// 0 degree
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
		
//		if (UseLineNum == 1)
//			ScanFramework[][1] = (ypos - scansizeY / 2)  + SlowScanDelta*LineNum
//			ScanFramework[][3] = (ypos - scansizeY / 2)  + SlowScanDelta*LineNum
//		endif
	
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
		
//		if (UseLineNum == 1)
//			ScanFramework[i][1] = (xpos - scansizeY / 2)  + SlowScanDelta*LineNum
//			ScanFramework[i][3] = (xpos - scansizeY / 2)  + SlowScanDelta*LineNum
//		endif
	
	endif //x or y direction scanning

	// INITIALIZE in and out waves
	//downinterpolation, scanspeeds will need to be adjusted to account for multiple cycles per point on the retrace
	// should leave downinterpolation, psvoltsloth, pslightsloth as they are and create new variables that are only used for the high speed
	//trEFM experiment that uses the existing vars and waves as a template	
	
	Make/O/N = (scanpoints, scanlines) Topography, ChargingRate, FrequencyOffset, Chi2Image
	Chi2Image=0

	// 0 degree
	if (XFastEFM == 1 && YFastEFM == 0)
	
		SetScale/I x, ScanFrameWork[0][0], ScanFramework[0][2], "um", Topography, FrequencyOffset, ChargingRate, Chi2Image
		if(scanlines==1)
			SetScale/I y, ypos, ypos, Topography, FrequencyOffset, ChargingRate, Chi2Image
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, FrequencyOffset, ChargingRate,Chi2Image
		endif
	
	// 90 degree
	elseif (XFastEFM == 0 && YFastEFM == 1)
	
		SetScale/I x, ScanFrameWork[0][2], ScanFramework[0][0], "um", Topography, FrequencyOffset, ChargingRate, Chi2Image
		if(scanlines==1)
			SetScale/I y, xpos, xpos, Topography, FrequencyOffset, ChargingRate, Chi2Image
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, FrequencyOffset, ChargingRate,Chi2Image
		endif
	
	endif

	
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
	
	Make/O/N = (Fitcyclepoints) voltagewave, lightwave, triggerwave, drivewave
	
	voltagewave = gentipwaveTemp
	lightwave = genlightwaveTemp
	triggerwave = gentriggerwaveTemp
	drivewave = genDriveWavetemp

	PSchunkpointssmall = (fitstoptime - fitstarttime)
	Make/O/N = (PSchunkpointssmall) CycleTime, ReadWaveFreqtemp	

	Variable cyclepoints = Fitcyclepoints
		cyclepoints *= numavgsperpoint	// Number of points per line	


	// this section creates the voltage and light waves, duplicates them and concatenates the results to a new ffPS wave		


	// Crude concatenation routine
	Duplicate/O lightwave, ffPSLightWave
	Duplicate/O voltagewave, ffPSVoltWave
	Duplicate/O triggerwave, ffPSTriggerWave
	Duplicate/O drivewave, ffPSDriveWave
	
	cycles = 0					
	if (numavgsperpoint > 1)
		do
			Concatenate/NP=0 {voltagewave} ,ffPSVoltWave
			Concatenate/NP=0 {lightwave}, ffPSLightWave
			Concatenate/NP=0 {triggerwave}, ffPSTriggerWave
			Concatenate/NP=0 {drivewave}, ffPSDriveWave
			cycles += 1
		while (cycles < numavgsperpoint)
		
		// overwrite the originals
		Duplicate/O ffPSLightWave, lightwave
		Duplicate/O ffPSVoltWave, voltagewave
		Duplicate/O ffPSTriggerWave, triggerwave
		Duplicate/O ffPSDriveWave, drivewave
	endif

	k = 0
	do
		CycleTime[k]=k * (1/samplerate) * interpolation              
		k += 1
	while (k < PSchunkpointssmall)
	
	variable starttimepoint = fitstarttime
	variable stoptimepoint = fitstoptime

	PSlength = scanpoints * cyclepoints
	PStimeofscan = (scanpoints * cyclepoints) / (samplerate) // time per line
	Upinterpolation = (PStimeofscan * samplerate) / (scanpoints)
	

	//******************  CCCCCCCCCCCCCCCCCC *******************************//
	//******************  DDDDDDDDDDDDDDDDDDD *******************************//	
	//***************** Open the scan panels ***********************************//
	
			// trefm charge creation/delay/ff-trEFM

	dowindow/f ChargingRateImage
	if (V_flag==0)
		Display/K=1/n=ChargingRateImage;Appendimage ChargingRate
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan (um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(62000,65000,48600),expand=.7
		ColorScale/C/N=text0/E/F=0/A=MC image=ChargingRate
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "hz/V^2"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=ChargingRate
	endif
	
	ModifyGraph/W=ChargingRateImage height = {Aspect, scansizeY/scansizeX}		

	dowindow/f TopographyImage
	if (V_flag==0)
		Display/K=1/n=TopographyImage;Appendimage Topography
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan(um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(65000,60000,48600),expand=.7	
		ColorScale/C/N=text0/E/F=0/A=MC image=Topography
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "um"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=Topography
	endif	
	
	dowindow/f FrequencyShiftImage
	if (V_flag==0)
		Display/K=1/n=FrequencyShiftImage;Appendimage FrequencyOffset
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan (um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(65000,65000,48600),expand=.7
		ColorScale/C/N=text0/E/F=0/A=MC image=FrequencyOffset
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "Hz"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=FrequencyOffset
	endif
	
	ModifyGraph/W=TopographyImage height = {Aspect, scansizeY/scansizeX}
	ModifyGraph/W=FrequencyShiftImage height = {Aspect, scansizeY/scansizeX}

	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=TopographyImage height = {Aspect, 1}
		ModifyGraph/W=ChargingRateImage height = {Aspect, 1}
		ModifyGraph/W=FrequencyShiftImage height = {Aspect, 1}
	endif

	//**************** End scan panel setup  ***************//
	//******************  DDDDDDDDDDDDDDDDDDD *******************************//

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
		
	// HStrEFM needs no FBL on the LIA phase angle	

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
	
	print (XYupdownwave[0][LineNum][0] - XLVDTOffset) * 10e5 * XLVDTSens
	
	//Set up the tapping mode feedback
	td_wv(LockinString + "Amp",CalHardD) 
	td_wv(LockinString + "Freq",CalEngageFreq) //set the frequency to the resonant frequency
	td_wv(LockinString + "FreqOffset",0)

	SetFeedbackLoop(2,"Always","Amplitude", Setpoint,-PGain,-IGain,-SGain,"Output.Z",0)	
	
	Sleep/S 1.5
	
	//******************  FFFFFFFFFFFFFFFFFFFFFF *******************************//
	

	//*********************************************************************//
	///Starting imaging loop here
	i=0
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

		if (CutDrive == 0)	
//			error += td_xsetoutwave(1,"Event.2,repeat", "Output.C", triggerwave, -1)
		elseif (CutDrive == 1)
			error += td_xsetoutWave(1, "Event.2,repeat", LockinString + "Amp",drivewave, -1)
			if (error != 0)
				print i, "errorONB_cut", error
			endif
		endif
		
		//stop amplitude FBLoop and start height FB for retrace
		StopFeedbackLoop(2)		

		// to keep tip from being stuck
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-500*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
		sleep/S 1
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
		sleep/s 1

Make/O/N=(numpnts(ReadWaveFreq)) ZTemp = NaN
error += td_xSetInWave(0,"Event.2", "ZSensor", ZTemp,"", interpval) // getting read z-sensor for debugging offset	
		
		error+= td_xsetoutwavePair(1,"Event.2", "$outputXLoop.Setpoint", Xupwave,"$outputYLoop.Setpoint", Yupwave,-UpInterpolation)	
		if (error != 0)
			print i, "errorONB7", error
		endif
		
		if (stringmatch("ARC.Lockin.0." , LockinString))
			error+= td_xsetoutwave(2, "Event.2", "ARC.PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)
		else
			error+= td_xsetoutwave(2, "Event.2", "Cypher.PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)
		endif
	
		if (error != 0)
			print i, "errorONB8", error
		endif

		td_wv(LockinString + "Amp", CalSoftD) 
		td_wv(LockinString+"Freq", CalResFreq) //set the frequency to the resonant frequency	
		//td_wv(LockinString+"Freq", CalResFreq - FreqOffsetNorm)
		//td_wv(LockinString+"FreqOffset", FreqOffsetNorm)
		td_wv(LockinString+"FreqOffset", 0)

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
		j=0

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


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function ImageScanFFtrEFM(xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, xoryscan,fitstarttime,fitstoptime, DigitizerAverages, DigitizerSamples, DigitizerPretrigger)
	
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
	
	// Raj's edit to allow 2x resolution in FF without taking forever to acquire (64 x 64 pixels in 16x8 um^2 image, e.g.)
	//scansizey /= 2
	
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
	
	Make/O/N = (scanlines, 4) ScanFramework
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
	
	// 0 degree
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
		
//		if (UseLineNum == 1)
//			ScanFramework[][1] = (ypos - scansizeY / 2)  + SlowScanDelta*LineNum
//			ScanFramework[][3] = (ypos - scansizeY / 2)  + SlowScanDelta*LineNum
//		endif
	
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
		
//		if (UseLineNum == 1)
//			ScanFramework[i][1] = (xpos - scansizeY / 2)  + SlowScanDelta*LineNum
//			ScanFramework[i][3] = (xpos - scansizeY / 2)  + SlowScanDelta*LineNum
//		endif
	
	endif //x or y direction scanning

	// INITIALIZE in and out waves
	//downinterpolation, scanspeeds will need to be adjusted to account for multiple cycles per point on the retrace
	// should leave downinterpolation, psvoltsloth, pslightsloth as they are and create new variables that are only used for the high speed
	//trEFM experiment that uses the existing vars and waves as a template	
	
	//Downinterpolation = ceil(scansizeX / (scanspeed * scanpoints * .00001))
	

	Make/O/N = (scanpoints, scanlines) Topography, ChargingRate, FrequencyOffset, Chi2Image
	Chi2Image=0
	
	if (XFastEFM == 1 && YFastEFM == 0)
	
		SetScale/I x, ScanFrameWork[0][0], ScanFramework[0][2], "um", Topography, FrequencyOffset, ChargingRate, Chi2Image
		if(scanlines==1)
			SetScale/I y, ypos, ypos, Topography, FrequencyOffset, ChargingRate, Chi2Image
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, FrequencyOffset, ChargingRate,Chi2Image
		endif
	
	elseif (XFastEFM == 0 && YFastEFM == 1)
	
		SetScale/I x, ScanFrameWork[0][2], ScanFramework[0][0], "um", Topography, FrequencyOffset, ChargingRate, Chi2Image
		if(scanlines==1)
			SetScale/I y, xpos, xpos, Topography, FrequencyOffset, ChargingRate, Chi2Image
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, FrequencyOffset, ChargingRate,Chi2Image
		endif
	
	endif
	
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
	
	Make/O/N = (Fitcyclepoints) voltagewave, lightwave, triggerwave, drivewave
	
	voltagewave = gentipwaveTemp
	lightwave = genlightwaveTemp
	triggerwave = gentriggerwaveTemp
	drivewave = genDrivewaveTemp

	PSchunkpointssmall = (fitstoptime - fitstarttime)
	Make/O/N = (PSchunkpointssmall) CycleTime, ReadWaveFreqtemp	

	Variable cyclepoints = Fitcyclepoints
	cyclepoints *= numavgsperpoint	// Number of points per line	


	// this section creates the voltage and light waves, duplicates them and concatenates the results to a new ffPS wave		

	// Crude concatenation routine
	Duplicate/O lightwave, ffPSLightWave
	Duplicate/O voltagewave, ffPSVoltWave
	Duplicate/O triggerwave, ffPSTriggerWave
	Duplicate/O driveWave, ffPSDriveWave
	
	cycles = 0					//Changed to cycles = 0 from 1 because it would skip entry 1 and only do (numavgsperpoint - 1) PCMG 4/29/14
	if (numavgsperpoint > 1)
		do
			Concatenate/NP=0 {voltagewave} ,ffPSVoltWave
			Concatenate/NP=0 {lightwave}, ffPSLightWave
			Concatenate/NP=0 {triggerwave}, ffPSTriggerWave
			Concatenate/NP=0 {drivewave}, ffPSDriveWave
			cycles += 1
		while (cycles < numavgsperpoint)
		
		// overwrite the originals
		Duplicate/O ffPSLightWave, lightwave
		Duplicate/O ffPSVoltWave, voltagewave
		Duplicate/O ffPSTriggerWave, triggerwave
		Duplicate/O ffPSDriveWave, drivewave
	endif

	k = 0
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
	//***************** Open the scan panels ***********************************//
	
			// trefm charge creation/delay/ff-trEFM

	dowindow/f ChargingRateImage
	if (V_flag==0)
		Display/K=1/n=ChargingRateImage;Appendimage ChargingRate
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan (um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(62000,65000,48600),expand=.7
		ModifyImage ChargingRate ctab= {0,20000,VioletOrangeYellow,0}
		ColorScale/C/N=text0/E/F=0/A=MC image=ChargingRate
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "hz/V^2"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=ChargingRate
	endif
	
	ModifyGraph/W=ChargingRateImage height = {Aspect, scansizeY/scansizeX}		

	dowindow/f TopographyImage
	if (V_flag==0)
		Display/K=1/n=TopographyImage;Appendimage Topography
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan(um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(65000,60000,48600),expand=.7	
		ColorScale/C/N=text0/E/F=0/A=MC image=Topography
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "um"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=Topography
	endif	
	
	dowindow/f FrequencyOffsetImage
	if (V_flag==0)
		Display/K=1/n=FrequencyOffsetImage;Appendimage FrequencyOffset
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan (um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(65000,65000,48600),expand=.7
		ModifyImage FrequencyOffset ctab= {-100,0,YellowHot, 0}
		ColorScale/C/N=text0/E/F=0/A=MC image=FrequencyOffset
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "Hz"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=FrequencyOffset
	endif
	
	ModifyGraph/W=TopographyImage height = {Aspect, scansizeY/scansizeX}
	ModifyGraph/W=FrequencyOffsetImage height = {Aspect, scansizeY/scansizeX}

	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=TopographyImage height = {Aspect, 1}
		ModifyGraph/W=ChargingRateImage height = {Aspect, 1}
		ModifyGraph/W=FrequencyOffsetImage height = {Aspect, 1}
	endif

	//**************** End scan panel setup  ***************//
	//******************  DDDDDDDDDDDDDDDDDDD *******************************//

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
		
	// HStrEFM needs no FBL on the LIA phase angle	

	SetPassFilter(1,q=EFMFilters[%EFM][%q],i=EFMFilters[%EFM][%i],a=EFMFilters[%EFM][%A],b=EFMFilters[%EFM][%B])

	// Set all DAC outputs to zero initially
	td_wv("Output.A", 0)
	td_wv("Output.B",0)	
	td_wv("Output.C",0)
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
	
	SetCrosspoint ("FilterOut","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","OutB","DDS")	
	
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
	
	SetFeedbackLoop(2,"Always","Amplitude", Setpoint,-PGain,-IGain,-SGain,"Height",0)	
	
	Sleep/S 1.5
	
	//******************  FFFFFFFFFFFFFFFFFFFFFF *******************************//
	//*********************************************************************//
	///Starting imaging loop here
	
	i=0
	do
		starttime2 =StopMSTimer(-2) //Start timing the raised scan line
		print "line ", i+1

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
		
		error+= td_xSetInWave(0,"Event.0", "ZSensor", ReadWaveZ,"", Downinterpolation)// used during Trace to record height data		
			if (error != 0)
				print i, "error1", error
			endif
			
		error+= td_xSetOutWavePair(0,"Event.0", "PIDSLoop.0.Setpoint", Xdownwave,"PIDSLoop.1.Setpoint",Ydownwave ,-DownInterpolation)
		if (error != 0)
			print i, "error2", error
		endif


		SetPassFilter(1,q = ImagingFilterFreq, i = ImagingFilterFreq)

		td_wv(LockinString + "Amp",CalHardD) 
		td_wv(LockinString + "Freq",CalEngageFreq) //set the frequency to the resonant frequency
		td_wv(LockinString + "FreqOffset",0)
		
		td_wv("Output.A",0)
		td_wv("Output.B",0)
		td_wv("Output.C",0)

		// START TOPOGRAPHY SCAN
		error+= td_WriteString("Event.0", "Once")
			if (error != 0)
				print i, "error3", error
			endif
		
		starttime3 =StopMSTimer(-2) //Start timing the raised scan line

		CheckInWaveTiming(ReadWaveZ) // Waits until the topography trace has been fully collected.
		
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

		// Outputs three signals from the ARC. If CutDrive is active, then "trigger" is replaced by the drive signal to the shake pieze
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
//			error += td_xsetoutwave(1,"Event.2,repeat", "Output.C", triggerwave, -1)
		elseif (CutDrive == 1)
//			error += td_xsetoutWave(1, "Event.2,repeat", LockinString + "Amp",drivewave, -1)
		endif

		//stop amplitude FBLoop and start height FB for retrace
		StopFeedbackLoop(2)		

		// to keep tip from being stuck, raises 100 nm first
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-100*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
		sleep/S 1
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
		sleep/s 1

		
		// If not using the new trigger box with invertable output, uncomment these lines and comment the subsequent 2 setoutwave(pair) lines
//		error+= td_xsetoutwavePair(2,"Event.2", "ARC.PIDSLoop.0.Setpoint", Xupwave,"ARC.PIDSLoop.3.Setpoint", ReadWaveZback,-UpInterpolation)	
//		variable YIGainBack = td_rv("ARC.PIDSLoop.1.IGain")
//		SetFeedbackLoop(1, "Event.2", "Ysensor", Yupwave[0], 0, YIGainBack, 0, "Output.Y", 0)		//	hard-set Y position each line to free up an outwavebank
		
		error+= td_xsetoutwavePair(1,"Event.2", "$outputXLoop.Setpoint", Xupwave,"$outputYLoop.Setpoint", Yupwave,-UpInterpolation)
		if (stringmatch("ARC.Lockin.0." , LockinString))
			error+= td_xsetoutwave(2, "Event.2", "ARC.PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)
		else
			error+= td_xsetoutwave(2, "Event.2", "Cypher.PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)
		endif
//		error+= td_xsetoutwave(2, "Event.2", LockInString + "PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)

		td_wv(LockinString + "Amp", CalSoftD) 
		td_wv(LockinString + "Freq", CalResFreq) //set the frequency to the resonant frequency	
		td_wv(LockinString + "FreqOffset", 0)
		
		SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","OutB","DDS")
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
	Save/G/O/P=Path/M="\r\n" SaveWave as "parameters.cfg"

	setdatafolder savDF	

End

Function SaveImageScan(name,type)
	String name
	Variable type
	
	String savDF = GetDataFolder(1)
	
	Variable Layers
	if(type == 0)
		SetDataFolder root:Packages:trEFM:ImageScan:trEFM
		Layers = 4
	elseif(type == 1)
		SetDataFolder root:Packages:trEFM:ImageScan:FFtrEFM
		Layers = 3
	elseif(type == 2)
		SetDataFolder root:Packages:trEFM:ImageScan:SKPM
		Layers = 2
	endif
		

	Wave Topography, ChargingRate, FrequencyOffset, Chi2Image, CPDImage
	Wave ScanFrameWork

	SetDataFolder root:Packages:trEFM:ImageScan
	Nvar scanpoints, scanlines

	
	String/g DataTypeList
	DataTypeList = "HeightTrace;UserIn0ReTrace;UserIn1ReTrace;UserIn2ReTrace"

	Make/O/N = (scanpoints, scanlines, Layers) ImageWave
	



	if(scanlines == 1)
		setscale/I y, 0, ScanFramework[0][2]-ScanFrameWork[0][0], "um", ImageWave
	else
		setscale/I x, 0, abs(ScanFramework[scanlines-1][2]-ScanFrameWork[0][0]), "um",ImageWave
		setscale/I y, 0, abs(ScanFramework[scanlines-1][1]-ScanFrameWork[0][1]), "um",ImageWave
	endif
	
	//Test function to save multiple layer waves as a single 3D AR Image wave.	
	//these are the lines I used to test this opit	

	if( type == 0)
		DataTypeList = "HeightTrace;UserIn0ReTrace;UserIn1ReTrace;UserIn2ReTrace"
		ImageWave[][][0] = Topography[p][q]
		ImageWave[][][1] = ChargingRate[p][q]
		ImageWave[][][2] = FrequencyOffset[p][q]
		ImageWave[][][3] = Chi2Image[p][q]
		
	
	elseif(type == 1)
		DataTypeList = "HeightTrace;UserIn0ReTrace;UserIn1ReTrace"
		ImageWave[][][0] = Topography[p][q]
		ImageWave[][][1] = ChargingRate[p][q]
		ImageWave[][][2] = FrequencyOffset[p][q]

	elseif(type == 2)
		DataTypeList = "HeightTrace;UserIn0ReTrace"
		ImageWave[][][0] = Topography[p][q]
		ImageWave[][][1] = CPDImage[p][q]
		
		Wave ScanTimes = root:Packages:trEFM:ImageScan:SKPM:ScanTimes
		
		string savename = name + "_time.txt"
//		Save/G/O/M="," ScanTimes as savename
		Save/J/M="\r\n"/W ScanTimes as savename
//		Save/C/O/J ScanTimes as savetime
		
	endif
	
		//give it the right number of points in X and Y
	//we will assume that all layers have the same number of points and lines.		
	
	String NoteStr = ""
	variable A
	
	for (A = 0;A < Layers;A += 1)
		SetDimLabel 2,A,$StringFromList(A,DataTypeList,";"),ImageWave		//set the layer label based on the string from DataTypeList
		//put in some values for the note
		//here you can make this considerably more complex, calculating starting values and whatnot.
		NoteStr = ReplaceNumberByKey("Display Range"+num2str(A),NoteStr,12e-6,":","\r")
		NoteStr = ReplaceNumberByKey("Display Offset "+num2str(A),NoteStr,0,":","\r")
		NoteStr = ReplaceStringByKey("Colormap"+num2str(A),NoteStr,"Grays256",":","\r")
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

Function ClearImages()
	string SavDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:ImageScan:trEFM
	Wave/Z FrequencyOffset, ChargingRate, Topography
	
	if ( WaveExists(FrequencyOffset) && WaveExists(ChargingRate) && WaveExists(Topography))
		FrequencyOffset=0
		ChargingRate=0
		Topography=0
	endif
	
	SetDataFolder root:packages:trEFM:ImageScan:FFtrEFM
	Wave/Z FrequencyOffset, ChargingRate, Topography
		if ( WaveExists(FrequencyOffset) && WaveExists(ChargingRate) && WaveExists(Topography))
		FrequencyOffset=0
		ChargingRate=0
		Topography=0
	endif
	
	SetDataFolder root:packages:trEFM:ImageScan:SKPM
	Wave/Z CPDImage,  Topography
		if ( WaveExists(CPDImage) && WaveExists(Topography))
		
		CPDImage=0
		Topography=0
	endif
	
	SetDataFolder savDF
End
	
function gl_ResaveImageFunc(ImageWave,PName,Overwrite)
// this function is a leftover from the multi-Igorversion of the code, it is only here to avoid rewritting every instance
// of ReSaveImageFunc()
	Wave ImageWave
	String PName			//name of symbolic path that has already been set for this use, not used in version 5
	Variable Overwrite		//1 if you want to be able to overwrite the image file.

	ResaveImageFunc(ImageWave, PName, "Overwrite")
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function ImageScanRingDownEFM(xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, numavgsperpoint, xoryscan, fitstarttime, fitstoptime)
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
	Svar LockinString
	
	String savDF = GetDataFolder(1) // locate the current data folder
	SetDataFolder root:Packages:trEFM:WaveGenerator
	Wave gentipwaveTemp, gentriggerwaveTemp, genlightwaveTemp, gendrivewaveTemp

	SetDataFolder root:Packages:trEFM:ImageScan:trEFM
	NVAR LightOn = root:packages:trEFM:LightOn
	NVAR RingDownVoltage = root:packages:trEFM:RingDownVoltage
	
	Print "Light On is", LightOn

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
	Variable totaltime = 16 //
	//*******************  AAAAAAAAAAAAAAAAA **************************************//	
	
	ResetAll()	


	Downinterpolation = ceil((50000 * (scansizex / scanspeed) / scanpoints))      //Moved this up here so it actually can calculate gheightscantime PC 4/29/14
	
	PSlength = (samplerate) * 16e-3
	
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
	
	Make/O/N = (scanlines, 4) ScanFramework
	variable SlowScanDelta
	variable FastscanDelta
	variable i,j,k,l
	if (XorYscan == 0) //x direction scan
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
		
	elseif  (XorYscan == 1) //y direction scan
		ScanFramework[][0] = ypos - scansizeX / 2 //gPSscansizeX= fast width
		ScanFramework[][2] = ypos+scansizeX / 2
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
	
	endif //x or y direction scanning

	// INITIALIZE in and out waves
	//downinterpolation, scanspeeds will need to be adjusted to account for multiple cycles per point on the retrace
	// should leave downinterpolation, psvoltsloth, pslightsloth as they are and create new variables that are only used for the high speed
	//trEFM experiment that uses the existing vars and waves as a template	
	
	Make/O/N = (scanpoints, scanlines) Topography, ChargingRate, FrequencyOffset, Chi2Image
	Chi2Image=0

	
	SetScale/I x, ScanFrameWork[0][0], ScanFramework[0][2], "um", Topography, FrequencyOffset, ChargingRate, Chi2Image
	if(scanlines==1)
		SetScale/I y, ypos, ypos, Topography, FrequencyOffset, ChargingRate, Chi2Image
	else
		SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, FrequencyOffset, ChargingRate,Chi2Image
	endif
	
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
	
	Make/O/N = (Fitcyclepoints) voltagewave, lightwave, triggerwave, drivewave
	
	voltagewave = gentipwaveTemp
	lightwave = genlightwaveTemp
	triggerwave = gentriggerwaveTemp
	drivewave = gendrivewaveTemp		// for changing the drive ampltidue to shake piezo
	
	PSchunkpointssmall = (fitstoptime - fitstarttime)
	Make/O/N = (PSchunkpointssmall) CycleTime, ReadWaveFreqtemp	

	Variable cyclepoints = Fitcyclepoints
		cyclepoints *= numavgsperpoint	// Number of points per line	

	// this section creates the voltage and light waves, duplicates them and concatenates the results to a new ffPS wave		

	// Crude concatenation routine
	Duplicate/O lightwave, ffPSLightWave
	Duplicate/O voltagewave, ffPSVoltWave
	Duplicate/O triggerwave, ffPSTriggerWave
	Duplicate/O drivewave, ffPSDriveWave	// set lightwave from the panel to be drive amplitude and then 0 during region of interest
	
	cycles = 0					// i changed this because i am awesome -Jeff
	if (numavgsperpoint > 1)
		do
			Concatenate/NP=0 {voltagewave} ,ffPSVoltWave
			Concatenate/NP=0 {lightwave}, ffPSLightWave
			Concatenate/NP=0 {triggerwave}, ffPSTriggerWave
			Concatenate/NP=0 {drivewave}, ffPSDriveWave

			cycles += 1
		while (cycles < numavgsperpoint)
		
		// overwrite the originals
		Duplicate/O ffPSLightWave, lightwave
		Duplicate/O ffPSVoltWave, voltagewave
		Duplicate/O ffPSTriggerWave, triggerwave
		Duplicate/O ffPSDriveWave, drivewave
	endif

	k = 0
	do
		CycleTime[k]=k * (1/samplerate) * interpolation              //yet again phil does nothing.
		k += 1
	while (k < PSchunkpointssmall)
	
	variable starttimepoint = fitstarttime
	variable stoptimepoint = fitstoptime

	PSlength = scanpoints * cyclepoints
	PStimeofscan = (scanpoints * cyclepoints) / (samplerate) // time per line
	Upinterpolation = (PStimeofscan * samplerate) / (scanpoints)
	

	//******************  CCCCCCCCCCCCCCCCCC *******************************//
	//******************  DDDDDDDDDDDDDDDDDDD *******************************//	
	//***************** Open the scan panels ***********************************//
	
			// trefm charge creation/delay/ff-trEFM

	dowindow/f RingDownRateImage
	if (V_flag==0)
		Display/K=1/n=RingDownRateImage;Appendimage ChargingRate
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan (um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(62000,65000,48600),expand=.7
		ColorScale/C/N=text0/E/F=0/A=MC image=ChargingRate
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "hz/V^2"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=ChargingRate
	endif
	
	ModifyGraph/W=RingDownRateImage height = {Aspect, scansizeY/scansizeX}		

	dowindow/f TopographyImage
	if (V_flag==0)
		Display/K=1/n=TopographyImage;Appendimage Topography
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan(um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(65000,60000,48600),expand=.7	
		ColorScale/C/N=text0/E/F=0/A=MC image=Topography
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "um"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=Topography
	endif	
	
	dowindow/f FrequencyShiftImage
	if (V_flag==0)
		Display/K=1/n=FrequencyShiftImage;Appendimage FrequencyOffset
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan (um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(65000,65000,48600),expand=.7
		ColorScale/C/N=text0/E/F=0/A=MC image=FrequencyOffset
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "Hz"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=FrequencyOffset
	endif
	
	ModifyGraph/W=TopographyImage height = {Aspect, scansizeY/scansizeX}
	ModifyGraph/W=FrequencyShiftImage height = {Aspect, scansizeY/scansizeX}

	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=TopographyImage height = {Aspect, 1}
		ModifyGraph/W=RingDownRateImage height = {Aspect, 1}
		ModifyGraph/W=FrequencyShiftImage height = {Aspect, 1}
	endif

	//**************** End scan panel setup  ***************//
	//******************  DDDDDDDDDDDDDDDDDDD *******************************//

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
		
	// HStrEFM needs no FBL on the LIA phase angle	

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

	//move to initial scan point, read location, and print some beginning of experiment data
	if (xoryscan == 0)	
		MoveXY(ScanFramework[0][0], ScanFramework[0][1])
	elseif (XorYscan == 1)
		MoveXY(ScanFramework[0][1], ScanFramework[0][0])
	endif
	
	SetCrosspoint ("FilterOut","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Defl","OutC","OutA","OutB","Ground","OutB","DDS")
	variable currentX = td_ReadValue("XSensor")
	variable currentY = td_ReadValue("YSensor")

	//************************************* XYupdownwave is the final, calculated, scaled values to drive the XY piezos ************************//	
	if (xoryscan == 0)	//x  scan direction
		XYupdownwave[][][0] = (ScanFrameWork[q][0] + FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][1] = (ScanFrameWork[q][2] - FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][2] = (ScanFrameWork[q][1]) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][3] = (ScanFrameWork[q][3]) / YLVDTsens / 10e5 + YLVDToffset
	elseif (xoryscan == 1)	
		XYupdownwave[][][2] = (ScanFrameWork[q][0] + FastScanDelta*p) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][3] = (ScanFrameWork[q][2] - FastScanDelta*p) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][0] = (ScanFrameWork[q][1]) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][1] = (ScanFrameWork[q][3]) / XLVDTsens / 10e5 + XLVDToffset
	endif
	
	//Set up the tapping mode feedback
	td_wv(LockinString + "Amp",CalHardD) 
	td_wv(LockinString + "Freq",CalEngageFreq) //set the frequency to the resonant frequency
	SetFeedbackLoop(2,"Always","Amplitude", Setpoint,-PGain,-IGain,-SGain,"Output.Z",0)	

	// Turns voltage and light to always be on

	
	Sleep/S 1.5
	
	//******************  FFFFFFFFFFFFFFFFFFFFFF *******************************//


	// xx delete
	variable heightbefore, heightafter
	

	//*********************************************************************//
	///Starting imaging loop here
	
	i=0
	do
		starttime2 =StopMSTimer(-2) //Start timing the raised scan line
		print "line ", i+1

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
		Topography[][i] = -(ReadwaveZ[p] * ZLVDTSens)//-ReadWaveZmean
		DoUpdate
	
		//****************************************************************************
		//*** SET RETRACE VALUES HERE (EXPERIMENTAL MEASUREMENT)
		//*****************************************************************************		
		td_stopInWaveBank(-1)
		td_stopOutWaveBank(-1)

//		error+= td_xSetInWave(1,"Event.2", LockinString + "FreqOffset", ReadwaveFreq,"",1) // getting read frequency offset	
//		error+= td_xsetoutwavepair(0,"Event.2,repeat", "Output.B", voltagewave,"Output.A", lightwave,-1)
		
		error += td_xSetInWave(1, "Event.2", LockinString + "R", readwavefreq, "", 1)		// writes amplitude to ReadWaveFreq, should rename this!
		error += td_xSetOutWave(0, "Event.2,Repeat", LockinString + "Amp", drivewave, -1)
		
		//stop amplitude FBLoop and start height FB for retrace
		StopFeedbackLoop(2)		

		// print height
		heightbefore = td_rv("Zsensor")*td_rv("ZLVDTSens")

		// to keep tip from being stuck
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-500*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
		sleep/S 1
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
		sleep/s 1

		//print height 
		//print td_rv("Zsensor")*td_rv("ZLVDTSens")
		heightafter = td_rv("Zsensor")*td_rv("ZLVDTSens")
		print (heightafter - heightbefore)*1e9, " nanometerz"

		
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

		td_wv("Output.A",LightOn)	// light
		td_wv("Output.B",RingDownVoltage)	// voltage

		if (stringmatch("ARC.Lockin.0." , LockinString))
//			SetFeedbackLoop(4, "always", LockinString +"theta", NaN, EFMFilters[%trEFM][%PGain], EFMFilters[%trEFM][%IGain], 0, LockinString+"FreqOffset",  EFMFilters[%trEFM][%DGain])
		else
//			SetFeedbackLoopCypher(1, "always", LockinString +"theta", NaN, EFMFilters[%trEFM][%PGain], EFMFilters[%trEFM][%IGain], 0, LockinString+"FreqOffset",  EFMFilters[%trEFM][%DGain])
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
		j=0

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
			ChargingRate[scanpoints-j-1][i]=(W_Coef[2] * calResFreq * pi)	// extra conversion to get into Q
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
			td_StopOutWaveBank(0)
			td_wv("Output.A",0)	// light
			td_wv("Output.B",0)	// voltage
//			if (stringmatch("ARC.Lockin.0." , LockinString))
//				StopFeedbackLoop(4)
//			else
//				StopFeedbackLoopCypher(1)
//			endif	
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
