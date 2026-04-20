KeithleySMU.ipf
===============

GPIB control functions for the Keithley source-measure unit (SMU). The
Keithley must be in SCPI mode. By default all functions use GPIB board 1;
pass ``gpib_channel=0`` if the Keithley shares the AFM GPIB bus.

SMUCheck
--------
Verifies communication with the Keithley SMU.

Parameters
~~~~~~~~~~
gpib_Channel: variable *(optional)*
	GPIB board number; defaults to 1

SMUOpen
-------
Opens the VISA session to the Keithley SMU.

Parameters
~~~~~~~~~~
gpib_Channel: variable *(optional)*
	GPIB board number; defaults to 1

gpib_address: variable *(optional)*
	GPIB device address

SMUMode
-------
Sets the SMU operating mode (voltage source or current source).

Parameters
~~~~~~~~~~
mode: variable *(optional)*
	0 = voltage source, 1 = current source

gpib_Channel: variable *(optional)*
	GPIB board number

gpib_address: variable *(optional)*
	GPIB device address

SMUOECTSetup
------------
Configures the SMU for OECT (organic electrochemical transistor) measurements.

Parameters
~~~~~~~~~~
gpib_Channel: variable *(optional)*
	GPIB board number

voltage: variable *(optional)*
	Gate voltage in volts

currentcomp: variable *(optional)*
	Current compliance in amperes

gpib_address: variable *(optional)*
	GPIB device address

SMUClear
--------
Sends a device-clear command to the Keithley.

Parameters
~~~~~~~~~~
gpib_Channel: variable *(optional)*
	GPIB board number

gpib_address: variable *(optional)*
	GPIB device address

SMURead
-------
Reads the current measurement from the Keithley.

Parameters
~~~~~~~~~~
gpib_Channel: variable *(optional)*
	GPIB board number

gpib_address: variable *(optional)*
	GPIB device address

Return
~~~~~~
current
	Measured current in amperes

SMUIV
-----
Sweeps drain voltage and records drain current vs. gate voltage (I-V curve).

Parameters
~~~~~~~~~~
voltstart: variable
	Starting drain voltage in volts

voltstop: variable
	Ending drain voltage in volts

Vds: variable
	Fixed drain-source bias during gate sweep

steps: variable
	Number of voltage steps

delay: variable *(optional)*
	Settling delay in seconds between steps

gpib_address: variable *(optional)*
	GPIB device address

SMUJV
-----
Sweeps a single voltage rail and records the resulting J-V curve.

Parameters
~~~~~~~~~~
voltstart: variable
	Starting voltage in volts

voltstop: variable
	Ending voltage in volts

steps: variable
	Number of voltage steps

delay: variable *(optional)*
	Settling delay in seconds between steps

currentcomp: variable *(optional)*
	Current compliance in amperes

gpib_address: variable *(optional)*
	GPIB device address

SMUVolt
-------
Sets the SMU output to a specified DC voltage.

Parameters
~~~~~~~~~~
voltage: variable
	Output voltage in volts

currentcomp: variable *(optional)*
	Current compliance in amperes

SMUOff
------
Turns off the SMU output.
