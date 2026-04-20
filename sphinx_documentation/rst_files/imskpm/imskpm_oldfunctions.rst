IMSKPM_oldfunctions.ipf
=======================

Legacy IM-SKPM acquisition and averaging functions. Extracted from SKPM.ipf
and no longer used in active acquisition workflows.

PointScanIMFMSKPM
-----------------
Legacy FM-SKPM point scan using intensity modulation.

Parameters
~~~~~~~~~~
amplitude: variable
	AC drive amplitude in volts

averageIMSKPMdata
-----------------
Averages IM-SKPM frequency-shift data across a set of frequencies.

Parameters
~~~~~~~~~~
numberOfFreq: variable
	Number of frequencies to average over

NetAverageIMSKPMdata
--------------------
Computes the net (background-subtracted) average of IM-SKPM data.

Parameters
~~~~~~~~~~
numberOfFreq: variable
	Number of frequencies to average over

NetAverageIMSKPMdata2
---------------------
Second variant of the net-average computation, using an alternate
background-subtraction scheme.

Parameters
~~~~~~~~~~
numberOfFreq: variable
	Number of frequencies to average over

NormNetAverageIMSKPMdata
------------------------
Normalizes the net-averaged IM-SKPM data to the drive intensity.

Parameters
~~~~~~~~~~
numberOfFreq: variable
	Number of frequencies to average over
