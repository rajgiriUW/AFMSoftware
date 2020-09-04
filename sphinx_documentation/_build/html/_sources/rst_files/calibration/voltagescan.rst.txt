VoltageScan.ipf
===============

GetGlobals
----------
Function that grabs some settings from the Asylum variables and assigns them as global variables.

GrabTune
--------
Given a target value for the soft amplitude, this function grabs the corresponding tune variables

Parameters
~~~~~~~~~~
softamplitude: variable
   description

VoltageScan
-----------
Given a X position, Y position, and a liftheight this function scans over a range of voltages from vmin to vmax and records the frequency offset as a function of these voltages. The user can optionally specify vmin, vmax, and the number of points to take

Parameters
~~~~~~~~~~
xpos: variable
   description

ypos: variable
   description

liftheight: variable
	description

vmin: variable *(optional)*
	description

vmax: variable *(optional)*
	description

npoints: variable *(optional)*
	description

HeightScan
----------
Given a X position, Y position, and constant voltage this function scan from zmin to zmax and records the frequency shift
as a function of liftheight. Zmin, zmax, and number of points can be specified by the user.

Parameters
~~~~~~~~~~
xpos: variable
	description

ypos: variable
	description

voltage: variable
	description

zmin: variable *(optional)*
	description

zmax: variable *(optional)*
	description

npoints: variable *(optional)*
	description