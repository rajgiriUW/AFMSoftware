#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Can see some of the commands in TransferFuncPanel for examples

// This contains some Python support files for directly calling FFTA code rather than using
// the fixed C++ XOP

function PyPS(ibw_wave, parameters)
	Wave ibw_wave
	Wave Parameters
		
	String savDF = GetDataFolder(1)
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
	
	SetDataFolder root:packages:trEFM:PointScan:FFtrEFM:
	LoadWave/G/O/D/P=PointScan/N "pointscan.txt"
	Wave Wave0
	Duplicate/O wave0, shiftwave // overwrites the existing wave in the FFtrEFM folder

	SetDataFolder savDF
end

function PyPS_cypher(ibw_wave, parameters)
	Wave ibw_wave
	Wave Parameters
	
	String savDF = GetDataFolder(1)
	
	if (strlen(PathList("PointScan", ";", "")) == 0)
		NewPath PointScan		
	endif
	string ibw_path
	string parms_path
	
	PathInfo PointScan
	ibw_path = ParseFilePath(5, S_path, "\\", 0, 0)
	print(ibw_path)
	string command

//	Cypher computer 
//	command = "cmd.exe /K C:\Anaconda3\Scripts\activate.bat C:\Anaconda3 && cd C:\\AsylumResearch\\v16\\Ginger Code\\misc &&"

//	MFP3D computer
	command = "cmd.exe /K C:\Users\GingerLab\anaconda3\Scripts\activate.bat C:\Users\GingerLab\anaconda3 && C: && cd C:\Users\GingerLab\Documents\GingerCode_V14,V16_Cypher\misc &&"
	command += " python analyze_pixel.py \"" + ibw_path + "\" && Exit"
	print(command)
	ExecuteScriptText command
	
	SetDataFolder root:packages:trEFM:PointScan:FFtrEFM:
	LoadWave/G/O/D/P=PointScan/N "pointscan.txt"
	
	try
		LoadWave/J/O/D/P=PointScan/N=tfp "tfp.txt"
		LoadWave/J/O/D/P=PointScan/N=shift "shift.txt"
		wave tfp0, shift0
		Variable/G tfp_value, shift_value
		tfp_value = tfp0
		shift_value = shift0
		
	catch
		print("Error loading tfp")
	endtry 
	
	Wave Wave0
	Duplicate/O wave0, shiftwave // overwrites the existing wave in the FFtrEFM folder
	
	SetDataFolder savDF
end

function PyPS_cypher_image(folder, ibw_name, parameters)

	string folder
	string ibw_name
	Wave parameters
	string ibw_path
	string parms_path

	String savDF = GetDataFolder(1)

	PathInfo Path
	ibw_path = folder + ibw_name
	parms_path = folder + "parameters.cfg"
	string command
	
//	Cypher computer 
//	command = "cmd.exe /K C:\Anaconda3\Scripts\activate.bat C:\Anaconda3 && cd C:\\AsylumResearch\\v16\\Ginger Code\\misc &&"

//	MFP3D computer
	command = "cmd.exe /K C:\Users\GingerLab\anaconda3\Scripts\activate.bat C:\Users\GingerLab\anaconda3 && cd C:\Users\GingerLab\Documents\GingerCode_V14,V16_Cypher\misc &&"
	command += " python analyze_line.py \"" + ibw_path + "\" \" " + parms_path + "\" && Exit"
	ExecuteScriptText command
	
	SetDataFolder root:packages:trEFM:ImageScan:FFtrEFM:
	LoadWave/G/O/D/P=Path/N "line_tfp.txt"
	Wave Wave0
	Duplicate/O wave0, tfp_wave // overwrites the existing wave in the FFtrEFM folder
	LoadWave/G/O/D/P=Path/N "line_shift.txt"
	Wave Wave0
	Duplicate/O wave0, shift_wave // overwrites the existing wave in the FFtrEFM folder

	setdatafolder savDF	
end

function PyPS_image(folder, ibw_name, parameters)

	string folder
	string ibw_name
	Wave parameters
	string ibw_path
	string parms_path

	String savDF = GetDataFolder(1)

	PathInfo Path
	ibw_path = folder + ibw_name
	parms_path = folder + "parameters.cfg"
	string command
	
	command = "cmd.exe /K cd C:\Users\Asylum User\Desktop\GingerLab Code\Ginger-Code-Repo\igor_code_mfp_branch\misc &&"
	command += "activate fftaenv && "
	command += " python analyze_line.py \"" + ibw_path + "\" \" " + parms_path + "\" && Exit"
	ExecuteScriptText command

	SetDataFolder root:packages:trEFM:ImageScan:FFtrEFM:
	LoadWave/G/O/D/P=Path/N "line_tfp.txt"
	Wave Wave0
	Duplicate/O wave0, tfp_wave // overwrites the existing wave in the FFtrEFM folder
	LoadWave/G/O/D/P=Path/N "line_shift.txt"
	Wave Wave0
	Duplicate/O wave0, shift_wave // overwrites the existing wave in the FFtrEFM folder

	setdatafolder savDF	
end