#pragma rtGlobals=1		// Use modern global access method.

Function ResetAll()
// This function stops any feedback loops,
// wave banks, and resets all outputs to ground. 

	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	WAVE/T FIdx=root:Packages:trEFM:SavedFilterIndex
	WAVE PF=root:Packages:trEFM:SavedPassFilter
	WAVE BF=root:Packages:trEFM:SavedBandFilter
	WAVE/T DDSIdx=root:Packages:trEFM:SavedDDSIndex
	WAVE DDS=root:Packages:trEFM:SavedDDS
	WAVE/T XPTIdx=root:Packages:trEFM:SavedXPTIndex
	WAVE/T XPT=root:Packages:trEFM:SavedXPT
	GetGlobals()
	
	Variable xpos, ypos, i
	Variable XLVDTsens = GV("XLVDTSens")
	Variable YLVDTsens = GV("YLVDTSens")
	Variable XLVDToffset = GV("XLVDToffset")
	Variable YLVDToffset = GV("YLVDToffset")
	
	// Shutdown Feedback loops.
	StopFeedbackLoop(0)
	StopFeedbackLoop(1)
	StopFeedbackLoop(2)
	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
	
	// Get current xy location.
	xpos = (td_RV("XSensor") - td_rv("XLVDToffset")) * XLVDTsens * 1e6
	ypos = (td_RV("YSensor") - td_rv("YLVDToffset")) * YLVDTsens * 1e6
	MoveXY(xpos, ypos) // Raise the tip way far off the surface

	// Stop any In/Out wave banks that may be running.
	td_StopINWaveBank(-1)
	td_StopOUTWaveBank(-1)
	
	// Zero All outputs.
	td_WV("Output.A", 0)
	td_WV("Output.B", 0)

	
	//Reset all Filters
	Variable filterCount=10
	String passFilterString="%Pass Filter"
	String bandFilterString="%Band Filter"	

	for (i=0;i<filterCount;i+=1)
		td_wv(FIdx[i] + passFilterString,PF[i])
		td_wv(FIdx[i] + bandFilterString,BF[i])
	endfor
	
	//Reset DDS parameters
	for (i=0;i<11;i+=1)
		td_wv("Lockin." + DDSIdx[i],DDS[i])		
	endfor
	SetDataFolder savDF
	
End

Function SetCrosspoint (InA,InB,InFast,InAOffset,InBOffset,InFastOffset,OutXMod,OutYMod,OutZMod,FilterIn,BNCOut0,BNCOut1,BNCOut2,PogoOut,Chip,Shake)
//
// Function takes the required input settings and writes the appropriate string and wave
// Then it uses the Asylum functions to write them to the crosspoint switch
// Typical outputs: OutC = trigger, OutA = light, OutB = voltage. Note that if you connect the trigger to the output you should connect the light straight to ARC
//
	String InA,InB,InFast,InAOffset,InBOffset,InFastOffset,OutXMod,OutYMod,OutZMod,FilterIn,BNCOut0,BNCOut1,BNCOut2,PogoOut,Chip,Shake
	
	string SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:MFP3D:XPT:

	Make/T/O/N=16 Custom={InA,InB,InFast,InAOffset,InBOffset,InFastOffset,OutXMod,OutYMod,OutZMod,FilterIn,BNCOut0,BNCOut1,BNCOut2,PogoOut,Chip,Shake}

	XPTPopupFunc("LoadXPTPopup",17,"Custom")	
	XPTButtonFunc("WriteXPT")
	
	// To set crosspoint on Cypher
	if (exists("root:packages:MFP3D:XPT:Cypher:XPTLoad"))
		SetDataFolder root:packages:MFP3D:XPT:Cypher

		XPTPopupFunc("CypherBNCOut0Popup", 7, "ACDefl")
		XPTPopupFunc("CypherBNCOut1Popup", 7, "ACDefl")
		XPTPopupFunc("CypherHolderOut0Popup", 20, "ContChip")
		
		XPTBoxFunc("CypherXPTLock10Box_0", 1)
		XPTBoxFunc("CypherXPTLock11Box_0", 1)
		XPTBoxFunc("CypherXPTLock29Box_0", 1)

		XPTButtonFunc("WriteXPT")
		
	endif
	
	SetDataFolder SavedDataFolder
End

