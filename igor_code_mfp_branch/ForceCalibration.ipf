#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Cantilever force calibration using the damped driven harmonic oscillator (DDHO) model.
//
// Physical model
// --------------
// An AFM cantilever behaves as a DDHO with amplitude response:
//
//   A(w) = A0 * w0^2 / sqrt( (w^2 - w0^2)^2 + (w * w0 / Q)^2 )
//
// where w0 = 2*pi*f0 is the resonant angular frequency, Q is the quality
// factor, and A0 is a drive-amplitude prefactor. A noise-floor variant
// adds a (w * w0 * noise)^2 term under the radical.
//
// Calibration procedure
// ---------------------
// 1. Thermal tune (free cantilever, no drive):
//    GetFreeCantileverParms() reads the Asylum MFP3D thermal fit results —
//    spring constant k, resonant frequency f0, Q, mass m = k / (2*pi*f0)^2,
//    InVols, and AmpInVols — and stores them in FreeCantileverParms.
//
// 2. Driven frequency sweeps (cantilever near surface):
//    GetSurfaceCantileverParms() performs sweeps at V=0 and V=tipV,
//    fits the SHO model (amps) to each amplitude-vs-frequency curve, and
//    extracts the resonance shift, Q change, peak amplitude, and drive force.
//    Results are stored in SurfParmsInit and SurfParmsFinal.
//
// 3. Force extraction:
//    The electrostatic force at each voltage is computed from the deflection
//    signal and DEFINVOLS calibration: F = k * deflection (in meters).
//    The differential (V=tipV minus V=0) isolates the electrostatic contribution.
//
// Functions
// ---------
//
// amps(w0, w)
//   Igor FitFunc. SHO amplitude: A*w0^2 / sqrt((w^2-w0^2)^2 + (w*w0/Q)^2).
//   Coefficients: w0[0]=A, w0[1]=w0, w0[2]=Q.
//
// amps_n(w0, w)
//   SHO + noise floor FitFunc. Adds (w*w0*noise)^2 under the radical.
//   Coefficients: w0[0]=A, w0[1]=w0, w0[2]=Q, w0[3]=noise.
//
// GetFreeCantileverParms()
//   Reads thermal-tune results from Asylum MasterVariablesWave and
//   ThermalVariablesWave. Stores k, f0, Q, mass, InVols, AmpInVols, and
//   DriveAmplitude into root:packages:trEFM:ForceCal:FreeCantileverParms.
//
// GetSurfaceCantileverParms()
//   Fits amplitude curves collected at two tip voltages to the SHO model.
//   Extracts resonance frequency, Q, beta (damping), drive force, and
//   electrostatic force. Populates SurfParmsInit, SurfParmsFinal, and
//   the differential/free-cantilever columns of FinalParms.
//
// GetForceParms(tipV)
//   Top-level calibration entry point. Calls SetupForceCalibration, runs
//   ForceCalibration at 0 V and tipV, rescales and trims the resulting
//   amplitude/deflection/phase waves, then calls GetSurfaceCantileverParms
//   to extract the final force parameters.
//
// GetForceParms_Light(tipV)
//   Light-modulated variant of GetForceParms. Sweeps at tipV (dark) then
//   at tipV with illumination, so the differential isolates the
//   photo-induced force contribution.
//
// SetupForceCalibration([range])
//   Initializes the frequency sweep window [resF-range, resF+range] Hz
//   (default range = 2000 Hz) and stores the lift height for the sweep.
//
// ForceCalibration(tipV, [lighton, elecon])
//   Performs a single driven frequency sweep at the given tip voltage.
//   Acquires amplitude, phase, and deflection vs. frequency via Event.2
//   wave banks. lighton=1 enables illumination; elecon=1 switches to the
//   electrical-drive crosspoint for tip-driven measurements.
//
// FWHM(inwave)
//   Returns Q = f0 / FWHM by locating the peak and the two half-power
//   (1/sqrt(2)) crossing points of inwave.
//
// findAdrive(AmpVal, betaVal, resFval, driveFval, mass)
//   Computes the drive force amplitude (in Newtons) from the observed
//   tip amplitude and DDHO parameters using:
//   F_drive = AmpVal * sqrt( ((w0^2-wd^2)*2*pi)^2 + 4*beta^2*(wd*2*pi)^2 ) * mass
//
// getForce(calAmp, calDef, DEFINVOLS, k)
//   Returns the tip-sample force at resonance: F = -k * deflection(f0) * DEFINVOLS.
//   Applies a light smoothing to the deflection wave before evaluating at the
//   amplitude peak location.
//
// LiftToElec(liftHeight)
//   Lifts the tip to liftHeight (nm) using amplitude feedback with the
//   electrical crosspoint configuration for force-calibration measurements.

