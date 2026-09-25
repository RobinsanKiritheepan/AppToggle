# Sécurité / Security

*English below.*

## Signaler une faille

Merci de **ne pas** publier une faille dans une issue publique. Utilise l'onglet **Security** du dépôt, puis **Report a vulnerability** : le message reste privé entre toi et le mainteneur. Indique la version d'AppToggle, ta version de Windows et les étapes pour reproduire le problème.

## Ce que fait AppToggle, et ce qu'il ne fait pas

- **Aucune connexion Internet** : le code d'AppToggle n'envoie ni ne reçoit rien. Le seul lien est « Code source sur GitHub », qui ouvre ton navigateur quand tu cliques dessus.
- **Aucune donnée collectée** : la configuration reste sur ton PC, dans `config.ini` (à côté de l'exécutable dans la version zip, dans `AppData` dans la version du Microsoft Store).
- **Pas de droits administrateur** : AppToggle tourne avec les droits normaux de l'utilisateur.
- **Clavier** : selon la touche choisie, Windows prévient AppToggle par l'API `RegisterHotKey`, ou AppToggle utilise un crochet clavier. C'est le cas pour la touche Copilot et les combinaisons avec Win. Ce crochet voit passer les touches pour reconnaître le raccourci, mais AppToggle **n'enregistre, ne stocke et n'envoie aucune frappe** : l'historique des touches d'AutoHotkey est désactivé (`KeyHistory(0)`). Pendant « Changer la touche », les touches sont bloquées au maximum 15 secondes, et seule la combinaison choisie est gardée.
- **Lancement d'applis** : AppToggle ne lance que les applis que tu as configurées toi-même.
- **Démarrage** : dans la version zip, l'option « Lancer avec Windows » crée un simple raccourci visible dans ton dossier Démarrage (`Win + R`, puis `shell:startup`). Dans la version du Microsoft Store, c'est Windows qui gère le démarrage (**Paramètres > Applications > Démarrage**).

## Bonnes pratiques

- Installe AppToggle **uniquement** depuis le [Microsoft Store](https://apps.microsoft.com/detail/9NN6L7PJ0DFC) ou la page [Releases](https://github.com/RobinsanKiritheepan/AppToggle/releases) de ce dépôt. Pour la version zip, vérifie l'empreinte SHA-256 publiée avec chaque version.
- Version zip : range `AppToggle.exe` dans un **dossier à toi** (par exemple `Documents\AppToggle`), **jamais** dans Téléchargements ni dans un dossier partagé. Comme tout programme, l'exécutable charge au démarrage des bibliothèques Windows (DLL). Un fichier piégé déposé dans le même dossier pourrait être chargé à la place de l'original (attaque dite de « DLL planting »). AppToggle limite ce risque pour les bibliothèques qu'il charge lui-même (uniquement depuis `System32`), mais une partie est chargée par Windows avant le démarrage du programme.
- Dans la version zip, `AppToggle.exe` est l'interpréteur officiel AutoHotkey, non modifié : son empreinte SHA-256 est publiée avec chaque release et doit être identique à celle de la version officielle. Tout ce qu'il exécute est du code lisible dans les fichiers `.ahk` du dossier.

## Construction des versions à partager

`build.ps1` (version zip) télécharge la version officielle d'AutoHotkey depuis GitHub, vérifie l'empreinte SHA-256 du zip et de l'interpréteur avant de s'en servir, et publie avec chaque release le code source d'AutoHotkey correspondant (licence GPL v2). Aucun exécutable n'est compilé ni modifié.

`build-store.ps1` (Microsoft Store) compile `AppToggle.exe` avec Ahk2Exe à partir des versions officielles d'AutoHotkey et d'Ahk2Exe, dont il vérifie les empreintes SHA-256, et n'utilise que des outils de paquet signés par Microsoft. Le paquet contient aussi la licence et le code source d'AutoHotkey. C'est Microsoft qui signe le paquet publié sur le Store.

La version zip n'est pas signée numériquement : sur les PC où le Contrôle intelligent des applications de Windows 11 est activé, elle est bloquée. La version du Microsoft Store, signée par Microsoft, n'a pas ce problème.

---

## Reporting a vulnerability

Please **do not** open a public issue. Use the repository's **Security** tab, then **Report a vulnerability**, to send a private report. Include the AppToggle version, your Windows version and the steps to reproduce.

## What AppToggle does, and doesn't do

- **No network access**: AppToggle's code never sends or receives anything. The only link, "Source code on GitHub", opens your browser when you click it.
- **No data collection**: settings stay on your PC, in `config.ini` (next to the executable in the zip version, in `AppData` in the Microsoft Store version).
- **No administrator rights**: AppToggle runs with normal user rights.
- **Keyboard**: depending on the chosen key, Windows notifies AppToggle through the `RegisterHotKey` API, or AppToggle uses a keyboard hook. That is the case for the Copilot key and combinations with Win. The hook sees keys go by in order to recognize the shortcut, but AppToggle **never records, stores or sends keystrokes**: AutoHotkey's key history is disabled (`KeyHistory(0)`). While you set a new key, keys are blocked for 15 seconds at most, and only the chosen combination is kept.
- **Launching apps**: AppToggle only launches the apps you configured yourself.
- **Startup**: in the zip version, "Start with Windows" creates a plain, visible shortcut in your Startup folder (`Win + R`, then `shell:startup`). In the Microsoft Store version, Windows manages startup (**Settings > Apps > Startup**).

## Good practices

- Install AppToggle **only** from the [Microsoft Store](https://apps.microsoft.com/detail/9NN6L7PJ0DFC) or this repository's [Releases](https://github.com/RobinsanKiritheepan/AppToggle/releases) page. For the zip version, check the SHA-256 hash published with each version.
- Zip version: keep `AppToggle.exe` in **your own folder** (for example `Documents\AppToggle`), **never** in Downloads or a shared folder. Like any program, the executable loads Windows libraries (DLLs) at startup. A malicious file dropped in the same folder could be loaded instead of the real one ("DLL planting"). AppToggle limits this risk for the libraries it loads itself (only from `System32`), but some are loaded by Windows before the program starts.
- In the zip version, `AppToggle.exe` is the official, unmodified AutoHotkey interpreter: its SHA-256 hash is published with each release and must match the official one. Everything it runs is readable code in the folder's `.ahk` files.

## Building the shareable versions

`build.ps1` (zip version) downloads the official AutoHotkey release from GitHub, checks the SHA-256 hash of both the zip and the interpreter before using them, and each release ships the matching AutoHotkey source code (GPL v2 license). No executable is compiled or modified.

`build-store.ps1` (Microsoft Store) compiles `AppToggle.exe` with Ahk2Exe from the official AutoHotkey and Ahk2Exe releases, whose SHA-256 hashes it checks, and only uses packaging tools signed by Microsoft. The package also contains AutoHotkey's license and source code. Microsoft signs the package published on the Store.

The zip version isn't digitally signed: on PCs where Windows 11 Smart App Control is on, it gets blocked. The Microsoft Store version, signed by Microsoft, doesn't have this problem.
