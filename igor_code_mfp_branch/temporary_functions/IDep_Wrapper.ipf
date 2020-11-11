#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function IdepFF()

//	Make/O Currents = {200, 500, 300, 100, 700, 400, 50}
//	Make/O Voltages = {12.7, 14.4, 13.3, 11.9, 15.5, 13.8, 11.4}
	
	Make/O Currents = {200, 10}
	Make/O Voltages = {15.5, 10.5}


	variable i = 0
	string name = num2str(Currents[i])
	string base = "C:DATA:raj:20180216_BAPI_IDep"

	string/G subfolder = base + ":x" + num2str(i) + "_" + name
	string toponame = "Topography" 

	SetDataFolder root:packages:trEFM 
	
	pson()
	
	do
		SetDataFolder root:packages:trEFM 
		
		name = num2str(Currents[i])
		string/G subfolder = base + ":x" + num2str(i) + "_" + name
		
		GetMFPOffset("")
		Sleep/S 0.5
		GetCurrentPositionButton("")
		Sleep/S 0.5
		
		pssetting(Voltages[i], Currents[i]/1000)
		Sleep/S 0.5
		
		FFtrEFMImageScanButton("")
		
		toponame = "Topography_" + num2str(i)
		Wave Topography = root:packages:trEFM:ImageScan:FFtrEFM:Topography
		Save/C/O/P=path Topography as toponame
		
		i += 1

	while (i < numpnts(Currents))
	
	psoff()

end