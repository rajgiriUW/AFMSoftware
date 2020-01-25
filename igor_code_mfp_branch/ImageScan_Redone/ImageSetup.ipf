#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function MakePanels()
	Wave topography
	wave CHargingRate
	Wave FrequencyOffset
	
	NVAR ScanSizeY=root:packages:trEFM:ImageScan:scanSizeY
	NVAR ScanSizeX=root:packages:trEFM:ImageScan:scanSizeX
	
		dowindow/f ChargingRateImage
	if (V_flag==0)
		Display/K=1/n=ChargingRateImage;Appendimage ChargingRate
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan (um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(62000,65000,48600),expand=.7
		ColorScale/C/N=text0/E/F=0/A=MC image=ChargingRate
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "hz/V^2"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=ChargingRate
	endif
	
	ModifyGraph/W=ChargingRateImage height = {Aspect, scansizeY/scansizeX}		

	dowindow/f TopographyImage
	if (V_flag==0)
		Display/K=1/n=TopographyImage;Appendimage Topography
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan(um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(65000,60000,48600),expand=.7	
		ColorScale/C/N=text0/E/F=0/A=MC image=Topography
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "um"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=Topography
	endif	
	
	dowindow/f FrequencyShiftImage
	if (V_flag==0)
		Display/K=1/n=FrequencyShiftImage;Appendimage FrequencyOffset
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan (um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(65000,65000,48600),expand=.7
		ColorScale/C/N=text0/E/F=0/A=MC image=FrequencyOffset
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "Hz"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=FrequencyOffset
	endif
	
	ModifyGraph/W=TopographyImage height = {Aspect, scansizeY/scansizeX}
	ModifyGraph/W=FrequencyShiftImage height = {Aspect, scansizeY/scansizeX}

	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=TopographyImage height = {Aspect, 1}
		ModifyGraph/W=ChargingRateImage height = {Aspect, 1}
		ModifyGraph/W=FrequencyShiftImage height = {Aspect, 1}
	endif

end


Function SetUpFramework(xpos, ypos, scansizeX, scansizeY, scanlines, scanpoints, XFastEFM, YFastEFM)
	variable xpos, ypos, scansizeX, scansizeY, scanlines, scanpoints
	variable XFastEFM, YFastEFM

	Variable/G SlowScanDelta
	Variable/G FastscanDelta
	variable i,j,k,l
	
	Make/O/N = (scanlines, 4) ScanFramework

	// Set up scan Frameworks
	// 	ScanFramework[][0]: fastscan down (topo)
	//	ScanFramework[][1]: slowscan down (topo, only changes after each line)
	//	ScanFramework[][2]: fastscan up (efm)
	//	ScanFramework[][3]: slowscan up (efm, only changes after each line)
	// Note that images are confirmed correct on 6/20/2019 by Raj in both 0 deg and 90 deg, logic below is all valid
	// ScanSizeY is just the "width" in the panel, not physically the Y-scale (so for 90 degrees it's actually the X-size)
	
	// 0 degree
	if (XFastEFM == 1 && YFastEFM == 0) //x direction scan
		ScanFramework[][0] = xpos - scansizeX / 2 //gPSscansizeX= fast width
		ScanFramework[][2] = xpos + scansizeX / 2
		SlowScanDelta = scansizeY / (scanlines - 1)
		FastscanDelta = scansizeX / (scanpoints - 1)
	
		i=0
		do
			if(scanlines > 1)
				ScanFramework[i][1] = (ypos - scansizeY / 2) + SlowScanDelta*i
				ScanFramework[i][3] = (ypos - scansizeY / 2) + SlowScanDelta*i
			else
				ScanFramework[i][1] = ypos
				ScanFramework[i][3] = ypos
			endif
			i += 1
		while (i < scanlines)
		
//		if (UseLineNum == 1)
//			ScanFramework[][1] = (ypos - scansizeY / 2)  + SlowScanDelta*LineNum
//			ScanFramework[][3] = (ypos - scansizeY / 2)  + SlowScanDelta*LineNum
//		endif
	
	// 90 degree
	elseif  (XFastEFM == 0 && YFastEFM == 1) //y direction scan
		ScanFramework[][0] = ypos + scansizeX / 2 //gPSscansizeX= fast width
		ScanFramework[][2] = ypos - scansizeX / 2
		SlowScanDelta = scansizeY / (scanlines - 1)
		FastscanDelta = scansizeX / (scanpoints - 1)
		i=0
		do
			if(scanlines>1)
				ScanFramework[i][1] = (xpos - scansizeY / 2) + SlowScanDelta*i
				ScanFramework[i][3] = (xpos - scansizeY / 2) + SlowScanDelta*i
			else
				ScanFramework[i][1] = xpos
				ScanFramework[i][3] = xpos
			endif
			i += 1
		while (i < scanlines)
		
//		if (UseLineNum == 1)
//			ScanFramework[i][1] = (xpos - scansizeY / 2)  + SlowScanDelta*LineNum
//			ScanFramework[i][3] = (xpos - scansizeY / 2)  + SlowScanDelta*LineNum
//		endif
	
	endif //x or y direction scanning
	
	return ScanFramework

end


function SetUpImages(XFastEFM, YFastEFM, ScanFramework, xpos, ypos)

	variable XFastEFM, YFastEFM
	Wave ScanFramework
	variable xpos, ypos
	NVAR scanpoints=root:packages:trEFM:ImageScan:scanpoints
	NVAR scanlines=root:packages:trEFM:ImageScan:scanlines

	Make/O/N = (scanpoints, scanlines) Topography, ChargingRate, FrequencyOffset, Chi2Image
	Chi2Image=0

	// 0 degree
	if (XFastEFM == 1 && YFastEFM == 0)
	
		SetScale/I x, ScanFrameWork[0][0], ScanFramework[0][2], "um", Topography, FrequencyOffset, ChargingRate, Chi2Image
		if(scanlines==1)
			SetScale/I y, ypos, ypos, Topography, FrequencyOffset, ChargingRate, Chi2Image
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, FrequencyOffset, ChargingRate,Chi2Image
		endif
	
	// 90 degree
	elseif (XFastEFM == 0 && YFastEFM == 1)
	
		SetScale/I x, ScanFrameWork[0][2], ScanFramework[0][0], "um", Topography, FrequencyOffset, ChargingRate, Chi2Image
		if(scanlines==1)
			SetScale/I y, xpos, xpos, Topography, FrequencyOffset, ChargingRate, Chi2Image
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, FrequencyOffset, ChargingRate,Chi2Image
		endif
	
	endif

end


function SetUpXYUpDown(ScanFrameWork, FastScanDelta, XFastEFM, YFastEFM)
	Wave ScanFramework
	Variable FastScanDelta
	Variable XFastEFM, YFastEFM
	Variable XLVDTSens = GV("XLVDTSens")
	Variable XLVDToffset = GV("XLVDToffset")
	Variable YLVDTSens  = GV("YLVDTSens")
	Variable YLVDToffset = GV("YLVDToffset")
	Variable ZLVDTSens = GV("ZLVDTSens")
	NVAR scanpoints=root:packages:trEFM:ImageScan:scanpoints
	NVAR scanlines=root:packages:trEFM:ImageScan:scanlines
	Make/O/N = (scanpoints, scanlines, 4) XYupdownwave
	if (XFastEFM == 1 && YFastEFM == 0)	//x  scan direction
		XYupdownwave[][][0] = (ScanFrameWork[q][0] + FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][1] = (ScanFrameWork[q][2] - FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][2] = (ScanFrameWork[q][1]) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][3] = (ScanFrameWork[q][3]) / YLVDTsens / 10e5 + YLVDToffset
	elseif (XFastEFM == 0 && YFastEFM == 1)	
		XYupdownwave[][][2] = (ScanFrameWork[q][0] - FastScanDelta*p) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][3] = (ScanFrameWork[q][2] + FastScanDelta*p) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][0] = (ScanFrameWork[q][1]) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][1] = (ScanFrameWork[q][3]) / XLVDTsens / 10e5 + XLVDToffset
	endif

	return XYUpDownWave
