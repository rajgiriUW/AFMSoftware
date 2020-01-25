#pragma rtGlobals = 1

Function GetGlobals()
// Function that grabs some settings from the Asylum variables
// and assigns them as global variables.

	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	Wave MVW = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	NVAR setpoint, adcgain, pgain, igain, sgain, imagingfilterfreq, gxpos, gypos
	Svar LockinString
	NVAR XLVDTSens, YLVDTSens, ZLVDTSens, XLVDToffset, YLVDToffset, ZLVDToffset
	NVAR xigain, yigain, zigain
	
	setpoint = GV("AmplitudeSetpointVolts")
	adcgain = GV("ADCgain")
	PGain = MVW[%ProportionalGain][0] / 10
	IGain = MVW[%IntegralGain][0] * 100
	SGain = MVW[%SecretGain][0]
	
	imagingfilterfreq = td_RV(LockinString+"filter.freq")
	
	XLVDTSens = GV("XLVDTSens")
	YLVDTSens = GV("YLVDTSens")
	ZLVDTSens = GV("ZLVDTSens")
	XLVDToffset = GV("XLVDToffset")
	YLVDToffset = GV("YLVDToffset")
	ZLVDToffset = GV("ZLVDToffset")
	
	xigain = 10^MVW[%XIGain][0] * sign(MVW[%XPiezoSens][0])
	yigain = 10^MVW[%YIGain][0]
	zigain = 10^MVW[%ZIGain][0]

	gxpos = (td_readvalue("XSensor") - XLVDToffset) * XLVDTSens * 1e6
	gypos = (td_readvalue("YSensor") - YLVDToffset) * YLVDTSens * 1e6

	SetDataFolder savDF
	
End

Function GrabTune(softamplitude)
// Given a target value for the soft amplitude, this function grabs the corresponding tune variables

	Variable softamplitude
	
	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM:FFtrEFMConfig
	Wave PIXELCONFIG
	SetDataFolder root:Packages:trEFM
	
	GetGlobals()
	NVAR pgain, igain, sgain, setpoint
	Svar LockinString
	SetDataFolder root:Packages:trEFM:VoltageScan
	Variable/G calresfreq, calengagefreq, calhardd, calsoftd, calphaseoffset, targetpercent
	NVAR tunecomplete
	
	variable calhardd_cypher =  td_rv(LockinString+"Amp")
	
	calhardd = td_rv(LockinString+"Amp")
	calengagefreq = td_rv(LockinString +"Freq")
	calphaseoffset = td_rv(LockinString +"PhaseOffset")

	Variable tunephaseoffset = td_rv(LockinString +"PhaseOffset")
	Variable resfrequency, V_max, resindex
	Variable r = 0
	Duplicate/O root:packages:MFP3D:Tune:frequency Grabfrequency
	Duplicate/O root:packages:MFP3D:Tune:amp Grabamplitude
	
	// find frequency @ targetpercent and set this as calresfreq
	Setscale/I x grabfrequency[0], grabfrequency[numpnts(grabfrequency)], grabamplitude
	WaveStats/Q Grabamplitude
	if (targetpercent > 0)
		FindLevel/EDGE=2/Q GrabAmplitude, (1+targetpercent/100)*V_Max
		calresfreq = V_levelX
	elseif (targetpercent < 0)
		FindLevel/EDGE=1/Q GrabAmplitude, (1+targetpercent/100)*V_Max	
		calresfreq = V_levelX
	elseif (targetpercent == 0)
		calresfreq = V_maxloc
	endif

	PIXELCONFIG[%drive_freq] = calresfreq
	td_wv(LockinString +"Freq", calresfreq)	
	td_wv(LockinString +"Amp", 0)

	Make/O/N = (1280) Awave = 0
	Make/O/N=(1280) Dwave = 0
	Dwave = calhardd * p / 1280
	
	// Sets up a wave of amplitudes from 0 to driveamplitude and fires it into the DDSAmplitude0
	// Then it just reads when the output is softamplitude.
	td_xsetoutwave(1, "Event.1",  LockinString +"Amp", Dwave,-100)
	td_xSetInWave(2, "Event.1",  LockinString +"R", Awave, "", 100) // getting read frequency offset.
	td_WriteString("Event.1", "Once")

	Sleep/S 1280/(.01*100)/1000*1.5

	SetScale/I x, 0, 1279, Awave, Dwave
	//Awave -= softamplitude
	//Awave = Awave[p]^2
	//WaveStats/Q Awave
  	//calsoftd = Dwave[V_minloc]
  	FindLevel/EDGE=1/P/Q Awave, softamplitude
  	calsoftd = Dwave[V_LevelX]
	
	td_wv(LockinString +"Freq", calengagefreq)
	td_wv(LockinString +"Amp", calhardd)
	
	td_stopinwavebank(-1)
	td_stopoutwavebank(-1)

	SetFeedbackLoop(2, "Always", lockinString+"R", setpoint, -pgain, -igain, -sgain, "Output.Z", 0)	
	DoScanFunc("StopEngage")
	
	tunecomplete = 1
	
	SetDataFolder savDF

