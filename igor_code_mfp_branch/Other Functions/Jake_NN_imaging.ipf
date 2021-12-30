
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//Code written to function with positionscan.ipf version of phasescan180()

//NOTE YOU NEED TO CHANGE SAVE PATH IN POSITIONSCAN.IPF and PHASESCAN180() !!!!!!!!!!!!
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Function collect_training_data(num_averages)
	Variable num_averages
	Variable i
	Variable tau, xpos, ypos, liftheight, DigitizerPretrigger, savenum
	
	Make/O tau_wave_array = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
	Make/O tau_array = {10e-9, 31.62e-9, 100e-9, 316.2e-9, 1e-6, 3.162e-6, 10e-6, 31.62e-6, 100e-6, 316.2e-6, 1e-3}
	
	
	xpos = 0
	ypos = 0
	liftheight = 50
	DigitizerPretrigger = 16384
	savenum = 1
	
	for (i=0; i < numpnts(tau_array); i+=1)
			//PhaseScan180(tau_array[i], DigitizerPreTrigger, xpos, ypos, liftheight, savenum)
	endfor	
end

Function collect_uw_logo()
	
end


Function jtest(i)
	Variable i
	
	Make/O tau_array = {10e-9, 31.62e-9, 100e-9, 316.2e-9, 1e-6, 3.162e-6, 10e-6, 31.62e-6, 100e-6, 316.2e-6, 1e-3}
	
	print numpnts(tau_array)
	
end