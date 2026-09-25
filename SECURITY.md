# Sécurité / Security

*English below.*

## Signaler une faille

Merci de **ne pas** publier une faille dans une issue publique. Utilise l'onglet **Security** du dépôt, puis **Report a vulnerability** : le message reste privé entre toi et le mainteneur. Indique la version d'AppToggle, ta version de Windows et les étapes pour reproduire le problème.

## Ce que fait AppToggle, et ce qu'il ne fait pas

- **Aucune connexion Internet** : le code d'AppToggle n'envoie ni ne reçoit rien. Le seul lien est « Code source sur GitHub », qui ouvre ton navigateur quand tu cliques dessus.
- **Aucune donnée collectée** : la configuration reste dans `config.ini`, à côté de l'exécutable.
- **Pas de droits administrateur** : AppToggle tourne avec les droits normaux de l'utilisateur.
- **Clavier** : selon la touche choisie, Windows prévient AppToggle par l'API `RegisterHotKey`, ou AppToggle utilise un crochet clavier. C'est le cas pour la touche Copilot et les combinaisons avec Win. Ce crochet voit passer les touches pour reconnaître le raccourci, mais AppToggle **n'enregistre, ne stocke et n'envoie aucune frappe** : l'historique des touches d'AutoHotkey est désactivé (`KeyHistory(0)`). Pendant « Changer la touche », les touches sont bloquées au maximum 15 secondes, et seule la combinaison choisie est gardée.
- **Lancement d'applis** : AppToggle ne lance que les applis que tu as configurées toi-même.
- **Démarrage** : l'option « Lancer avec Windows » crée un simple raccourci visible dans ton dossier Démarrage (`Win + R`, puis `shell:startup`).

## Bonnes pratiques

- Télécharge AppToggle **uniquement** depuis la page [Releases](https://github.com/RobinsanKiritheepan/AppToggle/releases) de ce dépôt, et vérifie l'empreinte SHA-256 publiée avec chaque version.
- Range `AppToggle.exe` dans un **dossier à toi** (par exemple `Documents\AppToggle`), **jamais** dans Téléchargements ni dans un dossier partagé. Comme tout programme, l'exécutable charge au démarrage des bibliothèques Windows (DLL). Un fichier piégé déposé dans le même dossier pourrait être chargé à la place de l'original (attaque dite de « DLL planting »). AppToggle limite ce risque pour les bibliothèques qu'il charge lui-même (uniquement depuis `System32`), mais une partie est chargée par Windows avant le démarrage du programme.
- `AppToggle.exe` est l'interpréteur officiel AutoHotkey, non modifié : son empreinte SHA-256 est publiée avec chaque release et doit être identique à celle de la version officielle. Tout ce qu'il exécute est du code lisible dans les fichiers `.ahk` du dossier.

## Construction de la version à partager

`build.ps1` télécharge la version officielle d'AutoHotkey depuis GitHub, vérifie l'empreinte SHA-256 du zip et de l'interpréteur avant de s'en servir, et publie avec chaque release le code source d'AutoHotkey correspondant (licence GPL v2). Aucun exécutable n'est compilé ni modifié.

AppToggle n'est pas encore signé numériquement : sur les PC où le Contrôle intelligent des applications de Windows 11 est activé, il est bloqué. Une version signée est prévue.

---

## Reporting a vulnerability

Please **do not** open a public issue. Use the repository's **Security** tab, then **Report a vulnerability**, to send a private report. Include the AppToggle version, your Windows version and the steps to reproduce.

## What AppToggle does, and doesn't do

- **No network access**: AppToggle's code never sends or receives anything. The only link, "Source code on GitHub", opens your browser when you click it.
- **No data collection**: settings stay in `config.ini`, next to the executable.
- **No administrator rights**: AppToggle runs with normal user rights.
- **Keyboard**: depending on the chosen key, Windows notifies AppToggle through the `RegisterHotKey` API, or AppToggle uses a keyboard hook. That is the case for the Copilot key and combinations with Win. The hook sees keys go by in order to recognize the shortcut, but AppToggle **never records, stores or sends keystrokes**: AutoHotkey's key history is disabled (`KeyHistory(0)`). While you set a new key, keys are blocked for 15 seconds at most, and only the chosen combination is kept.
- **Launching apps**: AppToggle only launches the apps you configured yourself.
- **Startup**: "Start with Windows" creates a plain, visible shortcut in your Startup folder (`Win + R`, then `shell:startup`).

## Good practices

- Download AppToggle **only** from this repository's [Releases](https://github.com/RobinsanKiritheepan/AppToggle/releases) page, and check the SHA-256 hash published with each version.
- Keep `AppToggle.exe` in **your own folder** (for example `Documents\AppToggle`), **never** in Downloads or a shared folder. Like any program, the executable loads Windows libraries (DLLs) at startup. A malicious file dropped in the same folder could be loaded instead of the real one ("DLL planting"). AppToggle limits this risk for the libraries it loads itself (only from `System32`), but some are loaded by Windows before the program starts.
- `AppToggle.exe` is the official, unmodified AutoHotkey interpreter: its SHA-256 hash is published with each release and must match the official one. Everything it runs is readable code in the folder's `.ahk` files.

## Building the shareable version

`build.ps1` downloads the official AutoHotkey release from GitHub, checks the SHA-256 hash of both the zip and the interpreter before using them, and each release ships the matching AutoHotkey source code (GPL v2 license). No executable is compiled or modified.

AppToggle isn't digitally signed yet: on PCs where Windows 11 Smart App Control is on, it gets blocked. A signed version is planned.