Function SetPassFilter(SetorReset, [x,y,z,a,b,fast,i,i1,q,q1])
//function sets the pass filter cutoff frequency on the input LPF to Asylum's ADC	
//the SetorReset parameter is 0 or 1, SetorReset==0 ignores ALL optional parms and resets to the globally stored values
// SetorReset==1 will set the Pass Filter for all optional parameters and leave unnamed channels alone
// EX: glSetPassFilter(0)  - will reset all pass filters to their stored values
//		glSetPassFilter(1,a=2000,i=20000) - will set the a%PassFilter and i%PassFilter to the specified values and leave
//				all other filters alone

	Variable SetorReset,x,y,z,a,b,fast,i,i1,q,q1

	String xFilter,yFilter,zFilter,aFilter,bFilter,fastFilter,iFilter,i1Filter,qFilter,q1Filter
	String FilterString
	Variable filterCount

	SetDataFolder root:packages:trEFM
	SVAR LockinString 
	
	FilterString = "ARC.Input."
	
	fastFilter = FilterString + "Fast.Filter.Freq"	
	
	if (strsearch(LockinString,"ARC",0) == -1)

		FilterString = "Cypher.Input."
		fastFilter = FilterString + "FastA.Filter.Freq"	
	
	endif	

	xFilter = FilterString + "X.Filter.Freq"
	yFilter =FilterString + "Y.Filter.Freq"
	zFilter = FilterString + "Z.Filter.Freq"	
	aFilter = FilterString + "A.Filter.Freq"
	bFilter = FilterString + "B.Filter.Freq"
	iFilter = LockinString + "Filter.Freq"
	i1Filter = "ARC.Lockin.1.Filter.Freq"
	qFilter = LockinString + "Filter.Freq"
	q1Filter = "ARC.Lockin.1.Filter.Freq"

	filterCount = 10
	
	variable error = 0

	if (SetorReset==1) // set those filters that are sent as function parameters
		if (!ParamIsDefault(x))
			error += td_wv(xFilter,x)
		endif
		if (!ParamIsDefault(y))
			error += td_wv(yFilter,y)
		endif
		if (!ParamIsDefault(z))
			error += td_wv(zFilter,z)
		endif
		if (!ParamIsDefault(a))
			error += td_wv(aFilter,a)
		endif
		if (!ParamIsDefault(b))
			error += td_wv(bFilter,b)
		endif
		if (!ParamIsDefault(fast))
			error += td_wv(fastFilter,fast)
		endif
		if (!ParamIsDefault(i))
			error += td_wv(iFilter,i)
		endif
		if (!ParamIsDefault(i1))
			error += td_wv(i1Filter,i1)
		endif
		if (!ParamIsDefault(q))
			error += td_wv(qFilter,q)
		endif
		if (!ParamIsDefault(q1))
			error += td_wv(q1Filter,q1)
		endif
	
	if (error != 0)
		print "Error in SetPassFilter = ", error
	endif
	
	else  // reset filters to the globally stored defaults
		
		WAVE/T FIdx=root:Packages:trEFM:SavedFilterIndex
		WAVE PF=root:Packages:trEFM:SavedPassFilter
		for (i=0;i<filterCount;i+=1)
			td_wv(FilterString + FIdx[i],PF[i])
		endfor
	endif

End
	
Function SetFeedbackLoop(whichLoop,startWhen,maintainWhat,setpoint,pgain,igain,sgain,changeWhat,dgain)
//
// Sets up a PIDS feedback loop. This function will set changeWhat to the setpoint by adjusting the value
// of maintainWhat. The user also must select the gain settings to be used by the PID.
//

	Variable whichLoop,setpoint,pgain,igain,sgain,dgain
	String startWhen,maintainWhat,changeWhat
	string SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM

	String Labels = ir_GetGroupLabels("PIDSloop.0")
	Variable nop = ItemsInList(Labels,";")
	Variable error
	
	String thisWave = "ARC.PISLoop" + num2str(whichLoop)
	String arWave = "ARC.PIDSLoop." + num2str(whichLoop)
		
	make/o/t/n=(nop) $thisWave
	SetDimLabels($thisWave,Labels,0)	
	WAVE/T curWave=$thisWave

	curWave[0] = maintainWhat
	curWave[1] = changeWhat
	
	if (IsNan(setpoint))
		curWave[2] = "yes"
	else
		curWave[2] = "no"
	endif
	
	curWave[3] = num2str(setpoint)
	curWave[4] = "0"
	curWave[5] = num2str(dgain)
	curWave[6] = num2str(pgain)		
	curWave[7] = num2str(igain)	
	curWave[8] = num2str(sgain)		 
	curWave[9] = "-inf"	
	curWave[10] = "inf"	
	curWave[11] = "Never"
	curWave[12] = "Never"
	curWave[13] = "0"
		
	
	//error=td_writeGroup(arWave,curWave)
	curWave[11] = startWhen
	error=td_writeGroup(arWave,curWave)
	
	SetDataFolder SavedDataFolder
	
	return error
	
