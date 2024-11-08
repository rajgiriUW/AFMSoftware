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
	NewPanel /W=(2803,711,3213,1039)
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (56576,56576,56576)
	DrawRect 248,11,407,194
	SetDrawEnv fillfgc= (56576,56576,56576)
	DrawRect 10,12,244,327
	SetDrawEnv fillfgc= (56576,56576,56576)
	DrawRect 249,203,405,325
	SetDrawEnv fsize= 10
	DrawText 152,207,"min: 20, max: 80"
	SetDrawEnv fname= "Calibri",fsize= 15,fstyle= 5
	DrawText 67,30,"Single Point Sweep"
	SetDrawEnv fname= "Calibri",fsize= 15,fstyle= 5
	DrawText 299,32,"Image Scan"
	SetDrawEnv fname= "Calibri",fsize= 15,fstyle= 5
	DrawText 282,223,"Other Methods"
	DrawRRect 114,136,240,227
	Button button1,pos={46,38},size={142,24},proc=IMSKPMAMButton,title="IM-SKPM (AM) Point Scan"
	SetVariable setvar1,pos={17,75},size={60,16},title="X"
	SetVariable setvar1,limits={-inf,inf,0},value= root:packages:trEFM:gxpos
	SetVariable setvar2,pos={15,99},size={60,16},title="Y"
	SetVariable setvar2,limits={-inf,inf,0},value= root:packages:trEFM:gypos
	SetVariable setvar3,pos={130,74},size={100,16},title="lift height (nm)"
	SetVariable setvar3,limits={-inf,inf,0},value= root:packages:trEFM:liftheight
	SetVariable setvar4,pos={110,98},size={120,16},title="Number of Averages"
	SetVariable setvar4,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:numavg
	SetVariable IMSKPMVoltage,pos={119,158},size={115,16},title="Func Gen Voltage"
	SetVariable IMSKPMVoltage,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:ACVoltage
	CheckBox UseOffset,pos={148,209},size={87,14},title="No DC Offset?"
	CheckBox UseOffset,variable= root:packages:trEFM:PointScan:SKPM:usehalfoffset,side= 1
	Button buttonFMIM,pos={258,269},size={139,31},proc=IMSKPMFMButton,title="IM-SKPM (FM) Point Scan\r (Slow!)"
	Button buttonFMIM,fColor=(52224,52224,52224)
	Button buttonFMIM1,pos={268,233},size={122,28},proc=IM_FFtrEFMButton,title="IM-EFM Point Scan"
	Button buttonFMIM1,fColor=(47872,47872,47872)
	SetVariable DutyCycle,pos={148,178},size={86,16},title="Duty Cycle %"
	SetVariable DutyCycle,limits={10,90,0},value= root:packages:trEFM:PointScan:SKPM:dutycycle
	SetVariable scanpointsT,pos={282,64},size={100,16},title="Scan Points    "
	SetVariable scanpointsT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanpoints
	SetVariable scanlinesT,pos={283,88},size={100,16},title="Scan Lines     "
	SetVariable scanlinesT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanlines
	SetVariable scanspeedT,pos={270,112},size={113,16},title="Scan Speed(um/s)"
	SetVariable scanspeedT,fSize=10
	SetVariable scanspeedT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanspeed
	Button button2,pos={258,39},size={142,24},proc=IMSKPMAM_ImageScanButton,title="IM-SKPM (AM) Image Scan"
	SetVariable scanwidthT,pos={283,138},size={100,16},title="Width (�m)        "
	SetVariable scanwidthT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizex
	SetVariable scanheightT,pos={283,163},size={100,16},title="Height (�m)       "
	SetVariable scanheightT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizey
	Button button3,pos={21,264},size={92,35},proc=IMSKPMSingle_AMButton,title="IM-SKPM (AM) \rSingle Frequency"
	SetVariable MeanCPD,pos={53,234},size={146,16},title="Mean CPD = "
	SetVariable MeanCPD,labelBack=(65280,48896,48896),fStyle=1
	SetVariable MeanCPD,limits={20,80,0},value= root:packages:trEFM:PointScan:SKPM:MeanCPD,noedit= 2
	CheckBox Use81150A,pos={161,140},size={72,14},title="Use Siglent"
	CheckBox Use81150A,variable= root:packages:trEFM:PointScan:SKPM:Use81150,side= 1
	Button FreqButton,pos={144,263},size={81,35},proc=IMFrequencyListButton,title="Edit Frequency \rList"
	Button button15,pos={19,125},size={57,19},proc=GetCurrentPositionButton,title="Current XY"
	Button button15,help={"Fill the X,Y with the current stage position."}
	CheckBox DCInterleave,pos={120,117},size={111,14},title="DC step in between"
	CheckBox DCInterleave,variable= root:packages:trEFM:PointScan:SKPM:DCInterleave,side= 1
	CheckBox Intensityoffset,pos={21,184},size={89,26},title="Intensity offset \rat high freq?"
	CheckBox Intensityoffset,variable= root:packages:trEFM:PointScan:SKPM:Intensityoffset,side= 1
	SetVariable Intensity1,pos={21,214},size={86,16},title="Intensity %"
	SetVariable Intensity1,limits={10,90,0},value= root:packages:trEFM:PointScan:SKPM:Intensity1
	CheckBox do_toff_IMSKPM,pos={23,152},size={80,26},title="laser time off \r IMSKPM?"
	CheckBox do_toff_IMSKPM,variable= root:packages:trEFM:PointScan:SKPM:do_toff_IMSKPM,side= 1
