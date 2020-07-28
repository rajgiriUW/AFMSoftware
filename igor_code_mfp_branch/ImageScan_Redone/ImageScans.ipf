



Function ErrorHandle(error)

	variable error
	Svar LockinString = root:Packages:trEFM:LockinString
	
	if (stringmatch("ARC.Lockin.0." , LockinString))
		print("pass")
//		error+= td_xsetoutwave(2, "Event.2", "ARC.PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)
	else
		print("pass")
//		error+= td_xsetoutwave(2, "Event.2", "Cypher.PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)
	endif
	
	return error
End

//*******************  AAAAAAAAAAAAAAAAA **************************************//
//*******  Initialize all global and local Variables that are shared for all experiments ********//

// check all sloth wave generator vars and ensure they are referenced here properly

Function ImageScan(xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, [numavgsperpoint, xoryscan, fitstarttime, fitstoptime, DigitizerAverages, DigitizerSamples, DigitizerPretrigger])

	Variable xpos, ypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, numavgsperpoint,xoryscan, fitstarttime, fitstoptime
	Variable DigitizerAverages, DigitizerSamples, DigitizerPretrigger
	SVAR Imagefunc = root:packages:trEFM:ImageFunctionString
	
//	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm"))
//		#pragma rtGlobals=1
//	elseif (stringmatch(imagefunc, "skpm"))
//		#pragma rtGlobals=3


	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm") || stringmatch(imagefunc, "gmode"))
		 Variable saveOption = 0
	
 		Prompt saveOption, "Do you want to save the raw frequency data for later use?"
 		DoPrompt ">>>",saveOption
 			if(V_flag==1)
 				GetCurrentPosition()
				abort			//Abort
			endif
		if(saveoption == 1)	
	 		NewPath Path
	 	endif
	endif
	SetDataFolder root:packages:trEFM
 	Svar LockinString


 	String savDF = GetDataFolder(1) // locate the current data folder
 	SetDataFolder root:Packages:trEFM:WaveGenerator
 	Wave gentipwaveTemp, gentriggerwaveTemp, genlightwaveTemp, genDriveWaveTemp
 	
	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "gmode"))

		Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
		Wave CSACQUISITIONCONFIG = root:packages:GageCS:CSACQUISITIONCONFIG
		Wave CSTRIGGERCONFIG = root:packages:GageCS:CSTRIGGERCONFIG
		NVAR OneOrTwoChannels = root:packages:trEFM:ImageScan:OneorTwoChannels
		
		SetDataFolder root:packages:trEFM:ImageScan
//		Nvar numavgsperpoint
		
		DigitizerAverages = scanpoints * numavgsperpoint
		
		CSACQUISITIONCONFIG[%SegmentCount] = DigitizerAverages
		CSACQUISITIONCONFIG[%SegmentSize] = DigitizerSamples
		CSACQUISITIONCONFIG[%Depth] = DigitizerPretrigger 
		CSACQUISITIONCONFIG[%TriggerHoldoff] =  DigitizerPretrigger 
		CSTRIGGERCONFIG[%Source] = -1 //External Trigger
		
		GageSet(-1)
		SetDataFolder root:Packages:trEFM:ImageScan:FFtrEFM

	elseif (stringmatch(imagefunc, "trefm"))

		SetDataFolder root:Packages:trEFM:ImageScan:trEFM

	elseif (stringmatch(imagefunc, "downefm"))
		
		SetDataFolder root:Packages:trEFM:ImageScan:trEFM
		NVAR LightOn = root:packages:trEFM:LightOn
		NVAR RingDownVoltage = root:packages:trEFM:RingDownVoltage
		
		Print "Light On is", LightOn
		
	elseif (stringmatch(imagefunc, "skpm" ))
		
//		Nvar numavgsperpoint
		SetDataFolder root:packages:trEFM:PointScan:SKPM
		variable/G freq_PGain
		variable/G freq_IGain 
		variable/G freq_DGain

		SetDataFolder root:Packages:trEFM:ImageScan:SKPM

	endif

	GetGlobals()  //getGlobals ensures all vars shared with asylum are current
	
	//global Variables	
	if ((scansizex / scansizey) != (scanpoints / scanlines))
		abort "X/Y scan size ratio and points/lines ratio don't match"
	endif
	
	NVAR calresfreq = root:packages:trEFM:VoltageScan:Calresfreq
	NVAR CalEngageFreq = root:packages:trEFM:VoltageScan:CalEngageFreq
	NVAR CalHardD = root:packages:trEFM:VoltageScan:CalHardD
	NVAR CalsoftD = root:packages:trEFM:VoltageScan:CalsoftD
	NVAR CalPhaseOffset = root:packages:trEFM:VoltageScan:CalPhaseOffset

	Variable FreqOffsetNorm = 500
	
	NVAR Setpoint =  root:Packages:trEFM:Setpoint
	NVAR ADCgain = root:Packages:trEFM:ADCgain
	NVAR PGain = root:Packages:trEFM:PGain
	NVAR IGain = root:Packages:trEFM:IGain
	NVAR SGain = root:Packages:trEFM:SGain
	NVAR ImagingFilterFreq = root:Packages:trEFM:ImagingFilterFreq

	NVAR XFastEFM = root:packages:trEFM:ImageScan:XFastEFM
	NVAR YFastEFM = root:packages:trEFM:ImageScan:YFastEFM
	NVAR UseLineNum = root:packages:trEFM:ImageScan:UseLineNum
	NVAR LineNum = root:packages:trEFM:ImageScan:LineNum

	NVAR OneOrTwoChannels = root:packages:trEFM:ImageScan:OneorTwoChannels

	if (stringmatch(imagefunc, "skpm"))
		// SKPM Variables.
		NVAR LockinTimeConstant = root:Packages:trEFM:PointScan:SKPM:LockinTimeConstant 
		NVAR LockinSensitivity = root:Packages:trEFM:PointScan:SKPM:LockinSensitivity
		NVAR ACFrequency= root:Packages:trEFM:PointScan:SKPM:ACFrequency
		NVAR ACVoltage = root:Packages:trEFM:PointScan:SKPM:ACVoltage
		NVAR TimePerPoint = root:Packages:trEFM:PointScan:SKPM:TimePerPoint

		// single line stuff
		NVAR UseLineNumforVoltage = root:packages:trEFM:PointScan:SKPM:UseLineNumforVoltage
		NVAR LineNumforVoltage = root:packages:trEFM:PointScan:SKPM:LineNumforVoltage
		NVAR VoltageatLine = root:packages:trEFM:PointScan:SKPM:VoltageatLine
		
		NVAR LineNumforVoltage2 = root:packages:trEFM:PointScan:SKPM:LineNumforVoltage2
		NVAR VoltageatLine2 = root:packages:trEFM:PointScan:SKPM:VoltageatLine2

		NVAR gWGDeviceAddress = root:packages:trEFM:gWGDeviceAddress
	endif
		

	Variable XLVDTSens = GV("XLVDTSens")
	Variable XLVDToffset = GV("XLVDToffset")
	Variable YLVDTSens  = GV("YLVDTSens")
	Variable YLVDToffset = GV("YLVDToffset")
	Variable ZLVDTSens = GV("ZLVDTSens")

	Nvar xigain, yigain, zigain
		
	WAVE EFMFilters=root:Packages:trEFM:EFMFilters

	//local Variables
	Variable V_FitError=0	
	if(!WaveExists(W_sigma))
		Make/O W_sigma
	else
		wave W_sigma
	endif

	Variable starttime,starttime2,starttime3
	Variable Downinterpolation, Upinterpolation
	Variable ReadWaveZmean
	Variable Interpolation = 1 // sample rate of DAQ banks
	Variable samplerate = 50000 / interpolation

	Variable PSlength
	Variable PStimeofscan
	Variable PSchunkpoints, PSchunkpointssmall
	Variable baseholder
	Variable InputChecker
	Variable multfactor //avgs per pt
	Variable cycles

	Variable TotalTime

	if (stringmatch(imagefunc, "trefm"))
		NVAR interpval = root:Packages:trEFM:interpVal
		totaltime = 16 * interpval
		samplerate = 50000 / interpval
	else
		totaltime = 16 
	endif
	
	//*******************  AAAAAAAAAAAAAAAAA **************************************//	
	
	ResetAll()	

	Downinterpolation = ceil((50000 * (scansizex / scanspeed) / scanpoints))      
	
	if (stringmatch(imagefunc, "trefm"))
		samplerate = 50000 / interpval
		PSlength = 800 // (samplerate) * 16e-3
	else
		PSlength = (samplerate/interpolation) * 16e-3
	endif