End
Function SetFeedbackLoopCypher(whichLoop,startWhen,maintainWhat,setpoint,pgain,igain,sgain,changeWhat,dgain)
//
// Sets up a PIDS feedback loop. This function will set changeWhat to the setpoint by adjusting the value
// of maintainWhat. The user also must select the gain settings to be used by the PID.
//

	Variable whichLoop,setpoint,pgain,igain,sgain,dgain
	String startWhen,maintainWhat,changeWhat
	string SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM

	String Labels = ir_GetGroupLabels("Cypher.PIDSloop.1")
	Variable nop = ItemsInList(Labels,";")
	Variable error
	
	String thisWave = "Cypher.PISLoop" + num2str(whichLoop)
	String arWave = "Cypher.PIDSLoop." + num2str(whichLoop)
		
	make/o/t/n=(nop) $thisWave
	SetDimLabels($thisWave,Labels,0)	
	WAVE/T curWave=$thisWave

	curWave[0] = maintainWhat
	curWave[1] = changeWhat
	
	if (IsNan(setpoint))
		curWave[2] = "yes"
	else
		curWave[2] = "no"
	endif
	
	curWave[3] = num2str(setpoint)
	curWave[4] = "0"
	curWave[5] = num2str(dgain)
	curWave[6] = num2str(pgain)		
	curWave[7] = num2str(igain)	
	curWave[8] = num2str(sgain)		 
	curWave[9] = "-inf"	
	curWave[10] = "inf"	
	curWave[11] = "Never"
	curWave[12] = "Never"
	curWave[13] = "0"
		
	
	//error=td_writeGroup(arWave,curWave)
	curWave[11] = startWhen
	error=td_writeGroup(arWave,curWave)
	
	SetDataFolder SavedDataFolder
	
	return error
	
End

Function StopFeedbackLoop(whichLoop)
//
// Given an integer number corresponding to one of the 5 feedback loops, this function stops the specified feedback loop.
//
	Variable whichLoop
	String thisLoop
	Variable error, i
	
	if (whichLoop == -1)
		for (i = 0; i < 6; i += 1)
			thisLoop = "PIDSLoop." + num2str(i) + ".Status"
			error = td_WriteValue(thisLoop, -1)			
		endfor
	else
		thisLoop = "PIDSLoop." + num2str(whichLoop) + ".Status"
		error = td_WriteValue(thisLoop, -1)
	endif
	
	if (error > 0)	
		printf "Error in StopFeedbackLoop: %g\r", error
	endif
	
	return error
End

Function StopFeedbackLoopCypher(whichLoop)
//
// Given an integer number corresponding to one of the 5 feedback loops, this function stops the specified feedback loop.
//
	Variable whichLoop
	String thisLoop
	Variable error, i
	
	if (whichLoop == -1)
		for (i = 0; i < 6; i += 1)
			thisLoop = "Cypher.PIDSLoop." + num2str(i) + ".Status"
			error = td_WriteValue(thisLoop, -1)			
		endfor
	else
		thisLoop = "Cypher.PIDSLoop." + num2str(whichLoop) + ".Status"
		error = td_WriteValue(thisLoop, -1)
	endif
	
	if (error > 0)	
		printf "Error in StopFeedbackLoop: %g\r", error
	endif
	
	return error
End


///////////////////////////////////////////////////////////////////////////////////////////
//  MOVEMENT FUNCTIONS
/////////////////////////////////////////////////////////////////////////////////////	
Function ReadPosition()
//
// Prints the current X, Y, and Z position to the console
//
	string SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	Variable XLVDToffset, YLVDToffset, ZLVDToffset
	Variable	XLVDTsens,YLVDTsens,ZLVDTsens
	GetGlobals()  //ensures values from Asylum panel are current
	
	XLVDToffset = GV("XLVDToffset")
	YLVDToffset = GV("YLVDToffset")
 	ZLVDToffset = GV("ZLVDToffset")
 	
 	XLVDTsens = GV("XLVDTSens")
	YLVDTsens = GV("YLVDTSens")
 	ZLVDTsens = GV("ZLVDTSens")
	variable aX ,aY, aZ//, a5

	ax= (td_readvalue("XSensor")-XLVDToffset)*XLVDTSens*1e6 //read x position of end of line
	ay=(td_readvalue("YSensor")-YLVDToffset)*yLVDTSens*1e6 //read y position of end of line
	az= td_readvalue("ZSensor")*ZLVDTSens*1e6 //read z position of end of line
	print "(",ax,",",ay,",",az,")"
	
	SetDataFolder SavedDataFolder
		