EndMacro


/////////////////////////////////

Function IMFrequencyListButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	NVAR do_toff_IMSKPM = root:packages:trEFM:PointScan:SKPM:do_toff_IMSKPM
	NVAR freqlistchoice = root:packages:trEFM:PointScan:SKPM:freqlistchoice

	Wave Frequency_list
	if (!WaveExists(Frequency_List))
		if (do_toff_IMSKPM==0)
			freqlistchoice=0
		else
			freqlistchoice=2
		endif
		FrequencyList(freqlistchoice)
		Wave Frequency_list
	endif
	
	Edit Frequency_list
	
	SetDataFolder savDF
	
End

Function IMSKPMAMButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	NVar  xpos =  root:packages:trEFM:gxpos
	NVAR ypos =  root:packages:trEFM:gypos
	NVAR liftheight =  root:packages:trEFM:liftheight
	NVAR numavg = root:packages:trEFM:PointScan:SKPM:numavg
	NVAR do_toff_IMSKPM = root:packages:trEFM:PointScan:SKPM:do_toff_IMSKPM
	NVAR freqlistchoice = root:packages:trEFM:PointScan:SKPM:freqlistchoice
	
	Wave Frequency_List = root:packages:trEFM:PointScan:SKPM:frequency_list
	if (!WaveExists(Frequency_List))
		if (do_toff_IMSKPM==0)
			freqlistchoice=0
		else
			freqlistchoice=2
		endif
		FrequencyList(freqlistchoice)
		Wave Frequency_list
	endif
	
	PointScanIMSKPM_AM(xpos, ypos, liftheight, numavg)
	SetDataFolder savDF
	
End

