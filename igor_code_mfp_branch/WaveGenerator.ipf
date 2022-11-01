
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// Note, look at the testawg() below for how to write directly from the computer (faster than USB, more prone to errors)

// THese are mostly interface functions for the Agilent/Keysight 3500 (the new, nice AWG)

Function LoadTauWave(num, [amp])
	Variable num
	variable amp
	
	if (ParamIsDefault(amp))
		amp = 5
	endif
	
	Variable defaultRM, instr
	String resourceName = "USB0::0x0957::0x2907::MY52500433::0::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "*RST\n"
	VISAWrite instr, "FUNC:ARB:SRATE 100E6\n"
	
	string ampstr = "FUNC:ARB:PTP " + num2str(amp) + "\n"
//	VISAWrite instr, "FUNC:ARB:PTP 5\n"
	VISAWrite instr, ampstr
	
	VISAWrite instr, "MMEM:LOAD:DATA \"USB:\\tau"+ num2str(num) +".dat\"\n"
	VISAWrite instr, "FUNC:ARB \"USB:\\tau"+ num2str(num) +".dat\"\n"
	VISAWrite instr, "FUNC ARB\n"
	
	VISAWrite instr, "BURS:MODE TRIG\n"
	VISAWrite instr, "TRIG:SOUR EXT\n"
	VISAWrite instr, "BURS:STAT ON\n"
	
	VISAWrite instr, "OUTP ON\n"

	viClose(instr)
	viClose(defaultRM)

end

Function LoadSquareWave81150(voltage, frequency, [EOM, duty, offset])
	variable voltage, frequency
	variable EOM
	variable duty
	variable offset
	if (ParamIsDefault(EOM))
		EOM = 0
	endif
	
	if (ParamIsDefault(duty))
		duty = 50
	endif
	
	if (ParamIsDefault(offset))
		offset = voltage/2
	endif
	
	variable num
	
	Variable defaultRM, instr
//	String resourceName = "USB0::0x0957::0x4108::MY47C01225::INSTR" //81150 addresss
	//String resourceName = "USB0::0x0957::0x2907::MY52500433::0::INSTR"
	String resourceName = "USB0::0xF4EC::0x1101::SDG6XEBQ5R0541::INSTR" // Siglent One
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "*RST"
	VISAWrite instr, "C1:OUTP OFF"
	VISAWRite instr, "C1:BSWV WVTP,SQUARE"
	VISAWRite instr, "C1:BSWV FRQ," + num2str(frequency) 
	VISAWrite instr, "C1:BSWV AMP," + num2str(2*voltage)
	VISAWrite instr, "	C1:OUTP LOAD,50"
	
	//VISAWrite instr, "FUNC:ARB:SRATE 100E6\n"

	if (EOM == 0) // offset to half

		VISAWrite instr, "C1:BSWV OFST," + num2str(offset)
	endif
	//funcstr = funcstr + "\n"
	//VISAWrite instr, funcstr
	string dutystr

	sprintf dutystr, "C1:BSWV DUTY,%g" duty
	VISAWrite instr, dutystr
	VISAWrite instr, "C1:OUTP ON"

	viClose(instr)
	viClose(defaultRM)

end

function TurnOff81150()

	Variable defaultRM, instr
//	String resourceName = "USB0::0x0957::0x4108::MY47C01225::INSTR" //81150 addresss
	String resourceName = "USB0::0xF4EC::0x1101::SDG6XEBQ5R0541::INSTR" // Siglent One
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "*RST\n"
	VISAWrite instr, "OUTP OFF\n"
	
	viClose(instr)
	viClose(defaultRM)
	
end

Function LoadChirpWave(filename, [offset, amplitude, sampling_rate])
	String filename // not include the .dat
	variable offset
	variable amplitude
	string sampling_rate
	
	if (paramisdefault(offset))
		offset = 0
	endif
	
	if (paramisdefault(amplitude))
		amplitude = 2
	endif
	
	if (paramisdefault(sampling_rate))
		sampling_rate = "100E6"
	endif

	Variable defaultRM, instr
	String resourceName = "USB0::0x0957::0x2907::MY52500433::0::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "*RST\n"
	VISAWrite instr, "FUNC:ARB:SRATE " + sampling_rate +"\n"

