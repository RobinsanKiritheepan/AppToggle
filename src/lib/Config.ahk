; Lecture et écriture de config.ini, rangé à côté de l'exe (version portable : rien dans le registre).
; Le fichier est en UTF-16 : c'est le seul encodage que Windows lit correctement avec les accents dans un .ini.

class Entry {
    name := "", key := "", type := "exe", target := "", process := "", title := "", enabled := true
    hwnd := 0, launchedAt := 0, error := ""

    ; Ce qui identifie l'appli pour Windows : un id du Store ou le chemin d'un .exe
    ParsingName => this.type = "store" ? "shell:AppsFolder\" this.target : this.target
    TypeLabel => this.type = "store" ? "Microsoft Store" : Tr("Programme")
}

class Config {
    static path := A_ScriptDir "\config.ini"
    static entries := [], active := true, notify := true, hintShown := false, lang := "auto"

    static Load() {
        this.entries := []
        if !FileExist(this.path)
            return this.Save()
        if this.MigrateV1()
            return
        this.active := IniRead(this.path, "General", "Actif", 1) = 1
        this.notify := IniRead(this.path, "General", "Notification", 1) = 1
        this.hintShown := IniRead(this.path, "General", "AstuceVue", 0) = 1
        this.lang := IniRead(this.path, "General", "Langue", "auto")
        if !(this.lang ~= "^(auto|fr|en)$")
            this.lang := "auto"
        for sec in StrSplit(IniRead(this.path), "`n") {
            if !(sec ~= "i)^Raccourci\d+$")
                continue
            e := Entry()
            e.name := IniRead(this.path, sec, "Nom", "")
            e.key := Keys.Normalize(IniRead(this.path, sec, "Touche", ""))
            e.type := IniRead(this.path, sec, "Type", "exe") = "store" ? "store" : "exe"
            e.target := RegExReplace(IniRead(this.path, sec, "Cible", ""), "i)^shell:AppsFolder\\")
            e.process := IniRead(this.path, sec, "Processus", "")
            e.title := IniRead(this.path, sec, "Titre", "")
            e.enabled := IniRead(this.path, sec, "Actif", 1) = 1
            if e.target != "" && e.process != "" {
                if e.name = ""
                    e.name := RegExReplace(e.process, "i)\.exe$")
                this.entries.Push(e)
            }
        }
    }

    static Save() {
        t := "; " Tr("Configuration d'AppToggle. Le plus simple est de la modifier depuis la fenêtre de réglages.") "`r`n"
        t .= "[General]`r`nActif=" (this.active ? 1 : 0) "`r`nNotification=" (this.notify ? 1 : 0)
        t .= "`r`nAstuceVue=" (this.hintShown ? 1 : 0) "`r`nLangue=" this.lang "`r`n"
        for i, e in this.entries {
            t .= "`r`n[Raccourci" i "]`r`nNom=" e.name "`r`nTouche=" e.key "`r`nType=" e.type
            t .= "`r`nCible=" e.target "`r`nProcessus=" e.process "`r`nTitre=" e.title
            t .= "`r`nActif=" (e.enabled ? 1 : 0) "`r`n"
        }
        try {
            f := FileOpen(this.path, "w", "UTF-16")
            f.Write(t)
            f.Close()
        } catch {
            Tray.Notify(Tr("Impossible d'enregistrer les réglages"), Tr("Le dossier d'AppToggle est peut-être en lecture seule."), "Iconx")
        }
    }

    ; Ancien format (version 1, une seule appli dans [App]) -> nouveau format
    static MigrateV1() {
        target := IniRead(this.path, "App", "Cible", "")
        if target = ""
            return false
        e := Entry()
        e.name := IniRead(this.path, "App", "Nom", "Application")
        e.type := IniRead(this.path, "App", "Type", "exe") = "store" ? "store" : "exe"
        e.target := RegExReplace(target, "i)^shell:AppsFolder\\")
        e.process := IniRead(this.path, "App", "Process", "")
        e.title := IniRead(this.path, "App", "Titre", "")
        e.key := Keys.Normalize(IniRead(this.path, "Touche", "Combo", Keys.Copilot))
        if e.process != ""
            this.entries.Push(e)
        this.Save()
        return true
    }
}
