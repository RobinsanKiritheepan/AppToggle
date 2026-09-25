# Prépare la version à partager d'AppToggle dans dist\ :
#   dist\AppToggle\  = AppToggle.exe (interpréteur AutoHotkey officiel, renommé, NON modifié)
#                      + AppToggle.ahk et ses modules + icônes + licences
#   dist\AppToggle-<version>.zip, SHA256.txt et le code source d'AutoHotkey (à joindre à la release).
#
# Pourquoi pas un exe compilé : le Contrôle intelligent des applications de Windows 11 bloque les .exe
# non signés qu'il ne connaît pas. L'interpréteur officiel, lui, est reconnu ; renommé AppToggle.exe,
# il lance tout seul AppToggle.ahk placé à côté de lui.
#
# Lancement : clic droit > « Exécuter avec PowerShell »
#        ou : powershell -ExecutionPolicy Bypass -File build.ps1
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$src = Join-Path $root 'src'
$dist = Join-Path $root 'dist'

# Version officielle d'AutoHotkey embarquée et ses empreintes SHA-256 (vérifiées avant tout usage)
$ahkVersion = '2.0.26'
$ahkZipSha = '43522AA3122A57784AC5DB30ABF85C2244475C36ACD7796E2C993355F9E926AE'   # AutoHotkey_2.0.26.zip
$ahkExeSha = 'A2A54B8ABC476D7671D4DE0771BB54BF5F2373D79FF6871D0BA6A62C3B88AE00'   # AutoHotkey64.exe qu'il contient

$version = [regex]::Match([IO.File]::ReadAllText((Join-Path $src 'AppToggle.ahk')), 'static Version := "([\d.]+)"').Groups[1].Value
if (-not $version) { throw 'Version introuvable dans src\AppToggle.ahk' }
New-Item -ItemType Directory -Force $dist | Out-Null

# 1. AutoHotkey officiel, téléchargé une seule fois dans tools\ (sans droits administrateur)
$cache = Join-Path $root "tools\AutoHotkey-$ahkVersion"
$ahkExe = Join-Path $cache 'AutoHotkey64.exe'
if (-not (Test-Path $ahkExe)) {
    Write-Host "Téléchargement d'AutoHotkey $ahkVersion (version officielle)..."
    $zip = Join-Path $env:TEMP "AutoHotkey_$ahkVersion.zip"
    Invoke-WebRequest "https://github.com/AutoHotkey/AutoHotkey/releases/download/v$ahkVersion/AutoHotkey_$ahkVersion.zip" -OutFile $zip -UseBasicParsing
    if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne $ahkZipSha) {
        [IO.File]::Delete($zip)
        throw "Le zip AutoHotkey téléchargé n'a pas l'empreinte attendue : arrêt par sécurité."
    }
    Expand-Archive $zip $cache -Force
    [IO.File]::Delete($zip)
}
if ((Get-FileHash $ahkExe -Algorithm SHA256).Hash -ne $ahkExeSha) {
    throw "tools\AutoHotkey-$ahkVersion\AutoHotkey64.exe a été modifié (empreinte différente). Supprime ce dossier puis relance."
}

# 2. Si AppToggle tourne depuis dist\AppToggle, on l'arrête le temps de remplacer les fichiers
$app = Join-Path $dist 'AppToggle'
$appExe = Join-Path $app 'AppToggle.exe'
$running = Get-Process AppToggle -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $appExe }
if ($running) {
    Write-Host "Arrêt temporaire d'AppToggle..."
    $running | Stop-Process -Force
    $running | Wait-Process -Timeout 5 -ErrorAction SilentlyContinue
}

# 3. Assemblage du dossier (config.ini et errors.log éventuels sont conservés)
New-Item -ItemType Directory -Force $app | Out-Null
foreach ($sub in 'lib', 'ui', 'assets') {
    $p = Join-Path $app $sub
    if (Test-Path $p) { [IO.Directory]::Delete($p, $true) }
}
Copy-Item $ahkExe $appExe -Force
Copy-Item (Join-Path $src 'AppToggle.ahk') $app -Force
Copy-Item (Join-Path $src 'lib') (Join-Path $app 'lib') -Recurse
Copy-Item (Join-Path $src 'ui') (Join-Path $app 'ui') -Recurse
New-Item -ItemType Directory (Join-Path $app 'assets') | Out-Null
Copy-Item (Join-Path $root 'assets\*.ico') (Join-Path $app 'assets')
Copy-Item (Join-Path $root 'LICENSE') (Join-Path $app 'LICENSE.txt') -Force
Copy-Item (Join-Path $cache 'license.txt') (Join-Path $app 'LICENCE-AutoHotkey.txt') -Force

# 4. Vérification de la syntaxe par l'interpréteur lui-même
$p = Start-Process $ahkExe -ArgumentList '/Validate', '/ErrorStdOut', "`"$(Join-Path $app 'AppToggle.ahk')`"" -Wait -PassThru -NoNewWindow
if ($p.ExitCode -ne 0) { throw 'Erreur dans les scripts (voir ci-dessus) : paquet non créé.' }

# 5. Zip à partager (sans réglages personnels), empreintes, et code source d'AutoHotkey (licence GPL)
$zipOut = Join-Path $dist "AppToggle-$version.zip"
$tmp = Join-Path $env:TEMP 'AppToggle-paquet'
if (Test-Path $tmp) { [IO.Directory]::Delete($tmp, $true) }
New-Item -ItemType Directory $tmp | Out-Null
Copy-Item $app $tmp -Recurse
Get-ChildItem (Join-Path $tmp 'AppToggle') -File | Where-Object { $_.Name -in 'config.ini', 'errors.log', 'erreurs.log' } | ForEach-Object { $_.Delete() }
Compress-Archive -Path (Join-Path $tmp 'AppToggle') -DestinationPath $zipOut -Force
[IO.Directory]::Delete($tmp, $true)
@(
    "$((Get-FileHash $zipOut -Algorithm SHA256).Hash)  AppToggle-$version.zip"
    "$ahkExeSha  AppToggle.exe (AutoHotkey $ahkVersion officiel, non modifié)"
) | Set-Content (Join-Path $dist 'SHA256.txt') -Encoding ASCII
$ahkSource = Join-Path $dist "AutoHotkey-v$ahkVersion-source.zip"
if (-not (Test-Path $ahkSource)) {
    Write-Host "Téléchargement du code source d'AutoHotkey $ahkVersion (à joindre à la release)..."
    Invoke-WebRequest "https://github.com/AutoHotkey/AutoHotkey/archive/refs/tags/v$ahkVersion.zip" -OutFile $ahkSource -UseBasicParsing
}

Write-Host "OK : AppToggle $version (AutoHotkey $ahkVersion)"
Write-Host "Dossier prêt à l'emploi : $app"
Write-Host 'Fichiers à joindre à la release GitHub :'
Write-Host "  $zipOut"
Write-Host "  $(Join-Path $dist 'SHA256.txt')"
Write-Host "  $ahkSource"

if ($running) { Start-Process $appExe -ArgumentList "`"$(Join-Path $app 'AppToggle.ahk')`"", '/startup' -WorkingDirectory $app }
