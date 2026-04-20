Add-Type -AssemblyName System.Drawing

$width  = 1400
$height = 720
$bmp = New-Object System.Drawing.Bitmap($width, $height)
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode      = 'AntiAlias'
$g.TextRenderingHint  = 'ClearTypeGridFit'

# ── Palette ──────────────────────────────────────────────────────────────
$bgColor    = [System.Drawing.Color]::FromArgb(245,247,250)
$entryColor = [System.Drawing.Color]::FromArgb(70,130,180)
$logicColor = [System.Drawing.Color]::FromArgb(46,139,87)
$scanColor  = [System.Drawing.Color]::FromArgb(100,149,237)
$instrColor = [System.Drawing.Color]::FromArgb(205,133,63)
$pyColor    = [System.Drawing.Color]::FromArgb(255,160,50)
$imskpmColor= [System.Drawing.Color]::FromArgb(147,112,219)
$hetColor   = [System.Drawing.Color]::FromArgb(95,158,160)
$legColor   = [System.Drawing.Color]::FromArgb(160,160,160)
$miscColor  = [System.Drawing.Color]::FromArgb(210,105,30)
$hdrColor   = [System.Drawing.Color]::FromArgb(30,30,50)
$white      = [System.Drawing.Color]::White
$dark       = [System.Drawing.Color]::FromArgb(30,30,30)

$g.Clear($bgColor)

# ── Fonts ────────────────────────────────────────────────────────────────
$titleFont   = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$secFont     = New-Object System.Drawing.Font('Segoe UI',  8, [System.Drawing.FontStyle]::Bold)
$fileFont    = New-Object System.Drawing.Font('Consolas',  7, [System.Drawing.FontStyle]::Regular)
$labelFont   = New-Object System.Drawing.Font('Segoe UI',  7, [System.Drawing.FontStyle]::Italic)
$noteFont    = New-Object System.Drawing.Font('Segoe UI',  8, [System.Drawing.FontStyle]::Regular)
$monoMed     = New-Object System.Drawing.Font('Consolas',  9, [System.Drawing.FontStyle]::Bold)
$monoSm      = New-Object System.Drawing.Font('Consolas',  8, [System.Drawing.FontStyle]::Regular)

$wBrush  = New-Object System.Drawing.SolidBrush($white)
$dkBrush = New-Object System.Drawing.SolidBrush($dark)
$hBrush  = New-Object System.Drawing.SolidBrush($hdrColor)
$sfC     = New-Object System.Drawing.StringFormat; $sfC.Alignment = 'Center'

# ── Helper: draw a labelled box with file list ────────────────────────────
function DrawBox([System.Drawing.Graphics]$g, $x,$y,$w,$h, $color, $title, $files) {
    $fill  = New-Object System.Drawing.SolidBrush($color)
    $light = [System.Drawing.Color]::FromArgb(230,
                [int]([math]::Min(255,$color.R+60)),
                [int]([math]::Min(255,$color.G+60)),
                [int]([math]::Min(255,$color.B+60)))
    $bg    = New-Object System.Drawing.SolidBrush($light)
    $pen   = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60,60,80), 1.5)

    $g.FillRectangle($bg,   $x,    $y+22, $w,    $h-22)
    $g.FillRectangle($fill, $x,    $y,    $w,    22)
    $g.DrawRectangle($pen,  $x,    $y,    $w,    $h)

    $g.DrawString($title, $secFont, $wBrush,
        [System.Drawing.RectangleF]::new($x,$y+4,$w,18), $sfC)

    $fy = $y + 26
    foreach ($f in $files) {
        $g.DrawString($f, $fileFont, $dkBrush, ($x+6), $fy)
        $fy += 13
    }
}

# ── Title ─────────────────────────────────────────────────────────────────
$g.DrawString('igor_code_mfp_branch  --  Package Layout  (*.ipf files)', $titleFont, $hBrush, 18, 12)