End
//////////////////////////////////////////////////////////////////////////////////////	

///////////////////////////////////////////////////////////////////////////////////////////
Function MoveXYZ(Xposition, Yposition,Zposition)
// a function that moves the xy stage to the desired position (given in microns)
	variable Xposition, Yposition, zposition
	WAVE EFMFilters=root:Packages:trEFM:EFMFilters
	variable a2,a4
	variable XLVDTSens = GV("XLVDTSens")
	variable YLVDTSens = GV("YLVDTSens")
	variable XLVDToffset = GV("XLVDToffset")
	variable YLVDToffset = GV("YLVDToffset")
	variable ZLVDTSensScaled = GV("ZLVDTSens")*1e6
	
	a2= (td_readvalue("XSensor")-XLVDToffset)*XLVDTSens*1e6 //read x position of end of line
	a4= (td_readvalue("YSensor")-yLVDToffset)*yLVDTSens*1e6 //read x position of end of line
	
	xposition = ((Xposition*1e-6)/abs(XLVDTSens))
	yposition = ((yposition*1e-6)/abs(yLVDTSens))
	
	SetFeedbackLoop(2, "always",  "ZSensor", Zposition/ZLVDTSensScaled,EFMFilters[%ZHeight][%PGain],EFMFilters[%ZHeight][%IGain],0, "Output.Z",EFMFilters[%ZHeight][%DGain])

	//continuouslined(Xposition,Yposition,30,-10, -10) //move to (Xposition,Yposition)
	GoToSpot(XYPos=Cmplx(xposition,yposition))

	td_WriteValue("PIDSLoop.2.Setpoint", zposition)
	
	//StopFeedbackLoop(0)
	//StopFeedbackLoop(1)	
End
//////////////////////////////////////////////////////////////////////////////////////////

Function MoveXY(xpos, ypos)
// Moves to the X,Y position while keeping the tip withdrawn away from the surface.
	Variable xpos, ypos
	variable XLVDTSens = GV("XLVDTSens")
	variable YLVDTSens = GV("YLVDTSens")
	
	Variable XLVDTOffset, YLVDTOffset
	XLVDTOffset = GV("XLVDTOffset")
	YLVDTOffset = GV("YLVDTOffset")
	
	// Convert positions to voltages.
	xpos = ((Xpos*1e-6)/abs(XLVDTSens))
	ypos = ((ypos*1e-6)/abs(yLVDTSens))
	
	// Withdraw the tip.
	if( td_ReadValue("Height"))
		DoScanFunc("Withdraw")
	endif
	
	if (IsNan(YLVDTOffset))
		YLVDTOffset = 0
	endif
	if (IsNan(XLVDToffset))
		XLVDTOffset = 0
	endif
	
	// Set the PIDS loops for X and Y stage movement.
	Struct ARFeedbackStruct FB
	ARGetFeedbackParms(FB,"outputX")
	FB.PGain = 0
	FB.SGain = 0
	IR_WritePIDSloop(FB)
	
	ARGetFeedbackParms(FB,"outputY")
	FB.PGain = 0
	FB.SGain = 0
	IR_WritePIDSloop(FB)
	
	Variable XEnd, YEnd
	XEnd = xpos + XLVDTOffset
	YEnd = ypos + YLVDTOffset
	
	
	// Ramp to the desired position.
	variable ScanSpeed = GV("ScanSpeed")
	td_SetRamp(10,"$outputXLoop.Setpoint",max(scanSpeed/abs(xLVDTSens),2),xEnd,"$outputYLoop.Setpoint",max(scanSpeed/abs(yLVDTSens),2),yEnd,"",0,0,"")
End

