#pragma rtGlobals=3		// Use modern global access method and strict wave access.
Function SetEFMvf(voltage,frequency,[sleeptime])
	Variable voltage,frequency,sleeptime

	Setvf(voltage, frequency, "WG")		
	if (paramIsDefault(sleeptime))
		sleeptime = 1e-3
	endif

	Sleep/S sleeptime

End

Function InitBoardAndDeviceLIAAWG()

	string SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM

	variable V_flag
	// These variables are useful for NI-488.2 calls using the NI4882 command.
	Variable/G gHasGPIB, gBoardAddress, gLIADeviceAddress, gWGDeviceAddress, gWGDeviceAddress2
	
	// These variables are useful for pre-NI-488.2 keywords and for the
	// GPIB board and GPIB device calls.
	Variable/G gBoardUnitDescriptor, gLIADeviceUnitDescriptor, gWGDeviceUnitDescriptor

	// These are defaults for the current system, these are the ONLY values associated with the
	//GPIB board and devices that should need to be changed if equipment is changed
	gBoardAddress=0 // if more then one board is available this value will have to be determined and set
	String LIAModelNumber = "SR830"  //model num string for standford research sr830
	String WGModelNumber = "33120A" //model num for agilent wave generator
	//END of hardcoded vars
	
	Variable errorcnt=0,i
	String error="", curModelNumber=""
	Variable numDevices
	
	//first we search for the gpib board and set the board unit descriptor
	NI4882/Q ibfind={"gpib0"}; gBoardUnitDescriptor = V_flag
	if (V_flag==-1) // no gpib board was found
		NI4882/Q ibfind={"gpib1"}; gBoardUnitDescriptor = V_flag
	endif
	
	if (V_flag==-1)
		errorcnt+=1
		error += "No GPIB Board was found\r"
		gHasGPIB=0
	else  // board was found, set gpib flag to true and make board controller-in-charge
		gHasGPIB=1
		NI4882 ibsic={gBoardUnitDescriptor}
		numDevices = FindListeners()
		if (numDevices==0)
			gHasGPIB=0
		endif
	endif
	
	if (gHasGPIB==1) //if we have a board, try to determine the devices
	
		numDevices = FindListeners()	// find out how many devices are connected and 
									// put all device IDs into wave called gResultList
		
		WAVE gResultList

		for (i=0; i<numDevices; i+=1)
			
			if (gResultList[i]>0) //the first board has a device address of 0 and should be excluded

				// get the model number string
				GPIBsetup()
				WriteGPIB(gResultList[i],"*rst")
				WriteGPIB(gResultList[i],"*idn?")
				curModelNumber = ReadGPIB(gResultList[i], 4,2)
				
				//check the model number against the model number strings hardcoded at top of this function
				if (stringmatch(curModelNumber,LIAModelNumber)==1)
					gLIADeviceAddress = gResultList[i]
				elseif (stringmatch(curModelNumber,WGModelNumber)==1)
					gWGDeviceAddress = gResultList[i]
				endif
				
			endif
		
		endfor
		
		//now that we have checked all devices, see if both a LIA and a WG are present
		if (gLIADeviceAddress==0)
			errorcnt+=1
			error += "No LIA was found."
		elseif (gWGDeviceAddress==0)
			errorcnt+=1
			error += "No WG was found."
		endif
	
	Endif

	if (errorcnt>0)
		print error
	endif

	SetDataFolder SavedDataFolder
End

Function FindListeners()

	string SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	NVAR gHasGPIB, gBoardAddress

	if (gHasGPIB==1)	
		Make/O gAddressList = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24, -1}		// -1 is NOADDR - marks end of list.
		Make/O/N=0 gResultList
		NI4882/Q FindLstn={gBoardAddress,gAddressList,gResultList,5}
	endif
	
	SetDataFolder SavedDataFolder
	
	return V_ibcnt
End

function GPIBsetup()
	// This function is very simple, it causes the board to be the CIC and sends all devices a clearI/O command
	// It should be safe and prudent to call this everytime you want to run a GPIB function

	string SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gHasGPIB, gBoardAddress
	
	//according to ni488.2 help docs the device commands should be set to the unit descriptor
	//however, all attemps to use the UD have failed. The following variable, set manually here to zero,
	// is a placeholder for future work. It SHOULD be the actual deviceUD for the device you are trying to clear
	variable DeviceUD
	DeviceUD=0
	
	
	if (gHasGPIB==1)	
		GPIB2 board=gBoardAddress	// Board to use for GPIB InterfaceClear command.
		GPIB2 device=DeviceUD	// Device to use for GPIBXXX operations.
		Gpib2 KillIO							// Inits NIGPIB2 and sends Interface Clear message.
	endif
	
	SetDataFolder SavedDataFolder
end

