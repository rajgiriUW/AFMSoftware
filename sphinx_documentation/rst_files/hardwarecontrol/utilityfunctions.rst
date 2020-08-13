UtilityFunctions.ipf
====================

ResetAll
--------
This function stops any feedback loops, wave banks, and resets all outputs to ground.

SetCrossPoint
-------------
Function takes the required input settings and writes the appropriate string and wave. Then it uses the Asylum functions to write them to the crosspoint switch. Typical outputs: OutC = trigger, OutA = light, OutB = voltage. Note that if you connect the trigger to the output you should connect the light straight to ARC.

Parameters
~~~~~~~~~~
InA: string
	description

InB: string
	description

InFast: string
	description

InAOffset: string
	description

InBOffset: string
	description

InFastOffset: string
	description

OutXMod: string
	description

OutYMod: string
	description

OutZMod: string
	description

FilterIn: string
	description

BNCOut0: string
	description

BNCOut1: string
	description

BNCOut2: string
	description

PogoOut: string
	description

Chip: string
	description

Shake: string
	description

SetPassFilter
-------------
Function sets the pass filter cutoff frequency on the input LPF to Asylum's ADC	
The SetorReset parameter is 0 or 1, SetorReset==0 ignores ALL optional parms and resets to the globally stored values
SetorReset==1 will set the Pass Filter for all optional parameters and leave unnamed channels alone
EX: glSetPassFilter(0)  - will reset all pass filters to their stored values
glSetPassFilter(1,a=2000,i=20000) - will set the a%PassFilter and i%PassFilter to the specified values and leave all other filters alone.

Parameters
~~~~~~~~~~
SetorReset: variable
	description

x: variable *(optional)*
	description

y: variable *(optional)*
	description

z: variable *(optional)*
	description

a: variable *(optional)*
	description

b: variable *(optional)*
	description

fast: variable *(optional)*
	description

i: variable *(optional)*
	description

i1: variable *(optional)*
	description

q: variable *(optional)*
	description

q1: variable *(optional)*
	description

SetFeedbackLoop
---------------
Sets up a PIDS feedback loop. This function will set changeWhat to the setpoint by adjusting the value of maintainWhat. The user also must select the gain settings to be used by the PID.

Parameters
~~~~~~~~~~
whichLoop: variable
	description

startWhen: string
	description

maintainWhat: string
	description

setpoint: variable
	description

pgain: variable
	description

igain: variable
	description

sgain: variable
	description

changeWhat: string
	description

dgain: variable
	description

Return
~~~~~~
error
	description

SetFeedbackLoopCypher
---------------------
Sets up a PIDS feedback loop. This function will set changeWhat to the setpoint by adjusting the value of maintainWhat. The user also must select the gain settings to be used by the PID.

Parameters
~~~~~~~~~~
whichLoop: variable
	description

startWhen: string
	description

maintainWhat: string
	description

setpoint: variable
	description

pgain: variable
	description

igain: variable
	description

sgain: variable
	description

changeWhat: string
	description

dgain: variable
	description

Return
~~~~~~
error
	description

StopFeedbackLoop
----------------
Given an integer number corresponding to one of the 5 feedback loops, this function stops the specified feedback loop.

Parameters
~~~~~~~~~~
whichLoop: variable
	description

Return
~~~~~~
error
	description

StopFeedbackLoopCypher
----------------------
Given an integer number corresponding to one of the 5 feedback loops, this function stops the specified feedback loop.

Parameters
~~~~~~~~~~
whichLoop: variable
	description

Return
~~~~~~
error
	description

ReadPosition
------------
Prints the current X, Y, and Z position to the console

MoveXYZ
-------
a function that moves the xy stage to the desired position (given in microns)

Parameters
~~~~~~~~~~
Xposition: variable
	description

Yposition: variable
	description

Zposition: variable
	description

MoveXY
------
Moves to the X,Y position while keeping the tip withdrawn away from the surface.

Parameters
~~~~~~~~~~
xpos: variable
	description

ypos: variable
	description

CheckInWaveTiming
-----------------
this function checks a specifiec data point in the named inWave and continues to run until that data point has a value. It is used to ensure that the function calling it runs until all required data has been collected. If whichDataPoint is specified then the function checks that, otherwise it checks the last data point
NOTES: This fxn assumes the passed wave is currently set to NaN, whichDataPoint is the integer index to the data point you want to key on

Parameters
~~~~~~~~~~
whichWave: wave
	description

whichDataPoint: variable *(optional)*
	description

LightOnOff
----------
turns the LED on or off (1 or 0).

Parameters
~~~~~~~~~~
onoff: variable
	description

wavegenerator
-------------
function description

Parameters
~~~~~~~~~~
amplitude: variable
	description

frequency: variable
	description

outputletter: string
	description

event: string
	description

bank: variable
	description

wavegeneratoroffset
-------------------
function description

Parameters
~~~~~~~~~~
amplitude: variable
	description

frequency: variable
	description

outputletter: string
	description

event: string
	description

bank: variable
	description