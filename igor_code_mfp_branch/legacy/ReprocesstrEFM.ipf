#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// ReprocesstrEFM.ipf
//
// Offline reprocessing utilities for trEFM and FFtrEFM image data.
// Combined from UserAnalysis.ipf (PC, MG 2014-06) and ReDoAnalysis.ipf.
//
// trEFMReprocess()   -- classic time-domain trEFM: loads trEFM_000N.ibw files,
//                       averages raw frequency-shift traces, fits exponential decay.
//                       User supplies fit window (ms), scan geometry, and # averages.
//
// FFtrEFMReprocess() -- FFtrEFM pipeline: loads FFtrEFM_000N.ibw line files and
//                       rebuilds tfp/shift/rate images using stored PIXELCONFIG params.
//
// aver()             -- diagnostic helper: loads a single pixel trace and plots the
//                       averaged frequency shift used to build that image point.


// ── trEFM (time-domain) reprocessing ─────────────────────────────────────────────

Function trEFMReprocess(Fitstart, Fitstop, numavgs, scanpoints, scanlines)

	Variable Fitstart, Fitstop, numavgs, scanpoints, scanlines
	Wave readwavefreq
	Wave cycletime

	GetFileFolderInfo/Q/D
	NewPath/C/M="Please Select Folder"/O/Q/Z FolderPath, S_Path

	Fitstart =  round((fitstart * 1e-3) * (50000 / 1))
	print fitstart
	Fitstop = round((fitstop * 1e-3) * (50000 / 1))
	print fitstop

	Make/O/N = (scanpoints, scanlines) ChargingRate_user, FrequencyOffset_user, Chi2Image_user
		Chi2Image_user=0

	Variable V_FitOptions, j = 0, m, i = 0, k

	Make/O/N = (Fitstop - Fitstart) ReadWaveFreqtemp, CycleTime

	k=0
	do
		CycleTime[k]=k * (1/50000) * 1
		k += 1
	while (k < Fitstop-Fitstart)

	do
		j=0
		if (i < 10)
			LoadWave/O/H/P=FolderPath "trEFM_000" + num2str(i) + ".ibw"
		elseif (i < 100)
			LoadWave/O/H/P=FolderPath "trEFM_00" + num2str(i) + ".ibw"
		else
			LoadWave/O/H/P=FolderPath "trEFM_0" + num2str(i) + ".ibw"
		endif

			do
				V_FitOptions = 4
				ReadWaveFreqTemp = 0
				k = 0
				m = j*800*numavgs

				Make/O/N = (Fitstop - Fitstart, numavgs) ReadwaveFreqAVG
				variable avgloopp = 0
				do
					Duplicate/O/R=[m+Fitstart, m+Fitstop] ReadwaveFreq, Temp1
					ReadWaveFreqAvg[][avgloopp] = Temp1[p] - 500

					avgloopp += 1

					m += 800
				while (avgloopp < numavgs)

				MatrixOp/O readwavefreqtemp = sumrows(readwavefreqavg) / numcols(ReadWaveFreqAvg)


				make/o/n=3 W_sigma
				Make/O/N=3 W_Coef
				Make/O/T/N=1 T_Constraints
				T_Constraints[0] = {"K2>(1/100000)", "K2<10"}

				curvefit/N=1/Q exp_XOffset, readwavefreqtemp  /x=CycleTime /C=T_Constraints
				FrequencyOffset_user[scanpoints-j-1][i]=W_Coef[1]
				ChargingRate_user[scanpoints-j-1][i]=1/(W_Coef[2])
				Chi2Image_user[scanpoints-j-1][i]=W_sigma[2]

				j+=1
			while (j < scanpoints)

		i+=1
	while(i<scanlines)

End


// ── FFtrEFM reprocessing ──────────────────────────────────────────────────────────

Function FFtrEFMReprocess()
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

	SetDataFolder savDF
End


// ── Diagnostic helper ─────────────────────────────────────────────────────────────

// aver(): load a single pixel's raw .ibw and plot the averaged frequency-shift trace.
// pixel     = pixel index to inspect
// nmavgs    = number of averages per pixel
// scanpoints = scan points per line
Function aver(pixel, nmavgs, scanpoints)

	Variable pixel, nmavgs, scanpoints
	Variable i,k

	GetFileFolderInfo/Q
	if(V_flag<0)
		return -1
	elseif(V_flag==0 && V_isFile==1)
		String filePath = S_Path
	endif
	LoadWave/Q/N=ReadWaveFreq/O filePath

	i=(scanpoints - pixel)*nmavgs*800 -  nmavgs*800

	Make/o/n= (800,nmavgs) Test2
	Make/o/n=800 Test3

	k=i+799
	Variable avgloo=0
	Wave readwavefreq

	do
		Duplicate/O/R = [i,k] ReadwaveFreq, Test1
		test2[][avgloo] = Test1[p] - 500
		avgloo += 1
		i += 800
		k += 800
	while (avgloo < nmavgs)

	MatrixOp/O Test3 = sumrows(test2) / numcols(test2)

	Make/O/N=800 TimeAnalysis
	TimeAnalysis = x*20E-6

	DoWindow/F FreqShiftPlot
	If(V_flag == 0)
		Display Test3 vs TimeAnalysis
		ModifyGraph tick=2,mirror=1,fSize=16,standoff=0
		ModifyGraph width=360,height=288
		Label bottom "\\u#2Time (ms)"
		Label left "Frequency Shift (Hz)"
		ModifyGraph wbRGB=(40000,40000,40000),gbRGB=(52224,52224,52224)
		DoWindow/C FreqShiftPlot
	else
		DoUpdate/W=FreqShiftPlot
	endif

End
