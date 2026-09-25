# Compile AppToggle : src\AppToggle.ahk -> dist\AppToggle.exe (+ un zip prêt à partager et son empreinte SHA-256)
# Lancement : clic droit > « Exécuter avec PowerShell »
#        ou : powershell -ExecutionPolicy Bypass -File build.ps1
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$src = Join-Path $root 'src\AppToggle.ahk'
$dist = Join-Path $root 'dist'
$exe = Join-Path $dist 'AppToggle.exe'

# 1. AutoHotkey v2 : son interpréteur sert de base à l'exe
$ahkDir = (Get-ItemProperty 'HKLM:\SOFTWARE\AutoHotkey' -ErrorAction SilentlyContinue).InstallDir
if (-not $ahkDir) { $ahkDir = Join-Path $env:ProgramFiles 'AutoHotkey' }
$base = Join-Path $ahkDir 'v2\AutoHotkey64.exe'
if (-not (Test-Path $base)) { throw "AutoHotkey v2 est introuvable. Installe-le depuis https://www.autohotkey.com puis relance." }

# 2. Le compilateur Ahk2Exe (outil officiel), téléchargé une seule fois dans tools\Ahk2Exe, sans droits admin
$ahk2exe = Join-Path $root 'tools\Ahk2Exe\Ahk2Exe.exe'
if (-not (Test-Path $ahk2exe)) {
    Write-Host 'Téléchargement du compilateur Ahk2Exe...'
    $zip = Join-Path $env:TEMP 'Ahk2Exe.zip'
    Invoke-WebRequest 'https://github.com/AutoHotkey/Ahk2Exe/releases/download/Ahk2Exe1.1.37.02a2/Ahk2Exe1.1.37.02a2.zip' -OutFile $zip
    Expand-Archive $zip (Split-Path $ahk2exe) -Force
    Remove-Item $zip
}

# 3. Si AppToggle tourne depuis dist, on l'arrête le temps de remplacer l'exe (sinon le fichier est verrouillé)
$running = Get-Process AppToggle -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe }
if ($running) {
    Write-Host 'Arrêt temporaire d''AppToggle...'
    $running | Stop-Process -Force
    $running | Wait-Process -Timeout 5 -ErrorAction SilentlyContinue
}

# 4. Compilation
New-Item -ItemType Directory -Force $dist | Out-Null
Write-Host 'Compilation...'
$p = Start-Process $ahk2exe -ArgumentList "/in `"$src`" /out `"$exe`" /base `"$base`" /silent verbose" -Wait -PassThru -NoNewWindow
if ($p.ExitCode -ne 0 -or -not (Test-Path $exe)) { throw "La compilation a échoué (code $($p.ExitCode))." }

# 5. Paquet à partager : l'exe + les licences (la config se crée toute seule au premier lancement).
#    L'exe embarque AutoHotkey (GPL v2) : sa licence et son code source doivent accompagner chaque release.
$version = (Get-Item $exe).VersionInfo.ProductVersion
$ahkVersion = (Get-Item $base).VersionInfo.ProductVersion
$staging = Join-Path $dist 'paquet'
New-Item -ItemType Directory -Force $staging | Out-Null
Copy-Item $exe $staging -Force
Copy-Item (Join-Path $root 'LICENSE') (Join-Path $staging 'LICENSE.txt') -Force
Copy-Item (Join-Path $ahkDir 'license.txt') (Join-Path $staging 'LICENCE-AutoHotkey.txt') -Force
$zipOut = Join-Path $dist "AppToggle-$version.zip"
Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $zipOut -Force
Get-ChildItem $staging | ForEach-Object { $_.Delete() }
(Get-Item $staging).Delete()
$hash = (Get-FileHash $exe -Algorithm SHA256).Hash
"$hash  AppToggle.exe" | Set-Content (Join-Path $dist 'SHA256.txt') -Encoding ASCII

$ahkSource = Join-Path $dist "AutoHotkey-v$ahkVersion-source.zip"
if (-not (Test-Path $ahkSource)) {
    Write-Host "Téléchargement du code source d'AutoHotkey v$ahkVersion (à joindre à la release)..."
    Invoke-WebRequest "https://github.com/AutoHotkey/AutoHotkey/archive/refs/tags/v$ahkVersion.zip" -OutFile $ahkSource
}
Write-Host "OK : $exe (version $version, AutoHotkey $ahkVersion)"
Write-Host "SHA-256 : $hash"
Write-Host "Fichiers à joindre à la release GitHub :"
Write-Host "  $zipOut"
Write-Host "  $(Join-Path $dist 'SHA256.txt')"
Write-Host "  $ahkSource"

if ($running) { Start-Process $exe -ArgumentList '/startup' }