Function amps(w0,w) : FitFunc
	Wave w0
	Variable w

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(w) = A*w0^2 / sqrt( (w^2-w0^2)^2 + (w * w0/Q) ^ 2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ w
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w0[0] = A
	//CurveFitDialog/ w0[1] = w0
	//CurveFitDialog/ w0[2] = Q

	return w0[0]*w0[1]^2 / sqrt( (w^2-w0[1]^2)^2 + (w * w0[1]/w0[2]) ^ 2) 
End

// SHO + Noise
Function amps_n(w0,w) : FitFunc
	Wave w0
	Variable w

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(w) = A*w0^2 / sqrt( (w^2-w0^2)^2 + (w * w0/Q) ^ 2 + (w * w0 * noise)^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ w
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w0[0] = A
	//CurveFitDialog/ w0[1] = w0
	//CurveFitDialog/ w0[2] = Q
	//CurveFitDialog/ w0[3] = noise

	return w0[0]*w0[1]^2 / sqrt( (w^2-w0[1]^2)^2 + (w * w0[1]/w0[2]) ^ 2 + (w * w0[1] * w0[3])^2)
End


// Main Force Cal Function. Must use ARC Lockin
function GetForceParms(tipV)

	Variable tipV
	SetDataFolder root:packages:trEFM:ForceCal
	
	SetupForceCalibration()

	Make/O calAmps
	Make/O calDef
	Make/O calPhase
	Make/O calFreqs

	// 0 V
	ForceCalibration(0)
	Duplicate/O calAmps, calAmpsVi
	Duplicate/O calDef, calDefVi
	Duplicate/O calPhase, calPhaseVi
	
	// With Voltage
	ForceCalibration(tipV)
	Duplicate/O calAmps, calAmpsVf
	Duplicate/O calDef, calDefVf
	Duplicate/O calPhase, calPhaseVf

	// Rescale Waves
	NVAR fL, fH
	setscale/I x, fL, fH, calAmpsVi
	setscale/I x, fL, fH, calDefVi
	setscale/I x, fL, fH, calPhaseVi
	setscale/I x, fL, fH, calAmpsVf
	setscale/I x, fL, fH, calDefVf
	setscale/I x, fL, fH, calPhaseVf

	// Delete garbage spikes
	DeletePoints 0,5, calAmpsVi	
	DeletePoints 0,5, calAmpsVf	

	// Gets Cantilever parameters, force/k/beta/etc
	GetSurfaceCantileverParms()
	
	Wave FInalParms
	FinalParms[17][0] = tipV
	
	doscanfunc("stopengage")
	sleep/S 3
	
end

function GetForceParms_Light(tipV)

	Variable tipV
	SetDataFolder root:packages:trEFM:ForceCal
	
	SetupForceCalibration()

	Make/O calAmps
	Make/O calDef
	Make/O calPhase
	Make/O calFreqs

	// Voltage On
	Print "Voltage On"
	ForceCalibration(tipV)
	Duplicate/O calAmps, calAmpsVi
	Duplicate/O calDef, calDefVi
	Duplicate/O calPhase, calPhaseVi
	
	// With Light
	Print "Light On"
	ForceCalibration(tipV, lighton=1)
	Duplicate/O calAmps, calAmpsVf
	Duplicate/O calDef, calDefVf
	Duplicate/O calPhase, calPhaseVf

	// Rescale Waves
	NVAR fL, fH
	setscale/I x, fL, fH, calAmpsVi
	setscale/I x, fL, fH, calDefVi
	setscale/I x, fL, fH, calPhaseVi
	setscale/I x, fL, fH, calAmpsVf
	setscale/I x, fL, fH, calDefVf
	setscale/I x, fL, fH, calPhaseVf

	// Delete garbage spikes
	DeletePoints 0,5, calAmpsVi	
	DeletePoints 0,5, calAmpsVf	

	// Gets Cantilever parameters, force/k/beta/etc
	GetSurfaceCantileverParms()
	
	Wave FInalParms
	FinalParms[17][0] = tipV
	
	doscanfunc("stopengage")
	sleep/S 3
	
end

function SetupForceCalibration([range])

	variable range
	SetDataFolder root:packages:trEFM:ForceCal

	if (paramIsDefault(range))
		range = 2000
	endif

	NVAR thermalK, resF, DEFINVOLS, AMPINVOLS, Mass
	NVAR F_0VresF, F_0Vbeta,F_0VQ, F_0VAmpInMeters, F_0VForce, F_0VDriveF
	
	NVAR fL, fH, gZCalHeight
	NVAR liftheight = root:packages:trEFM:liftheight
	gZCalHeight = liftheight
	
	fL = resF - range
	fH = resF + range
	
end

function ForceCalibration(tipV, [lighton, elecon])
//	Only works with ARC Lockin selected due to issues with td_xSetOutWave and the Cypher Lockin
	Variable tipV
	variable lighton
	variable elecOn
	
	if (ParamIsDefault(ElecOn))
		ElecOn = 0
	endif
	
	SetDataFolder root:packages:trEFM:ForceCal
	
	NVAR thermalK, resF, DEFINVOLS, AMPINVOLS, Mass
	NVAR F_0VresF, F_0Vbeta,F_0VQ, F_0VAmpInMeters, F_0VForce, F_0VDriveF
	
	NVAR fL, fH, gZCalHeight
	NVAR calsoftd = root:packages:trEFM:VoltageScan:calsoftd
	SVAR LockinString = root:packages:trEFM:LockinString
	Nvar calresfreq  = root:packages:trEFM:VoltageScan:calresfreq
	NVAR calphaseoffset = root:packages:trEFM:VoltageScan:calphaseoffset
	NVAR calengagefreq = root:packages:trEFM:VoltageScan:calengagefreq
	NVAR calhardd = root:packages:trEFM:VoltageScan:calhardd
	
	variable dFreq = 10// can change to speed up
	variable pts = (fH-fL)/dFreq - mod( (fH-fL)/dFreq, 32)
	make/n=(pts)/O calAmps, calPhase, calDef, calFreqs
	calAmps = nan
	calPhase = nan
	calDef = nan
	calFreqs = (p*dFreq +fL )
	
	variable error =0
	
	// Set up acquisition. Record Amp/Phase/Def, write Frequency range to DDS
	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)

	SetCrosspoint("FilterOut", "Ground", "ACDefl", "Ground", "Ground", "Ground", "Off", "Off", "Off", "Defl", "Ground", "OutA", "OutB", "Ground", "OutB", "DDS")

	error += td_xSetInWave(0, "Event.2", "Phase", calPhase, "", 100)
	error += td_xSetInWavePair(1, "Event.2","Amplitude", calAmps, "Deflection", calDef, "", 100)
	error +=	td_xSetOutWave(2, "Event.2", "DDSFrequency0", calFreqs, -100)

	if (ElecOn == 0)
	
		if (ParamIsDefault(lighton))
			LiftTo(gZCalHeight, tipV)	
		else
			LiftTo(gZCalHeight, tipV, lighton=lighton)	
		endif
	
		td_wv("DDSAmplitude0", calsoftd)
	else
		LiftTo(gZCalHeight, 0)	
	
		SetCrosspoint("FilterOut", "Ground", "ACDefl", "Ground", "Ground", "Ground", "Off", "Off", "Off", "Defl", "Ground", "OutA", "OutB", "Ground", "DDS", "Ground")
		Sleep/S 1
		
		variable EAmp = GV("NapDriveAmplitude")
		variable EFreq = GV("NapDriveFrequency")
		variable EOffset = GV("NapTipVoltage")
		variable EPhase = GV("NapPhaseOffset")
		td_WriteValue("DDSAmplitude0",EAmp)	
		td_WriteValue("DDSFrequency0",EFreq)	
		td_WriteValue("DDSPhaseOffset0",EPhase)
		td_WriteValue("DDSDCOffset0",EOffset)	
		
	endif

	td_writestring("Event.2","Once")
	CheckInWaveTiming(CalAmps)
//	sleep/S pts*0.001*10
	Sleep/S 1
	
	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	
//	stopfeedbackloop(3)
	
	SetDataFolder root:packages:trEFM:ForceCal
	
end

Function GetFreeCantileverParms()
	Wave TVW = root:packages:MFP3D:Main:Variables:ThermalVariablesWave
	Wave MVW = root:packages:MFP3D:Main:Variables:MasterVariablesWave
	
	Variable k, ThermalDC, ThermalQ, DriveAmp
	
	SetDataFolder root:packages:trEFM:ForceCal
	Make/O/N=8 FreeCantileverParms
	
	NVAR thermalK, resF, DEFINVOLS, AMPINVOLS, Mass
	
	AMPINVOLS = MVW[%AmpInVols][%value]
	DEFINVOLS = MVW[%InVols][%value]
	ThermalK = MVW[%DisplaySpringConstant][%value] * 1e9 // 1e9 due to Asylum software passing as nN/m instead of nN/nm
	resF = TVW[%ThermalFrequency][%value]
	ThermalDC = TVW[%ThermalDC][%value]
	ThermalQ = TVW[%ThermalQ][%value]
	DriveAmp = MVW[%DriveAmplitude][%value]
	Mass =thermalK / (2*pi*resF)^2
		
	FreeCantileverParms[0] = AMPINVOLS
	FreeCantileverParms[1] = DEFINVOLS
	FreeCantileverParms[2] = ThermalK
	FreeCantileverParms[3] = resF
	FreeCantileverParms[4] = thermalDC
	FreeCantileverParms[5] = thermalQ
	FreeCantileverParms[6] = driveAmp
	FreeCantileverParms[7] = Mass

End

Function GetSurfaceCantileverParms()
	// Saves/calculates cantilever parameters and saves into FinalParms
	// FinalParms is a 7x4 matrix
	// Column 0: Initial Voltage case (typically 0 V)
	// Column 1: Final Voltage case (typically 10 V)
	// Column 2: Differential. Primarily relevant for change in electrostatic force
	// Column 3: Free Cantilever Parameters extracted via "Get Real"
	// Specific elements

	SetDataFolder root:packages:trEFM:ForceCal
	
	Wave FreeCantileverParms
	NVAR thermalK, resF, DEFINVOLS, AMPINVOLS, Mass
	NVAR driveF = root:packages:trEFM:VoltageScan:calengagefreq
	variable resFinit, Q, k, betaVal, ampVal, ampDrive, Force0		//ampval is on tip, ampDrive is from shake
	Make/O/N=8 SurfParmsInit, SurfParmsFinal
	
	Wave calAmpsVi, calDefVi, calPhaseVi, calFreqsVi
	Wave calAmpsVf, calDefVf, calPhaseVf, calFreqsVf
	
	// initial parameters
	Wavestats/Q calAmpsVi
	resFinit = V_maxLoc
	Q = FWHM(calAmpsVi)
	k = (resFinit*2*pi)^2 * Mass
	betaVal =  resF*2*pi/(2*Q)
	ampVal = V_max * AMPINVOLS
	ampDrive = findAdrive(ampVal, betaVal, resFinit, resFinit, Mass) // driven at resonance
	Force0 = getForce(calAmpsVi, calDefVi, DEFINVOLS, k)
	SurfParmsInit = {resFinit, Q, betaVal, k, Force0, ampDrive, ampVal, NaN}

	variable k0 = k
	variable omega0 = resFinit

	// final parameters
	Wavestats/Q calAmpsVf
	resFinit = V_maxLoc
	Q = FWHM(calAmpsVf)
	k = (resFinit*2*pi)^2 * Mass
	betaVal =  resF*2*pi/(2*Q)
	ampVal = V_max * AMPINVOLS
	ampDrive = findAdrive(ampVal, betaVal, resFinit, resFinit, Mass) // driven at resonance
	Force0 = getForce(calAmpsVf, calDefVf, DEFINVOLS, k)
	SurfParmsFinal = {resFinit, Q, betaVal, k, Force0, ampDrive, ampVal, NaN}
	
	Make/O/N=(8,3) FinalParms = NaN
	FinalParms[0,6][0] = SurfParmsInit[p]
	FinalParms[0,6][1] = SurfParmsFinal[p]
	FinalParms[0,6][2] = SurfParmsFinal[p] - SurfParmsInit[p]
	
	
	if(WaveExists(root:packages:trEFM:VoltageScan:phasewave))
		curvefit/M=2/W=0/Q poly_XOffset 3, root:packages:trEFM:VoltageScan:phasewave/X=root:packages:trEFM:VoltageScan:voltagewave/D
		variable dFdZ = K2
		FinalParms[7][2] = dFdZ * 4*k0 / omega0	// electrostatic force gradient
	endif

	SetDimLabel 1, 0, Initial, FinalParms
	SetDimLabel 1, 1, Final, FinalParms
	SetDimLabel 1, 2, Differential, FinalParms

	SetDimLabel 0, 0, ResFrequency, FinalParms
	SetDimLabel 0, 1, Q, FinalParms
	SetDimLabel 0, 2, Beta, FinalParms
	SetDimLabel 0, 3, SpringConstant, FinalParms
	SetDimLabel 0, 4, ElectroForce, FinalParms
	SetDimLabel 0, 5, DrivingForce, FinalParms
	SetDimLabel 0, 6, Amplitude, FinalParms
	SetDimLabel 0, 7, dFdZ, FinalParms
	
	Redimension/N=(18,-1) FinalParms
	FinalParms[8,17][1,2] = NaN
	FinalParms[8,15][0] = FreeCantileverParms[p-8]
	
	NVAR lift = root:packages:trEFM:liftheight
	NVAR voltage 
	FinalParms[16][0] = lift

	
	SetDimLabel 0, 8, AMPINVOLS, FinalParms
	SetDimLabel 0, 9, DEFINVOLS, FinalParms
	SetDimLabel 0, 10, ThermalK, FinalParms
	SetDimLabel 0, 11, ThermalResFreq, FinalParms
	SetDimLabel 0, 12, ThermalDC, FinalParms
	SetDimLabel 0, 13, ThermalQ, FinalParms
	SetDimLabel 0, 14, ThermalDriveAmplitude, FinalParms
	SetDimLabel 0, 15, Mass, FinalParms
	SetDimLabel 0, 16, LiftHeight, FinalParms
	SetDimLabel 0, 17, Voltage, FinalParms
	

end

function FWHM(inwave)
	wave inwave
	
	wavestats/Q inwave
	variable inwavemax = V_max
	variable inwavemaxloc = V_maxloc 
	
	FindLevel/r=(0, inwavemaxloc)/Q inwave, V_max/sqrt(2)
	variable fwhmL = V_levelX
	
	FindLevel/r=(inwavemaxloc, inf)/Q inwave, V_max/sqrt(2)
	variable fwhmH = V_levelX
	
	return inwavemaxloc/(fwhmH - fwhmL)
end

function findAdrive(AmpVal, betaVal, resFval, driveFval,  mass)
	variable AmpVal, betaVal, resFval, driveFval, mass
		
	variable Ampdrive = AmpVal * sqrt( ( ( (resFval^2 - driveFval^2)*2*pi)^2 + 4*(betaVal^2)*(driveFval * 2*pi)^2 ) )
	Ampdrive *= mass	// the Ampdrive force in N	
	
	return Ampdrive
end

function getForce(calAmp, calDef, DEFINVOLS, k)
	wave calAmp, calDef
	variable DEFINVOLS, k

	duplicate/o calDef, defTestSM
	smooth/b=3 3, defTestSM

	wavestats/Q calAmp

	variable F = -1*(k*deftestsm(V_maxLoc)*DEFINVOLS) 	//1e9 because DEFINVOLS in m/V 	
	killWaves/Z defTestSM
	
	return F
end	




Function LiftToElec(liftHeight)
	Variable liftHeight
	SetDataFolder root:packages:trefm

	Wave EFMFilters
	NVAR setpoint, pgain, sgain,igain
	SVAR LockinString
	
	SetCrosspoint("FilterOut", "Ground", "ACDefl", "Ground", "Ground", "Ground", "Off", "Off", "Off", "Defl", "Ground", "OutA", "OutB", "Ground", "DDS", "Ground")

	// Find surface
	SetFeedbackLoop(2, "Always", LockinString +"R", setpoint, -pgain, -igain, -sgain, "Output.Z", 0)
	
	Sleep/s 1
	readposition()
	
	// Stop amplitude feedback		
	StopFeedbackLoop(2)
	
	// Lift the tip to the desired lift height.
	Variable z1= td_readvalue("ZSensor") * GV("ZLVDTSens")	
	SetFeedbackLoop(3, "always",  "ZSensor", (z1 - liftHeight * 1e-9) / GV("ZLVDTSens"), 0,  EFMFilters[%ZHeight][%IGain], 0, "Output.Z", 0)

	Sleep/s 1
	readposition()
	
End