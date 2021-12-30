#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ImageScanNLPC(xpos, ypos, laserX,laserY, scansizeX,scansizeY, scanlines, scanpoints, motorstep, motorspeed, motoraccel, DeflectionSP, bias, savename)
	variable xpos, ypos, scansizeX, scansizeY, laserX, laserY, motorstep, motorspeed, motoraccel, scanlines, scanpoints, bias, DeflectionSP
	string savename

	//xpos,ypos = xposition, yposition of AFM tip in microns
	//scansizeX,scansizeY = how many microns in X,Y we wish to scan over
	//motorstep = step size of micrometer motors (acceptable values are 1,2,3,4,5 with corresponding step sizes of 1, 1/2, 1/4, 1/8, and 1/16)
	//motorspeed = speed of micrometer motors in um/s (been using 1000 but not set on this)
	//motoraccel = acceleration of micrometer motors (been using 5000 but not set on this)
	//Voffset = the sample bias offset for the chip holder.  As of 8/4/17, it is ~54 mV for 0.2 nA/V holder and ~75 mV for 2 nA/V (UNITS ARE VOLTS)
	//savename = what you want the saved image to be named.  NOTE THIS MUST BE IN QUOTES
	
	// need to apply voltages -- would be nice to grab from the panel
	
	ResetAll()
	GetGlobals()  //getGlobals ensures all vars shared with asylum are current
	
	//Send parameters to arduino/motor
	setstep(motorstep)
	setspeed(motorspeed,motorspeed)
	setaccel(motoraccel,motoraccel)
	
	//Set path for saving later
	NewPath/O Path

	
	//THE BELOW LINE SHOULD PROBABLY GO INTO trEFMinit.ipf WHEN THE CODING IS IN FINAL VERSION AND THEN UPLOAD TO SOURCETREE

	
	SetDataFolder root:Packages:trEFM:ImageScan:NPLC
	String savDF = GetDataFolder(1)
	
	NVAR nplc_interp, reengage_per_pixel
	
	Wave MVW = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	//MVW[%SurfaceBiasOffset][%value]=Voffset
	print MVW[%SurfaceBiasOffset][%value]
	
	Variable starttime,starttime2,starttime3 //Don't think I included any of these time checks in my final code
	//NVAR Setpoint =  root:Packages:trEFM:Setpoint
	//NVAR PGain = root:Packages:trEFM:PGain
	//NVAR IGain = root:Packages:trEFM:IGain
	//NVAR SGain = root:Packages:trEFM:SGain
	
	variable PGain = 0 
	variable SGain = 0
	variable IGain = MVW[%IntegralGain][%Value] * 100
	
	//Create collection waves
	Make/O/N = (scanpoints, scanlines) PC_array //where all data will end up for saving
	Make/O/N = (scanpoints, scanlines) PC_error_array 
	Make/O/N = (scanpoints, scanlines) PC_SNR_array 
	Make/O/N = (128) ReadWavePC //where data is temporarily stored as PC is read in at each pixel.  Change this number to change number of averages per pixel
	//number in parenthesis is how many times to read the current
	ReadWavePC = NaN
	
	//Make image window
	dowindow/f PCImage
	if (V_flag==0)
		Display/K=1/n=PCImage;Appendimage PC_array
		SetAxis/A bottom
		SetAxis/A left
		Label bottom "X (points)"
		Label left "Y (points)"
		ModifyGraph wbRGB=(62000,65000,48600),expand=.7
		ModifyImage PC_array ctab= {0,20000,VioletOrangeYellow,0}
		ColorScale/C/N=text0/E/F=0/A=MC image=PC_array
		ColorScale/C/N=text0/A=RC/X=5.00/Y=5.00/E=2 "Photocurrent (nA)"
		ColorScale/C/N=text0/X=5.00/Y=5.00/E image=PC_array
	endif
	
	ModifyGraph/W=PCImage height = {Aspect, scansizeY/scansizeX}		
	if (scansizeY/scansizeX < .2)
		ModifyGraph/W=PCImage height = {Aspect, 1}
	endif
	
	//stop all FBLoops except for the XY loops just in case
	StopFeedbackLoop(3)
	StopFeedbackLoop(4)
	StopFeedbackLoop(5)
		
	//WAVE EFMFilters=root:Packages:trEFM:EFMFilters //think this is unnescessary but unsure of what it does so leaving in
	//SetPassFilter(1,q=EFMFilters[%EFM][%q],i=EFMFilters[%EFM][%i],a=EFMFilters[%EFM][%A],b=EFMFilters[%EFM][%B])
	
	//NVAR defSetpoint
	
	//move AFM tip to desired location if not already there (probably not currently there if just finished a topo scan where xpos,ypos is origin) and set crosspoint
	//MoveXY(xpos,ypos)
	//Sleep/s 1
	//SetCrosspoint ("Filterout","Ground","PogoIn0","Ground","Ground","Ground","Off","Off","Off","Defl","Ground","OutC","Ground","OutC","Ground","DDS")
	
	MoveXY(xpos, ypos)
	
	SetCrosspoint ("Lateral","PogoIn0","FilterOut","Ground","Ground","Ground","Off","Off","Off","Defl","Ground","OutC","Ground","OutC","Ground","DDS")


	//*********************************************************************//
	//Starting imaging loop here
	//*********************************************************************//
	
