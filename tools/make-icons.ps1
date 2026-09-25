# Génère les icônes d'AppToggle (assets\icon.ico = actif, assets\icon-off.ico = en pause)
# et assets\logo.png pour le README. À relancer seulement si on change le design.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$assets = Join-Path (Split-Path $PSScriptRoot) 'assets'
New-Item -ItemType Directory -Force $assets | Out-Null

function New-RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = [Math]::Min(2 * $r, [Math]::Min($w, $h))
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

# Un carré arrondi en dégradé avec un interrupteur blanc : pastille à droite = actif, à gauche = en pause.
# Les petites tailles sont calées sur des pixels entiers pour rester nettes dans la barre des tâches.
function New-IconBitmap([int]$S, [bool]$on) {
    $bmp = New-Object System.Drawing.Bitmap $S, $S, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.PixelOffsetMode = 'HighQuality'
    $g.Clear([System.Drawing.Color]::Transparent)

    $m = if ($S -ge 256) { 12 } elseif ($S -ge 64) { 3 } elseif ($S -ge 48) { 2 } else { 0 }
    $side = $S - 2 * $m
    $bgPath = New-RoundedPath $m $m $side $side ([Math]::Round(0.22 * $side))
    if ($on) {
        $c1 = [System.Drawing.Color]::FromArgb(255, 0x3B, 0x82, 0xF6)
        $c2 = [System.Drawing.Color]::FromArgb(255, 0x8B, 0x5C, 0xF6)
        $thumb = [System.Drawing.Color]::FromArgb(255, 0x63, 0x6F, 0xF6)
    } else {
        $c1 = [System.Drawing.Color]::FromArgb(255, 0x8E, 0x8E, 0x93)
        $c2 = [System.Drawing.Color]::FromArgb(255, 0x5A, 0x5A, 0x5F)
        $thumb = [System.Drawing.Color]::FromArgb(255, 0x76, 0x76, 0x7B)
    }
    $rect = New-Object System.Drawing.RectangleF $m, $m, $side, $side
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $c1, $c2, 45.0
    $g.FillPath($grad, $bgPath)

    $pw = [int][Math]::Round(0.625 * $S); if (($S - $pw) % 2) { $pw-- }
    $ph = [int][Math]::Round(0.375 * $S); if (($S - $ph) % 2) { $ph-- }
    $px = ($S - $pw) / 2; $py = ($S - $ph) / 2
    $pill = New-RoundedPath $px $py $pw $ph ($ph / 2)
    $g.FillPath([System.Drawing.Brushes]::White, $pill)

    $inset = [Math]::Max(1, [Math]::Round($ph * 0.16))
    $d = $ph - 2 * $inset
    $tx = if ($on) { $px + $pw - $inset - $d } else { $px + $inset }
    $tb = New-Object System.Drawing.SolidBrush $thumb
    $g.FillEllipse($tb, [float]$tx, [float]($py + $inset), [float]$d, [float]$d)

    $g.Dispose()
    return $bmp
}

function ConvertTo-Png([System.Drawing.Bitmap]$bmp) {
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    return , $ms.ToArray()
}

# Format BMP d'icône classique (en-tête 40 octets, pixels BGRA de bas en haut, masque 1 bit) :
# le plus compatible pour les petites tailles.
function ConvertTo-IconDib([System.Drawing.Bitmap]$bmp) {
    $S = $bmp.Width
    $data = $bmp.LockBits([System.Drawing.Rectangle]::new(0, 0, $S, $S), 'ReadOnly', ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb))
    $px = New-Object byte[] ($S * $S * 4)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $px, 0, $px.Length)
    $bmp.UnlockBits($data)
    $maskRow = [int]([Math]::Floor(($S + 31) / 32) * 4)
    $ms = New-Object System.IO.MemoryStream
    $w = New-Object System.IO.BinaryWriter $ms
    $w.Write([uint32]40); $w.Write([int32]$S); $w.Write([int32](2 * $S))
    $w.Write([uint16]1); $w.Write([uint16]32); $w.Write([uint32]0)
    $w.Write([uint32]($S * $S * 4 + $maskRow * $S))
    $w.Write([int32]0); $w.Write([int32]0); $w.Write([uint32]0); $w.Write([uint32]0)
    for ($y = $S - 1; $y -ge 0; $y--) { $w.Write($px, $y * $S * 4, $S * 4) }
    for ($y = $S - 1; $y -ge 0; $y--) {
        $row = New-Object byte[] $maskRow
        for ($x = 0; $x -lt $S; $x++) {
            if ($px[($y * $S + $x) * 4 + 3] -eq 0) { $row[[Math]::Floor($x / 8)] = $row[[Math]::Floor($x / 8)] -bor (0x80 -shr ($x % 8)) }
        }
        $w.Write($row)
    }
    $w.Flush()
    return , $ms.ToArray()
}

# Fichier .ico = en-tête + répertoire + images (BMP jusqu'à 64 px, PNG pour 256 px)
function Write-Ico([string]$path, [bool]$on) {
    $sizes = 16, 20, 24, 32, 40, 48, 64, 256
    $images = foreach ($s in $sizes) {
        $bmp = New-IconBitmap $s $on
        if ($s -ge 256) { , (ConvertTo-Png $bmp) } else { , (ConvertTo-IconDib $bmp) }
        $bmp.Dispose()
    }
    $fs = [System.IO.File]::Create($path)
    $w = New-Object System.IO.BinaryWriter $fs
    $w.Write([uint16]0); $w.Write([uint16]1); $w.Write([uint16]$sizes.Count)
    $offset = 6 + 16 * $sizes.Count
    for ($i = 0; $i -lt $sizes.Count; $i++) {
        $s = $sizes[$i]; $len = $images[$i].Length
        $w.Write([byte]($(if ($s -ge 256) { 0 } else { $s })))
        $w.Write([byte]($(if ($s -ge 256) { 0 } else { $s })))
        $w.Write([byte]0); $w.Write([byte]0)
        $w.Write([uint16]1); $w.Write([uint16]32)
        $w.Write([uint32]$len); $w.Write([uint32]$offset)
        $offset += $len
    }
    foreach ($img in $images) { $w.Write($img) }
    $w.Close()
}

Write-Ico (Join-Path $assets 'icon.ico') $true
Write-Ico (Join-Path $assets 'icon-off.ico') $false
$logo = New-IconBitmap 256 $true
[System.IO.File]::WriteAllBytes((Join-Path $assets 'logo.png'), (ConvertTo-Png $logo))
$logo.Dispose()
"Icônes générées dans $assets"
