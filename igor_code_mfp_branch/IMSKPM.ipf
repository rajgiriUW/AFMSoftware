#pragma rtGlobals=3		
#pragma rtGlobals = 1

// Contains the IM-SKPM code methods
// 3 Methods are included
// 1) AM mode: David M's + Jake P's method using the Force panel to call specific Asylum functions. Raj cannot verify this method works
// 2) AM mode: Raj's version that sets up the feedback loops to be functionally the same as that used in AM-SKPM Nap mode. 
// 3) FM mode: to be coded. The original code for this has long since been lost.


// AM-SKPM based approach using built-in Asylum functions
// Consult Daviid's+Jake's notes on the force and NAP panel setups

Window IMSKPM_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(2094,222,2498,518)
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (56576,56576,56576)
	DrawRect 7,9,552,436
	SetDrawEnv fsize= 10
	DrawText 142,159,"min: 20, max: 80"
	Button button1,pos={48,14},size={142,24},proc=IMSKPMAMButton,title="IM-SKPM (AM) Point Scan"
	SetVariable setvar1,pos={16,50},size={60,16},title="X"
	SetVariable setvar1,limits={-inf,inf,0},value= root:packages:trEFM:gxpos
	SetVariable setvar2,pos={16,80},size={60,16},title="Y"
	SetVariable setvar2,limits={-inf,inf,0},value= root:packages:trEFM:gypos
	SetVariable setvar3,pos={121,51},size={100,16},title="lift height (nm)"
	SetVariable setvar3,limits={-inf,inf,0},value= root:packages:trEFM:liftheight
	SetVariable setvar4,pos={100,79},size={120,16},title="Number of Averages"
	SetVariable setvar4,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:numavg
	SetVariable IMSKPMVoltage,pos={80,103},size={139,16},title="Function Gen Voltage"
	SetVariable IMSKPMVoltage,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:ACVoltage
	CheckBox UseOffset,pos={149,170},size={69,14},title="No Offset?"
	CheckBox UseOffset,variable= root:packages:trEFM:PointScan:SKPM:usehalfoffset,side= 1
	Button buttonFMIM,pos={19,211},size={165,33},proc=IMSKPMFMButton,title="IM-SKPM (FM) Point Scan (Slow!)"
	Button buttonFMIM,fColor=(52224,52224,52224)
	Button buttonFMIM1,pos={11,256},size={167,28},proc=IM_FFtrEFMButton,title="IM-EFM Point Scan (in progress)"
	Button buttonFMIM1,fColor=(47872,47872,47872)
	SetVariable DutyCycle,pos={135,127},size={86,16},title="Duty Cycle %"
	SetVariable DutyCycle,limits={20,80,0},value= root:packages:trEFM:PointScan:SKPM:dutycycle
	SetVariable scanpointsT,pos={272,51},size={100,16},title="Scan Points    "
	SetVariable scanpointsT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanpoints
	SetVariable scanlinesT,pos={273,75},size={100,16},title="Scan Lines     "
	SetVariable scanlinesT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanlines
	SetVariable scanspeedT,pos={260,99},size={113,16},title="Scan Speed(um/s)"
	SetVariable scanspeedT,fSize=10
	SetVariable scanspeedT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanspeed
	Button button2,pos={257,16},size={142,24},proc=IMSKPMAM_ImageScanButton,title="IM-SKPM (AM) Image Scan"
	SetVariable scanwidthT,pos={273,125},size={100,16},title="Width (µm)        "
	SetVariable scanwidthT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizex
	SetVariable scanheightT,pos={273,150},size={100,16},title="Height (µm)       "
	SetVariable scanheightT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizey
EndMacro


/////////////////////////////////

Function IMSKPMAMButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	NVar  xpos =  root:packages:trEFM:gxpos
	NVAR ypos =  root:packages:trEFM:gypos
	NVAR liftheight =  root:packages:trEFM:liftheight
	NVAR numavg = root:packages:trEFM:PointScan:SKPM:numavg
	PointScanIMSKPM_AM(xpos, ypos, liftheight, numavg)
	SetDataFolder savDF
	
End

