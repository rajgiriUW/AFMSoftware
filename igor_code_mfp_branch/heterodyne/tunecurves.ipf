#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function tunecurve(resfreq, [scale])

	variable resfreq 
	variable scale
	If (ParamIsDefault(scale))
	
		scale = 1
	endif

	// We find the secondmode manually already
	NVAR secondmode = root:packages:trEFM:TF:secondmode
	NVAR liftheight = root:packages:trEFM:liftheight
	// But now we want to actually tune
	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	GetGlobals()
	NVAR pgain, igain, sgain, setpoint
	Svar LockinString, Lockinstring2
	SetDataFolder root:Packages:trEFM:VoltageScan
	NVAR calresfreq, calengagefreq, calhardd, calsoftd, calphaseoffset, calhardd2
	
	
	// Set up Frequency, resonance +/- 5 kHz for first resonacne, 50 kHz for second resonance 
	variable fH, fL
	fL = resfreq - 5000*(10^scale)
	fH = resfreq + 5000*(10^scale)
	variable dFreq = 10// can change to speed up
	variable pts = (fH-fL)/dFreq - mod( (fH-fL)/dFreq, 32)
	make/n=(pts)/O calAmps, calPhase, calDef, calFreqs
	calAmps = nan
	calPhase = nan
	calDef = nan
	calFreqs = (p*dFreq +fL )
	
	//calhardd = td_rv(LockinString+"Amp")
	//calengagefreq = td_rv(LockinString +"Freq")
	//calphaseoffset = td_rv(LockinString +"PhaseOffset")
	
	Liftto(liftheight, 0) // does this on first resonance

	// Set up acquisition. Record Amp/Phase/Def, write Frequency range to DDS
	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)

	SetCrosspoint("FilterOut", "Ground", "ACDefl", "Ground", "Ground", "Ground", "Off", "Off", "Off", "Defl", "Ground", "OutA", "OutB", "Ground", "OutB", "DDS")
	
	if (scale == 0) // first mode, use soft tapping
		td_wv(LockinString+"Amp", calsoftD)
	else
		td_wv(LockinString2+"Amp", calhardd2)
		td_wv(LockinString + "Amp", 0) // set first mode to 0
	endif
	
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
		print "Iteration ", j+1, " of ", iterations
		do
			print "Tune Curve ", i+1
			Tunecurve(modes[i], scale = i)
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

