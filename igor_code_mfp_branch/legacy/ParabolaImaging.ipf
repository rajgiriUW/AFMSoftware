#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// ParabolaImaging.ipf
//
// Spatial image scan that measures the parabolic frequency-shift vs. voltage curve
// at each pixel across a sample surface.
//
// Physical basis:
//   In electrical AFM (EFM/KPFM), the cantilever frequency shift depends on the
//   electrostatic force gradient between tip and sample. For a tip held at voltage
//   V_tip above a sample with contact potential difference (CPD) V_CPD, the
//   frequency shift varies as:
//
//       delta_f(V) = (1/4k) * (d²C/dz²) * (V_tip - V_CPD)²
//
//   where k is the cantilever spring constant and d²C/dz² is the second derivative
//   of the tip-sample capacitance with respect to tip-sample separation. This
//   parabolic dependence means the minimum of the delta_f vs. V curve occurs at
//   V_tip = V_CPD, directly yielding the local CPD (i.e. the surface potential).
//
//   parabolaimaging() rasters the tip across a grid of XY positions. At each pixel
//   it acquires a full voltage sweep (via VoltageScanButton) and saves the resulting
//   phase wave as Parabola_i_j.ibw. Post-processing can then fit each pixel's curve
//   to extract the CPD and the curvature (proportional to d²C/dz²) as spatial maps.
//
// Reference:
//   Silveira, W. R.; Muller, E. M.; Ng, T. N.; Dunlap, D. H.; Marohn, J. A.
//   High-Sensitivity Electric Force Microscopy of Organic Electronic Materials and Devices.
//   In Scanning Probe Microscopy: Electrical and Electromechanical Phenomena at the Nanoscale;
//   Kalinin, S. V., Gruverman, A., Eds.; Springer: New York, 2007; pp 788-832.
//
// Author: Raj Giridharagopal, Dept. of Chemistry, University of Washington
// Contact: rgiri@uw.edu

function parabolaimaging()

	NVAR xpos = root:packages:trEFM:gxpos
	NVAR ypos = root:packages:trEFM:gypos
	NVAR scanpoints = root:packages:trEFM:ImageScan:scanpoints
	NVAR scanlines = root:packages:trEFM:ImageScan:scanlines
	NVAR width = root:packages:trEFM:ImageScan:scansizex
	NVAR height = root:packages:trEFM:ImageScan:scansizey

	SetDataFolder root:packages:trEFM:VoltageScan

	variable i = 0
	variable j = 0

	variable xsteps = width / scanpoints
	variable ysteps = height / scanlines

	make/O/N=(scanpoints) xstepswave = 0
	make/O/N=(scanpoints) ystepswave = 0
	setscale/i x, (xpos-width)/2, (xpos+width)/2, xstepswave
	xstepswave = x
	setscale/I x, (ypos-height)/2, (ypos+height)/2, ystepswave
	ystepswave = x

	Newpath/O path

	Wave phasewave = root:packages:trEFM:VoltageScan:phasewave
	Wave voltagewave = root:packages:trEFM:VoltageScan:voltagewave

	Save/C/O/P=path voltagewave as "Voltage_Wave.ibw"
	string name = "Parabola_0_0"

	do
		i = 0
		do
			xpos = xstepswave[i]
			ypos = ystepswave[j]
			DoUpdate
			MoveHereButton("")
			Sleep/S 1
			VoltageScanButton("")

			name = "Parabola_" + num2str(i) + "_" + num2str(j) + ".ibw"
			Save/C/O/P=path phasewave as name

			i += 1
		while (i < scanpoints)

		j += 1
	while ( j < scanlines)

end
