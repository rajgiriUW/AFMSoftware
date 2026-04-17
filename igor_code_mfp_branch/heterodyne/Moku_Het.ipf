#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function Moku_HK(xpos, ypos, liftheight, [wACvoltage, interpolation])
// Heterodyne SKPM
// Send frequency to AC wAC signal such wAC - w0 = w1
// w0 = first resonance
// w1 = second resonance ~6.12 X the first resonance
// wAC = AC voltage, set by function generator
// wACvoltage = AC voltage on function generator
// Set wAC to be w2-w1, we topo modulate at w1 and detect at w1+wAC = w2
	variable xpos, ypos, liftheight, wACvoltage, interpolation

	if (ParamIsDefault(interpolation))
		interpolation = 1	
	endif
	
	if (xpos >=45)
	 	xpos = 45
	elseif (xpos <= -45)
	 	xpos = -45
	endif

	if (ypos >=45)
	 	ypos = 45
	elseif (ypos <= -45)
	 	ypos = -45
	endif

	// Global variables needed
	GetGlobals()

	SetDataFolder root:packages:trEFM:PointScan:SKPM
	variable/G freq_PGain
	variable/G freq_IGain 
	variable/G freq_DGain
	
	SetDataFolder root:packages:trEFM
	SVAR LockinString	
	NVAR calresfreq = root:packages:trEFM:VoltageScan:Calresfreq
	NVAR CalEngageFreq = root:packages:trEFM:VoltageScan:CalEngageFreq
	NVAR CalHardD = root:packages:trEFM:VoltageScan:CalHardD
	NVAR CalSoftD = root:packages:trEFM:VoltageScan:CalsoftD
	NVAR CalPhaseOffset = root:packages:trEFM:VoltageScan:CalPhaseOffset
	NVAR pgain, sgain, igain, adcgain, setpoint
	Wave EFMFilters = root:packages:trEFM:EFMFilters
	
	NVAR secondmode = root:packages:trEFM:TF:secondmode
	NVAR firstmode = root:package:trEFM:calresfreq

	if (DataFolderExists("root:packages:trEFM:TF") == 0)
		Abort "Open the TF Panel first from trEFM menu."
	endif

	if (secondmode == 0 || numtype(secondmode) == 2)
		Abort "You need to run w1w2_tune() before proceeding."
	endif

	// Local variables
	variable error = 0
	variable ReadWaveZmean
	Make/O/N=(8000) CPDvstime = nan
	
	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	SetPassFilter(1, a = EFMFilters[%EFM][%A], b = EFMFilters[%EFM][%B], fast = EFMFilters[%EFM][%Fast], i = EFMFilters[%EFM][%i], q = EFMFilters[%EFM][%q])

	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
	
	td_WV("Output.A", 0)
	td_WV("Output.B", 0)
	
	MoveXY(xpos, ypos) // Move to xy, keeping the tip raised away from the surface

//	Manually lift tip
	td_WV(LockinString +"Freq", calengagefreq)
	td_WV(LockinString +"Amp", calhardd)
	td_WV(LockinString + "PhaseOffset", calphaseoffset)
	
	// Lower the tip to tap the surface.
	SetFeedbackLoop(2, "Always", LockinString +"R", setpoint, -pgain, -igain, -sgain, "Output.Z", 0)
	Sleep/S 1.5
	
	Variable z1= td_readvalue("ZSensor") * GV("ZLVDTSens")
//	StopFeedbackLoop(2)
//	SetFeedbackLoop(3, "always",  "ZSensor", (z1 - liftheight * 1e-9) / GV("ZLVDTSens"), 0, EFMFilters[%ZHeight][%IGain], 0, "Output.Z", 0)	

	// Set up for FM-SKPM point scan
	SetCrosspoint ("Ground","BNCIn1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","BNCIn2","DDS")

	// Apply AC at w1 to the Chip
//	loadarbwaveSiglent(secondmode + firstmode, wACvoltage, wACvoltage / 2)

//	td_wv((LockinString + "Amp"), calsoftd) //set the amplitude from the grab tune function
//	td_wv((LockinString + "Freq"), CalResFreq) //set the frequency to the resonant frequency
//	td_wv((LockinString + "PhaseOffset"), CalPhaseOffset)  // phase offset also comes from calibration panel

	// Deflection signal goes to Moku LIA. Detects the Amplitude at w1 
	// Input B 
	error += td_xsetinwave(0, "Event.2, Always", "Output.B", CPDvsTime, "", interpolation)
//	SetFeedbackLoop(4, "Always",  "Input.B", 0, 0,  300, 0, "DDSDCOffset0", 0)   // InputQ = $Lockin.0.Q , quadrature lockin output 
	SetFeedbackLoop(4, "always",  "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], 0, "Output.B",  EFMFilters[%KP][%DGain]) 

	variable startTime = StopMSTimer(-2)
	do 
	while((StopMSTimer(-2) - StartTime) < 0.5*1e6) 
	
	td_WriteString("Event.2", "Once")
	CheckInWaveTiming(CPDvsTime)
	
	Beep

end