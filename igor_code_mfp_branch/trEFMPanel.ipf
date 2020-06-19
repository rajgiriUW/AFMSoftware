#define ARrtGlobals
#Ifdef ARrtGlobals
#pragma rtGlobals=1        // Use modern global access method.
#else
#pragma rtGlobals=3        // Use strict wave reference mode
#endif 
#include ":AsylumResearch:Code3D:Initialization"


StartMeUp()
	

Function LightOnButton(ctrlname) : ButtonControl

	String ctrlname
	NVAR lightOn = root:packages:trEFM:LightOn
	
	if (LightOn == 0)
		LightOn = 5
		Button button10, title = "LED is ON"
		Button button10 fColor=(65280,21760,0)
		LightOnOff(1)
	elseif (LightOn == 5)
		LightOn = 0
		Button button10, title = "LED is OFF"
		Button button10 fColor=(0,0,0)
		LightOnOff(0)
	endif
	
End

Function EditGainsButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	Wave EFMFilters
	
	Edit/K=1 EFMFilters.ld
	
	SetDataFolder savDF
	
End

Function FitShiftWaveAvgButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:PointScan:trEFM
	Wave shiftwaveavg
	Wave timekeeper
	
	NVAR fitstarttime = root:packages:trEFM:ImageScan:fitstarttime	
	NVAR fitstoptime = root:packages:trEFM:ImageScan:fitstoptime
	
	if (strlen(csrinfo(A)) == 0)
		Cursor A shiftwaveavg fitstarttime/0.02
	endif
	
	if (strlen(csrinfo(B)) == 0)
		Cursor B shiftwaveavg fitstoptime/0.02
	endif
	
	CurveFit/Q/M=2/W=0 exp_XOffset, root:packages:trEFM:PointScan:trEFM:shiftwaveavg[pcsr(A),pcsr(B)]/X=root:packages:trEFM:PointScan:timekeeper[pcsr(A),pcsr(B)]/D
	Wave W_coef
	print W_coef[2]
	
	SetDataFolder savDF
	
End

Function AnalysisSettingsButton(ctrlname) : ButtonControl

	String ctrlname
	String saveDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM:FFtrEFMConfig
	
	
	SetDataFolder root:Packages:trEFM:ImageScan
	Nvar DigitizerTime, DigitizerPercentPreTrig, DigitizerPreTrigger, DigitizerSamples
	Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
	
	PIXELCONFIG[%Total_Time] = DigitizerTime * 1e-3
	PIXELCONFIG[%Trigger] = (1-DigitizerPercentPreTrig/100) * DigitizerTime * 1e-3
	
	Edit/K=1 'PIXELCONFIG'.ld
	SetDataFolder saveDF
	
End