End

Function VoltageScan(xpos, ypos, liftheight, [vmin, vmax, npoints])
//
// Given a X position, Y position, and a liftheight this function scans over a range of voltages from vmin to vmax and
// records the frequency offset as a function of these voltages. The user can optionally specify vmin, vmax, and the number of points to take
// 
	Variable xpos, ypos, liftheight, vmin, vmax, npoints
	SetDataFolder root:Packages:trEFM
	Svar LockinString
	SetDataFolder root:Packages:trEFM:VoltageScan
	
	// Check to see that the user has completed a cantilever tune.
	NVAR tunecomplete
	
	if(tunecomplete != 1)
		Abort "Tune the cantilever before proceeding to voltage scan."
	endif

	NVAR calsoftd, calphaseoffset, calresfreq, calengagefreq, calhardd
	
	SetDataFolder root:Packages:trEFM
	
	NVAR setpoint, pgain, sgain,igain
	Wave EFMFilters

	SetDataFolder root:Packages:trEFM:VoltageScan
	
	// Set the default variables if not specified by user.
	if (ParamIsDefault(vmax) && ParamIsDefault(vmin) && ParamIsDefault(npoints))
	
		vmax = 10
		vmin = -10
		npoints = 85		// Note: 85 is the upper limit given 512 averages per point. Higher than 85 prevents voltage from getting outputted to tip correctly
	
	endif
	
	// Set the voltage wave according to number of points.
	if ((npoints == 1) && (vmax == vmin))
	
		Make/O/N = (npoints) voltagewave, phasewave
		voltagewave = vmin
	
	elseif ((npoints >1) && (vmax > vmin))	
	
		Make/O/N = (npoints * 2-1) voltagewave, phasewave
		Make/O/N = (npoints) tempwave, tempwave1, tempwave2//, reversetempwave
		variable len = npoints
		variable len2 = floor(npoints/2)
	
		// Create the voltage wave.
		LinSpace2(0, vmin, len2, tempwave)
		LinSpace2(vmin, vmax, len, tempwave1)
		LinSpace2(vmax, 0, len2, tempwave2)
		Concatenate/O {tempwave, tempwave1, tempwave2}, voltagewave
		setscale/I x, 0, numpnts(voltagewave), voltagewave
	else
	
		Abort "Check your limits for voltage scan."
		
	endif

	// Set the wave interpolation.
	Variable efminterpolation = 2
	Variable efmcalpart = 512 // Data points acquired at each voltage.
	Variable efmcallength = efmcalpart * npoints * 2 // Total wave length.
	npoints = npoints * 2

	SetCrosspoint("FilterOut", "Ground", "ACDefl", "Ground", "Ground", "Ground", "Off", "Off", "Off", "Defl", "Ground", "OutC", "OutB", "Ground", "OutB", "DDS")

	td_stopinwavebank(-1)
	td_stopoutwavebank(-1)

	// Set the outputs to 0.
	td_wv("Output.A",0) 
	td_wv("Output.B",0) 
	
	Sleep/S 1/2
	// Create the voltage wave,  including the interpolation settings.