//	VISAWrite instr, "FUNC:ARB:SRATE 100E6\n"
//	VISAWrite instr, "FUNC:ARB:SRATE 10E6\n"
	VISAWrite instr, "FUNC:ARB:PTP "+num2str(amplitude)+"\n"
	
	VISAWrite instr, "MMEM:LOAD:DATA \"USB:\\"+filename +".dat\"\n"
	VISAWrite instr, "FUNC:ARB \"USB:\\"+filename +".dat\"\n"
	VISAWrite instr, "FUNC ARB\n"
	
	VISAWrite instr, "BURS:MODE TRIG\n"
	VISAWrite instr, "TRIG:SOUR EXT\n"
	VISAWrite instr, "BURS:STAT ON\n"
	VISAWrite instr, "VOLT:OFFS " + num2str(offset) + "\n"
	
	VISAWrite instr, "OUTP ON\n"

	viClose(instr)
	viClose(defaultRM)

end

Function LoadPulseWave(freq, amp, pulsewidth, offset)
// Needed if you want to do voltage pulses synced
// Keep in mind the output impedance is defaults to 50 ohm, which means the actual
// voltage will be doubled unless you put a 50 ohm load (the BNC cap) in parallel with the output.
// a reasonable default is LoadPulseWave(100, 2, 0.003, -0.5) to get a 100 Hz, 2 V with -0.5 V offset, 3 ms long
	Variable freq, amp, pulsewidth, offset
	Variable defaultRM, instr
	String resourceName = "USB0::0x0957::0x2907::MY52500433::0::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "*RST\n"
	VISAWrite instr, "FUNC PULS"
	VISAWrite instr, "FREQ "+ num2str(freq)
	VISAWrite instr, "VOLT " + num2str(amp)
	VISAWrite instr, "VOLT:OFFS  " + num2str(offset)
	VISAWrite instr, "FUNC:PULS:WIDT " + num2str(pulsewidth)
	
	VISAWrite instr, "BURS:MODE TRIG\n"
	VISAWrite instr, "TRIG:SOUR EXT\n"
	VISAWrite instr, "BURS:STAT ON\n"
	
	VISAWrite instr, "OUTP ON\n"

	viClose(instr)
	viClose(defaultRM)

end

function testawg() // scratchspace for quick testing

	Variable defaultRM, instr
	String resourceName = "USB0::0x0957::0x2907::MY52500433::0::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
//	string strdata = "0, 0.2,0.3,0.4,0.3,0.2,0.1,0, 0.2,0.3,0.4,0.3,0.2,0.1,0, 0.2,0.3,0.4,0.3,0.2,0.1,0, 0.2,0.3,0.4,0.3,0.2,0.1,0, 0.2,0.3,0.4,0.3,0.2,0.1,0, 0.2,0.3,0.4,0.3,0.2,0.1,0, 0.2,0.3,0.4,0.3,0.2,0.1,0, 0.2,0.3,0.4,0.3,0.2,0.1,0, 0.2,0.3,0.4,0.3,0.2,0.1,0, 0.2,0.3,0.4,0.3,0.2,0.1,0, 0.2,0.3,0.4,0.3,0.2,0.1,0, 0.2,0.3,0.4,0.3,0.2,0.1,0, 0.2,0.3,0.4,0.3,0.2,0.1,0, 0.2,0.3,0.4,0.3,0.2,0.1"
	svar outw
	string strdata = outw[0, 200]
	VISAWrite instr, "DATA:VOLatile:CLEar"
	VISAWrite instr, "SOURce1:DATA:ARBitrary TestArb2," + strdata
	VISAWrite instr, "SOURce1:FUNCtion ARB"
	VISAWRite instr, "SOURce1:FUNCtion:ARBitrary TestArb2"
	VISAWrite instr, "FUNC:ARB:SRATE 1E5\n"
	viClose(instr)
	viClose(defaultRM)
	
