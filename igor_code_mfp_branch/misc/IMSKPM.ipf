#pragma rtGlobals=3		

// AM-SKPM based approach using built-in Asylum functions
// Consult Daviid's+Jake's notes on the force and NAP panel setups
				
Function PointScanIMSKPM_forcepanel(amplitude)
// This method uses spoofing the force callback mode to enable detection
// Unfortunately, without documentation readily available it's hard to use.
	variable amplitude
	string savDF = GetDataFolder(1)
	SetDataFolder root:packages:MFP3D:Force:
	Wave Potential
	Variable/g SKPM_VOLTAGE
	Variable/G iteration_tracker
	iteration_tracker = 0
	String/G folder_path
	NewPath folder_path
	Make/O/N=29 frequency_list
	variable/G current_freq
	String/G skpm_path

	frequency_list[0] = 1
	
	frequency_list[1] = 1.8
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
	frequency_list[23] = 562300
	frequency_list[24] = 1000000
	frequency_list[25] = 1778000
	frequency_list[26] = 3660000
	frequency_list[27] = 5623000
	frequency_list[28] = 10000000

	
	
	
	//frequency_list[0] = 1
	//frequency_list[1] = 3.7
	//frequency_list[2] = 10
	//frequency_list[3] =  37
	//frequency_list[4] = 100
	//frequency_list[5] = 366
	//frequency_list[6] = 1000
	//frequency_list[7] = 3660
	//frequency_list[8] = 10000
	//frequency_list[9] = 36600
	//frequency_list[10] = 100000
	//frequency_list[11] = 366000
	//frequency_list[12] = 1000000	
	
	//frequency_list[1] = 1
	//frequency_list[3] = 3.7
	//frequency_list[5] = 10
	//frequency_list[7] =  37
	//frequency_list[9] = 100
	//frequency_list[11] = 366
	//frequency_list[12] = 1000
	//frequency_list[10] = 3660
	//frequency_list[8] = 10000
	//frequency_list[6] = 36600
	//frequency_list[4] = 100000
	//frequency_list[2] = 366000
	//frequency_list[0] = 1000000	
		
	SKPM_VOLTAGE = amplitude
	variable i = 0
	string name
	variable wave_points = DimSize(Potential,0)
	Make/O/N=(wave_points,29) IMWaves, MilliWaves, IMWavesAvg
	ARCheckFunc("ARUserCallbackMasterCheck_1",1)
	ARCheckFunc("ARUserCallbackForceDoneCheck_1",1)
	PDS("ARUserCallbackForceDone","Stage1()")
	Stage1()
	print folder_path
End


Function Stage1()
	Wave IMWaves,MIlliWaves
	nvar SKPM_VOLTAGE
	Wave Potential
	nvar current_freq
	nvar iteration_tracker = root:packages:MFP3D:Force:iteration_tracker
	svar skpm_path
	svar folder_path
	Wave frequency_list
	string name
	string savDF2
	
	skpm_path = num2str(current_freq)
	if (iteration_tracker >= 29)
		print "That's it, we're done."
		Save/C/O/P=folder_path IMWaves as "IMWaves.ibw"
		Save/C/O/P=folder_path Milliwaves as "Milliwaves.ibw"
		
		savDF2 = GetDataFolder(1)
		
		SetDataFolder root:Packages:trEFM
		//NVAR gWGDeviceAddress
		//gWGDeviceAddress = 11
		setvfsqu(skpm_voltage, .5, "wg")
		//gWGDeviceAddress = 10
		setdatafolder savDF2
				
		variable iiiii
		for(iiiii = 0; iiiii <4;iiiii+=1)
		Beep
		Sleep/s 1/8	
		endfor
	
		return 0	
	endif
	
	if (iteration_tracker <= 29)
		current_freq = frequency_list[iteration_tracker]
		//print current_freq
	endif
	
	
	PDS("ARUserCallbackForceDone","Stage2()")
	
	savDF2 = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	//NVAR gWGDeviceAddress
	//gWGDeviceAddress = 11
	setvfsqu(skpm_voltage, .5, "wg") //5V to turn the laser on
	//gWGDeviceAddress = 10
	setdatafolder savDF2
	
		
	SimpleEngageMe("")
	Sleep/s 1/2	
	
	print "the current frequency is xxx mHz"
	
	DoForceFunc("SingleForce_2")
End //InitFunc

Function Stage2()
	nvar SKPM_VOLTAGE
	svar skpm_path
	SetDataFolder root:packages:MFP3D:Force
	nvar current_freq
	svar folder_path
	Wave Potential,Milliwaves
	string savDF2
	
	print folder_path
	nvar iteration_tracker = root:packages:MFP3D:Force:iteration_tracker
	
	MilliWaves[][iteration_tracker] = Potential[p]
	
	PDS("ARUserCallbackForceDone","Stage3()")

	savDF2 = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	//NVAR gWGDeviceAddress
	//gWGDeviceAddress = 11
	setvfsqu(skpm_voltage, current_freq, "wg")
	//gWGDeviceAddress = 10
	setdatafolder savDF2
		
	SimpleEngageMe("")
	Sleep/s 1/2
	
	print "the current frequency is:",current_freq,"Hz"
				
	DoForceFunc("SingleForce_2")
End

