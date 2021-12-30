#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function PointScanGMode(xpos, ypos, liftheight,DigitizerAverages,DigitizerSamples,DigitizerPretrigger)
	
	Variable xpos, ypos, liftheight, DigitizerAverages, DigitizerSamples, DigitizerPretrigger

	String savDF = GetDataFolder(1)
	
	Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
	Wave CSACQUISITIONCONFIG = root:packages:GageCS:CSACQUISITIONCONFIG
	Wave CSTRIGGERCONFIG = root:packages:GageCS:CSTRIGGERCONFIG
	NVAR OneOrTwoChannels = root:packages:trEFM:ImageScan:OneorTwoChannels
	
	CSACQUISITIONCONFIG[%SegmentCount] = DigitizerAverages
	CSACQUISITIONCONFIG[%SegmentSize] = DigitizerSamples
	CSACQUISITIONCONFIG[%Depth] = DigitizerPretrigger
	CSACQUISITIONCONFIG[%TriggerHoldoff] =  DigitizerPretrigger

	CSTRIGGERCONFIG[%Source] = -1 //External Trigger
	
	GageSet(-1)
	
	SetDataFolder root:Packages:trEFM
	Nvar pgain, sgain, igain, adcgain, setpoint,adcgain
	Svar LockinString
	Nvar XLVDTsens
	NVAR elecdrive
	NVar interpval
	Wave EFMFilters = root:packages:trEFM:EFMFilters
	Variable XLVDToffset = td_Rv("XLVDToffset")
	GetGlobals()
	
	SetDataFolder root:Packages:trEFM:VoltageScan
	Nvar calsoftd, calresfreq, calphaseoffset, calengagefreq, calhardd
	ResetAll()
	
	SetDataFolder root:Packages:trEFM:WaveGenerator
	Wave gentipwave, gentriggerwave, genlightwave, gendrivewave
	Nvar numcycles
	CommitDriveWaves(interpval=interpval)
	
	SetDataFolder root:Packages:trEFM:PointScan:FFtrEFM

	Make/O/N = (DigitizerSamples,DigitizerAverages) gagewave
	Make/O/N = (DigitizerSamples,DigitizerAverages) ch2_wave
	Make/O/N = (DigitizerSamples) shiftwave
	Make/O/N = (400 * numcycles) phasewave
	Make/O/N = 400 phasewaveavg
	
	// Dummy wave for checking inwavetiming
	Make/O/N = (800*interpval) tempwaveavg
////////////////////////// CALC INPUT/OUTPUT WAVES \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

//////////////////////////    SETTINGS   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	
	SetPassFilter(1, a = EFMFilters[%EFM][%A], b = EFMFilters[%EFM][%B], fast = EFMFilters[%EFM][%Fast], i = EFMFilters[%EFM][%i], q = EFMFilters[%EFM][%q])

	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
	
	// Initial settings for outputs.
	td_WV("Output.A", 0)
	td_WV("Output.B", 0)
	td_WV("Output.C", 0)
	
	MoveXY(xpos, ypos) // Move to xy, keeping the tip raised away from the surface
	
	SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","OutB","DDS")

////////////////////////// SET EFM HARDWARE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	NVAR xigain, zigain

	td_WV(LockinString + "Amp", calhardd)
	td_WV(LockinString + "freq", calengagefreq)
	
	SetFeedbackLoop(3, "Always", LockinString + "R", setpoint, -pgain, -igain, -sgain, "Height", 0)
	StopFeedbackLoop(2)
	// Wait for the feedback loops and frequency to settle.
	variable startTime = StopMSTimer(-2)
	do 
	
	while((StopMSTimer(-2) - StartTime) < 2*1e6) 
				
	Sleep/S .5

//////////////////////////END SETTINGS\\\\\\\\\\\\\\\

//////////////////////////SCAN\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	Variable i = 0

	// Get the waves ready to read/write when Event 2 is fired.
	NVAR interpval
//	td_xSetOutWavePair(1, "Event.2,Always", "Output.A", genlightwave, "Output.C", gentriggerwave, interpval)
//	td_xSetOutWave(1, "Event.2,Always", "Output.A", genlightwave, interpval)
//	td_xSetOutWavePair(0, "Event.2,Always", "Output.B", gentipwave, LockinString + "Amp", gendrivewave, interpval)
	
//	td_xSetOutWavePair(1, "Event.2,Always", "Output.A", genlightwave, "Output.C", gentriggerwave, interpval)
//	td_xSetOutWave(0, "Event.2,Always", "Output.B", gentipwave,interpval)

	NVAR Cutdrive = root:packages:trEFM:cutDrive
	if (cutDrive == 0)
//		td_xSetOutWavePair(1, "Event.2,Always", "Output.A", genlightwave, "Output.C", gentriggerwave, interpval)
		td_xSetOutWavePair(1, "Event.2,Always", "Output.A", genlightwave, "Output.B", gentipwave, 1)
