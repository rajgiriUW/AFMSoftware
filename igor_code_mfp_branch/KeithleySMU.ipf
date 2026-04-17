#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function SMUCheck([gpib_Channel])
//	Note Keithley must be in SCPI Mode
// Usage: SMUCheck() uses Board 1, which is typical
// But if you move the Keithley to share the same GPIB connectors as the rest of the AFM, 
//	then it would need to be set to 0. In that case use:
// 	SMUCheck(gpib_channel=0)
    Variable gpib_channel
    
    If(ParamIsDefault(gpib_channel))
    
    	gpib_channel = 1
    endif
        
    Variable defaultRM, instr
 
    Variable status
    String variableRead
 
    status = viOpenDefaultRM(defaultRM)
    
    String resourceName = "GPIB" + num2str(gpib_Channel) + "::24::INSTR"
    
    status = viOpen(defaultRM, resourceName, 0, 0, instr)
    
    VISAWrite instr, "*IDN?"
    VISARead/T="\r\n" instr, variableRead
    Print variableRead
    
    VISAWrite instr, ":*RST" // Restore GPIB default conditions
    
    viClose(instr)
    viClose(defaultRM)
end


function SMUOpen([gpib_Channel, gpib_address])

    Variable gpib_channel, gpib_address
    If(ParamIsDefault(gpib_channel))
     	gpib_channel = 1
    endif
    if (ParamIsDefault(gpib_address))
    	gpib_address = 24
    endif
    Variable defaultRM, instr
 
    Variable status
    String variableRead 
    status = viOpenDefaultRM(defaultRM)
    
    String resourceName = "GPIB" + num2str(gpib_Channel) + "::" +num2str(gpib_address)+"::INSTR"
    
    status = viOpen(defaultRM, resourceName, 0, 0, instr)
    VISAWrite instr, ":*RST"
    viClose(instr)
    viClose(defaultRM)
end

function SMUMode([mode, gpib_Channel, gpib_address])
	string mode
	variable gpib_channel, gpib_address
	if (ParamIsDefault(mode))
		mode = "VOLT"
	endif
    if (ParamIsDefault(gpib_address))
    	gpib_address = 24
    endif
	
    	Variable defaultRM, instr
    	SMUOpen()
    	Variable status
	String variableRead 

    	status = viOpenDefaultRM(defaultRM)
	String resourceName = "GPIB" + num2str(gpib_Channel) + "::" +num2str(gpib_address)+"::INSTR"
     	status = viOpen(defaultRM, resourceName, 0, 0, instr)
    
    	string modestr =  ":SOUR:FUNC:MODE " + mode
     	VISAWrite instr, modestr// Select current source mode
      
end

function SMUOECTSetup([gpib_Channel, voltage, currentcomp, gpib_address])
	// Setups up for default OECT Settings
	// Note that readings of 9.91e37 are NaN
	variable gpib_channel, voltage, currentcomp, gpib_address

	SetDataFolder root:packages:trEFM:ImageScan
	
	if(ParamIsDefault(gpib_channel))
    		gpib_channel = 1
	endif
    if (ParamIsDefault(gpib_address))
    	gpib_address = 24
    endif
	if(ParamIsDefault(voltage))
		voltage = 0
	endif
	
	if(ParamIsDefault(currentcomp))
		currentcomp = 50e-3
	endif
	
	Make/D/O/N=(3) dataValues // data buffer
	String/G Data = "\r\n"
		
    	Variable defaultRM, instr
    	Variable status

    	status = viOpenDefaultRM(defaultRM)
	String resourceName = "GPIB" + num2str(gpib_Channel) + "::" +num2str(gpib_address)+"::INSTR"
     	status = viOpen(defaultRM, resourceName, 0, 0, instr)

	// Set up voltage source and compliance range and current measure mode
//	SMUMode() //Voltage Mode
	VISAWrite instr, ":OUTP OFF"
	
	string voltagestr = ":SOUR:VOLT:LEV " + num2str(voltage)
	string currentprot = ":SENS:CURR:PROT " + num2str(currentcomp)
	string currentrng = ":SENS:CURR:RANG " + num2str(currentcomp)
	VISAWrite instr, voltagestr
	VISAWrite instr, currentprot
	VISAWrite instr, ":SENS:FUNC 'CURR'"
	VISAWrite instr, currentrng
	VISAWrite instr, ":FORM:ELEM VOLT, CURR, TIME" // Set to remove the resistance, and status
	// Note time is in seconds since the last *RST was sent