Function IMSKPMSingle_AMButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	NVar  xpos =  root:packages:trEFM:gxpos
	NVAR ypos =  root:packages:trEFM:gypos
	NVAR liftheight =  root:packages:trEFM:liftheight
	NVAR numavg = root:packages:trEFM:PointScan:SKPM:numavg
	SingleFrequency_IMSKPMAM(xpos, ypos, liftheight, numavg)
	
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
	Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
	
	PIXELCONFIG[%Total_Time] = DigitizerTime * 1e-3
	PIXELCONFIG[%Trigger] = (1-DigitizerPercentPreTrig/100) * DigitizerTime * 1e-3
	SetDataFolder root:Packages:trEFM
	
	NVAR liftheight =  root:packages:trEFM:liftheight
	NVar  gxpos =  root:packages:trEFM:gxpos
	NVAR gypos =  root:packages:trEFM:gypos
	Nvar WavesCommitted
	Nvar UsePython
	NVAR numavg = root:packages:trEFM:PointScan:SKPM:numavg
	NVAR do_toff_IMSKPM = root:packages:trEFM:PointScan:SKPM:do_toff_IMSKPM
	NVAR freqlistchoice = root:packages:trEFM:PointScan:SKPM:freqlistchoice
	
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

	Wave Frequency_List = root:packages:trEFM:PointScan:SKPM:frequency_list	
	if (!WaveExists(Frequency_List))
		if (do_toff_IMSKPM==0)
			freqlistchoice=0
		else
			freqlistchoice=2
		endif
		FrequencyList(freqlistchoice)
		Wave Frequency_list
	endif
	
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
	variable current_pwr
	variable current_duty
	NVAR Use81150 = root:packages:trEFM:pointScan:SKPM:Use81150
	
	// For the time being, we will be recording 80000 points for 1.6 s
	SetDataFolder root:packages:trEFM:PointScan:SKPM	
	DutyList()
	Wave intensity_List = root:packages:trEFM:PointScan:SKPM:intensity_list
	Wave Frequency_List = root:packages:trEFM:PointScan:SKPM:frequency_list
	Wave duty_List = root:packages:trEFM:PointScan:SKPM:duty_list
	Wave t_off_List = root:packages:trEFM:PointScan:SKPM:t_off_list
	
	NVAR useHalfOffset = root:packages:trEFM:PointScan:SKPM:usehalfoffset
	NVAR dutycycle = root:packages:trEFM:PointScan:SKPM:dutycycle
	NVAR MeanCPD = root:packages:trEFM:pointscan:SKPM:MeanCPD
	NVAR DCinterleave = 	root:packages:trEFM:PointScan:SKPM:DCInterleave
	NVAR Intensityoffset = root:packages:trEFM:PointScan:SKPM:Intensityoffset
	NVAR do_toff_IMSKPM = root:packages:trEFM:PointScan:SKPM:do_toff_IMSKPM

	// For offseting the laser intensity in IMSKPM spectra
	NVAR intensity1 = root:packages:trEFM:PointScan:SKPM:Intensity1
	
	// These two bits of code are for debugging/removing artifacts. 
	// 	First line just reverses the frequencies
	// 	Second line randomizes the frequencies 
//	Reverse Frequency_list
//	Shuffle(Frequency_List)

	// CurrentFreq = current CPD trace
	// IMWaves_CurrentFreq = multiple CPD runs at the current frequency, then averaged together if # averages > 1
	// Deflection = raw deflection, mostly used in EFM only
	// IMWaves = 

	Make/O/N=(80000) IM_CurrentFreq = NaN
	Make/O/N=(80000) IMWaves_CurrentFreq = NaN
	Make/O/N=(80000) IM_Deflection = NaN
	Make/O/N=(80000) IMWaves_Matrix = NaN
	Make/O/N=(numpnts(Frequency_List)) IMWavesAvg = NaN
	Make/O/N=(numpnts(Frequency_List)) IMDC = NaN
	
	SetPassFilter(1, a = EFMFilters[%EFM][%A], b = EFMFilters[%EFM][%B], fast = EFMFilters[%EFM][%Fast], i = EFMFilters[%EFM][%i], q = EFMFilters[%EFM][%q])

	variable j = 0
	variable k = 0 
	variable m = 0 // for DC interleave step

	DoWindow/F IMSKPM0
	if (V_flag == 0)
		if (do_toff_IMSKPM==1) // do regular IMSKPM vs frequency_list, if ==1: do t_off IMSKPM
			Display/K=1/N=IMSKPM IMWavesAvg vs t_off_List
			ModifyGraph log(bottom)=1
			ModifyGraph mirror=1,fStyle=1,fSize=22,axThick=3;DelayUpdate
			Label left "CPD (V)";DelayUpdate
			Label bottom "Laser time off (ns)"
			ModifyGraph mode=3,marker=16
		else
			Display/K=1/N=IMSKPM IMWavesAvg vs Frequency_List
			ModifyGraph log(bottom)=1
			ModifyGraph mirror=1,fStyle=1,fSize=22,axThick=3;DelayUpdate
			Label left "CPD (V)";DelayUpdate
			Label bottom "Frequency (Hz)"
			ModifyGraph mode=3,marker=16
		endif
	endif
	
	if (DCInterleave == 1)
		DoWindow IMDC
		if (V_flag == 0)
			Display/K=1/N=IMDC IMDC vs Frequency_List
			ModifyGraph log(bottom)=1
			ModifyGraph mirror=1,fStyle=1,fSize=22,axThick=3;DelayUpdate
			Label left "CPD (V)";DelayUpdate
			Label bottom "Frequency (Hz)"
			ModifyGraph mode=3,marker=15
			ModifyGraph rgb=(0,0,52224)
		endif
	endif
	
	DoWindow/F IM_CurrentFreq0
	if (V_flag == 0)
		Display/N=IM_CurrentFreq IM_CurrentFreq
	endif
	
	// USB function generator, futureproofing for FM mode 
	//TurnOnAWG()
	do

		SetDataFolder root:packages:trEFM:PointScan:SKPM
	
		// Future Proofing for imaging when want to cut sampling time down
		if (current_freq > 1e9)
			Make/O/N=(10000) IM_CurrentFreq = NaN
			Make/O/N=(10000) IMWaves_CurrentFreq = NaN
			Make/O/N=(10000) IM_Deflection = NaN	
			Make/O/N=(10000) IMWaves = NaN
		else
			Make/O/N=(80000) IM_CurrentFreq = NaN
			Make/O/N=(80000) IMWaves_CurrentFreq = NaN
			Make/O/N=(80000) IM_Deflection = NaN
			Make/O/N=(80000) IMWaves = NaN
		endif
		
		k = 0

		if (Intensityoffset==1)
		// change to corresponding laser intensity offset to compensate for high freq intensity decrease
		//for now: intneisty only works for 10 20 40
			IntensityLIst(Intensity1)
			current_pwr = intensity_list[j]
			string current_pwr_str2 = "?TPP" + num2str(current_pwr)+"\r\n"
			print "current_pwr_str2=", current_pwr_str2
			VDTWrite2 current_pwr_str2
		endif