Function IMSKPMFMButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	NVar  xpos =  root:packages:trEFM:gxpos
	NVAR ypos =  root:packages:trEFM:gypos
	NVAR liftheight =  root:packages:trEFM:liftheight
	NVAR numavg = root:packages:trEFM:PointScan:SKPM:numavg
	PointScanIMSKPM_FM(xpos, ypos, liftheight, numavg)
	SetDataFolder savDF
	
End

Function IMSKPMAM_ImageScanButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	
	SetDataFolder root:Packages:trEFM:ImageScan
	Nvar scansizex, scansizey, scanlines, scanpoints, scanspeed
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	
	Nvar WavesCommitted
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif

	Svar imageFunctionString = root:packages:trEFM:ImageFunctionString
	imageFunctionString = "skpm"

	//ImageScan(gxpos, gypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed)

	ImageScanIMSKPM_AM(gxpos, gypos, liftheight, scansizeX, scansizeY, scanlines, scanpoints, scanspeed)
	GetCurrentPosition()
	SetDataFolder savDF
	
End

Function IM_FFtrEFMButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	
	SetDataFolder root:packages:trEFM:ImageScan
	Nvar DigitizerAverages, DigitizerSamples,DigitizerPretrigger
	Nvar DigitizerTime, DigitizerSampleRate, DigitizerPercentPreTrig
	DigitizerSamples = ceil(DigitizerSampleRate * DigitizerTime * 1e-3)
	DigitizerPretrigger = ceil(DigitizerSamples * DigitizerPercentPreTrig / 100)

	SetDataFolder root:Packages:trEFM
	
	NVAR liftheight =  root:packages:trEFM:liftheight
	NVar  gxpos =  root:packages:trEFM:gxpos
	NVAR gypos =  root:packages:trEFM:gypos
	Nvar WavesCommitted
	Nvar UsePython
	NVAR numavg = root:packages:trEFM:PointScan:SKPM:numavg
	
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	
	SetDataFolder root:Packages:trEFM:PointScan:FFtrEFM
	
	Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
	Make/O/N=(DigitizerSamples) timekeeper
	Linspace2(0,PIXELCONFIG[%Total_Time],DigitizerSamples, timekeeper)
	SetScale d,0,(DigitizerSamples),"s",timekeeper
	
	PixelConfig[%Trigger] = (1 - DigitizerPercentPreTrig/100) * DigitizerTime * 1e-3
	PixelConfig[%Total_Time] = DigitizerTime * 1e-3
	
	PointScanIMSKPM_EFM(gxpos, gypos, liftheight, numavg)
	
	// Save the Data
	CreateParametersFile(PIXELCONFIG)
	
	if (strlen(PathList("PointScan", ";", "")) == 0)
		NewPath PointScan
	endif
	
	Wave SaveWave = root:packages:trEFM:pointscan:SaveWave
	Wave GageWave = root:packages:trEFM:pointScan:gageWave
	Save/G/O/P=PointScan/M="\r\n" SaveWave as "ps_parameters.cfg"
	Save/C/O/P=PointScan/M="\r\n" gagewave as "pointscan.ibw"
	
	if (UsePython == 1)
		PyPS_cypher(gagewave, SaveWave)
	endif

end

///////////////////////////////

Function PointScanIMSKPM_AM(xpos, ypos, liftheight, numavg)

// This method uses a somewhat more "brute force" approach
// Engage on teh surface, lift to panel height, switch the feedback methods and crosspoint
// Then record waves for specific amounts of time
// xpos and ypos in microns
// liftheight in nanometers

	Variable  xpos, ypos, liftheight, numavg

	String savDF = GetDataFolder(1)
	
	SetDataFolder root:Packages:trEFM
	Nvar pgain, sgain, igain, adcgain, setpoint,adcgain
	NVar interpval
	Svar LockinString
	NVAR ElecDrive, ElecAmp

	Nvar XLVDTsens
	Wave EFMFilters = root:packages:trEFM:EFMFilters
	GetGlobals()

	// Electrical Drive Settings	
	variable EAmp = GV("NapDriveAmplitude")
	variable EFreq = GV("NapDriveFrequency")
	variable EOffset = GV("NapTipVoltage")
	variable EPhase = GV("NapPhaseOffset")
	
