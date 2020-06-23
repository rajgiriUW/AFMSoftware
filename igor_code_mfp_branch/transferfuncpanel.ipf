#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Window TransferFuncPanel() : Panel
	TFPanelInit()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1952,496,2247,752)
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fsize= 14,fstyle= 5
	DrawText 43,21,"Transfer Function"
	SetDrawEnv fsize= 10,fstyle= 2
	DrawText 17,246,"Chirp Script in \"C:Data:Raj:generate_chirp.py\""
	Button transferfuncparams,pos={20,187},size={131,34},proc=GModeTransferFUncButton,title="Transfer Func with AWG"
	SetVariable digipre,pos={42,67},size={90,16},title="Pre-Trigger %"
	SetVariable digipre,limits={1,98,0},value= root:packages:trEFM:TF:TFDigitizerPercentPreTrig
	SetVariable digisamples,pos={35,47},size={97,16},title="Time (ms)"
	SetVariable digisamples,limits={-inf,inf,0},value= root:packages:trEFM:TF:TFDigitizerTime
	SetVariable digiaverages,pos={52,27},size={80,16},title="Averages"
	SetVariable digiaverages,limits={-inf,inf,0},value= root:packages:trEFM:TF:TFDigitizerAverages
	PopupMenu popup1,pos={47,108},size={86,22},bodyWidth=60,proc=PopMenuProcTF,title="Rate"
	PopupMenu popup1,mode=1,popvalue="10 MS",value= #"\"10 MS;50 MS;100MS;5MS;1MS;0.5MS\""
	Button PixelParams,pos={171,38},size={96,24},proc=PixelParams,title="Pixel-wise Settings"
	Button LineParams,pos={171,70},size={96,24},proc=LineParams,title="Line-Wise Settings"
	SetVariable chirpcenter,pos={4,136},size={139,16},title="Chirp Center (Hz)"
	SetVariable chirpcenter,limits={-inf,inf,0},value= root:packages:trEFM:TF:ChirpCenter
	SetVariable ChirpWidth,pos={10,156},size={132,16},title="Chirp Width (Hz)"
	SetVariable ChirpWidth,limits={-inf,inf,0},value= root:packages:trEFM:TF:ChirpWidth
	SetVariable tfrate,pos={25,87},size={107,16},title="Sample Rate"
	SetVariable tfrate,valueBackColor=(60928,60928,60928)
	SetVariable tfrate,limits={-inf,inf,0},value= root:packages:trEFM:TF:TFDigitizerSampleRate,noedit= 1
	SetVariable tfrate1,pos={182,111},size={107,16},title="Resonance"
	SetVariable tfrate1,valueBackColor=(60928,60928,60928)
	SetVariable tfrate1,limits={-inf,inf,0},value= root:packages:trEFM:VoltageScan:calresfreq,noedit= 1
	SetVariable tfrate3,pos={150,131},size={139,16},title="Second Mode"
	SetVariable tfrate3,valueBackColor=(60928,60928,60928)
	SetVariable tfrate3,limits={-inf,inf,0},value= root:packages:trEFM:TF:secondmode,noedit= 1
	CheckBox OneorTwoCHannelBox,pos={167,159},size={107,14},proc=NewCHirp,title="Create New Chirp?"
	CheckBox OneorTwoCHannelBox,variable= root:packages:trEFM:TF:CreateNewChirp,side= 1
	Button saveTF,pos={201,183},size={62,25},proc=SaveTFButton,title="Save TF"
EndMacro

Function TFPanelInit()
	
	NewDataFolder/O/S root:packages:trEFM:TF
	
	Variable/G TFDigitizerAverages = 50
	Variable/G TFDigitizerTime = 1.6
	Variable/G TFDigitizerSampleRate = 10e6
	Variable/G TFDigitizerPercentPreTrig = 97
	Variable/G ChirpCenter = 500e3
	Variable/G ChirpWidth = 450e3

	Variable/G CreateNewChirp = 1
	Variable/G secondmode
	
end

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
	NVAR createNewChirp
	
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