//		eg. what what is should look like to change the intensity: VDTWrite2 "?TPP20.0\r\n"
		
		// 0) Set up WaveGenerator
		current_freq = Frequency_List[j]
		
		if(do_toff_IMSKPM==1)
			current_duty = duty_List[j]
			t_off_list[j] = (100-duty_list[j])*0.01/frequency_list[j]*1000000000 //in ns, the time off
		else
			current_duty =dutycycle
		endif
		
		if (use81150 != 0)
			// turn on laser CW, wait for 5s, then run IMSKPM - to account for inconsistency when light first turn on and CPD changes slowly.	
			//LoadDCWave81150(5)
			//Sleep/S 5
			LoadSquareWave81150(skpm_voltage, current_freq, EOM=usehalfoffset, duty=current_duty, offset=0.5)
			//LoadSquareWave81150(skpm_voltage, current_freq, EOM=usehalfoffset, duty=dutycycle)
			//LoadSineWave81150(skpm_voltage, current_freq, EOM=usehalfoffset, duty=dutycycle, offset=0.5)		
		else
			setvfsqu(skpm_voltage, current_freq, "wg", EOM=usehalfoffset, duty=dutycycle)	 
		endif
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
//			StopFeedbackLoop(3)
			StopFeedbackLoop(5)

			// 80000 points @ 50 kHz = 1.6 s @ interpval 1
			interpval = round(5 / current_freq)
			if (interpval < 1)
				interpval = 1
			endif
			print "Interpval = ", interpval, " Frequency: ", current_Freq, "Duty cycle:", current_duty, "t_on (ns):", current_duty/100/current_freq*1e9, "t_off (ns):", (1-current_duty/100)/current_freq*1e9
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
		Concatenate {outputIM}, IMWaves_Matrix
	
		Redimension/N=-1 outputIM
		IMWavesAvg[j] = mean(outputIM)
		
		MeanCPD = mean(outputIM)
	
		DoUpdate
	
		// DC Interleaved for samples with lots of halide migration
		// Ugly copy-paste from above...
		if (DCInterleave == 1)
			SetDataFolder root:packages:trEFM:PointScan:SKPM
			if (current_freq > 1e9)
				Make/O/N=(10000) IM_CurrentFreq = NaN
				Make/O/N=(10000) IMWaves_CurrentFreq = NaN
				Make/O/N=(10000) IM_Deflection = NaN	
				Make/O/N=(10000) IMWaves = NaN
			else
				Make/O/N=(80000) IM_CurrentFreq = NaN
				Make/O/N=(80000) IMWaves_CurrentFreq = NaN
				Make/O/N=(80000) IM_Deflection = NaN
				Make/O/N=(80000) IMWaves = NaN
			endif
			
			if (use81150 != 0)
				//LoadSquareWave81150(100e-3, 1e-4, EOM=usehalfoffset, duty=dutycycle, offset=skpm_voltage)	
				//LoadSineWave81150(100e-3, 1e-4, EOM=usehalfoffset, duty=dutycycle, offset=1.2)	
			else
				setvfsqu(100e-3, 1e-4, "wg", EOM=usehalfoffset, duty=dutycycle)	 
			endif			
			
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

			print "DC step"
			td_xsetinwavepair(0, "Event.2", "Potential", IM_CurrentFreq, "Deflection", IM_Deflection, "", interpval)
			td_WriteString("Event.2", "Once")
	
			CheckInWaveTiming(IM_CurrentFreq)
			
			td_StopInWaveBank(-1)
			td_StopOutWaveBank(-1)
			
			print td_wv("Output.A", 0)

			IMDC[j] = mean(IM_CurrentFreq)
			
			DoUpdate		

		endif

		j += 1

	while (j < numpnts(Frequency_List))
	//while (j < numpnts(duty_List))

