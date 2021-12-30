#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// For supporting Electrical Acquisition of Tip Transfer Function

// For doing electrical transfer function measurement
// This applies an AC electrical drive to the tip over a frequency range, fits to SHO model, then 
// calculates teh transfer function based on that.
// Fundamentally, this isn't really any different than doing the thermal tune and fit, only this supports adding
// 	several tip modes. E.g. a 70 kHz tip will have a second resonance on the MFP-3D that defines the transfer
//	function
// This function saves the transfer function fit as TransferFunc.ibw, and it saves the Parameters table as a text file


function GetElecTip(tipV)
// Applies an electrical 
	Variable tipV
	SetDataFolder root:packages:trEFM:ForceCal
	
	variable range = 25000
	
	SetupForceCalibration(range=range)
	NVAR resF = root:packages:trEFM:ForceCal:resF
	
	// error correction
	if ((resF - range) < 0)
		print "Default range too high! Fixing..."
		range = resF - 5000
		SetupForceCalibration(range=range)
	endif
	
	print "Starting with frequency", resF
	
	Make/O calAmps
	Make/O calDef
	Make/O calPhase
	Make/O calFreqs

	// Voltage On
	Print "Voltage On"
	ForceCalibration(tipV, ElecOn=1)
	Duplicate/O calAmps, calAmpsVi
	Duplicate/O calDef, calDefVi
	Duplicate/O calPhase, calPhaseVi
	
	// Rescale Waves
	NVAR fL, fH
	setscale/I x, fL, fH, calAmpsVi
	setscale/I x, fL, fH, calDefVi
	setscale/I x, fL, fH, calPhaseVi

	// Delete garbage spikes
	DeletePoints 0,5, calAmpsVi
	
	Duplicate/O calAmps, calAmpsVi1
	Duplicate/O calPhase, calPhaseVi1
	setscale/I x, fL, fH, calAmpsVi1
	setscale/I x, fL, fH, calPhaseVi1

	// Delete garbage spikes
	DeletePoints 0,5, calAmpsVi1	

	// Gets Cantilever parameters, force/k/beta/etc
	//GetSurfaceCantileverParms()
	
	// Fitting
	WaveStats/Q calAmpsVi1

	variable amp = V_max
	print "Amp Max = ", V_max
	Wave FinalParms  =root:packages:trEFM:ForceCal:FinalParms
	variable Q = FinalParms[1][1]
	Make/O/N=3 Coeffs = {amp, resF, Q}
	Make/O/T/N=3 T_Constraints
	T_Constraints[0] = {"K0 > 0","K1 > 0","K2 > 0"}
	FuncFit/Q amps Coeffs CalAmpsVi1 /D /C=T_Constraints
	FuncFit/Q amps Coeffs CalAmpsVi1 /D /C=T_Constraints
	print "FIt = ", Coeffs
	
	Redimension/N=(20,-1) FinalParms
	SetDimLabel 0, 16, Fit_Parameters, FinalParms
	SetDimLabel 0, 17, Amplitude, FinalParms
	SetDimLabel 0, 18, Resonance, FinalParms
	SetDimLabel 0, 19, Q, FinalParms
	FinalParms[16,19][0,2] = NaN
	FinalParms[17,0] = Coeffs[0]
	FinalParms[18,0] = Coeffs[1]
	FinalParms[19,0] = Coeffs[2]
	
	wave totalPSD = root:packages:MFP3D:Tune:TotalPSD
	variable endFreq = dimdelta(TotalPSD,0) * numpnts(TotalPSD)
	
	Make/O/N=(numpnts(totalPSD)) TransferFunc1 = 0
	Make/O/N=(numpnts(totalPSD)) TransferFunc2 = 0
	Make/O/N=(numpnts(totalPSD)) TransferFunc3 = 0
	SetScale/I x, 0, endFreq, TransferFunc1
	SetScale/I x, 0, endFreq, TransferFunc2
	SetScale/I x, 0, endFreq, TransferFunc3

	TransferFunc1 = Coeffs[0]*Coeffs[1]^2 / sqrt( (x^2-Coeffs[1]^2)^2 + (x * Coeffs[1]/Coeffs[2]) ^ 2)
	TransferFunc1 *= FinalParms[8][0] // AMPINVOLS
	
	// Are there more harmonics within this AFM's DDS range?
	variable orig_res = resF
	
	variable k = 0
	if (6.25 * orig_res < endFreq)
		print "Starting with new frequency", 6.2*resF
		resF = 6.25 * orig_res
		fL = resF - range
		fH = resF + range
		Make/O calAmps
		Make/O calDef
		Make/O calPhase
		Make/O calFreqs

		// Voltage On
		Print "Voltage On"
		ForceCalibration(tipV, ElecOn=1)
		Duplicate/O calAmps, calAmpsVi2
		Duplicate/O calDef, calDefVi
		Duplicate/O calPhase, calPhaseVi2

