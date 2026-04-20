IMSKPM_Panel_Old.ipf
====================

Legacy version of the IM-SKPM panel. Superseded by IMSKPM_Panel.ipf but
retained for reference. Contains additional frequency/intensity/duty-cycle
list helpers that are not in the current panel.

IMSKPM_Panel
------------
Legacy panel window definition for IM-SKPM.

IMFrequencyListButton
---------------------
Button handler that calls FrequencyLIst() to populate the frequency list.

Parameters
~~~~~~~~~~
ctrlname: string
	Name of the button control

IMSKPMAMButton
--------------
Button handler that launches a full IM-SKPM AM scan.

Parameters
~~~~~~~~~~
ctrlname: string
	Name of the button control

IMSKPMSingle_AMButton
---------------------
Button handler that runs a single-frequency AM-SKPM point scan.

Parameters
~~~~~~~~~~
ctrlname: string
	Name of the button control

IMSKPMFMButton
--------------
Button handler that launches an IM-SKPM FM point scan.

Parameters
~~~~~~~~~~
ctrlname: string
	Name of the button control

IMSKPMAM_ImageScanButton
------------------------
Button handler that launches an IM-SKPM AM image scan.

Parameters
~~~~~~~~~~
ctrlname: string
	Name of the button control

IM_FFtrEFMButton
----------------
Button handler that launches an IM-SKPM FFtrEFM image scan.

Parameters
~~~~~~~~~~
ctrlname: string
	Name of the button control

PointScanIMSKPM_AM
------------------
Core AM-SKPM point scan routine.

Parameters
~~~~~~~~~~
xpos: variable
	X position in microns

ypos: variable
	Y position in microns

liftheight: variable
	Lift height in nanometers

numavg: variable
	Number of averages per pixel

Shuffle
-------
Shuffles the order of a wave in-place.

Parameters
~~~~~~~~~~
InWave: wave
	Wave to shuffle

FrequencyLIst
-------------
Builds the frequency list wave from current panel globals.

Parameters
~~~~~~~~~~
freqlistchoice: variable
	Index selecting which frequency list preset to use

IntensityLIst
-------------
Builds the intensity list wave from a starting intensity value.

Parameters
~~~~~~~~~~
Intensity1: variable
	Starting intensity value

DutyLIst
--------
Builds the duty-cycle list wave from current panel globals.

imskpm
------
Fit function for the IM-SKPM amplitude-vs-frequency curve.

Parameters
~~~~~~~~~~
w: wave
	Fit coefficients wave

f: variable
	Frequency in Hz

SingleFrequency_IMSKPMAM
------------------------
Single-frequency AM-SKPM point scan, optionally with interpolation.

Parameters
~~~~~~~~~~
xpos: variable
	X position in microns

ypos: variable
	Y position in microns

liftheight: variable
	Lift height in nanometers

numavg: variable
	Number of averages per pixel

interpval: variable *(optional)*
	Interpolation factor
