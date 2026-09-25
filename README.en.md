# AppToggle

Open, bring back or minimize any app with a single key, for example the Copilot key on recent keyboards.

**Version française : [README.md](README.md)**

<p align="center">
  <img src="docs/en-dark.png" width="49%" alt="AppToggle in dark mode">
  <img src="docs/en-light.png" width="49%" alt="AppToggle in light mode">
</p>

## Features

- **Several shortcuts**, each with its own key and on/off switch.
- **Pick an app without typing anything**: choose from the open windows. AppToggle detects by itself whether it's a Microsoft Store app or a regular program. You can also pick an `.exe` manually.
- **Set the key by pressing it**: just press the combination you want. The Copilot key is supported.
- **Smart toggle**: the app is launched if it's closed, restored if it's minimized, brought to the front if it's hidden behind other windows, and minimized if it's already in front.
- **Visible status**: a colored icon near the clock when AppToggle is on, gray when it's paused.
- **English and French**: follows the Windows language, or pick one in the options.
- **Follows the Windows theme** (dark or light) and accent color.
- **Lightweight**: a folder of about 1.4 MB, less than 2 MB of active memory in the background, no CPU usage until you press a key.
- **Portable and offline**: settings are saved in `config.ini`, next to the executable. Nothing in the registry, no data collection, no internet connection.

## Installation

1. Download `AppToggle-x.y.z.zip` from the [latest release](https://github.com/RobinsanKiritheepan/AppToggle/releases/latest).
2. Extract the zip: it contains an `AppToggle` folder. Put it in a folder of your own where it will stay (for example `Documents`), not in Downloads.
3. Open the folder and double-click `AppToggle.exe`: the settings window opens. Keep all the files of the folder together.

### Smart App Control (Windows 11): known limitation

If this security setting is on, Windows blocks AppToggle with the message "Smart App Control blocked an app that may be unsafe". It isn't malware: Windows blocks any program it doesn't know that isn't digitally signed by a verified publisher. AppToggle isn't signed yet; a signed version is planned.

In the meantime, it's better not to turn off this protection just for AppToggle. If all you want is to open an app with the Copilot key, Windows 11 can do it without installing anything: **Settings > Personalization > Text input**, Copilot key option, then **Custom** and pick the app (it must come from the Microsoft Store, like Claude or ChatGPT). The app opens, but doesn't minimize when you press the key again.

If Windows only shows "Windows protected your PC" (SmartScreen), click **More info**, then **Run anyway**.

### Why `AppToggle.exe` is AutoHotkey

`AppToggle.exe` is the official [AutoHotkey v2](https://www.autohotkey.com) interpreter, **unmodified**, just renamed: it automatically runs `AppToggle.ahk`, which sits next to it. As a result, AppToggle shows up as "AutoHotkey" in Task Manager and in the file properties. The SHA-256 hash published with each release lets you check that it's the official interpreter, and everything else is readable code (`.ahk`).

## How to use

1. Open the app you want (Claude, ChatGPT, Discord…).
2. In AppToggle, click **Add**, then **Pick an open app**, and select it.
3. Click **Change** and press the key combination you want, or click **Use the Copilot key**.
4. Click **Save**.

<p align="center">
  <img src="docs/en-picker.png" width="45%" alt="Pick an open app">
  <img src="docs/en-capture.png" width="47%" alt="Set the key by pressing it">
</p>

Turn on **Start with Windows** so AppToggle starts with your PC. Clicking the icon near the clock opens the settings again; right-clicking gives you Enabled, Start with Windows and Quit.

So you can still type normally, a combination must include Ctrl, Alt or Win (except special keys such as F13 to F24 or media keys).

## Security and privacy

AppToggle never connects to the internet, collects no data and doesn't need administrator rights. To recognize some keys (including the Copilot key) it uses a Windows keyboard hook, but it never records or sends keystrokes. All the details, good practices and how to report a vulnerability are in [SECURITY.md](SECURITY.md).

## Building the shareable version

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
```

The script downloads the official AutoHotkey release once into `tools\` (no administrator rights needed) and checks its SHA-256 hash. It then assembles `dist\AppToggle\` (the renamed interpreter, the scripts, the icons and the licenses) and checks the syntax. Finally, it prepares the release files: the zip, the SHA-256 hashes and the matching AutoHotkey source code. There is nothing to compile. To run it straight from the code with [AutoHotkey v2](https://www.autohotkey.com) installed, just double-click `src\AppToggle.ahk`.

## Project structure

| File | Role |
|---|---|
| `src/AppToggle.ahk` | Entry point: startup, single instance, executable information |
| `src/lib/Engine.ahk` | Links keys to apps; open, bring back or minimize |
| `src/lib/Config.ahk` | Reads and writes `config.ini` |
| `src/lib/Keys.ahk` | Key names and key combination capture |
| `src/lib/Lang.ahk` | French / English translations |
| `src/lib/Tray.ahk` | Icon near the clock, its menu, start with Windows |
| `src/lib/Theme.ahk` | Colors, fonts, dark or light mode |
| `src/lib/Draw.ahk` | GDI+ drawing: cards, switches, buttons, keycaps |
| `src/ui/` | The windows: settings, add or edit a shortcut, pick an app |
| `tools/make-icons.ps1` | Generates the icons in `assets` |
| `build.ps1` | Assembles the shareable version and release files |

## `config.ini` format

The file is created on first launch. It's meant to be edited from the settings window, but stays readable (key names are in French):

```ini
[General]
Actif=1
Notification=1
Langue=auto

[Raccourci1]
Nom=Claude
Touche=+#F23
Type=store
Cible=Claude_pzs8sxrjxfjjc!Claude
Processus=claude.exe
Titre=
Actif=1
```

- `Langue` (language): `auto` (Windows language), `fr` or `en`.
- `Touche` (key) uses AutoHotkey syntax: `^` Ctrl, `!` Alt, `+` Shift, `#` Win. The Copilot key is `+#F23`.
- `Type=store`: `Cible` (target) is the Microsoft Store app ID (`Get-StartApps` in PowerShell shows it). `Type=exe`: `Cible` is the full path of the program.
- `Processus` (process) is used to find the app's window; `Titre` (title, optional) filters on part of the window title.

## Licenses and notices

- **AppToggle's code** (scripts, icons, documentation) is released under the MIT license: see [LICENSE](LICENSE).
- **`AppToggle.exe`** is the official, unmodified [AutoHotkey v2](https://github.com/AutoHotkey/AutoHotkey) interpreter, released under the GNU GPL v2 (it includes the PCRE library, under a BSD license). Each release provides its license (`LICENCE-AutoHotkey.txt`, in the folder) and the matching AutoHotkey source code.
- Windows and Copilot are trademarks of Microsoft; Claude is a trademark of Anthropic; ChatGPT and Codex are trademarks of OpenAI. AppToggle is an independent project, not affiliated with or endorsed by these companies. Screenshots use demo apps.
