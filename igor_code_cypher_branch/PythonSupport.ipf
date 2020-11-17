#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Can see some of the commands in TransferFuncPanel for examples

// This contains some Python support files for directly calling FFTA code rather than using
// the fixed C++ XOP

function PyPS(ibw_wave, parameters)
	Wave ibw_wave
	Wave Parameters
	
	if (strlen(PathList("PointScan", ";", "")) == 0)
		NewPath PointScan		
	endif
	string ibw_path
	string parms_path
	
	PathInfo PointScan
	ibw_path = ParseFilePath(5, S_path, "\\", 0, 0)
	print(ibw_path)
	string command

	command = "cmd.exe /K cd C:\Users\Asylum User\Desktop\GingerLab Code\Ginger-Code-Repo\igor_code_mfp_branch\misc &&"
	command += "activate fftaenv && "
	command += " python analyze_pixel.py \"" + ibw_path + "\" && Exit"
	print(command)
	ExecuteScriptText command
	
	LoadWave/G/O/D/P=PointScan/N "pointscan.txt"
	Wave Wave0
	Duplicate/O wave0, shiftwave // overwrites the existing wave in the FFtrEFM folder
end