#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function LBICscan(xpos, ypos, scansizeX,scansizeY, scanlines, scanpoints)
	
	Variable xpos, ypos, scansizeX,scansizeY, scanlines, scanpoints
	
	String savDF = GetDataFolder(1) // locate the current data folder
	
	
	SetDataFolder root:Packages:trEFM:ImageScan:LBIC
	NVAR LIAsens
	
	GetGlobals()  //getGlobals ensures all vars shared with asylum are current
	
	//global Variables	
	if ((scansizex / scansizey) != (scanpoints / scanlines))
		abort "X/Y scan size ratio and points/lines ratio don't match"
	endif
	
	Variable XLVDTSens = GV("XLVDTSens")
	Variable XLVDToffset = GV("XLVDToffset")
	Variable YLVDTSens  = GV("YLVDTSens")
	Variable YLVDToffset = GV("YLVDToffset")

	//local Variables
	Variable starttime,starttime2,starttime3
	Variable Downinterpolation, Upinterpolation
	Variable Interpolation = 1 // sample rate of DAQ banks
	Variable samplerate = 50000/interpolation
	Variable totaltime = 16 //
	
//	variable scanspeed = 1
//	Downinterpolation = ceil((50000 * (scansizex / scanspeed) / scanpoints))  
	
	ResetAll()	
	DoUpdate

	Make/O/N = (scanlines, 4) ScanFramework
	variable SlowScanDelta
	variable FastscanDelta
	variable i,j,k,l
	NVAR XFastPL, YFastPL, PLLineNum, PL_UseLineNum

	if (XFastpl == 1 && YFastpl == 0) //x direction scan
		ScanFramework[][0] = xpos - scansizeX / 2 
		ScanFramework[][2] = xpos + scansizeX / 2
		SlowScanDelta = scansizeY / (scanlines - 1)
		FastscanDelta = scansizeX / (scanpoints - 1)

		i = 0
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
		
	elseif (XFastpl == 0 && YFastpl == 1)
		
		ScanFramework[][0] = ypos - scansizeX / 2 //gPSscansizeX= fast width
		ScanFramework[][2] = ypos + scansizeX / 2
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
	
	endif	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///uncomment to scan at 90 deg.
	//ScanFramework[][0] = ypos - scansizey / 2 
	//ScanFramework[][2] = ypos + scansizey / 2
	//SlowScanDelta = scansizex / (scanlines - 1)
	//FastscanDelta = scansizey/ (scanpoints - 1)
	//i = 0
	//do
	//	if(scanlines > 1)
	//		ScanFramework[i][1] = (xpos - scansizex / 2) + SlowScanDelta*i
	//		ScanFramework[i][3] = (xpos - scansizeY / 2) + SlowScanDelta*i
	//	else
	//		ScanFramework[i][1] = xpos
	//		ScanFramework[i][3] = xpos
	//	endif
	//	i += 1
	//while (i < scanlines)
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	Make/O/N = (scanpoints, scanlines) LIBCurrent, LIBCurrentConverted
	Make/O/N = (scanpoints) Distance
	
	SetScale/I x, ScanFrameWork[0][0], ScanFramework[0][2], "um", LIBCurrent, LIBCurrentConverted
	if(scanlines==1)
		SetScale/I y, ypos, ypos, LIBCurrent, LIBCurrentConverted
	else
		SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], LIBCurrent, LIBCurrentConverted
	endif
	
	if(mod(scanpoints,32) != 0)									
			abort "Scan Points must be divisible by 32"
	endif
	
	Make/O/N = (scanpoints)  Xdownwave, Ydownwave, Xupwave, Yupwave
	Make/O/N = (scanpoints, scanlines, 4) XYupdownwave

	NVAR TimePerPoint = root:Packages:trEFM:PointScan:SKPM:TimePerPoint
	Variable pointsPerPixel = timeperpoint * samplerate * 1e-3
	Variable pointsPerLine = pointsPerPixel * scanpoints
	Variable timeofscan = timeperpoint * 1e-3 * scanpoints
	Upinterpolation = (timeofscan * samplerate) / (scanpoints)
		
	dowindow/f LIBCurrentImage
	if (V_flag==0)
		Display/K=1/n=LIBCurrentImage;Appendimage LIBCurrent
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan(um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(65000,60000,48600),expand=.7	
		ColorScale/C/N=text0/E/F=0/A=MC image=LIBCurrent
		ModifyImage LIBCurrent ctab= {*,*,VioletOrangeYellow,0}
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "V"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=LIBCurrent
	endif		
	ModifyGraph/W=LIBCurrentImage height = {Aspect, scansizeY/scansizeX}
	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=LIBCurrentImage height = {Aspect, 1}
	endif
	
	dowindow/f LIBCurrentConvertedImage
	if (V_flag==0)
		Display/K=1/n=LIBCurrentConvertedImage;Appendimage LIBCurrentConverted
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan(um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(65000,60000,48600),expand=.7	
		ColorScale/C/N=text0/E/F=0/A=MC image=LIBCurrentConverted
		ModifyImage LIBCurrentConverted ctab= {*,*,VioletOrangeYellow,0}
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "pA"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=LIBCurrentConverted
	endif		
	ModifyGraph/W=LIBCurrentConvertedImage height = {Aspect, scansizeY/scansizeX}
	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=LIBCurrentConvertedImage height = {Aspect, 1}
	endif
	
	Make/o/n=(pointsPerPixel) LIBCurrentWaveTemp
	Make/O/N=(scanpoints) LIBCurrentTrace, LIBCurrentTraceBefore, LIBCurrentConvertedTrace
	LIBCurrentTrace = 0
	LIBCurrentTraceBefore = 0
	LIBCurrentConvertedTrace = 0
	
	SetScale/I x ScanFrameWork[0][0], ScanFramework[0][2],"um", LIBCurrentTrace, LIBCurrentTraceBefore, LIBCurrentConvertedTrace
	
	dowindow/f LIBCurrentTraceWindow
	if (V_flag==0)
		Display/K=1/n=LIBCurrentTraceWindow LIBCurrentTrace
		appendtograph LIBCurrentTraceBefore
		ModifyGraph rgb(LIBCurrentTraceBefore)=(0,0,0)
		ModifyGraph lsize=3
		ModifyGraph tick(left)=2,fStyle(left)=1,axThick(left)=2;DelayUpdate
		Label left "Voltage (V)"
		ModifyGraph tick=2,mirror(bottom)=1,fStyle=1,axThick=2;DelayUpdate
		Label bottom "Distance (um)"
		appendtograph /R LIBCurrentConvertedTrace
		ModifyGraph rgb(LIBCurrentConvertedTrace)=(65535,65535,65535)	
		ModifyGraph tick=2,fStyle=1,axThick=2;DelayUpdate
		Label right "Current (pA)"
		Legend/C/N=text1/A=RB
		Legend/C/N=text1/J "\\f01\\s(LIBCurrentTrace) LIBCurrentTrace\r\\s(LIBCurrentTraceBefore) LIBCurrentTraceBefore"
	endif
	
	Make/O/N = (pointsPerLine) LIBCurrentWave
	LIBCurrentWave = NaN

	variable error = 0
	td_StopInWaveBank(-1)

	MoveXY(ScanFramework[0][0], ScanFramework[0][1])
	//************************************* XYupdownwave is the final, calculated, scaled values to drive the XY piezos ************************//	
	//XYupdownwave[][][0] = (ScanFrameWork[q][0] + FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
	//XYupdownwave[][][1] = (ScanFrameWork[q][2] - FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
	//XYupdownwave[][][2] = (ScanFrameWork[q][1]) / YLVDTsens / 10e5 + YLVDToffset
	//XYupdownwave[][][3] = (ScanFrameWork[q][3]) / YLVDTsens / 10e5 + YLVDToffset
	
	if (XFastPL == 1 && YFastPL == 0)	//x  scan direction
		XYupdownwave[][][0] = (ScanFrameWork[q][0] + FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][1] = (ScanFrameWork[q][2] - FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][2] = (ScanFrameWork[q][1]) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][3] = (ScanFrameWork[q][3]) / YLVDTsens / 10e5 + YLVDToffset
	elseif (XFastPL == 0 && YFastPL == 1)	
		XYupdownwave[][][2] = (ScanFrameWork[q][0] + FastScanDelta*p) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][3] = (ScanFrameWork[q][2] - FastScanDelta*p) / YLVDTsens / 10e5 + YLVDToffset
		XYupdownwave[][][0] = (ScanFrameWork[q][1]) / XLVDTsens / 10e5 + XLVDToffset
		XYupdownwave[][][1] = (ScanFrameWork[q][3]) / XLVDTsens / 10e5 + XLVDToffset
	endif

	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	
	SetCrosspoint ("Ground","In1","FilterOut","Ground","Ground","Ground","Off","Off","Off","Defl","Ground","Ground","OutB","Ground","Ground","DDS")
	//Daviiiiid
	//variable appliedbias = 5
	//variable biasfreq = 400
	//wavegeneratoroffset(appliedbias,2*biasfreq,"Output.B","Event.2,repeat",1)  
	//td_WriteString("Event.2", "Once")
	
	///Starting imaging loop here
	i = 0
	
	do

		if (PL_UseLineNum == 0)
			PLLineNum = i	// flag to scan a whole image, not just a line
		endif

		if (XFastPL == 1 && YFastPL == 0)	
			MoveXY(ScanFramework[PLLineNum][0], ScanFramework[PLLineNum][1])
		elseif (XFastPL == 0 && YFastPL == 1)
			MoveXY(ScanFramework[PLLineNum][1], ScanFramework[PLLineNum][0])
		endif

