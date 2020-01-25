#pragma rtGlobals=3		// Use modern global access method and strict wave access.
function drivetipRecord(Vmin, Vmax, DriveAmp)
	variable vmin, vmax, driveamp
	
	SetCrosspoint ("Ground","Ground","ACDefl","Ground","Ground","Ground","Off","Off","Off","Ground","OutC","OutA","OutB","Ground","DDS","Ground")
	
	make/O/N=800 ElecAmpIn, ElecBiasOut
	
	SetScale/I x, Vmin, Vmax, ElecBiasOut
	ElecBiasOut[] = x
	ElecAmpIn = NaN
	
	svar LockinString
	td_Wv(LockInString + "Amp", driveAmp)
	
	td_xsetoutWave(0, "Event.2", "Output.B", ElecBiasOut, 1)
	td_xsetinWave(1, "Event.2", "Amplitude", ElecAmpIn, "", 1)
	
	td_writestring("Event.2", "Once")
	
	CheckInWaveTiming(ElecAmpIn)

end

