#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function nplcinit()

	NewDataFolder/O/S root:Packages:trEFM:ImageScan:NPLC
	
	String savedDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM:ImageScan:NPLC
	
	variable/G motor_step = 1
	variable/G motor_speed = 1000 
	variable/G motor_accel = 5000
	variable/G nplc_voltage = 0 
	
	variable/G reengage_per_pixel = 0
	variable/G print_positions = 0
	
	variable/G nplc_interp = 1000
	
	variable/G laserX = 0
	variable/G laserY = 0
	
	string/G nplc_filename = "NPLC"

	SetDataFolder savedDF
end

// If you edit the Panel, add nplcinit() as the first line
Window NLPC_Panel() : Panel
	nplcinit()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1170,574,1455,988)
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fsize= 16,fstyle= 1
	DrawText 9,29,"NLPC Panel"
	DrawRect 16,59,271,208
	Button button0,pos={9,33},size={83,21},proc=TestBeepButton,title="Test Connection"
	Button StartScan,pos={35,354},size={111,44},proc=NLPC_ScanButton,title="Start Scanning"
	Button StartScan,fSize=14,fStyle=1
	ValDisplay NLPC_SP,pos={129,34},size={118,14},title="Defl Setpoint"
	ValDisplay NLPC_SP,limits={0,0,0},barmisc={0,1000}
	ValDisplay NLPC_SP,value= #"root:packages:mfp3d:main:variables:MasterVariablesWave[%DeflectionSetpointVolts][%Value]"
	SetVariable setvar13,pos={70,62},size={62,16},title="X"
	SetVariable setvar13,help={"X Stage Position (in microns)"}
	SetVariable setvar13,limits={-inf,inf,0},value= root:packages:trEFM:gxpos
	SetVariable setvar14,pos={157,62},size={61,16},title="Y"
	SetVariable setvar14,help={"Y Stage Position (in microns)"}
	SetVariable setvar14,limits={-inf,inf,0},value= root:packages:trEFM:gypos
	Button button16,pos={194,86},size={62,19},proc=GetMFPOffset,title="Grab Offset"
	Button button16,help={"Fill the X,Y with the current stage position."}
	Button button14,pos={38,83},size={74,23},proc=MoveHereButton,title="Move Here"
	Button button14,help={"Move to the X,Y position given above."}
	Button button15,pos={121,86},size={57,19},proc=GetCurrentPositionButton,title="Current XY"
	Button button15,help={"Fill the X,Y with the current stage position."}
	SetVariable setvar8,pos={37,142},size={92,16},title="Width (µm)"
	SetVariable setvar8,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizex
	SetVariable setvar0,pos={144,141},size={112,16},title="Scan Points"
	SetVariable setvar0,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanpoints
	SetVariable setvar1,pos={144,162},size={112,16},title="Scan Lines"
	SetVariable setvar1,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scanlines
	SetVariable setvar9,pos={37,163},size={92,16},title="Height (µm)"
	SetVariable setvar9,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:scansizey
	Button button1,pos={28,271},size={72,23},proc=NLPC_ZeroButton,title="Zero Laser"
	SetVariable InterpVal,pos={154,219},size={119,16},title="Interpolation   "
	SetVariable InterpVal,limits={1,10000,0},value= root:packages:trEFM:ImageScan:NPLC:nplc_interp
	SetVariable nplcmotorstep,pos={16,212},size={111,16},title="Motor Step"
	SetVariable nplcmotorstep,limits={0,inf,0},value= root:packages:trEFM:ImageScan:NPLC:motor_step
	SetVariable nplcmotorspeed,pos={16,232},size={111,16},title="Motor Speed"
	SetVariable nplcmotorspeed,limits={0,inf,0},value= root:packages:trEFM:ImageScan:NPLC:motor_speed
	SetVariable nplcmotoraccel,pos={16,252},size={111,16},title="Motor Accel"
	SetVariable nplcmotoraccel,limits={0,inf,0},value= root:packages:trEFM:ImageScan:NPLC:motor_accel
	ValDisplay NLPC_DAC,pos={129,14},size={118,14},title="DAC Offset"
	ValDisplay NLPC_DAC,limits={0,0,0},barmisc={0,1000}
	ValDisplay NLPC_DAC,value= #"root:packages:mfp3d:main:variables:MasterVariablesWave[%SurfaceBiasOffset][%Value]"
	SetVariable nplc_filename,pos={14,330},size={144,16},title="Filename"
	SetVariable nplc_filename,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:NPLC:nplc_filename,styledText= 1
	CheckBox nplc_reengagepxl,pos={154,244},size={119,14},title="Re-engage per-pixel?"
	CheckBox nplc_reengagepxl,variable= root:packages:trEFM:ImageScan:NPLC:reengage_per_pixel
	SetVariable nplc_voltage,pos={83,187},size={111,16},title="Sample Voltage"
	SetVariable nplc_voltage,limits={-10,10,0},value= root:packages:trEFM:ImageScan:NPLC:nplc_voltage
	SetVariable setvarLaserX,pos={41,111},size={92,16},title="Laser X"
	SetVariable setvarLaserX,help={"X Stage Position (in microns)"}
	SetVariable setvarLaserX,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:NPLC:laserX
	SetVariable setvarLaserY,pos={145,110},size={91,16},title="Laser Y"
	SetVariable setvarLaserY,help={"Y Stage Position (in microns)"}
	SetVariable setvarLaserY,limits={-inf,inf,0},value= root:packages:trEFM:ImageScan:NPLC:laserY
	CheckBox nplc_verbose,pos={154,265},size={89,14},title="Print positions?"
	CheckBox nplc_verbose,variable= root:packages:trEFM:ImageScan:NPLC:print_positions
	Button buttonReset,pos={177,361},size={89,24},proc=NLPC_Reset,title="Default Setitngs"
EndMacro


Function TestBeepButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			testbeep()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function NPLC_REengageCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	NVAR reengage_per_pixel = root:Packages:trEFM:ImageScan:NPLC:reengage_per_pixel

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			reengage_per_pixel = checked
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function NLPC_ScanButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String savedDF = GetDataFolder(1)

	SetDataFolder root:Packages:trEFM:ImageScan
	NVAR scanlines, scanpoints, scansizex, scansizey

	SetDataFolder root:Packages:trEFM
	NVAR gxpos, gypos

	SetDataFolder root:Packages:trEFM:ImageScan:NPLC
	NVAR motor_step, motor_speed, motor_accel, nplc_voltage, laserX, laserY
	SVAR nplc_filename

	Wave MVW = root:packages:mfp3d:main:variables:MasterVariablesWave
	variable DeflectionSP = MVW[%DeflectionSetpointVolts][%Value]

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			//graboffset()
			ImageScanNLPC(gxpos, gypos, laserX, laserY, scansizeX,scansizeY, scanlines, scanpoints, motor_step, motor_speed, motor_accel, DeflectionSP, nplc_voltage, nplc_filename)
			SetDataFolder savedDF
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function NLPC_ZeroButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			zero()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function NLPC_Reset(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String savedDF = GetDataFolder(1)

	SetDataFolder root:Packages:trEFM:ImageScan
	NVAR scanlines, scanpoints, scansizex, scansizey

	SetDataFolder root:Packages:trEFM
	NVAR gxpos, gypos

	SetDataFolder root:Packages:trEFM:ImageScan:NPLC
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			nplcinit()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End