function/S GetAsciiCode(DeviceAddress, talkOrListen)
	Variable DeviceAddress
	String talkOrListen
	String AsciiAddress

	if (stringmatch(talkOrListen,"MLA")==1)	
		Switch (DeviceAddress)
			Case 0:
				Return " "
			Case 1:
				Return "!"
			Case 2:
				Return "\""
			Case 3:
				Return "#"
			Case 4:
				Return "$"
			Case 5:
				Return "%"
			Case 6:
				Return "&"
			Case 7:
				Return "'"						
			Case 8:
				Return "("
			Case 9:
				Return ")"	
			Case 10:
				Return "*"
			Case 11:
				Return "+"
			Case 12:
				Return ","
			Case 13:
				Return "-"
			Case 14:
				Return "."
			Case 15:
				Return "/"
			Case 16:
				Return "0"
			Case 17:
				Return "1"
			Case 18:
				Return "2"
			Case 19:
				Return "3"
			Case 20:
				Return "4"
			Case 21:
				Return "5"
			Case 22:
				Return "6"
			Case 23:
				Return "7"													
			Case 24:
				Return "8"		
		endswitch
	else
		Switch (DeviceAddress)	
			Case 0:
				Return "@"
			Case 1:
				Return "A"
			Case 2:
				Return "B"
			Case 3:
				Return "C"
			Case 4:
				Return "D"
			Case 5:
				Return "E"
			Case 6:
				Return "F"
			Case 7:
				Return "G"						
			Case 8:
				Return "H"
			Case 9:
				Return "I"	
			Case 10:
				Return "J"
			Case 11:
				Return "K"
			Case 12:
				Return "L"
			Case 13:
				Return "M"
			Case 14:
				Return "N"
			Case 15:
				Return "O"
			Case 16:
				Return "P"
			Case 17:
				Return "Q"
			Case 18:
				Return "R"
			Case 19:
				Return "S"
			Case 20:
				Return "T"
			Case 21:
				Return "U"
			Case 22:
				Return "V"
			Case 23:
				Return "W"													
			Case 24:
				Return "X"		
		endswitch
	endif

end


function WriteGPIB(whichDeviceAddress,cmdString)
	//This function is a wrapper for GPIBWrite2
	//it is used to encapsulate all the preliminary setup and clear messages as
	//well as setting the ascii codes for the requested device
	
	Variable whichDeviceAddress
	String cmdString

	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gBoardUnitDescriptor,gBoardAddress

	GPIBsetup()

	String boardMTA = GetAsciiCode(gBoardAddress,"MTA")		
	String devMLA = GetAsciiCode(whichDeviceAddress,"MLA")

		
	Ni4882 ibcmd={gBoardUnitDescriptor,boardMTA, 0}  //sets the talk address of the board to 0
	Ni4882 ibcmd={gBoardUnitDescriptor,devMLA,0}   // tells the board the listen address of the device, see above for ascii codes
	GPIBwrite2 cmdString

	SetDataFolder SavedDataFolder
end	

function/S ReadGPIB(whichDeviceAddress,numResponses,whichResponse)
	//This function is a wrapper for GPIBWrite2
	//it is used to encapsulate all the preliminary setup and clear messages as
	//well as setting the ascii codes for the requested device
	//the function reads in the first 4 responses and returns the response requested
	
	Variable whichDeviceAddress, numResponses
	Variable whichResponse

	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM

	Make/T/O/N=(numResponses) responseString	
	responseString=""
	NVAR gBoardUnitDescriptor,gBoardAddress
	
	String boardMLA = GetAsciiCode(gBoardAddress,"MLA")
	String devMTA = GetAsciiCode(whichDeviceAddress,"MTA")
		
	Ni4882 ibcmd={gBoardUnitDescriptor,devMTA,1} // see above for talk address ascii codes
	Ni4882 ibcmd={gBoardUnitDescriptor,boardMLA,1}  //sets the listen address for the board

	GPIBReadWave2 responseString

	Return responseString[whichResponse-1]

	SetDataFolder SavedDataFolder
end	


////////////////////////////////// Function that retrives the frequency of the Lockin
function GetFreq(whichDevice)
//////////////****************************************
	String whichDevice
	Variable whichDeviceAddress
	String whatCommand

	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gHasGPIB, gLIADeviceAddress,gWGDeviceAddress
	
	if (stringmatch(whichDevice,"LIA")==1) //asked for the LIA frequency
		whichDeviceAddress = gLIADeviceAddress
		whatCommand = "freq?"
	else // if WG is asked for OR if whichDevice string doesn't match
		whichDeviceAddress = gWGDeviceAddress
		whatCommand = "freq?"
	endif
	
	
	if (gHasGPIB==1)	
		GPIBsetup()
	
		variable frequency
		
		WriteGPIB(whichDeviceAddress,whatCommand)
		
		frequency = str2num(ReadGPIB(whichDeviceAddress,1,1))

		return frequency
	endif
	
	SetDataFolder SavedDataFolder
		
end

function GetVolt(whichDevice)
//////////////****************************************
	String whichDevice
	Variable whichDeviceAddress
	String whatCommand

	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gHasGPIB, gLIADeviceAddress,gWGDeviceAddress
	
	if (stringmatch(whichDevice,"LIA")==1) //asked for the LIA frequency
		whichDeviceAddress = gLIADeviceAddress
		whatCommand = "slvl?"
	else // if WG is asked for OR if whichDevice string doesn't match
		whichDeviceAddress = gWGDeviceAddress
		whatCommand = "volt?"
	endif
	
	if (gHasGPIB==1)	
		GPIBsetup()
	
		variable voltage

 		WriteGPIB(whichDeviceAddress,whatCommand)
		
		voltage = str2num(ReadGPIB(whichDeviceAddress,1,1))

		return voltage
	endif
	
	SetDataFolder SavedDataFolder
		
end