# ── Col 1  x=18 ──────────────────────────────────────────────────────────
$c1 = 18

# Entry point box
$eFill = New-Object System.Drawing.SolidBrush($entryColor)
$ePen  = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40,80,140), 2)
$g.FillRectangle($eFill, $c1, 48, 250, 22)
$eLightBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(210,225,245))
$g.FillRectangle($eLightBrush, $c1, 70, 250, 62)
$g.DrawRectangle($ePen, $c1, 48, 250, 84)
$g.DrawString('ENTRY POINT', $secFont, $wBrush, [System.Drawing.RectangleF]::new($c1,51,250,18), $sfC)
$g.DrawString('trEFMPanel.ipf', $monoMed, $dkBrush, [System.Drawing.RectangleF]::new($c1,73,250,18), $sfC)
$g.DrawString('opens via  trEFMImagingPanel()', $labelFont, $dkBrush, [System.Drawing.RectangleF]::new($c1,91,250,16), $sfC)
$g.DrawString('calls trEFMInit()  on launch', $labelFont, $dkBrush, [System.Drawing.RectangleF]::new($c1,105,250,16), $sfC)

# Arrow
$arrPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(80,80,110), 2)
$ax = $c1 + 125
$g.DrawLine($arrPen, $ax, 132, $ax, 148)
$g.DrawLine($arrPen, $ax-6, 142, $ax, 149); $g.DrawLine($arrPen, $ax+6, 142, $ax, 149)

# Core Logic
DrawBox $g $c1 149 250 68 $logicColor 'CORE LOGIC' @(
    'trEFMInit.ipf     (initialization + logic backbone)',
    'Common.ipf        (shared utilities)',
    'WaveGenerator.ipf (waveform construction)',
    'DriveWaveEditor.ipf'
)

# Scanning modules
DrawBox $g $c1 230 250 168 $scanColor 'SCANNING MODULES' @(
    'PointScan.ipf',
    'ImageScan.ipf',
    'ImageScan_FFtrEFM.ipf',
    'VoltageScan.ipf',
    'GModeImaging.ipf',
    'GmodePointScan.ipf',
    'PL.ipf',
    'PL_interleave.ipf',
    'transferfuncpanel.ipf',
    'CalCurve.ipf'
)

# ── Col 2  x=285 ─────────────────────────────────────────────────────────
$c2 = 285

DrawBox $g $c2 48 255 100 $scanColor 'CALIBRATION & SKPM' @(
    'ElecCal.ipf',
    'ForceCalibration.ipf',
    'ForceMapSMU.ipf',
    'SKPM.ipf',
    'SKPM_AM.ipf',
    'SKPMGainsPanel.ipf'
)

DrawBox $g $c2 162 255 82 $instrColor 'INSTRUMENT I/O' @(
    'GPIB.ipf',
    'KeithleySMU.ipf',
    'TriggerBoxSerial.ipf',
    'NPLC_Utils.ipf'
)

# Python support -- custom box
$pyFill  = New-Object System.Drawing.SolidBrush($pyColor)
$pyLight = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,230,185))
$pyPen   = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180,100,20), 1.5)
$g.FillRectangle($pyFill,  $c2, 256,    255, 22)
$g.FillRectangle($pyLight, $c2, 278,    255, 118)
$g.DrawRectangle($pyPen,   $c2, 256,    255, 140)
$g.DrawString('PYTHON BRIDGE', $secFont, $wBrush, [System.Drawing.RectangleF]::new($c2,259,255,18), $sfC)
$g.DrawString('PythonSupport.ipf', $monoSm, $dkBrush, ($c2+6), 282)
$g.DrawString('calls via ExecuteScriptText:', $labelFont, $dkBrush, ($c2+6), 296)
$g.DrawString('  misc/analyze_pixel.py', $fileFont, $dkBrush, ($c2+6), 309)
$g.DrawString('  misc/analyze_line.py',  $fileFont, $dkBrush, ($c2+6), 322)
$g.DrawString('  (misc/generatePulse.py - referenced)', $fileFont, $dkBrush, ($c2+6), 335)
$g.DrawString('  (misc/generate_chirp.py - referenced)', $fileFont, $dkBrush, ($c2+6), 348)
$g.DrawString('  (misc/polling.py - referenced)',         $fileFont, $dkBrush, ($c2+6), 361)
$g.DrawString('  (misc/chirp.dat  - data file)',          $fileFont, $dkBrush, ($c2+6), 374)

