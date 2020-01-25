#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Written 08/2017 by Lucas Flagg and Jake Precht


//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//
//Simple functions for diagnosis and experiment building//
//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//

Function testbeep()
		VDT2 /P=COM4 baud=115200, databits=8, parity=0, stopbits=2,in=1,out=1
		VDTOperationsPort2 COM4
		VDTWrite2 "b"
End


Function getinfo()
		VDT2 /P=COM4 baud=115200, databits=8, parity=0, stopbits=2,in=1,out=1, terminalEOL=0
		VDTOperationsPort2 COM4
		VDTWrite2 "i"
		string outstring
		VDTRead2/O=5/t="$" outstring
		print outstring
End


Function getstep()
		VDT2 /P=COM4 baud=115200, databits=8, parity=0, stopbits=2,in=1,out=1
		VDTOperationsPort2 COM4
		VDTWrite2 "sr"
		string outstring
		VDTRead2/O=2/t="$" outstring
		print "motor step is " + outstring + " (whole step is 1.25 microns; 2 = 1/2, 3 = 1/4, 4 = 1/8, 5 = 1/16)"
End	


Function setstep(stepnumber)
		variable stepnumber
		string writestep
		VDT2 /P=COM4 baud=115200, databits=8, parity=0, stopbits=2,in=1,out=1
		VDTOperationsPort2 COM4
		writestep = "ss" + num2str(stepnumber)
		VDTWrite2 writestep /// options 1,2,3,4,5
		sleep/s 1
		getstep()
End

				
Function getspeed()
		VDT2 /P=COM4 baud=115200, databits=8, parity=0, stopbits=2,in=1,out=1
		VDTOperationsPort2 COM4
		VDTWrite2 "vr"
		string outstring
		VDTRead2/O=2/t="$" outstring
		print "motor speed is " + outstring
End	


Function setspeed(xspeed,yspeed)
		variable xspeed, yspeed
		string writespeed
		VDT2 /P=COM4 baud=115200, databits=8, parity=0, stopbits=2,in=1,out=1
		VDTOperationsPort2 COM4
		writespeed = "vs" + num2str(xspeed) + "," + num2str(yspeed) +"$"
		VDTWrite2 writespeed
		
		sleep/s 1
		getspeed()
End


Function getaccel()
		VDT2 /P=COM4 baud=115200, databits=8, parity=0, stopbits=2,in=1,out=1
		VDTOperationsPort2 COM4
		VDTWrite2 "ar"
		string outstring
		VDTRead2/O=2/t="$" outstring
		print "motor acceleration is " + outstring		
End


Function setaccel(xaccel,yaccel)
		variable xaccel,yaccel
		string writeaccel
		VDT2 /P=COM4 baud=115200, databits=8, parity=0, stopbits=2,in=1,out=1
		VDTOperationsPort2 COM4
		writeaccel = "as" + num2str(xaccel) + "," + num2str(yaccel) + "$"
		VDTWrite2 writeaccel
		
		sleep/s 1
		getaccel()
End


Function getpos()
		VDT2 /P=COM4 baud=115200, databits=8, parity=0, stopbits=2,in=1,out=1
		VDTOperationsPort2 COM4
		VDTWrite2 "p"
		string outstring
		VDTRead2/O=2 /t="$" outstring
		print "laser position is " + outstring
End


Function setpos(xx, yy)
		variable xx, yy
		string pos = "ga" + num2str(xx*1000) + "," + num2str(yy*1000) + "$"
		VDT2 /P=COM4 baud=115200, databits=8, parity=0, stopbits=2,in=1,out=1
		VDTOperationsPort2 COM4
		VDTWrite2 pos
				
		sleep/s 1
		getpos()
End


Function zero()
		VDT2 /P=COM4 baud=115200, databits=8, parity=0, stopbits=2,in=1,out=1
		VDTOperationsPort2 COM4
		VDTWrite2 "ga0,0$"
				
		sleep/s 1
		getpos()
End

Function closeport(com_number) //The user ONLY inputs the port number
							   //E.G. to close COM5, use closeport(5)
		variable com_number
		VDTClosePort2 $"COM" + num2str(com_number)
End


Function testmotion()
		do
		setpos(70,-70)
		sleep/s 3
		setpos(0,0)
		sleep/s 3
		setpos(-70,70)
		sleep/s 3
		setpos(0,0)
		sleep/s 3
		while(1==1)
End

//BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB//
//*******************NLPC image scan***********************//
//BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB//

Function ImageVariousBias	()
	
	NewPath/O Path

	 Sleep/s 1
	 //ImageScanNLPC(0, 0, 100, 100, 15, 15, 5, 1000, 5000, -0.075, 1.8, 0, "0V_light_140um_15step")
	 Sleep/s 1
	 //ImageScanNLPC(0, 0, 140, 140, 15, 15, 5, 1000, 5000, -0.075, 1.8, 10, "10V_light_140um_15step")
	 Sleep/s 1
	 //ImageScanNLPC(0, 0, 100, 0, 1, 201, 5, 1000, 5000, -0.075, 2, 0, "0V_A4_TOPO_spot2_500nm step_d")
	 Sleep/s 1
	 //ImageScanNLPC(0, 0, 100, 0, 1, 201, 5, 1000, 5000, -0.075, 2, -1, "-1V_A4_TOPO_spot2_500nm step_d")
	 Sleep/s 1
	 //ImageScanNLPC(0, 0, 100, 0, 1, 201, 5, 1000, 5000, -0.075, 2, 1, "1V_A4_TOPO_spot2_500nm step_d")
	 Sleep/s 1
	 //ImageScanNLPC(0, 0, 10, 10, 21, 21, 5, 1000, 5000, -0.075, 1.8, 3, "3V_light_10um_21step")
	 Sleep/s 1
end