//		do

//			ForceCalibration(tipV, ElecOn=1)
//			calAmpsVi2 += calAmps
//			k += 1
			
//		while (k < 4)
//		calAmpsVi2 /= 5
	
		// Rescale Waves
		setscale/I x, fL, fH, calAmpsVi2
		setscale/I x, fL, fH, calDefVi
		setscale/I x, fL, fH, calPhaseVi2

		// Delete garbage spikes
		DeletePoints 0,5, calAmpsVi2	

		// Fitting
		WaveStats/Q calAmpsVi2

		amp = V_max
		Wave FinalParms  =root:packages:trEFM:ForceCal:FinalParms
		Q = FinalParms[1][1]
		Make/O/N=3 Coeffs = {amp, resF, Q}
		T_Constraints[0] = {"K0 > 0","K1 > 0","K2 > 0"}
		FuncFit/Q amps Coeffs CalAmpsVi2 /D /C=T_Constraints
		FuncFit/Q amps Coeffs CalAmpsVi2 /D /C=T_Constraints
		print "FIt = ", Coeffs
		
		TransferFunc2 = Coeffs[0]*Coeffs[1]^2 / sqrt( (x^2-Coeffs[1]^2)^2 + (x * Coeffs[1]/Coeffs[2]) ^ 2)
		TransferFunc2 *= FinalParms[8][0] // AMPINVOLS
		
		Redimension/N=(24,-1) FinalParms
		SetDimLabel 0, 20, Fit_Parameters, FinalParms
		SetDimLabel 0, 21, Amplitude, FinalParms
		SetDimLabel 0, 22, Resonance, FinalParms
		SetDimLabel 0, 23, Q, FinalParms
		FinalParms[20,23][0, 2] = NaN
		FinalParms[21,0] = Coeffs[0]
		FinalParms[22,0] = Coeffs[1]
		FinalParms[23,0] = Coeffs[2]
	endif
	
	if (17.5 * orig_res < endFreq)
		print "Starting with new frequency", 6.2*resF
		resF =17.5 * orig_res
		fL = resF - 2*range
		fH = resF + 2*range
		Make/O calAmps
		Make/O calDef
		Make/O calPhase
		Make/O calFreqs

		// Voltage On
		Print "Voltage On"
		ForceCalibration(tipV, ElecOn=1)
		Duplicate/O calAmps, calAmpsVi3
		Duplicate/O calDef, calDefVi
		Duplicate/O calPhase, calPhaseVi3
	
		// Rescale Waves
		setscale/I x, fL, fH, calAmpsVi3
		setscale/I x, fL, fH, calDefVi
		setscale/I x, fL, fH, calPhaseVi3

		// Delete garbage spikes
		DeletePoints 0,5, calAmpsVi3	

		// Fitting
		WaveStats/Q calAmpsVi3

		amp = V_max
		Wave FinalParms  =root:packages:trEFM:ForceCal:FinalParms
		Q = FinalParms[1][1]
		Make/O/N=3 Coeffs = {amp, resF, Q}
		FuncFit/Q amps Coeffs CalAmpsVi3 /D /C=T_Constraints
		FuncFit/Q amps Coeffs CalAmpsVi3 /D /C=T_Constraints
		print "FIt = ", Coeffs
		
		TransferFunc3 = Coeffs[0]*Coeffs[1]^2 / sqrt( (x^2-Coeffs[1]^2)^2 + (x * Coeffs[1]/Coeffs[2]) ^ 2)
		TransferFunc3 *= FinalParms[8][0] // AMPINVOLS
		
		Redimension/N=(28,-1) FinalParms
		SetDimLabel 0, 24, Fit_Parameters, FinalParms
		SetDimLabel 0, 25, Amplitude, FinalParms
		SetDimLabel 0, 26, Resonance, FinalParms
		SetDimLabel 0, 27, Q, FinalParms
		FinalParms[25,28][0] = NaN
		FinalParms[26,0] = Coeffs[0]
		FinalParms[27,0] = Coeffs[1]
		FinalParms[28,0] = Coeffs[2]
	endif
	
	make/O/N=(numpnts(TotalPSD)) TransferFunc = 0
	SetScale/I x, 0, endFreq, TransferFunc
	TransferFunc = TransferFunc1 + TransferFunc2 + TransferFunc3

	// Scale by INVOLS	
	CalAmpsVi3 *=  FinalParms[8][0]
	CalAmpsVi2 *=  FinalParms[8][0]
	CalAmpsVi1 *=  FinalParms[8][0]
	
	resF = orig_res
	
	variable ds = dimsize(FinalParms, 0)
	Redimension/N=(ds+4, -1) FinalParms
	SetDimLabel 0, ds, Electrical_Drive, FinalParms
	SetDimLabel 0, ds+1, AC_Amplitude, FinalParms
	SetDimLabel 0, ds+2, PhaseOffset, FinalParms
	SetDimLabel 0, ds+3, DC_Offset, FinalParms
	FinalParms[ds,ds+3][0,2] = NaN
	FinalParms[ds+1][0] = GV("NapDriveAmplitude")
	FinalParms[ds+2][0] = GV("NapPhaseOffset")
	FinalParms[ds+3][0] = GV("NapTipVoltage")
	
	doscanfunc("stopengage")
	sleep/S 3
	