# ── Col 3  x=558 ─────────────────────────────────────────────────────────
$c3 = 558

DrawBox $g $c3 48 270 104 $imskpmColor 'IMSKPM/  (IM-SKPM variants)' @(
    'IMSKPM_AM.ipf',
    'IMSKPM_FM.ipf',
    'IMSKPM_Panel.ipf',
    'IMSKPM_Panel_Old.ipf',
    'IMSKPM_ForcePanelSpoofMethod.ipf',
    'IMSKPM_oldfunctions.ipf'
)

DrawBox $g $c3 166 270 56 $hetColor 'heterodyne/  (Moku instruments)' @(
    'Moku_Het.ipf',
    'Moku_SKPM.ipf'
)

# ── Col 4  x=846 ─────────────────────────────────────────────────────────
$c4 = 846

DrawBox $g $c4 48 270 156 $legColor 'legacy/  (deprecated)' @(
    'GMode_Triggers.ipf',
    'ImageScanIMSKPM.ipf',
    'NLPC_Panel.ipf',
    'NPLC_Scan.ipf',
    'PLDegrade.ipf',
    'ParabolaImaging.ipf',
    'ReprocesstrEFM.ipf',
    'ShutterControlAndPanel.ipf',
    'laserspotsadvanced.ipf'
)

DrawBox $g $c4 218 270 118 $miscColor 'misc/  (scripts & assets)' @(
    'analyze_pixel.py',
    'analyze_line.py',
    'generatePulse.py',
    'generate_chirp.py',
    'polling.py',
    'GaGeXOP.xop  (XOP extension)',
    'chirp.dat    (data file)'
)

# ── Legend ────────────────────────────────────────────────────────────────
$ly = 450
$g.DrawString('Legend:', $secFont, $hBrush, 18, $ly)
$pairs = @(
    [pscustomobject]@{C=$entryColor;  L='Entry point'},
    [pscustomobject]@{C=$logicColor;  L='Core logic / init'},
    [pscustomobject]@{C=$scanColor;   L='Scanning & calibration'},
    [pscustomobject]@{C=$instrColor;  L='Instrument I/O'},
    [pscustomobject]@{C=$pyColor;     L='Python bridge'},
    [pscustomobject]@{C=$imskpmColor; L='IMSKPM/ (IM-SKPM variants)'},
    [pscustomobject]@{C=$hetColor;    L='heterodyne/ (Moku)'},
    [pscustomobject]@{C=$legColor;    L='legacy/ (deprecated)'},
    [pscustomobject]@{C=$miscColor;   L='misc/ (scripts & assets)'}
)
$lx = 18; $ly2 = $ly + 18
foreach ($p in $pairs) {
    $cb = New-Object System.Drawing.SolidBrush($p.C)
    $g.FillRectangle($cb, $lx, $ly2, 14, 14)
    $g.DrawRectangle([System.Drawing.Pens]::Gray, $lx, $ly2, 14, 14)
    $g.DrawString($p.L, $noteFont, $hBrush, ($lx+18), $ly2)
    $lx += 155
    if ($lx -gt 1380) { $lx = 18; $ly2 += 20 }
}

# ── Save ──────────────────────────────────────────────────────────────────
$out = 'c:\Users\raj\OneDrive\Documents\GitHub\AFMSoftware\igor_code_mfp_branch\misc\package_layout.png'
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
Write-Host "Saved: $out"