//	VISAWrite instr, ":TRIG:COUN 1"
//	VISAWrite instr, ":TRAC:CLE"
	VISAWrite instr, ":OUTP ON"
	VISAWrite instr, ":SENS:AVER:TCON MOV"
	VISAWrite instr, ":SENS:AVER:COUN 5"
	VISAWrite instr, ":DISP:ENAB ON"
//	VISAWrite instr, ":READ?"
	VISAWrite instr, ":INIT"
	VISAWrite instr, ":FETC?"
//	VISAWrite instr, ":TRACE:DATA?"

	VISAReadWave instr, DataValues
//    	Print dataValues

	viClose(instr)
	viClose(defaultRM)
end

function SMUClear([gpib_Channel, gpib_address])
	// Setups up for default OECT Settings
	variable gpib_channel, gpib_address
	if(ParamIsDefault(gpib_channel))
    		gpib_channel = 1
	endif
    if (ParamIsDefault(gpib_address))
    	gpib_address = 24
    endif
    	Variable defaultRM, instr
    	Variable status

    	status = viOpenDefaultRM(defaultRM)
	String resourceName = "GPIB" + num2str(gpib_Channel) + "::" +num2str(gpib_address)+"::INSTR"
     	status = viOpen(defaultRM, resourceName, 0, 0, instr)
	
     	VISAWrite instr, ":*CLS"
     	
     	viClose(instr)
	viClose(defaultRM)

end

function SMURead([gpib_Channel, gpib_address])
	// Setups up for default OECT Settings
	variable gpib_channel, gpib_address
	if(ParamIsDefault(gpib_channel))
    		gpib_channel = 1
	endif
    if (ParamIsDefault(gpib_address))
    	gpib_address = 24
    endif	
    	Variable defaultRM, instr
    	Variable status
 // data buffer
	
	Wave DataValues = root:packages:trEFM:ImageScan:DataValues
	
    	status = viOpenDefaultRM(defaultRM)
	String resourceName = "GPIB" + num2str(gpib_Channel) + "::" +num2str(gpib_address)+"::INSTR"
     	status = viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, ":INIT"
	VISAWrite instr, ":FETC?"

	VISAReadWave instr, DataValues
     	
     	viClose(instr)
	viClose(defaultRM)

end

function SMUIV(voltstart, voltstop, Vds, steps, [delay, gpib_address])
	variable voltstart, voltstop, Vds, steps, delay, gpib_address
	if (ParamIsDefault(delay))
		delay = 0
	endif
	if (ParamIsDefault(gpib_address))
    		gpib_address = 24
	endif
	SMUOECTSetup(voltage=Vds, gpib_address=gpib_address)
	SetDataFOlder root:packages:trEFM:ImageScan
	Make/O/N=(steps) voltages
	Make/O/N=(steps) currents
	voltages = voltstart + p*(voltstop - voltstart)/steps
	variable i = 0
	Wave DataValues = root:packages:trEFM:ImageScan:dataValues
	Wave TipVoltage = root:packages:MFP3D:Main:Variables:MasterVariablesWave
	do
		td_wv("Output.C", voltages[i])
		DoUpdate
		Sleep/S delay
		SMURead()
		currents[i] = DataValues[1]
		i += 1
	while (i < steps)

	display currents vs voltages
	ModifyGraph mirror=1,fStyle=1,fSize=19,axThick=3,prescaleExp(left)=3;DelayUpdate
	Label left "I\\BDS\\M Current  (mA)";DelayUpdate
	Label bottom "Gate Voltage (V)"

end

