#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function SetPGainCPD(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			td_wv("ARC.PIDSLoop.4.PGain",dval)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function SetIGainCPD(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			td_wv("ARC.PIDSLoop.4.IGain",dval)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function SetDGainCPD(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			td_wv("ARC.PIDSLoop.4.DGain",dval)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Window SKPMGainsPanelCPD() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1099,386,1336,502)
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (56576,56576,56576)
	DrawRect 6,7,230,106
	SetDrawEnv fstyle= 1
	DrawText 121,25,"Kelvin Loop Gains"
	SetDrawEnv fstyle= 1
	DrawText 13,25,"Phase offet Gains"
	SetVariable setvar3,pos={125,32},size={100,16},proc=SetPGainCPD,title="PGain"
	SetVariable setvar3,limits={-inf,inf,0.05},value= root:packages:trEFM:EFMFilters[%KP][%PGain]
	SetVariable setvar4,pos={125,55},size={100,16},proc=SetIGainCPD,title="IGain"
	SetVariable setvar4,value= root:packages:trEFM:EFMFilters[%KP][%IGain]
	SetVariable setvar5,pos={125,79},size={100,16},proc=SetDGainCPD,title="DGain"
	SetVariable setvar5,limits={-inf,inf,0.0001},value= root:packages:trEFM:EFMFilters[%KP][%DGain]
	SetVariable setvar0,pos={13,33},size={100,16},proc=SetPGain,title="PGain"
	SetVariable setvar0,limits={-inf,inf,0.01},value= root:packages:trEFM:PointScan:SKPM:Freq_PGain
	SetVariable setvar1,pos={13,57},size={100,16},proc=SetIGain,title="IGain"
	SetVariable setvar1,limits={-inf,inf,0.01},value= root:packages:trEFM:PointScan:SKPM:Freq_IGain
	SetVariable setvar2,pos={13,81},size={100,16},proc=SetDGain,title="DGain"
	SetVariable setvar2,limits={-inf,inf,0.0001},value= root:packages:trEFM:PointScan:SKPM:Freq_DGain
EndMacro

Function SetPGain(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			td_wv("ARC.PIDSLoop.5.PGain",dval)
			//td_wv("ARC.Lockin.0.theta.PGain",dval)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function SetIGain(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			td_wv("ARC.PIDSLoop.5.IGain",dval)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function SetDGain(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			td_wv("ARC.PIDSLoop.5.DGain",dval)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End