//	Make/O/N = (efmcalLength) readwave, voltwave, copywave
//	voltwave = 0
	
	Variable i =0
	Variable j =0
	
//	do
//		if (i < npoints)
//			voltwave[j,  j + efmcalpart] = voltagewave[i]
//			i += 1
//			j += efmcalpart
//		else
//			voltwave[j,  efmcallength - 1] = voltagewave[npoints]
//			j += efmcallength
//		endif
//	while (j < EFMcallength)

	// create a long voltage ramp instead of stair-step version in above loop
	LinSpace2(0, vmin, efmcallength/4, tempwave)
	LinSpace2(vmin, vmax, efmcallength/2, tempwave1)
	LinSpace2(vmax, 0, efmcallength/4, tempwave2)
	Concatenate/O {tempwave, tempwave1, tempwave2}, voltwave
	setscale/I x, 0, numpnts(voltwave), voltwave
	
	Make/O/N = (efmcalLength) readwave = NaN

	MoveXY(xpos,  ypos)

	// Reset the crosspoint panel because MoveXY is grounding it.
	SetCrosspoint("FilterOut", "Ground", "ACDefl", "Ground", "Ground", "Ground", "Off", "Off", "Off", "Defl", "Ground", "OutC", "OutB", "Ground", "OutB", "DDS")

	// Make sure the outputs are zeroed.
	td_WV("Output.A",  0)	
	td_WV("Output.B",  0) 
	// Set the frequency to the resonant frequency
	// and the amplitude to the drive amp, both taken from the Asylum tune panel.
	td_WV(LockinString +"Freq", calengagefreq)
	td_WV(LockinString +"Amp", calhardd)
	td_WV(LockinString + "PhaseOffset", calphaseoffset)
	
	// Lower the tip to tap the surface.
//	SetFeedbackLoop(2, "Always", LockinString +"R", setpoint, -pgain, -igain, -sgain, "Output.Z", 0)
	SetFeedbackLoop(2, "Always", LockinString +"R", setpoint, -pgain, -igain, -sgain, "Output.Z", 0)
	//PIDSloopButtonFunc("StartPIDSLoop2")
	Sleep/S 1.5

	// Connect the input and output waves.
	td_xSetInWave(2, "Event.1", LockinString +"FreqOffset",  readwave, "", efminterpolation)
	td_xSetOutWave(1, "Event.1", "Output.B",  voltwave,  -efminterpolation)
	
	Variable starttime = StopMSTimer(-2)

	// Lift the tip to the desired lift height.
	Variable z1= td_readvalue("ZSensor") * GV("ZLVDTSens")
	StopFeedbackLoop(2)
	SetFeedbackLoop(3, "Always",  "ZSensor", (z1 - liftheight * 1e-9) / GV("ZLVDTSens"), 0, EFMFilters[%ZHeight][%IGain], 0, "Output.Z", 0)	
	
	// Set the drive frequency to resonance.
	td_WV(LockinString +"freq", calresfreq)
	td_WV(LockinString +"Amp", calsoftd)
	td_WV(LockinString + "PhaseOffset", calphaseoffset)
	
	SetPassFilter(1, a = EFMFilters[%EFM][%A], b = EFMFilters[%EFM][%B], fast = EFMFilters[%EFM][%Fast], i = EFMFilters[%EFM][%i], q = EFMFilters[%EFM][%q])
	
	Variable gFreqOffsetNorm = 500 
//	td_WV(LockinString +"freq", calresfreq - gFreqOffsetNorm)
//	td_WV(LockinString +"freqoffset", gFreqOffsetNorm)