//	Nvar numcycles = root:Packages:trEFM:WaveGenerator:numcycles
	NVAR SKPM_voltage = root:packages:trEFM:PointScan:SKPM:ACVoltage // 7.47
	variable current_freq =1
	
	// For the time being, we will be recording 80000 points for 1.6 s
	SetDataFolder root:packages:trEFM:PointScan:SKPM	
	FrequencyList()
	Wave Frequency_List
	NVAR useHalfOffset = root:packages:trEFM:PointScan:SKPM:usehalfoffset
	NVAR dutycycle = root:packages:trEFM:PointScan:SKPM:dutycycle

	// These two bits of code are for debugging/removing artifacts. 
	// 	First line just reverses the frequencies
	// 	Second line randomizes the frequencies 
//	Reverse Frequency_list
//	Shuffle(Frequency_List)

	Make/O/N=(80000) IM_CurrentFreq = NaN
	
	Make/O/N=(80000) IMWaves = NaN
	Make/O/N=(numpnts(Frequency_List)) IMWavesAvg = NaN
	
	SetPassFilter(1, a = EFMFilters[%EFM][%A], b = EFMFilters[%EFM][%B], fast = EFMFilters[%EFM][%Fast], i = EFMFilters[%EFM][%i], q = EFMFilters[%EFM][%q])

	variable j = 0
	variable k = 0 

	DoWindow/F IMSKPM
	if (V_flag == 0)
		Display/K=1/N=IMSKPM IMWavesAvg vs Frequency_List
		ModifyGraph log(bottom)=1
		ModifyGraph mirror=1,fStyle=1,fSize=22,axThick=3;DelayUpdate
		Label left "CPD (V)";DelayUpdate
		Label bottom "Frequency (Hz)"
		ModifyGraph mode=3,marker=16
	endif
	
	DoWindow/F IM_CurrentFreq
	if (V_flag == 0)
		Display/N=IM_CurrentFreq IM_CurrentFreq
	endif
	
	// USB function generator, futureproofing for FM mode 
	//TurnOnAWG()
	do

		SetDataFolder root:packages:trEFM:PointScan:SKPM
	
		Make/O/N=(80000) IMWaves_CurrentFreq = NaN
		Make/O/N=(80000) IM_Deflection = NaN
	
		k = 0

		// 0) Set up WaveGenerator	
		current_freq = Frequency_List[j]
		setvfsqu(skpm_voltage, current_freq, "wg", EOM=usehalfoffset, duty=dutycycle)	 
//		LoadArbWave(current_freq, skpm_voltage, 0) // Cypher function gen
//		LiftTo(liftheight, 0)
		do
	
			IM_CurrentFreq = NaN
		
			// Initial settings for outputs.
			td_WV("Output.A", 0)
			td_WV("Output.B", 0)

			StopFeedbackLoop(4)
			
//			if ( j == 0 && k ==0 )
	
				StopFeedbackLoop(3)
				StopFeedbackLoop(5)
	
				SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","OutB","DDS")
				MoveXY(xpos, ypos) // Move to xy, keeping the tip raised away from the surface	
//			endif
			
//			if (j == 0 && k ==0 )
				// 1) Find Surface and Lift tip to specified lift height
				LiftTo(liftheight, 0)  // sets Feedback Loop 3 to Z-position
//			endif
						
			// 2) Switch up Crosspoint for Electrical Mode
			SetCrosspoint ("FilterOut","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Defl","OutC","OutA","OutB","Ground","DDS","Ground")

			td_wv("Output.A", 5) // turn on laser

			td_WriteValue("DDSAmplitude0",EAmp)	
			td_WriteValue("DDSFrequency0",EFreq)	
			//td_WriteValue("DDSDCOffset0",EOffset)	
			td_WriteValue("DDSPhaseOffset0",EPhase)
			//td_WriteValue("DDSDCOffset0",0)	
	
			// 3) Set up Feedback Loop for POtential

			// Inputq or InputQ? Or use LockinString + Q
			SetFeedbackLoop(4, "Always", "InputQ", 0, 0,  8000, 0, "Potential", 0)   // InputQ = $Lockin.0.Q , quadrature lockin output 
			StopFeedbackLoop(3)
			StopFeedbackLoop(5)

			// 80000 points @ 50 kHz = 1.6 s @ interpval 1
			interpval = round(5 / current_freq)
			if (interpval < 1)
				interpval = 1
			endif
			print "Interpval = ", interpval, " Frequency: ", current_Freq
			td_xsetinwavepair(0, "Event.2", "Potential", IM_CurrentFreq, "Deflection", IM_Deflection, "", interpval)
			td_WriteString("Event.2", "Once")
	
			CheckInWaveTiming(IM_CurrentFreq)

			Concatenate {IM_CurrentFreq}, IMWaves_CurrentFreq
			
			if (j == 0 && k ==0 )