function SetVF(voltage, frequency, whichDevice)

	variable voltage, frequency
	String whichDevice
	Variable whichDeviceAddress
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gBoardAddress, gLIADeviceAddress,gWGDeviceAddress, gHasGPIB

	variable offset=0 //voltage/2 //this is here because half the time we want no voltage
	string writtenstring1
	string writtenstring2
	string writtenstring3

	if (gHasGPIB==1)
		GPIBsetup()

		if (stringmatch(whichDevice,"LIA")==1) //asked for the LIA frequency
			whichDeviceAddress = gLIADeviceAddress
			
			if (whichDeviceAddress != 0 )	// LIA exists?
			
				if (voltage<.004) // the range of voltages for the LIA is .004 - 5 Vrms
					voltage=.004
				elseif (voltage>5)
					voltage = 5
				endif

				sprintf writtenstring1, "freq %g" frequency
				sprintf writtenstring2, "slvl %g" voltage

				WriteGPIB(whichDeviceAddress, writtenstring2)
				WriteGPIB(whichDeviceAddress,writtenstring1)

				GPIB2 interfaceclear					
			endif
			
		else // if WG is asked for OR if whichDevice string doesn't match
			whichDeviceAddress = gWGDeviceAddress
			
			if (whichDeviceAddress != 0)
			
				WriteGPIB(whichDeviceAddress,"APPL:sin")	
			
				if (voltage<.1)
					// this is in here so we can output zero voltages (generator has a 100mV output minimum)
					// so we set voltage to minimum, put the WG into square wave burst mode and set the offset so
					// the voltage will be zeroed when the square wave bursts.
					voltage=.1
					offset = .05 
					WriteGPIB(whichDeviceAddress,"BM:INT:Rate .01")
					WriteGPIB(whichDeviceAddress, "BM:NCYC 1")
					WriteGPIB(whichDeviceAddress,"BM:Stat on")
					WriteGPIB(whichDeviceAddress,"APPL:squ")			
				elseif (voltage>10)
					voltage = 10
				endif

				sprintf writtenstring1, "freq %g" frequency
				sprintf writtenstring2, "volt %g" voltage
				sprintf writtenstring3, "volt:offs %g" offset

				WriteGPIB(whichDeviceAddress, "OUTP:LOAD Max")
				WriteGPIB(whichDeviceAddress, writtenstring2)
			
				WriteGPIB(whichDeviceAddress,writtenstring1)
				WriteGPIB(whichDeviceAddress, writtenstring3)
				GPIB2 interfaceclear		
			endif
		endif
		
	endif
	
	SetDataFolder SavedDataFolder
	
end

function SetVFSqu(voltage, frequency, whichDevice, [EOM])

	variable voltage, frequency
	String whichDevice
	variable EOM
	if (ParamIsDefault(EOM))
		EOM = 0
	endif
	
	Variable whichDeviceAddress
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gBoardAddress, gLIADeviceAddress,gWGDeviceAddress, gHasGPIB

	//variable offset=0 //
	variable offset=voltage/2 //this is here because half the time we want no voltage
	if (EOM != 0)
		offset = 0
	endif
	
	string writtenstring1
	string writtenstring2
	string writtenstring3

	if (gHasGPIB==1)
		GPIBsetup()

		if (stringmatch(whichDevice,"LIA")==1) //asked for the LIA frequency
			whichDeviceAddress = gLIADeviceAddress
			
			if (whichDeviceAddress != 0 )	// LIA exists?
			
				if (voltage<.004) // the range of voltages for the LIA is .004 - 5 Vrms
					voltage=.004
				elseif (voltage>5)
					voltage = 5
				endif

				sprintf writtenstring1, "freq %g" frequency
				sprintf writtenstring2, "slvl %g" voltage

				WriteGPIB(whichDeviceAddress, writtenstring2)
				WriteGPIB(whichDeviceAddress,writtenstring1)

				GPIB2 interfaceclear					
			endif
			
		else // if WG is asked for OR if whichDevice string doesn't match
			whichDeviceAddress = gWGDeviceAddress
			

			if (whichDeviceAddress != 0)
			
				WriteGPIB(whichDeviceAddress,"APPL:squ")	
			
				if (voltage<.1)
					// this is in here so we can output zero voltages (generator has a 100mV output minimum)
					// so we set voltage to minimum, put the WG into square wave burst mode and set the offset so
					// the voltage will be zeroed when the square wave bursts.
					voltage=.1
					offset = .05 
					WriteGPIB(whichDeviceAddress,"BM:INT:Rate .01")
					WriteGPIB(whichDeviceAddress, "BM:NCYC 1")
					WriteGPIB(whichDeviceAddress,"BM:Stat on")
					WriteGPIB(whichDeviceAddress,"APPL:squ")			
				elseif (voltage>10)
					voltage = 10
				endif

				sprintf writtenstring1, "freq %g" frequency
				sprintf writtenstring2, "volt %g" voltage
				
				
				// change the value to change the offset to the wavegenerator
				
				//sprintf writtenstring3, "volt:offs %g" 2.5
				sprintf writtenstring3, "volt:offs %g" offset
				

				WriteGPIB(whichDeviceAddress, "OUTP:LOAD Max")
				WriteGPIB(whichDeviceAddress, writtenstring2)
			
				WriteGPIB(whichDeviceAddress,writtenstring1)
				WriteGPIB(whichDeviceAddress, writtenstring3)
				GPIB2 interfaceclear		
			endif
		endif
		
	endif
	
	SetDataFolder SavedDataFolder
	