//Let's try making an absolute micrometer movement loop
//Starting position is (0,0) from the perspective of the micrometer motors
//This position requires the user to align the laser to the tip by hand first without using the micrometers.  Later will need to figure out a relative movement scheme if wish to automate the alignment of laser to tip, but this is fastest first approach
//Going to implement by making a 1D wave of x values and a 1D wave of y values
//Then within an imaging loop, I will pluck out the desired x and y values and send them to setpos(xx,yy) which moves the micrometers
//Scans should start in upper left corner as written
	Make/O/N = (scanpoints) xmotorpos
	Make/O/N = (scanlines) ymotorpos
	variable i,j
	variable xposoffset, yposoffset //used to offset from (0,0) as origin to xymotor[0][0] being at (-ScanSizeX/2,ScanSizeY/2) ---this sets scan to start from upper left corner
	xposoffset = -(ScanSizeX/2) + laserX
	yposoffset =(ScanSizeY/2) + laserY
	print "initial x position is " +  num2str(xposoffset)
	print  "initial y position is " + num2str(yposoffset)
	variable xstep, ystep //space between pixels in x and y direction
	xstep = (ScanSizeX/(scanpoints-1))
	ystep = (ScanSizeY/(scanlines-1))
	print "x step size is" + num2str(xstep) + " um"
	print "y step size is" + num2str(ystep) + " um"

	i=0 //index for x loop
	j=0 //index for y loop
	
	//populate x and y
	do
		xmotorpos[i] = xposoffset + i*xstep
		i += 1
	while (i<scanpoints)
	print xmotorpos
	
	if (scanlines==1)
		ymotorpos[0] = 0
	else
		do
			ymotorpos[j] = yposoffset - j*ystep
			j +=1
		while (j<scanlines)
	endif
	print ymotorpos

	print "pre-contact deflection is " + num2str(td_rv("Deflection"))
	variable tempdeflection, tempsetpoint
	tempdeflection = td_rv("Deflection")
	//print "free deflection is " + num2str(tempdeflection)
	// EDIT SETPOINT HERE
	tempsetpoint = tempdeflection +DeflectionSP
	
	print "deflection setpoint is " + num2str(tempsetpoint)

	// Disengage Tip, Move Laser to initial spot
	SetFeedbackLoop(2, "Always", "Deflection", -1, -pgain, igain, -sgain, "Height", 0)
	setpos(xmotorpos[0],ymotorpos[0]) //move motors

	//apply a voltage to the sample
	td_wv("Output.C", bias) 
	
	Sleep/S 2 //allow feedback loop to settle
	
	//Set up the contact mode feedback
	SetFeedbackLoop(2, "Always", "Deflection", tempsetpoint, -pgain, igain, -sgain, "Height", 0)

	Sleep/S 2 //allow feedback loop to settle
	print "setpoint is " + num2str(tempsetpoint) + " deflection is " + num2str(td_rv("Deflection"))
		
	print "Sample voltage " + num2str(td_rv("Output.C"))

	//************************************************************************** //
	//MAIN IMAGING LOOP//
	i=0
	j=0
	

	// 2019 - 10 25: Raj
	// If instead you want to 
	// 	At each pixel, run ARDoIVButtonFunc("ARDoIVDoItButton_1")
	//	Then, save these values:
	//		current = root:packages:MFP3D:Orca:DoIV:Current
	//		bias = root:packages:MFP3D:Orca:DoIV:Bias (only need to save this once at the end)
	//
	//	Make/N=(xpixel, ypixels, rows_in_current) IVMatrix = NaN
	//	IVMatrix[xpixel][ypixel][] = current
	//	IVMatrix[][][3]

	
	do //y loop (slow scan)
		do //x loop (fast scan)
			print "point index is " + num2str(i) + " , " +num2str(j)

			if (reengage_per_pixel == 1)
				SetFeedbackLoop(2, "Always", "Deflection", -1, -pgain, igain, -sgain, "Height", 0)
				Sleep/S .2
			endif
		
			print "X Position = ", (td_readvalue("XSensor") - td_RV("XLVDToffset")) * td_rv("XLVDTSens") * 1e6
			print "Y Position = ", (td_readvalue("YSensor") - td_RV("YLVDToffset")) * td_rv("YLVDTSens") * 1e6
					
			setpos(xmotorpos[i],ymotorpos[j]) //move motors
			//Sleep/S (1/100)
			Sleep/S(1/10)

			if (reengage_per_pixel == 1)
				tempdeflection = td_rv("Deflection")
				tempsetpoint = tempdeflection + DeflectionSP	
				print num2str(td_rv("Deflection"))
				SetFeedbackLoop(2, "Always", "Deflection", tempsetpoint, -pgain, igain, -sgain, "Height", 0)
				Sleep/S 0.2 //allow feedback loop to settle
			endif
		
			if (td_rv("ZSensor") < -7) 	// drifted out of range
				print "Drifted out of range"
				print num2str(td_rv("Deflection"))
			endif
		
			td_xSetInWave(0, "Event.2", "Input.B", ReadWavePC, "", nplc_interp) //set-up next read in of photocurrent
			ReadWavePC = NaN
			//print td_rv("Input.B")
			Sleep/S (1/30)
		      print time()
		      
			//Fire data collection event
			td_WriteString("Event.2","Once")
		
			CheckInWaveTiming(ReadWavePC) //this will not let the code go to the next line until the condition is met that ReadWavePC is full
		  
			// Stop data collection
			td_StopInWaveBank(-1)
		      	//print ReadWavePC
			wavestats/q ReadWavePC //gets stats (will pull average photocurrent (V_avg) from the ReadWavePC wave)
		     	//print ReadWavePC
		     	//print time()	      
			PC_array[i][j]  = V_avg*-0.2 //write photocurrent value to my collection array
			PC_error_array[i][j] = V_sdev*.2
			PC_SNR_array[i][j] = PC_array[i][j]/ PC_error_array[i][j]
			//PC_array[i][j]  = V_avg*-2 , PC_SNR_array for signal to noise ratio check
			// Correct depending on which orca holdder is used 2nA/V or 0.2nA/V
			print "V average is " + num2str(V_avg) + ", average photo current is " + num2str(V_avg*-0.2*1000) +" (pA), SNR is" + num2str(V_avg/V_sdev)
			
			//ReadWavePC = NaN //clear ReadWavePC for next loop iteration
			
			print "deflection is " + num2str(td_rv("Deflection"))
			i +=1
			
			DoUpdate
			
		while (i<scanpoints)
		
		doupdate 
		j += 1
		i = 0
		
		//print "pre-contact deflection is " + num2str(td_rv("Deflection"))

		//print "free deflection is " + num2str(tempdeflection)
		// EDIT SETPOINT HERE
		
	
		// Re-engage the feedback loop, assumes -1V is below the free air defleciton
		SetFeedbackLoop(2, "Always", "Deflection", -1, -pgain, igain, -sgain, "Height", 0)
		Sleep/S 1
		
		if (j < scanlines)
			setpos(xmotorpos[i],ymotorpos[j]) //move motors
		endif
		
		tempdeflection = td_rv("Deflection")
		tempsetpoint = tempdeflection + DeflectionSP		
		SetFeedbackLoop(2, "Always", "Deflection", tempsetpoint, -pgain, igain, -sgain, "Height", 0)
		Sleep/S 1 //allow feedback loop to settle
	
		//print "deflection setpoint is " + num2str(tempsetpoint)
	while (j<scanlines)
	// end imaging loop 
	//************************************************************************** //
	

