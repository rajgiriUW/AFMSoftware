#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtGlobals = 1

Menu "trEFM"
	"trEFM Panel" , trEFMImagingPanel() // If this panel function is ever saved over, make sure to run trEFMInit() before the experiment
	"SKPM Panel", SKPMPanel()
	"PL Panel", LBICPanel()
	"NLPC Panel", NLPC_Panel()
	"Reset All" , ResetAll()
	SubMenu "Gains"
		"SKPM", SKPMGainsPanelCPD()
		"trEFM", EditGainsButton("")
	end
	"About", About()
End


Function trEFMInit()
// Function to initalize required data folders and variables for trEFM methods.

	hideprocedures

	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S root:Packages:trEFM
	NewDataFolder/O/S root:Packages:trEFM:ForceCal
	NewDataFolder/O/S root:Packages:trEFM:VoltageScan
	NewDataFolder/O/S root:Packages:trEFM:HeightScan
	NewDataFolder/O/S root:Packages:trEFM:WaveGenerator
	NewDataFolder/O/S root:Packages:trEFM:PointScan
	NewDataFolder/O/S root:Packages:trEFM:PointScan:trEFM
	NewDataFolder/O/S root:Packages:trEFM:PointScan:FFtrEFM
	NewDataFolder/O/S root:Packages:trEFM:PointScan:SKPM
	NewDataFolder/O/S root:Packages:trEFM:PointScan:GMode
	NewDataFolder/O/S root:Packages:trEFM:FFtrEFMConfig
	NewDataFolder/O/S root:Packages:trEFM:ImageScan
	NewDataFolder/O/S root:Packages:trEFM:ImageScan:trEFM
	NewDataFolder/O/S root:Packages:trEFM:ImageScan:FFtrEFM
	NewDataFolder/O/S root:Packages:trEFM:ImageScan:SKPM
	NewDataFolder/O/S root:Packages:trEFM:ImageScan:Gmode
	NewDataFolder/O/S root:packages:trEFM:ImageScan:LBIC

	if(exists("root:packages:trEFM:InitCheck") != 2)
		GageInitialize() //Don't Initialize this if we have already, bad things happen.
	endif
	
	Wave CSACQUISITIONCONFIG = root:packages:GageCS:CSACQUISITIONCONFIG
	Wave CSTRIGGERCONFIG = root:packages:GageCS:CSTRIGGERCONFIG
	CSACQUISITIONCONFIG[%Mode] = 1
	CSACQUISITIONCONFIG[%SampleRate] = 10e6
	CSTRIGGERCONFIG[%Level] = 70
	
	InitBoardAndDeviceLIAAWG()  // GPIB LIA and Waveform Generator setup.
	
	// Setup global variables.
	SetDataFolder root:packages:trEFM
	SaveHardwareSettings()
	SetDefaultGainsAndFilters()
	Variable/G setpoint, adcgain, pgain, igain, sgain, imagingfilterfreq
	Variable/G xlvdtsens, ylvdtsens, zlvdtsens, xldvtoffset, yldvtoffset, zldvtoffset
	Variable/G xigain, yigain, zigain
	Variable/G gxpos, gypos, liftheight
	Variable/G interpval
	Variable/G WavesCommitted
	Variable/G InitCheck =0
	Variable/G triggerDelay = 186
	Variable/G phaseDelay = 180
	Variable/G RingDownVoltage
	Variable/G LightOn
	String/G LockinString = "ARC.Lockin.0."

	// cut drive variables
	Variable/G cutpreV = 0
	Variable/G cutDrive = 0
	Variable/G cutLength = 1
	WavesCommitted = 0
	gxpos = 0
	gypos = 0 
	liftheight = 50 // in nm.
	
	// Elec Drive variables
	Variable/G ElecDrive = 0
	Variable/G ElecAmp = 0
	
	// Panel global variables
	SetDataFolder  root:Packages:trEFM:ImageScan
	Variable/G UseLineNum = 0
	Variable/G XFastEFM = 1
	Variable/G YFastEFM = 0
	Variable/G LineNum = 0
	

	
	GetGlobals()
	
	// Setup voltage scan and tune variables.
	SetDataFolder root:Packages:trEFM:VoltageScan
	Variable/G tunecomplete = 0
	Variable/G vmin, vmax, npoints, softamplitude, targetpercent
	
	vmin = -10
	vmax = 10
	npoints = 85
	softamplitude = .3
	targetpercent = 0
	
	//Setup height scan variables.
	SetDataFolder root:Packages:trEFM:HeightScan
	Variable/G zmin, zmax, voltage, znpoints
	
	zmin = 10 
	zmax = 60
	voltage = 10
	znpoints = 10
	
	// Setup Wave Generator variables.
	SetDataFolder root:Packages:trEFM:WaveGenerator
	Make/O/N = 800 gentriggerwaveTemp, gentipwaveTemp, genlightwaveTemp, genDriveWaveTemp
	Variable/G numcycles = 100
	// Default Tip wave
	gentipwaveTemp[0,99] = 0
	gentipwaveTemp[100,649] = 10
	gentipwaveTemp[650,799] = 0
	
	// Default trigger wave
	gentriggerwaveTemp[0,399] = 0
	gentriggerwaveTemp[400,649] = 5
	gentriggerwaveTemp[700,799] = 0
	
	// Default light wave
	genlightwaveTemp[0,199] = 0
	genlightwaveTemp[200,349] = 5
	genlightwaveTemp[350,799] = 0
	
	// Default ringdown drive wave
	gendrivewaveTemp[0,199] = 0.001
	genlightwaveTemp[200,349] = 0
	genlightwaveTemp[350,799] = 0.001
	
	// Setup point scan variables.
	SetDataFolder root:Packages:trEFM:PointScan
	Nvar numcycles = root:Packages:trEFM:WaveGenerator:numcycles
	

	Make/O/N = (800) timekeeper
	SetScale d,0,800,"ms",timekeeper
		Variable i = 0, timeperiod
	timeperiod = 16/800
	do
		timekeeper[i]= i * timeperiod
		i += 1	
	while (i < 800)
	// Setup image scan variables.
	SetDataFolder root:Packages:trEFM:ImageScan
	Variable/G scansizex, scansizey, scanlines, scanpoints, scanspeed, numavgsperpoint, xoryscan, fitstarttime, fitstoptime
	Variable/G DigitizerAverages, DigitizerSamples, DigitizerPretrigger
	Variable/G DigitizerTime, DigitizerSampleRate, DigitizerPercentPreTrig
	Variable/G GM_AC
	
	// Imaging/trEFM
	scansizex = 5
	scansizey = 5
	scanlines = 128
	scanpoints = 128
	scanspeed = 1 // in micrometers/sec.
	numavgsperpoint = 15
	xoryscan = 0 // changes whether the scan treats the x direction or y direction to perform the line scans.
	fitstarttime = 8 // a reasonable default when turning the light on at 8 ms
	fitstoptime = 9
	InterpVal = 1
	
	// FF-trEFM
	DigitizerTime = 0.8192
	DigitizerSampleRate = 10e6
	DigitizerPercentPreTrig = 50
	DigitizerAverages = 500
	DigitizerSamples = ceil(DigitizerSampleRate * DigitizerTime * 1e-3)
	DigitizerPretrigger = ceil(DigitizerSamples * DigitizerPercentPreTrig / 100)

	SetDataFolder root:Packages:trEFM:FFtrEFMConfig
	MakePixelConfig()
	
	// RingDownEFM
	RingDownVoltage = 10
	LightOn = 0
	
	// G Mode
	GM_AC = 3
	
	// SKPM 
	SetDataFolder root:Packages:trEFM:PointScan:SKPM
	Variable/G LockinTimeConstant, LockinSensitivity, ACFrequency, ACVoltage, TimePerPoint, AppliedBias, BiasFreq
	LockinTimeConstant = 1
	LockinSensitivity = 14
	ACFrequency = 1000
	ACVoltage = 1.5
	TimePerPoint = 20
	AppliedBias = 0.05
	BiasFreq = 2
	
	Variable/G Freq_PGain, Freq_IGain, Freq_DGain
	Freq_PGain = -0.01
	Freq_IGain = 0
	Freq_DGain = 0
	
	Variable/G DwellTime
	DwellTime = 5
	
	// Single line stuff
	Variable/G LineNumforVoltage = 0
	Variable/G VoltageatLine = 0
	Variable/G UseLineNumforVoltage = 0
	Variable/G LineNumforVoltage2 = 0
	Variable/G VoltageatLine2 = 0
	
	SetDataFolder root:Packages:trEFM:ForceCal
	
	// Calibration Variables
	Variable/G thermalK, resF, DEFINVOLS, AMPINVOLS, Mass
	Variable/G F_0VresF, F_0Vbeta,F_0VQ, F_0VAmpInMeters, F_0VForce, F_0VDriveF
	Variable/G VresF, Vbeta,VQ, VAmpInMeters, VForce, VDriveF, VthermalK
	Variable/G deltaThermalK, deltaForce, deltaAmp, deltaresF
	Variable/G  fL, fH, VelecInit, VelecFin
	Variable/G gZCalHeight = 50	// lift height in nm
	Variable/G F_NumAvgs = 1
	
	fL = 0
	fH = 0 
	VelecInit = 0
	VelecFin = 10
	
	SetDataFolder root:Packages:trEFM
	InitCheck = 1
