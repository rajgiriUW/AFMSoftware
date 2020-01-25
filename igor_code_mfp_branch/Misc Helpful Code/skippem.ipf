
Function skippem(xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed)
	
	Variable xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed
	Variable saveOption = 0
	
	String savDF = GetDataFolder(1) // locate the current data folder
	SetDataFolder root:packages:trEFM
	Svar LockinString
	
	SetDataFolder root:packages:trEFM:ImageScan
	Nvar numavgsperpoint

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
	Variable FreqOffsetNorm = 500
	
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
	
	
	Make/O/N = (scanpoints, scanlines) Topography, ChargingRate, FrequencyOffset, CPDImage

	
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
	setLockinPhase(-9) //this phase is selected for a frequency of 1000 hz
	setLockinSensitivity(LockinSensitivity) // 17 sets the sensitivity of the lockin to 1mv/na //20 is a good value
	sendLockinString("FMOD0") //sets source to external 
	Setvf(0, ACFrequency,"WG")
	Make/O/N=(scanpoints) CPDTrace
	Variable pointsPerPixel = timeperpoint * samplerate * 1e-3
	Variable pointsPerLine = pointsPerPixel * scanpoints
	make/o/n=(pointsPerPixel) CPDWaveTemp
	
	variable lastvoltage, lk, ll
	make/o/n=(pointsPerPixel) CPDWaveLastPoint
	
	Variable timeofscan = timeperpoint * 1e-3 * scanpoints
	Upinterpolation = (timeofscan * samplerate) / (scanpoints)
	print timeofscan,upinterpolation, lockintimeConstant,lockinsensitivity

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
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "hz/V^2"
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
	endif
	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=TopgraphyImage height = {Aspect, 1}
		ModifyGraph/W=ChargingRateImage height = {Aspect, 1}
		ModifyGraph/W=FrequencyOffsetImage height = {Aspect, 1}
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
	SetFeedbackLoop(5, "Always", LockinString+"theta", td_rv(LockinString+"theta"), -0.02, 0, 0, "Output.A", 0)
	SetFeedbackLoop(4, "Always", "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], 0, "Output.B", 0)	
	SetFeedbackLoop(3, "Always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,1000,0, "Output.Z",0)
	
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

	MoveXY(ScanFramework[0][0], ScanFramework[0][1])

	SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","In0","DDS")
	
	variable currentX = td_ReadValue("XSensor")
	variable currentY = td_ReadValue("YSensor")

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
		
		SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","Ground","DDS")

		SetPassFilter(1,q = ImagingFilterFreq, i = ImagingFilterFreq)

		td_wv(LockinString + "Amp",CalHardD) 
		td_wv(LockinString + "Freq",CalEngageFreq) //set the frequency to the resonant frequency
		td_wv(LockinString + "FreqOffset",0)
		td_wv("Output.A",0)
		td_wv("Output.B",0)

		setvfsin(0, ACFrequency)
		
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
		SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","In0","DDS")
		 td_xSetInWave(1,"Event.2", "Output.B", CPDWave,"",-1) 
		 
		//stop amplitude FBLoop and start height FB for retrace
		StopFeedbackLoop(2)		
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,1000,0, "Output.Z",0) // note the integral gain of 1000
		
		error+= td_xsetoutwavePair(1,"Event.2", "ARC.PIDSLoop.0.Setpoint", Xupwave,"ARC.PIDSLoop.1.Setpoint", Yupwave,-UpInterpolation)	
			if (error != 0)
				print i, "errorONB7", error
			endif
		
		error+= td_xsetoutwave(2, "Event.2", "ARC.PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)
			if (error != 0)
				print i, "errorONB8", error
			endif
		
		SetPassFilter(1, q = EFMFilters[%KP][%q], i = EFMFilters[%KP][%i])
		
		lastvoltage = 0
		if (i != 0)
			lk = 0
			ll = (scanpoints-1)*pointsPerPixel
			do
				CPDWaveLastPoint[lk] = CPDWaveLast[ll]
				ll += 1
				lk += 1
			while (lk < pointsPerPixel)
			
			lastvoltage = mean(CPDWaveLastPoint)
			if (lastvoltage>6 || lastvoltage <-6)
				lastvoltage=0
			endif	
			printf "LastVoltage is %g\r", lastvoltage		
			td_wv("Output.B", lastvoltage) //get the intial tip voltage close to where it was before
		endif
		
		SetFeedbackLoop(5,"Always", LockinString+"theta", td_rv(LockinString+"theta"), -0.02, 0, 0, "Output.A", 0)
		setvfsin(ACVoltage, ACFrequency)
		SetFeedbackLoop(4, "always",  "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], 0, "Output.B", 0) 
	
		//Fire retrace event here
		error += td_WriteString("Event.2", "Once")

		CheckInWaveTiming(CPDWave)
		// ************  End of Retrace 		

		//**********************************************************************************
		//***  PROCESS DATA AND UPDATE GRAPHS
		//*******************************************************************************
		j=0
		do
			CPDWaveTemp=0
			k=0
			l=j*pointsPerPixel
			
			do
				CPDWaveTemp[k]=CPDWave[l]
				
				k+=1
				l+=1
			while (k<pointsPerPixel)
		
			CPDImage[scanpoints-j-1][i]=mean(CPDWaveTemp)
		
			j+=1
		while (j<scanpoints)
		


		
		CPDTRace = CPDImage[p][i]
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
			
			td_stopInWaveBank(-1)
			td_stopOutWaveBank(-1)
			
			td_wv(LockinString + "Amp",CalHardD) 
			td_wv(LockinString + "Freq",CalEngageFreq)
			td_wv(LockinString + "FreqOffset",0)	
				
			SetFeedbackLoop(2,"Always","Amplitude", Setpoint,-PGain,-IGain,-SGain,"Height",0)	
				
		endif 
	
		print "Time for last scan line (seconds) = ", (StopMSTimer(-2) -starttime2)*1e-6, " ; Time remaining (in minutes): ", ((StopMSTimer(-2) -starttime2)*1e-6*(scanlines-i-1)) / 60
		i += 1
		
		//Reset the primary inwaves to Nan so that gl_checkinwavetiming function works properly
		CPDWaveLast[] = CPDWave[p]
		ReadWaveZ[] = NaN
		CPDWave[] = NaN
		
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