//Save and wrap it up!
	string name
	name = savename + ".ibw"
	Save/C/O/P = Path PC_array as name	
	
	string name1
	name1 = savename + "_error.ibw"
	Save/C/O/P = Path PC_error_array as name1
	
	string name2
	name2 = savename + "_SNR.ibw"
	Save/C/O/P = Path PC_SNR_array as name2
	
	
	//Signal end of scan to user
	Beep

	doscanfunc("stopengage")
       setpos(laserX,laserY)
//	doscanfunc("stopengage")

End





Function testcalibration(stepnumber,stepsize,originx,originy) //stepsize in um
	variable stepnumber,stepsize,originx,originy
	variable k
	k = 0
	do 
		setpos(stepsize*k + originx,stepsize*k + originy)
		//setpos((0.5*k + 0.5),(0.5*k + 0.5))
		//setpos(0.5*k,0.5*k)
		Sleep/s 0.5
		k+=1
	while (k<stepnumber)
end
		

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///// using the DoIV panel to collect. Maybe our engage or collection is the problem//////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function NLPC2 (xpos, ypos, scansizeX, scansizeY, scanpoints, scanlines) 
	variable xpos, ypos, scansizeX, scansizeY, scanlines, scanpoints
	ResetAll()
	GetGlobals()  //getGlobals ensures all vars shared with asylum are current
	
	//*********************************************************************//
	// Construct laser positions array
	//*********************************************************************//
	
	Make/O/N = (scanpoints) xmotorpos
	Make/O/N = (scanlines) ymotorpos
	variable i,j
	variable xposoffset, yposoffset //used to offset from (0,0) as origin to xymotor[0][0] being at (-ScanSizeX/2,ScanSizeY/2) ---this sets scan to start from upper left corner
	xposoffset = -(ScanSizeX/2)+xpos
	yposoffset =(ScanSizeY/2)+ypos
	print xposoffset
	print yposoffset
	variable xstep, ystep //space between pixels in x and y direction
	xstep = (ScanSizeX/(scanpoints-1))
	ystep = (ScanSizeY/(scanlines-1))
	print xstep
	print ystep

	i=0 //index for x loop
	j=0 //index for y loop
	
	//populate x and y
	do
		xmotorpos[i] = xposoffset + i*xstep
		i += 1
	while (i<scanpoints)
	print xmotorpos
	
	if (scanlines==1)
		ymotorpos[0] = 0
	else
		do
			ymotorpos[j] = yposoffset - j*ystep
			j +=1
		while (j<scanlines)
	endif
	print ymotorpos

	// run one point scan to get dimensions
	setpos(0,0)
	
	 ARDoIVButtonFunc("ARDoIVDoItButton_1")
	 Make/O current
	 Wave current = root:packages:MFP3D:Orca:DoIV:Current
	 Make/O bias
	 Wave bias = root:packages:MFP3D:Orca:DoIV:Bias
	 
	 variable Isize = numpnts(current)
	 Make/O/N = (scanpoints,scanlines, Isize)IVMatrix 
	 IVMatrix[][][] = NaN
	 