end

function GetElecNoiseTip(tipV)
// Applies an electrical 
	Variable tipV
	SetDataFolder root:packages:trEFM:ForceCal
	
	variable range = 25000
	
	SetupForceCalibration(range=range)
	NVAR resF = root:packages:trEFM:ForceCal:resF
	
	// error correction
	if ((resF - range) < 0)
		range = resF - 5000
		SetupForceCalibration(range=range)
	endif
	
	print "Doing baseline noise up to frequency", resF - range - 30000
	ForceCalibration_Noise(ElecOn=1)
	Wave CalNoise = root:packages:trEFM:ForceCal:CalNoise
	Duplicate/O root:packages:trEFM:ForceCal:CalFreqs, CalNoiseFreqs 
	SetScale/I x, CalNoiseFreqs[0], CalNoiseFreqs[numpnts(CalNoiseFreqs)-1], CalNoise
	
	print "Starting with frequency", resF
	
	Make/O calAmps
	Make/O calDef
	Make/O calPhase
	Make/O calFreqs

	// Voltage On
	Print "Voltage On"
	SetupForceCalibration(range=range)
	ForceCalibration(tipV, ElecOn=1)
	Duplicate/O calAmps, calAmpsVi
	Duplicate/O calDef, calDefVi
	Duplicate/O calPhase, calPhaseVi
	
	// Rescale Waves
	NVAR fL, fH
	setscale/I x, fL, fH, calAmpsVi
	setscale/I x, fL, fH, calDefVi
	setscale/I x, fL, fH, calPhaseVi

	// Delete garbage spikes
	DeletePoints 0,5, calAmpsVi
	
	Duplicate/O calAmps, calAmpsVi1
	Duplicate/O calPhase, calPhaseVi1
	setscale/I x, fL, fH, calAmpsVi1
	setscale/I x, fL, fH, calPhaseVi1

	// Delete garbage spikes
	DeletePoints 0,5, calAmpsVi1	

	// Gets Cantilever parameters, force/k/beta/etc
	//GetSurfaceCantileverParms()
	
	// Fitting
	WaveStats/Q calAmpsVi1

	variable amp = V_max
	Wave FinalParms  = root:packages:trEFM:ForceCal:FinalParms
	variable Q = FinalParms[1][1]
	Make/O/N=3 Coeffs = {amp, resF, Q}

	Make/O/T/N=3 T_Constraints
	Make/O/T/N=4 T_Constraints_n
	Wave CalFreqs =  root:packages:trEFM:ForceCal:CalFreqs
	
	Concatenate/O {CalNoiseFreqs, CalFreqs}, NoiseFreqs
	Concatenate/O {CAlNoise, CalAmpsVi1}, NoiseAmps
	Redimension/N=(numpnts(NoiseAmps)) NoiseFreqs
	
	T_Constraints_n[0] = {"K0 > 0","K2 > 0", "K2 < 500", "K3 > 0, K3 < 0.01"}
	T_Constraints[0] = {"K0 > 0","K1 > 0","K2 > 0"}
	FuncFit/Q amps Coeffs NoiseAmps /X=NoiseFreqs /D /C=T_Constraints
	Make/O/N=4 Coeffs_n = {Coeffs[0], Coeffs[1], Coeffs[2], 0.002}
	FuncFit/Q/H="0100" amps_n Coeffs_n NoiseAmps /X=NoiseFreqs /D /C=T_Constraints_n

	print "FIt = ", Coeffs_N
		
	Redimension/N=(20,-1) FinalParms
	SetDimLabel 0, 16, Fit_Parameters, FinalParms
	SetDimLabel 0, 17, Amplitude, FinalParms
	SetDimLabel 0, 18, Resonance, FinalParms
	SetDimLabel 0, 19, Q, FinalParms
	FinalParms[16,19][0,2] = NaN
	FinalParms[17,0] = Coeffs[0]
	FinalParms[18,0] = Coeffs[1]
	FinalParms[19,0] = Coeffs[2]
	
	wave totalPSD = root:packages:MFP3D:Tune:TotalPSD
	variable endFreq = dimdelta(TotalPSD,0) * numpnts(TotalPSD)
	
	Make/O/N=(numpnts(totalPSD)) TransferFunc1 = 0
	Make/O/N=(numpnts(totalPSD)) TransferFunc2 = 0
	Make/O/N=(numpnts(totalPSD)) TransferFunc3 = 0
	SetScale/I x, 0, endFreq, TransferFunc1
	SetScale/I x, 0, endFreq, TransferFunc2
	SetScale/I x, 0, endFreq, TransferFunc3

	TransferFunc1 = Coeffs_N[0]*Coeffs_N[1]^2 / sqrt( (x^2-Coeffs_N[1]^2)^2 + (x * Coeffs_N[1]/Coeffs_N[2]) ^ 2 + (x * Coeffs_N[1] * Coeffs_N[3])^2 )
	TransferFunc1 *= FinalParms[8][0] // AMPINVOLS
	
	// Are there more harmonics within this AFM's DDS range?
	variable orig_res = resF
	if (6.25 * orig_res < endFreq)
		print "Starting with new frequency", 6.2*resF
		resF = 6.25 * orig_res
		fL = resF - range
		fH = resF + range
		Make/O calAmps
		Make/O calDef
		Make/O calPhase
		Make/O calFreqs

		// Voltage On
		Print "Voltage On"
		ForceCalibration(tipV, ElecOn=1)
		Duplicate/O calAmps, calAmpsVi2
		Duplicate/O calDef, calDefVi
		Duplicate/O calPhase, calPhaseVi2
	
		// Rescale Waves
		setscale/I x, fL, fH, calAmpsVi2
		setscale/I x, fL, fH, calDefVi
		setscale/I x, fL, fH, calPhaseVi2

		// Delete garbage spikes
		DeletePoints 0,5, calAmpsVi2	

		// Fitting
		WaveStats/Q calAmpsVi2

		amp = V_max
		Wave FinalParms  =root:packages:trEFM:ForceCal:FinalParms
		Q = FinalParms[1][1]
		Make/O/N=3 Coeffs = {amp, resF, Q}
		FuncFit/Q amps Coeffs CalAmpsVi2 /D /C=T_Constraints
		print "FIt = ", Coeffs
		
		TransferFunc2 = Coeffs[0]*Coeffs[1]^2 / sqrt( (x^2-Coeffs[1]^2)^2 + (x * Coeffs[1]/Coeffs[2]) ^ 2)
		TransferFunc2 *= FinalParms[8][0] // AMPINVOLS
		
		Redimension/N=(24,-1) FinalParms
		SetDimLabel 0, 20, Fit_Parameters, FinalParms
		SetDimLabel 0, 21, Amplitude, FinalParms
		SetDimLabel 0, 22, Resonance, FinalParms
		SetDimLabel 0, 23, Q, FinalParms
		FinalParms[20,23][0, 2] = NaN
		FinalParms[21,0] = Coeffs[0]
		FinalParms[22,0] = Coeffs[1]
		FinalParms[23,0] = Coeffs[2]
	endif
	
	if (17.5 * orig_res < endFreq)
		print "Starting with new frequency", 6.2*resF
		resF =17.5 * orig_res
		fL = resF - range
		fH = resF + range
		Make/O calAmps
		Make/O calDef
		Make/O calPhase
		Make/O calFreqs

		// Voltage On
		Print "Voltage On"
		ForceCalibration(tipV, ElecOn=1)
		Duplicate/O calAmps, calAmpsVi3
		Duplicate/O calDef, calDefVi
		Duplicate/O calPhase, calPhaseVi3
	
		// Rescale Waves
		setscale/I x, fL, fH, calAmpsVi3
		setscale/I x, fL, fH, calDefVi
		setscale/I x, fL, fH, calPhaseVi3

		// Delete garbage spikes
		DeletePoints 0,5, calAmpsVi3	

		// Fitting
		WaveStats/Q calAmpsVi3

		amp = V_max
		Wave FinalParms  =root:packages:trEFM:ForceCal:FinalParms
		Q = FinalParms[1][1]
		Make/O/N=3 Coeffs = {amp, resF, Q}
		FuncFit/Q amps Coeffs CalAmpsVi3 /D /C=T_Constraints
		print "FIt = ", Coeffs
		
		TransferFunc3 = Coeffs[0]*Coeffs[1]^2 / sqrt( (x^2-Coeffs[1]^2)^2 + (x * Coeffs[1]/Coeffs[2]) ^ 2)
		TransferFunc3 *= FinalParms[8][0] // AMPINVOLS
		
		Redimension/N=(28,-1) FinalParms
		SetDimLabel 0, 24, Fit_Parameters, FinalParms
		SetDimLabel 0, 25, Amplitude, FinalParms
		SetDimLabel 0, 26, Resonance, FinalParms
		SetDimLabel 0, 27, Q, FinalParms
		FinalParms[25,28][0] = NaN
		FinalParms[26,0] = Coeffs[0]
		FinalParms[27,0] = Coeffs[1]
		FinalParms[28,0] = Coeffs[2]
	endif
	
	make/O/N=(numpnts(TotalPSD)) TransferFunc = 0
	SetScale/I x, 0, endFreq, TransferFunc
	TransferFunc = TransferFunc1 + TransferFunc2 + TransferFunc3

	// Scale by INVOLS	
	CalAmpsVi3 *=  FinalParms[8][0]
	CalAmpsVi2 *=  FinalParms[8][0]
	CalAmpsVi1 *=  FinalParms[8][0]
	
	resF = orig_res
	
	doscanfunc("stopengage")
	sleep/S 3
	