end

function SetVFSquBis(voltage, frequency, whichDevice)
	// function badly hardcoded... Daviiid
	
	variable voltage, frequency
	String whichDevice
	
	variable whichDeviceAddress=str2num(whichDevice)
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	variable offset=voltage/2 //this is here because half the time we want no voltage
	string writtenstring1
	string writtenstring2
	string writtenstring3

	WriteGPIB(whichDeviceAddress,"APPL:squ")	
	
	if (voltage<.1)
		// this is in here so we can output zero voltages (generator has a 100mV output minimum)
		// so we set voltage to minimum, put the WG into square wave burst mode and set the offset so
		// the voltage will be zeroed when the square wave bursts.
		voltage=.1
		offset = .05 
		WriteGPIB(whichDeviceAddress,"BM:INT:Rate .01")
		WriteGPIB(whichDeviceAddress, "BM:NCYC 1")
		WriteGPIB(whichDeviceAddress,"BM:Stat on")
		WriteGPIB(whichDeviceAddress,"APPL:squ")			
	elseif (voltage>10)
			voltage = 10
	endif

	sprintf writtenstring1, "freq %g" frequency
	sprintf writtenstring2, "volt %g" voltage
	sprintf writtenstring3, "volt:offs %g" offset
				

	WriteGPIB(whichDeviceAddress, "OUTP:LOAD Max")
	WriteGPIB(whichDeviceAddress, writtenstring2)
			
	WriteGPIB(whichDeviceAddress,writtenstring1)
	WriteGPIB(whichDeviceAddress, writtenstring3)
	GPIB2 interfaceclear		
	
	SetDataFolder SavedDataFolder
	
end

function setVFsin(voltage, frequency)
	variable voltage, frequency
	variable offset=0 //voltage/2 //this is here because half the time we want no voltage
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gBoardUnitDescriptor,gBoardAddress, gHasGPIB
	
	if (gHasGPIB==1)	
		GPIBsetup()
		
		string writtenstring1
		string writtenstring2
		string writtenstring3
		string writtenstring4
		
		if (voltage<.1)
			voltage=.1
			offset = .05 	// this is in here so we can output zero voltages (generator is stupi
						// and has a 100mV output minimum)
						//	frequency= 10000
			sprintf writtenstring1, "freq %g" frequency
			sprintf writtenstring2, "volt %g" voltage
			sprintf writtenstring3, "volt:offs %g" offset
			
			
			Ni4882 ibcmd={gBoardAddress,"@", 1}
			Ni4882 ibcmd={gBoardAddress,"*",1}
			GPIBwrite2 "APPL:Squ"
			GPIBwrite2 "OUTP:LOAD MAX"
			GPIBwrite2 writtenstring2
			GPIBwrite2 writtenstring1
			GPIBwrite2 writtenstring3
			GPIBwrite2 "BM:INT:Rate .01"
			GPIBwrite2 "BM:NCYC 1"
			GPIBwrite2 "BM:Stat on"
			GPIB2 interfaceclear	
			//sleep/s .4 // it takes about .4 seconds for the function generator to process this
		else
	
			if (voltage>10)
				voltage = 10
			endif 
		
			sprintf writtenstring1, "freq %g" frequency
			sprintf writtenstring2, "volt %g" voltage
			sprintf writtenstring3, "volt:offs %g" offset
			Ni4882 ibcmd={gBoardAddress,"@", 1}
			Ni4882 ibcmd={gBoardAddress,"*",1}
			GPIBwrite2 "APPL:sin"
			GPIBwrite2 "OUTP:LOAD MAX"
			GPIBwrite2 writtenstring2
			GPIBwrite2 writtenstring1
			GPIBwrite2 writtenstring3
			GPIB2 interfaceclear	
		endif
	
	endif
	
	SetDataFolder SavedDataFolder
end


function GetLockInXYRO_1to4(i)
	// This function retrives the X, Y, R or Theta value from the lockin depending on i respectively (1-4)
	//////////////****************************************
	variable i	
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gHasGPIB

	if (gHasGPIB==1)
	
		variable board=0
	
		variable value
	
		string writtenstring
		sprintf writtenstring, "outp? %g" i
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 writtenstring
		Ni4882 ibcmd={board,"H",1}
		Ni4882 ibcmd={board," ",1}
		GPIBread2 value
	
		return value
	endif
	
	SetDataFolder SavedDataFolder
	
end


function EmptyReads()
	// This function retrives the X, Y, R or Theta value from the lockin depending on i respectively (1-4)
	//////////////****************************************
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
		
	NVAR gHasGPIB
	
	if (gHasGPIB==1)
		variable board=0
	
		variable value
		Ni4882 ibcmd={board,"H",1}
		Ni4882 ibcmd={board," ",1}
		GPIBread2 value
		
		return value
	endif
		
	SetDataFolder SavedDataFolder
		
end


function setChanneliOutputtoj(i,j)
	// This function makes sure the channel one output is outputting the X value (not the display)
	//////////////****************************************
	variable i,j  // i=1(channel1), i=2 (channel2

	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gHasGPIB
		
	if (gHasGPIB==1)		
		
		//j=0,1 = display, xory 
		variable board=0
		
		string writtenstring
		sprintf writtenstring, "fpop %g , %g" i, j
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 writtenstring
	endif
	
	SetDataFolder SavedDataFolder
	