// 2019 - 10 25: Raj
	// If instead you want to 
	// 	At each pixel, run ARDoIVButtonFunc("ARDoIVDoItButton_1")
	//	Then, save these values:
	//		current = root:packages:MFP3D:Orca:DoIV:Current
	//		bias = root:packages:MFP3D:Orca:DoIV:Bias (only need to save this once at the end)
	//
	//	Make/N=(xpixel, ypixels, rows_in_current) IVMatrix = NaN
	//	IVMatrix[xpixel][ypixel][] = current
	//	IVMatrix[][][3]
	//************************************************************************** //
	//MAIN IMAGING LOOP//
	i=0
	j=0
	variable k =0

	do //y loop (slow scan)
		do //x loop (fast scan)
			print i
			print j
			k=0
			setpos(xmotorpos[i],ymotorpos[j]) //move motors
			Sleep/S (1/100)
//			current = Nan
			ARDoIVButtonFunc("ARDoIVDoItButton_1")
			Wave current = root:packages:MFP3D:Orca:DoIV:Current
			//IVMatrix[i][j][] = current[q]
			do
				IVMatrix[i][j][k] = current[k]
				k += 1
			while ( k < Isize)
			i +=1
			doupdate 
		while (i<scanpoints)
		print "end of line " + num2str(j+1)
		doupdate 
		j += 1
		i = 0
	while (j<scanlines)
	// end imaging loop 
	//*****************************

DUplicate/O/R=[][][5] IVMatrix, ImgSlice
NewImage ImgSlice

end




