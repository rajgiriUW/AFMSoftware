#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function PLSpotDegrade(mins)
	variable mins
	
	Make/O/N = 500 PLvsTime = 0
	Make/O/N = 500 PLTimer = 0
	
	variable startTime
	variable i = 0
	variable j = 0
	
	variable lockinSens = 22
	SetLockInSensitivity(lockinSens)
	// 17 = 1 nA
	// 18 = 2 nA
	// 19 = 5 nA
	// 20 = 10 nA
	// 21 = 20 nA
	// 22 = 50 nA
	// 23 = 100 nA
	// 24 = 200 nA
	// 25 = 500 nA
	// 26 = 1 uA
	Make/O/N=10 LockInValues = {1e-9, 2e-9, 5e-9, 10e-9, 20e-9, 50e-9, 100e-9, 200e-9, 500e-9, 1e-6}
	
	variable LockInReading = 0
	
	OpenShutterButton("")
	
	do

		startTime = StopMSTimer(-2)
		do 
		// runs for 1 min
		while((StopMSTimer(-2) - StartTime) < 1*60*1e6) 
		
		LockInReading = td_rv("Input.B") 	
		PLvsTime[i] = LockInReading/10  * LockInValues[lockInSens - 17]
		Print "PL is ", PLvsTime[i] 
		PLTimer[i] = j	// x-axis
	
		// adjust lockin sensitivity if greater than 8 V coming from LIA
		if ( LockInReading > 8)
		
			lockinSens += 1	
			setLockInSensitivity(lockinSens)
			Sleep/S 1
		
		endif
	
		// turn off the laser if lockin sensitivity if greater than 8 V and the LIA sensitivity is max
		if ( LockInReading > 8 && lockinSens == 26)
			setvf(0, 1,"WG")
		endif
		
		DoUpdate
	
		i += 1
		j += 1
	
	while (j < mins)
	
	CloseShutterButton("")
	
	Beep	
	
end