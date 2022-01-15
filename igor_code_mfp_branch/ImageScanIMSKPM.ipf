#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ImageScanIMSKPM_AM(xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed)
	
	Variable xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed
	
	String savDF = GetDataFolder(1) // locate the current data folder
	SetDataFolder root:packages:trEFM
	Svar LockinString
	
	SetDataFolder root:packages:trEFM:ImageScan
	Nvar numavgsperpoint
	NVAR numavg = root:packages:trEFM:PointScan:SKPM:numavg
	
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	variable/G freq_PGain
	variable/G freq_IGain 
	variable/G freq_DGain

	SetDataFolder root:Packages:trEFM:ImageScan:SKPM

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
	
	ResetAll()	
	Downinterpolation = ceil((50000 * (scansizex / scanspeed) / scanpoints))
	DoUpdate

	//SETUP Scan Framework and populate scan waves 
	// Then initialize all other in and out waves
	
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
	
	FrequencyList()
	Wave Frequency_List = root:packages:trEFM:PointScan:SKPM:Frequency_List
		
	Make/O/N = (scanpoints, scanlines) Topography, IMTauImage
	Make/O/N = (scanpoints, scanlines, numpnts(frequency_list)) IMSKPM_Matrix

	if (XFastEFM == 1 && YFastEFM == 0)
		SetScale/I x, ScanFrameWork[0][0], ScanFramework[0][2], "um", Topography, IMTauImage
		if(scanlines==1)
			SetScale/I y, ypos, ypos, Topography, IMTauImage
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, IMTauImage
		endif
	

	elseif (XFastEFM == 0 && YFastEFM == 1)
		SetScale/I x, ScanFrameWork[0][2], ScanFramework[0][0], "um", Topography, IMTauImage
		if(scanlines==1)
			SetScale/I y, ypos, ypos, Topography, IMTauImage
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, IMTauImage
		endif
	
	endif

	Make/O/N = (scanpoints) ReadWaveZ, ReadWaveZback, Xdownwave, Ydownwave, Xupwave, Yupwave
	Make/O/N = (scanpoints, scanlines, 4) XYupdownwave
	ReadWaveZ = NaN

	//POPULATE Data/Drive waves by experiment, these settings should not change
	// from jump to jump, cycle to cycle, or between the trace and retrace
	// vars that do change are initialized below
	//***********************************************************************

	GPIBsetup()
	
	if (gWGDeviceAddress != 0)
		Setvf(0, ACFrequency,"WG")
	else
		TurnOffAWG()
	endif
	
	Variable pointsPerPixel = timeperpoint * samplerate * 1e-3
	Variable pointsPerLine = pointsPerPixel * scanpoints
	
	variable lastvoltage, lk, ll
	
	Variable timeofscan = timeperpoint * 1e-3 * scanpoints
	Upinterpolation = (timeofscan * samplerate) / (scanpoints)

	//***************** Open the scan panels ***********************************//
	
	dowindow/f IMTau
	if (V_flag==0)
		Display/K=1/n=IMTau;Appendimage IMTauImage
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan (um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(62000,65000,48600),expand=.7
		ColorScale/C/N=text0/E/F=0/A=MC image=IMTauImage
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "V"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=IMTauImage
	endif
	
	ModifyGraph/W=IMTau height = {Aspect, scansizeY/scansizeX}		

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
	ModifyGraph/W=IMTau height = {Aspect, scansizeY/scansizeX}
	
	//**************** End scan panel setup  ***************//

	//******************** SETUP all hardware, FBL, XPT and external hdwe settings that are common
	//*******************  to both the trace and retrace **************

	// BEcause IM-SKPM is so slow, the imaging is different than the other engines.
	// Here, we will take a topography, then in the retrace we will maintain that height at each point and call the IM-SKPM function
	// Each data trace will then be saved as a 3D matrix (of IM-SKPM vs frequency curves) and a 2D Matrix (of taus)
	
	// Set up the crosspoint, note that KP crosspoint settings change between the trace and retrace and are reset below

	//stop all FBLoops except for the XY loops
	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
	
	variable error = 0
	td_StopInWaveBank(-1)
		
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

		LineNum = i
		
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
		
		SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","Ground","DDS")
		SetPassFilter(1, q = ImagingFilterFreq, i = ImagingFilterFreq)

		td_wv(LockinString + "Amp", CalHardD) 
		td_wv(LockinString + "Freq", CalEngageFreq) //set the frequency to the resonant frequency
		td_wv(LockinString + "FreqOffset", 0)
		td_wv("Output.A", 0)
		td_wv("Output.B", 0)
		td_wv("Output.C",0)

		if (gWGDeviceAddress != 0)
			setvf(0, ACFrequency,"WG")
		else
			TurnOffAWG()
		endif
		
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
		ReadWaveZmean = Mean(ReadwaveZ) * ZLVDTSens
		Topography[][i] = -(ReadwaveZ[p] * ZLVDTSens)//-ReadWaveZmean)
		DoUpdate
	
		//****************************************************************************
		//*** SET RETRACE
		//*****************************************************************************		
		td_stopInWaveBank(-1)
		td_stopOutWaveBank(-1)

		heightbefore = td_rv("Zsensor")*td_rv("ZLVDTSens")
		 
		//stop amplitude FBLoop and 
		StopFeedbackLoop(2)		

		// to keep tip from being stuck
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-500*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0, name="OutputZ") // note the integral gain of 10000
		sleep/S 1
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0, name="OutputZ", arcZ=1) // note the integral gain of 10000
		sleep/s 1
		
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

//		SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","In0","DDS")
		SetPassFilter(1, q = EFMFilters[%KP][%q], i = EFMFilters[%KP][%i])
		
		if (gWGDeviceAddress != 0)
			setvf(ACVoltage, ACFrequency,"WG")		
		else
			loadarbwave(ACFrequency, ACVoltage, 0)	
		endif

		//Fire retrace event here
//		error += td_WriteString("Event.2", "Once")

		j = 0
		
		do
			error += td_writevalue(	"$outputXLoop.Setpoint", Xupwave[j])
			error += td_writevalue(	"$outputYLoop.Setpoint", Yupwave[j])
			error += td_writevalue("ARC.PIDSLoop.3.Setpoint", ReadWaveZback[j])
			
			if (error != 0)
				print(error)	
			endif
			
			print "Line ", i, " Pixel ", j
		
//			PointScanIMSKPM_AM(Xupwave[j], Yupwave[j], liftheight, numavg)
			Wave IMWavesAvg =  root:packages:trEFM:PointScan:SKPM:IMWavesAvg
			Make/D/N=3/O W_coef
			W_coef[0] = {1e-5,-.15,.05}
			FuncFit/Q/NTHR=1 imskpm W_coef  IMWavesAvg /X=frequency_list /D 
			
			IMTauImage[i][numpnts(ReadWaveZBack) - j - 1] = W_Coef[0]
			IMSKPM_Matrix[i][numpnts(ReadWaveZBack) - j - 1][] = IMWavesAvg[r]
			j += 1
			
		while (j <= numpnts(ReadWaveZBack))
		
		SetDataFolder root:Packages:trEFM:ImageScan:SKPM
		setvf(0, ACFrequency,"WG")
		print td_wv("Output.A", 0)

		CheckInWaveTiming(IMTauImage)
	
		//**********************************************************************************
		//***  PROCESS DATA AND UPDATE GRAPHS
		//*******************************************************************************
		j = 0
		do
			// Stub for when I add the image processing code
			j += 1
			
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
		ReadWaveZ[] = NaN
				
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
