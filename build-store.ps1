# Fabrique le paquet Microsoft Store : dist\store\AppToggle-<version>.msix
#
# Dans le Store, c'est Microsoft qui signe le paquet : Windows (et son Contrôle intelligent des
# applications) l'accepte donc partout. On peut y mettre l'exe compilé par Ahk2Exe, avec l'icône
# et les propriétés d'AppToggle.
#
# Identité du Partner Center (Product management > Product identity) : msix\identity.json
#   { "IdentityName": "...", "Publisher": "CN=...", "PublisherDisplayName": "..." }
# Sans ce fichier, un paquet de TEST est fabriqué (à ne pas envoyer au Store).
#
# Lancement : powershell -ExecutionPolicy Bypass -File build-store.ps1
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$src = Join-Path $root 'src'
$tools = Join-Path $root 'tools'
$out = Join-Path $root 'dist\store'

# Outils officiels : versions et empreintes SHA-256 épinglées
$ahkVersion = '2.0.26'
$ahkZip = @{ Url = "https://github.com/AutoHotkey/AutoHotkey/releases/download/v$ahkVersion/AutoHotkey_$ahkVersion.zip"
             Sha = '43522AA3122A57784AC5DB30ABF85C2244475C36ACD7796E2C993355F9E926AE' }
$ahkExeSha = 'A2A54B8ABC476D7671D4DE0771BB54BF5F2373D79FF6871D0BA6A62C3B88AE00'
$a2eZip = @{ Url = 'https://github.com/AutoHotkey/Ahk2Exe/releases/download/Ahk2Exe1.1.37.02a2/Ahk2Exe1.1.37.02a2.zip'
             Sha = 'C29B8C3A5124850D79FC9E66E2CA79677C377D7F31631AD3022BA159C5D9E3BE' }
$a2eExeSha = 'E54A599B19BAA5C1688849BBAE7A9CF049EEFCCD4F704C67941B40DA13A625B2'
$sdkVersion = '10.0.28000.2705'   # Microsoft.Windows.SDK.BuildTools (makeappx, makepri)

# Télécharge un zip, vérifie son empreinte, l'extrait
function Get-VerifiedZip([hashtable]$zip, [string]$dest) {
    $tmp = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName() + '.zip')
    Invoke-WebRequest $zip.Url -OutFile $tmp -UseBasicParsing
    if ($zip.Sha -and (Get-FileHash $tmp -Algorithm SHA256).Hash -ne $zip.Sha) {
        [IO.File]::Delete($tmp)
        throw "Empreinte inattendue pour $($zip.Url) : arrêt par sécurité."
    }
    Expand-Archive $tmp $dest -Force
    [IO.File]::Delete($tmp)
}

# Supprime un dossier, en réessayant si Windows (indexation, antivirus) tient encore un fichier ouvert
function Remove-Folder([string]$path) {
    for ($i = 0; $i -lt 10 -and (Test-Path $path); $i++) {
        try { Remove-Item $path -Recurse -Force -ErrorAction Stop } catch { Start-Sleep -Milliseconds 500 }
    }
    if (Test-Path $path) { throw "Impossible de supprimer $path : un fichier est peut-être ouvert." }
}

function Assert-Sha([string]$file, [string]$sha) {
    if ((Get-FileHash $file -Algorithm SHA256).Hash -ne $sha) {
        throw "$file a été modifié (empreinte différente). Supprime son dossier dans tools\ puis relance."
    }
}

# 1. AutoHotkey officiel (sert de base à l'exe compilé)
$ahkDir = Join-Path $tools "AutoHotkey-$ahkVersion"
if (-not (Test-Path "$ahkDir\AutoHotkey64.exe")) { Write-Host "Téléchargement d'AutoHotkey $ahkVersion..."; Get-VerifiedZip $ahkZip $ahkDir }
Assert-Sha "$ahkDir\AutoHotkey64.exe" $ahkExeSha

# Son code source (licence GPL) : joint au paquet, puisque l'exe compilé contient AutoHotkey
$ahkSource = Join-Path $root "dist\AutoHotkey-v$ahkVersion-source.zip"
if (-not (Test-Path $ahkSource)) {
    Write-Host "Téléchargement du code source d'AutoHotkey $ahkVersion..."
    New-Item -ItemType Directory -Force (Split-Path $ahkSource) | Out-Null
    Invoke-WebRequest "https://github.com/AutoHotkey/AutoHotkey/archive/refs/tags/v$ahkVersion.zip" -OutFile "$ahkSource.part" -UseBasicParsing
    Move-Item "$ahkSource.part" $ahkSource
}

# 2. Compilateur Ahk2Exe
$a2eDir = Join-Path $tools 'Ahk2Exe'
if (-not (Test-Path "$a2eDir\Ahk2Exe.exe")) { Write-Host 'Téléchargement du compilateur Ahk2Exe...'; Get-VerifiedZip $a2eZip $a2eDir }
Assert-Sha "$a2eDir\Ahk2Exe.exe" $a2eExeSha

