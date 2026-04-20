Moku_Het.ipf
============

Heterodyne SKPM acquisition using the Moku:Lab as the lock-in and signal
source. Drives the cantilever at wAC such that wAC - w0 = w1 (first
resonance), detecting at w2 = w1 + wAC (second resonance).

Moku_HK
-------
Heterodyne SKPM point scan. Configures the Moku:Lab outputs for
heterodyne detection and records CPD data.

Parameters
~~~~~~~~~~
xpos: variable
	X position in microns

ypos: variable
	Y position in microns

liftheight: variable
	Lift height in nanometers

wACvoltage: variable *(optional)*
	AC drive voltage on the function generator in volts

interpolation: variable *(optional)*
	Interpolation flag; defaults to 1 (enabled)
