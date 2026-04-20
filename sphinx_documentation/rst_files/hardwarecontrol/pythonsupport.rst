PythonSupport.ipf
=================

Bridge functions for calling external Python (ffta) analysis code from
Igor Pro. Saves the current wave and parameter wave to disk as .ibw files,
then shells out to the Python script and reloads the result.

PyPS
----
Runs the Python point-scan analysis script on the specified wave.

Parameters
~~~~~~~~~~
ibw_wave: wave
	Input data wave to analyse

parameters: wave
	Parameter wave passed to the Python script

PyPS_cypher
-----------
Cypher-controller variant of PyPS. Handles the Cypher data folder layout
when locating and saving the input wave.

Parameters
~~~~~~~~~~
ibw_wave: wave
	Input data wave to analyse

parameters: wave
	Parameter wave passed to the Python script

PyPS_cypher_image
-----------------
Cypher-controller variant for image-scan reanalysis. Iterates over all
pixels in the named folder and calls the Python analysis on each.

Parameters
~~~~~~~~~~
folder: string
	Igor data folder containing the image waves

ibw_name: string
	Base wave name used for each pixel

parameters: wave
	Parameter wave passed to the Python script

PyPS_image
----------
MFP3D variant for image-scan reanalysis. Iterates over all pixels in the
named folder and calls the Python analysis on each.

Parameters
~~~~~~~~~~
folder: string
	Igor data folder containing the image waves

ibw_name: string
	Base wave name used for each pixel

parameters: wave
	Parameter wave passed to the Python script
