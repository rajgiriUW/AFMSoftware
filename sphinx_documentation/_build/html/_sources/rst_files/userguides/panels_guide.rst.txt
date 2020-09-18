Panel Guide
===========

trEFM Panel
-----------
Main Panel
~~~~~~~~~~
|trefm_main|

A. Move Here
	* MoveXY()

B. Current XY
	* GetCurrentPosition()

C. Grab Offset
	* gv()
	* MoveXY()
	* GetCurrentPosition()

D. 0*!
	* description

E. LED is OFF / LED is ON
	* LightOnOff()

F. Grab Tune
	* SaveHardwareSettings()
	* GrabTune()
	* GetCurrentPosition()

G. Voltage Scan
	* CommitDriveWaves()
	* VoltageScan()
	* GetCurrentPosition()

H. Height Scan
	* CommitDriveWaves()
	* HeightScan()
	* GetCurrentPosition()

I. Edit LED Wave
	* LightWaveEditor()

J. Edit Voltage Wave
	* VoltageWaveEditor()

K. Edit Trigger Wave
	* TriggerWaveEditor()

L. ---> RECOM
	* TrigPol()

trEFM tab
~~~~~~~~~

|trefm_trefm|

A. Point Scan
	* CommitDriveWaves()
	* MultiplePointScan()
	* PointScantrEFM()
	* GetCurrentPosition()

B. Image Scan
	* CommitDriveWaves()
	* ImageScan()
	* GetCurrentPosition()

C. Fit Point Scan
	* description

D. Edit Gains
	* description

E. Save
	* SaveImageScan()

F. Clear
	* ClearImages()

FFtrEFM tab
~~~~~~~~~~~

|trefm_fftrefm|

A. Point Scan
	* CommitDriveWaves()
	* PointScanFFtrEFM()
	* GetCurrentPosition()

B. Image Scan
	* CommitDriveWaves()
	* ImageScan()
	* GetCurrentPosition()

C. Analysis Config
	* description

D. Save
	* SaveImageScan()

E. Clear
	* ClearImages()

G-KPFM tab
~~~~~~~~~~

|trefm_gkpfm|

A. Point Scan
	* CommitDriveWaves()
	* PointScanGMode()
	* GetCurrentPosition()

B. Image Scan
	* CommitDriveWaves()
	* ImageScan()
	* GetCurrentPosition()

C. Analysis Config
	* description

D. Save
	* SaveImageScan()

E. Clear
	* ClearImages()

Ring Down tab
~~~~~~~~~~~~~

|trefm_ringdown|

A. Point Scan
	* CommitDriveWaves()
	* MultiplePointScan()
	* PointScanRingDown()
	* GetCurrentPosition()

B. Image Scan
	* CommitDriveWaves()
	* ImageScan()
	* GetCurrentPosition()

C. Fit Point Scan
	* description

D. Light is On / Light is Off
	* description

E. Save
	* SaveImageScan()

F. Clear
	* ClearImages()

Extra tab
~~~~~~~~~

|trefm_extra|

A. Re-Analyze
	* ReDoAnalysis()

B. Force Calibration
	* GetFreeCantileverParms()
	* GetForceParms()

C. Electrical Calibration
	* GetFreeCantileverParms()
	* GetElecTip()

D. Elec+Noise Calibration (SLOW!)
	* GetFreeCantileverParms()
	* GetElecNoiseTip()

E. Transfer Func with AWG
	* CommitDriveWaves()
	* LoadChirp()
	* PointScanTF()
	* GetCurrentPosition()

F. Calibration Curve with Func Gen
	* CommitDriveWaves()
	* TauScan()
	* GetCurrentPosition()

SKPM Panel
----------

|skpm|

A. Image Scan
	* CommitDriveWaves()
	* ImageScanSKPM()
	* GetCurrentPosition()

B. Regular Point Scan
	* PointScanSKPM()
	* GetCurrentPosition()

C. With Pulsed Bias
	* PointScanSKPMVoltagePulse()
	* GetCurrentPosition()

D. Turn on PS
	* PsON()

E. Turn off PS
	* PsOff()

PL Panel
--------

|pl|

A. Get Cursor Pos
	* hcsr()
	* vcsr()

B. Transfer position
	* TransferPosition()

C. Set AWG
	* GPIBsetup()
	* writeGPIB()

D. Set LIA
	* LockinRecall()

E. Grab Offset from ARC
	* gv()
	* MoveXY()
	* GetCurrentPosition()

F. Move here
	* MoveXY()

G. Get Current XY
	* GetCurrentPosition()

H. Clear Images
	* ClearLBICImages()

I. Image Scan
	* LBICscan()
	* GetCurrentPosition()

J. 0*!
	* description

K. Save Data
	* SaveLBICImageScan()

NLPC Panel
----------

|nlpc|

A. Test Connection
	* testbeep()

B. Move Here
	* MoveXY()

C. Current XY
	* GetCurrentPosition()

D. Grab Offset
	* gv()
	* MoveXY()
	* GetCurrentPosition()

E. Zero Laser
	* zero()

F. Default Settings
	* nplcinit()

G. Start Scanning
	* ImageScanNLPC()

TF Panel
--------

|tf|

A. Pixel-wise Settings
	* PopMenuProcTF()

B. Line-wise Settings
	* PixelParams()

C. Save TF
	* CreateParametersFile()

D. Transfer Func with AWG
	* CommitDriveWaves()
	* LoadChirp()
	* PointScanTF()
	* GetCurrentPosition()

.. |nlpc| image:: panels_images/nlpc_labelled.jpg
	:scale: 50 %

.. |pl| image:: panels_images/pl_labelled.jpg
	:scale: 50 %

.. |skpm| image:: panels_images/skpm_labelled.jpg
	:scale: 50 %

.. |tf| image:: panels_images/tf_labelled.jpg
	:scale: 50 %

.. |trefm_extra| image:: panels_images/trefm_extra_labelled.jpg
	:scale: 50 %

.. |trefm_fftrefm| image:: panels_images/trefm_fftrefm_labelled.jpg
	:scale: 50 %

.. |trefm_gkpfm| image:: panels_images/trefm_gkpfm_labelled.jpg
	:scale: 50 %

.. |trefm_main| image:: panels_images/trefm_main_labelled.jpg
	:scale: 50 %

.. |trefm_ringdown| image:: panels_images/trefm_ringdown_labelled.jpg
	:scale: 50 %

.. |trefm_trefm| image:: panels_images/trefm_trefm_labelled.jpg
	:scale: 50 %