//		if (XFastPL == 1 && YFastPL == 0)	
//			MoveXY(ScanFramework[i][0], ScanFramework[i][1])
//		elseif (XFastPL == 0 && YFastPL == 1)
//			MoveXY(ScanFramework[i][1], ScanFramework[i][0])
//		endif
		Sleep/S 2
		
		starttime2 = StopMSTimer(-2) //Start timing the raised scan line
		print "line ", i+1

		// these are the actual 1D drive waves for the tip movement
		// quick way to make scan 90, change the "2" and "0" , 0 and 2 = 0 degree scan
		// To fix a line scan at a position, change i in Xdownwave here to a specific line number not exceeding pixel counts
		//Xdownwave[] = XYupdownwave[p][64][2]	
		//Ydownwave[] = XYupdownwave[p][i][0]
		
		// 0 degree scan, uncomment these
		// To fix a line scan at a position, change i in Ydownwave here to a specific line number not exceeding pixel counts
		 //Xdownwave[] = XYupdownwave[p][i][0]
		 //Ydownwave[] = XYupdownwave[p][i][2]



		// 0 or 90 degree scan
		//if (XFastPL == 0 && YFastPL == 1)		// use both flags as redundancy against Igor errors
			Xdownwave[] = XYupdownwave[p][PLLineNum][0]	
			Ydownwave[] = XYupdownwave[p][PLLineNum][2]
		//elseif (XFastPL == 1 && YFastPL == 0)
		//	Xdownwave[] = XYupdownwave[p][i][0]
		//	Ydownwave[] = XYupdownwave[p][PLLineNum][2]
		//endif

		// Note that the upwaves don't actually do anything in PL scans
		Xupwave[] = XYupdownwave[p][i][1]
		Yupwave[] = XYupdownwave[p][i][3]
	
		td_xSetInWave(0, "Event.1", "Input.B", LIBCurrentWave,"", 1) 
		td_xSetOutWavePair(0, "Event.1", "PIDSLoop.0.Setpoint", Xdownwave, "PIDSLoop.1.Setpoint", Ydownwave , -UpInterpolation)
						
		Sleep/S .5	
				
		//Fire retrace event here
		error += td_WriteString("Event.1", "Once")

		CheckInWaveTiming(LIBCurrentWave)
		Sleep/S .05

		//**********************************************************************************
		//***  PROCESS DATA AND UPDATE GRAPHS
		//*******************************************************************************
		
		j = 0
		do
			LIBCurrentWaveTemp = 0
			k = 0
			l = j * pointsPerPixel
				do
					LIBCurrentWaveTemp[k] = LIBCurrentWave[l]
					k += 1
					l += 1
				while (k < pointsPerPixel)
		
			LIBCurrent[j][i] = mean(LIBCurrentWaveTemp)
			LIBCurrentConverted[j][i]=(LIBCurrent[j][i]*LIAsens/10.0)
			j += 1
		while (j < scanpoints)

		if(i>0)
			LIBCurrentTraceBefore=LIBCurrentTrace
		endif
		
		LIBCurrentTrace = LIBCurrent[p][i]
		LIBCurrentConvertedTrace  = LIBCurrentConverted[p][i]
		
		if (i < scanlines)		
			DoUpdate 
			td_stopInWaveBank(-1)
			//td_stopOutWaveBank(-1)
			td_stopoutwavebank(0)
		endif 
	
		//print "Time for last scan line (seconds) = ", (StopMSTimer(-2) -starttime2)*1e-6, " ; Time remaining (in minutes): ", ((StopMSTimer(-2) -starttime2)*1e-6*(scanlines-i-1)) / 60
		i += 1
		
		LIBCurrentWave[] = NaN
		
			
	while (i < scanlines )	
	
	if (error != 0)
		print "there was some setinoutwave error during this program"
	endif
	
	DoUpdate		

	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	Beep
	setdatafolder savDF