End

Function SetDefaultGainsAndFilters()
// Function sets up the gains and filters waves and assigns default values
// if new default values are desired they should be changed here.

	String savDF = GetDataFolder(1) // locate the current data folder
	SetDataFolder root:Packages:trEFM
	
	Make/O/N = (6,13) EFMFilters
	
	SetDimLabel 0, 0, EFM, EFMFilters
	SetDimLabel 0, 1, trEFM, EFMFilters
	SetDimLabel 0, 2, KP, EFMFilters
	SetDimLabel 0, 3, cAFM, EFMFilters
	SetDimLabel 0, 4, Beats, EFMFilters
	SetDimLabel 0, 5, ZHeight, EFMFilters
	SetDimLabel 1, 0, X, EFMFilters
	SetDimLabel 1, 1, Y, EFMFilters
	SetDimLabel 1, 2, Z, EFMFilters
	SetDimLabel 1, 3, A, EFMFilters
	SetDimLabel 1, 4, B, EFMFilters
	SetDimLabel 1, 5, Fast, EFMFilters
	SetDimLabel 1, 6, i, EFMFilters
	SetDimLabel 1, 7, q, EFMFilters
	SetDimLabel 1, 8, i1, EFMFilters
	SetDimLabel 1, 9, q1, EFMFilters
	SetDimLabel 1, 10, PGain, EFMFilters
	SetDimLabel 1, 11, IGain, EFMFilters
	SetDimLabel 1, 12, DGain, EFMFilters
	
	EFMFilters[%EFM][%X] = 1000
	EFMFilters[%EFM][%Y] = 1000
	EFMFilters[%EFM][%Z] = 2000
	EFMFilters[%EFM][%A] = 2000
	EFMFilters[%EFM][%B] = 2000
	EFMFilters[%EFM][%Fast] = 1500
	EFMFilters[%EFM][%i] = 20000
	EFMFilters[%EFM][%q] = 20000
	EFMFilters[%EFM][%i1] = 1000
	EFMFilters[%EFM][%q1] = 1000
	EFMFilters[%EFM][%PGain] = 6
	EFMFilters[%EFM][%iGain] = 21000
	EFMFilters[%EFM][%DGain] =0.0015
	
	EFMFilters[%trEFM][%X] = 1000
	EFMFilters[%trEFM][%Y] = 1000
	EFMFilters[%trEFM][%Z] = 2000
	EFMFilters[%trEFM][%A] = 2000
	EFMFilters[%trEFM][%B] = 2000
	EFMFilters[%trEFM][%Fast] = 1500
	EFMFilters[%trEFM][%i] = 20000
	EFMFilters[%trEFM][%q] = 20000
	EFMFilters[%trEFM][%i1] = 1000
	EFMFilters[%trEFM][%q1] = 1000
	EFMFilters[%trEFM][%PGain] = 13
	EFMFilters[%trEFM][%iGain] = 33000
	EFMFilters[%trEFM][%DGain] = 0.0001
	
	EFMFilters[%KP][%X] = 1000
	EFMFilters[%KP][%Y] = 1000
	EFMFilters[%KP][%Z] = 2000
	EFMFilters[%KP][%A] = 2000
	EFMFilters[%KP][%B] = 2000
	EFMFilters[%KP][%Fast] = 1500
	EFMFilters[%KP][%i] = 5000
	EFMFilters[%KP][%q] = 5000
	EFMFilters[%KP][%i1] = 1000
	EFMFilters[%KP][%q1] = 1000
	EFMFilters[%KP][%PGain] = 0.5
	EFMFilters[%KP][%iGain] = 11
	EFMFilters[%KP][%DGain] = 0
	
	EFMFilters[%cAFM][%X] = 1000
	EFMFilters[%cAFM][%Y] = 1000
	EFMFilters[%cAFM][%Z] = 2000
	EFMFilters[%cAFM][%A] = 2000
	EFMFilters[%cAFM][%B] = 2000
	EFMFilters[%cAFM][%Fast] = 1500
	EFMFilters[%cAFM][%i] = 1000
	EFMFilters[%cAFM][%q] = 1000
	EFMFilters[%cAFM][%i1] = 1000
	EFMFilters[%cAFM][%q1] = 1000
	EFMFilters[%cAFM][%PGain] = 0
	EFMFilters[%cAFM][%iGain] = 0
	EFMFilters[%cAFM][%DGain] = 0
	
	EFMFilters[%Beats][%X] = 1000
	EFMFilters[%Beats][%Y] = 1000
	EFMFilters[%Beats][%Z] = 2000
	EFMFilters[%Beats][%A] = 50000
	EFMFilters[%Beats][%B] = 50000
	EFMFilters[%Beats][%Fast] = 1500
	EFMFilters[%Beats][%i] = 2000
	EFMFilters[%Beats][%q] = 2000
	EFMFilters[%Beats][%i1] = 1000
	EFMFilters[%Beats][%q1] = 1000
	EFMFilters[%Beats][%PGain] = 0
	EFMFilters[%Beats][%iGain] = 0
	EFMFilters[%Beats][%DGain] = 0
	
	EFMFilters[%ZHeight][%X] = 0
	EFMFilters[%ZHeight][%Y] = 0
	EFMFilters[%ZHeight][%Z] = 0
	EFMFilters[%ZHeight][%A] = 0
	EFMFilters[%ZHeight][%B] = 0
	EFMFilters[%ZHeight][%Fast] = 0
	EFMFilters[%ZHeight][%i] = 0
	EFMFilters[%ZHeight][%q] = 0
	EFMFilters[%ZHeight][%i1] = 0
	EFMFilters[%ZHeight][%q1] = 0
	EFMFilters[%ZHeight][%PGain] = 0
	EFMFilters[%ZHeight][%iGain] = 1000
	EFMFilters[%ZHeight][%DGain] = 0	
	
	SetDataFolder savDF
	
