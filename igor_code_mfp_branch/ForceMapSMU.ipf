#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// NOTE: these don't really do anything, but there's some relevant analysis code
// Procedure is: Load Procedures-->XCalculated.ipf
// Edit "ForceCalcRaj" to uncomment the SMURead() call. JUst ctrl+f and search "Raj"
// Then, in Force Map, add a channel to capture and use ForceCalcRaj as the function. 
// Note that it saves as a "modified ADhesion channel" so if you line-flatten the adhesion after, it overwrites it
// Also, it will save in units of "Newton" but with the prefix according the Keithley. i.e. milliNewtons == milliAmps

// Call SMUOECTSetup(voltage=whatever) before you start. Then use the ForceMap panel

function MapvsCurrent(inw, layer, moduli, currents)

// Before calling, Make/O/N=0 Moduli; Make/O/N=0 Currents
// Layer = Modulus Layer
	Wave inw // ForceMap
	variable layer
	wave moduli
	wave currents
	
	setDataFolder root:packages:trEFM:ImageScan
	
	Duplicate/O/R=[][][layer] inw, TempMap
	Duplicate/O/R=[][][2] inw, current
	
	Redimension/N=(-1,-1) TempMap,current
//	Redimension/N=-1 TempMap
	
	Make/O/N=(numpnts(TempMap)) ScatterPlot
	
	Concatenate {Tempmap}, Moduli
	Concatenate {Current}, Currents
	
	Display Moduli vs CUrrents
	ModifyGraph mode=3,marker=19
	ModifyGraph mirror=1,fStyle=1,fSize=18,axThick=3,prescaleExp(left)=-6;DelayUpdate
	ModifyGraph prescaleExp(bottom)=3;DelayUpdate
	Label left "Modulus (MPa)";DelayUpdate
	Label bottom "Drain-Source Current (mA)"
	ModifyGraph tickUnit=1
	
end

// These all don't work, you can ignore 

function FMapSMU2(voltage)
// Plan B: Edit the XCalculated Function and add that as a channel. Devious!
// Set the Calc Tab to do FMapCalcRaj as Channel 2.
	variable voltage
	if (abs(voltage) > 1)
		Abort "Voltage above 1 V is not recommended in water!"
	endif
	
	SetDataFolder root:packages:trEFM:ImageScan

	SMUSetup(voltage=voltage)
	SMURead()
	
	Wave DataValues = root:packages:trEFM:ImageScan:DataValues
	print "Current = ", DataValues[1]
	
	FMapButtonFunc("DownFMap_2") 
end

function FMapSMU(voltage)

// Basically, what this will be do is generate a matrix of the size xsize, ysize
// Then, it will interrogate if the Xsetpoint or YSetpoint changes from PIDSLoop0 and PIDSLoop1
// If they do, then Read the current. 
	variable voltage
	
	if (abs(voltage) > 1)
		Abort "Voltage above 1 V is not recommended in water!"
	endif
	
	SetDataFolder root:packages:trEFM:ImageScan

	Wave  FVW = root:packages:MFP3D:Main:Variables:ForceVariablesWave
	variable xpnts = FVW[%FMapScanPoints][%Value]
	variable ypnts = FVW[%FMapScanLines][%Value]
	
	Make/O/N=(xpnts, ypnts) CurrentWave = NaN
	Make/O/N=(xpnts, ypnts) TimeWave = NaN
	
	variable r = 0
	variable c = 0
	
	variable xsetpoint = td_rv("ARC.PIDSLoop.0.Setpoint")
	variable ysetpoint = td_rv("ARC.PIDSLoop.1.Setpoint")
	variable new_xsetpoint
	variable new_ysetpoint
	
	SMUSetup(voltage=voltage)
	SMURead()
	
	Wave DataValues = root:packages:trEFM:ImageScan:DataValues
	print "Current = ", DataValues[1]
	variable current = DataValues[1]
	variable timestamp = DataValues[2]
	variable voltage_setting = DataValues[0]	

	FMapButtonFunc("DownFMap_2") 	// For simplicity we will always do Force Down		
	xsetpoint = td_rv("ARC.PIDSLoop.0.Setpoint")
	ysetpoint = td_rv("ARC.PIDSLoop.1.Setpoint")		
		
	do
		ysetpoint = td_rv("ARC.PIDSLoop.1.Setpoint")
		do
	 	xsetpoint = td_rv("ARC.PIDSLoop.0.Setpoint")
		
		SMURead()
		CurrentWave[r][c] = DataValues[1]
		TimeWave[r][c] = DataValues[2]
		
		new_xsetpoint = td_rv("ARC.PIDSLoop0.Setpoint")
		if (new_xsetpoint != xsetpoint)
			r += 1
		endif
		
		while (r < xpnts)
		
		new_ysetpoint = td_rv("ARC.PIDSLoop.1.Setpoint")
		if (new_ysetpoint != ysetpoint)
			c += 1
		endif
	while (c < ypnts)
	

end