//	Make/D/N=3/O W_coef
//	W_coef[0] = {1e-5,-.15,.05}
//	FuncFit/NTHR=1 imskpm W_coef  IMWavesAvg /X=frequency_list /D 
	
	DeletePoints/M=1 0,1, IMWaves_Matrix
	NewImage/F IMWaves_Matrix
	Beep
	
	//setvfsin(0.01, 1) // lowers amplitude to turn off TTL signal
	//TurnOffAWG()
	//LoadArbWave(1, 0.25, 0)
	if (use81150 != 0)
		TurnOff81150()
	endif
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

Function FrequencyLIst(freqlistchoice)

	variable freqlistchoice
	SetDataFolder root:packages:trEFM:PointScan:SKPM

	if (freqlistchoice==0)
	Make/O/N=28 frequency_list
			frequency_list[0,5] = {1.00000000e+00, 1.74752840e+00, 3.05385551e+00, 5.33669923e+00, 9.32603347e+00, 1.62975083e+01}
			frequency_list[6,11] = {2.84803587e+01, 4.97702356e+01, 8.69749003e+01, 1.51991108e+02, 2.65608778e+02, 4.64158883e+02}
			frequency_list[12,16] = {8.11130831e+02, 1.41747416e+03, 2.47707636e+03, 4.32876128e+03, 7.56463328e+03}
			 frequency_list[17,21] = {1.32194115e+04, 2.31012970e+04, 4.03701726e+04, 7.05480231e+04, 1.23284674e+05}
			 frequency_list[22,25] = {2.15443469e+05, 3.76493581e+05, 6.57933225e+05, 1.14975700e+06}
			 frequency_list[26,27] = {3.51119173e+06, 1.07226722e+07}
		
		//	frequency_list[0] = 1
		//	frequency_list[1] = 2
		//	frequency_list[2] = 3
		//	frequency_list[3] = 5
		//	frequency_list[4] = 10
		//	frequency_list[5] = 20
		//	frequency_list[6] =  30
		//	frequency_list[7] =  50
		//	frequency_list[8] = 100
		//	frequency_list[9] = 200
		//	frequency_list[10] = 300
		//	frequency_list[11] = 500
		//	frequency_list[12] = 1000
		//	frequency_list[13] = 2000
		//	frequency_list[14] = 3000
		//	frequency_list[15] = 5000
		//	frequency_list[16] = 10000
		//	frequency_list[17] = 20000
		//	frequency_list[18] = 30000
		//	frequency_list[19] = 50000
		//	frequency_list[20] = 100000
		//	frequency_list[21] = 200000
		//	frequency_list[22] = 300000
		//	frequency_list[23] = 500000
		//	frequency_list[24] = 1000000
		//	frequency_list[23] = 2000000
		//	frequency_list[24] = 3000000
		//	frequency_list[25] = 5000000
		//	frequency_list[26] = 7000000
		//	frequency_list[27] = 10000000
		//	frequency_list[28] = 20000000
		//	frequency_list[29] = 30000000
		//	frequency_list[30] = 50000000
		//	frequency_list[31] = 70000000
		//	frequency_list[32] = 100000000
		//	frequency_list[33] = 120000000
	endif
	if (freqlistchoice==1)
		// Linearly spaced using numpy.logspace
		// this set of frequency_list must be used for intensity offset
		//	frequency_list[0,5] = {1.00000000e+00, 1.74752840e+00, 3.05385551e+00, 5.33669923e+00, 9.32603347e+00, 1.62975083e+01}
		//	frequency_list[6,11] = {2.84803587e+01, 4.97702356e+01, 8.69749003e+01, 1.51991108e+02, 2.65608778e+02, 4.64158883e+02}
		//	frequency_list[12,16] = {8.11130831e+02, 1.41747416e+03, 2.47707636e+03, 4.32876128e+03, 7.56463328e+03}
		//	 frequency_list[17,21] = {1.32194115e+04, 2.31012970e+04, 4.03701726e+04, 7.05480231e+04, 1.23284674e+05}
		//	 frequency_list[22,26] = {2.15443469e+05, 3.76493581e+05, 6.57933225e+05, 1.14975700e+06, 2.00923300e+06}
		//	 frequency_list[27,31] = {3.51119173e+06, 6.13590727e+06, 1.07226722e+07, 1.87381742e+07, 3.27454916e+07}
		//	 frequency_list[32,33] = {5.72236766e+07, 1.00000000e+08}
		//	 frequency_list[34,36] = {1.3e+08,1.6e+08, 2e+08}
	endif
	if (freqlistchoice==2)
	Make/O/N=27 frequency_list
		frequency_list[0,4]= {166666.6667, 166666.6667, 166666.6667, 166666.6667, 200000.0000}
		frequency_list[5,9] ={250000.0000, 270270.2703, 285714.2857, 312500.0000, 357142.8571}
		frequency_list[10,14] ={384615.3846, 416666.6667, 438596.4912, 454545.4545, 462962.9630}
		frequency_list[15,19] ={471698.1132, 476190.4762, 480769.2308, 484261.5012, 487804.8780}
		frequency_list[20,26] ={488997.5550, 490196.0784, 491159.1356, 491883.9154, 492610.8374, 493339.9112, 493827.1605}
	endif