end


function setChanneliDisplayj(i,j)
	// This function tells the channel what to output to the LED display
	//////////////****************************************
	variable i,j  // i=1(channel1), i=2 (channel2	
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
		
	NVAR gHasGPIB
		
	if (gHasGPIB==1)		
		variable board=0
		
		//j=0,1,2 = x, r, xnoise or (y , theta, ynoise)
		string writtenstring
		sprintf writtenstring, "ddef %g , %g, 0" i, j
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 writtenstring
	endif
	
	SetDataFolder SavedDataFolder
	
end



function setAutoPhase()
	// This function tells the lock-in to autophase
	//////////////****************************************
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gHasGPIB

	if (gHasGPIB==1)	
		variable board=0
		
		string writtenstring
		sprintf writtenstring, "aphs" 
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 writtenstring
	endif
	
	SetDataFolder SavedDataFolder
		
end


function setReserve(number)
	// This function sets the lockin reserve
	// 0 is  high, 1 is normal, 2 is low
	//////////////****************************************
	variable number
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gHasGPIB	
	
	if (gHasGPIB==1)	
		variable board=0
		
		if (number != 0 && number != 1 && number != 2)
		number = 1
		endif
		string writtenstring
		sprintf writtenstring, "rmod %g" number
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 writtenstring
	endif	

	SetDataFolder SavedDataFolder
	
end


function setLPslope(number)
	// This function sets the lockin low pass filter slope
	// 0 is 6db , 1 is 12db, 2 is 18 db, 3 is 24 db
	//////////////****************************************
	variable number
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gHasGPIB	
	
	if (gHasGPIB==1)	
		
		variable board=0
		
		if (number != 0 && number != 1 && number != 2 && number != 3)
		number = 3
		endif
		string writtenstring
		sprintf writtenstring, "ofsl %g" number
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 writtenstring
	endif

	SetDataFolder SavedDataFolder
	
end


function setSync(number)
	// This function sets the lockin to have either the sync state or not
	// 0 is off, 1 is on
	//////////////****************************************
	variable number
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM

	NVAR gHasGPIB	
	
	if (gHasGPIB==1)	
		variable board=0
		
		if (number != 0 && number != 1)
		number = 1
		endif
		string writtenstring
		sprintf writtenstring, "sync %g" number
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 writtenstring
	endif	
		
	SetDataFolder SavedDataFolder
		
end



function setFloat0orGround1(number)
	// This function tells whether the input on the Lockin should be either floating or set to ground
	//////////////****************************************
	variable number
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
			
	NVAR gHasGPIB	
	
	if (gHasGPIB==1)	
		variable board=0
		
		if (number != 1 && number != 0)
		number = 0
		endif
		string writtenstring
		sprintf writtenstring, "IGND %g" number 
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 writtenstring
	endif	

	SetDataFolder SavedDataFolder
	
end



function setNotch(number)
	// This function set the Lockin notch filters.
	// 0 sets no filter, 1 sets it at 60hz, 2 sets the 120hz, and 3 sets both
	//////////////****************************************
	variable number
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
		
	NVAR gHasGPIB	
	
	if (gHasGPIB==1)	
		variable board=0
		
		if (number != 0 && number != 1 && number != 2 && number != 3)
		number = 0
		endif
		string writtenstring
		sprintf writtenstring, "ILIN %g" number 
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 writtenstring
	endif
		
	SetDataFolder SavedDataFolder
		
end
	
	

function sendLockinString(writtenstring)
	// Sends the Lock in a command
	//////////////****************************************
	string writtenstring
		
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
		
	NVAR gHasGPIB	
	
	if (gHasGPIB==1)
		variable board=0
		
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 writtenstring
	endif
	
	SetDataFolder SavedDataFolder
	
end



function sendlockinQuery(writtenstring)
	//sends the lockin a command and returns a variable reponse
	//////////////****************************************
	string writtenstring
		
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
		
	NVAR gHasGPIB	
	
	if (gHasGPIB==1)	
		variable board=0
		
		variable response
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 writtenstring
		Ni4882 ibcmd={board,"H",1}
		Ni4882 ibcmd={board," ",1}
		GPIBread2 response
		
		return response
	endif
	
	SetDataFolder SavedDataFolder
	
end



function setLockinPhase(phase)
	// This function tells the lock-in to go to a specific phase
	//////////////****************************************
	variable phase
		
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
		
	NVAR gHasGPIB	

	if (gHasGPIB==1)	
		variable board=0
		
		string writtenstring
		sprintf writtenstring, "phas %g" phase
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 writtenstring
	endif	
	
	SetDataFolder SavedDataFolder
end



function setLockinSensitivity(sens)
	// This function sets the lock-in sensitivity
	//////////////****************************************
	variable sens // if sens = 17, then sens=1mv/nA
		
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
		
	NVAR gHasGPIB	
	
	if (gHasGPIB==1)	
		variable board=0
		
		string writtenstring
		sprintf writtenstring, "sens %g" sens
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 writtenstring
	endif
		
	SetDataFolder SavedDataFolder
		
end



function SetLockinFreq(frequency)
	////////////////// Function that sets the frequency of the Lockin
	//////////////****************************************
	variable frequency
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
		
	NVAR gHasGPIB
	
	if (gHasGPIB==1)	
		variable board=0
		
		if (frequency<.001)
		frequency = .001
		endif
		if (frequency>102000)
		frequency = 102000
		endif
		
		string writtenstring
		sprintf writtenstring, "freq %g" frequency
		
		//print writtenstring
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 writtenstring
	endif
		
	SetDataFolder SavedDataFolder	
		
