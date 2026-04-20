IMSKPM_Panel.ipf
================

Igor panel and button-handler functions for the IM-SKPM interface. Provides
the GUI controls that drive the IM-SKPM acquisition modes.

IMSKPM_Panel
------------
Defines the IM-SKPM panel window layout.

IMFrequencyListButton
---------------------
Button handler that calls FrequencyLIst() to populate the frequency list
wave from current panel globals.

Parameters
~~~~~~~~~~
ctrlname: string
	Name of the button control

IMSKPMAMButton
--------------
Button handler that launches a full IM-SKPM AM image or point scan.

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
Core AM-SKPM point scan routine called by the panel button handlers.

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
Builds the frequency list wave from global frequency step and range parameters.

imskpm
------
Fit function for the IM-SKPM amplitude-vs-frequency curve used during
surface potential extraction.

Parameters
~~~~~~~~~~
w: wave
	Fit coefficients wave

f: variable
	Frequency in Hz

SingleFrequency_IMSKPMAM
------------------------
Runs a single-frequency AM-SKPM point scan, optionally with interpolation.

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