end

Function IntensityLIst(Intensity1)
//VDTWrite2 "?TPP20.0\r\n"
// can only be 10, 20 40% for now

	variable intensity1
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	Make/O/N=37 intensity_list
	
	if (intensity1==10)
		intensity_list[0,5] = {10, 10,10,10,10,10}
		intensity_list[6,11] = {10,10,10,10,10,10}
		intensity_list[12,16] = {10,10,10,10,10}
		intensity_list[17,21] = {10,10,10,10,10}
		intensity_list[22,26] = {10,10,10,10,10}
		intensity_list[27,31] = {10.1, 10.5, 11, 11.3, 11.5}
		intensity_list[32,33] = {17.9, 25.4}
		intensity_list[34,36] = {34, 44.3, 62.6}
	endif
	if (intensity1==20)
		intensity_list[0,5] = {20,20,20,20,20,20}
		intensity_list[6,11] = {20,20,20,20,20,20}
		intensity_list[12,16] = {20,20,20,20,20}
		intensity_list[17,21] = {20,20,20,20,20}
		intensity_list[22,26] = {20,20,20,20.1,20.3}
		intensity_list[27,31] = {20.6,21.2,21.9,23.3,26.2}
		intensity_list[32,33] = {30.7,40.5}
		intensity_list[34,36] = {47.7,59.5,81.0}
	endif
	if (intensity1==40)
		intensity_list[0,5] = {40,40,40,40,40,40}
		intensity_list[6,11] = {40,40,40,40,40,40}
		intensity_list[12,16] = {40,40,40,40,40}
		intensity_list[17,21] = {40,40,40,40,40}
		intensity_list[22,26] = {40,40,40,40,40.3}
		intensity_list[27,31] = {40.8,41.3,42.5,44.5,48.5}
		intensity_list[32,33] = {55.1,67.8}
		intensity_list[34,36] = {74.3,87.5,100}
	endif
	
End

Function DutyLIst()
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	Make/O/N=27 duty_list
	Make/O/N=27 t_off_list
	
	// for now: values for 5% power baseline - higher freq offset back to 5% value
