# Compose les captures de la fiche Microsoft Store (1366 x 768) : la fenêtre d'AppToggle à taille réelle,
# un titre et une phrase d'accroche sur un fond aux couleurs du logo.
# Entrée : captures brutes (store-<langue>-<nom>.png) dans le dossier -Source.
# Sortie : docs\store\<langue>-<n>-<nom>.png
param([Parameter(Mandatory)][string]$Source)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$outDir = Join-Path (Split-Path $PSScriptRoot) 'docs\store'
New-Item -ItemType Directory -Force $outDir | Out-Null

$texts = @{
    fr = [ordered]@{
        'main-dark'  = @('Une touche. Ton appli.', "Ouvre, ramène ou réduis n'importe quelle appli avec une seule touche, touche Copilot comprise.")
        'picker'     = @('Aucun chemin à taper', "Ouvre ton appli, puis choisis-la dans la liste : AppToggle s'occupe du reste.")
        'capture'    = @('Ta touche, en un appui', 'Appuie sur ta combinaison, la touche Copilot est reconnue. Chaque raccourci a son interrupteur.')
        'main-light' = @('Léger et discret', 'Moins de 2 Mo de mémoire, aucune connexion Internet. Suit le thème clair ou sombre de Windows.')
    }
    en = [ordered]@{
        'main-dark'  = @('One key. Your app.', 'Open, bring back or minimize any app with a single key, including the Copilot key.')
        'picker'     = @('No paths to type', 'Open your app, then pick it from the list: AppToggle does the rest.')
        'capture'    = @('Set your key in one press', 'Just press your combination, the Copilot key works too. Every shortcut has its own switch.')
        'main-light' = @('Light and discreet', 'Less than 2 MB of memory, no internet connection. Follows the Windows light or dark theme.')
    }
}

function New-RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = 2 * $r
    $p.AddArc($x, $y, $d, $d, 180, 90); $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90); $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure(); return $p
}

$W = 1366; $H = 768
$logo = [System.Drawing.Image]::FromFile((Join-Path (Split-Path $PSScriptRoot) 'assets\logo.png'))
foreach ($lang in $texts.Keys) {
    $i = 0
    foreach ($name in $texts[$lang].Keys) {
        $i++
        $shot = [System.Drawing.Image]::FromFile((Join-Path $Source "store-$lang-$name.png"))
        $bmp = New-Object System.Drawing.Bitmap $W, $H
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAliasGridFit'; $g.InterpolationMode = 'HighQualityBicubic'

        $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush ([System.Drawing.Rectangle]::new(0, 0, $W, $H)),
            ([System.Drawing.Color]::FromArgb(255, 0x10, 0x1B, 0x3D)), ([System.Drawing.Color]::FromArgb(255, 0x2C, 0x16, 0x52)), 35.0
        $g.FillRectangle($bg, 0, 0, $W, $H)

        # fenêtre à droite, à taille réelle, avec une ombre douce
        $sx = $W - 70 - $shot.Width; $sy = [int](($H - $shot.Height) / 2)
        for ($k = 12; $k -ge 1; $k--) {
            $shadow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(7, 0, 0, 0))
            $path = New-RoundedPath ($sx - $k) ($sy - $k + 10) ($shot.Width + 2 * $k) ($shot.Height + 2 * $k) (8 + $k)
            $g.FillPath($shadow, $path); $shadow.Dispose(); $path.Dispose()
        }
        $g.DrawImage($shot, $sx, $sy, $shot.Width, $shot.Height)

        # colonne de texte à gauche
        $left = 70; $colW = $sx - $left - 60
        $g.DrawImage($logo, $left, 170, 56, 56)
        $fName = New-Object System.Drawing.Font 'Segoe UI Variable Display', 26, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
        $g.DrawString('AppToggle', $fName, [System.Drawing.Brushes]::White, $left + 70, 180)
        $fTitle = New-Object System.Drawing.Font 'Segoe UI Variable Display', 46, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
        $g.DrawString($texts[$lang][$name][0], $fTitle, [System.Drawing.Brushes]::White, ([System.Drawing.RectangleF]::new($left, 270, $colW, 130)))
        $fSub = New-Object System.Drawing.Font 'Segoe UI Variable Text', 22, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
        $subBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 0xC9, 0xD1, 0xE6))
        $titleH = $g.MeasureString($texts[$lang][$name][0], $fTitle, $colW).Height
        $g.DrawString($texts[$lang][$name][1], $fSub, $subBrush, ([System.Drawing.RectangleF]::new($left, 270 + $titleH + 18, $colW, 200)))

        $out = Join-Path $outDir ("{0}-{1}-{2}.png" -f $lang, $i, $name)
        $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
        foreach ($o in $fName, $fTitle, $fSub, $subBrush, $bg, $g, $bmp, $shot) { $o.Dispose() }
        "  $out"
    }
}
$logo.Dispose()