Function OneOrTwoChannelsCHeckBox(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	NVAR OneOrTwoChannels = root:packages:trEFM:ImageScan:OneorTwoChannels
	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			OneOrTwoChannels = checked
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function UpdateConf()
	
end


Function LightOffButton(ctrlname) : ButtonControl

	String ctrlname
	LightOnOff(0)
	
End

Function GrabTuneButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM:VoltageScan
	Nvar softamplitude

	SaveHardwareSettings() 	// copy default parameters over

	svar LockInString = root:packages:trEFM:LockinString
	if( stringmatch(LockInString,"Cypher.LockinA.0."))
		Abort "Swtich to ARC Lockin"
	endif
	
	GrabTune(softamplitude)
	GetCurrentPosition()
	SetDataFolder savDF
	
	return 0
	
End

Function VoltageScanButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	SetDataFolder root:Packages:trEFM
	NVAR liftheight
	nvar gxpos, gypos

	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	
	SetDataFolder root:Packages:trEFM:VoltageScan
	Nvar vmin, vmax, npoints
	
	if( vmin == -10 && vmax == 10 && npoints == 85)
		VoltageScan(gxpos, gypos, liftheight)
	else

		VoltageScan(gxpos, gypos, liftheight, vmin =  vmin, vmax = vmax, npoints = npoints)

	endif
	GetCurrentPosition()
	DoWindow/F VoltageScanWindow
	wave phasewave = root:packages:trEFM:VoltageScan:phasewave
	wave voltagewave = root:packages:trEFM:VoltageScan:voltagewave
	if(v_flag == 0)
		display/l/K=1/b/N=VoltageScanWindow phasewave vs voltagewave 
			
		Label/W=VoltageScanWindow bottom "Applied Voltage (Volts)"
		Label/W=VoltageScanWindow left "Frequency Shift (Hz)"
					
		ModifyGraph/W=VoltageScanWindow lsize=4,rgb=(0,39168,0)
		ModifyGraph/W=VoltageScanWindow fStyle=1,fSize=14
		ModifyGraph/W=VoltageScanWindow gbRGB = (65535,65535,65535)
		ModifyGraph/W=VoltageScanWindow wbRGB = (65535,65535,65535)
		ModifyGraph/W=VoltageScanWindow mode=2,lsize(Phasewave) = 6
	endif
	
	SetDataFolder savDF

End

Function HeightScanButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	SetDataFolder root:Packages:trEFM
	Nvar gxpos, gypos
	
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	
	SetDataFolder root:Packages:trEFM:HeightScan
	Nvar zmin, zmax, znpoints, voltage
	
	if( zmin == -10 && zmax == 60 && znpoints == 10)

		HeightScan(gxpos,gypos, voltage)
	else

		HeightScan(gxpos, gypos, voltage, zmin = zmin, zmax = zmax, npoints = znpoints)
	endif

	GetCurrentPosition()
	DoWindow/F HeightScanWindow
	if(V_Flag == 0)
		display/l/K = 1/b/N = HeightScanWindow shiftwave vs readheight
			
		Label/W = HeightScanWindow bottom "Height Above Surface (nm)"
		Label/W = HeightScanWindow left "Frequency Shift (Hz)"	
				
		ModifyGraph/W = HeightScanWindow lsize=4,rgb=(0,39168,0)
		ModifyGraph/W = HeightScanWindow fStyle=1,fSize=14
		ModifyGraph/W = HeightScanWindow gbRGB= (65535,65535,65535)
		ModifyGraph/W = HeightScanWindow wbRGB= (65535,65535,65535)
		ModifyGraph/W = HeightScanWindow mode=2,lsize(shiftwave)=6
	endif
	SetDataFolder savDF

End


Function EditTipWaveButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	Nvar WavesCommitted
	SetDataFolder root:Packages:trEFM:WaveGenerator
	
	VoltageWaveEditor()
	WavesCommitted = 0
	SetDataFolder savDF
	
End

Function EditLightWaveButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	Nvar WavesCommitted
	SetDataFolder root:Packages:trEFM:WaveGenerator
	
	LightWaveEditor()
	WavesCommitted = 0
	SetDataFolder savDF
	
End

Function EditRingDownWaveButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	Nvar WavesCommitted
	SetDataFolder root:Packages:trEFM:WaveGenerator
	
	RingDownWaveEditor()
	WavesCommitted = 0
	SetDataFolder savDF
	
End

Function EditTriggerWaveButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	Nvar WavesCommitted
	SetDataFolder root:Packages:trEFM:WaveGenerator
	
	TriggerWaveEditor()
	WavesCommitted = 0
	SetDataFolder savDF
	
End

Function RecomButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	SetDataFolder root:Packages:trEFM:WaveGenerator
	
	Wave GenTriggerWaveTemp = root:Packages:trEFM:WaveGenerator:gentriggerwaveTemp
	Wave GenLightWaveTemp = root:Packages:trEFM:WaveGenerator:genlightwaveTemp

	// Find when Light wave goes to 0
	PulseStats/Q/L=(5, 0) genlightwavetemp
	variable trig = V_PulseLoc2 

	gentriggerwavetemp[0, x2pnt(gentriggerwavetemp, trig)] = 0
	gentriggerwavetemp[x2pnt(gentriggerwavetemp, trig+1e-5), x2pnt(gentriggerwavetemp, trig+3e-3)] = 5
	gentriggerwavetemp[x2pnt(gentriggerwavetemp, trig+3e-3), *] = 0
	variable scale = dimdelta(genlightwavetemp, 0)
	SetScale/P x, 0, 2e-5, gentriggerwavetemp

	Button button4, title = "---> CHARGE", proc = Chargebutton
	
	SetDataFolder root:packages:trEFM:FFtrEFMConfig
	Wave PixelConfig
	PixelConfig[%recombination] = 1
	TrigPol(0) // sets trigger box
	
	Print "Set for recombination experiment"

	SetDataFolder savDF
	
End

Function LightOnOrOffButton(ctrlname): ButtonControl
	string ctrlname
	
	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	nvar LightOn
	
	if (Lighton == 5)
		LightOn = 0
		Button LightOnOrOff, title= "Light is Off"
	else
		LightOn = 5
		Button LightOnOrOff, title= "Light is On"
	endif
	
end

Function ChargeButton(ctrlname): ButtonControl
	string ctrlname
	
	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	SetDataFolder root:Packages:trEFM:WaveGenerator
	
	Wave GenTriggerWaveTemp = root:Packages:trEFM:WaveGenerator:gentriggerwaveTemp
	Wave GenLightWaveTemp = root:Packages:trEFM:WaveGenerator:genlightwaveTemp

	// Find when Light wave goes to 0
	PulseStats/Q/L=(5, 0) genlightwavetemp
	variable trig = V_PulseLoc1

	// Set trigger wave to match
	gentriggerwavetemp[0, x2pnt(gentriggerwavetemp, trig)] = 0
	gentriggerwavetemp[x2pnt(gentriggerwavetemp, trig+1e-5), x2pnt(gentriggerwavetemp, trig+3e-3)] = 5
	gentriggerwavetemp[x2pnt(gentriggerwavetemp, trig+3e-3), *] = 0
	variable scale = dimdelta(genlightwavetemp, 0)
	SetScale/P x, 0, 2e-5, gentriggerwavetemp

	Button button4, title = "---> RECOM", proc = Recombutton
	
	// set up FF-trEFM PixelConfig and write to trigger box
	SetDataFolder root:packages:trEFM:FFtrEFMConfig
	Wave PixelConfig
	PixelConfig[%recombination] = 0
	TrigPol(1) // sets trigger box
	
	Print "Set for charging experiment"
	
	// correct trEFM fit times
	NVAR fitstarttime = root:packages:trEFM:ImageScan:fitstarttime	
	NVAR fitstoptime = root:packages:trEFM:ImageScan:fitstoptime
	
	fitstarttime = floor(V_PulseLoc1*1000)
	fitstoptime = floor(V_PulseLoc1*1000) + 2.5

	SetDataFolder savDF
	
end

Function MultiplePointScan()

	String savDF = GetDataFolder(1)
	
	Wave timekeeper=root:Packages:trEFM:PointScan:timekeeper
	
	SetDataFolder root:Packages:trEFM:WaveGenerator
	Wave gentriggerwaveTemp, gentipwaveTemp
	Nvar numcycles
	
	Variable savecycles = numcycles
	Variable numofscans = floor(numcycles / 100) // Number of scans to do before any remainder.
	Variable additionalAverages = mod(numcycles, 100) //remaining averages to be done in last point scan.
	Variable totalscans = numofscans
	
	if(additionalAverages > 0)
		totalscans += 1
	endif
	
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	variable ex,why
	ex = gxpos
	why = gypos
	SetDataFolder root:Packages:trEFM:PointScan:trEFM
	Make/O/N = 800 multshiftwave
	Wave shiftwaveavg
	numcycles = 100
	Variable i
	multshiftwave = 0
	for(i = 0; i < numofscans; i += 1)
	
		print "Point scan", i+1, "of", totalscans
		PointScantrEFM(gxpos, gypos, liftheight)
		multshiftwave += shiftwaveavg
		GetCurrentPosition()
		
	endfor

	if(additionalAverages > 0)
	
		print "Point scan", totalscans , "of", totalscans
		numcycles = additionalAverages
		PointScantrEFM(gxpos, gypos, liftheight)
		multshiftwave += shiftwaveavg
		
	endif
	
	for(i=0; i < 800; i+=1)
		multshiftwave[i] /= totalscans
	endfor
	numcycles = savecycles
	
	Dowindow/f MultPointScanWindow
	
	if (V_flag ==0)
		Display/W=(406.5,53,1155.75,488)/n=MultPointScanWindow/K=1  multshiftwave vs timekeeper
		AppendToGraph/R=newaxis gentriggerwaveTemp vs timekeeper
		AppendToGraph/R gentipwaveTemp vs timekeeper
		ModifyGraph margin(right)=144,wbRGB=(65535,65535,65535),gbRGB=(65535,65535,65535)
		ModifyGraph lSize=2
		ModifyGraph rgb(multshiftwave)=(0,0,0)
		ModifyGraph rgb(gentriggerwaveTemp) = (65280, 0,0)
		ModifyGraph rgb(gentipwaveTemp) = (0, 0,65280)
		ModifyGraph mirror(bottom)=1
		ModifyGraph fSize=14
		ModifyGraph fStyle=1
		ModifyGraph axThick=1
		ModifyGraph axRGB(left)=(0,0,0),tlblRGB(left)=(0,0,0),alblRGB(left)=(0,0,0)
		ModifyGraph axRGB(right)=(0,0,65280),tlblRGB(right)=(0,0,65280);DelayUpdate
		ModifyGraph alblRGB(right)=(0,0,65280)
		ModifyGraph axRGB(newaxis)=(65280,0,0),tlblRGB(newaxis)=(65280,0,0);DelayUpdate
		ModifyGraph alblRGB(newaxis)=(65280,0,0)
		ModifyGraph lblPos(right)=51,lblPos(newaxis)=45
		ModifyGraph freePos(newaxis)=72.75
		Label left "Frequency Offset (Hz)"
		Label bottom "Time (S)"
		Label right "Voltage Wave Input"
		Label newaxis "Light Wave Input"
		TextBox/C/N=text0/V=0 ""
		ReorderTraces multshiftwave,{gentipwaveTemp,gentriggerwaveTemp}
	endif


	SetDataFolder savDF
	
End
Function trEFMPointScanButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	SetDataFolder root:Packages:trEFM:WaveGenerator
	Wave gentipwaveTemp, gentriggerwaveTemp
	Nvar numcycles
	
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	Nvar WavesCommitted
	
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	
	if(numcycles > 100)
	
		DoAlert 1, "More than 100 averages has been selected. Performing multiple Point Scans. Cool?"
		
		if (V_flag == 2)
			Abort
		endif
		
		MultiplePointScan()
		Abort
		
	endif
	
	NVAR CutDrive, CutPreV
	
	if (CutDrive == 1)
		print "CutDrive"
	endif
	
	PointScantrEFM(gxpos, gypos, liftheight)
	GetCurrentPosition()
	
	SetDataFolder root:Packages:trEFM:WaveGenerator
	Wave gentipwaveTemp, gentriggerwaveTemp, genlightwaveTemp
	
	SetDataFolder root:Packages:trEFM:PointScan:trEFM
	Wave timekeeper=root:Packages:trEFM:PointScan:timekeeper
	
	Dowindow/f PointScanWindow
	
	if (V_flag ==0)
		Display/W=(406.5,53,1155.75,488)/n=PointScanWindow/K=1  shiftwaveavg vs timekeeper
		AppendToGraph/R=newaxis gentriggerwaveTemp vs timekeeper
		AppendToGraph/R gentipwaveTemp vs timekeeper
		AppendToGraph/R=newaxis2 genlightwaveTemp vs timekeeper
		ModifyGraph margin(right)=144,wbRGB=(65535,65535,65535),gbRGB=(65535,65535,65535)
		ModifyGraph lSize=2
		ModifyGraph rgb(shiftwaveavg)=(0,0,0)
		ModifyGraph rgb(gentriggerwaveTemp) = (65280, 0,0)
		ModifyGraph rgb(gentipwaveTemp) = (0, 0,65280)
		ModifyGraph rgb(genlightwaveTemp) = (0, 52224, 0)
		Modifygraph lstyle(gentriggerwaveTemp) = 3
		Modifygraph lSize(gentriggerwaveTemp) = 4

		ModifyGraph mirror(bottom)=1
		ModifyGraph fSize=14
		ModifyGraph fStyle=1
		ModifyGraph axThick=1
		ModifyGraph axRGB(left)=(0,0,0),tlblRGB(left)=(0,0,0),alblRGB(left)=(0,0,0)
		ModifyGraph axRGB(right)=(0,0,65280),tlblRGB(right)=(0,0,65280);DelayUpdate
		ModifyGraph alblRGB(right)=(0,0,65280)
		ModifyGraph axRGB(newaxis)=(65280,0,0),tlblRGB(newaxis)=(65280,0,0);DelayUpdate
		ModifyGraph alblRGB(newaxis)=(65280,0,0)
		ModifyGraph tlblRGB(newaxis2)=(0,52224,0),alblRGB(newaxis2)=(0,52224,0);DelayUpdate
		ModifyGraph axThick(newaxis2)=2,freePos(newaxis2)=179,axRGB(newaxis2)=(0,52224,0); DelayUpdate
		ModifyGraph tlblRGB(newaxis2)=(0,52224,0),alblRGB(newaxis2)=(0,52224,0);DelayUpdate
		ModifyGraph margin(right)=216
	
		ModifyGraph lblPos(right)=51,lblPos(newaxis)=45, lblPos(newaxis2) = 50
		ModifyGraph freePos(newaxis)=72.75
		ModifyGraph freePos(newAxis2) = 150
		Label left "Frequency Offset (Hz)"
		Label bottom "Time (S)"
		Label right "Voltage Wave Input (BNC2)"
		Label newaxis "Trigger Wave Input (BNC0)"
		Label newaxis2 "Light Wave Input (BNC1)"
		TextBox/C/N=text0/V=0 ""
		ReorderTraces shiftwaveavg,{gentipwaveTemp,gentriggerwaveTemp}
		
		if (waveexists(root:packages:trEFM:WaveGenerator:genDriveWaveTemp))
			AppendToGraph/R=cutdriver root:packages:trEFM:WaveGenerator:genDriveWaveTemp vs root:packages:trEFM:PointScan:timekeeper
			ModifyGraph margin(right)=288
			ModifyGraph fStyle=1,fSize=14,axThick=3,tickUnit(cutdriver)=1;DelayUpdate
			ModifyGraph prescaleExp(cutdriver)=3,freePos(cutdriver)=230;DelayUpdate
			ModifyGraph axRGB(cutdriver)=(65280,43520,0),tlblRGB(cutdriver)=(65280,43520,0);DelayUpdate
			ModifyGraph alblRGB(cutdriver)=(65280,43520,0);DelayUpdate
			ModifyGraph lstyle(genDriveWaveTemp)=4
			ModifyGraph lsize(genDriveWaveTemp)=4,rgb(genDriveWaveTemp)=(65280,43520,0)
			Label cutdriver "Drive Amplitude, AMP signal (mV)"
		endif

	endif
	
	SetDataFolder savDF	
	
End

Function RingDownPointScanButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	SetDataFolder root:Packages:trEFM:WaveGenerator
	Wave gentipwaveTemp, gentriggerwaveTemp
	Nvar numcycles
	
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	Nvar WavesCommitted
	
	svar LockInString = root:packages:trEFM:LockinString
	if( stringmatch(LockInString,"Cypher.LockinA.0."))
		Abort "Swtich to ARC Lockin"
	endif
	
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	
	if(numcycles > 100)
	
		DoAlert 1, "More than 100 averages has been selected. Performing multiple Point Scans. Cool?"
		
		if (V_flag == 2)
			Abort
		endif
		
		MultiplePointScan()
		Abort
		
	endif
	
	PointScanRingDown(gxpos, gypos, liftheight)
	GetCurrentPosition()
	
	SetDataFolder root:Packages:trEFM:WaveGenerator
	Wave gentipwaveTemp, gentriggerwaveTemp, genlightwaveTemp
	
	SetDataFolder root:Packages:trEFM:PointScan:trEFM
	Wave timekeeper=root:Packages:trEFM:PointScan:timekeeper
	
	Dowindow/f PointScanWindow
	
	if (V_flag ==0)
		Display/W=(406.5,53,1155.75,488)/n=PointScanWindow/K=1  shiftwaveavg vs timekeeper
		AppendToGraph/R=newaxis gentriggerwaveTemp vs timekeeper
		AppendToGraph/R gentipwaveTemp vs timekeeper
		AppendToGraph/R=newaxis2 genlightwaveTemp vs timekeeper
		ModifyGraph margin(right)=144,wbRGB=(65535,65535,65535),gbRGB=(65535,65535,65535)
		ModifyGraph lSize=2
		ModifyGraph rgb(shiftwaveavg)=(0,0,0)
		ModifyGraph rgb(gentriggerwaveTemp) = (65280, 0,0)
		ModifyGraph rgb(gentipwaveTemp) = (0, 0,65280)
		ModifyGraph rgb(genlightwaveTemp) = (0, 52224, 0)
		Modifygraph lstyle(gentriggerwaveTemp) = 3
		Modifygraph lSize(gentriggerwaveTemp) = 4

		ModifyGraph mirror(bottom)=1
		ModifyGraph fSize=14
		ModifyGraph fStyle=1
		ModifyGraph axThick=1
		ModifyGraph axRGB(left)=(0,0,0),tlblRGB(left)=(0,0,0),alblRGB(left)=(0,0,0)
		ModifyGraph axRGB(right)=(0,0,65280),tlblRGB(right)=(0,0,65280);DelayUpdate
		ModifyGraph alblRGB(right)=(0,0,65280)
		ModifyGraph axRGB(newaxis)=(65280,0,0),tlblRGB(newaxis)=(65280,0,0);DelayUpdate
		ModifyGraph alblRGB(newaxis)=(65280,0,0)
		ModifyGraph tlblRGB(newaxis2)=(0,52224,0),alblRGB(newaxis2)=(0,52224,0);DelayUpdate
		ModifyGraph axThick(newaxis2)=2,freePos(newaxis2)=179,axRGB(newaxis2)=(0,52224,0); DelayUpdate
		ModifyGraph tlblRGB(newaxis2)=(0,52224,0),alblRGB(newaxis2)=(0,52224,0);DelayUpdate
		ModifyGraph margin(right)=216
	
		ModifyGraph lblPos(right)=51,lblPos(newaxis)=45, lblPos(newaxis2) = 50
		ModifyGraph freePos(newaxis)=72.75
		ModifyGraph freePos(newAxis2) = 150
		Label left "Frequency Offset (Hz)"
		Label bottom "Time (S)"
		Label right "Voltage Wave Input (BNC2)"
		Label newaxis "Trigger Wave Input (BNC0)"
		Label newaxis2 "Light Wave Input (BNC1)"
		TextBox/C/N=text0/V=0 ""
		ReorderTraces shiftwaveavg,{gentipwaveTemp,gentriggerwaveTemp}
	endif
	
	SetDataFolder savDF	
	
End

Function trEFMImageScanButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	SetDataFolder root:Packages:trEFM:ImageScan
	Nvar scansizex, scansizey, scanlines, scanpoints, scanspeed, numavgsperpoint, xoryscan, fitstarttime, fitstoptime
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	Nvar WavesCommitted
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	
	ImageScantrEFM(gxpos, gypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, numavgsperpoint, xoryscan,fitstarttime,fitstoptime)
	//ImageScanNItrEFM(gxpos, gypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, numavgsperpoint, xoryscan,fitstarttime,fitstoptime)
	GetCurrentPosition()
	SetDataFolder savDF
	
	
End

Function FFtrEFMImageScanButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	
	SetDataFolder root:Packages:trEFM:ImageScan
	Nvar scansizex, scansizey, scanlines, scanpoints, scanspeed, numavgsperpoint, xoryscan, fitstarttime, fitstoptime
	NVAR DigitizerAverages, DigitizerSamples, DigitizerPretrigger, DigitizerSampleRate, DigitizerTime
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	
	Nvar WavesCommitted
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif

	// Check is settings exceed 75 MB. Needed to avoid saturating the Gage Card
	if (DigitizerSampleRate * DigitizerTime * 1e-3 * numavgsperpoint * scanpoints > 70e6)
		variable fileSpaceOption = 0 
		Prompt fileSpaceOption, "These settings near/over 75 MB limit! Continue?"
			DoPrompt ">>>",fileSpaceOption
				If(V_flag==1)
					abort			//Aborts if you cancel the save option
				endif
	endif

	ImageScanFFtrEFM(gxpos, gypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, xoryscan,fitstarttime,fitstoptime,DigitizerAverages,DigitizerSamples,DigitizerPretrigger)
	GetCurrentPosition()
	SetDataFolder savDF
	
End


Function CreateParametersFile(PIXELCONFIG)
	Wave PIXELCONFIG
	NVAR numavgsperpoint = root:Packages:trEFM:ImageScan:numavgsperpoint
	NVAR scanpoints = root:packages:trEFM:ImageScan:scanpoints
	string formatf
	NVAR scansizex = root:packages:trEFM:ImageScan:scansizex
	NVAR scansizey = root:packages:trEFM:ImageScan:scansizey
	NVAR liftheight = root:packages:trEFM:liftheight
	NVAR numavgsperpint = root:packages:trEFM:ImageScan:numavgsperpoint

	Make/O/T/N=(25) SaveWave 
	SaveWave[0] = "[Parameters]"
	SaveWave[1] = "trigger = " + num2str(PixelConfig[%trigger])
	SaveWave[2] = "total_time = " + num2str(PixelConfig[%total_time])  

	sprintf formatf, "%.0f", PixelConfig[%sample_rate]
	SaveWave[3] = "sampling_rate = " + formatf  

	sprintf formatf, "%.0f", PixelConfig[%drive_freq] 
	SaveWave[4] = "drive_freq = " + formatf 
	
	SaveWave[5] = "n_pixels = " + num2str(scanpoints)
	SaveWave[6] = "pts_per_pixel = " + num2str(numavgsperpint)	
	
	SaveWave[7] = ""
	SaveWave[8] = "[Processing]" 
	SaveWave[9] = "roi = " + num2str(PixelConfig[%region_of_interest])
	SaveWave[10] = "window = blackman"
	SaveWave[11] = "bandpass_filter = 1"
	SaveWave[12] = "filter_bandwidth = " + num2str(PixelConfig[%bandwidth])
	SaveWave[13] = "n_taps = "+ num2str(PixelConfig[%filter_taps])
	SaveWave[14] = "recombination = "+ num2str(PixelConfig[%recombination])  
	SaveWave[15] = "wavelet_analysis = "+ num2str(PixelConfig[%wavelet_analysis]) 
	SaveWave[16] = "wavelet_parameter = "+ num2str(PixelConfig[%wavelet_parameter])  
	SaveWave[17] = "phase_fitting = 0" 
	SaveWave[18] = "FastScanSize = " + num2str(scansizex*1e-6)
	SaveWave[19] = "SlowScanSize = " + num2str(scansizey*1e-6)
	SaveWave[20] = "lift_height = " + num2str(liftheight)
	
end


Function SKPMImageScanButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	
	SetDataFolder root:Packages:trEFM:ImageScan
	Nvar scansizex, scansizey, scanlines, scanpoints, scanspeed
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	
	Nvar WavesCommitted
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif

	ImageScanSKPM(gxpos, gypos, liftheight, scansizeX, scansizeY, scanlines, scanpoints, scanspeed)
	GetCurrentPosition()
	SetDataFolder savDF
	
End

Function SKPMPointScanButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
		
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	Nvar DwellTime
	
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif

	PointScanSKPM(gxpos, gypos, liftheight, DwellTime)

	GetCurrentPosition()
	SetDataFolder savDF
	
End

Function SKPMPointScanButtonPulsedBias(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
		
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	Nvar DwellTime, AppliedBias, BiasFreq
	
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif

	PointScanSKPMVoltagePulse(gxpos, gypos, liftheight, DwellTime,  appliedbias, biasfreq)

	GetCurrentPosition()
	SetDataFolder savDF
	
End




Function FFtrEFMPointScanButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	
	SetDataFolder root:packages:trEFM:ImageScan
	Nvar DigitizerAverages, DigitizerSamples,DigitizerPretrigger
	Nvar DigitizerTime, DigitizerSampleRate, DigitizerPercentPreTrig
	DigitizerSamples = ceil(DigitizerSampleRate * DigitizerTime * 1e-3)
	DigitizerPretrigger = ceil(DigitizerSamples * DigitizerPercentPreTrig / 100)

	SetDataFolder root:Packages:trEFM
	
	Nvar liftheight
	Nvar gxpos, gypos
	Nvar WavesCommitted
	
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	
	SetDataFolder root:Packages:trEFM:PointScan:FFtrEFM
	
	Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
	Make/O/N=(DigitizerSamples) timekeeper
	Linspace2(0,PIXELCONFIG[%Total_Time],DigitizerSamples, timekeeper)
	SetScale d,0,(DigitizerSamples),"s",timekeeper
	
	PixelConfig[%Trigger] = (1 - DigitizerPercentPreTrig/100) * DigitizerTime * 1e-3
	PixelConfig[%Total_Time] = DigitizerTime * 1e-3
	
	PointScanFFtrEFM(gxpos, gypos, liftheight,DigitizerAverages,DigitizerSamples,DigitizerPretrigger)
	GetCurrentPosition()

	Dowindow/f FFtrEFMWindow
	
	if (V_flag ==0)
		Display/W=(406.5,53,1155.75,488)/n=FFtrEFMWindow/K=1  shiftwave vs timekeeper
		ModifyGraph margin(right)=0,wbRGB=(65535,65535,65535),gbRGB=(65535,65535,65535)
		ModifyGraph lSize=2
		ModifyGraph rgb(shiftwave)=(0,0,0)
		ModifyGraph mirror(bottom)=1
		ModifyGraph fSize=14
		ModifyGraph fStyle=1
		ModifyGraph axThick=1
		Label left "Frequency Offset (Hz)"
		Label bottom "Time"
		TextBox/C/N=text0/V=0 ""
		SetAxis bottom 0.0004,0.0008
		SetAxis/A=2 left;
		
	endif
	
	nvar tfp_value = root:packages:trEFM:PointScan:FFtrEFM:tfp_value
	
	if (numtype(tfp_value) == 2)
		
		nvar tfp_value = root:packages:trEFM:tfp_value
		nvar shift_value = root:packages:trEFM:shift_value

	endif
	
	print "tFP value (s): ", tfp_value

	SetDataFolder savDF
	
End

Function GmodeImageScanButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	
	SetDataFolder root:Packages:trEFM:ImageScan
	Nvar scansizex, scansizey, scanlines, scanpoints, scanspeed, numavgsperpoint, xoryscan, fitstarttime, fitstoptime
	NVAR DigitizerAverages, DigitizerSamples, DigitizerPretrigger, DigitizerSampleRate, DigitizerTime
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	
	Nvar WavesCommitted
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif

	// Check is settings exceed 75 MB. Needed to avoid saturating the Gage Card
	if (DigitizerSampleRate * DigitizerTime * 1e-3 * numavgsperpoint * scanpoints > 70e6)
		variable fileSpaceOption = 0 
		Prompt fileSpaceOption, "These settings near/over 75 MB limit! Continue?"
			DoPrompt ">>>",fileSpaceOption
				If(V_flag==1)
					abort			//Aborts if you cancel the save option
				endif
	endif

	ImageScanGmode(gxpos, gypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, xoryscan,fitstarttime,fitstoptime,DigitizerAverages,DigitizerSamples,DigitizerPretrigger)
	GetCurrentPosition()
	SetDataFolder savDF
	
	
end

Function GModePointScanButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	
	SetDataFolder root:packages:trEFM:ImageScan
	Nvar DigitizerAverages, DigitizerSamples,DigitizerPretrigger
	Nvar DigitizerTime, DigitizerSampleRate, DigitizerPercentPreTrig
	DigitizerSamples = ceil(DigitizerSampleRate * DigitizerTime * 1e-3)
	DigitizerPretrigger = ceil(DigitizerSamples * DigitizerPercentPreTrig / 100)

	SetDataFolder root:Packages:trEFM
	
	Nvar liftheight
	Nvar gxpos, gypos
	Nvar WavesCommitted
	
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	
	SetDataFolder root:Packages:trEFM:PointScan:FFtrEFM
	
	Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
	Make/O/N=(DigitizerSamples) timekeeper
	Linspace2(0,PIXELCONFIG[%Total_Time],DigitizerSamples, timekeeper)
	SetScale d,0,(DigitizerSamples),"s",timekeeper
	
	PixelConfig[%Trigger] = (1 - DigitizerPercentPreTrig/100) * DigitizerTime * 1e-3
	PixelConfig[%Total_Time] = DigitizerTime * 1e-3
	
	PointScanGMode(gxpos, gypos, liftheight,DigitizerAverages,DigitizerSamples,DigitizerPretrigger)
	GetCurrentPosition()

	Dowindow/f FFtrEFMWindow
	
	if (V_flag ==0)
		Display/W=(406.5,53,1155.75,488)/n=FFtrEFMWindow/K=1  shiftwave vs timekeeper
		ModifyGraph margin(right)=0,wbRGB=(65535,65535,65535),gbRGB=(65535,65535,65535)
		ModifyGraph lSize=2
		ModifyGraph rgb(shiftwave)=(0,0,0)
		ModifyGraph mirror(bottom)=1
		ModifyGraph fSize=14
		ModifyGraph fStyle=1
		ModifyGraph axThick=1
		Label left "Frequency Offset (Hz)"
		Label bottom "Time"
		TextBox/C/N=text0/V=0 ""
		SetAxis bottom 0.0004,0.0008
		SetAxis/A=2 left;
		
	endif
	
	nvar tfp_value = root:packages:trEFM:PointScan:FFtrEFM:tfp_value
	
	if (numtype(tfp_value) == 2)
		
		nvar tfp_value = root:packages:trEFM:tfp_value
		nvar shift_value = root:packages:trEFM:shift_value

	endif
	
	print "tFP value (s): ", tfp_value

	SetDataFolder savDF
end
Function GModeTransferFuncButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	
	SetDataFolder root:packages:trEFM:ImageScan
	Nvar DigitizerAverages, DigitizerSamples,DigitizerPretrigger
	Nvar DigitizerTime, DigitizerSampleRate, DigitizerPercentPreTrig
	
	// For this, we will hard-code certain values
	// Runs for 10 ms per signal, with 300 us pre-trigger and 9700 us post-trigger
	DigitizerAverages = 5
	DigitizerTime = 10
	DigitizerPercentPreTrig = 97
	
	DigitizerSamples = ceil(DigitizerSampleRate * DigitizerTime * 1e-3)
	DigitizerPretrigger = ceil(DigitizerSamples * DigitizerPercentPreTrig / 100)

	SetDataFolder root:Packages:trEFM
	
	Nvar liftheight
	Nvar gxpos, gypos
	Nvar WavesCommitted
	
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	
	SetDataFolder root:Packages:trEFM:PointScan:FFtrEFM
	
	Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
	Make/O/N=(DigitizerSamples) timekeeper
	Linspace2(0,PIXELCONFIG[%Total_Time],DigitizerSamples, timekeeper)
	SetScale d,0,(DigitizerSamples),"s",timekeeper
	
	PixelConfig[%Trigger] = (1 - DigitizerPercentPreTrig/100) * DigitizerTime * 1e-3
	PixelConfig[%Total_Time] = DigitizerTime * 1e-3
	
	NVAR calengagefreq = root:packages:trEFM:VoltageScan:calengagefreq
//	print "Generating Chirp with frequency", calengagefreq, " Hz and width", 
	variable f_center = 500e3
	variable f_width = 400e3

	string cmd = "cmd.exe /K cd C:\\Data\\Raj && python generate_chirp.py " + num2str(f_center) + " " + num2str(f_width) + " && Exit"
	ExecuteScriptText cmd

	print "Generated chirp with frequency", num2str(f_center), " Hz and width", num2str(f_width), "Hz" 
	
	string copychirp
	Prompt copychirp, "Insert a Flash Drive and press Continue"
	DoPrompt ">>>",copychirp
	if(V_flag==1)
		Abort			//Aborts if you cancel the save option
	endif
	
	ExecuteScriptText "cmd.exe /K copy chirp.dat E: && Exit"

	Prompt copychirp, "Insert Flash Drive in Wave Generator"
	DoPrompt ">>>",copychirp
	if(V_flag==1)
		Abort			//Aborts if you cancel the save option
	endif
	
	KillWaves/Z root:packages:trEFM:PointScan:FFtrEFM:gagewave
	KillWaves/Z root:packages:trEFM:PointScan:FFtrEFM:ch2_wave
		
	loadchirpwave("chirp", offset=0.0) // verified on oscilloscope should be offset=0 on 6/19/2020
	sleep/S 20

	PointScanTF(gxpos, gypos, liftheight,DigitizerAverages,DigitizerSamples,DigitizerPretrigger)
	GetCurrentPosition()	
	
	Wave gagewave = root:packages:trEFM:PointScan:FFtrEFM:gagewave
	Wave ch2_wave = root:packages:trEFM:PointScan:FFtrEFM:ch2_wave
	
	string gagename = "gagewave_chirp" 
	Duplicate/O gagewave, $gagename
		
	string tf_name = "tip_chirp"
	Duplicate/O ch2_wave, $tf_name	
	
	// Display the results
	Duplicate/O/R=[][0] gagewave_chirp, transfer_func
	Redimension/N=-1 TransferFunc
	SetScale/I x, 0, PixelConfig[%Total_Time], "s", transfer_func
	
	DUplicate/O/R=[][0] ch2_wave, excitation
	SetScale/I x, 0, PixelConfig[%Total_Time], "s", excitation
	Redimension/N=-1 Excitation	
	
	FFT/OUT=3/DEST=transfer_func_FFT transfer_func
	FFT/OUT=3/DEST=excitation_FFT excitation
	
	display transfer_func_FFT
	appendtograph/R excitation_FFT
	
	Beep
end

// Needs debugging, loops through several chirps
Function GModeTransferFUncButton2(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	
	SetDataFolder root:packages:trEFM:ImageScan
	Nvar DigitizerAverages, DigitizerSamples,DigitizerPretrigger
	Nvar DigitizerTime, DigitizerSampleRate, DigitizerPercentPreTrig
	
	// For this, we will hard-code certain values
	// Runs for 10 ms per signal, with 300 us pre-trigger and 9700 us post-trigger
	DigitizerAverages = 5
	DigitizerTime = 10
	DigitizerPercentPreTrig = 97
	
	DigitizerSamples = ceil(DigitizerSampleRate * DigitizerTime * 1e-3)
	DigitizerPretrigger = ceil(DigitizerSamples * DigitizerPercentPreTrig / 100)

	SetDataFolder root:Packages:trEFM
	
	Nvar liftheight
	Nvar gxpos, gypos
	Nvar WavesCommitted
	
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	
	SetDataFolder root:Packages:trEFM:PointScan:FFtrEFM
	
	Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
	Make/O/N=(DigitizerSamples) timekeeper
	Linspace2(0,PIXELCONFIG[%Total_Time],DigitizerSamples, timekeeper)
	SetScale d,0,(DigitizerSamples),"s",timekeeper
	
	PixelConfig[%Trigger] = (1 - DigitizerPercentPreTrig/100) * DigitizerTime * 1e-3
	PixelConfig[%Total_Time] = DigitizerTime * 1e-3
	
	// Loop through 4 chirps
	variable chirps = 0
	make/O/T chirpfiles = {"chirp_w", "chirp_2w", "chirp_3w", "chirp_w2"}
	//make/O/T chirpfiles = {"chirp_w"}
	string gagename, tf_name
	for (chirps = 0; chirps < numpnts(chirpfiles); chirps += 1)

		KillWaves/Z root:packages:trEFM:PointScan:FFtrEFM:gagewave
		KillWaves/Z root:packages:trEFM:PointScan:FFtrEFM:ch2_wave
		
		loadchirpwave(chirpfiles[chirps], offset=0.35) // 0.35 is empirical, but you should check on an oscilloscope
		sleep/S 20
		PointScanTF(gxpos, gypos, liftheight,DigitizerAverages,DigitizerSamples,DigitizerPretrigger)
		GetCurrentPosition()
		
		Wave gagewave = root:packages:trEFM:PointScan:FFtrEFM:gagewave
		Wave ch2_wave = root:packages:trEFM:PointScan:FFtrEFM:ch2_wave
		
		gagename = "gagewave_" + chirpfiles[chirps]
		Duplicate/O gagewave, $gagename
		
		tf_name = "tip_" + chirpfiles[chirps]
		Duplicate/O ch2_wave, $tf_name
		
	endfor
	
	Beep
end

Function CommitDriveWaves()

	String ctrlname
	String savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	Nvar WavesCommitted
	SetDataFolder root:Packages:trEFM:WaveGenerator
	Nvar numcycles
	
	CleanDriveWave(gentipwaveTemp)
	CleanDriveWave(gentriggerwaveTemp)
	CleanDriveWave(genlightwaveTemp)
	CleanDriveWave(gendrivewaveTemp)
	AppendCycles(numcycles)

	WavesCommitted = 1
	SetDataFolder savDF
	
End

Function SaveImageButton(ctrlname): ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	String name
	Variable type
	
	Prompt name, "Save As?"
	Prompt type, "0 for trEFM. 1 for FF-trEFM, 2 for SKPM"
	DoPrompt "Save Image As",name, type
	print name

	SaveImageScan(name, type)
	
End

Function ClearImagesButton(ctrlname): ButtonControl

	String ctrlname
	SetDataFolder root:packages:trEFM:ImageScan:trEFM
	ClearImages()
	
End

Function MoveHereButton(ctrlname): ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM
	Nvar gxpos,gypos
	
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	
	// Move to desired position
	MoveXY(gxpos,gypos)
	
End
Function GetCurrentPosition()

	String savDF
	savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM
	Nvar gxpos,gypos
	
	gxpos = (td_readvalue("XSensor") - td_RV("XLVDToffset")) * GV("XLVDTSens") * 1e6
	gypos = (td_readvalue("YSensor") - td_RV("YLVDToffset")) * GV("YLVDTSens") * 1e6
	

	if(abs(gxpos) < 1e-4)
		gxpos = 0
	endif
	
	if(abs(gypos) < 1e-4)
		gypos = 0
	endif
	
	SetDataFolder savDF
End

Function GetCurrentPositionButton(ctrlname): ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	GetCurrentPosition()
	
End


// Moves the ARC/MFP3D Offsets over to the X/Y and then Moves Here
Function GetMFPOffset(ctrlname): ButtonControl

	string ctrlname
	
	String savDF
	savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM
	
	Nvar gxpos,gypos

	gxpos = gv("XOffset") * 1e6
	gypos = gv("Yoffset") * 1e6
	
	MoveXY(gxpos, gypos)
	
	Sleep/S 0.2
	GetCurrentPosition()
	
	DoUpdate
	
	SetDataFolder savDF
	
end


Function TabProc(ctrlName,tabNum) : TabControl
	String ctrlName
	Variable tabNum
	Variable istrEFM = tabNum == 0
	Variable isFFtrEFM = tabNum == 1
	Variable isGMode = tabNum == 2
	Variable isRingDown = tabNum == 3
	Variable isExtra = tabNum == 4
	
	//trEFM
	ModifyControl cyclesT disable= !isTrEFM
	ModifyControl pntscanbuttonT disable= !isTrEFM
	ModifyControl scanwidthT disable= !isTrEFM
	ModifyControl scanheightT disable= !isTrEFM
	ModifyControl scanpointsT disable= !isTrEFM
	ModifyControl scanlinesT disable= !isTrEFM
	ModifyControl averagesT disable= !isTrEFM
	ModifyControl scanspeedT disable= !isTrEFM
	ModifyControl fitstartT disable= !isTrEFM
	ModifyControl fitstopT disable= !isTrEFM
	ModifyControl savebuttonT disable= !isTrEFM
	ModifyControl clearbuttonT disable= !isTrEFM
	ModifyControl imgscanbuttonT disable= !isTrEFM
	ModifyControl editgains disable= !isTrEFM
	ModifyControl FitShiftWaveAvg disable = !istrEFM
	ModifyControl popup0 disable= !istrEFM
	ModifyControl InterpVal disable = !istrEFM
	
	//FFtrEFM

	ModifyControl pntscanbuttonT2 disable= !isFFtrEFM
	ModifyControl imgscanbuttonT2 disable= !isFFtrEFM
	ModifyControl scanwidthT2 disable= !isFFtrEFM
	ModifyControl scanheightT2 disable= !isFFtrEFM
	ModifyControl scanpointsT2 disable= !isFFtrEFM
	ModifyControl scanlinesT2 disable= !isFFtrEFM
	ModifyControl scanspeedT2 disable= !isFFtrEFM
	ModifyControl savebuttonT2 disable= !isFFtrEFM
	ModifyControl clearbuttonT2 disable= !isFFtrEFM
	ModifyControl averagesT2 disable= !isFFtrEFM
	ModifyControl digiaverages disable= !isFFtrEFM
	ModifyControl digisamples disable= !isFFtrEFM
	ModifyControl digipre disable= !isFFtrEFM
	ModifyControl aconfig disable= !isFFtrEFM
	ModifyControl popup1 disable= !isFFtrEFM
	ModifyControl DriveTime disable = (!isFFtrEFM)
	ModifyControl CutDriveOn disable = (!isFFtrEFM)
	ModifyControl DriveTimestop disable = (!isFFtrEFM)
	ModifyControl ElecDrive disable = (!isGMode && !isFFtrEFM)
	ModifyControl ElecAmp disable = (!isGMode && !isFFtrEFM)
	ModifyControl OneorTwoChannelBox disable = (!isGmode && !isFFtrEFM)

	// Ring Down

	ModifyControl cyclesT disable= (!isRingDown && !istrEFM)
	ModifyControl scanwidthT disable= (!isRingDown && !istrEFM)
	ModifyControl scanheightT disable= (!isRingDown && !istrEFM)
	ModifyControl scanpointsT disable= (!isRingDown && !istrEFM)
	ModifyControl scanlinesT disable= (!isRingDown && !istrEFM)
	ModifyControl averagesT disable= (!isRingDown && !istrEFM)
	ModifyControl scanspeedT disable= (!isRingDown && !istrEFM)
	ModifyControl fitstartT disable= (!isRingDown && !istrEFM)
	ModifyControl fitstopT disable= (!isRingDown && !istrEFM)
	ModifyControl savebuttonT disable= (!isRingDown && !istrEFM)
	ModifyControl clearbuttonT disable= (!isRingDown && !istrEFM)
	ModifyControl FitShiftWaveAvg disable = (!isRingDown && !istrEFM)

	ModifyControl LightOnOrOff disable = !isRingDown
	ModifyControl RingDownVoltage disable = !isRingDown
	ModifyControl imgscanbuttonRD disable= !isRingDown
	ModifyControl pntscanbuttonRD disable = !isRingDown

	// G-Mode
	ModifyControl pntscanbuttonT4 disable= !(isGmode)
	ModifyControl imgscanbuttonT4 disable=  !(isGmode)
	ModifyControl scanwidthT2 disable= !(isGmode || isFFtrEFM)
	ModifyControl scanheightT2 disable= !(isGmode || isFFtrEFM)
	ModifyControl scanpointsT2 disable=  !(isGmode || isFFtrEFM)
	ModifyControl scanlinesT2 disable=  !(isGmode || isFFtrEFM)
	ModifyControl scanspeedT2 disable= !(isGmode || isFFtrEFM)
	ModifyControl savebuttonT2 disable= !(isGmode || isFFtrEFM)
	ModifyControl clearbuttonT2 disable= !(isGmode || isFFtrEFM)
	ModifyControl averagesT2 disable=  !(isGmode || isFFtrEFM)
	ModifyControl digiaverages disable=  !(isGmode || isFFtrEFM)
	ModifyControl digisamples disable= !(isGmode || isFFtrEFM)
	ModifyControl digipre disable=  !(isGmode || isFFtrEFM)
	ModifyControl aconfig disable= !(isGmode || isFFtrEFM)
	ModifyControl popup1 disable=  !(isGmode || isFFtrEFM)
	MOdifyControl GMOdeAC disable = !isGmode


	// Extra/Calibration
	ModifyControl setvar0 disable= !isExtra
	ModifyControl button2 disable= !isExtra
	ModifyControl forceparams2 disable = !isExtra
	ModifyControl forceparams disable = !isExtra
	ModifyControl forceparams1 disable = !isExtra
	//ModifyControl forceparams1 disable = !isExtra
	ModifyControl setphasevar disable = !isExtra
	ModifyControl calcurve disable = !isExtra
	ModifyControl transferfuncparams disable = !isExtra
	
	// Change LED Wave Button
	if (isRingDown)
		Button button1 title = "Edit RingDown", proc= EditRingDownWaveButton
	else
		Button button1 title = "Edit LED Wave", proc= EditLightWaveButton
	endif
	
	return 0
End

// If this panel function does not contain a call to trEFMInit(), it has been saved over. Just insert it below and the 
// code should work again
Window trEFMImagingPanel() : Panel
	trefminit()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1945,793,2509,1106)
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (56576,56576,56576)
	DrawRect 11,6,238,91
	SetDrawEnv fillfgc= (56576,56576,56576)
	DrawRect 11,97,238,238
	SetDrawEnv fillfgc= (56576,56576,56576)
	DrawRect 12,244,239,301
	TabControl tab0,pos={249,6},size={310,295},proc=TabProc
	TabControl tab0,labelBack=(56576,56576,56576),tabLabel(0)="trEFM"
	TabControl tab0,tabLabel(1)="FFtrEFM",tabLabel(2)="G-KPFM"
	TabControl tab0,tabLabel(3)="Ring Down",tabLabel(4)="Extra",value= 0
	SetVariable setvar13,pos={17,11},size={62,16},title="X"
	SetVariable setvar13,help={"X Stage Position (in microns)"}
	SetVariable setvar13,limits={-inf,inf,0},value= root:packages:trEFM:gxpos
	SetVariable setvar14,pos={92,11},size={61,16},title="Y"
	SetVariable setvar14,help={"Y Stage Position (in microns)"}
	SetVariable setvar14,limits={-inf,inf,0},value= root:packages:trEFM:gypos
	SetVariable setvar15,pos={160,11},size={72,16},title="Z (nm)"
	SetVariable setvar15,help={"Lift height (in nm)"}
	SetVariable setvar15,limits={-inf,inf,0},value= root:packages:trEFM:liftheight
	Button button14,pos={17,35},size={74,23},proc=MoveHereButton,title="Move Here"
	Button button14,help={"Move to the X,Y position given above."}
	Button button15,pos={102,39},size={57,19},proc=GetCurrentPositionButton,title="Current XY"
	Button button15,help={"Fill the X,Y with the current stage position."}
	Button button7,pos={19,128},size={100,20},proc=GrabTuneButton,title="Grab Tune"
	Button button7,help={"Load the cantilever tune parameters into the software."}
	SetVariable setvar6,pos={20,109},size={79,16},title="Soft Amp",fSize=10
	SetVariable setvar6,limits={-inf,inf,0},value= root:packages:trEFM:VoltageScan:softamplitude
	SetVariable setvar7,pos={34,159},size={75,16},title="V Min"
	SetVariable setvar7,help={"Low end of Voltage Sweep."}
	SetVariable setvar7,limits={-inf,inf,0},value= root:packages:trEFM:VoltageScan:vmin
	SetVariable setvar8,pos={34,176},size={75,16},title="V Max"
	SetVariable setvar8,help={"High end of Voltage Sweep."}
	SetVariable setvar8,limits={-inf,inf,0},value= root:packages:trEFM:VoltageScan:vmax
	SetVariable setvar9,pos={34,194},size={75,16},title="Z (nm)"
	SetVariable setvar9,help={"Lift height (in nm)"}
	SetVariable setvar9,limits={-inf,inf,0},value= root:packages:trEFM:liftheight
	Button button8,pos={19,213},size={100,20},proc=VoltageScanButton,title="Voltage Scan"
	Button button9,pos={132,213},size={100,20},proc=HeightScanButton,title="Height Scan"
	SetVariable setvar04,pos={147,159},size={75,16},title="Z Min"
	SetVariable setvar04,help={"Low end of height scan."}
	SetVariable setvar04,limits={-inf,inf,0},value= root:packages:trEFM:HeightScan:zmin
	SetVariable setvar05,pos={148,177},size={74,16},title="Z Max"
	SetVariable setvar05,help={"High end of height scan."}
	SetVariable setvar05,limits={-inf,inf,0},value= root:packages:trEFM:HeightScan:zmax
	SetVariable setvar06,pos={143,195},size={79,16},title="Voltage"
	SetVariable setvar06,help={"Voltage at which the height scan takes place."}
	SetVariable setvar06,limits={-inf,inf,0},value= root:packages:trEFM:HeightScan:voltage
	Button button10,pos={164,107},size={68,40},proc=LightOnButton,title="LED is OFF"
	Button button0,pos={119,249},size={113,23},proc=EditTipWaveButton,title="Edit Voltage Wave"
	Button button1,pos={17,249},size={96,23},proc=EditLightWaveButton,title="Edit LED Wave"
	Button button3,pos={17,274},size={96,23},proc=EditTriggerWaveButton,title="Edit Trigger Wave"
	SetVariable cyclesT,pos={263,62},size={100,16},title="Averages"
	SetVariable cyclesT,help={"Number of averages in a point scan."}
	SetVariable cyclesT,limits={-inf,inf,0},value= root:packages:trEFM:WaveGenerator:numcycles
	Button editgains,pos={272,227},size={80,20},proc=EditGainsButton,title="Edit Gains"
	Button fitshiftwaveavg,pos={278,150},size={80,20},proc=FitShiftWaveAvgButton,title="Fit Point Scan"
	Button pntscanbuttonT,pos={260,34},size={100,25},proc=trEFMPointScanButton,title="Point Scan"
	Button imgscanbuttonT,pos={380,34},size={100,25},proc=trEFMImageScanButton,title="Image Scan"
	SetVariable scanheightT,pos={384,82},size={100,16},title="Height (µm)       "
	SetVariable scanheightT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizey
	SetVariable scanpointsT,pos={384,102},size={100,16},title="Scan Points    "
	SetVariable scanpointsT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanpoints
	SetVariable scanlinesT,pos={384,122},size={100,16},title="Scan Lines     "
	SetVariable scanlinesT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanlines
	SetVariable averagesT,pos={384,142},size={100,16},title="# Averages       "
	SetVariable averagesT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:numavgsperpoint
	SetVariable scanspeedT,pos={371,162},size={113,16},title="Scan Speed(um/s)"
	SetVariable scanspeedT,fSize=10
	SetVariable scanspeedT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanspeed
	SetVariable fitstartT,pos={267,113},size={96,16},title="Fit Start    ",fStyle=1
	SetVariable fitstartT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:fitstarttime
	SetVariable fitstopT,pos={267,131},size={96,16},title="Fit Stop    ",fStyle=1
	SetVariable fitstopT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:fitstoptime
	Button savebuttonT,pos={380,193},size={102,34},proc=SaveImageButton,title="Save"
	Button savebuttonT,help={"Save a previously acquired Image Scan."}
	Button clearbuttonT,pos={453,258},size={40,20},proc=ClearImagesButton,title="Clear"
	Button clearbuttonT,help={"Clear all collected data."}
	SetVariable scanwidthT,pos={384,62},size={100,16},title="Width (µm)        "
	SetVariable scanwidthT,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizex
	Button pntscanbuttonT2,pos={262,34},size={100,25},disable=1,proc=FFtrEFMPointScanButton,title="Point Scan"
	Button imgscanbuttonT2,pos={382,34},size={100,25},disable=1,proc=FFtrEFMImageScanButton,title="Image Scan"
	SetVariable scanheightT2,pos={441,82},size={100,16},disable=1,title="Height (µm)       "
	SetVariable scanheightT2,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizey
	SetVariable scanpointsT2,pos={441,102},size={100,16},disable=1,title="Scan Points    "
	SetVariable scanpointsT2,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanpoints
	SetVariable scanlinesT2,pos={441,122},size={100,16},disable=1,title="Scan Lines     "
	SetVariable scanlinesT2,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanlines
	SetVariable scanspeedT2,pos={420,160},size={121,16},disable=1,title="Scan Speed(um/s)"
	SetVariable scanspeedT2,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanspeed
	Button savebuttonT2,pos={434,188},size={99,33},disable=1,proc=SaveImageButton,title="Save"
	Button clearbuttonT2,pos={454,229},size={40,20},disable=1,proc=ClearImagesButton,title="Clear"
	SetVariable scanwidthT2,pos={441,62},size={100,16},disable=1,title="Width (µm)        "
	SetVariable scanwidthT2,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizex
	SetVariable cyclesT3,pos={529,50},size={85,16},disable=1,title="# of Cycles"
	SetVariable cyclesT3,limits={-inf,inf,0},value= root:packages:trEFM:WaveGenerator:numcycles
	Button pntscanbuttonT3,pos={521,70},size={100,25},disable=1,proc=trEFMPointScanButton,title="Point Scan"
	Button imgscanbuttonT3,pos={654,228},size={100,25},disable=1,proc=trEFMImageScanButton,title="Image Scan"
	SetVariable scanheightT3,pos={643,70},size={110,16},disable=1,title="Scan Height (µm)"
	SetVariable scanheightT3,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizey
	SetVariable scanpointsT3,pos={653,90},size={100,16},disable=1,title="Scan Points"
	SetVariable scanpointsT3,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanpoints
	SetVariable scanlinesT3,pos={653,110},size={100,16},disable=1,title="Scan Lines"
	SetVariable scanlinesT3,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanlines
	SetVariable averagesT3,pos={653,130},size={100,16},disable=1,title="# Averages"
	SetVariable averagesT3,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:numavgsperpoint
	SetVariable scanspeedT3,pos={653,150},size={100,16},disable=1,title="Scan Speed"
	SetVariable scanspeedT3,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanspeed
	SetVariable fitstartT3,pos={678,170},size={75,16},disable=1,title="Fit Start"
	SetVariable fitstartT3,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:fitstarttime
	SetVariable fitstopT3,pos={678,190},size={75,16},disable=1,title="Fit Stop"
	SetVariable fitstopT3,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:fitstoptime
	Button savebuttonT3,pos={654,208},size={50,20},disable=1,proc=SaveImageButton,title="SAVE"
	Button clearbuttonT3,pos={703,208},size={50,20},disable=1,proc=ClearImagesButton,title="CLEAR"
	SetVariable scanwidthT3,pos={643,50},size={110,16},disable=1,title="Scan Width (µm)"
	SetVariable scanwidthT3,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizex
	SetVariable digipre,pos={266,102},size={90,16},disable=1,title="Pre-Trigger %"
	SetVariable digipre,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:DigitizerPercentPreTrig
	SetVariable digisamples,pos={259,82},size={97,16},disable=1,title="Time (ms)"
	SetVariable digisamples,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:DigitizerTime
	Button aconfig,pos={277,175},size={80,20},disable=1,proc=AnalysisSettingsButton,title="Analysis Config"
	SetVariable averagesT2,pos={441,142},size={100,16},disable=1,title="# Averages       "
	SetVariable averagesT2,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:numavgsperpoint
	SetVariable digiaverages,pos={276,62},size={80,16},disable=1,title="Averages"
	SetVariable digiaverages,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:DigitizerAverages
	PopupMenu popup0,pos={262,198},size={95,22},bodyWidth=60,proc=LockinSelectPopup,title="Lockin"
	PopupMenu popup0,mode=1,popvalue="ARC",value= #"\"ARC;Cypher\""
	PopupMenu popup1,pos={271,122},size={86,22},bodyWidth=60,disable=1,proc=PopMenuProc,title="Rate"
	PopupMenu popup1,mode=1,popvalue="10 MS",value= #"\"10 MS;50 MS;100MS;5MS;1MS;0.5MS\""
	SetVariable setvar0,pos={254,34},size={130,16},disable=1,proc=SetPhaseDelay,title="Trigger Delay (ns)"
	SetVariable setvar0,limits={-inf,inf,0},value= root:packages:trEFM:triggerDelay
	SetVariable setphasevar,pos={256,57},size={130,16},disable=1,proc=SetPhase,title="Phase Delay (deg)"
	SetVariable setphasevar,limits={-inf,inf,0},value= root:packages:trEFM:phaseDelay
	Button button2,pos={414,40},size={76,23},disable=1,proc=RedoAnalysisButton,title="Re-Analyze"
	Button button4,pos={125,277},size={102,17},proc=Recombutton,title="---> RECOM"
	Button forceparams,pos={402,108},size={137,28},disable=1,proc=ForceCalButton,title="Force Calibration"
	Button calcurve,pos={266,221},size={96,40},disable=1,proc=CalCurveButton,title="Calibration Curve\rwith Func Gen"
	SetVariable RingDownVoltage,pos={278,187},size={79,16},disable=1,title="Voltage    "
	SetVariable RingDownVoltage,limits={-10,10,0},value= root:packages:trEFM:RingDownVoltage
	Button LightOnorOff,pos={277,210},size={80,20},disable=1,proc=LightOnOrOffButton,title="Light is On"
	Button imgscanbuttonRD,pos={380,34},size={100,25},disable=1,proc=RingDownImageScanButton,title="Image Scan"
	Button pntscanbuttonRD,pos={260,34},size={100,25},disable=1,proc=RingDownPointScanButton,title="Point Scan"
	Button pntscanbuttonRD,help={"Do a trEFM Point Scan."}
	Button button16,pos={171,39},size={62,19},proc=GetMFPOffset,title="Grab Offset"
	Button button16,help={"Fill the X,Y with the current stage position."}
	SetVariable InterpVal,pos={263,85},size={100,16},title="Interpolation   "
	SetVariable InterpVal,limits={1,64,1},value= root:packages:trEFM:interpval
	Button whichFastbutton,pos={17,62},size={45,27},proc=trEFMXFast,title="0°!"
	Button whichFastbutton,fStyle=1,fColor=(52224,52224,52224)
	SetVariable setvar03,pos={68,68},size={136,16},title="Single Line Number"
	SetVariable setvar03,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:LineNum
	CheckBox singleline,pos={211,70},size={16,14},proc=UseLineNum,title=""
	CheckBox singleline,variable= root:packages:trEFM:ImageScan:UseLineNum
	CheckBox CutDriveOn,pos={286,238},size={71,14},disable=1,proc=CutDriveProc,title="Cut Drive? "
	CheckBox CutDriveOn,variable= root:packages:trEFM:cutDrive,side= 1
	SetVariable DriveTime,pos={255,255},size={102,16},disable=1,title="Time (ms) pre-V"
	SetVariable DriveTime,limits={-inf,inf,0},value= root:packages:trEFM:cutpreV
	SetVariable settargetpercent,pos={102,109},size={40,16},title="%",fSize=10
	SetVariable settargetpercent,limits={-inf,inf,0},value= root:packages:trEFM:VoltageScan:targetpercent
	SetVariable DriveTimestop,pos={363,255},size={79,16},disable=1,title="Length (ms)"
	SetVariable DriveTimestop,limits={-inf,inf,0},value= root:packages:trEFM:cutLength
	SetVariable ElecAmp,pos={351,278},size={91,16},disable=1,title="Elec Amp (V)"
	SetVariable ElecAmp,limits={0,10,0},value= root:packages:trEFM:elecAmp
	CheckBox ElecDrive,pos={267,280},size={73,14},disable=1,title="Elec Drive?"
	CheckBox ElecDrive,variable= root:packages:trEFM:elecDrive,side= 1
	SetVariable GmodeAC,pos={363,102},size={61,16},disable=1,title="AC (V)"
	SetVariable GmodeAC,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:GM_AC
	Button pntscanbuttonT4,pos={273,37},size={100,25},disable=1,proc=GModePointScanButton,title="Point Scan"
	Button imgscanbuttonT4,pos={393,37},size={100,25},disable=1,proc=GmodeImageScanButton,title="Image Scan"
	Button forceparams1,pos={402,165},size={137,28},disable=1,proc=ElecCalButton,title="Electrical Calibration"
	Button forceparams2,pos={402,215},size={136,34},disable=1,proc=ElecCal_Noise_Button,title="Elec+Noise Calibration\r(SLOW!)"
	CheckBox OneorTwoCHannelBox,pos={265,153},size={92,14},disable=1,proc=OneOrTwoChannelsCHeckBox,title="Two Channels?"
	CheckBox OneorTwoCHannelBox,variable= root:packages:trEFM:ImageScan:OneorTwoChannels,side= 1
	Button transferfuncparams,pos={402,255},size={136,34},proc=GModeTransferFUncButton,title="Transfer Func with AWG"
	ToolsGrid snap=1,visible=1,grid=(0,28.35,5)
EndMacro


Window SKPMPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(982,457,1432,721)
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (56576,56576,56576)
	DrawRect 4,5,441,252
	SetDrawEnv fstyle= 1
	DrawText 11,26,"Function Generator"
	SetDrawEnv fstyle= 1
	DrawText 11,104,"External LIA"
	SetDrawEnv fstyle= 1
	DrawText 142,26,"Image Scan"
	SetDrawEnv fstyle= 1
	DrawText 140,87,"Pointscan"
	SetDrawEnv fstyle= 1
	DrawText 11,168,"IMSKPM"
	SetVariable setvar0,pos={11,108},size={115,16},title="Time Constant (ms)"
	SetVariable setvar0,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:LockinTimeConstant
	SetVariable setvar1,pos={11,128},size={100,16},title="Sensitivity"
	SetVariable setvar1,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:LockinSensitivity
	SetVariable setvar2,pos={11,29},size={108,16},title="Frequency (Hz)"
	SetVariable setvar2,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:ACFrequency
	SetVariable setvar3,pos={11,49},size={81,16},title="Voltage (V)"
	SetVariable setvar3,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:ACVoltage
	SetVariable setvar4,pos={141,30},size={126,16},title="Time Per Point (ms)"
	SetVariable setvar4,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:TimePerPoint
	Button button0,pos={140,110},size={100,20},proc=SKPMPointScanButton,title="Regular Point Scan"
	Button button1,pos={141,49},size={100,20},proc=SKPMImageScanButton,title="Image Scan"
	SetVariable setvar5,pos={11,69},size={99,16},title="Device address"
	SetVariable setvar5,limits={-inf,inf,0},value= root:packages:trEFM:gWGDeviceAddress
	SetVariable setvar6,pos={141,92},size={81,16},title="Dwell time (s)"
	SetVariable setvar6,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:DwellTime
	Button button2,pos={140,135},size={100,20},proc=SKPMPointScanButtonPulsedBias,title="With Pulsed Bias"
	SetVariable setvar7,pos={143,160},size={81,16},title="Bias (V)"
	SetVariable setvar7,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:AppliedBias
	SetVariable setvar8,pos={142,179},size={81,16},title="Freq. (Hz)"
	SetVariable setvar8,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:BiasFreq
	SetVariable setvar9,pos={9,173},size={108,16},title="Device address 2"
	SetVariable setvar9,limits={-inf,inf,0},value= root:packages:trEFM:gWGDeviceAddress2
	CheckBox singleline,pos={288,9},size={142,14},proc=UseLineNumforVoltage,title="Change Voltage Mid-Scan"
	CheckBox singleline,variable= root:packages:trEFM:PointScan:SKPM:UseLineNumforVoltage
	SetVariable setvar03,pos={296,27},size={136,16},title="Line # for Voltage"
	SetVariable setvar03,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:LineNumforVoltage
	SetVariable setvar04,pos={296,47},size={136,16},title="Voltage 1"
	SetVariable setvar04,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:VoltageatLine
	SetVariable setvar05,pos={296,72},size={136,16},title="Line # for Voltage 2 "
	SetVariable setvar05,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:LineNumforVoltage2
	SetVariable setvar06,pos={296,92},size={136,16},title="Voltage 1"
	SetVariable setvar06,limits={-inf,inf,0},value= root:packages:trEFM:PointScan:SKPM:VoltageatLine2
	Button button3,pos={332,115},size={100,20},proc=PSON_button,title="Turn on PS"
	Button button4,pos={332,142},size={100,20},proc=PSOff_button,title="Turn off PS"
	ToolsGrid snap=1,visible=1
EndMacro

Function LockinSelectPopup(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string savDF = GetDataFolder(1)
	
	SetDataFolder root:packages:trEFM
	Svar LockinString
	
	if(popNum == 1)
		LockinString = "ARC.Lockin.0."
	elseif(popNum == 2)
		LockinString = "Cypher.LockinA.0."
	endif
	
	print LockinString
	
	SetDataFolder savDF
End

Function PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM:ImageScan
	Nvar DigitizerSampleRate
	Wave CSACQUISITIONCONFIG = root:packages:GageCS:CSACQUISITIONCONFIG
	Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
	
	switch(popNum)
		Case 1:
			DigitizerSampleRate = 10e6
			CSACQUISITIONCONFIG[%SampleRate] = 10e6
			PIXELCONFIG[%sample_rate] = 10e6
			break
		Case 2:
			DigitizerSampleRate = 50e6
			CSACQUISITIONCONFIG[%SampleRate] = 50e6
			PIXELCONFIG[%sample_rate] = 50e6
			break
		Case 3:
			DigitizerSampleRate = 100e6
			CSACQUISITIONCONFIG[%SampleRate] = 100e6
			PIXELCONFIG[%sample_rate] = 100e6
			break
		Case 4:
			DigitizerSampleRate = 5e6
			CSACQUISITIONCONFIG[%SampleRate] = 5e6
			PIXELCONFIG[%sample_rate] = 5e6
			break
		Case 5:
			DigitizerSampleRate = 1e6
			CSACQUISITIONCONFIG[%SampleRate] = 1e6
			PIXELCONFIG[%sample_rate] = 1e6
			break
		Case 6:
			DigitizerSampleRate = 0.5e6
			CSACQUISITIONCONFIG[%SampleRate] = 0.5e6
			PIXELCONFIG[%sample_rate] = 0.5e6
			break
	endswitch
	
	SetDataFolder savDF
End


Function SetPhaseDelay(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			nvar resfreq = root:packages:trEFM:VoltageScan:calresfreq
			nvar gdelay = root:packages:trEFM:triggerdelay
			Variable dval = sva.dval
			String sval = sva.sval
			variable delay =round( gdelay * PIXELCONFIG[%drive_freq] * 128 * 1e-9)
			PhaseRes(128)
			print "New Zero Phase:" + num2str(128 - delay - 1)
			PhaseSet(128 - delay - 1)
			break
			
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function SetPhase(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			nvar resfreq = root:packages:trEFM:VoltageScan:calresfreq
			nvar gdelay = root:packages:trEFM:triggerdelay
			Variable dval = sva.dval
			String sval = sva.sval
			variable delay =round( gdelay * PIXELCONFIG[%drive_freq] * 128 * 1e-9)
			PhaseRes(128)
			PhaseSet(128 - delay - 1)
			print dval/360 * 128
			PhaseSet(dval/360 * 128)
			break
			
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ForceCalButton(ctrlname) : ButtonControl
	string ctrlname
	
	variable setvoltage
	
	svar LockInString = root:packages:trEFM:LockinString
	
	if( stringmatch(LockInString,"Cypher.LockinA.0."))
		Abort "Must use ARC Lockin. Also have you done the GetReal calibration?"
	endif
		
	Prompt setvoltage, "Procedure: 1) GetReal 2) Set to Arc Lockin 3) Grab Tune. 4) Set voltage. Continue?"
	DoPrompt ">>>",setvoltage
	if(V_flag==1)
		Abort			//Aborts if you cancel the save option
	endif

	if (setvoltage < -10)
		setvoltage = -10
	elseif (setvoltage > 10)
		setvoltage = 10
	endif
	
	GetFreeCantileverParms()
	GetForceParms(setvoltage)
	
	Edit FinalParms.ld
end

Function ElecCalButton(ctrlname) : ButtonControl
	string ctrlname
	
	variable setvoltage
	
	svar LockInString = root:packages:trEFM:LockinString
	
	if( stringmatch(LockInString,"Cypher.LockinA.0."))
		Abort "Must use ARC Lockin. Also have you done the GetReal calibration?"
	endif
		
	Prompt setvoltage, "Procedure: 1) Force Calibration 2) Elec Tune with Electrical Tune Panel. Continue?"
	DoPrompt ">>>",setvoltage
	if(V_flag==1)
		Abort			//Aborts if you cancel the save option
	endif

	if (setvoltage < -10)
		setvoltage = -10
	elseif (setvoltage > 10)
		setvoltage = 10
	endif
	
	GetFreeCantileverParms()
	GetElecTip(setvoltage)
	
	Wave calAmpsVi =  root:packages:trEFM:ForceCal:calAmpsVi
	Wave TransferFunc = root:packages:trEFM:ForceCal:TransferFunc
	Wave FinalParms = root:packages:trEFM:ForceCal:FinalParms

	display TransferFunc
	ModifyGraph log=1
	Label left "Amplitude (m)";DelayUpdate;Label bottom "Frequency (Hz)"
	ModifyGraph mirror=1,fStyle=1,fSize=16,axThick=3
	ModifyGraph lsize=3
	appendtograph CalAmpsVi1
	appendtograph CalAmpsVi2
	appendtograph CalAmpsVi3
	
	ModifyGraph lstyle(calAmpsVi1)=2,lsize(calAmpsVi1)=4;DelayUpdate
	ModifyGraph rgb(calAmpsVi1)=(0,15872,65280),lstyle(calAmpsVi2)=2;DelayUpdate
	ModifyGraph lsize(calAmpsVi2)=4,rgb(calAmpsVi2)=(0,39168,19712)
	
	Save/C/O TransferFunc as "TransferFunc.ibw"
	Save/G/W/M="\r\n"/U={1,0,1,0} FinalParms as "FinalParms.txt"
	
	Edit FinalParms.ld
end

Function ElecCal_Noise_Button(ctrlname) : ButtonControl
	string ctrlname
	
	variable setvoltage
	
	svar LockInString = root:packages:trEFM:LockinString
	
	if( stringmatch(LockInString,"Cypher.LockinA.0."))
		Abort "Must use ARC Lockin. Also have you done the GetReal calibration?"
	endif
		
	Prompt setvoltage, "Procedure: 1) Force Calibration 2) Elec Tune with Electrical Tune Panel. Continue?"
	DoPrompt ">>>",setvoltage
	if(V_flag==1)
		Abort			//Aborts if you cancel the save option
	endif

	Prompt setvoltage, "Warning! This probably takes several minutes, at least. Continue?"
	DoPrompt ">>>",setvoltage
	if(V_flag==1)
		Abort			//Aborts if you cancel the save option
	endif

	if (setvoltage < -10)
		setvoltage = -10
	elseif (setvoltage > 10)
		setvoltage = 10
	endif
	
	GetFreeCantileverParms()
	GetElecNoiseTip(setvoltage)
	
	Wave calAmpsVi =  root:packages:trEFM:ForceCal:calAmpsVi
	Wave TransferFunc = root:packages:trEFM:ForceCal:TransferFunc
	Wave FinalParms = root:packages:trEFM:ForceCal:FinalParms

	display TransferFunc
	ModifyGraph log=1
	Label left "Amplitude (m)";DelayUpdate;Label bottom "Frequency (Hz)"
	ModifyGraph mirror=1,fStyle=1,fSize=16,axThick=3
	ModifyGraph lsize=3
	appendtograph CalAmpsVi1
	appendtograph CalAmpsVi2
	appendtograph CalAmpsVi3
	
	ModifyGraph lstyle(calAmpsVi1)=2,lsize(calAmpsVi1)=4;DelayUpdate
	ModifyGraph rgb(calAmpsVi1)=(0,15872,65280),lstyle(calAmpsVi2)=2;DelayUpdate
	ModifyGraph lsize(calAmpsVi2)=4,rgb(calAmpsVi2)=(0,39168,19712)
	
	Save/C/O TransferFunc as "TransferFunc.ibw"
	Save/G/W/M="\r\n"/U={1,0,1,0} FinalParms as "FinalParms.txt"
	
	Edit FinalParms.ld
end

Function LightCalButton(ctrlname) : ButtonControl
	string ctrlname
	
	variable setvoltage
	
	svar LockInString = root:packages:trEFM:LockinString
	
	if( stringmatch(LockInString,"Cypher.LockinA.0."))
		Abort "Must use ARC Lockin. Also have you done the GetReal calibration?"
	endif
		
	Prompt setvoltage, "Procedure: 1) GetReal 2) Set to Arc Lockin 3) Grab Tune. 4) Set voltage. Continue?"
	DoPrompt ">>>",setvoltage
	if(V_flag==1)
		Abort			//Aborts if you cancel the save option
	endif

	if (setvoltage < -10)
		setvoltage = -10
	elseif (setvoltage > 10)
		setvoltage = 10
	endif
	
	GetFreeCantileverParms()

	GetForceParms_Light(setvoltage)
	
	Edit FinalParms.ld
end




Function CalCurveButton(ctrlname) : ButtonControl
	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	
	variable setvoltage
	Prompt setvoltage, "Voltage Wave must be 5V less than desired total voltage! 1 to continue"
	DoPrompt ">>>",setvoltage	// prompt does nothing
	if(V_flag==1)
		Abort			//Aborts if you cancel the save option
	endif
	SetDataFolder root:packages:trEFM:ImageScan
	Nvar DigitizerAverages, DigitizerSamples,DigitizerPretrigger
	Nvar DigitizerTime, DigitizerSampleRate, DigitizerPercentPreTrig
	DigitizerSamples = ceil(DigitizerSampleRate * DigitizerTime * 1e-3)
	DigitizerPretrigger = ceil(DigitizerSamples * DigitizerPercentPreTrig / 100)

	SetDataFolder root:Packages:trEFM
	
	Nvar liftheight
	Nvar gxpos, gypos
	Nvar WavesCommitted
	
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	
	SetDataFolder root:Packages:trEFM:PointScan:FFtrEFM
	
	Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
	Make/O/N=(DigitizerSamples) timekeeper
	Linspace2(0,PIXELCONFIG[%Total_Time],DigitizerSamples, timekeeper)
	SetScale d,0,(DigitizerSamples),"s",timekeeper
	
	PixelConfig[%Trigger] = (1 - DigitizerPercentPreTrig/100) * DigitizerTime * 1e-3
	PixelConfig[%Total_Time] = DigitizerTime * 1e-3
	
	TauScan(gxpos, gypos, liftheight,DigitizerAverages,DigitizerSamples,DigitizerPretrigger)
	GetCurrentPosition()
end

Function RedoAnalysisButton(ctrlname) : ButtonControl
	string ctrlname
	ReDoAnalysis()
End

Function RingDownImageScanButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	SetDataFolder root:Packages:trEFM:ImageScan
	Nvar scansizex, scansizey, scanlines, scanpoints, scanspeed, numavgsperpoint, xoryscan, fitstarttime, fitstoptime
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	
	svar LockInString = root:packages:trEFM:LockinString
	if( stringmatch(LockInString,"Cypher.LockinA.0."))
		Abort "Swtich to ARC Lockin"
	endif
	
	Nvar WavesCommitted
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	
	ImageScanRingDownEFM(gxpos, gypos, liftheight, scansizeX,scansizeY, scanlines, scanpoints, scanspeed, numavgsperpoint, xoryscan,fitstarttime,fitstoptime)
	GetCurrentPosition()
	SetDataFolder savDF
	
	
End

Function trEFMXFast(ba): ButtonControl
	STRUCT WMButtonAction &ba

	
	NVAR XFastEFM = root:packages:trEFM:ImageScan:XFastEFM
	NVAR YFastEFM = root:packages:trEFM:ImageScan:YFastEFM
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			if (XFastEFM == 0)
				XFastEFM = 1
				YFastEFM = 0
				Button whichFastButton title="0°!"
				Button whichFastButton fColor=(52224,52224,52224)
			elseif(XFastEFM == 1)
				XFastEFM = 0
				YFastEFM = 1
				Button whichFastButton title="90°!"
				Button whichFastButton fColor=(65280,32768,32768)
			endif
			break
		case -1: // control being killed
			break
	endswitch
	
End

Function About()
	print "Written by many members of the Ginger Lab from 2003 - 2019." 
	print "Primary points of contact are Rajiv Giridharagopal (rgiri@uw.edu) and David Ginger (dginger@uw.edu)."
	print "All rights reserved, whatever that means."
end