Function LiftTo(liftHeight,tipVoltage,[lighton])
	Variable liftHeight, tipVoltage,lighton
	SetDataFolder root:packages:trefm

	Wave EFMFilters
	NVAR setpoint, pgain, sgain,igain
	SVAR LockinString
	
	NVAR calsoftd = root:packages:trEFM:VoltageScan:calsoftd
	Nvar calresfreq  = root:packages:trEFM:VoltageScan:calresfreq
	NVAR calphaseoffset = root:packages:trEFM:VoltageScan:calphaseoffset
	NVAR calengagefreq = root:packages:trEFM:VoltageScan:calengagefreq
	NVAR calhardd = root:packages:trEFM:VoltageScan:calhardd
	
	SetCrosspoint("FilterOut", "Ground", "ACDefl", "Ground", "Ground", "Ground", "Off", "Off", "Off", "Defl", "Ground", "OutA", "OutB", "Ground", "OutB", "DDS")

	// Find surface
	td_WV((LockinString + "Amp"), calhardd)
	td_WV(LockinString + "Freq", calengagefreq)
	td_WV(LockinString + "PhaseOffset", calphaseoffset)
	SetFeedbackLoop(2, "Always", LockinString +"R", setpoint, -pgain, -igain, -sgain, "Output.Z", 0)
	
	Sleep/s 1
	readposition()
	
	// Lift the tip to the desired lift height.
	Variable z1= td_readvalue("ZSensor") * GV("ZLVDTSens")	
	StopFeedbackLoop(2)
	SetFeedbackLoop(3, "always",  "ZSensor", (z1 - liftHeight * 1e-9) / GV("ZLVDTSens"), 0,  EFMFilters[%ZHeight][%IGain], 0, "Output.Z", 0)

	Sleep/s 1
	readposition()

	td_wv("Output.B", tipVoltage)
	if (!ParamIsDefault(lighton) )
		td_wv("Output.A", 5)
	endif

end

Function CheckInWaveTiming(whichWave,[whichDataPoint])

	// this function checks a specifiec data point in the named inWave and continues to run
	// until that data point has a value. It is used to ensure that the function calling it runs 
	// until all required data has been collected.
	// If whichDataPoint is specified then the function checks that, otherwise it checks the last data point
	// NOTES: This fxn assumes the passed wave is currently set to NaN, whichDataPoint is the integer index to
	//	the data point you want to key on
		
	Wave whichWave
	Variable whichDataPoint
	Variable k
	
	if (ParamIsDefault(whichDataPoint))
		whichDataPoint = numpnts(whichWave)-1
	endif

	k=0
	
	
	do
		Sleep/S .001
		if (!IsNan(whichWave[whichDataPoint]))
			k+=1
		endif

	while (k<1)

End

Function LightOnOff(onoff)
//
// turns the LED on or off (1 or 0).
//
	Variable onoff
	
	SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Defl","OutC","OutA","OutB","Ground","OutB","DDS")

	if(onoff == 0)
		td_WV("Output.A", 0)
	elseif(onoff == 1)
		td_WV("Output.A", 5)
	endif
	
End

function wavegenerator(amplitude,frequency,outputletter,event,bank)

	variable amplitude,frequency,bank
	string outputletter,event
	variable length, interpolation 
	
	if (frequency>=10)
		length= 10000*10/frequency- mod(10000*10/frequency,1)
		interpolation =1
	endif
	if (frequency<10)
		length= 100
		interpolation = 1000/frequency- mod(1000/frequency,1)
	endif
		
	make/o/n=(length) basewave1
	
	td_stopoutwavebank(bank)
	
	basewave1[0,length/2-1]= amplitude/2 // for square waves
	basewave1[length/2,length-1]= -amplitude/2	
		
	td_xsetoutwave(bank, event, outputletter, basewave1,interpolation) //note with C%ouput we can't go faster than 78hz
	
	//Daviiid, change from Event.2 to Event.1
	//td_WriteString("Event.2", "Once")
	td_WriteString("Event.1", "Once")
	
end

function wavegeneratoroffset(amplitude,frequency,outputletter,event,bank)

	variable amplitude,frequency,bank
	string outputletter,event
	variable length, interpolation 
	
	if (frequency>=10)
		length= 10000*10/frequency- mod(10000*10/frequency,1)
		interpolation =1
	endif
	if (frequency<10)
		length= 100
		interpolation = 1000/frequency- mod(1000/frequency,1)
	endif
		
	make/o/n=(length) basewave1
	
	td_stopoutwavebank(bank)
	
	basewave1[0,length/2-1]= 0 // for square waves
	basewave1[length/2,length-1]= amplitude	
		
	td_xsetoutwave(bank, event, outputletter, basewave1,interpolation) //note with C%ouput we can't go faster than 78hz
	
	//Daviiid, change from Event.2 to Event.1
	//td_WriteString("Event.2", "Once")
	td_WriteString("Event.1", "Once")
	
end