# 3. Outils de paquet de Microsoft (makeappx, makepri) : on vérifie leur signature Microsoft
$sdkDir = Join-Path $tools "sdk-buildtools-$sdkVersion"
if (-not (Test-Path $sdkDir)) {
    Write-Host 'Téléchargement des outils de paquet Microsoft (SDK Build Tools)...'
    Get-VerifiedZip @{ Url = "https://api.nuget.org/v3-flatcontainer/microsoft.windows.sdk.buildtools/$sdkVersion/microsoft.windows.sdk.buildtools.$sdkVersion.nupkg" } $sdkDir
}
$makeappx = Get-ChildItem $sdkDir -Recurse -Filter makeappx.exe | Where-Object { $_.FullName -match '\\x64\\' } | Select-Object -First 1
$makepri = Join-Path $makeappx.DirectoryName 'makepri.exe'
foreach ($exe in $makeappx.FullName, $makepri) {
    $sig = Get-AuthenticodeSignature $exe
    if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {
        throw "$exe n'est pas signé par Microsoft : arrêt par sécurité."
    }
}

# 4. Version (x.y.z -> x.y.z.0, le Store exige 4 nombres) et identité
$version = [regex]::Match([IO.File]::ReadAllText((Join-Path $src 'AppToggle.ahk')), 'static Version := "([\d.]+)"').Groups[1].Value
if (-not $version) { throw 'Version introuvable dans src\AppToggle.ahk' }
$msixVersion = "$version.0"
$idFile = Join-Path $root 'msix\identity.json'
if (Test-Path $idFile) {
    $id = Get-Content $idFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $isTest = $false
} else {
    $id = [pscustomobject]@{ IdentityName = 'AppToggle.Test'; Publisher = 'CN=AppToggleTest'; PublisherDisplayName = 'AppToggle (test)' }
    $isTest = $true
}

# 5. Dossier du paquet
$layout = Join-Path $out 'layout'
Remove-Folder $layout
New-Item -ItemType Directory -Force $layout | Out-Null

Write-Host 'Compilation de AppToggle.exe...'
$p = Start-Process "$a2eDir\Ahk2Exe.exe" -ArgumentList "/in `"$src\AppToggle.ahk`" /out `"$layout\AppToggle.exe`" /base `"$ahkDir\AutoHotkey64.exe`" /silent verbose" -Wait -PassThru -NoNewWindow
if ($p.ExitCode -ne 0 -or -not (Test-Path "$layout\AppToggle.exe")) { throw "La compilation a échoué (code $($p.ExitCode))." }

Write-Host 'Images du Store...'
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $tools 'make-icons.ps1') -StoreImages (Join-Path $layout 'images')
if ($LASTEXITCODE) { throw 'La génération des images a échoué.' }

$manifest = [IO.File]::ReadAllText((Join-Path $root 'msix\AppxManifest.xml'))
$esc = { param($s) [Security.SecurityElement]::Escape([string]$s) }
$manifest = $manifest.Replace('{{IdentityName}}', (& $esc $id.IdentityName)).Replace('{{Publisher}}', (& $esc $id.Publisher))
$manifest = $manifest.Replace('{{PublisherDisplayName}}', (& $esc $id.PublisherDisplayName)).Replace('{{Version}}', $msixVersion)
[IO.File]::WriteAllText((Join-Path $layout 'AppxManifest.xml'), $manifest, [Text.UTF8Encoding]::new($false))
Copy-Item (Join-Path $root 'LICENSE') (Join-Path $layout 'LICENSE.txt')
Copy-Item "$ahkDir\license.txt" (Join-Path $layout 'LICENCE-AutoHotkey.txt')

# 6. Index des images (resources.pri : Windows choisit la bonne taille selon l'écran) puis paquet .msix
$work = Join-Path $out 'work'
New-Item -ItemType Directory -Force $work | Out-Null
& $makepri createconfig /cf "$work\priconfig.xml" /dq en-US /pv 10.0.0 /o | Out-Null
if ($LASTEXITCODE) { throw 'makepri createconfig a échoué.' }
# Un seul resources.pri avec toutes les tailles (sinon makepri le découpe pour des paquets de ressources séparés)
$cfg = [xml](Get-Content "$work\priconfig.xml" -Raw)
$cfg.resources.SelectNodes('packaging') | ForEach-Object { [void]$cfg.resources.RemoveChild($_) }
$cfg.Save("$work\priconfig.xml")
& $makepri new /pr $layout /cf "$work\priconfig.xml" /of "$layout\resources.pri" /mn "$layout\AppxManifest.xml" /o | Out-Null
if ($LASTEXITCODE) { throw 'makepri new a échoué.' }
# Ajouté après makepri : ce zip n'est pas une ressource de l'appli (et ses points dans le nom gêneraient makepri)
Copy-Item $ahkSource (Join-Path $layout (Split-Path $ahkSource -Leaf))
$msix =Join-Path $out "AppToggle-$version$(if ($isTest) { '-TEST' }).msix"
$log = & $makeappx.FullName pack /d $layout /p $msix /o 2>&1
if ($LASTEXITCODE) { $log | Write-Host; throw 'makeappx pack a échoué (voir le message ci-dessus).' }
Remove-Folder $work

Write-Host ''
Write-Host "OK : $msix ($([math]::Round((Get-Item $msix).Length / 1KB)) Ko, version $msixVersion)"
if ($isTest) {
    Write-Host 'ATTENTION : paquet de TEST (msix\identity.json absent). Ne pas l''envoyer au Store.' -ForegroundColor Yellow
}
