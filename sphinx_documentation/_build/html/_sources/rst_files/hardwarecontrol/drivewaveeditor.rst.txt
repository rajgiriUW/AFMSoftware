DriveWaveEditor.ipf
===================

VoltageWaveEditor
-----------------
Call this function to open to function editor and edit the voltage wave that is sent to the tip during the Point Scan Experiment.

TriggerWaveEditor
-----------------
Call this function to edit the wave that will be sent to the trigger LED box

LightWaveEditor
---------------
Call this function to edit the wave that will be sent to the trigger LED box

RingDownWaveEditor
------------------
Call this function to edit the wave that will be sent to the trigger LED box

CutWaveEditor
-------------
Call this function to edit the wave that will be sent to the drive to "cut" the drive. This logic uses "trigger wave" as the point where the drive should be cut. This allows us to do the equivalent of ringdown but at arbitrary locations

Parameters
~~~~~~~~~~
checked: variable
	description

CutDriveProc
------------
function description

Parameters
~~~~~~~~~~
cba: struct
	description

InitARFEDriveParmsGL
---------------------
function description

Parameters
~~~~~~~~~~
InfoStruct: struct
	description

CleanDriveWave
--------------
A (hopefully) temporary function that solves the problem of extra points being inserted at the end of our drive waves. 

Parameters
~~~~~~~~~~
drivewave: wave
	description

AppendCycles
------------
Call this function to open to function editor and edit the voltage wave that is sent to the tip during the Point Scan Experiment.

Parameters
~~~~~~~~~~
numcycles: variable
	description