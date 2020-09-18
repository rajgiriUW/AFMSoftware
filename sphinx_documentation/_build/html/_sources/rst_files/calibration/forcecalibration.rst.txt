ForceCalibration.ipf
====================

amps
----
function description

Parameters
~~~~~~~~~~
w0: wave
	description

w: variable
	description

Return
~~~~~~
w0[0]*w0[1]^2 / sqrt( (w^2-w0[1]^2)^2 + (w * w0[1]/w0[2]) ^ 2) 
	description

amps_n
------
function description

Parameters
~~~~~~~~~~
w0: wave
	description

w: variable
	description

Return
~~~~~~
w0[0]*w0[1]^2 / sqrt( (w^2-w0[1]^2)^2 + (w * w0[1]/w0[2]) ^ 2 + (w * w0[1] * w0[3])^2)
	description

GetForceParms
-------------
Main Force Cal Function. Must use ARC Lockin

Parameters
~~~~~~~~~~
tipV: variable
	description

GetForceParms_Light
-------------------
function description

Parameters
~~~~~~~~~~
tipV: variable
	description

SetupForceCalibration
---------------------
function description

Parameters
~~~~~~~~~~
range: variable *(optional)*
	description

ForceCalibration
----------------
Only works with ARC Lockin selected due to issues with td_xSetOutWave and the Cypher Lockin

Parameters
~~~~~~~~~~
tipV: variable
	description

lighton: variable *(optional)*
	description

elecon: variable *(optional)*
	description

GetFreeCantileverParms
----------------------
function description

GetSurfaceCantileverParms
-------------------------
Saves/calculates cantilever parameters and saves into FinalParms

FWHM
----
function description

Parameters
~~~~~~~~~~
inwave: wave
	description

Return
~~~~~~
inwavemaxloc/(fwhmH - fwhmL)
	description

findAdrive
-----------
function description

Parameters
~~~~~~~~~~
AmpVal: variable
	description

betaVal: variable
	description

resFval: variable
	description

driveFval: variable
	description

mass: variable
	description

Return
~~~~~~
Ampdrive
	description

getForce
--------
function description

Parameters
~~~~~~~~~~
calAmp: wave
	description

calDef: wave
	description

DEFINVOLS: variable
	description

k: variable
	description

Return
~~~~~~
F: variable
	description

LiftTo
------
function description

Parameters
~~~~~~~~~~
liftHeight: variable
	description

tipVoltage: variable
	description

lighton: variable *(optional)*
	description

LiftToElect
-----------
function description

Parameters
~~~~~~~~~~
liftHeight: variable
	description