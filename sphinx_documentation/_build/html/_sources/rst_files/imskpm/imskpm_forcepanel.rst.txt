IMSKPM_ForcePanelSpoofMethod.ipf
================================

AM-SKPM implementation that spoofs the Asylum Force panel callback to enable
surface potential detection via the built-in Force panel infrastructure.

PointScanIMSKPM_forcepanel
--------------------------
AM-SKPM point scan using the Force panel spoof method. Sets up a staged
callback sequence via the MFP3D Force panel so that each tip-sample approach
triggers CPD extraction.

Parameters
~~~~~~~~~~
amplitude: variable
	AC drive amplitude in volts

Stage1
------
First callback stage: engages feedback loop and begins electrostatic
drive sequence.

Stage2
------
Second callback stage: switches crosspoint routing and records CPD data.

Stage3
------
Third callback stage: restores feedback parameters and stores the CPD result
wave.