End

Function SaveHardwareSettings()
	String savDF = GetDataFolder(-1)
	SetDataFolder root:Packages:trEFM

	Variable/G SavedOutputA, SavedOutputB, SavedOutputC
	SavedOutputA= td_rv("Output.A")
	SavedOutputB= td_rv("Output.B")
	SavedOutputC= td_rv("Output.C")

	//retrieve and store all filter data, both pass and band
	Make/O/N = 10 SavedPassFilter, SavedBandFilter
	Make/T/O/N=10 SavedFilterIndex={"X","Y","Z","A","B","Fast","i","q","i1","q1"}
	variable filterCount
	String passFilterString, bandFilterString
	filterCount=10
	passFilterString="Pass Filter."
	bandFilterString="Band Filter."	
	Variable i
	for (i=0;i<filterCount;i+=1)
		SavedPassFilter[i] = td_rv(passFilterString + SavedFilterIndex[i])
		SavedBandFilter[i] = td_rv(bandFilterString + SavedFilterIndex[i])		
	endfor
	
	//retrieve and store all DDS values
	Make/O/N=11 SavedDDS
	Make/T/O/N=11 SavedDDSIndex={"DCOffset","0.Freq","0.FreqOffset","0.PhaseOffset","0.Amp","0.Filter.Freq","1.Freq","1.FreqOffset","1.PhaseOffset","1.Amp","1.Filter.Freq"}
	for (i=0;i<11;i+=1)
		SavedDDS[i] = td_rv("Lockin." + SavedDDSIndex[i])		
	endfor
	
	//retrieve and store the current crosspoint parameters
	make/T/O/N=16 SavedXPT
	Make/T/O/N=16 SavedXPTIndex={"InA","InB","InFast","InAOffset","InBOffset","InFastOffset","OutXMod","OutYMod","OutZMod","FilterIn","Out0","Out1","Out2","PogoOut","Chip","Shake"}
	for (i=0;i<16;i+=1)
		SavedXPT[i] = td_rs(SavedXPTIndex[i] + "%Crosspoint")		
	endfor	
	
	SetDataFolder savDF