//	td_WV(LockinString +"freq", calresfreq)
//	td_WV(LockinString +"freqoffset", 0)
	
	print td_rv(LockinString+"theta")
	
	if (stringmatch("ARC.Lockin.0." , LockinString))
		SetFeedbackLoop(4, "always", LockinString +"theta", NaN, EFMFilters[%EFM][%PGain], EFMFilters[%EFM][%IGain], 0, LockinString+"FreqOffset",  EFMFilters[%EFM][%DGain])
	else
		SetFeedbackLoopCypher(1, "always", LockinString +"theta", NaN, EFMFilters[%EFM][%PGain], EFMFilters[%EFM][%IGain], 0, LockinString+"FreqOffset",  EFMFilters[%EFM][%DGain])
	endif
	
	td_WV("Output.B", voltwave[0])
	
	// Fire the data acquisition event.
	td_WriteString("Event.1", "Once")
//	Sleep/S efmcallength * 1e-5 * 4 * 1.1  // Wait until the data has finished collecting.
	CheckInWaveTiming(readwave)	

	// Stop data acquisition.
	td_StopINwaveBank(2)
	td_StopOUTwaveBank(1)
	
	td_WV("Output.B", 0)
	
	i = 0
	//copywave = readwave - gFreqOffsetNorm
	Duplicate/O readwave, copywave
	
	// Average the copy wave by taking each 512 point block,  chopping off each side of 128 points,  and using the middle 256 points.
	SetScale/I x, 0, numpnts(copywave), copywave
	do
		phasewave[i] = mean(copywave, ((4*i + 1) * 128) - 1, ((4*i + 3) * 128) - 1)
		i +=1
	while (i < npoints)

	// Smoothed raw wave instead of middle-sample averaging above
	Duplicate/O readwave,readwave_smth
	Smooth 25, readwave_smth
	
	StopFeedbackLoop(4)
	
	// Reset the DDS parameters to their starting values.
	td_WV(LockinString +"freq", calengagefreq) 
	td_WV(LockinString +"freqoffset", 0)
	td_WV(LockinString +"Amp", calhardd)
	td_WV(LockinString +"PhaseOffset",  calphaseoffset)	
	StopFeedbackLoop(3)
	SetFeedbackLoop(2, "Always", LockinString +"R", setpoint, -pgain, -igain, -sgain, "Output.Z", 0)
 	
 	
 	variable airtime = (StopMSTimer(-2) - starttime) * 1e-6
 	print airtime, " seconds spent above the surface."
 	
	sleep/S 1/2
	
	ResetAll()

	DoScanFunc("StopEngage")

End
	