function SMUJV(voltstart, voltstop, steps, [delay, currentcomp, gpib_address])
// To match typical JV Curves upstairs that are from -2 to +1.2 V in 0.1 V increments
// Use this command: 
// SMUJV(-1.2, 1.3, 33, delay=0.1)
// SMUJV(-0.2, 1.3, 15, delay=0.1)
// The 1.3 and 33 is because I'm too lazy to fix the step sizing part, but this ends at 1.2 V
	variable voltstart, voltstop, steps, delay, currentcomp, gpib_address
	if (ParamIsDefault(delay))
		delay = 0.1
	endif
	
	if (ParamIsDefault(currentcomp))
		currentcomp = 50E-3
	endif
	
	if (ParamIsDefault(gpib_address))
    		gpib_address = 24
	endif
	SMUOECTSetup(voltage=voltstart, currentcomp=currentcomp)
	SetDataFOlder root:packages:trEFM:ImageScan
	Make/O/N=(steps) voltages
	Make/O/N=(steps) currents
	voltages = voltstart + p*(voltstop - voltstart)/steps
	variable i = 0
	Wave DataValues = root:packages:trEFM:ImageScan:dataValues
	Wave TipVoltage = root:packages:MFP3D:Main:Variables:MasterVariablesWave
	do
		SMUVolt(voltages[i], currentcomp=currentcomp)
		DoUpdate
		Sleep/S delay
		SMURead()
		currents[i] = DataValues[1]
		i += 1
	while (i < steps)

	display currents vs voltages
	ModifyGraph mirror=1,fStyle=1,fSize=19,axThick=3,prescaleExp(left)=3;DelayUpdate
	Label left "Current  (mA)";DelayUpdate
	Label bottom "Voltage (V)"

	 SMUOff()

end

function SMUVolt(voltage, [currentcomp])
	// Setups up for default OECT Settings
	// Note that readings of 9.91e37 are NaN
	variable voltage, currentcomp

	if(ParamIsDefault(currentcomp))
		currentcomp = 50e-3
	endif

	SetDataFolder root:packages:trEFM:ImageScan
	
	Make/D/O/N=(3) dataValues // data buffer
	String/G Data = "\r\n"
		
    	Variable defaultRM, instr
    	Variable status

    	status = viOpenDefaultRM(defaultRM)
      	String resourceName = "GPIB1" + "::24::INSTR"
     	status = viOpen(defaultRM, resourceName, 0, 0, instr)

	// Set up voltage source and compliance range and current measure mode
//	SMUMode() //Voltage Mode
//	VISAWrite instr, ":OUTP OFF"
	
	string voltagestr = ":SOUR:VOLT:LEV " + num2str(voltage)

	string currentprot = ":SENS:CURR:PROT " + num2str(currentcomp)
	string currentrng = ":SENS:CURR:RANG " + num2str(currentcomp)
	VISAWrite instr, voltagestr
	VISAWrite instr, currentprot
	VISAWrite instr, ":SENS:FUNC 'CURR'"
	VISAWrite instr, currentrng

//	VISAWrite instr, voltagestr
//	VISAWrite instr, ":SENS:CURR:PROT 50E-3"   // change to 100E-3
	VISAWrite instr, ":SENS:FUNC 'CURR'"
//	VISAWrite instr, ":SENS:CURR:RANG 50E-3"  // change to 
	VISAWrite instr, ":FORM:ELEM VOLT, CURR, TIME" // Set to remove the resistance, and status
	// Note time is in seconds since the last *RST was sent

//	VISAWrite instr, ":TRIG:COUN 1"
//	VISAWrite instr, ":TRAC:CLE"
	VISAWrite instr, ":OUTP ON"
	VISAWrite instr, ":SENS:AVER:TCON MOV"
	VISAWrite instr, ":SENS:AVER:COUN 5"
	VISAWrite instr, ":DISP:ENAB ON"
//	VISAWrite instr, ":READ?"
	VISAWrite instr, ":INIT"
	VISAWrite instr, ":FETC?"
//	VISAWrite instr, ":TRACE:DATA?"

	VISAReadWave instr, DataValues
//    	Print dataValues

	viClose(instr)
	viClose(defaultRM)
end

function SMUOff()
	// Setups up for default OECT Settings
	// Note that readings of 9.91e37 are NaN
    	Variable defaultRM, instr
    	Variable status

    	status = viOpenDefaultRM(defaultRM)
      	String resourceName = "GPIB1" + "::24::INSTR"
     	status = viOpen(defaultRM, resourceName, 0, 0, instr)

	VISAWrite instr, ":OUTP OFF"

	viClose(instr)
	viClose(defaultRM)
end