Function LineParams(ctrlname):ButtonControl

	string ctrlname
	PixelParams("")
	
	string savDF = getDataFolder(1)
	
	setDataFolder root:packages:trEFM:TF
	
	NVAR scanpoints = root:packages:treFM:imagescan:scanpoints
	NVAR TFDigitizerAverages
	TFDigitizerAverages = scanpoints

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
	NVAR CreateNewChirp
	
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

	if (CreateNewChirp == 1)
		LoadChirp()
	endif
	
	KillWaves/Z root:packages:trEFM:PointScan:FFtrEFM:gagewave
	KillWaves/Z root:packages:trEFM:PointScan:FFtrEFM:ch2_wave

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

	wavestats/Q/R=(5000, TFDigitizerSampleRate/2) transfer_func_FFT
	
	// Find the levels where the TF crosses
//	FindLevels/N=2/R=(5000, TFDigitizerSampleRate/2) excitation_FFT, excitation_FFT(V_maxLoc)/2
//	Wave W_FindLevels
//	transfer_func_FFT[0, x2pnt(Excitation_FFT, W_FindLevels[0])]= 0
//	transfer_func_FFT[x2pnt(Excitation_FFT, W_FIndLevels[1]), x2pnt(Excitation_FFT, TFDigitizerSampleRate/2)] = 0
	
//	transfer_func_fft /= (excitation_FFT + 1e-10)
	
	SetDataFolder savDF
	
	Beep
end

Function ProcessTF()
// Divides the response by the excitation pulse
end

Function LoadChirp()
	variable f_center = 500e3
	variable f_width = 400e3
	NVAR TFDigitizerTime = root:packages:trEFM:TF:TFDigitizerTime
	variable length = TFDigitizerTime * 1e-3
	NVAR sampling_rate = root:packages:trEFM:TF:TFDigitizerSampleRate
	NVAR ChirpCenter = root:packages:trEFM:TF:ChirpCenter
	NVAR ChirpWidth = root:packages:trEFM:TF:ChirpWidth
	
	string cmd = "cmd.exe /K cd C:\\Data\\Raj && python generate_chirp.py " + num2str(ChirpCenter) + " " + num2str(ChirpWidth) + " " + num2str(length) + " -s " + num2str(sampling_rate) + " && Exit"
	ExecuteScriptText cmd

	print "Generated chirp with frequency", num2str(ChirpCenter), "Hz and width", num2str(ChirpWidth), "Hz,", num2str(length), "seconds long and sampled at",num2str(sampling_rate), "Hz"  
	
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
	

	// Run experiment	
	if (sampling_rate == 10e6)
		loadchirpwave("chirp", offset=0.0, sampling_rate="10E6") // verified on oscilloscope should be offset=0 on 6/19/2020
	elseif (sampling_rate == 100e6)
		loadchirpwave("chirp", offset=0.0, sampling_rate="100E6") // verified on oscilloscope should be offset=0 on 6/19/2020
	endif

	sleep/S 12

end

Function NewChirp(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	NVAR CreateNewChirp = root:packages:trEFM:TF:CreateNewChirp
	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			CreateNewChirp = checked
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function SaveTFButton(ctrlname) : ButtonControl

	String ctrlname
	String saveDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:FFtrEFMConfig
	
	NewPath Path
	Wave pixelconfig
	CreateParametersFile(pixelconfig)
	Wave/T SaveWave
	SaveWave[5] = "n_pixels = " + num2str(1) // set n_pixels to 1
	SaveWave[7] = "lines_per_image = " + num2str(0)
	Save/G/I/P=Path/M="\r\n" SaveWave as "TFparameters.cfg"
	
	SetDataFolder root:packages:trEFM:TF
	Save/C/I/P=Path root:packages:trEFM:PointScan:FFtrEFM:gagewave_chirp as "TF_Response.ibw"
	Save/C/I/P=Path root:packages:trEFM:PointScan:FFtrEFM:tip_chirp as "TF_Excitation.ibw"
		
End
