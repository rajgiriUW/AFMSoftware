ElecCal.ipf
===========

GetElecTip
----------
Applies an electrical

Parameters
~~~~~~~~~~
tipV: variable
	description

GetElecNoiseTip
---------------
Applies an electrical

Parameters
~~~~~~~~~~
tipV: variable

ForceCalibration_Noise
----------------------
Only works with ARC Lockin selected due to issues with td_xSetOutWave and the Cypher Lockin. Acquires the noise spectra by driving the tip up to below first resonance

Parameters
~~~~~~~~~~
elecOn: variable *(optional)*
	description