Function HeightScan(xpos, ypos, voltage, [zmin, zmax, npoints])
//
// Given a X position, Y position, and constant voltage this function scan from zmin to zmax and records the frequency shift
// as a function of liftheight. Zmin, zmax, and number of points can be specified by the user.
//
	Variable xpos, ypos, voltage, zmin, zmax, npoints
	
	String savDF = GetDataFolder(1)
	
	SetDataFolder root:Packages:trEFM
	GetGlobals()
	
	NVAR setpoint, adcgain, pgain, igain, sgain, xigain, yigain, zigain
	NVAR XLVDTSens, YLVDTSens, ZLVDTSens, XLVDToffset, YLVDToffset, ZLVDToffset
	
	WAVE EFMFilters
	
	SetDataFolder root:Packages:trEFM:VoltageScan
	
	// Check to see that the user has completed a cantilever tune.
	NVAR tunecomplete
	
	if(tunecomplete != 1)
		Abort "Tune the cantilever before proceeding to voltage scan."
	endif
	
	NVAR calsoftd, calphaseoffset, calresfreq, calengagefreq, calhardd
	
	SetDataFolder root:Packages:trEFM:HeightScan
	if (ParamIsDefault(zmin) && ParamIsDefault(zmax) && ParamIsDefault(npoints))
	
		zmax = 60
		zmin = 10
		npoints = 10
	
	endif
	
	if ((npoints == 1) && (zmax == zmin))
	
		Make/O/N = (npoints) heightwave, shiftwave, readheight
		heightwave = zmin
	
	elseif ((npoints >1) && (zmax > zmin))	
	
		Make/O/N = (npoints * 2) heightwave, shiftwave, readheight
		Make/O/N = (npoints) tempwave, reversetempwave
	
		// Create the height wave.
		LinSpace2(zmin, zmax, npoints, tempwave) 
		Reverse tempwave /D = reversetempwave
		heightwave[0, npoints - 1] = tempwave[p]
		heightwave[npoints, 2 * npoints - 1] = reversetempwave[p - npoints]
	
	else
	
		Abort "Check your limits for height scan."
		
	endif
	
	
	MoveXY(xpos, ypos) // Move to XY, keeping the tip raised up
	SetCrosspoint("Ground", "Ground", "ACDefl", "Ground", "Ground", "Ground", "Off", "Off", "Off", "Ground", "Ground", "OutA", "Ground", "Ground", "OutB", "DDS")
	// Move the tip down to the surface.
	SetFeedbackLoop(2, "Always", "Lockin.0.R", setpoint, -pgain, -igain, -sgain, "Output.Z", 0)
	Sleep/S 3 // Wait until the tip hits the surface.
	
	// Read the Z position and alter the height wave to be absolute position above the surface.
	variable z1 = td_RV("ZSensor") * GV("ZLVDTSens")

	heightwave = (-Heightwave * 1e-09 + z1) / GV("ZLVDTSens")
	
	SetFeedbackLoop(2, "always",  "ZSensor", HeightWave[0], EFMFilters[%ZHeight][%PGain], EFMFilters[%ZHeight][%IGain], 0, "Output.Z", EFMFilters[%ZHeight][%DGain]) 
	td_WV("Output.B", 0)
	Sleep/S 1
	
	
	
	// Set the drive frequency to resonance.
	td_WV("DDSFrequency0", calresfreq)
	td_WV("DDSAmplitude0", calsoftd)
	
	SetPassFilter(1, a = EFMFilters[%EFM][%A], b = EFMFilters[%EFM][%B], fast = EFMFilters[%EFM][%Fast], i = EFMFilters[%EFM][%i], q = EFMFilters[%EFM][%q])
	
	
	td_WV("DDSFrequency0", calresfreq )

	// Tell the lockin to maintain the value of theta( NaN means maintain the initial value) by changing the frequency offset.
	SetFeedbackLoop(4, "always", "Lockin.0.theta", NaN, EFMFilters[%EFM][%pgain], EFMFilters[%EFM][%igain], 0, "Lockin.0.FreqOffset", EFMFilters[%EFM][%dgain])
	
	Variable i, j
	Variable Temp
	i = 0
	
	do
		
		// move to the height.
		td_WriteValue("PIDSLoop.2.Setpoint", heightwave[i])
		Sleep/S 50/1000
		
		// Apply the tip voltage
		td_WV("Output.B", voltage)
		
		// Take 512 readings at that height and average.
		j = 0
		Temp = 0
		do
			Temp += td_RV("DDSFrequencyOffset0")
			readheight[i] += (-td_RV("ZSensor") * GV("ZLVDTSens") + z1) * 1e9
			
			j += 1
		while(j < 512)
			
		readheight[i] = readheight[i] / 512
		shiftwave[i] = Temp / 512
			
		i += 1
		print i
		td_WV("Output.B", 0)

	while (i < npoints * 2)
	
	// Zero the tip Voltage
	td_WV("Output.B", 0)
	
	// Reset the DDS parameters to their starting values.
	td_WV("DDSFrequency0", calengagefreq) 
	td_WV("DDSFrequencyOffset0", 0)
	td_WV("DDSAmplitude0", calhardd)
	td_WV("DDSPhaseOffset0",  calphaseoffset)	
	
	MoveXY(xpos,  ypos)
	StopFeedbackLoop(4)
	
	// Send the tip back to the surface
	SetFeedbackloop(2, "Always", "Lockin.0.R", setpoint, -pgain, -igain, - sgain, "Output.Z", 0)
	Sleep/S 2
	
	td_WV("PIDSLoop.2.Setpoint", 5)

End
