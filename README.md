# AppToggle

Ouvre, ramène ou réduit une application avec une seule touche, par exemple la touche Copilot des claviers récents.

**English version: [README.en.md](README.en.md)**

<p align="center">
  <img src="docs/apercu-sombre.png" width="49%" alt="AppToggle en thème sombre">
  <img src="docs/apercu-clair.png" width="49%" alt="AppToggle en thème clair">
</p>

## Fonctionnalités

- **Plusieurs raccourcis**, chacun avec sa touche et son interrupteur marche/arrêt.
- **Choix de l'application sans rien taper** : sélection parmi les fenêtres ouvertes. AppToggle détecte seul s'il s'agit d'une appli du Microsoft Store ou d'un programme classique. On peut aussi choisir un `.exe` à la main.
- **Capture de la touche au clavier** : on appuie sur la combinaison voulue. La touche Copilot est reconnue.
- **Bascule intelligente** : l'appli est lancée si elle est fermée, restaurée si elle est réduite, ramenée au premier plan si elle est cachée derrière d'autres fenêtres, réduite si elle est déjà devant.
- **État visible** : icône colorée près de l'horloge quand AppToggle est actif, grise quand il est en pause.
- **Français et anglais** : la langue suit celle de Windows, ou se choisit dans les options.
- **Suit le thème de Windows** (sombre ou clair) et sa couleur d'accent.
- **Léger** : un dossier d'environ 1,4 Mo, moins de 2 Mo de mémoire active en arrière-plan, aucune activité du processeur tant qu'on n'appuie pas sur une touche.
- **Portable et hors ligne** : la configuration est enregistrée dans `config.ini`, à côté de l'exécutable. Rien dans le registre, aucune donnée collectée, aucune connexion Internet.

## Installation

