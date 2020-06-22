#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Window TransferFuncPanel() : Panel
	
	NewDataFolder/O/S root:Packages:trEFM:TF
	Variable/G TFDigitizerAverages = 50
	Variable/G TFDigitizerSamples 
	Variable/G TFDigitizerPretrigger
	Variable/G TFDigitizerTime = 1.6
	Variable/G TFDigitizerSampleRate = 10e6
	Variable/G TFDigitzerPercentPreTrig = 60
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1388,438,1731,669)
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fsize= 14,fstyle= 5
	DrawText 43,21,"Transfer Function"
	Button transferfuncparams,pos={14,163},size={136,34},proc=GModeTransferFUncButton,title="Transfer Func with AWG"
	SetVariable digipre,pos={26,81},size={90,16},title="Pre-Trigger %"
	SetVariable digipre,limits={-inf,inf,0},value= root:packages:trEFM:TF:DigitzerPercentPreTrig
	SetVariable digisamples,pos={20,59},size={97,16},title="Time (ms)"
	SetVariable digisamples,limits={-inf,inf,0},value= root:packages:trEFM:TF:TFDigitizerTime
	SetVariable digiaverages,pos={36,37},size={80,16},title="Averages"
	SetVariable digiaverages,limits={-inf,inf,0},value= root:packages:trEFM:TF:TFDigitizerAverages
	PopupMenu popup1,pos={31,108},size={86,22},bodyWidth=60,proc=PopMenuProcTF,title="Rate"
	PopupMenu popup1,mode=1,popvalue="10 MS",value= #"\"10 MS;50 MS;100MS;5MS;1MS;0.5MS\""
	Button PixelParams,pos={156,38},size={96,24},proc=PixelParams,title="Pixel-wise Settings"
	Button LineParams,pos={157,70},size={96,24},title="Line-Wise Settings"
EndMacro

