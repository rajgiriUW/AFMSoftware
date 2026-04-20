ForceMapSMU.ipf
===============

Analysis helpers for correlating force-map data with simultaneous SMU current
measurements. These functions post-process saved force-map waves and do not
drive acquisition directly.

.. note::
   These functions are not used for active acquisition. The recommended
   workflow is: call ``SMUOECTSetup(voltage=<value>)`` before starting the
   Force Map, add a channel using ``ForceCalcRaj`` as the function, then
   use ``MapvsCurrent`` for post-processing.

MapvsCurrent
------------
Correlates a force-map layer with simultaneously recorded SMU currents.

Parameters
~~~~~~~~~~
inw: wave
	Force-map wave

layer: variable
	Force-map layer index containing the modulus data

moduli: wave
	Output wave to append modulus values

currents: wave
	Output wave to append current values

FMapSMU2
--------
Runs a force-map acquisition with simultaneous SMU current recording
(second variant).

Parameters
~~~~~~~~~~
voltage: variable
	Gate voltage applied by the SMU in volts

FMapSMU
-------
Runs a force-map acquisition with simultaneous SMU current recording.

Parameters
~~~~~~~~~~
voltage: variable
	Gate voltage applied by the SMU in volts