end

Function LoadArbWave(freq, amp, offset, [polarity])
	Variable freq, amp, offset
	variable polarity
	Variable num
	Variable defaultRM, instr
	if (paramisdefault(polarity))
		polarity = 0 
	endif
	String resourceName = "USB0::0x0957::0x2907::MY52500433::0::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "*RST\n"
//	VISAWrite instr, "FUNC SIN"
	VISAWrite instr, "FUNC SQU"
	VISAWrite instr, "FREQ "+ num2str(freq)
	VISAWrite instr, "VOLT " + num2str(amp)
	VISAWrite instr, "VOLT:OFFS  " + num2str(offset)
	
	if (polarity == 0)
		VISAWRITE instr, "OUTP:POL NORM"
	else
		VISAWRITE instr, "OUTP:POL INV"
	endif
	
	VISAWrite instr, "OUTP ON\n"

	viClose(instr)
	viClose(defaultRM)

end

function TurnOffAWG()

	Variable defaultRM, instr
	String resourceName = "USB0::0x0957::0x2907::MY52500433::0::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "*RST\n"
	VISAWrite instr, "OUTP OFF\n"
	
	viClose(instr)
	viClose(defaultRM)
	
end

function TurnOnAWG()

	Variable defaultRM, instr
	String resourceName = "USB0::0x0957::0x2907::MY52500433::0::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "*RST\n"
	VISAWrite instr, "OUTP ON\n"
	
	viClose(instr)
	viClose(defaultRM)
	
end

function clearAWGError()

	Variable defaultRM, instr
	String resourceName = "USB0::0x0957::0x2907::MY52500433::0::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	VISAWrite instr, "SYSTem:ERRor?"
	viClose(instr)
	viClose(defaultRM)

end

Function LoadTauBWave(num)
	Variable num
	
	Variable defaultRM, instr
	String resourceName = "USB0::0x0957::0x2907::MY52500433::0::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "*RST\n"
	VISAWrite instr, "FUNC:ARB:SRATE 100E6\n"
	VISAWrite instr, "FUNC:ARB:PTP 5\n"
	
	VISAWrite instr, "MMEM:LOAD:DATA \"USB:\\taub"+ num2str(num) +".dat\"\n"
	VISAWrite instr, "FUNC:ARB \"USB:\\taub"+ num2str(num) +".dat\"\n"
	VISAWrite instr, "FUNC ARB\n"
	
	VISAWrite instr, "BURS:MODE TRIG\n"
	VISAWrite instr, "TRIG:SOUR EXT\n"
	VISAWrite instr, "BURS:STAT ON\n"
	
	VISAWrite instr, "OUTP ON\n"

	viClose(instr)
	viClose(defaultRM)

end

Function LoadDCWave81150(offset)
	variable offset
	
	Variable defaultRM, instr
//	String resourceName = "USB0::0x0957::0x4108::MY47C01225::INSTR" //81150 addresss
	//String resourceName = "USB0::0x0957::0x2907::MY52500433::0::INSTR"
	String resourceName = "USB0::0xF4EC::0x1101::SDG6XEBQ5R0541::INSTR" // Siglent One
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "*RST"
	VISAWrite instr, "C1:OUTP OFF"
	VISAWRite instr, "C1:BSWV WVTP,DC"
//	VISAWRite instr, "C1:BSWV FRQ," + num2str(frequency) 
//	VISAWrite instr, "C1:BSWV AMP," + num2str(2*voltage)
	VISAWrite instr, "	C1:OUTP LOAD,50"
	
	//VISAWrite instr, "FUNC:ARB:SRATE 100E6\n"

	VISAWrite instr, "C1:BSWV OFST," + num2str(offset)

	//funcstr = funcstr + "\n"
	//VISAWrite instr, funcstr

	VISAWrite instr, "C1:OUTP ON"

	viClose(instr)
	viClose(defaultRM)

end