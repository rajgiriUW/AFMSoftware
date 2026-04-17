#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Intensity-modulated FM-SKPM acquisition and averaging functions.
// Extracted from SKPM.ipf; no longer used in active acquisition.

Function PointScanIMFMSKPM(amplitude)

	variable amplitude

	string savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:PointScan:SKPM

	Wave CPDwave

	Variable/G iteration_tracker
	iteration_tracker = 0

	String/G folder_path
	NewPath folder_path

	variable/G current_freq
	String/G skpm_path

	//////////////////////////////////////////////////////////
	Variable numberOfFreq= 25
	Make/O/N=(numberOfFreq) frequency_list
	variable lowfreq = 0.5
	variable firstfreq = 1
	variable lastfreq = 10000000
	/////////////////////////////////////////////////////////////

	variable interv=(lastfreq/firstfreq)^(1/(numberOfFreq-1))
	variable i,j
	for(i=0; i<numberOfFreq; i+=1)
		frequency_list[i]=firstfreq*interv^(i)
	endfor

	variable wave_points = DimSize(CPDwave,0)
	Make/O/N=(wave_points,numberOfFreq) IMWaves, MilliWaves
	IMWaves=0
	MilliWaves=0

	String savDF2 = GetDataFolder(1)
	SetDataFolder root:Packages:trEFM
	Nvar liftheight
	Nvar gxpos, gypos
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	Nvar DwellTime
	if( IsNan(gxpos) | IsNan(gypos))
		Abort "X and Y are NaN. Make sure to get the current position before continuing."
	endif
	SetDataFolder savDF2

	for(i=0; i<numberOfFreq; i+=1)

		SetVFSquBis(amplitude, lowfreq, "11" )
		print "the current frequency is:",lowfreq,"Hz"
		sleep/s .1
		PointScanSKPM(gxpos, gypos, liftheight, DwellTime)
		GetCurrentPosition()
		MilliWaves[][iteration_tracker] = CPDwave[p]

		SetVFSquBis(amplitude, frequency_list[i], "11" )
		print "the current frequency is:", frequency_list[i],"Hz (",i+1,"/",numberOfFreq,")"
		sleep/s .1
		PointScanSKPM(gxpos, gypos, liftheight, DwellTime)
		GetCurrentPosition()

		IMWaves[][iteration_tracker] = CPDwave[p]

		iteration_tracker+=1

		averageIMSKPMdata(numberOfFreq)
		NetAverageIMSKPMdata(numberOfFreq)
		NetAverageIMSKPMdata2(numberOfFreq)
		NormNetAverageIMSKPMdata(numberOfFreq)

	endfor

	//SetVFSquBis(0.01, 1, "11" )
	SetVFSquBis(5, 1, "11" )

	print "That's it, we're done."
	SetDataFolder root:packages:trEFM:PointScan:SKPM
	Save/C/O/P=folder_path IMWaves as "IMWaves.ibw"
	Save/C/O/P=folder_path Milliwaves as "Milliwaves.ibw"
	Save/C/O/P=folder_path frequency_list as "frequency_list.ibw"

	SetDataFolder savDF

	variable iiiii
	for(iiiii = 0; iiiii <4;iiiii+=1)
	Beep
	Sleep/s 1/8
	endfor
End

Function averageIMSKPMdata(numberOfFreq)

	variable numberOfFreq
	wave IMWaves, MilliWaves

//	string savDF = GetDataFolder(1)
//	SetDataFolder root:packages:trEFM:PointScan:SKPM

	Make/O/N=(numberOfFreq) IMWavesAVG, MilliWavesAVG, MilliWavesAVGsup, MilliWavesAVGinf
	variable wave_points = DimSize(IMWaves,0)

	variable i,j
	for(i = 0; i <numberOfFreq; i+=1)

		wavestats /Q /R=[i*wave_points, (i+1)*wave_points] MilliWaves
		MilliWavesAVG[i]=V_avg

		variable tempMax=0
		variable tempMin=0
		variable couterMax=0
		variable couterMin=0
		for(j = 0; j <wave_points; j+=1)
			if(MilliWaves[j][i] > V_avg+0.05*V_avg)
				tempMax+=MilliWaves[j][i]
				couterMax+=1
			elseif(MilliWaves[j][i] < V_avg-0.05*V_avg)
				tempMin+=MilliWaves[j][i]
				couterMin+=1
			endif
		endfor

		if(couterMax!=0)
		MilliWavesAVGsup[i]=tempMax/couterMax
		else
		MilliWavesAVGsup[i]=0
		endif
		if(couterMax!=0)
		MilliWavesAVGinf[i]=tempMin/couterMin
		else
		MilliWavesAVGinf[i]=0
		endif

		wavestats /Q /R=[i*wave_points, (i+1)*wave_points] IMWaves
		IMWavesAVG[i]=V_avg

	endfor

//	SetDataFolder savDF
End

Function NetAverageIMSKPMdata(numberOfFreq)

	variable numberOfFreq
	wave IMWaves, MilliWaves
	wave IMWavesAVG, MilliWavesAVG, MilliWavesAVGsup, MilliWavesAVGinf

//	string savDF = GetDataFolder(1)
//	SetDataFolder root:packages:trEFM:PointScan:SKPM

	Make/O/N=(numberOfFreq) netAvgSPV

	variable i,j
	for(i = 0; i <numberOfFreq; i+=1)
		NetAvgSPV[i]=(IMWavesAVG[i]-MilliWavesAVGsup[i])/(MilliWavesAVGinf[i]-MilliWavesAVGsup[i])
	endfor

//	SetDataFolder savDF
End


Function NetAverageIMSKPMdata2(numberOfFreq)

	variable numberOfFreq
	wave IMWaves, MilliWaves
	wave IMWavesAVG, MilliWavesAVG, MilliWavesAVGsup, MilliWavesAVGinf, netAvgSPV

	string savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:PointScan:SKPM

	Make/O/N=(numberOfFreq) netAvgSPV2

	variable i,j
	for(i = 0; i <numberOfFreq-1; i+=1)
		NetAvgSPV2[i]=(IMWavesAVG[i]-0.5*(MilliWavesAVGsup[i]+MilliWavesAVGsup[i+1]))/(0.5*(MilliWavesAVGinf[i]+MilliWavesAVGinf[i+1])-0.5*(MilliWavesAVGsup[i]+MilliWavesAVGsup[i+1]))
	endfor
	NetAvgSPV2[numberOfFreq-1]=(IMWavesAVG[numberOfFreq-1]-MilliWavesAVGsup[numberOfFreq-1])/(MilliWavesAVGinf[numberOfFreq-1]-MilliWavesAVGsup[numberOfFreq-1])

	SetDataFolder savDF
End


Function NormNetAverageIMSKPMdata(numberOfFreq)

	variable numberOfFreq
	wave IMWaves, MilliWaves
	wave IMWavesAVG, MilliWavesAVG, MilliWavesAVGsup, MilliWavesAVGinf, NetAvgSPV2

	string savDF = GetDataFolder(1)
	SetDataFolder root:packages:trEFM:PointScan:SKPM

	Make/O/N=(numberOfFreq) NormNetAvgSPV

	wavestats /Q netAvgSPV2
	variable i,j
	for(i = 0; i <numberOfFreq; i+=1)
		NormNetAvgSPV[i]=0.5+0.5*(netAvgSPV2[i]-V_min)/(v_max-v_min)
	endfor

	SetDataFolder savDF
End
