IMSKPM_AM.ipf
=============

Intensity-modulated AM-SKPM acquisition. Contains three methods: (1) AM mode
using the Asylum Force panel (David M./Jake P. method), (2) AM mode using
direct feedback loop configuration, and (3) a staged acquisition approach.

PointScanIMSKPM_AM
------------------
AM-SKPM point scan using direct feedback loop configuration. Engages on the
surface, lifts to the panel height, switches feedback method and crosspoint,
then records waves for specified durations.

Parameters
~~~~~~~~~~
xpos: variable
	X position in microns

ypos: variable
	Y position in microns

liftheight: variable
	Lift height in nanometers

Shuffle
-------
Shuffles the order of a wave in-place.

Parameters
~~~~~~~~~~
InWave: wave
	Wave to shuffle

IMSKPM_FM
---------
FM-SKPM wrapper calling PointScanIMSKPM_FM.

Parameters
~~~~~~~~~~
xpos: variable
	X position in microns

ypos: variable
	Y position in microns

liftheight: variable
	Lift height in nanometers

FrequencyLIst
-------------
Builds the frequency list wave used in IM-SKPM acquisitions from global
frequency step and range parameters.

PointScanIMSKPM_forcepanel
--------------------------
AM-SKPM point scan using the Force panel spoof callback method. See
IMSKPM_ForcePanelSpoofMethod.ipf for the current implementation.

Parameters
~~~~~~~~~~
amplitude: variable
	AC drive amplitude in volts

Stage1
------
First stage of the staged AM-SKPM acquisition: engages feedback and records
the first time window.

Stage2
------
Second stage of the staged AM-SKPM acquisition: switches crosspoint and
records the second time window.

Stage3
------
Third stage of the staged AM-SKPM acquisition: restores feedback settings
and saves data.
