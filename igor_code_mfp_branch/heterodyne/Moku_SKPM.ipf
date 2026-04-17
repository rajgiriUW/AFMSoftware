#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Moku-based AM-SKPM, to test out the coding functionality
function MokuPS_AM(xpos, ypos, liftheight, [interpolation])
// Moku hookups <---> ARC
// Input 1 <--> Defl
// Input 2 <--> BNCOut2 (DDS)
// Output 1 <--> BNCIn2 (I, in-phase)
// Output 2 <--> BNCIn1 (Q, quadrature, the signal we want)
	variable xpos, ypos, liftheight, interpolation

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
	
	SetDataFolder root:packages:trEFM
	SVAR LockinString	
	NVAR calresfreq = root:packages:trEFM:VoltageScan:Calresfreq
	NVAR CalEngageFreq = root:packages:trEFM:VoltageScan:CalEngageFreq
	NVAR CalHardD = root:packages:trEFM:VoltageScan:CalHardD
	NVAR CalSoftD = root:packages:trEFM:VoltageScan:CalsoftD
	NVAR CalPhaseOffset = root:packages:trEFM:VoltageScan:CalPhaseOffset
	NVAR pgain, sgain, igain, adcgain, setpoint
	Wave EFMFilters = root:packages:trEFM:EFMFilters

	// Electric Tune variables
	variable EAmp = GV("NapDriveAmplitude")
	variable EFreq = GV("NapDriveFrequency")
	variable EOffset = GV("NapTipVoltage")
	variable EPhase = GV("NapPhaseOffset")
	wave NapVariablesWave = root:packages:MFP3D:Main:Variables:NapVariablesWave
	variable PotentialIGain = NapVariablesWave[%PotentialIGain][%Value]
	
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

	// Tap on surface, then lift
	LiftTo(liftheight, 0, verbose=1)

	// Set up for AM-SKPM point scan
	SetCrosspoint ("Ground","BNCIn1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutB","DDS","Ground","DDS","Ground")
	td_WriteValue("DDSAmplitude0",EAmp)	
	td_WriteValue("DDSFrequency0",EFreq)	
	td_WriteValue("DDSPhaseOffset0",EPhase)
	td_WriteValue("DDSDCOffset0", EOffset)

	error += td_xsetinwave(0, "Event.2, Always", "DDSDCOffset0", CPDvsTime, "", interpolation)
	print error
	
	SetFeedbackLoop(4, "Always",  "Input.B", 0, 0,  1000, 0, "DDSDCOffset0", 0)   // InputQ = $Lockin.0.Q , quadrature lockin output 
//	SetFeedbackLoop(5, "Always",  "Potential", td_rv("Potential"), 1,  0, 0, "Output.B", 0)   // InputQ = $Lockin.0.Q , quadrature lockin output 

	variable startTime = StopMSTimer(-2)
	do 
	while((StopMSTimer(-2) - StartTime) < 0.5*1e6) 
	
	td_WriteString("Event.2", "Once")
	CheckInWaveTiming(CPDvsTime)

//	td_StopInWaveBank(-1)
//	td_StopOutWaveBank(-1)


//	doscanfunc("StopEngage")
	Beep	
	
end

// Stub for conventional FM Point Scan
function MokuPSFM(xpos, ypos, liftheight, [interpolation])
// Moku hookups <---> ARC
// Input 1 <--> Defl
// Input 2 <--> BNCOut2 (DDS)
// Output 1 <--> BNCIn2 (I, in-phase)
// Output 2 <--> BNCIn1 (Q, quadrature, the signal we want)
	variable xpos, ypos, liftheight, interpolation

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

	// Electric Tune variables
	variable EAmp = GV("NapDriveAmplitude")
	variable EFreq = GV("NapDriveFrequency")
	variable EOffset = GV("NapTipVoltage")
	variable EPhase = GV("NapPhaseOffset")
	wave NapVariablesWave = root:packages:MFP3D:Main:Variables:NapVariablesWave
	variable PotentialIGain = NapVariablesWave[%PotentialIGain][%Value]
	
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

	// Tap on surface, then lift
	LiftTo(liftheight, 0, verbose=1)

	// Set up for FM-SKPM point scan
	SetCrosspoint ("Ground","BNCIn1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutB","DDS","Ground","BNCIn2","DDS")

	td_wv((LockinString + "Amp"), calsoftd) //set the amplitude from the grab tune function
	td_wv((LockinString + "Freq"), CalResFreq) //set the frequency to the resonant frequency
	td_wv((LockinString + "PhaseOffset"), CalPhaseOffset)  // phase offset also comes from calibration panel

	error += td_xsetinwave(0, "Event.2, Always", "Output.B", CPDvsTime, "", interpolation)
