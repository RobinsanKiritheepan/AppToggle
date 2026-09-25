; Le cœur d'AppToggle : chaque touche est reliée à une appli.
; Appui sur la touche : appli fermée -> on la lance ; réduite -> on la restaure ;
; ouverte mais derrière d'autres fenêtres -> on la ramène devant ; déjà devant -> on la réduit.

class Engine {
    static bound := Map(), paused := false

    ; (Ré)enregistre tous les raccourcis d'après la configuration
    static Apply() {
        for hk in this.bound
            try Hotkey(hk, "Off")
        this.bound := Map()
        for e in Config.entries
            e.error := ""
        if !Config.active || this.paused
            return
        for e in Config.entries {
            if !e.enabled
                continue
            if e.key = "" {
                e.error := Tr("Aucune touche choisie")
                continue
            }
            if this.bound.Has(e.key) {
                e.error := Tr("Touche déjà utilisée par « {1} »", this.bound[e.key].name)
                continue
            }
            try {
                Hotkey(e.key, ObjBindMethod(this, "Handle", e), "On")
                this.bound[e.key] := e
            } catch
                e.error := Tr("Touche non reconnue par Windows")
        }
    }

    ; Pause temporaire (pendant qu'on choisit une nouvelle touche)
    static Pause(on) {
        this.paused := on
        this.Apply()
    }

    static Handle(e, *) {
        try this.Toggle(e)
        finally KeyWait(Keys.Split(e.key).key)
    }

    static Toggle(e, *) {
        if e.behavior = "command" {
            if !e.launchedAt || A_TickCount - e.launchedAt > 250 {
                e.launchedAt := A_TickCount
                this.Launch(e)
            }
            return
        }
        hwnd := this.FindWindow(e)
        if !hwnd {
            ; évite de lancer l'appli deux fois si on appuie pendant qu'elle démarre
            if !e.launchedAt || A_TickCount - e.launchedAt > 4000 {
                e.launchedAt := A_TickCount
                this.Launch(e)
            }
            return
        }
        ; On teste « réduite » en premier : certaines applis se disent encore actives une fois réduites
        if WinGetMinMax(hwnd) = -1 {
            DllCall("ShowWindow", "ptr", hwnd, "int", 9)      ; SW_RESTORE
            WinActivate(hwnd)
        } else if this.IsForeground(e, hwnd)
            WinMinimize(hwnd)
        else
            WinActivate(hwnd)
    }

    static IsForeground(e, hwnd) {
        fg := DllCall("GetForegroundWindow", "ptr")
        if fg = hwnd
            return true
        try return fg && DllCall("GetAncestor", "ptr", fg, "uint", 3, "ptr") = hwnd
        return false
    }

    static Launch(e) {
        try {
            if e.type = "store"
                Run("shell:AppsFolder\" e.target)
            else {
                target := e.target
                if !RegExMatch(target, "i)^(?:[A-Z]:[\\/]|\\\\)")
                    target := A_ScriptDir "\" target
                SplitPath(target, , &dir)
                Run('"' target '"' (e.args != "" ? " " e.args : ""), e.workdir != "" ? e.workdir : dir)
            }
        } catch
            Tray.Notify(Tr("Impossible d'ouvrir « {1} »", e.name), Tr("Vérifie cette appli dans les réglages d'AppToggle."), "Iconx")
    }

    ; La fenêtre principale de l'appli (la plus haute à l'écran), ou 0 si elle n'est pas ouverte
    static FindWindow(e) {
        try {
            if e.hwnd && WinExist(e.hwnd) && this.IsMainWindow(e.hwnd)
                && WinGetProcessName(e.hwnd) = e.process
                && (e.title = "" || InStr(WinGetTitle(e.hwnd), e.title))
                return e.hwnd
        }
        e.hwnd := 0
        try list := WinGetList("ahk_exe " e.process)
        catch
            return 0
        for hwnd in list {
            if !this.IsMainWindow(hwnd)
                continue
            if e.title != "" && !InStr(WinGetTitle(hwnd), e.title)
                continue
            return e.hwnd := hwnd
        }
        return 0
    }

    ; Écarte les fenêtres « techniques » : barres d'outils, popups, fenêtres sans titre ou masquées par Windows
    static IsMainWindow(hwnd) {
        try {
            if WinGetExStyle(hwnd) & 0x80                           ; WS_EX_TOOLWINDOW
                return false
            if DllCall("GetWindow", "ptr", hwnd, "uint", 4, "ptr")   ; GW_OWNER : boîte de dialogue d'une autre fenêtre
                return false
            if WinGetTitle(hwnd) = ""
                return false
            cloaked := 0
            DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 14, "int*", &cloaked, "uint", 4)  ; DWMWA_CLOAKED
            return !cloaked
        }
        return false
    }
}
