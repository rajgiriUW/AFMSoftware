ImageScan_FFtrEFM.ipf
=====================

FFtrEFM image scan mode. Acquires a full force-map style image while
running the digitizer in triggered mode and fitting each pixel using the
FFtrEFM algorithm.

ImageScanFFtrEFM
----------------
FFtrEFM image scan. Prompts whether to save raw frequency data, then
rasters over the sample surface acquiring digitizer traces at each pixel
for subsequent FFtrEFM fitting.

Parameters
~~~~~~~~~~
xpos: variable
	X position in microns

ypos: variable
	Y position in microns

liftheight: variable
	Lift height in nanometers

scansizeX: variable
	Scan size in X in microns

scansizeY: variable
	Scan size in Y in microns

scanlines: variable
	Number of scan lines

scanpoints: variable
	Number of scan points per line

scanspeed: variable
	Scan speed in microns per second

xoryscan: variable
	0 = X-fast scan, 1 = Y-fast scan

fitstarttime: variable
	Start time for FFtrEFM fit window in seconds

fitstoptime: variable
	Stop time for FFtrEFM fit window in seconds

DigitizerAverages: variable
	Number of digitizer averages per pixel

DigitizerSamples: variable
	Number of digitizer samples per trigger

DigitizerPretrigger: variable
	Number of pretrigger samples