end
	
	

function SetLockinAgain()
	////////////////// Function that tells the Lockin to Auto Gain itself
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gHasGPIB	
	
	if (gHasGPIB==1)	
		variable board=0
		
		//////////////****************************************
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 "Agan"
	endif
		
	SetDataFolder SavedDataFolder	
end


function GetLockinTimeC()
	/////////////////////// Function that retrieves the TimeC of the lock_in
	//////////////****************************************
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gHasGPIB	
	
	if (gHasGPIB==1)	
		variable board=0
		
		variable Tc
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 "OFLT?"
		Ni4882 ibcmd={board,"H",1}
		Ni4882 ibcmd={board," ",1}
		GPIBread2 Tc
		
		variable TimeConstant
		switch(Tc)
			case 0:
			TimeConstant=10e-6
			break
			case 1:
			TimeConstant=30e-6
			break
			case 2:
			TimeConstant=100e-6
			break
			case 3:
			TimeConstant=300e-6
			break
			case 4:
			TimeConstant=1e-3
			break	
			case 5:
			TimeConstant=3e-3
			break
			case 6:
			TimeConstant=10e-3
			break
			case 7:
			TimeConstant=30e-3
			break
			case 8:
			TimeConstant=100e-3
			break
			case 9:
			TimeConstant=300e-3
			break
			case 10:
			TimeConstant=1
			break	
			case 11:
			TimeConstant=3
			break
			case 12:
			TimeConstant=10
			break
			case 13:
			TimeConstant=30
			break
			case 14:
			TimeConstant=100
			break
			case 15:
			TimeConstant=300
			break
			case 16:
			TimeConstant=1e3
			break	
			case 17:
			TimeConstant=3e3
			break
			case 18:
			TimeConstant=10e3
			break
			case 19:
			TimeConstant=30e3
			break
		
		endswitch
		
		return TimeConstant
	endif
	
	SetDataFolder SavedDataFolder
		
end

function LockinRecall(recall_val)
	////////////////// Function that sets the TimeConstant of the lock-in
	//////////////****************************************
	variable recall_val
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
		
	NVAR gHasGPIB
	string writtenstring
	sprintf writtenstring, "RSET %g" recall_val
	
	variable board = 0
	
	//print writtenstring
	Ni4882 ibcmd={board,"@", 1}
	Ni4882 ibcmd={board,"(",1}
	GPIBwrite2 writtenstring
	
end

function SetLockinTimeC(timeC)
	////////////////// Function that sets the TimeConstant of the lock-in
	//////////////****************************************
	variable timeC
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
		
	NVAR gHasGPIB
	
	if (gHasGPIB==1)	
		variable board=0
		
		variable timeC2
		//if (frequency<.001)
		//frequency = .001
		//endif
		//if (frequency>102000)
		//frequency = 102000
		//endif
		
		if (timeC<=10e-6)
			timeC2=0

		elseif (timeC> 10e-6 && timeC<=30e-6)
			timeC2=1
		
		elseif (timeC> 30e-6 && timeC<=100e-6)
			timeC2=2

		elseif (timeC> 100e-6 && timeC<=300e-6)
			timeC2=3
		
		elseif (timeC> 300e-6 && timeC<=1e-3)
			timeC2=4

		elseif (timeC> 1e-3 && timeC<=3e-3)
			timeC2=5

		elseif (timeC> 3e-3 && timeC<=10e-3)
			timeC2=6

		elseif (timeC> 10e-3 && timeC<=30e-3)
			timeC2=7

		elseif (timeC> 30e-3 && timeC<=100e-3)
			timeC2=8

		elseif (timeC> 100e-3 && timeC<=300e-3)
			timeC2=9

		elseif (timeC> 300e-3 && timeC<=1e0)
			timeC2=10

		elseif (timeC> 1e0 && timeC<=3e0)
			timeC2=11

		elseif (timeC> 3e0 && timeC<=10e0)
			timeC2=12

		elseif (timeC> 10e0 && timeC<=30e0)
			timeC2=13

		elseif (timeC> 30e0 && timeC<=100e0)
			timeC2=14

		elseif (timeC> 100e0 && timeC<=300e0)
			timeC2=15
		
		elseif (timeC> 300e0 && timeC<=1e3)
			timeC2=16

		elseif (timeC> 1e3 && timeC<=3e3)
			timeC2=17

		elseif (timeC> 3e3 && timeC<=10e3)
			timeC2=18

		elseif (timeC> 30e3)
			timeC2=19
		endif
		
		string writtenstring
		sprintf writtenstring, "OFLT %g" TimeC2
		
		//print writtenstring
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
		GPIBwrite2 writtenstring
	endif
		
	SetDataFolder SavedDataFolder	
end