End





















Function PLpointscan(xpos, ypos, scantime)
	
	Variable xpos, ypos, scantime
	
	String savDF = GetDataFolder(1) // locate the current data folder

	SetDataFolder root:Packages:trEFM:ImageScan:LBIC
	NVAR LIAsens
	
	GetGlobals()  //getGlobals ensures all vars shared with asylum are current
	
	Variable XLVDTSens = GV("XLVDTSens")
	Variable XLVDToffset = GV("XLVDToffset")
	Variable YLVDTSens  = GV("YLVDTSens")
	Variable YLVDToffset = GV("YLVDToffset")

	//local Variables
	Variable Interpolation = 1 // sample rate of DAQ banks
	Variable samplerate = 50000/interpolation
	Variable pointperscan = scantime*samplerate
	pointperscan-=mod(pointperscan,32)

	Make/O/N = (pointperscan) PLwave, PLwaveConverted
	PLwave = NaN	
	
	variable error = 0

	MoveXY(xpos, ypos)
	
	td_StopInWaveBank(-1)
	
	SetCrosspoint ("Ground","In1","FilterOut","Ground","Ground","Ground","Off","Off","Off","Defl","Ground","Ground","OutB","Ground","Ground","DDS")

	Sleep/S .05	
	
	td_xSetInWave(0, "Event.1", "Input.B", PLwave,"", -1) 
	
	Sleep/S .05						
						
	//Fire retrace event here
	error += td_WriteString("Event.1", "Once")

	CheckInWaveTiming(PLwave)

	Sleep/S .05	
	
	Plwaveconverted=PLwave*LIAsens/10.0
	
	if (error != 0)
		print "there was some setinoutwave error during this program"
	endif
	
	DoWindow/F PLvsTime
	if(v_flag == 0)
		display/l/K=1/b/N=PLvsTime PLwave
		appendtograph/R Plwaveconverted
			
		Label/W=PLvsTime left "PL (Volts)"
		Label/W=PLvsTime bottom "Time (s)"
		Label/W=PLvsTime right "PL (pA)"
					
		ModifyGraph/W=PLvsTime lsize=2,rgb=(0,39168,0)
		ModifyGraph/W=PLvsTime fStyle=1,fSize=14
		ModifyGraph/W=PLvsTime gbRGB = (65535,65535,65535)
		ModifyGraph/W=PLvsTime wbRGB = (65535,65535,65535)
	endif
	
	DoUpdate		

	td_StopInWaveBank(-1)
	Beep
	setdatafolder savDF
