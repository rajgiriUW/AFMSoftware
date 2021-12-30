#pragma rtGlobals=3		// Use modern global access method and strict wave access.



				
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