end

Function MakeLightWaves(gentipwaveTemp, genlightwaveTemp, gentriggerwaveTemp, genDriveWaveTemp, fitcyclepoints, numavgsperpoint)
	wave gentipwaveTemp, genlightwaveTemp, gentriggerwaveTemp, genDriveWaveTemp
	variable FitCyclePoints
	variable numavgsperpoint
	
	Make/O/N = (Fitcyclepoints) voltagewave, lightwave, triggerwave, drivewave
	
	voltagewave = gentipwaveTemp
	lightwave = genlightwaveTemp
	triggerwave = gentriggerwaveTemp
	drivewave = genDriveWavetemp
	
	// Crude concatenation routine
	Duplicate/O lightwave, ffPSLightWave
	Duplicate/O voltagewave, ffPSVoltWave
	Duplicate/O triggerwave, ffPSTriggerWave
	Duplicate/O drivewave, ffPSDriveWave
	
	variable cycles = 0					
	if (numavgsperpoint > 1)
		do
			Concatenate/NP=0 {voltagewave} ,ffPSVoltWave
			Concatenate/NP=0 {lightwave}, ffPSLightWave
			Concatenate/NP=0 {triggerwave}, ffPSTriggerWave
			Concatenate/NP=0 {drivewave}, ffPSDriveWave
			cycles += 1
		while (cycles < numavgsperpoint)
		
		// overwrite the originals
		Duplicate/O ffPSLightWave, lightwave
		Duplicate/O ffPSVoltWave, voltagewave
		Duplicate/O ffPSTriggerWave, triggerwave
		Duplicate/O ffPSDriveWave, drivewave
	endif
end