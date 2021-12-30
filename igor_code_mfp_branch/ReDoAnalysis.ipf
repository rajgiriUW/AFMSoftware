#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function ReDoAnalysis()
	string savDF = GetDataFolder(1)
	
	SetDataFolder root:packages:trEFM:ImageScan
	NewPath FolderPath
	
	if(V_flag == 1)
		Abort
	endif
	Nvar scanpoints, scanlines
	make/o gagewave

	make/o/n=(scanpoints) tfpline,shiftline
	make/o/n=(scanpoints,scanlines) tfp_array_redo,shift_array_redo,rate_array_redo
	tfp_array_redo = 0
	rate_array_redo = 0
	shift_array_redo = 0
	
	variable i
	for(i = 0; i < scanlines; i += 1)
	
		if (i < 10)
			LoadWave/O/H/P=FolderPath "FFtrEFM_000" + num2str(i) + ".ibw" 
		elseif (i < 100)
			LoadWave/O/H/P=FolderPath "FFtrEFM_00" + num2str(i) + ".ibw"
		else
			LoadWave/O/H/P=FolderPath "FFtrEFM_0" + num2str(i) + ".ibw"
		endif

		//AnalyzeLineOffline(root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG,scanpoints,shiftline,tfpline,gagewave)
		
		rate_array_redo[][i] = 1/tfpline[p]
		tfp_array_redo[][i] =  tfpline[p]
		shift_array_redo[][i] = shiftline[p]
		
		DoUpdate
	endfor
End