//	Downinterpolation = ceil(scansizeX / (scanspeed * scanpoints * .00001))     
	
	if (mod(PSlength,32)!=0)	
		PSlength= PSlength + (32 - mod(PSlength,32))
	endif
			
	Variable gheightscantime = (scanpoints * .00001 * downinterpolation) * 1.05
	Variable gPSscantime = (interpolation * .00001 * PSlength) * 1.05
	Variable scantime = (gheightscantime + gPSscantime)*scanlines			
	Variable gPSwavepoints = PSlength


	DoUpdate


	//******************  BBBBBBBBBBBBBBBBBB *******************************//
	//SETUP Scan Framework and populate scan waves 
	// Then initialize all other in and out waves
	//***********************************************************************
	
	Make/O/N = (scanlines, 4) ScanFramework

	if (stringmatch(imagefunc, "skpm"))
		Make/O/N=(scanlines) ScanTimes = Nan
	endif

	variable SlowScanDelta
	variable FastscanDelta
	variable i,j,k,l
	// Set up scan Frameworks
	// 	ScanFramework[][0]: fastscan down (topo)
	//	ScanFramework[][1]: slowscan down (topo, only changes after each line)
	//	ScanFramework[][2]: fastscan up (efm)
	//	ScanFramework[][3]: slowscan up (efm, only changes after each line)
	// Note that images are confirmed correct on 6/20/2019 by Raj in both 0 deg and 90 deg, logic below is all valid
	// ScanSizeY is just the "width" in the panel, not physically the Y-scale (so for 90 degrees it's actually the X-size)
	
	// 0 degree
	if ( XorYscan == 0)  //x direction scan
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
	elseif  ( XorYscan == 1)  //y direction scan
		
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

	// INITIALIZE in and out waves
	//downinterpolation, scanspeeds will need to be adjusted to account for multiple cycles per point on the retrace
	// should leave downinterpolation, psvoltsloth, pslightsloth as they are and create new variables that are only used for the high speed
	//trEFM experiment that uses the existing vars and waves as a template	
	
	//Downinterpolation = ceil(scansizeX / (scanspeed * scanpoints * .00001))
	
	Make/O/N = (scanpoints, scanlines) Topography, ChargingRate, FrequencyOffset, Chi2Image, CPDImage
	Chi2Image=0
	
	if ( (XFastEFM == 1 && YFastEFM == 0) )
	
		SetScale/I x, ScanFrameWork[0][0], ScanFramework[0][2], "um", Topography, FrequencyOffset, ChargingRate, Chi2Image
		SetScale/I x, ScanFrameWork[0][0], ScanFramework[0][2], "um", Topography, CPDImage
		if(scanlines==1)
			SetScale/I y, ypos, ypos, Topography, FrequencyOffset, ChargingRate, Chi2Image
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, FrequencyOffset, ChargingRate,Chi2Image
		endif

	elseif (XFastEFM == 0 && YFastEFM == 1)

		SetScale/I x, ScanFrameWork[0][2], ScanFramework[0][0], "um", Topography, FrequencyOffset, ChargingRate, Chi2Image
		SetScale/I x, ScanFrameWork[0][2], ScanFramework[0][0], "um", Topography, CPDImage
		if(scanlines==1)
			SetScale/I y, xpos, xpos, Topography, FrequencyOffset, ChargingRate, Chi2Image
		else
			SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], Topography, FrequencyOffset, ChargingRate,Chi2Image
		endif

	endif	

	if(mod(scanpoints,32) != 0)									
		abort "Scan Points must be divisible by 32"
	endif
	
	Make/O/N = (scanpoints) ReadWaveZ, ReadWaveZback, Xdownwave, Ydownwave, Xupwave, Yupwave
	Make/O/N = (scanpoints, scanlines, 4) XYupdownwave
	ReadWaveZ = NaN

	//******************  BBBBBBBBBBBBBBBBBB *******************************//


	//******************  CCCCCCCCCCCCCCCCCC *******************************//
	//POPULATE Data/Drive waves by experiment, these settings should not change
	// from jump to jump, cycle to cycle, or between the trace and retrace
	// vars that do change are initialized below
	//***********************************************************************
	if (!stringmatch(imagefunc, "skpm"))
								
		if (numavgsperpoint == 0)	// accidental 0 avg case
			numavgsperpoint = 1
		endif
		print "Number of Averages per point:",numavgsperpoint

		totaltime = (totaltime * 1e-3) * (samplerate) 					//puts totaltime (16 ms) into point space (800)
		fitstarttime = round((fitstarttime * 1e-3) * (samplerate))
		fitstoptime = round((fitstoptime * 1e-3) * (samplerate))

		Variable Fitcyclepoints = totaltime 
		
		Make/O/N = (Fitcyclepoints) voltagewave, lightwave, triggerwave, drivewave
		
		voltagewave = gentipwaveTemp
		lightwave = genlightwaveTemp
		triggerwave = gentriggerwaveTemp
		drivewave = genDrivewaveTemp

		PSchunkpointssmall = (fitstoptime - fitstarttime)
		Make/O/N = (PSchunkpointssmall) CycleTime, ReadWaveFreqtemp	

		Variable cyclepoints = Fitcyclepoints
		cyclepoints *= numavgsperpoint	// Number of points per line	


		// this section creates the voltage and light waves, duplicates them and concatenates the results to a new ffPS wave		
		// Crude concatenation routine
		Duplicate/O lightwave, ffPSLightWave
		Duplicate/O voltagewave, ffPSVoltWave
		Duplicate/O triggerwave, ffPSTriggerWave
		Duplicate/O driveWave, ffPSDriveWave
		
		cycles = 0					//Changed to cycles = 0 from 1 because it would skip entry 1 and only do (numavgsperpoint - 1) PCMG 4/29/14
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

		k = 0
		do
			CycleTime[k]=k * (1/samplerate) * interpolation
			k += 1

		while (k < PSchunkpointssmall)
		
		variable starttimepoint = fitstarttime
		variable stoptimepoint = fitstoptime

		PSlength = scanpoints * cyclepoints
		PStimeofscan = (scanpoints * cyclepoints) / (samplerate) // time per line
		Upinterpolation = (PStimeofscan * samplerate) / (scanpoints)
	

	else //skpm
		GPIBsetup()
	
		Variable lockinsens=GetLockinSens()
		
		SetLockinTimeC(LockinTimeConstant/1000) //the user specifies the Lockin time constant, and this call sets it, making sure 
		
		if (stringmatch(imagefunc, "skpm"))
			setLPslope(2) // 0 is 6dB, 1 is 12dB, 2 is 18dB, and 3 is 24 dB
			
			setSync(0) // 0 is off and 1 is on
			
			setFloat0orGround1(1) //0 is float and 1 is ground
			
			setNotch(0) //0 is neither, 1 is 60hz, 2 is 120hz, and 3 is both
			
			setReserve(0) //0 is high, 1 is normal, 2 is low
		elseif (stringmatch(imagefunc, "skpmspv"))
			setLPslope(3) // 0 is 6dB, 1 is 12dB, 2 is 18dB, and 3 is 24 dB
			setSync(1) // 0 is off and 1 is on
			setFloat0orGround1(0) //0 is float and 1 is ground
			setNotch(3) //0 is neither, 1 is 60hz, 2 is 120hz, and 3 is both
			setReserve(1) //0 is high, 1 is normal, 2 is low
		endif
			
		setChanneliOutputtoj(1,1) //output x on channel 1
		setChanneliDisplayj(1, 0) //display x on channel 1
		//setLockinPhase(-9) //this phase is selected for a frequency of 1000 hz
		setLockinPhase(-100)
		setLockinSensitivity(LockinSensitivity) // 17 sets the sensitivity of the lockin to 1mv/na //20 is a good value
		sendLockinString("FMOD0") //sets source to external 

		if (gWGDeviceAddress != 0 || stringmatch(imagefunc, "skpmspv"))
			Setvf(0, ACFrequency,"WG")
		else
			TurnOffAWG()
		
		endif
		
		if (stringmatch(imagefunc, "skpm"))
			Make/O/N=(scanpoints) CPDTrace, CPDTraceBefore
		elseif (stringmatch(imagefunc, "skpmspv"))
			Make/O/N=(scanpoints) CPDTrace, CPDTraceBefore, CPDTrace2
		endif

		Variable pointsPerPixel = timeperpoint * samplerate * 1e-3
		Variable pointsPerLine = pointsPerPixel * scanpoints
		make/o/n=(pointsPerPixel) CPDWaveTemp
		
		variable lastvoltage, lk, ll
		make/o/n=(pointsPerPixel) CPDWaveLastPoint
		
		Variable timeofscan = timeperpoint * 1e-3 * scanpoints
		Upinterpolation = (timeofscan * samplerate) / (scanpoints)
		print timeofscan, upinterpolation, lockintimeConstant, lockinsensitivity
	endif
	

	//******************  CCCCCCCCCCCCCCCCCC *******************************//

	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc,  "gmode"))
		Make/O/N =(scanpoints) tfp_wave, shift_wave
		Make/O/N = (DigitizerSamples, DigitizerAverages) data_wave
		Make/O/N = (scanpoints, scanlines) tfp_array, shift_array,rate_array
	endif


	
	//******************  DDDDDDDDDDDDDDDDDDD *******************************//	
	//***************** Open the scan panels ***********************************//
	
			// trefm charge creation/delay/ff-trEFM

	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc,  "trefm") || stringmatch(imagefunc, "gmode"))
		dowindow/f ChargingRateImage
	elseif (stringmatch(imagefunc, "downefm"))
		dowindow/f RingDownRateImage
	elseif (stringmatch(imagefunc, "skpm"))
		dowindow/f CPD
	endif

	if (V_flag==0)
		if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "gmode"))
			Display/K=1/n=ChargingRateImage;Appendimage ChargingRate
		elseif (stringmatch(imagefunc, "downefm"))
			Display/K=1/n=RingDownRateImage;Appendimage ChargingRate
		elseif (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
			Display/K=1/n=CPD;Appendimage CPDImage
		endif

		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan (um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(62000,65000,48600),expand=.7
		if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "gmode"))
			ModifyImage ChargingRate ctab= {0,20000,VioletOrangeYellow,0}
		endif
		if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm") || stringmatch(imagefunc, "gmode"))
			ColorScale/C/N=text0/E/F=0/A=MC image=ChargingRate
			ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "hz/V^2"
			ColorScale/C/N=text0/X=5.00/Y=5.00/E image=ChargingRate
		elseif (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
			ColorScale/C/N=text0/E/F=0/A=MC image=CPDImage
			ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "V"
			ColorScale/C/N=text0/X=5.00/Y=5.00/E image=CPDImage
		endif

		if (stringmatch(imagefunc, "skpmspv"))
			ModifyImage CPDImage ctab= {*,*,Mocha,0}
		endif
	endif
	
	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "gmode"))
		ModifyGraph/W=ChargingRateImage height = {Aspect, scansizeY/scansizeX}
	elseif (stringmatch(imagefunc, "downefm"))
		ModifyGraph/W=RingDownRateImage height = {Aspect, scansizeY/scansizeX}
	elseif (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
		ModifyGraph/W=CPD height = {Aspect, scansizeY/scansizeX}
	endif

	if (stringmatch(imagefunc, "skpmspv"))
		dowindow/f CPD2
		if (V_flag==0)
			Display/K=1/n=CPD2;Appendimage CPDImage2
			SetAxis/A bottom
			SetAxis/A left
			Label bottom "Fast Scan (um)"
			Label left "Slow Scan (um)"
			ModifyGraph wbRGB=(62000,65000,48600),expand=.7
			ColorScale/C/N=text0/E/F=0/A=MC image=CPDImage2
			ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "V"
			ColorScale/C/N=text0/X=5.00/Y=5.00/E image=CPDImage2
			ModifyImage CPDImage2 ctab= {*,*,Mocha,0}
		endif
		ModifyGraph/W=CPD height = {Aspect, scansizeY/scansizeX}		

		dowindow/f CPDdifference
		if (V_flag==0)
			Display/K=1/n=CPDdifference;Appendimage CPDdiff
			SetAxis/A bottom
			SetAxis/A left
			Label bottom "Fast Scan (um)"
			Label left "Slow Scan (um)"
			ModifyGraph wbRGB=(62000,65000,48600),expand=.7
			ColorScale/C/N=text0/E/F=0/A=MC image=CPDdiff
			ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "V"
			ColorScale/C/N=text0/X=5.00/Y=5.00/E image=CPDdiff
			ModifyImage CPDdiff ctab= {*,*,Mocha,0}
		endif
		ModifyGraph/W=CPD height = {Aspect, scansizeY/scansizeX}
	endif	


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
	
	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "gmode"))
		dowindow/f FrequencyOffsetImage
	elseif (stringmatch(imagefunc, "trefm") || stringmatch(imagefunc , "downefm"))
		dowindow/f FrequencyShiftImage
	elseif (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
		ModifyGraph/W=TopgraphyImage height = {Aspect, scansizeY/scansizeX}
		ModifyGraph/W=CPD height = {Aspect, scansizeY/scansizeX}
		dowindow/f CPDTraceWindow
		if (stringmatch(imagefunc, "skpmspv"))
			ModifyGraph/W=CPD2 height = {Aspect, scansizeY/scansizeX}
			ModifyGraph/W=CPDdifference height = {Aspect, scansizeY/scansizeX}
			dowindow/f CPDTraceWindow
		endif
	endif

	if (V_flag==0)
		if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "gmode"))
			Display/K=1/n=FrequencyOffsetImage;Appendimage FrequencyOffset
		elseif (stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm"))
			Display/K=1/n=FrequencyShiftImage;Appendimage FrequencyOffset
		elseif (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
			Display/K=1/n=CPDTraceWindow CPDTrace appendtograph CPDTraceBefore
			ModifyGraph rgb(CPDTraceBefore)=(0,0,0)
		endif

		if (stringmatch(imagefunc, "skpmspv"))
			dowindow/f CPDTraceWindow12
			if (V_flag==0)
				Display/K=1/n=CPDTraceWindow12 CPDTrace
				appendtograph CPDTrace2
				ModifyGraph rgb(CPDTrace2)=(0,0,0)
			endif
		endif

		if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "gmode") || stringmatch(imagefunc, "downefm"))
			SetAxis/A bottom
			SetAxis/A left
			Label bottom "Fast Scan (um)"
			Label left "Slow Scan (um)"
			ModifyGraph wbRGB=(65000,65000,48600),expand=.7
			if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "gmode"))
				ModifyImage FrequencyOffset ctab= {-100,0,YellowHot, 0}
			endif
			ColorScale/C/N=text0/E/F=0/A=MC image=FrequencyOffset
			ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "Hz"
			ColorScale/C/N=text0/X=5.00/Y=5.00/E image=FrequencyOffset
		endif
	endif
	
	ModifyGraph/W=TopographyImage height = {Aspect, scansizeY/scansizeX}

	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "gmode"))
		ModifyGraph/W=FrequencyOffsetImage height = {Aspect, scansizeY/scansizeX}
	elseif (stringmatch(imagefunc, "trefm") || stringmatch(imagefunc , "downefm"))
		ModifyGraph/W=FrequencyShiftImage height = {Aspect, scansizeY/scansizeX}
	endif

	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=TopographyImage height = {Aspect, 1}

		if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "gmode"))
			ModifyGraph/W=ChargingRateImage height = {Aspect, 1}
		elseif (stringmatch(imagefunc, "downefm"))
			ModifyGraph/W=RingDownRateImage height = {Aspect, 1}
		endif

		if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "gmode"))
			ModifyGraph/W=FrequencyOffsetImage height = {Aspect, 1}
		elseif (stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm"))
			ModifyGraph/W=FrequencyShiftImage height = {Aspect, 1}
		endif

		if (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc , "skpmspv"))
			ModifyGraph/W=CPDImage height = {Aspect, 1}
			if (stringmatch(imagefunc, "skpmspv"))
				ModifyGraph/W=CPDImage2 height = {Aspect, 1}
			endif	

		endif
	endif

	//**************** End scan panel setup  ***************//
	//******************  DDDDDDDDDDDDDDDDDDD *******************************//

	//Set inwaves with proper length and instantiate to Nan so that inwave timing works
	Make/O/N = (PSlength) ReadwaveFreq, ReadWaveFreqLast
	Make/O/N = (pointsPerLine) CPDWave, CPDWaveLast
	ReadwaveFreq = NaN

	//******************  EEEEEEEEEEEEEEEEEEE *******************************//	
	//******************** SETUP all hardware, FBL, XPT and external hdwe settings that are common
	//*******************  to both the trace and retrace **************
	
	// crosspoint needs to be updated to send the trigger to the gage card	
	// Set up the crosspoint, note that KP crosspoint settings change between the trace and retrace and are reset below

	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "gmode"))
		SetCrosspoint ("FilterOut","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","OutB","DDS")
	elseif (stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm"))
		SetCrosspoint ("FilterOut","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Defl","OutC","OutA","OutB","Ground","OutB","DDS")
	elseif (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
		SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","In0","DDS")
	endif
	
	//stop all FBLoops except for the XY loops
	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
	
	variable error = 0
	td_StopInWaveBank(-1)
		
	// HStrEFM needs no FBL on the LIA phase angle	

	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm") || stringmatch(imagefunc, "gmode"))
		SetPassFilter(1,q=EFMFilters[%EFM][%q],i=EFMFilters[%EFM][%i],a=EFMFilters[%EFM][%A],b=EFMFilters[%EFM][%B])
	elseif (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
		SetPassFilter(1,q=EFMFilters[%KP][%q],i=EFMFilters[%KP][%i],a=EFMFilters[%KP][%A],b=EFMFilters[%KP][%B])
		SetFeedbackLoop(5, "Always", LockinString+"theta", td_rv(LockinString+"theta"), freq_PGain, freq_IGain, freq_DGain, "Output.A", 0)
		SetFeedbackLoop(4, "Always", "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], 0, "Output.B", 0)	
		SetFeedbackLoop(3, "Always",  "ZSensor", ReadWaveZ[scanpoints-1] - liftheight * 1e-9 / GV("ZLVDTSens"), 0, EFMFilters[%ZHeight][%IGain],0, "Output.Z",0)
		
		//stop all FBLoops again now that they have been initialized
		StopFeedbackLoop(3)
		StopFeedbackLoop(4)
		StopFeedbackLoop(5)
	endif

	if (stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm"))
		if (stringmatch("ARC.Lockin.0." , LockinString))
			SetFeedbackLoop(4, "always", LockinString +"theta", NaN, EFMFilters[%trEFM][%PGain], EFMFilters[%trEFM][%IGain], 0, LockinString+"FreqOffset",  EFMFilters[%trEFM][%DGain])
		else
			SetFeedbackLoopCypher(1, "always", LockinString +"theta", NaN, EFMFilters[%trEFM][%PGain], EFMFilters[%trEFM][%IGain], 0, LockinString+"FreqOffset",  EFMFilters[%trEFM][%DGain])
		endif
		SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0)
	endif


	// Set all DAC outputs to zero initially
	td_wv("Output.A", 0)
	td_wv("Output.B",0)	

	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "gmode") || stringmatch(imagefunc, "skpmspv"))
		td_wv("Output.C",0)
	endif
	//******************  EEEEEEEEEEEEEEEEEEE *******************************//	
	
	//******************  FFFFFFFFFFFFFFFFFFFFFF *******************************//
	//pre-loop initialization, done only once
	if (stringmatch(imagefunc, "trefm"))
		NVAR gxpos= root:packages:trEFM:gxpos
		NVAR gypos = root:packages:trEFM:gypos
	endif

	//move to initial scan point
	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "gmode"))
		if (XFastEFM == 1 && YFastEFM == 0)	
			if (UseLineNum == 0)
				MoveXY(ScanFramework[0][0], ScanFramework[0][1])
			else
				MoveXY(ScanFramework[0][0], (ypos - scansizeY / 2)  + SlowScanDelta*LineNum)
			endif
		elseif (XFastEFM == 0 && YFastEFM == 1)
			if (UseLineNum == 0)
				MoveXY(ScanFramework[0][1], ScanFramework[0][0])
			else
				MoveXY((xpos - scansizeY / 2)  + SlowScanDelta*LineNum, ScanFramework[0][0])
			endif
		endif
	elseif (stringmatch(imagefunc, "downefm"))
		if (xoryscan == 0)	
			MoveXY(ScanFramework[0][0], ScanFramework[0][1])
		elseif (XorYscan == 1)
			MoveXY(ScanFramework[0][1], ScanFramework[0][0])
		endif
	elseif (stringmatch(imagefunc, "skpmspv"))
		MoveXY(ScanFramework[0][0], ScanFramework[0][1])

	endif



	
	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "gmode"))
		SetCrosspoint ("FilterOut","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","OutB","DDS")
	elseif (stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm"))
		SetCrosspoint ("FilterOut","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Defl","OutC","OutA","OutB","Ground","OutB","DDS")
	endif
	
	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm") || stringmatch(imagefunc, "gmode"))
		variable currentX = td_ReadValue("XSensor")
		variable currentY = td_ReadValue("YSensor")
	endif

	//************************************* XYupdownwave is the final, calculated, scaled values to drive the XY piezos ************************//	
	if ( (stringmatch(imagefunc, "skpmspv")) || (stringmatch(imagefunc, "downefm") && xoryscan == 0) || (XFastEFM == 1 && YFastEFM == 0) )	//x  scan direction
		XYupdownwave[][][0] = (ScanFrameWork[q][0] + FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][1] = (ScanFrameWork[q][2] - FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][2] = (ScanFrameWork[q][1]) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][3] = (ScanFrameWork[q][3]) / YLVDTsens / 10e5 + YLVDToffset
	elseif ( (stringmatch(imagefunc, "downefm") && xoryscan == 1) || (XFastEFM == 0 && YFastEFM == 1) )
		XYupdownwave[][][2] = (ScanFrameWork[q][0] - FastScanDelta*p) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][3] = (ScanFrameWork[q][2] + FastScanDelta*p) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][0] = (ScanFrameWork[q][1]) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][1] = (ScanFrameWork[q][3]) / XLVDTsens / 10e5 + XLVDToffset
	endif

	if (stringmatch(imagefunc, "trefm"))
		print (XYupdownwave[0][LineNum][0] - XLVDTOffset) * 10e5 * XLVDTSens
	endif
	
	//Set up the tapping mode feedback
	td_wv(LockinString + "Amp",CalHardD) 
	td_wv(LockinString + "Freq",CalEngageFreq) //set the frequency to the resonant frequency

	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "gmode"))
		td_wv(LockinString + "FreqOffset",0)
	endif
	
	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "gmode") || stringmatch(imagefunc, "skpmspv"))
		SetFeedbackLoop(2,"Always","Amplitude", Setpoint,-PGain,-IGain,-SGain,"Height",0)
	elseif (stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm"))
		SetFeedbackLoop(2,"Always","Amplitude", Setpoint,-PGain,-IGain,-SGain,"Output.Z",0)
	endif
	
	Sleep/S 1.5
	
	//******************  FFFFFFFFFFFFFFFFFFFFFF *******************************//
	//*********************************************************************//


	//*********************************************************************//
	///Starting imaging loop here
	i=0

	if (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
		variable heightbefore, heightafter
	endif
	
	if (stringmatch(imagefunc, "skpmspv"))
		j = 0
	endif

	do
		starttime2 =StopMSTimer(-2) //Start timing the raised scan line

		if (!stringmatch(imagefunc, "skpmspv") || (stringmatch(imagefunc, "skpmspv") && j == 0))
			print "line ", i+1
		endif
		if (stringmatch(imagefunc, "skpmspv") && j == 0)
			print "Light off"
			td_wv("Output.C", 0)
		elseif (stringmatch(imagefunc, "skpmspv") && j==1)
			print "Light on"
			td_wv("Output.C", 5)
			Sleep/S .25
		endif

		if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "skpm"))
			if (UseLineNum == 0)	// single line scans
				LineNum = i
			endif
		endif
		
		if (stringmatch(imagefunc, "skpm"))
			if (UseLineNumForVoltage != 0)
				if (i == LineNumforVoltage)
					PsSetting(VoltageatLine, current=0.7)
				endif
				
				if (i == LineNumforVoltage2)
					PsSetting(VoltageatLine2, current=0.7)
				endif
			endif
		endif

		// these are the actual 1D drive waves for the tip movement
		if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "skpm"))
			Xdownwave[] = XYupdownwave[p][LineNum][0]
			Xupwave[] = XYupdownwave[p][LineNum][1]
			Ydownwave[] = XYupdownwave[p][LineNum][2]
			Yupwave[] = XYupdownwave[p][LineNum][3]
		elseif (stringmatch(imagefunc, "downefm") || stringmatch(imagefunc, "gmode") || stringmatch(imagefunc, "skpmspv"))
			Xdownwave[] = XYupdownwave[p][i][0]
			Xupwave[] = XYupdownwave[p][i][1]
			Ydownwave[] = XYupdownwave[p][i][2]
			Yupwave[] = XYupdownwave[p][i][3]
		endif
	
		//****************************************************************************
		//*** SET TRACE VALUES HERE
		//*****************************************************************************
		td_StopInWaveBank(-1)
		td_StopOutWaveBank(-1)
		
		if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm"))
			error+= td_xSetInWave(0,"Event.0", "ZSensor", ReadWaveZ,"", Downinterpolation)// used during Trace to record height data		
				if (error != 0)
					print i, "error1", error
				endif


			if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "gmode"))
				error+= td_xSetOutWavePair(0,"Event.0", "PIDSLoop.0.Setpoint", Xdownwave,"PIDSLoop.1.Setpoint",Ydownwave ,-DownInterpolation)
			elseif (stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm"))
				error+= td_xSetOutWavePair(0,"Event.0", "$outputXLoop.Setpoint", Xdownwave,"$outputYLoop.Setpoint",Ydownwave ,-DownInterpolation)
			endif
			if (error != 0)
				print i, "error2", error
			endif
		endif

		if (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
			td_xSetInWave(0,"Event.0", "ZSensor", ReadWaveZ,"", Downinterpolation)	
			
			td_xSetOutWavePair(0, "Event.0", "PIDSLoop.0.Setpoint", Xdownwave, "PIDSLoop.1.Setpoint", Ydownwave , -DownInterpolation)

			SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","Ground","DDS")
		endif


		SetPassFilter(1,q = ImagingFilterFreq, i = ImagingFilterFreq)
		

		td_wv(LockinString + "Amp",CalHardD) 
		td_wv(LockinString + "Freq",CalEngageFreq) //set the frequency to the resonant frequency
		td_wv(LockinString + "FreqOffset",0)

		if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "gmode") || stringmatch(imagefunc, "skpmspv"))
			td_wv("Output.A",0)
			td_wv("Output.B",0)
			if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "gmode"))
				td_wv("Output.C",0)
			endif
		endif

		if (stringmatch(imagefunc, "skpm"))
			if (gWGDeviceAddress != 0)
				setvf(0, ACFrequency,"WG")
			else
				TurnOffAWG()
			endif
		elseif (stringmatch(imagefunc, "skpmspv"))
			setvf(0, ACFrequency,"WG")
		endif

		error+= td_WriteString("Event.0", "Once")
			if (error != 0)
				print i, "error3", error
			endif
		
		starttime3 =StopMSTimer(-2) //Start timing the raised scan line

		CheckInWaveTiming(ReadWaveZ) // Waits until the topography trace has been fully collected.
		
		Sleep/S .05
		//*********** End of the 1st scan pass
		
		//ReadWaveZback is the drive wave for the z piezo		
		ReadWaveZback[] = ReadwaveZ[scanpoints-1-p] - liftheight * 1e-9 / GV("ZLVDTSens")
		ReadWaveZmean = Mean(ReadwaveZ) * ZLVDTSens
		Topography[][i] = -(ReadwaveZ[p] * ZLVDTSens-ReadWaveZmean)
		DoUpdate
	
		//****************************************************************************
		//*** SET DATA COLLECTION STUFF.
		//*****************************************************************************		
		td_stopInWaveBank(-1)
		td_stopOutWaveBank(-1)

		if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "gmode"))

			// START TOPOGRAPHY SCAN
			// Outputs three signals from the ARC. If CutDrive is active, then "trigger" is replaced by the drive signal to the shake pieze
			//	Otherwise, the outputs are:
			//	BNC0 : triggerwave
			//	BNC1: light wave
			//	BNC2: voltage wave
			//	BNC1 needs to connect to the light box. It can ALSO connect to the trigger box. Or, if CutDrive is off, BNC0 could connect to it
			//
			// IMPORTANT: You CANNOT use cutdrive and triggerwave at the same time.
		
			NVAR Cutdrive = root:packages:trEFM:cutDrive

			//stop amplitude FBLoop and start height FB for retrace
			StopFeedbackLoop(2)		

			// to keep tip from being stuck, raises 100 nm first
			SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-100*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
			sleep/S 1
			SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
			sleep/s 1

			if (stringmatch(imagefunc, "gmode"))
				//		SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","DDS","Ground")	
				SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","DDS","OutA","OutB","Ground","DDS","Ground")	

				variable EAmp = GV("NapDriveAmplitude")
				variable EFreq = GV("NapDriveFrequency")
				variable EOffset = GV("NapTipVoltage")
				variable EPhase = GV("NapPhaseOffset")

				td_WriteValue("DDSAmplitude0",EAmp)	
				td_WriteValue("DDSFrequency0",EFreq)	
				td_WriteValue("DDSDCOffset0",EOffset)	
				td_WriteValue("DDSPhaseOffset0",EPhase)
			endif


			error+= td_xsetoutwavepair(0,"Event.2,repeat", "Output.A", lightwave,"Output.B", voltagewave,-1)

			if (stringmatch(imagefunc, "gmode") || CutDrive == 0)
	//			error += td_xsetoutwave(1,"Event.2,repeat", "Output.C", triggerwave, -1)
				error+= td_xsetoutwavePair(1,"Event.2", "$outputXLoop.Setpoint", Xupwave,"$outputYLoop.Setpoint", Yupwave,-UpInterpolation)
				
				error = ErrorHandle(error)
			elseif (!stringmatch(imagefunc, "gmode") || CutDrive == 1)
				error += td_xsetoutWave(1, "Event.2,repeat", LockinString + "Amp",drivewave, -1)
				variable YIGainBack = td_rv("ARC.PIDSLoop.1.IGain")
				variable XIGainBack = td_rv("ARC.PIDSLoop.0.IGain")
	//			error += SetFeedbackLoop(1, "Event.2", "YSensor", Yupwave[0], 0, YIGainBack, 0, "Output.Y", 0)	
	//			error += SetFeedbackLoop(1, "Always", "YSensor", Yupwave[0], 0, YIGainBack, 0, "Output.Y", 0)	
				if (XFastEFM == 1 && YFastEFM == 0)
					error += td_wv("PIDSLoop.1.Setpoint", Yupwave[0])
					error+= td_xsetoutwavePair(2,"Event.2", "ARC.PIDSLoop.0.Setpoint", Xupwave,"ARC.PIDSLoop.3.Setpoint", ReadWaveZback,-UpInterpolation)	
				else
					error += td_wv("PIDSLoop.0.Setpoint", Yupwave[0])
					error+= td_xsetoutwavePair(2,"Event.2", "ARC.PIDSLoop.1.Setpoint", Xupwave,"ARC.PIDSLoop.3.Setpoint", ReadWaveZback,-UpInterpolation)	
				endif
				if (error != 0)
					print "error", error
				endif
		
			endif

			// If not using the new trigger box with invertable output, uncomment these lines and comment the subsequent 2 setoutwave(pair) lines
	//		error+= td_xsetoutwavePair(2,"Event.2", "ARC.PIDSLoop.0.Setpoint", Xupwave,"ARC.PIDSLoop.3.Setpoint", ReadWaveZback,-UpInterpolation)	
	//		variable YIGainBack = td_rv("ARC.PIDSLoop.1.IGain")
	//		SetFeedbackLoop(1, "Event.2", "Ysensor", Yupwave[0], 0, YIGainBack, 0, "Output.Y", 0)		//	hard-set Y position each line to free up an outwavebank
			
			if (stringmatch(imagefunc, "gmode"))
				error+= td_xsetoutwavePair(1,"Event.2", "$outputXLoop.Setpoint", Xupwave,"$outputYLoop.Setpoint", Yupwave,-UpInterpolation)
				error = ErrorHandle(error)
			endif

	//		error+= td_xsetoutwave(2, "Event.2", LockInString + "PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)


			if (!stringmatch(imagefunc, "gmode"))
				td_wv(LockinString + "Amp", CalSoftD) 
				td_wv(LockinString + "Freq", CalResFreq) //set the frequency to the resonant frequency	
				td_wv(LockinString + "FreqOffset", 0)

				
			//		SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","OutB","DDS")
				
				SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","DDS","OutA","OutB","Ground","OutB","DDS")
			endif

			SetPassFilter(1, q = EFMFilters[%trEFM][%q], i = EFMFilters[%trEFM][%i])

			GageAcquire()
			
			//Fire retrace event here
			error += td_WriteString("Event.2", "Once")
			GageWait(600) // Wait until data collection has finished.
			
			td_stopInWaveBank(-1)
			td_stopOutWaveBank(-1)
			
			td_writevalue("Output.A", 0)
			td_writevalue("Output.B", 0)
			td_writevalue("Output.C", 0)
			
			GageTransfer(1, data_wave)
			
			if (OneOrTwoChannels == 1)
				GageTransfer(2, ch2_wave)
			endif
			
			AnalyzeLineOffline(PIXELCONFIG, scanpoints, shift_wave, tfp_wave, data_wave)

			// ************  End of Retrace 		

			// Optional Save Raw Data

			if(saveOption == 1)
				string name
				if (i < 10)		
					name = "FFtrEFM_000" + num2str(i) + ".ibw"
				elseif (i < 100)
					name = "FFtrEFM_00" + num2str(i) + ".ibw"
				else
					name = "FFtrEFM_0" + num2str(i) + ".ibw"
				endif

				Save/C/O/P = Path data_wave as name
				
				if (OneOrTwoChannels == 1)
				
					if (i < 10)		
						name = "CH2_000" + num2str(i) + ".ibw"
					elseif (i < 100)
						name = "CH2_00" + num2str(i) + ".ibw"
					else
						name = "CH2_0" + num2str(i) + ".ibw"
					endif

					Save/C/O/P = Path ch2_wave as name
					
				endif
			endif
			//**********************************************************************************
			//***  PROCESS DATA AND UPDATE GRAPHS
			//*******************************************************************************
			FrequencyOffset[][i] = shift_wave[p]
			tfp_array[][i] = tfp_wave[p]
			ChargingRate[][i] = 1 / tfp_wave[p]

			variable counter
			for(counter = 0; counter < scanpoints;counter+=1)
				FrequencyOffset[counter][i] = shift_wave[scanpoints - counter - 1]
				tfp_array[counter][i] = tfp_wave[scanpoints-counter-1]
				ChargingRate[counter][i] = 1 / tfp_wave[scanpoints-counter-1]
			endfor
			//**********************************************************************************
			//***  END OF PROCESS DATA AND UPDATE GRAPHS
			//*******************************************************************************		


		elseif (stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm") || stringmatch(imagefunc, "skpm"))
			if (stringmatch(imagefunc, "trefm"))
				error+= td_xSetInWave(1,"Event.2", LockinString + "FreqOffset", ReadwaveFreq,"",interpval) // getting read frequency offset	

				error+= td_xsetoutwavepair(0,"Event.2,repeat", "Output.B", voltagewave,"Output.A", lightwave,-1*interpval)
				
				NVAR Cutdrive = root:packages:trEFM:cutDrive

				if (CutDrive == 0)	
					error += td_xsetoutwave(1,"Event.2,repeat", "Output.C", triggerwave, -1)
				elseif (CutDrive == 1)
					error += td_xsetoutWave(1, "Event.2,repeat", LockinString + "Amp",drivewave, -1)
					if (error != 0)
						print i, "errorONB_cut", error
					endif
				endif

				//stop amplitude FBLoop and start height FB for retrace
				StopFeedbackLoop(2)	

			elseif (stringmatch(imagefunc, "downefm"))
				error += td_xSetInWave(1, "Event.2", LockinString + "R", readwavefreq, "", 1)
				// writes amplitude to ReadWaveFreq, should rename this!
				error += td_xSetOutWave(0, "Event.2,Repeat", LockinString + "Amp", drivewave, -1)
				
				//stop amplitude FBLoop and start height FB for retrace
				StopFeedbackLoop(2)		

				// print height
				heightbefore = td_rv("Zsensor")*td_rv("ZLVDTSens")

			elseif (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
				td_xSetInWave(1, "Event.2", "Output.B", CPDWave,"", -1) 
				heightbefore = td_rv("Zsensor")*td_rv("ZLVDTSens")
		 
				//stop amplitude FBLoop and 
				StopFeedbackLoop(2)		
				SetCrosspoint ("Ground","In1","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutA","OutC","OutB","Ground","In0","DDS")

			endif

			
	

			// to keep tip from being stuck
			SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-500*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
			if (stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm"))
				sleep/S 1
			elseif (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
				sleep/s .5
			endif
			SetFeedbackLoop(3, "always",  "ZSensor", ReadWaveZ[scanpoints-1]-liftheight*1e-9/GV("ZLVDTSens"),0,EFMFilters[%ZHeight][%IGain],0, "Output.Z",0) // note the integral gain of 10000
			if (stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm"))
				sleep/S 1
			elseif (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
				sleep/s .5
			endif

			if (stringmatch(imagefunc, "downefm") || stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
				heightafter = td_rv("Zsensor")*td_rv("ZLVDTSens")
				print (heightafter - heightbefore)*1e9, " nanometerz"
			endif

			if (stringmatch(imagefunc, "trefm"))
				Make/O/N=(numpnts(ReadWaveFreq)) ZTemp = NaN
				error += td_xSetInWave(0,"Event.2", "ZSensor", ZTemp,"", interpval) // getting read z-sensor for debugging offset
			endif
			
			if (!stringmatch(imagefunc, "skpmspv"))
				error+= td_xsetoutwavePair(1,"Event.2", "$outputXLoop.Setpoint", Xupwave,"$outputYLoop.Setpoint", Yupwave,-UpInterpolation)	
				if (error != 0)
					print i, "errorONB7", error
				endif
				
				error = ErrorHandle(error)
			
				if (error != 0)
					print i, "errorONB8", error
				endif
			endif

			td_wv(LockinString + "Amp", CalSoftD) 
			td_wv(LockinString+"Freq", CalResFreq) //set the frequency to the resonant frequency
			if (stringmatch(imagefunc, "downefm"))	
				td_wv(LockinString+"Freq", CalResFreq - FreqOffsetNorm)
				td_wv(LockinString+"FreqOffset", FreqOffsetNorm)

				td_wv("Output.A",LightOn)	// light
				td_wv("Output.B",RingDownVoltage)	// voltage
				if (stringmatch("ARC.Lockin.0." , LockinString))
					SetFeedbackLoop(4, "always", LockinString +"theta", NaN, EFMFilters[%trEFM][%PGain], EFMFilters[%trEFM][%IGain], 0, LockinString+"FreqOffset",  EFMFilters[%trEFM][%DGain])
				else
					SetFeedbackLoopCypher(1, "always", LockinString +"theta", NaN, EFMFilters[%trEFM][%PGain], EFMFilters[%trEFM][%IGain], 0, LockinString+"FreqOffset",  EFMFilters[%trEFM][%DGain])
				endif
			elseif (stringmatch(imagefunc, "trefm"))
				td_wv(LockinString+"FreqOffset", 0)
			elseif (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
				td_wv((LockinString + "PhaseOffset"), CalPhaseOffset)
				error+= td_xsetoutwavePair(1, "Event.2", "ARC.PIDSLoop.0.Setpoint", Xupwave, "ARC.PIDSLoop.1.Setpoint", Yupwave, -UpInterpolation)	
				error+= td_xsetoutwave(2, "Event.2", "ARC.PIDSLoop.3.Setpoint", ReadWaveZback, -UpInterpolation)
			endif


			SetPassFilter(1, q = EFMFilters[%trEFM][%q], i = EFMFilters[%trEFM][%i])

			if (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
				lastvoltage = 0
			
				if (i != 0)
					lk = 0
					ll = (scanpoints - 1) * pointsPerPixel
					do
						CPDWaveLastPoint[lk] = CPDWaveLast[ll]
						ll += 1
						lk += 1
					while (lk < pointsPerPixel)
					
					lastvoltage = mean(CPDWaveLastPoint)
					if (lastvoltage > 6 || lastvoltage < -6)
						lastvoltage = 0
					endif	
					printf "LastVoltage is %g\r", lastvoltage		
					td_wv("Output.B", lastvoltage) //get the intial tip voltage close to where it was before
				endif
				
				SetFeedbackLoop(5, "Always", LockinString+"theta", td_rv(LockinString+"theta"), freq_PGain, freq_IGain, freq_DGain, "Output.A", 0)

				if (stringmatch(imagefunc, "skpmspv") || gWGDeviceAddress != 0)
					setvf(ACVoltage, ACFrequency,"WG")		
				else
					loadarbwave(ACFrequency, ACVoltage)	
				endif

				sleep/S 1/4
				
				//auto set LIA phase
				if (i == 0)
					td_wv("Output.B", 3) 
					setLockinTimeC(100/1000) //Tc100ms
					sleep/S 1/4
					setAutoPhase()
					sleep/S 1.0
					setLockinTimeC(LockinTimeConstant / 1000)
					td_wv("Output.B", 0) 
					sleep/S 1/4
				endif
				
				sleep/S 1/4

				SetFeedbackLoop(4, "always",  "Input.B", 0, EFMFilters[%KP][%PGain], EFMFilters[%KP][%IGain], EFMFilters[%KP][%DGain], "Output.B", 0) 
				sleep/S 1/4
				
				print "CPD linescan starts"
				
				//Fire retrace event here
				error += td_WriteString("Event.2", "Once")
				
				//abort
				
				CheckInWaveTiming(CPDWave)
			
				print "CPD linescan finished"
			endif




			//**********  END OF RETRACE SETTINGS

			//Fire retrace event here
			error += td_WriteString("Event.2", "Once")

			CheckInWaveTiming(ReadwaveFreq)	

			// ************  End of Retrace 		

			// Optional Save Raw Data
			if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm"))
				if(saveOption == 1)
//					string name
					if (i < 10)		
						name = "trEFM_000" + num2str(i) + ".ibw"
					elseif (i < 100)
						name = "trEFM_00" + num2str(i) + ".ibw"
					else
						name = "trEFM_0" + num2str(i) + ".ibw"
					endif

					Save/C/O/P = Path readWaveFreq as name
				endif
			endif
			//**********************************************************************************
			//***  PROCESS DATA AND UPDATE GRAPHS
			//*******************************************************************************
			variable V_FItOPtions = 4
			j=0

			do
				if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm"))
					V_FitError = 0
					V_FitOptions = 4
					readwavefreqtemp = 0
					k = 0
					l = j*cyclepoints

					Make/O/N = (PSChunkpointssmall, numavgsperpoint) ReadwaveFreqAVG
					variable avgloop = 0
					do
						Duplicate/O/R = [l + starttimepoint, l + stoptimepoint] ReadwaveFreq, Temp1
						ReadWaveFreqAvg[][avgloop] = Temp1[p] - 500

						avgloop += 1

						l += Fitcyclepoints
					while (avgloop < numavgsperpoint)
					
					MatrixOp/O readwavefreqtemp = sumrows(readwavefreqavg) / numcols(ReadWaveFreqAvg)

					make/o/n=3 W_sigma
					Make/O/N=3 W_Coef
					// Constraints added to improve fitting routines
					Make/O/T/N=1 T_Constraints
					//T_Constraints[0] = {"K1>0","K2>(1/100000)", "K2<10"}
					T_Constraints[0] = {"K2>(1/100000)", "K2<10"}
					
					curvefit/N=1/Q exp_XOffset, readwavefreqtemp  /x= CycleTime /C=T_Constraints
					FrequencyOffset[scanpoints-j-1][i]=W_Coef[1]
					ChargingRate[scanpoints-j-1][i]=1/(W_Coef[2]) 
					Chi2Image[scanpoints-j-1][i]=W_sigma[2]
				elseif (stringmatch(imagefunc, "skpm"))
					CPDWaveTemp = 0
					k = 0
					l = j * pointsPerPixel
					
					do
						CPDWaveTemp[k] = CPDWave[l]
						
						k += 1
						l += 1
					while (k < pointsPerPixel)
				
					CPDImage[scanpoints-j-1][i] = mean(CPDWaveTemp)
					//CPDImage[scanpoints-j-1][i] = StatsMedian(CPDWaveTemp)
				elseif (stringmatch(imagefunc, "skpmspv"))
					variable h = 0
					do
						CPDWaveTemp = 0
						k = 0
						l = h * pointsPerPixel
						
						do
							CPDWaveTemp[k] = CPDWave[l]
							
							k += 1
							l += 1
						while (k < pointsPerPixel)
					
						if(j==0)
							CPDImage[scanpoints-h-1][i] = mean(CPDWaveTemp)
						elseif(j==1)
//							CPDImage2[scanpoints-h-1][i] = mean(CPDWaveTemp)
//							CPDdiff[scanpoints-h-1][i]=CPDTrace2[p][i]-CPDTrace[p][i]
						endif
						
						h += 1
					while (h < scanpoints)

				endif

				j+=1
			while (j < scanpoints)


			if (stringmatch(imagefunc, "skpm"))
				if(i>0)
					CPDTraceBefore=CPDTrace
				endif
				CPDTrace = CPDImage[p][i]
			elseif (stringmatch(imagefunc, "skpmspv"))
				if(i>0 && j==0)
					CPDTraceBefore=CPDTrace
				endif
			
				if(j==0)
					CPDTrace = CPDImage[p][i]
//				elseif(j==1)
//					CPDTrace2 = CPDImage2[p][i]
				endif
			endif

		endif

			//**********************************************************************************
			//***  END OF PROCESS DATA AND UPDATE GRAPHS
			//*******************************************************************************		
		

		//*************************************************************
		//************ RESET FOR NEXT LINE **************** //
		//*************************************************************
		
		if (i < scanlines)//////////////
			DoUpdate 
			//stop height FBLoop, restart Amplitude FBLoop and move to starting point of next line
			StopFeedbackLoop(3)
			if (stringmatch(imagefunc, "gmode"))
				StopFeedbackLoop(4)
				SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","OutB","DDS")
			elseif (stringmatch(imagefunc, "trefm"))
				if (stringmatch("ARC.Lockin.0." , LockinString))
					StopFeedbackLoop(4)
				else
					StopFeedbackLoopCypher(1)
				endif
			elseif (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
				StopFeedbackLoop(4)
			elseif (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
				StopFeedbackLoop(5)
				td_stopInWaveBank(-1)
				td_stopOutWaveBank(-1)
			elseif (stringmatch(imagefunc, "downefm"))
				td_StopOutWaveBank(0)
				td_wv("Output.A",0)	// light
				td_wv("Output.B",0)	// voltage
			endif	
			td_wv(LockinString+"Amp",CalHardD) 
			td_wv(LockinString+"Freq",CalEngageFreq)
			td_wv(LockinString+"FreqOffset",0)		
			SetFeedbackLoop(2,"Always","Amplitude", Setpoint,-PGain,-IGain,-SGain,"Height",0)		
			
		endif   //if (i<gPSscanlines)


		if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm") || stringmatch(imagefunc, "gmode") || stringmatch(imagefunc, "skpmspv"))
			print "Time for last scan line (seconds) = ", (StopMSTimer(-2) -starttime2)*1e-6, " ; Time remaining (in minutes): ", ((StopMSTimer(-2) -starttime2)*1e-6*(scanlines-i-1)) / 60
		elseif (stringmatch(imagefunc, "skpm"))
			scantimes[i] = (StopMSTimer(-2) -starttime2)*1e-6
			print "Time for last scan line (seconds) = ", scantimes[i], " ; Time remaining (in minutes): ", scantimes[i]*(scanlines-i-1) / 60
		endif
		i += 1

		
		//Reset the primary inwaves to Nan so that gl_checkinwavetiming function works properly
		if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "trefm") || stringmatch(imagefunc, "downefm") || stringmatch(imagefunc, "gmode"))
			ReadWaveFreqLast[] = ReadwaveFreq[p]
			ReadWaveZ[] = NaN
			ReadwaveFreq[] = NaN
		elseif (stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "skpmspv"))
			CPDWaveLast[] = CPDWave[p]
			ReadWaveZ[] = NaN
			CPDWave[] = NaN
		endif
				
			//ACVoltage = root:Packages:trEFM:PointScan:SKPM:ACVoltage
			//ACVoltage+=0.05
			//print "Vac= ", ACVoltage, " V"
//	if (stringmatch(imagefunc, "skpmspv"))
//		j+=1
//		while (j < 2 )	
//		i += 1
//		
//		endif
		
	while (i < scanlines )	
	// end imaging loop 
	//************************************************************************** //
	
	if (error != 0)
		print "there was some setinoutwave error during this program"
	endif
	
	DoUpdate
	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "skpm") || stringmatch(imagefunc, "gmode") || stringmatch(imagefunc, "skpmspv"))		
		StopFeedbackLoop(3)	
		StopFeedbackLoop(4)
	endif

	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)

	if (stringmatch(imagefunc, "skpm"))
		if (useLineNUm != 0)
			display ScanTimes
			Label left "Scan time (s)";DelayUpdate
			Label bottom "Scan Line (#)"
		endif
	endif
	
	Beep
	doscanfunc("stopengage")

	if (stringmatch(imagefunc, "fftrefm") || stringmatch(imagefunc, "gmode"))
		// Save Parameters file
		CreateParametersFile(PIXELCONFIG)
		Save/G/O/P=Path/M="\r\n" SaveWave as "parameters.cfg"
	endif

	setdatafolder savDF	
End