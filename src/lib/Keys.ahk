; Touches : noms lisibles (« Ctrl », « Maj »…) et capture d'une combinaison au clavier.
; Format AutoHotkey : ^ = Ctrl, ! = Alt, + = Maj, # = Win, puis la touche. Ex. « ^!c » = Ctrl + Alt + C.

class Keys {
    ; La touche Copilot des claviers récents envoie en réalité Win + Maj + F23
    static Copilot := "+#F23"

    static Split(hk) {
        RegExMatch(hk, "^([\^!+#<>*~$]*)(.*)$", &m)
        return {mods: m[1], key: m[2]}
    }

    ; Remet les modificateurs toujours dans le même ordre (^!+#) pour pouvoir comparer deux touches
    static Normalize(hk) {
        if hk = ""
            return ""
        p := this.Split(hk), mods := ""
        for sym in ["^", "!", "+", "#"]
            if InStr(p.mods, sym)
                mods .= sym
        return mods p.key
    }

    static Labels(hk) {
        if hk = ""
            return []
        if hk = this.Copilot
            return [Tr("Touche Copilot")]
        if StrLower(hk) = "+vkdf"
            return ["§"]
        p := this.Split(hk), out := []
        for pair in [["#", "Win"], ["^", "Ctrl"], ["!", "Alt"], ["+", Tr("Maj")]]
            if InStr(p.mods, pair[1])
                out.Push(pair[2])
        out.Push(this.KeyLabel(p.key))
        return out
    }

    static Text(hk) {
        s := ""
        for i, lab in this.Labels(hk)
            s .= (i > 1 ? " + " : "") lab
        return s = "" ? Tr("Aucune touche") : s
    }

    static KeyLabel(key) {
        names := this.Names()
        if names.Has(key)
            return names[key]
        if key ~= "i)^vk[0-9a-f]{2}$"
            return (n := GetKeyName(key)) != "" ? StrUpper(n) : key
        if key ~= "i)^Numpad"
            return Tr("Pavé {1}", SubStr(key, 7))
        return StrLen(key) = 1 ? StrUpper(key) : key
    }

    ; Noms des touches spéciales dans la langue de l'interface
    static Names() {
        static cache := Map()
        if cache.Has(Lang.code)
            return cache[Lang.code]
        m := Map(), m.CaseSense := "Off"
        if Lang.code = "en"
            m.Set("Space", "Space", "Enter", "Enter", "Tab", "Tab", "Backspace", "Backspace", "Delete", "Del"
                , "Insert", "Ins", "Home", "Home", "End", "End", "PgUp", "Page Up", "PgDn", "Page Down"
                , "Up", "Up", "Down", "Down", "Left", "Left", "Right", "Right", "PrintScreen", "Print Screen"
                , "Pause", "Pause", "ScrollLock", "Scroll Lock", "CapsLock", "Caps Lock", "NumLock", "Num Lock"
                , "AppsKey", "Menu", "Escape", "Esc", "Media_Play_Pause", "Play/Pause", "Media_Next", "Next track"
                , "Media_Prev", "Previous track", "Media_Stop", "Stop", "Volume_Mute", "Mute", "Volume_Up", "Volume +"
                , "Volume_Down", "Volume -")
        else
            m.Set("Space", "Espace", "Enter", "Entrée", "Tab", "Tab", "Backspace", "Retour", "Delete", "Suppr"
                , "Insert", "Inser", "Home", "Début", "End", "Fin", "PgUp", "Page préc.", "PgDn", "Page suiv."
                , "Up", "Haut", "Down", "Bas", "Left", "Gauche", "Right", "Droite", "PrintScreen", "Impr. écran"
                , "Pause", "Pause", "ScrollLock", "Arrêt défil.", "CapsLock", "Verr. Maj", "NumLock", "Verr. Num"
                , "AppsKey", "Menu", "Escape", "Échap", "Media_Play_Pause", "Lecture", "Media_Next", "Piste suiv."
                , "Media_Prev", "Piste préc.", "Media_Stop", "Stop", "Volume_Mute", "Muet", "Volume_Up", "Volume +"
                , "Volume_Down", "Volume -")
        return cache[Lang.code] := m
    }

    ; Nom AutoHotkey d'une touche pressée (lettres et touches spéciales par leur nom, le reste par code « vkXX »)
    static NameFor(vk, sc) {
        name := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
        if name ~= "i)^[a-z0-9]$"
            return StrLower(name)
        if name ~= "i)^(F\d{1,2}|Space|Enter|Tab|Backspace|Delete|Insert|Home|End|PgUp|PgDn|Up|Down|Left|Right|PrintScreen|Pause|ScrollLock|CapsLock|NumLock|AppsKey|Numpad\w+|Media_\w+|Volume_\w+|Browser_\w+|Launch_\w+)$"
            return name
        return Format("vk{:02X}", vk)
    }

    ; Refuse les combinaisons qui empêcheraient de taper normalement. Renvoie "" si c'est bon.
    static Problem(hk) {
        if StrLower(hk) = "+vkdf"
            return ""
        p := this.Split(hk)
        alone := p.key ~= "i)^(F\d{1,2}|Pause|ScrollLock|AppsKey|PrintScreen|Insert|Media_\w+|Volume_\w+|Browser_\w+|Launch_\w+)$"
        if alone
            return ""
        if p.mods = ""
            return Tr("Ajoute Ctrl, Alt ou Win : seule, cette touche t'empêcherait d'écrire normalement.")
        if p.mods = "+"
            return Tr("Maj seule ne suffit pas (Maj + lettre sert à écrire en majuscule). Ajoute Ctrl, Alt ou Win.")
        return ""
    }
}

; Écoute le clavier jusqu'à ce qu'une combinaison complète soit pressée puis relâchée.
; Pendant la capture, les touches sont bloquées (rien n'arrive aux autres applis) et les raccourcis sont en pause.
; Rien n'est enregistré : seule la combinaison choisie est gardée.
class KeyCapture {
    static ih := "", done := "", down := Map(), result := ""
    static Mods := [["^", [0x11, 0xA2, 0xA3]], ["!", [0x12, 0xA4, 0xA5]], ["+", [0x10, 0xA0, 0xA1]], ["#", [0x5B, 0x5C]]]

    static Active => this.ih != ""

    static Start(onDone) {
        if this.ih
            this.Cancel(false)
        Engine.Pause(true)
        this.done := onDone, this.down := Map(), this.result := ""
        ih := InputHook("L0 T15")
        ih.KeyOpt("{All}", "NS")
        ih.OnKeyDown := ObjBindMethod(this, "OnDown")
        ih.OnKeyUp := ObjBindMethod(this, "OnUp")
        ih.OnEnd := ObjBindMethod(this, "OnEnd")
        this.ih := ih
        ih.Start()
    }

    static Cancel(notify := true) {
        if !this.ih
            return
        if !notify
            this.done := ""
        this.result := "cancel"
        this.ih.Stop()
    }

    static IsModifier(vk) {
        for pair in this.Mods
            for v in pair[2]
                if v = vk
                    return true
        return false
    }

    static OnDown(ih, vk, sc) {
        this.down[vk] := true
        if this.result != "" || this.IsModifier(vk)
            return
        mods := ""
        for pair in this.Mods
            for v in pair[2]
                if this.down.Has(v) {
                    mods .= pair[1]
                    break
                }
        this.result := (vk = 0x1B && mods = "") ? "cancel" : mods Keys.NameFor(vk, sc)
        this.Finish()
    }

    static OnUp(ih, vk, sc) {
        if this.down.Has(vk)
            this.down.Delete(vk)
        this.Finish()
    }

    ; On attend que tout soit relâché avant de rendre la main, sinon la fin de la combinaison fuiterait vers Windows
    static Finish() {
        if this.result != "" && !this.down.Count
            this.ih.Stop()
    }

    static OnEnd(ih) {
        res := this.result, reason := ih.EndReason, cb := this.done
        this.ih := "", this.done := "", this.down := Map(), this.result := ""
        Engine.Pause(false)
        if !cb
            return
        if reason = "Timeout"
            cb.Call("", "timeout")
        else if res = "" || res = "cancel"
            cb.Call("", "cancel")
        else
            cb.Call(res, "")
    }
}