End


Function LBICInit()
	
	Variable /G root:packages:trEFM:ImageScan:LBIC:LIAsens=500
	Variable /G root:packages:trEFM:ImageScan:LBIC:xCursorPosition=0
	Variable /G root:packages:trEFM:ImageScan:LBIC:yCursorPosition=0
	
	Variable/G root:packages:trEFM:ImageScan:LBIC:TimePerPL = 0
	
	Variable/G root:packages:trEFM:ImageScan:LBIC:XFastPL = 1
	Variable/G root:packages:trEFM:ImageScan:LBIC:YFastPL = 0
	
	Variable/G root:packages:trEFM:ImageScan:LBIC:PLLineNum = 0
	Variable/G root:packages:trEFM:ImageScan:LBIC:PL_UseLineNum = 0

End

	//add this if modified 
	//	NewDataFolder/O/S root:Packages:trEFM:ImageScan:LBIC
	//	LBICInit()
Window LBICPanel() : Panel
	LBICInit()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(633,68,859,484)
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (56576,56576,56576)
	DrawRect 0,-0,225,414
	SetDrawEnv fstyle= 1
	DrawText 57,144,"Scan center"
	SetDrawEnv fstyle= 1
	DrawText 64,209,"Scan size"
	SetDrawEnv fstyle= 1
	DrawText 12,21,"Cursor position on an Image"
	SetDrawEnv linethick= 2,arrow= 1
	DrawLine 27,90,54,135
	SetVariable setvar4,pos={37,253},size={126,16},title="Time Per Point (ms)"
	SetVariable setvar4,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:TimePerPoint
	Button button1,pos={44,369},size={100,20},proc=SaveLBICImageButton,title="Save Data"
	SetVariable setvar5,pos={11,150},size={72,16},title="X (um)"
	SetVariable setvar5,limits={-inf,inf,0},value= root:packages:trEFM:gxpos
	SetVariable setvar6,pos={11,171},size={72,16},title="Y (um)"
	SetVariable setvar6,limits={-inf,inf,0},value= root:packages:trEFM:gypos
	Button button2,pos={89,147},size={90,22},proc=MoveHereButton,title="Move here"
	Button button15,pos={89,169},size={90,22},proc=GetCurrentPositionButton,title="Get Current XY"
	Button button15,help={"Fill the X,Y with the current stage position."}
	SetVariable scanwidthT,pos={384,62},size={100,16},title="Width (µm)        "
	SetVariable scanwidthT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizex
	SetVariable scanwidthT1,pos={384,62},size={100,16},title="Width (µm)        "
	SetVariable scanwidthT1,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizex
	SetVariable scanwidthT2,pos={384,62},size={100,16},title="Width (µm)        "
	SetVariable scanwidthT2,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizex
	SetVariable setvar8,pos={11,214},size={79,16},title="Width (µm)"
	SetVariable setvar8,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizex
	SetVariable setvar9,pos={11,234},size={79,16},title="Height (µm)"
	SetVariable setvar9,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizey
	SetVariable setvar0,pos={92,213},size={90,16},title="Scan Points"
	SetVariable setvar0,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanpoints
	SetVariable setvar1,pos={92,233},size={90,16},title="Scan Lines"
	SetVariable setvar1,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanlines
	Button button3,pos={48,314},size={100,20},proc=LBICImageScanButton,title="Image Scan"
	Button button4,pos={48,291},size={100,20},proc=ClearLBICImagesButton,title="Clear Images"
	SetVariable setvar7,pos={37,272},size={126,16},title="LIA sensitivity (pA)"
	SetVariable setvar7,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:LBIC:LIAsens
	SetVariable setvar2,pos={11,23},size={72,16},title="X (um)"
	SetVariable setvar2,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:LBIC:xCursorPosition
	SetVariable setvar3,pos={95,24},size={72,16},title="Y (um)"
	SetVariable setvar3,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:LBIC:yCursorPosition
	Button button5,pos={18,45},size={99,18},proc=GetCursorPosition,title="Get Cursor Pos"
	Button button6,pos={18,65},size={99,27},proc=TransferPositionButton,title="Transfer position"
	ValDisplay TimePerPLScan,pos={27,396},size={153,14},title="TimePerPLScan (s)"
	ValDisplay TimePerPLScan,frame=0,limits={0,0,0},barmisc={0,1000}
	ValDisplay TimePerPLScan,value= #"root:packages:trEFM:ImageScan:LBIC:TimePerPL"
	Button button8,pos={153,306},size={45,27},proc=PLXFast,title="0°!",fStyle=1
	Button button8,fColor=(52224,52224,52224)
	SetVariable setvar03,pos={18,342},size={126,16},title="Single Line Number"
	SetVariable setvar03,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:LBIC:PLLineNum
	CheckBox singleline,pos={153,342},size={16,14},proc=UseLineNum,title=""
	CheckBox singleline,variable= root:packages:trEFM:ImageScan:LBIC:PL_UseLineNum
	Button SetupAWG,pos={144,46},size={72,26},proc=SetAWGForPL,title="Set AWG"
	Button SetupAWG,fSize=14,fStyle=1,fColor=(0,15872,65280)
	Button SetupLIA,pos={144,72},size={72,18},proc=SetLockInForPL,title="Set LIA"
	Button SetupLIA,fSize=14,fStyle=1,fColor=(0,15872,65280)
	Button button16,pos={63,99},size={117,18},proc=GetMFPOffset,title="Grab Offset from ARC"
	Button button16,help={"Fill the X,Y with the current stage position."}
	ToolsGrid snap=1,visible=1
