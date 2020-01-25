
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function LoadTauWave(num)
	Variable num
	Variable defaultRM, instr
	String resourceName = "USB0::0x0957::0x2907::MY52500433::0::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "*RST\n"
	VISAWrite instr, "FUNC:ARB:SRATE 100E6\n"
	VISAWrite instr, "FUNC:ARB:PTP 5\n"
	
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

Function LoadArbWave(freq, amp)
	Variable freq, amp
	Variable num
	Variable defaultRM, instr
	String resourceName = "USB0::0x0957::0x2907::MY52500433::0::INSTR"
	
	viOpenDefaultRM(defaultRM)
	viOpen(defaultRM, resourceName, 0, 0, instr)
	
	VISAWrite instr, "*RST\n"
	VISAWrite instr, "FUNC SIN"
	VISAWrite instr, "FREQ "+ num2str(freq)
	VISAWrite instr, "VOLT " + num2str(amp)
	
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