//				doscanfunc("stopengage")
//				Sleep/S 1
			endif

			td_StopInWaveBank(-1)
			td_StopOutWaveBank(-1)
			
			print td_wv("Output.A", 0)
			 k += 1 
			 
			DoUpdate 
		while (k < numavg)
	
		DeletePoints/M=1 0,1, IMWaves_CurrentFreq
	
		MatrixOp/O outputIM = sumrows(IMWaves_CurrentFreq) / numcols(IMWaves_CurrentFreq)
		Concatenate {outputIM}, IMWaves
	
		Redimension/N=-1 outputIM
		IMWavesAvg[j] = mean(outputIM)
	
		DoUpdate
	
		j += 1
	
	while (j < numpnts(Frequency_List))

	Make/D/N=3/O W_coef
	W_coef[0] = {1e-5,-.15,.05}
	FuncFit/NTHR=1 imskpm W_coef  IMWavesAvg /X=frequency_list /D 
	
	DeletePoints/M=1 0,1, IMWaves
	Beep
	
	//setvfsin(0.01, 1) // lowers amplitude to turn off TTL signal
	TurnOffAWG()
	LoadArbWave(1, 0.25, 0)
	setvfsqu(0.05, 0.25, "wg")	
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	
	doscanfunc("stopengage")
	Sleep/S 1
	
End

Function Shuffle(InWave)
	Wave InWave
	Variable n=numpnts(InWave)
	Make/o/N=(n) order=enoise(n)
	Sort order, InWave
End

Function FrequencyLIst()

	SetDataFolder root:packages:trEFM:PointScan:SKPM
	Make/O/N=30 frequency_list

	frequency_list[0] = 1.8
	frequency_list[1] = 2.5
	frequency_list[2] = 3.7
	frequency_list[3] = 5.6
	frequency_list[4] = 10
	frequency_list[5] = 18
	frequency_list[6] =  37
	frequency_list[7] =  56
	frequency_list[8] = 100
	frequency_list[9] = 178
	frequency_list[10] = 366
	frequency_list[11] = 562
	frequency_list[12] = 1000
	frequency_list[13] = 1778
	frequency_list[14] = 3660
	frequency_list[15] = 5623
	frequency_list[16] = 10000
	frequency_list[17] = 17780
	frequency_list[18] = 36600
	frequency_list[19] = 56230
	frequency_list[20] = 100000
	frequency_list[21] = 177800
	frequency_list[22] = 366000
	frequency_list[23] = 150
	frequency_list[24] = 2000000
	frequency_list[23] = 562300
	frequency_list[24] = 1000000
	frequency_list[25] = 1778000
	frequency_list[26] = 3660000
	frequency_list[27] = 5623000
	frequency_list[28] = 10000000
	frequency_list[29] = 14900000

end

Function imskpm(w,f) : FitFunc
	Wave w
	Variable f

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(f) = 0.5 * C + A*  tau*f * (1 - exp(-1 / (2*f*tau)))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ f
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = tau
	//CurveFitDialog/ w[1] = C
	//CurveFitDialog/ w[2] = A

	return 0.5 * w[1] + w[2]*  w[0]*f * (1 - exp(-1 / (2*f*w[0])))
End


Function SingleFrequency_IMSKPMAM(xpos, ypos, liftheight, numavg, [interpval])

	Variable  xpos, ypos, liftheight, numavg
	variable interpval
	
	if (ParamIsDefault(interpval))
	
		interpval = 1
		
	endif
	
	String savDF = GetDataFolder(1)
	
	SetDataFolder root:Packages:trEFM
	Nvar pgain, sgain, igain, adcgain, setpoint,adcgain
	Svar LockinString
	NVAR ElecDrive, ElecAmp

	Nvar XLVDTsens
	Wave EFMFilters = root:packages:trEFM:EFMFilters
	GetGlobals()

	// Electrical Drive Settings	
	variable EAmp = GV("NapDriveAmplitude")
	variable EFreq = GV("NapDriveFrequency")
	variable EOffset = GV("NapTipVoltage")
	variable EPhase = GV("NapPhaseOffset")
	