EndMacro

Function LBICImageScanButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)

	SetDataFolder root:Packages:trEFM:ImageScan
	Nvar scansizex, scansizey, scanlines, scanpoints
	nvar TimePerPoint = root:packages:trEFM:PointScan:SKPM:timeperpoint
	NVAR timeperPL = root:packages:trEFM:ImageScan:LBIC:TimePerPL
	SetDataFolder root:Packages:trEFM
	Nvar gxpos, gypos

	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif

	timeperPL = scanpoints * scanlines * timeperpoint / 1000
	DoUpdate
	
	//OpenShutterButton("")
	
	LBICscan(gxpos, gypos, scansizeX, scansizeY, scanlines, scanpoints)

	//CloseShutterButton("")
	GetCurrentPosition()
	SetDataFolder savDF
	
End

Function LBICImageScanButtonSD(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)

	SetDataFolder root:Packages:trEFM:ImageScan
	Nvar scansizex, scansizey, scanlines, scanpoints
	SetDataFolder root:Packages:trEFM
	Nvar gxpos, gypos

	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif

	LBICscanFrameDown(gxpos, gypos, scansizeX, scansizeY, scanlines, scanpoints)
	GetCurrentPosition()
	SetDataFolder savDF
	
End

Function SaveLBICImageButton(ctrlname): ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	String name
	Variable type
	
	Prompt name, "Save As?"
	Prompt type, "0 for LBIC. 1 for LBIV"
	DoPrompt "Save Image As",name, type
	print name

	SaveLBICImageScan(name,type)
	
End

Function SaveLBICImageScan(name,type)
	String name
	Variable type
	
	String savDF = GetDataFolder(1)
	
	SetDataFolder root:packages:trEFM:ImageScan:LBIC

	Wave LIBCurrent, LIBCurrentConverted
	Wave ScanFrameWork

	SetDataFolder root:Packages:trEFM:ImageScan
	Nvar scanpoints, scanlines
	
	String/g DataTypeList
	//DataTypeList = "HeightTrace;UserIn0ReTrace;UserIn1ReTrace;UserIn2ReTrace"
	DataTypeList = "UserIn0ReTrace;UserIn1ReTrace"
	
	Make/O/N = (scanpoints, scanlines, 2) ImageWave
	
	setscale/I x, 0, ScanFramework[0][2]-ScanFrameWork[0][0], "um", ImageWave
	if(scanlines == 1)
		setscale/I y, 0, ScanFramework[0][2]-ScanFrameWork[0][0], "um", ImageWave
	else
		setscale/I y, 0, ScanFramework[scanlines-1][1]-ScanFrameWork[0][1], "um",ImageWave
	endif
	
	//Test function to save multiple layer waves as a single 3D AR Image wave.	
	//these are the lines I used to test this opit	
	if( type == 0)
		ImageWave[][][0] = LIBCurrent[p][q]
		ImageWave[][][1] = LIBCurrentConverted[p][q]
	else
		ImageWave[][][0] = LIBCurrent[p][q]
		ImageWave[][][1] = LIBCurrentConverted[p][q]
	endif
	
	//give it the right number of points in X and Y
	//we will assume that all layers have the same number of points and lines.		
	
	String NoteStr = ""
	variable A
	for (A = 0;A < 2;A += 1)
		SetDimLabel 2,A,$StringFromList(A,DataTypeList,";"),ImageWave		//set the layer label based on the string from DataTypeList
		//put in some values for the note
		//here you can make this considerably more complex, calculating starting values and whatnot.
		NoteStr = ReplaceNumberByKey("Display Range"+num2str(A),NoteStr,12e-6,":","\r")
		NoteStr = ReplaceNumberByKey("Display Offset "+num2str(A),NoteStr,0,":","\r")
		NoteStr = ReplaceStringByKey("Colormap"+num2str(A),NoteStr,"YellowHot",":","\r")
		NoteStr = ReplaceNumberByKey("Planefit Offset "+num2str(A),NoteStr,0,":","\r")
		NoteStr = ReplaceNumberByKey("Planefit X Slope"+num2str(A),NoteStr,0,":","\r")
		NoteStr = ReplaceNumberByKey("Planefit Y Slope"+num2str(A),NoteStr,0,":","\r")	
	endfor
	
	Note/K ImageWave		//clear any existing note on the wave
	Note ImageWave,NoteStr		//put ours on
	
	duplicate/o ImageWave, $name
	
	gl_ResaveImageFunc($name,"SaveImage",0)		//call the function that will save the info

	SetDataFolder savDF //restore the data folder to its original location
