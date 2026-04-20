Moku_SKPM.ipf
=============

Moku:Lab-based AM-SKPM and FM-SKPM point scan functions. The Moku:Lab
replaces the software lock-in, with its outputs routed through the ARC
BNC connectors (Input 1 = Defl, Input 2 = BNCOut2/DDS, Output 1 = BNCIn2
in-phase, Output 2 = BNCIn1 quadrature).

MokuPS_AM
---------
AM-SKPM point scan using the Moku:Lab as the lock-in amplifier.

Parameters
~~~~~~~~~~
xpos: variable
	X position in microns

ypos: variable
	Y position in microns

liftheight: variable
	Lift height in nanometers

interpolation: variable *(optional)*
	Interpolation flag; defaults to 1 (enabled)

MokuPSFM
--------
FM-SKPM point scan using the Moku:Lab.

Parameters
~~~~~~~~~~
xpos: variable
	X position in microns

ypos: variable
	Y position in microns

liftheight: variable
	Lift height in nanometers

interpolation: variable *(optional)*
	Interpolation flag; defaults to 1 (enabled)

MokuPSFM_ARC
------------
FM-SKPM point scan using the Moku:Lab with ARC controller Z-feedback
routing.

Parameters
~~~~~~~~~~
xpos: variable
	X position in microns

ypos: variable
	Y position in microns

liftheight: variable
	Lift height in nanometers

interpolation: variable *(optional)*
	Interpolation flag; defaults to 1 (enabled)

tunecurve
---------
Records a cantilever tune curve centered on the specified resonance
frequency using the Moku:Lab.

Parameters
~~~~~~~~~~
resfreq: variable
	Center resonance frequency in Hz

w1w2_tune
---------
Simultaneously tunes both the first and second cantilever resonances
using the Moku:Lab, iterating until both peaks are located.

Parameters
~~~~~~~~~~
iterations: variable *(optional)*
	Maximum number of tuning iterations
