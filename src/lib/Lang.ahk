; Langue de l'interface : français ou anglais.
; Le texte français sert de clé ; Tr("texte") renvoie la traduction anglaise si l'anglais est choisi.
; Un texte sans traduction reste en français. Paramètres : Tr("Version {1}", "2.1.0").

Tr(fr, args*) => args.Length ? Format(Lang.Get(fr), args*) : Lang.Get(fr)

class Lang {
    static code := "fr"

    ; Config.lang : "auto" (langue de Windows), "fr" ou "en"
    static Init() {
        pref := Config.lang
        if pref != "fr" && pref != "en"
            pref := (DllCall("GetUserDefaultUILanguage", "ushort") & 0x3FF) = 0x0C ? "fr" : "en"   ; 0x0C = français
        this.code := pref
    }

    static Get(fr) => this.code = "en" && this.en.Has(fr) ? this.en[fr] : fr

    static en := Map(
        ; --- fenêtre principale ---
        "Ouvre et réduis tes applis avec une seule touche", "Open and minimize your apps with a single key",
        "AppToggle est actif", "AppToggle is on",
        "AppToggle est en pause", "AppToggle is paused",
        "Tes touches fonctionnent normalement, rien n'est intercepté", "Your keys work normally, nothing is intercepted",
        "{1} raccourci à vérifier", "{1} shortcut needs attention",
        "{1} raccourcis à vérifier", "{1} shortcuts need attention",
        "{1} raccourci prêt", "{1} shortcut ready",
        "{1} raccourcis prêts", "{1} shortcuts ready",
        "Ajoute un raccourci pour commencer", "Add a shortcut to get started",
        "Raccourcis", "Shortcuts",
        "Ajouter", "Add",
        "Aucun raccourci pour l'instant", "No shortcuts yet",
        "Ouvre l'appli que tu veux, puis clique sur « Ajouter »", "Open the app you want, then click “Add”",
        "Options", "Options",
        "Lancer avec Windows", "Start with Windows",
        "AppToggle démarre tout seul quand tu allumes le PC", "AppToggle starts automatically when you turn on your PC",
        "Géré par Windows : Paramètres > Applications > Démarrage", "Managed by Windows: Settings > Apps > Startup",
        "Notification au démarrage", "Startup notification",
        "Un petit message confirme qu'AppToggle est prêt", "A short message confirms that AppToggle is ready",
        "Langue", "Language",
        "« Automatique » suit la langue de Windows", "“Automatic” follows the Windows language",
        "Automatique", "Automatic",
        "Automatique (langue de Windows)", "Automatic (Windows language)",
        "Version {1} · Logiciel libre, licence MIT", "Version {1} · Free software, MIT license",
        "Code source sur GitHub", "Source code on GitHub",
        "Désactivé", "Off",
        "Programme", "Program",
        "AppToggle continue en arrière-plan", "AppToggle keeps running in the background",
        "Tes raccourcis restent actifs. Clique sur l'icône près de l'horloge pour revenir ici.", "Your shortcuts stay active. Click the icon near the clock to come back here.",
        ; --- ajout / modification d'un raccourci ---
        "Nouveau raccourci", "New shortcut",
        "Modifier le raccourci", "Edit shortcut",
        "Application", "App",
        "Aucune application choisie", "No app selected",
        "Ouvre ton appli, puis choisis-la dans la liste", "Open your app, then pick it from the list",
        "Choisir une appli ouverte", "Pick an open app",
        "Parcourir…", "Browse…",
        "Touche", "Key",
        "Appuie sur ta combinaison de touches…", "Press your key combination…",
        "Annuler", "Cancel",
        "Échap pour annuler · Exemple : Ctrl + Alt + C", "Esc to cancel · Example: Ctrl + Alt + C",
        "Aucune touche choisie", "No key selected",
        "Changer", "Change",
        "La touche dédiée à côté de la barre d'espace, sur les claviers récents", "The dedicated key next to the space bar on recent keyboards",
        "Utiliser la touche Copilot", "Use the Copilot key",
        "Afficher les réglages avancés", "Show advanced settings",
        "Masquer les réglages avancés", "Hide advanced settings",
        "Nom affiché", "Display name",
        "Processus", "Process",
        "Titre contient", "Title contains",
        "Ex. Claude", "e.g. Claude",
        "Ex. claude.exe", "e.g. claude.exe",
        "Facultatif", "Optional",
        "Enregistrer", "Save",
        "Supprimer", "Delete",
        "Confirmer", "Confirm",
        "Choisir le programme à ouvrir", "Choose the program to open",
        "Programmes (*.exe)", "Programs (*.exe)",
        "Aucune touche détectée. Clique sur « Changer » pour réessayer.", "No key detected. Click “Change” to try again.",
        "Cette touche est déjà utilisée par « {1} ».", "This key is already used by “{1}”.",
        "Choisis d'abord une application.", "Pick an app first.",
        "Choisis une touche.", "Choose a key.",
        ; --- choix d'une appli ouverte ---
        "Choisir une application", "Choose an app",
        "Ton appli n'est pas dans la liste ? Ouvre-la, puis clique sur Actualiser.", "Your app isn't listed? Open it, then click Refresh.",
        "Actualiser", "Refresh",
        "Choisir", "Select",
        ; --- touches ---
        "Touche Copilot", "Copilot key",
        "Maj", "Shift",
        "Aucune touche", "No key",
        "Pavé {1}", "Numpad {1}",
        "Ajoute Ctrl, Alt ou Win : seule, cette touche t'empêcherait d'écrire normalement.", "Add Ctrl, Alt or Win: on its own, this key would stop you from typing normally.",
        "Maj seule ne suffit pas (Maj + lettre sert à écrire en majuscule). Ajoute Ctrl, Alt ou Win.", "Shift alone isn't enough (Shift + letter types a capital letter). Add Ctrl, Alt or Win.",
        "Touche déjà utilisée par « {1} »", "Key already used by “{1}”",
        "Touche non reconnue par Windows", "Key not recognized by Windows",
        ; --- barre des tâches, notifications, erreurs ---
        "Ouvrir les réglages", "Open settings",
        "Actif", "Enabled",
        "Quitter AppToggle", "Quit AppToggle",
        "AppToggle — actif ({1} raccourci)", "AppToggle — on ({1} shortcut)",
        "AppToggle — actif ({1} raccourcis)", "AppToggle — on ({1} shortcuts)",
        "AppToggle — en pause", "AppToggle — paused",
        "Clique sur son icône près de l'horloge pour le réactiver.", "Click its icon near the clock to turn it back on.",
        "AppToggle est prêt", "AppToggle is ready",
        "Ouvre les réglages pour ajouter un raccourci.", "Open the settings to add a shortcut.",
        "AppToggle : ouvre et réduit tes applis avec une touche", "AppToggle: open and minimize your apps with one key",
        "Impossible de modifier le démarrage automatique", "Couldn't change the startup setting",
        "Vérifie les droits sur le dossier Démarrage.", "Check the permissions of the Startup folder.",
        "Impossible d'ouvrir « {1} »", "Couldn't open “{1}”",
        "Vérifie cette appli dans les réglages d'AppToggle.", "Check this app in AppToggle's settings.",
        "Configuration d'AppToggle. Le plus simple est de la modifier depuis la fenêtre de réglages.", "AppToggle settings. The easiest way to change them is the settings window.",
        "Impossible d'enregistrer les réglages", "Couldn't save the settings",
        "Le dossier d'AppToggle est peut-être en lecture seule.", "AppToggle's folder may be read-only.",
        "AppToggle a rencontré un problème", "AppToggle ran into a problem",
        "Les détails sont dans errors.log, à côté de l'application.", "Details are in errors.log, next to the app."
    )
}