End

Function ClearLBICImagesButton(ctrlname): ButtonControl
	String ctrlname
	ClearLBICImages()
End

Function ClearLBICImages()
	string SavDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:ImageScan:LBIC
	Wave/Z LIBCurrent, LIBCurrentConverted
	
	if (WaveExists(LIBCurrent)) 
		LIBCurrent=0
		LIBCurrentConverted=0
	endif
	
	SetDataFolder savDF
End

Function SetLockInForPL(ba): ButtonControl
	STRUCT WMButtonAction &ba
	
	switch( ba.eventCode )
		
		case 2: // mouse up
		// click code here
			LockinRecall(4)	// hard-coded for Daviid's setup
		case -1: // control being killed
			break
			
	endswitch		
		
end

Function SetAWGForPL(ba): ButtonControl
	STRUCT WMButtonAction &ba
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	NVAR gWGDeviceAddress
	
	switch( ba.eventCode )
		
		case 2: // mouse up
		// click code here
			GPIBsetup()
			string string1

			writeGPIB(gWGDeviceAddress, "APPL:square")
			sprintf string1 "FREQ %g" 400
			writeGPIB(gWGDeviceAddress, string1)

			sprintf string1, "VOLT %g" 2.5
			writeGPIB(gWGDeviceAddress, string1)

			writeGPIB(gWGDeviceAddress, "VOLT:OFFS 1.25")
			GPIB2 interfaceclear	
			
			SetDataFolder SavedDataFolder
		case -1: // control being killed
			break
			SetDataFolder SavedDataFolder
			
	endswitch		
	
	SetDataFolder SavedDataFolder	
end


Function GetCursorPosition(ba): ButtonControl
	STRUCT WMButtonAction &ba
	
	String savDF = GetDataFolder(1) // locate the current data folder
	SetDataFolder root:Packages:trEFM:ImageScan:LBIC
	NVAR xCursorPosition
	NVAR yCursorPosition

	SetDataFolder savDF
	
	switch( ba.eventCode )
		
		case 2: // mouse up
		// click code here
			xCursorPosition=hcsr(A)
			yCursorPosition=vcsr(A)
		case -1: // control being killed
			break
			
	endswitch		
End

Function PLXFast(ba): ButtonControl
	STRUCT WMButtonAction &ba

	
	NVAR XFastPL = root:packages:trEFM:ImageScan:LBIC:XFastPL 
	NVAR YFastPL = root:packages:trEFM:ImageScan:LBIC:YFastPL
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			if (XFastPL == 0)
				XFastPL = 1
				YFastPL = 0
				Button button8 title="0°!"
				Button button8 fColor=(52224,52224,52224)
			elseif(XFastPL == 1)
				XFastPL = 0
				YFastPL = 1
				Button button8 title="90°!"
				Button button8 fColor=(65280,32768,32768)
			endif
			break
		case -1: // control being killed
			break
	endswitch
	
End

