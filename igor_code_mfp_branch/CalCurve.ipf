#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function Training_Collect()

	SetDataFolder root:packages:trEFM:PointScan:FFtrEFM

	// Assumes we generated 100 taus in Python; see misc/generatePulse.py
	Make/O/N=500 tau_wave_array
	tau_wave_array[] = p 	// equivalent to numpy arange from 0 to 99 inclusive

	NVAR tfp_value = root:packages:trEFM:PointScan:FFtrEFM:tfp_value
	NVAR shift_value = root:packages:trEFM:PointScan:FFtrEFM:shift_value

	NewPath/O pathtemp

	String savDF = GetDataFolder(1)
	Wave shiftwave, gagewave

	Variable i = 0
	
	do
	
		// Every 100 Taus, Retune and Grab the new tune
//		if (mod(i, 100) == 0)
//			CantTuneFunc("DoTuneAutoButton")
//			Sleep/S 10
//			GrabTuneButton("")
//			Sleep/S 5
//		endif
	
		LoadTauWave(tau_wave_array[i]) // Loads the tau wave into the function generator
		Sleep/S 15
		
		// Set data folder for scanning and initialize variables.
		SetDataFolder root:Packages:trEFM:PointScan:FFtrEFM
		FFtrEFMPointScanButton("") // pushes the point scan button

		SetDataFolder root:Packages:trEFM:PointScan:FFtrEFM
		Save/C/O/P = pathtemp gagewave as "wave_phase_" + num2str(i) + ".ibw"
		Sleep/S 1		

		i += 1
			
	while (i < 500)
		
end

Function TauScan(xpos, ypos, liftheight, DigitizerAverages, DigitizerSamples, DigitizerPretrigger)

	Variable xpos, ypos, liftheight,  DigitizerAverages, DigitizerSamples, DigitizerPretrigger
	
	// Pretrigger points are nicely set for given tau values at 10 MHz.
	// Taus are respectively, 10e-9, 25e-9, 50e-9, 100e-9, 250e-9, 500e-9, 1e-6, 5e-6, 10e-6, 100e-6, 1e-3
	Make/O tau_wave_array = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
	Make/O tau_array = {10e-9, 25e-9, 50e-9, 100e-9, 250e-9, 500e-9, 1e-6, 5e-6, 10e-6, 50e-6, 100e-6, 250e-6, 500e-6, 1e-3}
	Make/O/N=(numpnts(tau_wave_array)) tfp_array = NaN
	Make/O/N=(numpnts(tau_wave_array)) shift_array = NaN

	NVAR tfp_value = root:packages:trEFM:PointScan:FFtrEFM:tfp_value
	NVAR shift_value = root:packages:trEFM:PointScan:FFtrEFM:shift_value

	NewPath/O path

	String savDF = GetDataFolder(1)
	Wave shiftwave, gagewave

	Variable i
	// Loop through different values of Tau. Does not change the phase
	for(i = 0; i < 14; i += 1)
	
		// Load excitation wave to the waveform generator and wait for 15 seconds for it to finish loading.
		LoadTauWave(tau_wave_array[i])
		Sleep/S 15
		
		// Set data folder for scanning and initialize variables.
		SetDataFolder root:Packages:trEFM:PointScan:FFtrEFM
		PointScanFFtrEFM(xpos, ypos, liftheight, DigitizerAverages, DigitizerSamples, DigitizerPretrigger)
		
		Save/O/P = path gagewave as "wave_phase_" + num2str(i) + ".ibw"
		 
		Sleep/S 1		
		
		SetDataFolder savDF
		tfp_array[i] = tfp_value			
		shift_array[i] = shift_value
		
		print i, " ---> Tau: ", tau_array[i], "; tfp: ", tfp_value, "; shift: ", shift_value
		
	endfor
	
	GenerateCurve(tfp_array, tau_array)

End

Function PhaseScan180(tau, xpos, ypos, liftheight, DigitizerAverages, DigitizerSamples, DigitizerPretrigger, num)

	// Initialize variables and get current data folder.
	Variable tau, xpos, ypos, liftheight,  DigitizerAverages, DigitizerSamples, DigitizerPretrigger ,num
	String savDF = GetDataFolder(1)

	// Set data folder for scanning and initialize variables.
	SetDataFolder root:Packages:trEFM:PointScan:FFtrEFM
	Wave shiftwave, gagewave

	// Set the path for saving data.
	NewPath/O path

	// Do a point scan with 2000 averages and save it to a file.
	PointScanFFtrEFM(xpos, ypos, liftheight, DigitizerAverages, DigitizerSamples, DigitizerPretrigger)
	
	Save/O/P = path gagewave as "wave_phase_" + num2str(num) + ".ibw"
		 
	Sleep/S 1
	
	// Go back to original data folder.
	SetDataFolder savDF
	
End

Function GenerateCurve(tfp_array, tau_array)
	Wave tfp_array, tau_array
	
	Duplicate/O tfp_array, rate_array
	rate_array = 1/rate_array
	
	DoWindow/F Cal_Curve
		
	if (V_Flag == 0)
		Display/n=CalCurve/K=1 tfp_array vs tau_array 
		AppendToGraph/R rate_array vs tau_array
		ModifyGraph tick=2,fStyle=1,fSize=12,axThick=3,prescaleExp=6;DelayUpdate
		ModifyGraph mirror(bottom) = 1
		Label left "t\\Bfp\\M (us)";DelayUpdate
		Label bottom "tau (us)"
		ModifyGraph mode=4,marker=16,msize=4,lsize=3,rgb=(65280,0,0)
		ModifyGraph log=1
		ModifyGraph prescaleExp(right)=-3,axRGB(left)=(65280,0,0);DelayUpdate
		ModifyGraph axRGB(right)=(0,15872,65280),tlblRGB(left)=(65280,0,0);DelayUpdate
		ModifyGraph tlblRGB(right)=(0,15872,65280),alblRGB(left)=(65280,0,0);DelayUpdate
		ModifyGraph alblRGB(right)=(0,15872,65280);DelayUpdate
		ModifyGraph rgb(rate_array)=(0,15872,65280)
		Label right "1/t\\BFP\\M (kHz)"
	endif
	
end