#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function parabolaimaging()

	NVAR xpos = root:packages:trEFM:gxpos
	NVAR ypos = root:packages:trEFM:gypos
	NVAR scanpoints = root:packages:trEFM:ImageScan:scanpoints
	NVAR scanlines = root:packages:trEFM:ImageScan:scanlines
	NVAR width = root:packages:trEFM:ImageScan:scansizex
	NVAR height = root:packages:trEFM:ImageScan:scansizey
	
	SetDataFolder root:packages:trEFM:VoltageScan
	
	variable i = 0
	variable j = 0
	
	variable xsteps = width / scanpoints
	variable ysteps = height / scanlines
	
	make/O/N=(scanpoints) xstepswave = 0
	make/O/N=(scanpoints) ystepswave = 0
	setscale/i x, (xpos-width)/2, (xpos+width)/2, xstepswave
	xstepswave = x
	setscale/I x, (ypos-height)/2, (ypos+height)/2, ystepswave
	ystepswave = x

	Newpath/O path
	
	Wave phasewave = root:packages:trEFM:VoltageScan:phasewave
	Wave voltagewave = root:packages:trEFM:VoltageScan:voltagewave
	
	Save/C/O/P=path voltagewave as "Voltage_Wave.ibw"
	string name = "Parabola_0_0"
	
	do 
		i = 0
		do 
			xpos = xstepswave[i]
			ypos = ystepswave[j]
			DoUpdate
			MoveHereButton("")
			Sleep/S 1
			VoltageScanButton("")
			
			name = "Parabola_" + num2str(i) + "_" + num2str(j) + ".ibw"
			Save/C/O/P=path phasewave as name
			
			i += 1
		while (i < scanpoints)
		
		j += 1
	while ( j < scanlines)

end