//		td_xSetOutWave(0, "Event.2,Always", "Output.B", gentipwave,interpval)
	elseif (cutDrive == 1)
		td_xSetOutWavePair(0, "Event.2,Always", "Output.A", genlightwave, "Output.B", gentipwave, 1)
		td_xSetOutWave(1, "Event.2,Always", LockinString + "Amp", gendrivewave, 1)
	endif
	
	// Dummy wave
	td_xSetInWave(2, "Event.2" , LockinString + "freqOffset", tempwaveavg, "", 1)
	
	SetPassFilter(1, a = EFMFilters[%EFM][%A], b = EFMFilters[%EFM][%B], fast = EFMFilters[%EFM][%Fast], i = EFMFilters[%EFM][%i], q = EFMFilters[%EFM][%q])

	Variable currentz = td_RV("ZSensor") * GV("ZLVDTSens")

	// Raise up to the specified lift height.
//	SetFeedbackLoop(3, "always",  "ZSensor", (currentz - 100 * 1e-9)/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
//	sleep/S 1
//	SetFeedbackLoop(3, "Always", "ZSensor", (currentz - liftheight * 1e-9) / GV("ZLVDTSens"), 0, EFMFilters[%ZHeight][%IGain], 0, "Output.Z", 0)  
//	Sleep/S 1/30 // To avoid sparking.

	SetFeedbackLoop(3, "always",  "ZSensor",  (currentz - 100 * 1e-9)/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0, name="OutputZ", arcZ=1) // note the integral gain of 10000
	sleep/S 1
	SetFeedbackLoop(3, "always",  "ZSensor", (currentz - liftheight * 1e-9) / GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0, name="OutputZ", arcZ=1) // note the integral gain of 10000
	sleep/s 1

	// Set the Cantilever to Resonance.
//	td_WV(LockinString + "Amp", calsoftd)
//	td_WV(LockinString + "freq", calresfreq)
//	td_WV(LockinString + "PhaseOffset", calphaseoffset)
	
	// Adding electric tuning test here
//		SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","DDS","Ground")
//		td_WV(LockinString + "Amp", 2)

	// Write Chip DDS
	SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","DDS","OutA","OutB","Ground","DDS","Ground")

	XPTPopupFunc("CypherHolderOut1Popup", 18, "Ground")
	XPTButtonFunc("WriteXPT")
	
	print td_rv("DDSDCOffset0")

	variable EAmp = GV("NapDriveAmplitude")
	variable EFreq = GV("NapDriveFrequency")
	variable EOffset = GV("NapTipVoltage")
	variable EPhase = GV("NapPhaseOffset")

	td_WriteValue("DDSAmplitude0", 0)
	td_WriteValue("DDSDCOffset0", 0)	
	Sleep/S 1/30 // To avoid sparking.
	td_WriteValue("DDSDCOffset0",EOffset)	
	td_WriteValue("DDSAmplitude0",EAmp)	
	td_WriteValue("DDSFrequency0",EFreq)
	td_WriteValue("DDSPhaseOffset0",EPhase)
	
	// Using AWG to drive the sample instead 
	if (elecDrive != 0) 
		
		LoadArbWave(EFreq, EAmp, EOffset /2)
		td_WriteValue("DDSAmplitude0", 0)		// turn off DDS amplitude
		SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","Ground","OutA","Ground","Ground","OutB","Ground")
	
	endif
	
	
	// Wait for frequency to stabilize.
	startTime = StopMSTimer(-2)
	do 
	while((StopMSTimer(-2) - StartTime) < 300*1e3) 

	Sleep/S 1/30
	GageAcquire()
	// Fire data collection event.
	td_WriteString("Event.2", "Once")
	GageWait(600)
	
	CheckInWaveTiming(tempwaveavg) // wait until the data is done collecting.
	
	// Stop data collection.
	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	
	// Reset outputs to zero.
	td_WV("Output.A", 0)
	td_WV("Output.B", 0)
	td_WV("Output.C", 0)

	GageTransfer(1, gagewave)
	
	if (OneOrTwoChannels == 1)
		GageTransfer(2, ch2_wave)
	endif
	
//	AnalyzePointScan(PIXELCONFIG, gagewave,shiftwave)
	
	if (ElecDrive != 0)
		TurnOffAWG()

		startTime = StopMSTimer(-2)
		do 
		while((StopMSTimer(-2) - StartTime) < 300*1e3) 

	endif
	
	// reset the dds settings.
	SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","Ground", "DDS")

	XPTPopupFunc("CypherHolderOut1Popup", 21, "ContShake")
	XPTButtonFunc("WriteXPT")
	
	td_WV(LockinString + "Amp", calhardd)
	td_WV(LockinString + "freq", calengagefreq)
	td_WV(LockinString + "PhaseOffset", calphaseoffset)
	td_WV(LockinString + "freqOffset", 0)
	
	SetPassFilter(1, fast = 1000, i = 1000,q = 1000)
	
	StopFeedbackLoop(4)
	
	td_WV(LockinString + "freq", calresfreq)
	td_WV(LockinString + "freqOffset", 0)
	
	// Send the tip back to the surface.
	SetFeedbackLoop(3, "Always", "Amplitude", setpoint, -pgain, -igain, -sgain, "Height", 0)
	
	startTime = StopMSTimer(-2)	
	do  // waiting loop till we recontact surface
		doUpdate
	while((StopMSTimer(-2) - StartTime) < 1e6*.2)

//////////////////////////END SCAN\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	
	//SetFeedbackLoop(3, "Always", "Amplitude", setpoint, -pgain, -igain, -sgain, "Height", 0)
	ResetAll()
	
	SetDataFolder savDF
End

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

