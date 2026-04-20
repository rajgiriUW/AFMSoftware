Common.ipf
==========

Hardware control primitives shared across all acquisition modes. Wraps ARC
controller (td_\*), lock-in, and stage commands into higher-level operations
used by PointScan, ImageScan, and SKPM modules.

ResetAll
--------
Stops all feedback loops, zeros all DAC outputs, and restores cantilever
drive to engage settings. Called at the start and end of every point/image
scan.

SetCrosspoint
-------------
Writes the analog crosspoint switch matrix routing.

Parameters
~~~~~~~~~~
InA: variable
	Signal assigned to InA crosspoint slot

InB: variable
	Signal assigned to InB crosspoint slot

InFast: variable
	Signal assigned to InFast crosspoint slot

InAOffset: variable
	Offset for InA

InBOffset: variable
	Offset for InB

InFastOffset: variable
	Offset for InFast

OutXMod: variable
	Output X modulation routing

OutYMod: variable
	Output Y modulation routing

OutZMod: variable
	Output Z modulation routing

FilterIn: variable
	Filter input routing

BNCOut0: variable
	BNC output 0 routing

BNCOut1: variable
	BNC output 1 routing

BNCOut2: variable
	BNC output 2 routing

PogoOut: variable
	Pogo pin output routing

Chip: variable
	Chip select

Shake: variable
	Cantilever shake routing

SetPassFilter
-------------
Sets or resets ARC pass-filter parameters. Omitted keyword arguments leave
the corresponding channels unchanged.

Parameters
~~~~~~~~~~
SetorReset: variable
	1 to set filters, 0 to reset

x: variable *(optional)*
	X channel filter value

y: variable *(optional)*
	Y channel filter value

z: variable *(optional)*
	Z channel filter value

a: variable *(optional)*
	A channel filter value

b: variable *(optional)*
	B channel filter value

fast: variable *(optional)*
	Fast channel filter value

i: variable *(optional)*
	I channel filter value

i1: variable *(optional)*
	I1 channel filter value

q: variable *(optional)*
	Q channel filter value

q1: variable *(optional)*
	Q1 channel filter value

SetFeedbackLoop
---------------
Configures and starts one ARC PID feedback loop.

Parameters
~~~~~~~~~~
whichLoop: variable
	Loop index (0-based)

startWhen: variable
	Condition code for loop start

maintainWhat: variable
	Signal index to regulate

setpoint: variable
	PID setpoint

pgain: variable
	Proportional gain

igain: variable
	Integral gain

sgain: variable
	Sum gain

changeWhat: variable
	Output signal index

dgain: variable
	Derivative gain

name: string *(optional)*
	Loop name string

arcZ: variable *(optional)*
	1 to route output through Z-height servo

outmax: variable *(optional)*
	Output maximum clamp

outmin: variable *(optional)*
	Output minimum clamp

SetFeedbackLoop_v14
-------------------
Firmware v14 variant of SetFeedbackLoop.

Parameters
~~~~~~~~~~
whichLoop: variable
	Loop index

startWhen: variable
	Start condition code

maintainWhat: variable
	Signal index to regulate

setpoint: variable
	PID setpoint

pgain: variable
	Proportional gain

igain: variable
	Integral gain

sgain: variable
	Sum gain

changeWhat: variable
	Output signal index

dgain: variable
	Derivative gain

SetFeedbackLoopCypher
---------------------
Cypher-controller variant of SetFeedbackLoop.

Parameters
~~~~~~~~~~
whichLoop: variable
	Loop index

startWhen: variable
	Start condition code

maintainWhat: variable
	Signal index to regulate

setpoint: variable
	PID setpoint

pgain: variable
	Proportional gain

igain: variable
	Integral gain

sgain: variable
	Sum gain

changeWhat: variable
	Output signal index

dgain: variable
	Derivative gain

SetFeedbackLoopCypher_old
-------------------------
Legacy Cypher-controller variant of SetFeedbackLoop.

Parameters
~~~~~~~~~~
whichLoop: variable
	Loop index

startWhen: variable
	Start condition code

maintainWhat: variable
	Signal index to regulate

setpoint: variable
	PID setpoint

pgain: variable
	Proportional gain

igain: variable
	Integral gain

sgain: variable
	Sum gain

changeWhat: variable
	Output signal index

dgain: variable
	Derivative gain

StopFeedbackLoop
----------------
Disables the specified ARC PID loop and zeros its output.

Parameters
~~~~~~~~~~
whichLoop: variable
	Loop index to stop

StopFeedbackLoopCypher
----------------------
Cypher-controller variant of StopFeedbackLoop.

Parameters
~~~~~~~~~~
whichLoop: variable
	Loop index to stop

StartFeedbackLoop
-----------------
Re-enables a previously stopped ARC PID loop without changing its parameters.

Parameters
~~~~~~~~~~
whichLoop: variable
	Loop index to start

ReadPosition
------------
Reads the current XYZ stage position from LVDT sensors and stores the result
in root:Packages:trEFM globals gxpos and gypos.

MoveXYZ
-------
Moves the stage to the specified XYZ coordinates.

Parameters
~~~~~~~~~~
Xposition: variable
	Target X position in microns

Yposition: variable
	Target Y position in microns

Zposition: variable
	Target Z position in nanometers

ReadZ
-----
Reads the current Z-height from the LVDT sensor.

MoveXY
------
Moves the stage to the specified XY coordinates.

Parameters
~~~~~~~~~~
xpos: variable
	Target X position in microns

ypos: variable
	Target Y position in microns

CheckInWaveTiming
-----------------
Verifies that the timing of an input wave matches the expected digitizer
sample interval.

Parameters
~~~~~~~~~~
whichWave: wave
	Wave whose timing to check

whichDataPoint: variable *(optional)*
	Specific data point index to inspect

LightOnOff
----------
Turns the illumination source on or off.

Parameters
~~~~~~~~~~
onoff: variable
	1 to turn light on, 0 to turn off

LiftTo
------
Lifts the tip to the specified height and applies a tip voltage.

Parameters
~~~~~~~~~~
liftHeight: variable
	Target lift height in nanometers

tipVoltage: variable
	Voltage to apply to the tip in volts

lighton: variable *(optional)*
	1 to enable illumination during lift, 0 to disable

verbose: variable *(optional)*
	1 to print status messages