Function UseLineNum(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	NVAR PL_UseLineNum =  root:packages:trEFM:ImageScan:LBIC:PL_UseLineNum
	NVAR UseLineNum = root:packages:trEFM:ImageScan:UseLineNum

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			 PL_UseLineNum = checked
			 UseLineNum = checked
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function TransferPosition()
	String savDF = GetDataFolder(1) // locate the current data folder
	SetDataFolder root:Packages:trEFM:ImageScan:LBIC
	NVAR xCursorPosition
	NVAR yCursorPosition
	SetDataFolder root:Packages:trEFM
	NVAR gxpos
	NVAR gypos
	gxpos=xCursorPosition
	gypos=yCursorPosition
	SetDataFolder savDF
End

Function TransferPositionButton(ctrlname): ButtonControl
	String ctrlname
	TransferPosition()
End

//	print "FWHM = ", 2*sqrt(ln(2))*W_coef[3], "+/-", 2*sqrt(ln(2))*W_sigma[3]
//	print "1/e^2 = ", 2*sqrt(2)*W_coef[3], "+/-", 2*sqrt(2)*W_sigma[3]















Function LBICscanFrameDown(xpos, ypos, scansizeX,scansizeY, scanlines, scanpoints)
	
	Variable xpos, ypos, scansizeX,scansizeY, scanlines, scanpoints
	
	String savDF = GetDataFolder(1) // locate the current data folder
	
	
	SetDataFolder root:Packages:trEFM:ImageScan:LBIC
	NVAR LIAsens
	
	GetGlobals()  //getGlobals ensures all vars shared with asylum are current
	
	//global Variables	
	if ((scansizex / scansizey) != (scanpoints / scanlines))
		abort "X/Y scan size ratio and points/lines ratio don't match"
	endif
	
	Variable XLVDTSens = GV("XLVDTSens")
	Variable XLVDToffset = GV("XLVDToffset")
	Variable YLVDTSens  = GV("YLVDTSens")
	Variable YLVDToffset = GV("YLVDToffset")

	//local Variables
	Variable starttime,starttime2,starttime3
	Variable Downinterpolation, Upinterpolation
	Variable Interpolation = 1 // sample rate of DAQ banks
	Variable samplerate = 50000/interpolation
	Variable totaltime = 16 //
	
//	variable scanspeed = 1
//	Downinterpolation = ceil((50000 * (scansizex / scanspeed) / scanpoints))  
	
	ResetAll()	
	DoUpdate

	Make/O/N = (scanlines, 4) ScanFramework
	variable SlowScanDelta
	variable FastscanDelta
	variable i,j,k,l

	ScanFramework[][0] = xpos - scansizeX / 2 
	ScanFramework[][2] = xpos + scansizeX / 2
	SlowScanDelta = scansizeY / (scanlines - 1)
	FastscanDelta = scansizeX / (scanpoints - 1)

	i = 0
	do
		if(scanlines > 1)
//			ScanFramework[i][1] = (ypos - scansizeY / 2) + SlowScanDelta*i
//			ScanFramework[i][3] = (ypos - scansizeY / 2) + SlowScanDelta*i
			ScanFramework[i][1] = (ypos - scansizeY / 2) + SlowScanDelta*(scanlines - i)
			ScanFramework[i][3] = (ypos - scansizeY / 2) + SlowScanDelta*(scanlines - i)

		else
		
			ScanFramework[i][1] = ypos
			ScanFramework[i][3] = ypos
		endif
		i += 1
	while (i < scanlines)
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///uncomment to scan at 90 deg.
	//ScanFramework[][0] = ypos - scansizey / 2 
	//ScanFramework[][2] = ypos + scansizey / 2
	//SlowScanDelta = scansizex / (scanlines - 1)
	//FastscanDelta = scansizey/ (scanpoints - 1)
	//i = 0
	//do
	//	if(scanlines > 1)
	//		ScanFramework[i][1] = (xpos - scansizex / 2) + SlowScanDelta*i
	//		ScanFramework[i][3] = (xpos - scansizeY / 2) + SlowScanDelta*i
	//	else
	//		ScanFramework[i][1] = xpos
	//		ScanFramework[i][3] = xpos
	//	endif
	//	i += 1
	//while (i < scanlines)
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	Make/O/N = (scanpoints, scanlines) LIBCurrent, LIBCurrentConverted
	Make/O/N = (scanpoints) Distance
	
	SetScale/I x, ScanFrameWork[0][0], ScanFramework[0][2], "um", LIBCurrent, LIBCurrentConverted
	if(scanlines==1)
		SetScale/I y, ypos, ypos, LIBCurrent, LIBCurrentConverted
	else
		SetScale/I y, ScanFrameWork[0][1], ScanFramework[scanlines-1][1], LIBCurrent, LIBCurrentConverted
	endif
	
	if(mod(scanpoints,32) != 0)									
			abort "Scan Points must be divisible by 32"
	endif
	
	Make/O/N = (scanpoints)  Xdownwave, Ydownwave, Xupwave, Yupwave
	Make/O/N = (scanpoints, scanlines, 4) XYupdownwave

	NVAR TimePerPoint = root:Packages:trEFM:PointScan:SKPM:TimePerPoint
	Variable pointsPerPixel = timeperpoint * samplerate * 1e-3
	Variable pointsPerLine = pointsPerPixel * scanpoints
	Variable timeofscan = timeperpoint * 1e-3 * scanpoints
	Upinterpolation = (timeofscan * samplerate) / (scanpoints)
		
	dowindow/f LIBCurrentImage
	if (V_flag==0)
		Display/K=1/n=LIBCurrentImage;Appendimage LIBCurrent
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan(um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(65000,60000,48600),expand=.7	
		ColorScale/C/N=text0/E/F=0/A=MC image=LIBCurrent
		ModifyImage LIBCurrent ctab= {*,*,VioletOrangeYellow,0}
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "V"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=LIBCurrent
	endif		
	ModifyGraph/W=LIBCurrentImage height = {Aspect, scansizeY/scansizeX}
	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=LIBCurrentImage height = {Aspect, 1}
	endif
	
	dowindow/f LIBCurrentConvertedImage
	if (V_flag==0)
		Display/K=1/n=LIBCurrentConvertedImage;Appendimage LIBCurrentConverted
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "Fast Scan(um)"
		Label left "Slow Scan (um)"
		ModifyGraph wbRGB=(65000,60000,48600),expand=.7	
		ColorScale/C/N=text0/E/F=0/A=MC image=LIBCurrentConverted
		ModifyImage LIBCurrentConverted ctab= {*,*,VioletOrangeYellow,0}
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "pA"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=LIBCurrentConverted
	endif		
	ModifyGraph/W=LIBCurrentConvertedImage height = {Aspect, scansizeY/scansizeX}
	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=LIBCurrentConvertedImage height = {Aspect, 1}
	endif
	
	Make/o/n=(pointsPerPixel) LIBCurrentWaveTemp
	Make/O/N=(scanpoints) LIBCurrentTrace, LIBCurrentTraceBefore, LIBCurrentConvertedTrace
	LIBCurrentTrace = 0
	LIBCurrentTraceBefore = 0
	LIBCurrentConvertedTrace = 0
	
	SetScale/I x ScanFrameWork[0][0], ScanFramework[0][2],"um", LIBCurrentTrace, LIBCurrentTraceBefore, LIBCurrentConvertedTrace
	
	dowindow/f LIBCurrentTraceWindow
	if (V_flag==0)
		Display/K=1/n=LIBCurrentTraceWindow LIBCurrentTrace
		appendtograph LIBCurrentTraceBefore
		ModifyGraph rgb(LIBCurrentTraceBefore)=(0,0,0)
		ModifyGraph lsize=3
		ModifyGraph tick(left)=2,fStyle(left)=1,axThick(left)=2;DelayUpdate
		Label left "Voltage (V)"
		ModifyGraph tick=2,mirror(bottom)=1,fStyle=1,axThick=2;DelayUpdate
		Label bottom "Distance (um)"
		appendtograph /R LIBCurrentConvertedTrace
		ModifyGraph rgb(LIBCurrentConvertedTrace)=(65535,65535,65535)	
		ModifyGraph tick=2,fStyle=1,axThick=2;DelayUpdate
		Label right "Current (pA)"
		Legend/C/N=text1/A=RB
		Legend/C/N=text1/J "\\f01\\s(LIBCurrentTrace) LIBCurrentTrace\r\\s(LIBCurrentTraceBefore) LIBCurrentTraceBefore"
	endif
	
	Make/O/N = (pointsPerLine) LIBCurrentWave
	LIBCurrentWave = NaN

	variable error = 0
	td_StopInWaveBank(-1)

	MoveXY(ScanFramework[0][0], ScanFramework[0][1])
	//************************************* XYupdownwave is the final, calculated, scaled values to drive the XY piezos ************************//	
	XYupdownwave[][][0] = (ScanFrameWork[q][0] + FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
	XYupdownwave[][][1] = (ScanFrameWork[q][2] - FastScanDelta*p) / XLVDTsens / 10e5 + XLVDToffset
	XYupdownwave[][][2] = (ScanFrameWork[q][1]) / YLVDTsens / 10e5 + YLVDToffset
	XYupdownwave[][][3] = (ScanFrameWork[q][3]) / YLVDTsens / 10e5 + YLVDToffset

	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	
	SetCrosspoint ("Ground","In1","FilterOut","Ground","Ground","Ground","Off","Off","Off","Defl","Ground","Ground","OutB","Ground","Ground","DDS")
	//Daviiiiid
	//variable appliedbias = 5
	//variable biasfreq = 400
	//wavegeneratoroffset(appliedbias,2*biasfreq,"Output.B","Event.2,repeat",1)  
	//td_WriteString("Event.2", "Once")
		
	///Starting imaging loop here
	i = 0
	do
		MoveXY(ScanFramework[i][0], ScanFramework[i][1])
			
		starttime2 = StopMSTimer(-2) //Start timing the raised scan line
		print "line ", i+1

		// these are the actual 1D drive waves for the tip movement
		Xdownwave[] = XYupdownwave[p][i][0]
		Xupwave[] = XYupdownwave[p][i][1]
		Ydownwave[] = XYupdownwave[p][i][2]
		Yupwave[] = XYupdownwave[p][i][3]
	
		td_xSetInWave(0, "Event.1", "Input.B", LIBCurrentWave,"", 1) 
		td_xSetOutWavePair(0, "Event.1", "PIDSLoop.0.Setpoint", Xdownwave, "PIDSLoop.1.Setpoint", Ydownwave , -UpInterpolation)
						
		Sleep/S .5	
				
		//Fire retrace event here
		error += td_WriteString("Event.1", "Once")

		CheckInWaveTiming(LIBCurrentWave)
		Sleep/S .05

		//**********************************************************************************
		//***  PROCESS DATA AND UPDATE GRAPHS
		//*******************************************************************************
		
		j = 0
		do
			LIBCurrentWaveTemp = 0
			k = 0
			l = j * pointsPerPixel
				do
					LIBCurrentWaveTemp[k] = LIBCurrentWave[l]
					k += 1
					l += 1
				while (k < pointsPerPixel)
		
			LIBCurrent[j][i] = mean(LIBCurrentWaveTemp)
			LIBCurrentConverted[j][i]=(LIBCurrent[j][i]*LIAsens/10.0)
			j += 1
		while (j < scanpoints)

		if(i>0)
			LIBCurrentTraceBefore=LIBCurrentTrace
		endif
		
		LIBCurrentTrace = LIBCurrent[p][i]
		LIBCurrentConvertedTrace  = LIBCurrentConverted[p][i]
		
		if (i < scanlines)		
			DoUpdate 
			td_stopInWaveBank(-1)
			//td_stopOutWaveBank(-1)
			td_stopoutwavebank(0)
		endif 
	
		//print "Time for last scan line (seconds) = ", (StopMSTimer(-2) -starttime2)*1e-6, " ; Time remaining (in minutes): ", ((StopMSTimer(-2) -starttime2)*1e-6*(scanlines-i-1)) / 60
		i += 1
		
		LIBCurrentWave[] = NaN
		
			
	while (i < scanlines )	
	
	if (error != 0)
		print "there was some setinoutwave error during this program"
	endif
	
	DoUpdate		

	td_StopInWaveBank(-1)
	td_StopOutWaveBank(-1)
	Beep
	setdatafolder savDF
End

Function ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