end

function ForceCalibration_Noise([elecOn])
//	Only works with ARC Lockin selected due to issues with td_xSetOutWave and the Cypher Lockin
// Acquires the noise spectra by driving the tip up to below first resonance

	variable elecOn
	
	if (ParamIsDefault(ElecOn))
		ElecOn = 0
	endif
	
	SetDataFolder root:packages:trEFM:ForceCal
	
	NVAR thermalK, resF, DEFINVOLS, AMPINVOLS, Mass
	NVAR F_0VresF, F_0Vbeta,F_0VQ, F_0VAmpInMeters, F_0VForce, F_0VDriveF
	
	NVAR fL, fH, gZCalHeight
	fH = resF - 30000
	fL = 5000
	NVAR calsoftd = root:packages:trEFM:VoltageScan:calsoftd
	SVAR LockinString = root:packages:trEFM:LockinString

	variable dFreq = 10// can change to speed up
	variable pts = (fH-fL)/dFreq - mod( (fH-fL)/dFreq, 32)
	make/n=(pts)/O calNoise, calPhase, calDef, calFreqs
	calNoise = nan
	calPhase = nan
	calDef = nan
	calFreqs = (p*dFreq +fL )
	
	variable error =0
	
	// Set up acquisition. Record Amp/Phase/Def, write Frequency range to DDS
	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)

	SetCrosspoint("FilterOut", "Ground", "ACDefl", "Ground", "Ground", "Ground", "Off", "Off", "Off", "Defl", "Ground", "OutA", "OutB", "Ground", "OutB", "DDS")

	error += td_xSetInWave(0, "Event.2", "Phase", calPhase, "", 1)
	error += td_xSetInWavePair(1, "Event.2","Amplitude", calNoise, "Deflection", calDef, "", 1)
	error +=	td_xSetOutWave(2, "Event.2", "DDSFrequency0", calFreqs, -1)

	if (ElecOn == 0)
	
		LiftTo(gZCalHeight, 0)	
	
		td_wv("DDSAmplitude0", calsoftd)
	else
		LiftTo(gZCalHeight, 0)	
	
		SetCrosspoint("FilterOut", "Ground", "ACDefl", "Ground", "Ground", "Ground", "Off", "Off", "Off", "Defl", "Ground", "OutA", "OutB", "Ground", "DDS", "Ground")
		Sleep/S 1
		variable EAmp = GV("NapDriveAmplitude")
		variable EFreq = GV("NapDriveFrequency")
		variable EOffset = GV("NapPhaseOffset")
		string ErrorStr
		td_WriteValue("DDSAmplitude0",EAmp)
		td_WriteValue("DDSAmplitude1",EFreq)
		//td_WriteValue("DDSDCOffset0",EOffset)
		
	endif

	td_writestring("Event.2","Once")
	
	CheckInWaveTiming(calNoise)
//	sleep/S pts*0.001
	//sleep/S pts*0.001*10
	sleep/S 3
	
	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	
	stopfeedbackloop(3)
	
	SetDataFolder root:packages:trEFM:ForceCal
	
end
