IMSKPM_FM.ipf
=============

Intensity-modulated FM-SKPM point scan functions.

PointScanIMSKPM_FM
------------------
FM-SKPM point scan. Engages on the surface, applies intensity-modulated
drive, and records cantilever frequency shift data for surface potential
extraction.

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

PointScanIMSKPM_EFM
-------------------
EFM variant of the IM-SKPM FM point scan. Records electrostatic force
gradient data without feedback nulling.

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