1. Télécharger `AppToggle-x.y.z.zip` depuis la [dernière version publiée](https://github.com/RobinsanKiritheepan/AppToggle/releases/latest).
2. Extraire le zip : il contient un dossier `AppToggle`. Le ranger dans un dossier à toi où il restera (par exemple `Documents`), pas dans Téléchargements.
3. Ouvrir le dossier et double-cliquer sur `AppToggle.exe` : la fenêtre de réglages s'ouvre. Garde tous les fichiers du dossier ensemble.

### Pourquoi `AppToggle.exe` est AutoHotkey

`AppToggle.exe` est l'interpréteur officiel [AutoHotkey v2](https://www.autohotkey.com), **non modifié**, simplement renommé : il lance tout seul `AppToggle.ahk`, placé à côté de lui. Ce choix permet de fonctionner avec le **Contrôle intelligent des applications** de Windows 11, qui bloque les exécutables non signés qu'il ne connaît pas, alors qu'il reconnaît l'interpréteur officiel. Conséquence : dans le Gestionnaire des tâches et les propriétés du fichier, AppToggle apparaît sous le nom « AutoHotkey ».

L'empreinte SHA-256 publiée avec chaque release permet de vérifier que `AppToggle.exe` est bien l'interpréteur officiel, et tout le reste est du code lisible (`.ahk`). Si Windows affiche malgré tout « Windows a protégé votre ordinateur », cliquer sur **Informations complémentaires**, puis sur **Exécuter quand même**.

## Utilisation

1. Ouvrir l'application voulue (Claude, ChatGPT, Discord…).
2. Dans AppToggle, cliquer sur **Ajouter**, puis sur **Choisir une appli ouverte**, et la sélectionner.
3. Cliquer sur **Changer** et appuyer sur la combinaison de touches voulue, ou sur **Utiliser la touche Copilot**.
4. Cliquer sur **Enregistrer**.

<p align="center">
  <img src="docs/choix-appli.png" width="45%" alt="Choisir une appli ouverte">
  <img src="docs/capture-touche.png" width="47%" alt="Choisir la touche au clavier">
</p>

Activer **Lancer avec Windows** pour qu'AppToggle démarre avec le PC. Un clic sur l'icône près de l'horloge rouvre les réglages ; le clic droit donne accès à Actif, Lancer avec Windows et Quitter.

Pour ne pas empêcher d'écrire normalement, une combinaison doit contenir Ctrl, Alt ou Win (sauf les touches spéciales comme F13 à F24 ou les touches multimédia).

## Sécurité et vie privée

AppToggle ne se connecte jamais à Internet, ne collecte aucune donnée et n'a pas besoin des droits administrateur. Pour reconnaître certaines touches (dont la touche Copilot), il utilise un crochet clavier de Windows, mais n'enregistre ni n'envoie aucune frappe. Tous les détails, les bonnes pratiques et la façon de signaler une faille sont dans [SECURITY.md](SECURITY.md).

## Construire la version à partager

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
```

Le script télécharge une seule fois la version officielle d'AutoHotkey dans `tools\` (sans droits administrateur) et vérifie son empreinte SHA-256. Il assemble ensuite `dist\AppToggle\` (l'interpréteur renommé, les scripts, les icônes et les licences) et contrôle la syntaxe. Enfin, il prépare les fichiers d'une release : le zip, les empreintes SHA-256 et le code source d'AutoHotkey correspondant. Il n'y a rien à compiler. Pour lancer directement depuis le code, avec [AutoHotkey v2](https://www.autohotkey.com) installé, il suffit de double-cliquer sur `src\AppToggle.ahk`.

## Structure du projet

| Fichier | Rôle |
|---|---|
| `src/AppToggle.ahk` | Point d'entrée : démarrage, instance unique, informations de l'exécutable |
| `src/lib/Engine.ahk` | Relie les touches aux applis ; ouvrir, ramener ou réduire |
| `src/lib/Config.ahk` | Lecture et écriture de `config.ini` |
| `src/lib/Keys.ahk` | Noms des touches et capture d'une combinaison |
| `src/lib/Lang.ahk` | Traductions français / anglais |
| `src/lib/Tray.ahk` | Icône près de l'horloge, menu, lancement avec Windows |
| `src/lib/Theme.ahk` | Couleurs, polices, mode sombre ou clair |
| `src/lib/Draw.ahk` | Dessin des éléments avec GDI+ : cartes, interrupteurs, boutons, touches |
| `src/ui/` | Les fenêtres : réglages, ajout ou modification, choix d'une appli |
| `tools/make-icons.ps1` | Génère les icônes du dossier `assets` |
| `build.ps1` | Assemblage de la version à partager et fichiers de release |

## Format de `config.ini`

Le fichier est créé au premier lancement. Il se modifie depuis la fenêtre de réglages, mais reste lisible :

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

- `Langue` : `auto` (langue de Windows), `fr` ou `en`.
- `Touche` suit la syntaxe AutoHotkey : `^` Ctrl, `!` Alt, `+` Maj, `#` Win. La touche Copilot correspond à `+#F23`.
- `Type=store` : `Cible` est l'identifiant de l'appli du Microsoft Store (`Get-StartApps` dans PowerShell le donne). `Type=exe` : `Cible` est le chemin complet du programme.
- `Processus` sert à retrouver la fenêtre de l'appli ; `Titre` (facultatif) filtre sur un morceau du titre.

## Licences et mentions

- **Le code d'AppToggle** (scripts, icônes, documentation) est distribué sous licence MIT : voir [LICENSE](LICENSE).
- **`AppToggle.exe`** est l'interpréteur [AutoHotkey v2](https://github.com/AutoHotkey/AutoHotkey) officiel, non modifié, distribué sous licence GNU GPL v2 (il inclut la bibliothèque PCRE, sous licence BSD). Chaque release fournit sa licence (`LICENCE-AutoHotkey.txt`, dans le dossier) et le code source d'AutoHotkey correspondant à la version utilisée.
- Windows et Copilot sont des marques de Microsoft ; Claude est une marque d'Anthropic ; ChatGPT et Codex sont des marques d'OpenAI. AppToggle est un projet indépendant, sans lien avec ces sociétés ni approuvé par elles. Les captures d'écran utilisent des applis de démonstration.