End

Function MakePixelConfig()

	Make/O/N = (14,1) PIXELCONFIG
	
	SetDimLabel 0, 0, Trigger, PIXELCONFIG
	SetDimLabel  0,1,  total_time,PIXELCONFIG
	SetDimLabel  0,2,  sample_rate,PIXELCONFIG
	SetDimLabel  0,3,  drive_freq,PIXELCONFIG
	SetDimLabel  0,4,  windowed,PIXELCONFIG
	SetDimLabel  0,5,  filtered,PIXELCONFIG
	SetDimLabel  0,6, bandwidth,PIXELCONFIG
	SetDimLabel  0,7,  filter_taps,PIXELCONFIG
	SetDimLabel  0,8,  region_of_interest,PIXELCONFIG
	SetDimLabel  0,9,  wavelet_analysis,PIXELCONFIG
	SetDimLabel  0,10, wavelet_parameter, PIXELCONFIG
	SetDimLabel  0,11,recombination, PIXELCONFIG
	SetDimLabel  0,12,phase_fitting, PIXELCONFIG
	SetDimLabel  0,13,emd_analysis, PIXELCONFIG
	
	PIXELCONFIG[%trigger][0] = 4.096e-4
	PIXELCONFIG[%total_time][0] = 8.192e-4
	PIXELCONFIG[%sample_rate] [0]= 1e7
	PIXELCONFIG[%drive_freq][0] = 300e3
	PIXELCONFIG[%windowed][0] = 1  // True/False
	PIXELCONFIG[%filtered][0] = 1      // True/False
	PIXELCONFIG[%bandwidth][0] = 10e3
	PIXELCONFIG[%filter_taps] [0]= 999
	PIXELCONFIG[%region_of_interest][0] = 3e-4
	PIXELCONFIG[%phase_fitting] = 0	// True/False
	PIXELCONFIG[%emd_analysis] = 0	// True/False
End


Function PSON_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			PsON()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function PSOff_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			PsOff()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End