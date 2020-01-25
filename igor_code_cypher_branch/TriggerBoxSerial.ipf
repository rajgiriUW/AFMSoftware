#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function phaseset(phase)
	Variable phase
	string outstring
	string echon = "echo 1\r"
	string command = "phaseset " + num2str(phase) + "\r"
	
	//VDT2 /P=COM3 baud=9600,databits=8,parity=0,stopbits=2,in=1,out=1
	VDTOperationsPort2 COM4
	VDTWrite2 command
	//VDTRead2/O=3 outstring
	
	//print outstring
	
End

Function phaseres(res)
	Variable res
	string outstring
	string command = "phaseres " + num2str(res) + "\r"
	string echon = "echo 1\r"
	VDT2 /P=COM4 baud=9600,databits=8,parity=0,stopbits=2,in=1,out=1
	VDTOperationsPort2 COM4
	VDTWrite2 command
	VDTRead2/O=3 outstring
	
	print outstring
	
End

Function freqset()
	String savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:FFtrEFMConfig
	Wave PixelConfig
	Variable Frequency = Pixelconfig[%drive_freq]
	string outstring
	string command = "freqset " + num2str(frequency) + "\r"
	string echon = "echo 1\r"
	VDT2 /P=COM3 baud=9600,databits=8,parity=0,stopbits=2,in=1,out=1
	VDTOperationsPort2 COM3
	VDTWrite2 echon
	VDTWrite2 command
	VDTRead2/O=3 outstring
	
	print outstring
	
End

Function trigpol(polarity)
	Variable polarity // 0 = inverted (inverted), 1 = normal
	string outstring
	string command = "trigpol " + num2str(polarity) + "\r"
	string echon = "echo 1\r"
//	VDT2 /P=COM3 baud=9600,databits=8,parity=0,stopbits=2,in=1,out=1
	VDTOperationsPort2 COM4
	VDTWrite2 command
//	VDTRead2/O=3 outstring
	

End