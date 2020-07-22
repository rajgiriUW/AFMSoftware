#pragma rtGlobals=3		// Use modern global access method and strict wave access.




Function PhilDegrade(degradeTime, ndegradations)
	
	Variable degradeTime, ndegradations 
	Variable startTime,totalTime,EndTime, sectionstartTime, sectionLength, currentD, newstarttime
	
	SetDataFolder root:Packages:trEFM:ImageScan
	Nvar scansizex, scansizey, scanlines, scanpoints, scanspeed, numavgsperpoint, xoryscan, fitstarttime, fitstoptime
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	SetDataFolder root:Packages:trEFM:ImageScan:trEFM
	
	NVAR RingDownVoltage = root:packages:trEFM:RingDownVoltage
	Make/O/N=(ndegradations) on10Avg
	Make/O/N=(ndegradations) offavg
	Make/O/N=(ndegradations) AmpOn
	Make/O/N=(ndegradations) AmpOff
	currentD = 0
	Wave ChargingRate
	Wave Chi2Image
	
	starttime = StopMSTimer(-2) // Absolute start of the experiment
	nvar xpos= root:packages:trEFM:xpos 
	nvar ypos = root:packages:trEFM:ypos 
	do	
		// Execute series of Ringdown Scans.
		//Light on
		
		// Voltage on at 10V
		RingDownVoltage = 10
		
		ImageScanRingDownEFM(0, 0, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, numavgsperpoint, xoryscan,fitstarttime,fitstoptime)  // Light on - 10 V

		// Do image saving
		WaveStats/Q ChargingRate
		on10Avg[currentD] = V_avg
		Wavestats/Q Chi2Image
		AmpOn[currentD] = V_avg
		
		
		LightOnOrOffButton("") // Light is now off
		
		RingDownVoltage = 0
		ImageScanRingDownEFM(0, 0, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, numavgsperpoint, xoryscan,fitstarttime,fitstoptime)

		WaveStats/Q ChargingRate
		offAvg[currentD] = V_avg
		Wavestats/Q Chi2Image
		AmpOff[currentD] = V_avg
		// Degrade the Sample.
		LightOnButton("") 
		
		newstarttime = StopMSTimer(-2)
		WaitSec(degradeTime)
		print StopMSTimer(-2)-newstarttime
		totalTime = StopMSTimer(-2)-starttime / 1e6
		print totaltime
		currentD += 1
		LightOffButton("") 
		LightOnOrOffButton("")
	while(currentD < ndegradations)
	LightOffButton("") 
	
	print StopMSTimer(-2) - starttime  //  This is the total time taken by the process
End


Function WaitSec(seconds)
	variable seconds
	
	Variable startTime = StopMSTimer(-2)
	do

	while( StopMSTimer(-2) - startTime < seconds*1e6) // End of one wait period

End