//	Nvar numcycles = root:Packages:trEFM:WaveGenerator:numcycles
	NVAR SKPM_voltage = root:packages:trEFM:PointScan:SKPM:ACVoltage // 7.47
	variable current_freq =1
	
	// For the time being, we will be recording 80000 points for 1.6 s
	SetDataFolder root:packages:trEFM:PointScan:SKPM	
	NVAR useHalfOffset = root:packages:trEFM:PointScan:SKPM:usehalfoffset
	NVAR dutycycle = root:packages:trEFM:PointScan:SKPM:dutycycle

	Make/O/N=(80000) IM_CurrentFreq = NaN
	Make/O/N=(80000) IMWaves = NaN
	
	SetPassFilter(1, a = EFMFilters[%EFM][%A], b = EFMFilters[%EFM][%B], fast = EFMFilters[%EFM][%Fast], i = EFMFilters[%EFM][%i], q = EFMFilters[%EFM][%q])

	variable j = 0
	variable k = 0 

	DoWindow/F IM_CurrentFreq
	if (V_flag == 0)
		Display/N=IM_CurrentFreq IM_CurrentFreq
	endif
	
	// USB function generator, futureproofing for FM mode 
	//TurnOnAWG()


	SetDataFolder root:packages:trEFM:PointScan:SKPM
	
	Make/O/N=(80000) IMWaves_CurrentFreq = NaN
	Make/O/N=(80000) IM_Deflection = NaN
	
	k = 0

	do
	
		IM_CurrentFreq = NaN
		
		// Initial settings for outputs.
		td_WV("Output.A", 0)
		td_WV("Output.B", 0)

		StopFeedbackLoop(4)
		StopFeedbackLoop(3)
		StopFeedbackLoop(5)
	
		SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","OutB","DDS")
		MoveXY(xpos, ypos) // Move to xy, keeping the tip raised away from the surface	
		
		LiftTo(liftheight, 0)  // sets Feedback Loop 3 to Z-position
					
		SetCrosspoint ("FilterOut","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Defl","OutC","OutA","OutB","Ground","DDS","Ground")

		td_wv("Output.A", 5) // turn on laser

		td_WriteValue("DDSAmplitude0",EAmp)	
		td_WriteValue("DDSFrequency0",EFreq)	
		td_WriteValue("DDSPhaseOffset0",EPhase)

		SetFeedbackLoop(4, "Always", "InputQ", 0, 0,  8000, 0, "Potential", 0)   // InputQ = $Lockin.0.Q , quadrature lockin output 
		StopFeedbackLoop(3)
		StopFeedbackLoop(5)

		td_xsetinwavepair(0, "Event.2", "Potential", IM_CurrentFreq, "Deflection", IM_Deflection, "", interpval)
		td_WriteString("Event.2", "Once")
	
		CheckInWaveTiming(IM_CurrentFreq)

		Concatenate {IM_CurrentFreq}, IMWaves_CurrentFreq
			
		td_StopInWaveBank(-1)
		td_StopOutWaveBank(-1)
			
		print td_wv("Output.A", 0)
		 k += 1 
			 
		DoUpdate 
	while (k < numavg)
	
	DeletePoints/M=1 0,1, IMWaves_CurrentFreq
	
	MatrixOp/O outputIM = sumrows(IMWaves_CurrentFreq) / numcols(IMWaves_CurrentFreq)
	Concatenate {outputIM}, IMWaves
	
	Redimension/N=-1 outputIM
	Print "Mean SPV is ", mean(outputIM)
	
	DoUpdate
	
	DeletePoints/M=1 0,1, IMWaves
	Beep
	
	//setvfsin(0.01, 1) // lowers amplitude to turn off TTL signal
	TurnOffAWG()
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	
	doscanfunc("stopengage")
	Sleep/S 1
	
End