//	SetFeedbackLoop(4, "Always",  "Input.B", 0, 0,  300, 0, "DDSDCOffset0", 0)   // InputQ = $Lockin.0.Q , quadrature lockin output 
	SetFeedbackLoop(4, "always",  "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], 0, "Output.B",  EFMFilters[%KP][%DGain]) 
//	SetFeedbackLoop(5, "Always", LockinString+"theta", td_rv(LockinString+"theta"), freq_PGain, freq_IGain, 0, "Output.B", freq_DGain)

	variable startTime = StopMSTimer(-2)
	do 
	while((StopMSTimer(-2) - StartTime) < 0.5*1e6) 
	
	td_WriteString("Event.2", "Once")
	CheckInWaveTiming(CPDvsTime)
	
//	td_StopInWaveBank(-1)
//	td_StopOutWaveBank(-1)
	
//	doscanfunc("StopEngage")
	Beep	

end

// Stub for conventional FM Point Scan, uses ARC to send theta out instead of the second Moku lockin
function MokuPSFM_ARC(xpos, ypos, liftheight, [interpolation])
// Moku hookups <---> ARC
// Input 1 <--> Defl
// Input 2 <--> BNCOut2 (DDS)
// Output 1 <--> BNCIn2 (I, in-phase)
// Output 2 <--> BNCIn1 (Q, quadrature, the signal we want)
	variable xpos, ypos, liftheight, interpolation

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

	// Electric Tune variables
	variable EAmp = GV("NapDriveAmplitude")
	variable EFreq = GV("NapDriveFrequency")
	variable EOffset = GV("NapTipVoltage")
	variable EPhase = GV("NapPhaseOffset")
	wave NapVariablesWave = root:packages:MFP3D:Main:Variables:NapVariablesWave
	variable PotentialIGain = NapVariablesWave[%PotentialIGain][%Value]
	
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
	StopFeedbackLoop(2)
	SetFeedbackLoop(3, "always",  "ZSensor", (z1 - liftheight * 1e-9) / GV("ZLVDTSens"), 0, EFMFilters[%ZHeight][%IGain], 0, "Output.Z", 0)	

	// Tap on surface, then lift
//	LiftTo(liftheight, 0, verbose=1)

	// Set up for FM-SKPM point scan

	SetCrosspoint ("Ground","BNCIn1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutB","OutA","Ground","BNCIn2","DDS")

	td_wv((LockinString + "Amp"), calsoftd) //set the amplitude from the grab tune function
	print td_rv((LockinString + "Amp"))
	td_wv((LockinString + "Freq"), CalResFreq) //set the frequency to the resonant frequency
	td_wv((LockinString + "PhaseOffset"), CalPhaseOffset)  // phase offset also comes from calibration panel

	error += td_xsetinwave(0, "Event.2, Always", "Output.B", CPDvsTime, "", interpolation)
//	SetFeedbackLoop(4, "Always",  "Input.B", 0, 0,  300, 0, "DDSDCOffset0", 0)   // InputQ = $Lockin.0.Q , quadrature lockin output 
	SetFeedbackLoop(4, "always",  "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], 0, "Output.B",  EFMFilters[%KP][%DGain]) 
	SetFeedbackLoop(5, "Always", LockinString+"theta", td_rv(LockinString+"theta"), freq_PGain, freq_IGain, 0, "Output.A", freq_DGain)

	variable startTime = StopMSTimer(-2)
	do 
	while((StopMSTimer(-2) - StartTime) < 0.5*1e6) 
	
	td_WriteString("Event.2", "Once")
	CheckInWaveTiming(CPDvsTime)
	
//	td_StopInWaveBank(-1)
//	td_StopOutWaveBank(-1)
	
//	doscanfunc("StopEngage")
	Beep	

end


function tunecurve(resfreq)

	variable resfreq 

	// We find the secondmode manually already
	NVAR secondmode = root:packages:trEFM:TF:secondmode
	NVAR liftheight = root:packages:trEFM:liftheight
	// But now we want to actually tune
	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	GetGlobals()
	NVAR pgain, igain, sgain, setpoint
	Svar LockinString
	SetDataFolder root:Packages:trEFM:VoltageScan
	Variable/G calresfreq, calengagefreq, calhardd, calsoftd, calphaseoffset
	
	// Set up Frequency, resonance +/- 5 kHz
	variable fH, fL
	fL = resfreq - 5000
	fH = resfreq + 5000
	variable dFreq = 10// can change to speed up
	variable pts = (fH-fL)/dFreq - mod( (fH-fL)/dFreq, 32)
	make/n=(pts)/O calAmps, calPhase, calDef, calFreqs
	calAmps = nan
	calPhase = nan
	calDef = nan
	calFreqs = (p*dFreq +fL )
	
	calhardd = td_rv(LockinString+"Amp")
	calengagefreq = td_rv(LockinString +"Freq")
	calphaseoffset = td_rv(LockinString +"PhaseOffset")
	
	Liftto(liftheight, 0)

	// Set up acquisition. Record Amp/Phase/Def, write Frequency range to DDS
	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)

	SetCrosspoint("FilterOut", "Ground", "ACDefl", "Ground", "Ground", "Ground", "Off", "Off", "Off", "Defl", "Ground", "OutA", "OutB", "Ground", "OutB", "DDS")
	variable error = 0
	error += td_xSetInWave(0, "Event.2", "Phase", calPhase, "", 100)
	error += td_xSetInWavePair(1, "Event.2","Amplitude", calAmps, "Deflection", calDef, "", 100)
	error +=	td_xSetOutWave(2, "Event.2", "DDSFrequency0", calFreqs, -100)

	td_writestring("Event.2","Once")
	CheckInWaveTiming(CalAmps)
	setscale/I x, calfreqs[0], calfreqs[numpnts(calfreqs)-1], calamps
	Sleep/S 1
	
	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	
	doscanfunc("StopEngage")
	SetDataFolder savDF

end

function w1w2_tune([iterations])
	variable iterations // the more loops through, the more accurate the tune curve ends up particularly for second mode
	if (ParamIsDefault(iterations))
		iterations = 1
	endif
	
	variable i = 0
	variable j = 0

	SetDataFolder root:packages:trEFM:VoltageScan

	NVAR secondmode = root:packages:trEFM:TF:secondmode
	NVAR firstmode = root:packages:trEFM:VoltageScan:calresfreq

	if (numtype(firstmode) == 2)
		Abort "Grab Tune before running this"
	endif
	
	if (secondmode == 0) // not done yet, calculate based on beam physics 
		secondmode = 6.43 * firstmode
	elseif (numtype(secondmode) == 2)
		secondmode = 6.43 * firstmode
	endif
	
	Make/O/N=2 modes = {firstmode, secondmode}
	Make/O/N=2 realmodes = {firstmode, secondmode}
	Wave CalAmps = root:packages:treFM:VoltageScan:CalAmps

	do
		i =0
		print "Tune Curve", j+1, " of ", iterations
		do
			Tunecurve(modes[i])
			WaveStats/Q CalAmps
			RealModes[i] = V_maxloc

			i += 1
	
		while (i < 2)
		firstmode = Realmodes[0]
		secondmode = Realmodes[1]
		
		j += 1
	while (j < iterations)
	
	print "Modes measured are", Realmodes[0]/1000, "kHz and", RealModes[1]/1000, "kHz"
	print "Difference sideband =", Realmodes[1] - RealModes[0], "kHz"
	print "Sum sideband =", Realmodes[1] + RealModes[0], "kHz"
end

