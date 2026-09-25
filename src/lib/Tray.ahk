; Icône près de l'horloge (colorée = actif, grise = en pause), son menu, et le lancement avec Windows.

class Tray {
    static Init() {
        this.DarkMenus()
        m := A_TrayMenu
        m.Delete()
        m.Add("Ouvrir les réglages", (*) => Settings.Show())
        m.Add()
        m.Add("Actif", (*) => App.SetActive(!Config.active))
        m.Add("Lancer avec Windows", (*) => (Startup.Set(!Startup.IsOn()), Tray.Update(), Settings.Refresh()))
        m.Add()
        m.Add("Quitter AppToggle", (*) => ExitApp())
        m.Default := "Ouvrir les réglages"
        m.ClickCount := 1
        this.Update()
        A_IconHidden := false
    }

    static Update() {
        on := Config.active
        if A_IsCompiled
            TraySetIcon(A_ScriptFullPath, on ? -159 : -250)     ; icônes intégrées à l'exe (voir AppToggle.ahk)
        else
            TraySetIcon(A_ScriptDir "\..\assets\" (on ? "icon.ico" : "icon-off.ico"))
        n := 0
        for e in Config.entries
            n += e.enabled && e.error = ""
        A_IconTip := on ? "AppToggle — actif (" n " raccourci" (n > 1 ? "s" : "") ")" : "AppToggle — en pause"
        on ? A_TrayMenu.Check("Actif") : A_TrayMenu.Uncheck("Actif")
        Startup.IsOn() ? A_TrayMenu.Check("Lancer avec Windows") : A_TrayMenu.Uncheck("Lancer avec Windows")
    }

    static Notify(title, text, opts := "") => TrayTip(text, title, opts)

    ; Petit message au démarrage de Windows : rappelle quelles touches sont prêtes
    static Greet() {
        if !Config.active
            return this.Notify("AppToggle est en pause", "Clique sur son icône près de l'horloge pour le réactiver.")
        lines := "", count := 0
        for e in Config.entries
            if e.enabled && e.error = "" && count < 3
                lines .= (count++ ? "`n" : "") Keys.Text(e.key) "  →  " e.name
        this.Notify("AppToggle est prêt", lines != "" ? lines : "Ouvre les réglages pour ajouter un raccourci.")
    }

    ; Menus sombres quand Windows est en mode sombre (fonctions non documentées d'uxtheme, Windows 10 1903+)
    static DarkMenus() {
        if VerCompare(A_OSVersion, "10.0.18362") < 0
            return
        ux := DllCall("LoadLibrary", "str", "uxtheme", "ptr")
        DllCall(DllCall("GetProcAddress", "ptr", ux, "ptr", 135, "ptr"), "int", 1)   ; SetPreferredAppMode(AllowDark)
        DllCall(DllCall("GetProcAddress", "ptr", ux, "ptr", 136, "ptr"))             ; FlushMenuThemes
    }
}

; « Lancer avec Windows » = un raccourci dans le dossier Démarrage de l'utilisateur (rien de caché)
class Startup {
    static Link => A_Startup "\AppToggle.lnk"
    static Target => A_IsCompiled ? A_ScriptFullPath : A_AhkPath
    static Args => A_IsCompiled ? "/startup" : '"' A_ScriptFullPath '" /startup'

    static IsOn() => FileExist(this.Link) != ""

    static Set(on) {
        try {
            if on
                FileCreateShortcut(this.Target, this.Link, A_ScriptDir, this.Args, "AppToggle : ouvre et réduit tes applis avec une touche")
            else if this.IsOn()
                FileDelete(this.Link)
        } catch
            Tray.Notify("Impossible de modifier le démarrage automatique", "Vérifie les droits sur le dossier Démarrage.", "Iconx")
    }

    ; Si l'exe a été déplacé, le raccourci de démarrage est remis à jour
    static Repair() {
        if !this.IsOn()
            return
        try {
            FileGetShortcut(this.Link, &target, , &args)
            if target != this.Target || args != this.Args
                this.Set(true)
        }
    }
}
