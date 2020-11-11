
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
//e.g. loadpulsewave(100, 2, 0.001, -2) is square from -6 V to 2V
// Amplitude = +/- voltage listed. Offset is 1/2 the offset value
// For -4 to 0 that is (..,2, -1) because 4 V total swing, centered at 2 * -1 V
// Essentially, just double the values that you might expect to make them actually correct
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

Function LoadArbWave(freq, amp, offset)
	Variable freq, amp, offset
	Variable num
	Variable defaultRM, instr
	String resourceName = "USB0::0x0957::0x2907::MY52500433::0::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "*RST\n"
//	VISAWrite instr, "FUNC SIN"
	VISAWrite instr, "FUNC SQU"
	VISAWrite instr, "FREQ "+ num2str(freq)
	VISAWrite instr, "VOLT " + num2str(amp)
	VISAWrite instr, "VOLT:OFFS  " + num2str(offset)
	
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