Function Stage3()
	nvar iteration_tracker = root:packages:MFP3D:Force:iteration_tracker
	svar skpm_path
	WAve ImWAves,Potential, IMWavesAvg
	PDS("ARUserCallbackForceDone","Stage1()")
	
	variable npnts = numpnts(Potential)
	variable spnts = ceil(0.25 * npnts)	// 25% on for averaging
	
	IMWaves[][iteration_tracker] = Potential[p]
	Wavestats/Q/R=[spnts,npnts] Potential
	IMWavesAvg[iteration_tracker] = V_avg

	ARCallbackFunc("ForceDone") // Spoof a force done Callback
	
	iteration_tracker += 1
End

Function FrequencyLIst()

	SetDataFolder root:packages:trEFM:PointScan:SKPM
	Make/O/N=22 frequency_list

	frequency_list[0] = 1
	frequency_list[1] = 1.8
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
//	frequency_list[22] = 366000
//	frequency_list[23] = 562300
//	frequency_list[24] = 1000000
//	frequency_list[25] = 1778000
//	frequency_list[26] = 3660000
//	frequency_list[27] = 5623000
//	frequency_list[28] = 10000000

end

Function PointScanIMSKPM(xpos, ypos, liftheight)

// This method uses a somewhat more "brute force" approac
// Engage on teh surface, lift to panel height, switch the feedback methods and crosspoint
// Then record waves for specific amounts of time
	Variable  xpos, ypos, liftheight

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
	
	Nvar numcycles = root:Packages:trEFM:WaveGenerator:numcycles
	Variable SKPM_voltage = 2.5
	variable current_freq =1
	
	// For the time being, we will be recording 80000 points for 1.6 s
	SetDataFolder root:packages:trEFM:PointScan:SKPM	
	FrequencyList()
	Wave Frequency_List
	Shuffle(Frequency_List)

	Make/O/N=(80000) IM_CurrentFreq = NaN
	
	Make/O/N=(80000) IMWaves = NaN
	Make/O/N=(numpnts(Frequency_List)) IMWavesAvg = NaN
	
	SetPassFilter(1, a = EFMFilters[%EFM][%A], b = EFMFilters[%EFM][%B], fast = EFMFilters[%EFM][%Fast], i = EFMFilters[%EFM][%i], q = EFMFilters[%EFM][%q])

	variable j = 0
	variable k = 0 

	Display IMWavesAvg vs Frequency_List
	ModifyGraph log(bottom)=1
	ModifyGraph mirror=1,fStyle=1,fSize=22,axThick=3;DelayUpdate
	Label left "CPD (V)";DelayUpdate
	Label bottom "Frequency (Hz)"
	ModifyGraph mode=3,marker=16
	
	do

		SetDataFolder root:packages:trEFM:PointScan:SKPM
	
		Make/O/N=(80000) IMWaves_CurrentFreq = NaN
	
		k = 0

		// 0) Set up WaveGenerator	
		current_freq = Frequency_List[j]
		setvfsqu(skpm_voltage, current_freq, "wg")	
//		LiftTo(liftheight, 0)
		do
	
			IM_CurrentFreq = NaN
		
			// Initial settings for outputs.
			td_WV("Output.A", 0)
			td_WV("Output.B", 0)

			StopFeedbackLoop(4)
			
			if ( j == 0 && k ==0 )
	
				StopFeedbackLoop(3)
				StopFeedbackLoop(5)
	
				SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","OutB","DDS")
				MoveXY(xpos, ypos) // Move to xy, keeping the tip raised away from the surface	
			endif
			
			if (j == 0 && k ==0 )
				// 1) Find Surface and Lift tip to specified lift height
				LiftTo(liftheight, 0)  // sets Feedback Loop 3 to Z-position
			endif
						
			// 2) Switch up Crosspoint for Electrical Mode
			SetCrosspoint ("FilterOut","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Defl","OutC","OutA","OutB","Ground","DDS","Ground")

			td_WriteValue("DDSAmplitude0",EAmp)	
			td_WriteValue("DDSFrequency0",EFreq)	
			//td_WriteValue("DDSDCOffset0",EOffset)	
			td_WriteValue("DDSPhaseOffset0",EPhase)
			//td_WriteValue("DDSDCOffset0",0)	
	
			// 3) Set up Feedback Loop for POtential
			SetFeedbackLoop(4, "Always", "InputQ", 0, 0,  8000, 0, "Potential", 0)   // InputQ = $Lockin.0.Q , quadrature lockin output 

			td_xsetinwave(0, "Event.2", "Potential", IM_CurrentFreq, "", interpval)
			td_WriteString("Event.2", "Once")
	
			CheckInWaveTiming(IM_CurrentFreq)

			Concatenate {IM_CurrentFreq}, IMWaves_CurrentFreq
			
			if (j == 0 && k ==0 )

//				doscanfunc("stopengage")
//				Sleep/S 1
			endif

			td_StopInWaveBank(-1)
			td_StopOutWaveBank(-1)
			
			 k += 1
	
		while (k < numcycles)
	
		DeletePoints/M=1 0,1, IMWaves_CurrentFreq
	
		MatrixOp/O outputIM = sumrows(IMWaves_CurrentFreq) / numcols(IMWaves_CurrentFreq)
		Concatenate {outputIM}, IMWaves
	
		Redimension/N=-1 outputIM
		IMWavesAvg[j] = mean(outputIM)
	
		DoUpdate
	
		j += 1
	
	while (j < numpnts(Frequency_List))
	
	DeletePoints/M=1 0,1, IMWaves
	Beep
	
	setvfsin(0.01, 1) // lowers amplitude to turn off TTL signal

	SetDataFolder root:packages:trEFM:PointScan:SKPM
	
End

Function Shuffle(InWave)
	Wave InWave
	Variable n=numpnts(InWave)
	Make/o/N=(n) order=enoise(n)
	Sort order, InWave
End