function GetLockinSens()
	/////////////////////// Function that retrieves the sens of the lock_in
	//////////////****************************************
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gBoardAddress, gLIADeviceAddress,gWGDeviceAddress, gHasGPIB
	
	if (gHasGPIB==1)	
		variable Tc, Sensitivity
		
		WriteGPIB(gLIADeviceAddress,"SENS?")
		Tc = str2num(ReadGPIB(gLIADeviceAddress,1,1))

		//print Tc

		switch(Tc)
			case 0:
			Sensitivity=2e-9
			break
			case 1:
			Sensitivity=5e-9
			break
			case 2:
			Sensitivity=10e-9
			break
			case 3:
			Sensitivity=20e-9
			break
			case 4:
			Sensitivity=50e-9
			break	
			case 5:
			Sensitivity=100e-9
			break
			case 6:
			Sensitivity=200e-9
			break
			case 7:
			Sensitivity=500e-9
			break
			case 8:
			Sensitivity=1e-6
			break
			case 9:
			Sensitivity=2e-6
			break
			case 10:
			Sensitivity=5e-6
			break	
			case 11:
			Sensitivity=10e-6
			break
			case 12:
			Sensitivity=20e-6
			break
			case 13:
			Sensitivity=50e-6
			break
			case 14:
			Sensitivity=100e-6
			break
			case 15:
			Sensitivity=200e-6
			break
			case 16:
			Sensitivity=500e-6
			break	
			case 17:
			Sensitivity=1e-3
			break
			case 18:
			Sensitivity=2e-3
			break
			case 19:
			Sensitivity=5e-3
			break
			case 20:
			Sensitivity=10e-3
			break
			case 21:
			Sensitivity=20e-3
			break
			case 22:
			Sensitivity=50e-3
			break
			case 23:
			Sensitivity=100e-3
			break
			case 24:
			Sensitivity=200e-3
			break
			case 25:
			Sensitivity=500e-3
			break
			case 26:
			Sensitivity=1
			break
		
		endswitch
		
		SetDataFolder SavedDataFolder
		return Sensitivity
	endif
	
	SetDataFolder SavedDataFolder 

end	



function setupWFarbitrary(Voltage,Fdifference,Fsum)

	variable Voltage, Fsum,Fdifference
	variable board=0
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	
	NVAR gBoardUnitDescriptor, gHasGPIB
	
	if (gHasGPIB==1)	
		Fsum -= mod(Fsum,Fdifference)
		variable PointsPerPeriod=25
		variable WFlength = PointsPerPeriod*Fsum/Fdifference
	
		make/o/n=(WFlength) WFarbwave
	
		WFarbwave= Sin(2*pi*p/WFlength/2)*Sin(2*pi*p/PointsPerPeriod) //The wavefunction generator looks
		// for values from -1 to 1. The voltage scale is only applied later.
	
		string writtenstring0
		string writtenstring1,writtenstring1temp
		string writtenstring2
		string writtenstring3
		string writtenstring4
		string writtenstring5
		string writtenstring6
		string writtenstring7
		
		writtenstring0= "*RST"
		variable i=0
		writtenstring1temp= ""
		writtenstring1= "DATA VOLATILE "
		do
			sprintf writtenstring1temp, ",%g", WFarbwave[i]
			writtenstring1= writtenstring1 + writtenstring1temp
			i+=1
		while (i<WFlength)
		
		writtenstring2= "DATA:COPY PULSE, VOLATILE"
		writtenstring3= "FUNC:USER PULSE"
		writtenstring4= "FUNC:SHAP USER"
		sprintf writtenstring5, "freq %g" Fdifference
		sprintf writtenstring6, "volt %g" Voltage
		sprintf writtenstring7, "volt:offs %g" 0
		
		GPIBsetup()
			
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"*",1}
			
		GPIBwrite2 writtenstring0
		GPIBwrite2 "OUTP:LOAD MAX"
		GPIBwrite2 writtenstring1
		GPIBwrite2 writtenstring2
		GPIBwrite2 writtenstring3
		GPIBwrite2 writtenstring4
		GPIBwrite2 writtenstring5
		GPIBwrite2 writtenstring6
		GPIBwrite2 writtenstring7
		GPIB2 interfaceclear	
		sleep/s 2  //it takes awhile for the function generator to process this
	endif
	
	SetDataFolder SavedDataFolder
end

function WFarbitrary(Voltage,Fdifference,Fsum)
	
	variable Voltage, Fsum,Fdifference
		
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM	

	NVAR gHasGPIB
	
	if (gHasGPIB==1)	
		variable board=0
	
		string writtenstring0
		string writtenstring3
		string writtenstring4
		string writtenstring5
		string writtenstring6
		string writtenstring7
		
		writtenstring0= "*RST"
		writtenstring3= "FUNC:USER PULSE"
		writtenstring4= "FUNC:SHAP USER"
		sprintf writtenstring5, "freq %g" Fdifference
		sprintf writtenstring6, "volt %g" Voltage
		sprintf writtenstring7, "volt:offs %g" 0
		
		Ni4882 ibcmd={board,"@", 1}
		Ni4882 ibcmd={board,"(",1}
			
		//GPIBwrite2 writtenstring0
		GPIBwrite2 "OUTP:LOAD MAX"
		GPIBwrite2 writtenstring3
		GPIBwrite2 writtenstring4
		GPIBwrite2 writtenstring5
		GPIBwrite2 writtenstring6
		GPIBwrite2 writtenstring7
		GPIB2 interfaceclear	
		sleep/s .5  //it takes awhile for the function generator to process this
	endif

	SetDataFolder SavedDataFolder
end

//arbitrary waveform loader edited by Raj 6/29/20100
function LoadWF(whichWave)
	
	WAVE whichWave	
	NVAR gl_setAWGFreq = root:packages:trEFM:sloth:gl_setAWGFreq
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM	