Function PopMenuProcTF(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string savDF = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM:TF
	Nvar TFDigitizerSampleRate
	
	switch(popNum)
		Case 1:
			TFDigitizerSampleRate = 10e6
			break
		Case 2:
			TFDigitizerSampleRate = 50e6
			break
		Case 3:
			TFDigitizerSampleRate = 100e6
			break
		Case 4:
			TFDigitizerSampleRate = 5e6
			break
		Case 5:
			TFDigitizerSampleRate = 1e6
			break
		Case 6:
			TFDigitizerSampleRate = 0.5e6
			break
	endswitch
	
	SetDataFolder savDF
End


Function PixelParams(ctrlname) : ButtonControl

	string ctrlname
	string savDF = getDataFolder(1)
	
	setDataFolder root:packages:trEFM:TF

	NVAR TFDigitizerAverages, TFDigitizerTime, TFDigitizerSampleRate, TFDigitizerPercentPreTrig
	
	setDataFolder root:packages:trEFM:ImageScan
	NVAR DigitizerAverages, DigitizerTime, DigitizerSampleRate, DigitizerPercentPreTrig
	TFDigitizerAverages =DigitizerAverages
	TFDigitizerTime = DigitizerTime
	TFDigitizerPercentPreTrig = DigitizerPercentPreTrig
	
	switch(DigitizerSampleRate)
	
		case 0.5e6:
			PopMenuProcTF("", 6, "0.5MS")
			break
		case 1e6:
			PopMenuProcTF("", 5, "1MS")
			break
		case 5e6:
			PopMenuProcTF("", 4, "5MS")
			break
		case 10e6:
			PopMenuProcTF("", 1, "10 MS")
			break
		case 50e6:
			PopMenuProcTF("", 2, "50 MS")
			break
		case 100e6:
			PopMenuProcTF("", 3, "100MS")
			break
	endswitch
	
	TFDigitizerSampleRate = DigitizerSampleRate
	
	SetDataFolder savDF

end

Function GModeTransferFuncButton(ctrlname) : ButtonControl

	String ctrlname
	String savDF = GetDataFolder(1)
	CommitDriveWaves()
	
	SetDataFolder root:packages:trEFM:ImageScan
//	Nvar DigitizerAverages, DigitizerSamples,DigitizerPretrigger
//	Nvar DigitizerTime, DigitizerSampleRate, DigitizerPercentPreTrig

	SetDataFolder root:packages:trEFM:TF
	Nvar TFDigitizerAverages, TFDigitizerSamples, TFDigitizerPretrigger
	Nvar TFDigitizerTime, TFDigitizerSampleRate, TFDigitizerPercentPreTrig

	
	// For this, we will hard-code certain values
	// Runs for 10 ms per signal, with 300 us pre-trigger and 9700 us post-trigger
//	DigitizerAverages = 5
//	DigitizerTime = 10
//	DigitizerPercentPreTrig = 97
	
	TFDigitizerSamples = ceil(TFDigitizerSampleRate * TFDigitizerTime * 1e-3)
	TFDigitizerPretrigger = ceil(TFDigitizerSamples * TFDigitizerPercentPreTrig / 100)

	SetDataFolder root:Packages:trEFM
	
	Nvar liftheight
	Nvar gxpos, gypos
	Nvar WavesCommitted
	
	if(WavesCommitted == 0)
		Abort "Drive waves have not been committed."
	endif
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	
	SetDataFolder root:Packages:trEFM:PointScan:FFtrEFM
	
	Wave PIXELCONFIG = root:packages:trEFM:FFtrEFMConfig:PIXELCONFIG
	Make/O/N=(TFDigitizerSamples) timekeeper
	Linspace2(0, TFDigitizerTime * 1e-3, TFDigitizerSamples, timekeeper)
	SetScale d, 0, (TFDigitizerSamples), "s", timekeeper
	
	// Check is settings exceed 75 MB. Needed to avoid saturating the Gage Card
	if (TFDigitizerSampleRate * TFDigitizerTime * 1e-3 * TFDigitizerAverages  > 70e6)
		variable fileSpaceOption = 0 
		Prompt fileSpaceOption, "These settings near/over 75 MB limit! Continue?"
			DoPrompt ">>>",fileSpaceOption
				If(V_flag==1)
					abort			//Aborts if you cancel the save option
				endif
	endif
	
	PixelConfig[%Trigger] = (1 - TFDigitizerPercentPreTrig/100) * TFDigitizerTime * 1e-3
	PixelConfig[%Total_Time] = TFDigitizerTime * 1e-3
	
	NVAR calengagefreq = root:packages:trEFM:VoltageScan:calengagefreq
//	print "Generating Chirp with frequency", calengagefreq, " Hz and width", 


	PointScanTF(gxpos, gypos, liftheight, TFDigitizerAverages, TFDigitizerSamples, TFDigitizerPretrigger)
	GetCurrentPosition()	
	
	Wave gagewave = root:packages:trEFM:PointScan:FFtrEFM:gagewave
	Wave ch2_wave = root:packages:trEFM:PointScan:FFtrEFM:ch2_wave
	
	string gagename = "gagewave_chirp" 
	Duplicate/O gagewave, $gagename
	wave gagewave_chirp
	Duplicate/O gagewave_chirp, root:packages:trEFM:TF:gagewave_chirp
	
	string tf_name = "tip_chirp"
	Duplicate/O ch2_wave, $tf_name	
	wave tip_chirp
	Duplicate/O tip_chirp, root:packages:trEFM:TF:tip_chirp
	
	// Display the results
	MatrixOp/O transfer_func = sumrows(gagewave_chirp)/numcols(gagewave_chirp)
	SetScale/I x, 0, PixelConfig[%Total_Time], "s", transfer_func
		
	MatrixOp/O excitation = sumrows(tip_chirp)/numcols(tip_chirp)
	SetScale/I x, 0, PixelConfig[%Total_Time], "s", excitation

	FFT/OUT=3/DEST=transfer_func_FFT transfer_func
	FFT/OUT=3/DEST=excitation_FFT excitation
	
	display transfer_func_FFT
	appendtograph/R excitation_FFT
	
	SetDataFolder savDF
	
	Beep
end

Function LoadChirp()
	variable f_center = 500e3
	variable f_width = 400e3
	Wave TFDigitizerTime = root:packages:trEFM:TF:TFDigitizerTime
	variable length = TFDigitizerTime * 1e-3

	string cmd = "cmd.exe /K cd C:\\Data\\Raj && python generate_chirp.py " + num2str(f_center) + " " + num2str(f_width) + " " + num2str(length) + " && Exit"
	ExecuteScriptText cmd

	print "Generated chirp with frequency", num2str(f_center), " Hz and width", num2str(f_width), "Hz, ", num2str(length), " seconds long." 
	
	string copychirp
	Prompt copychirp, "Insert a Flash Drive and press Continue"
	DoPrompt ">>>",copychirp
	if(V_flag==1)
		Abort			//Aborts if you cancel the save option
	endif
	
	ExecuteScriptText "cmd.exe /K cd C:\\Data\\Raj && copy chirp.dat E: && Exit"

	Prompt copychirp, "Insert Flash Drive in Wave Generator"
	DoPrompt ">>>",copychirp
	if(V_flag==1)
		Abort			//Aborts if you cancel the save option
	endif
	
	KillWaves/Z root:packages:trEFM:PointScan:FFtrEFM:gagewave
	KillWaves/Z root:packages:trEFM:PointScan:FFtrEFM:ch2_wave
	
	// Run experiment	
	loadchirpwave("chirp", offset=0.0) // verified on oscilloscope should be offset=0 on 6/19/2020
	sleep/S 20

end