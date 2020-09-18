UserAnalysis.ipf
================

MakeImage
---------
Will recreate trEFM chargingrate, frequencyshift, and Chi2 images using .ibw data stored in a folder. You can choose where to start and stop the fits by entering the times you want in units of milliseconds (i.e. 8.12 to 12 ms).
Fitstart

Parameters
~~~~~~~~~~
Fitstart: variable
	description

Fitstop: variable
	description

numavgs: variable
	description

scanpoints: variable
	description

scanlines: variable
	description

aver
----
Will average the raw frequency shifts of a single pixel and then display the averaged frequency shift trace that was used to make a data point in the image. This is useful for understanding why a pixel in the image is noisy/bad.

Parameters
~~~~~~~~~~
pixel: variable
	description

nmavgs: variable
	description

scanpoints: variable
	description