//	duty_list[0] = 99.5
//	duty_list[1] =99.2
//	duty_list[2] =99
//	duty_list[3] =98.8
//	duty_list[4] =98
//	duty_list[5] =95
//	duty_list[6] =90
//	duty_list[7] =80
//	duty_list[8] =70
//	duty_list[9] = 60
	
	duty_list[0,4] = {33.3333, 33.3333, 33.3333, 33.3333, 40.0000}
	duty_list[5,9] = {50.0000, 54.0541, 57.1429, 62.5000, 71.4286}
	duty_list[10,14] = {76.9231, 83.3333, 87.7193, 90.9091, 92.5926}
	duty_list[15,19] = {94.3396, 95.2381, 96.1538, 96.8523, 97.5610}
	duty_list[20,26] = {97.7995, 98.0392, 98.2318, 98.3768, 98.5222, 98.6680, 98.7654}

end

//test_freq_list = 1/((t_on+test_time_off_list)*1e-9)
//test_duty_list = t_on/(test_time_off_list+t_on)*100

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
	NVAR Use81150 = root:packages:trEFM:pointScan:SKPM:Use81150

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
	
	NVAR MeanCPD = root:packages:trEFM:PointScan:SKPM:MeanCPD
	MeanCPD = mean(outputIM)
	
	DoUpdate
	
	DeletePoints/M=1 0,1, IMWaves
	Beep
	
	//setvfsin(0.01, 1) // lowers amplitude to turn off TTL signal
	//TurnOffAWG()
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	
	doscanfunc("stopengage")
	Sleep/S 1
	
End

// to do IMSKPM point scan, change laser intensity, duplicat and appendtograph
// doesn't work for t_off IMSKPM yet

function PointScanIMSKPM_AM_intensity(xpos, ypos, liftheight, numavg)

	Variable  xpos, ypos, liftheight, numavg
	Wave Frequency_List = root:packages:trEFM:PointScan:SKPM:frequency_list
	Wave IMWavesAvg = root:packages:trEFM:PointScan:SKPM:IMWavesAvg
	
	
	//change the laser intensity list here
	//eg. what what is should look like to change the intensity: VDTWrite2 "?TPP20.0\r\n"
	//laser intensity is between ?TPP and \r\n
	make/O/T/N=2 laser_intensity_list
//	laser_intensity_list[0] = "?TPP5.0\r\n"
//	laser_intensity_list[1] = "?TPP7.0\r\n"
	laser_intensity_list[0] = "?TPP20.0\r\n"
	laser_intensity_list[1] = "?TPP50.0\r\n"
//	laser_intensity_list[3] = "?TPP80.0\r\n"
//	laser_intensity_list[4] = "?TPP99.0\r\n"
//	laser_intensity_list[5] = "?TPP5.0\r\n"
	
	variable n = 0

	
	DoWindow/F IMSKPM1
	if (V_flag == 0)
		Display/K=1/N=IMSKPM IMWavesAvg vs Frequency_List
		ModifyGraph log(bottom)=1
		ModifyGraph mirror=1,fStyle=1,fSize=22,axThick=1;DelayUpdate
		Label left "CPD (V)";DelayUpdate
		Label bottom "Frequency (Hz)"
		ModifyGraph mode=3,marker=16
		legend
		Legend/C/N=text0/J/X=50.00/Y=0.00
	endif
	
	do
		string laserlistname1 = laser_intensity_list[n]
		string laserlistname2 = "intensity_" + laserlistname1[4,5]+"%"
		print "laserlistname2=", laserlistname2
		
		VDTWrite2 laser_intensity_list[n]
		print laser_intensity_list[n]
		PointScanIMSKPM_AM(xpos, ypos, liftheight, numavg)
		
		duplicate IMWavesAvg, $laserlistname2
		wave dupl_IMWavesAvg = $laserlistname2
		appendtograph/W=IMSKPM1 dupl_IMWavesAvg vs frequency_list
		ModifyGraph/W=IMSKPM1 mode($laserlistname2)=3, marker($laserlistname2)=19
		//let colour change automatically w/ laser intensity?
		
		doupdate
		
		n+= 1

	while (n < numpnts(laser_intensity_list))
	
End

