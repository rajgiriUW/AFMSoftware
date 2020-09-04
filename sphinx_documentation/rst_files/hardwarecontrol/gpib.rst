GPIB.ipf
========

SetEFMvf
--------
function description

Parameters
~~~~~~~~~~
voltage: variable
	description

frequency: variable
	description

sleeptime: variable *(optional)*
	description

InitBoardAndDeviceLIAAWG
------------------------
function description

FindListeners
-------------
function description

Return
~~~~~~
V_ibcnt
	description

GPIBsetup
---------
This function is very simple, it causes the board to be the CIC and sends all devices a clearI/O command. It should be safe and prudent to call this everytime you want to run a GPIB function

GetAsciiCode
------------
function description

Parameters
~~~~~~~~~~
DeviceAddress: variable
	description

talkOrListen: string
	description

Return
~~~~~~
string
	description

WriteGPIB
---------
This function is a wrapper for GPIBWrite2. it is used to encapsulate all the preliminary setup and clear messages as well as setting the ascii codes for the requested device

Parameters
~~~~~~~~~~
whichDeviceAddress: variable
	description

cmdString: string
	description

ReadGPIB
--------
This function is a wrapper for GPIBWrite2. it is used to encapsulate all the preliminary setup and clear messages as well as setting the ascii codes for the requested device the function reads in the first 4 responses and returns the response requested

Parameters
~~~~~~~~~~
whichDeviceAddress: variable
	description

numResponses: variable
	description

whichResponse: variable
	description

Return
~~~~~~
responseString[whichResponse-1]
	description

GetFreq
-------
Function that retrives the frequency of the Lockin

Parameters
~~~~~~~~~~
whichDevice: string
	description

Return
~~~~~~
frequency
	description

GetVolt
-------
function description

Parameters
~~~~~~~~~~
whichDevice: string
	description

Returns
~~~~~~~
voltage
	description

SetVF
-----
function description

Parameters
~~~~~~~~~~
voltage: variable

frequency: variable

whichDevice: string

SetVFSqu
--------
function description

Parameters
~~~~~~~~~~
voltage: variable
	description

frequency: variable
	description

whichDevice: string
	description

SetVFSquBis
-----------
function description

Parameters
~~~~~~~~~~
voltage: variable
	description

frequency: variable
	description

whichDevice: string
	description

setVFsin
--------
function description

Parameters
~~~~~~~~~~
voltage: variable
	description

frequency: variable
	description

GetLockInXYRO_1to4
------------------
This function retrives the X, Y, R or Theta value from the lockin depending on i respectively (1-4)

Parameters
~~~~~~~~~~
i: variable
	description

Return
~~~~~~
value
	description

EmptyReads
----------
This function retrives the X, Y, R or Theta value from the lockin depending on i respectively (1-4)

Return
~~~~~~
value
	description

setChanneliOutputtoj
--------------------
This function makes sure the channel one output is outputting the X value (not the display)

Parameters
~~~~~~~~~~
i: variable
	description

j: variable
	description

setChanneliDisplayj
-------------------
This function tells the channel what to output to the LED display

Parameters
~~~~~~~~~~
i: variable
	description

j: variable
	description

setAutoPhase
------------
This function tells the lock-in to autophase

setReserve
----------
This function sets the lockin reserve 0 is  high, 1 is normal, 2 is low

Parameters
~~~~~~~~~~
number: variable
	description

setLPslope
----------
This function sets the lockin low pass filter slope.
0 is 6db , 1 is 12db, 2 is 18 db, 3 is 24 db

Parameters
~~~~~~~~~~
number: variable
	description

setSync
-------
This function sets the lockin to have either the sync state or not.
0 is off, 1 is on

Parameters
~~~~~~~~~~
number: variable
	description

setFloat0orGround1
------------------
This function tells whether the input on the Lockin should be either floating or set to ground

Parameters
~~~~~~~~~~
number: variable
	description

setNotch
--------
This function set the Lockin notch filters.
0 sets no filter, 1 sets it at 60hz, 2 sets the 120hz, and 3 sets both

Parameters
~~~~~~~~~~
number: variable
	description

sendLockinString
----------------
Sends the Lock in a command

Parameters
~~~~~~~~~~
writtenstring: string
	description

sendlockinQuery
---------------
sends the lockin a command and returns a variable reponse

Parameters
~~~~~~~~~~
writtenstring: string

Return
~~~~~~
response
	description

setLockinPhase
--------------
This function tells the lock-in to go to a specific phase

Parameters
~~~~~~~~~~
phase: variable

setLockinSensitivity
--------------------
This function sets the lock-in sensitivity

Parameters
~~~~~~~~~~
sens: variable
	description

SetLockinFreq
-------------
Function that sets the frequency of the Lockin

Parameters
~~~~~~~~~~
frequency: variable
	description

SetLockinAgain
--------------
Function that tells the Lockin to Auto Gain itself

GetLockinTimeC
--------------
Function that retrieves the TimeC of the lock_in

Return
~~~~~~
TimeConstant
	description

LockinRecall
------------
Function that sets the TimeConstant of the lock-in

Parameters
~~~~~~~~~~
recall_val: variable
	description

SetLockinTimeC
--------------
Function that sets the TimeConstant of the lock-in

Parameters
~~~~~~~~~~
timeC: variable
	description

GetLockinSens
-------------
Function that retrieves the sens of the lock_in

Return
~~~~~~
Sensitivity
	description

setupWFarbitrary
----------------
function description

Parameters
~~~~~~~~~~
Voltage: variable
	description

Fdifference: variable
	description

Fsum: variable
	description

WFarbitrary
-----------
function description

Parameters
~~~~~~~~~~
Voltage: variable
	description

Fdifference: variable
	description

Fsum: variable
	description

LoadWF
------
arbitrary waveform loader

Parameters
~~~~~~~~~~
whichWave: wave
	description

findVISAAddress
---------------
simple function to find all relevant VISA addresses for a given instrument

Parameters
~~~~~~~~~~
source: string *(optional)*
	description

psSetting
---------
function description

Parameters
~~~~~~~~~~
voltage: variable
	description

current: variable *(optional)*
	description

psOff
-----
function description

psOn
----
function description

psRst
-----
functions description