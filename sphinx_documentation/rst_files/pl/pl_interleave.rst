PL_interleave.ipf
=================

Interleaved LBIC (laser beam induced current) and topography scan. Alternates
between contact and lift passes to simultaneously acquire surface topography
and photocurrent images.

LBICscan_interleave
-------------------
Interleaved LBIC image scan. Uses the lock-in output to record photocurrent
at each pixel while maintaining topographic feedback.

Parameters
~~~~~~~~~~
xpos: variable
	X position in microns

ypos: variable
	Y position in microns

scansizeX: variable
	Scan size in X in microns

scansizeY: variable
	Scan size in Y in microns

scanlines: variable
	Number of scan lines

scanpoints: variable
	Number of scan points per line
