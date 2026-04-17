#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Window ShutterPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(409,62,597,169)
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (56576,56576,56576)
	DrawRect 4,2,182,102
	Button Select_Port_Control,pos={12,28},size={80,20},proc=OpenPortButton,title="Open Port"
	Button ReadPortButton,pos={58,6},size={75,21},proc=VDTinitButton,title="Read Ports"
	Button Select_Port_Control1,pos={96,28},size={80,20},proc=ClosePortButton,title="Close Port"
	Button InitShutterButton,pos={54,51},size={78,21},proc=InitShutterButton,title="Init. Shutter"
	Button CloseShutterButton,pos={39,75},size={54,23},proc=CloseShutterButton,title="CLOSE"
	Button CloseShutterButton,fStyle=1
	Button OpenShutterButton1,pos={95,75},size={54,23},proc=OpenShutterButton,title="OPEN"
	Button OpenShutterButton1,fStyle=1
	ToolsGrid visible=1
EndMacro

Function OpenPortButton(ctrlname): ButtonControl
	String ctrlname
	String savDF = GetDataFolder(1)
	String name
	Variable type
	Prompt name, "Type Port To Select"
	DoPrompt "Select Port To Open",name
	SelectPort(name)
End

Function ClosePortButton(ctrlname): ButtonControl
	String ctrlname
	String savDF = GetDataFolder(1)
	String name
	Variable type
	Prompt name, "Type Port To Close"
	DoPrompt "Select Port To Close",name
	ClosetPort(name)
End

Function VDTinitButton(ctrlname): ButtonControl
	String ctrlname
	VDTGetPortList2
	print "Port List", S_VDT
End

Function InitShutterButton(ctrlname): ButtonControl
	String ctrlname
	InitShutter()
	print "Shutter Initialized"
End

Function OpenShutterButton(ctrlname): ButtonControl
	String ctrlname
	String angle = "20"
	SetShutterAngle(angle)
	print "Shutter Opened"
End

Function CloseShutterButton(ctrlname): ButtonControl
	String ctrlname
	String angle = "160"
	SetShutterAngle(angle)
	print "Shutter Closed"
End


Function SelectPort(port)
	String Port
	VDTOperationsPort2 $Port
	print "Opened Port:", port
End

Function ClosetPort(port)
	String Port
	VDTClosePort2 $Port
	print "Closed Port:", port
End

Function InitShutter()
		VDTWrite2 /O=2 "20"	
		sleep/s .5
		VDTWrite2 /O=2 "160"	
		sleep/s .5
		VDTWrite2 /O=2 "90"	
		sleep/s .5
End

Function SetShutterAngle(angle)
	String angle
	VDTWrite2 /O=2 angle	
End