duplicate/o whichwave, whatwave
	NVAR gBoardAddress, gLIADeviceAddress,gWGDeviceAddress, gHasGPIB,gBoardUnitDescriptor
	
	if (gHasGPIB==1)	
	
		variable i
		string writtenstring0,writtenstring1,writtenstring2,writtenstring3,writtenstring4,writtenstring5,writtenstring6,writtenstring7,writtenstring8,writtenstring9


		wavestats/Q whichWave
// Raj	-- this scales to 10 V even if that isn't desired, if you need to change it go ahead?
		variable maxVoltage = V_max 
		variable denom=max(abs(V_max),abs(V_min))
// Raj 4-28-2011 : this is corrected in the calcslothwaves tab now, no worries.
		whichWave[]=whichWave[p]/(denom) //* maxvoltage/10	// should be -1 to +1 for -10 to +10

		writtenstring8 = "DATA VOLATILE "
		for (i=0;i<numpnts(whichWave);i+=1)
			writtenstring8 += ", " + num2str(whichWave[i])
		endfor 

		NI4882 ibtmo={gBoardUnitDescriptor,14}

//temp to clear error messages
		writtenstring0= "*CLS"
		WriteGPIB(gWGDeviceAddress,writtenstring0)

		writtenstring0= "*RST"
		writtenstring1="OUTP:LOAD MAX"
		writtenstring2="FREQ " + num2str(gl_setAWGFreq)
//		writtenstring3= "VOLT " + num2str(maxVoltage)
//		string writtenstring10 = "VOLT:OFFS " + num2str(0.5 * maxVoltage)
		writtenstring3= "VOLT " + num2str(maxVoltage)
		string writtenstring10 = "VOLT:OFFS " + num2str(0.5 * maxVoltage)
		writtenstring4= "FUNC:USER VOLATILE"
		writtenstring5= "FUNC:SHAP USER"
	writtenstring6= "BM:NCYC 1"
		sprintf writtenstring7, "TRIG:SOUR EXT"
	writtenstring9= "BM:STAT ON"
	
	
//	The following test string works with no problem
//	writtenstring8 = "DATA VOLATILE, .35, .7, .95, .35, .7, .9, .35, .7, .9"

		WriteGPIB(gWGDeviceAddress,writtenstring0)
		WriteGPIB(gWGDeviceAddress,writtenstring1)
		WriteGPIB(gWGDeviceAddress,writtenstring2)
		WriteGPIB(gWGDeviceAddress,writtenstring3)
WriteGPIB(gWGDeviceAddress,writtenstring10)
		WriteGPIB(gWGDeviceAddress,writtenstring8)
		beep
		// something with the data output is causing some random suffix errors
//		print writtenstring8
		WriteGPIB(gWGDeviceAddress,writtenstring6)	// throwing errors -138: SUffix not allowed?
		WriteGPIB(gWGDeviceAddress,writtenstring9)
		WriteGPIB(gWGDeviceAddress,writtenstring7)
		WriteGPIB(gWGDeviceAddress,writtenstring4)
		WriteGPIB(gWGDeviceAddress,writtenstring5)
		
		GPIB2 interfaceclear	
		sleep/s .5  //it takes awhile for the function generator to process this
	endif

	SetDataFolder SavedDataFolder
end

Function findVISAAddress([source])
// simple function to find all relevant VISA addresses for a given instrument
	string source
	if (ParamIsDefault(source))
		source = "USB"
	endif
	Variable defaultRM=0, findList=0, retcnt
	String expr, instrDesc
	Variable i, status=0
	
	expr = source + "?*INSTR"
	
	status = viOpenDefaultRM(defaultRM)
	
	status = viFindRsrc(defaultRM, expr, findList, retcnt, instrDesc)
	Printf "Instrument %d: %s\r", i, instrDesc
end

// ps = Power Supply functions below
function psSetting(voltage, [current])
	variable voltage, current	// state = on or off
	
	if (ParamIsDefault(current))
		current = 0.7
		
	endif
	
	if (current > 0.7)
		print "Hard coded to limit to 700 mA"
		current = 0.7	// safety condition to keep LEDs from dying
	endif
	
	Variable num
	Variable defaultRM, instr
	String resourceName = "USB0::0x05E6::0x2200::9060216::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	string volt = "VOLT " + num2str(voltage) + " V"
	string curr = "CURR " + num2str(current) + " A"
	
	VISAwrite instr, volt
	VISAWrite instr, curr
	
	string state
	
	VISARead instr, state
	VISAWrite instr, "VOLT?"

	print state
	
	viClose(instr)
	viClose(defaultRM)
end

function psOff()

	Variable num
	Variable defaultRM, instr
	String resourceName = "USB0::0x05E6::0x2200::9060216::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "OUTP OFF"
	
	viClose(instr)
	viClose(defaultRM)
end

function psOn()

	Variable num
	Variable defaultRM, instr
	String resourceName = "USB0::0x05E6::0x2200::9060216::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "OUTP ON"
	
	viClose(instr)
	viClose(defaultRM)
end

function psRst()
	// resets it
	
	Variable num
	Variable defaultRM, instr
	String resourceName = "USB0::0x05E6::0x2200::9060216::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "*RST"
	
	viClose(instr)
	viClose(defaultRM)
	
end