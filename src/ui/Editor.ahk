; Fenêtre « Nouveau raccourci / Modifier le raccourci ».
; On travaille sur une copie (draft) : rien n'est modifié tant qu'on n'a pas cliqué sur Enregistrer.

class Editor {
    static gui := "", draft := "", orig := "", msg := ""
    static capturing := false, advanced := false, confirmDel := false
    static W := 480, M := 24

    static Open(e := "") {
        if !Settings.gui
            return
        this.Close()
        this.orig := e
        this.draft := e ? e.Clone() : Entry()
        if !e && !this.KeyUsedBy(Keys.Copilot)
            this.draft.key := Keys.Copilot
        this.msg := "", this.capturing := false, this.advanced := false, this.confirmDel := false
        this.Build()
    }

    static Rebuild() {
        if this.gui
            this.Build()
    }

    static Build() {
        T := Theme, W := this.W, M := this.M, cw := W - 2 * M, d := this.draft
        old := this.gui
        hasApp := d.target != "" && d.process != ""

        yApp := 92, hApp := 120
        yLblKey := yApp + hApp + 20, yKey := yLblKey + 30, hKey := 100
        y := yKey + hKey + 10
        yMsg := y
        if this.msg != ""
            y += 30
        yAdv := y
        yAdvCard := yAdv + 32, hAdvCard := 3 * 56 + 14
        yBtn := (this.advanced ? yAdvCard + hAdvCard : yAdv + 22) + 24
        H := yBtn + 32 + 20

        cv := Canvas(W, H, T.bg)
        cv.RoundRect(M, yApp, cw, hApp, 8, T.card, T.cardStroke)
        cv.RoundRect(M, yKey, cw, hKey, 8, T.card, T.cardStroke)
        if this.capturing
            cv.RoundRect(M + 12, yKey + 12, cw - 24 - 110 - 12, 40, 6, T.card, T.accent, 2)
        if this.advanced {
            cv.RoundRect(M, yAdvCard, cw, hAdvCard, 8, T.card, T.cardStroke)
            Loop 3
                cv.RoundRect(M + 146, yAdvCard + 12 + (A_Index - 1) * 56, cw - 162, 34, 4, T.field, T.fieldStroke)
        }

        title := this.orig ? Tr("Modifier le raccourci") : Tr("Nouveau raccourci")
        g := UI.NewWindow(title, "-MinimizeBox +Owner" Settings.gui.Hwnd)
        g.OnEvent("Close", (*) => this.Close())
        g.OnEvent("Escape", (*) => this.Close())
        UI.Background(g, cv, W, H)
        UI.Text(g, title, M, 14, cw, 34, T.text, T.bg, 16, 600, , T.fontTitle)

        ; --- application ---
        UI.Text(g, Tr("Application"), M + 2, yApp - 30, 200, 26, T.text, T.bg, 10, 600)
        if hasApp {
            g.Add("Picture", Format("x{} y{} w40 h40", M + 16, yApp + 16), "HBITMAP:" Widgets.AppIcon(d, 40, T.card))
            UI.Text(g, d.name, M + 70, yApp + 14, cw - 86, 24, T.text, T.card, 11, 600)
            UI.Text(g, d.process " · " d.TypeLabel, M + 70, yApp + 38, cw - 86, 20, T.text3, T.card, 9)
        } else {
            g.Add("Picture", Format("x{} y{} w40 h40", M + 16, yApp + 16), "HBITMAP:" Widgets.Placeholder(40, T.card))
            UI.Text(g, Tr("Aucune application choisie"), M + 70, yApp + 14, cw - 86, 24, T.text, T.card, 11, 600)
            UI.Text(g, Tr("Ouvre ton appli, puis choisis-la dans la liste"), M + 70, yApp + 38, cw - 86, 20, T.text3, T.card, 9)
        }
        UI.Button(g, Tr("Choisir une appli ouverte"), M + 16, yApp + 72, 222, hasApp ? "secondary" : "primary", T.card, (*) => this.PickOpen(), Chr(0xE71D))
        UI.Button(g, Tr("Parcourir…"), M + 16 + 222 + 8, yApp + 72, 126, "secondary", T.card, (*) => this.Browse(), Chr(0xE8B7))

        ; --- touche ---
        UI.Text(g, Tr("Touche"), M + 2, yLblKey, 200, 26, T.text, T.bg, 10, 600)
        if this.capturing {
            UI.Text(g, Tr("Appuie sur ta combinaison de touches…"), M + 26, yKey + 21, cw - 24 - 110 - 40, 22, T.accentText, T.card, 10)
            UI.Button(g, Tr("Annuler"), W - M - 16 - 110, yKey + 16, 110, "secondary", T.card, (*) => KeyCapture.Cancel())
            UI.Text(g, Tr("Échap pour annuler · Exemple : Ctrl + Alt + C"), M + 16, yKey + 64, cw - 32, 22, T.text3, T.card, 9)
        } else {
            kc := Widgets.Keycaps(Keys.Labels(d.key), T.card)
            if kc.w
                g.Add("Picture", Format("x{} y{} w{} h{}", M + 16, yKey + 19, kc.w, kc.h), "HBITMAP:" kc.hbm)
            else
                UI.Text(g, Tr("Aucune touche choisie"), M + 16, yKey + 18, 240, 30, T.text3, T.card, 10)
            UI.Button(g, Tr("Changer"), W - M - 16 - 110, yKey + 16, 110, "secondary", T.card, (*) => this.StartCapture(), Chr(0xE765))
            if d.key = Keys.Copilot
                UI.Text(g, Tr("La touche dédiée à côté de la barre d'espace, sur les claviers récents"), M + 16, yKey + 64, cw - 32, 22, T.text3, T.card, 9)
            else
                UI.Link(g, Tr("Utiliser la touche Copilot"), M + 16, yKey + 64, 220, T.card, (*) => this.SetKey(Keys.Copilot))
        }

        ; --- message d'erreur éventuel ---
        if this.msg != "" {
            UI.Text(g, Chr(0xE7BA), M + 4, yMsg + 2, 18, 20, T.danger, T.bg, 10, 400, , T.icons)
            UI.Text(g, this.msg, M + 26, yMsg, cw - 26, 24, T.danger, T.bg, 9)
        }

        ; --- réglages avancés (repliés par défaut) ---
        UI.Link(g, this.advanced ? Tr("Masquer les réglages avancés") : Tr("Afficher les réglages avancés"), M + 2, yAdv, 260, T.bg
            , (*) => (this.advanced := !this.advanced, UI.Later(() => this.Rebuild())))
        if this.advanced {
            fields := [[Tr("Nom affiché"), "name", Tr("Ex. Claude")], [Tr("Processus"), "process", Tr("Ex. claude.exe")], [Tr("Titre contient"), "title", Tr("Facultatif")]]
            for i, f in fields {
                fy := yAdvCard + 12 + (i - 1) * 56
                UI.Text(g, f[1], M + 16, fy, 124, 34, T.text, T.card, 10)
                ed := UI.Edit(g, M + 146, fy, cw - 162, d.%f[2]%)
                DllCall("SendMessage", "ptr", ed.Hwnd, "uint", 0x1501, "ptr", 1, "wstr", f[3])   ; EM_SETCUEBANNER
                ed.OnEvent("Change", ObjBindMethod(this, "OnField", f[2]))
            }
        }

        ; --- boutons ---
        UI.Button(g, Tr("Enregistrer"), W - M - 130, yBtn, 130, "primary", T.bg, (*) => this.Save())
        UI.Button(g, Tr("Annuler"), W - M - 130 - 8 - 110, yBtn, 110, "secondary", T.bg, (*) => this.Close())
        if this.orig
            UI.Button(g, this.confirmDel ? Tr("Confirmer") : Tr("Supprimer"), M, yBtn, 124, this.confirmDel ? "danger" : "subtle-danger", T.bg, (*) => this.Delete(), Chr(0xE74D))

        g.Show(Format("Hide w{} h{}", W, H))
        UI.WindowTheme(g)
        if old {
            WinGetPos(&x, &y, , , old.Hwnd)
            WinMove(x, y, , , g.Hwnd)
        } else
            UI.CenterOn(g, Settings.gui)
        g.Show()
        if old
            old.Destroy()
        else
            Settings.gui.Opt("+Disabled")
        this.gui := g
        Hover.Prune()
    }

    static OnField(prop, ctrl, *) => this.draft.%prop% := Trim(ctrl.Value)

    static KeyUsedBy(hk, except := "") {
        for e in Config.entries
            if e != except && e.key = hk
                return e
        return ""
    }

    static PickOpen() => Picker.Open(ObjBindMethod(this, "OnPicked"))

    static OnPicked(item) {
        d := this.draft
        d.name := item.name, d.type := item.type, d.target := item.target, d.process := item.process
        d.title := "", d.hwnd := 0, this.msg := ""
        UI.Later(() => this.Rebuild())
    }

    static Browse() {
        this.gui.Opt("+OwnDialogs")
        path := FileSelect(3, , Tr("Choisir le programme à ouvrir"), Tr("Programmes (*.exe)"))
        if path = ""
            return
        SplitPath(path, &file)
        d := this.draft
        d.type := "exe", d.target := path, d.process := file, d.title := "", d.hwnd := 0
        d.name := Picker.ExeName(path), this.msg := ""
        UI.Later(() => this.Rebuild())
    }

    static StartCapture() {
        this.capturing := true, this.msg := ""
        UI.Later(() => this.Rebuild())
        KeyCapture.Start(ObjBindMethod(this, "OnCaptured"))
    }

    static OnCaptured(hk, reason) {
        this.capturing := false
        if reason = "timeout"
            this.msg := Tr("Aucune touche détectée. Clique sur « Changer » pour réessayer.")
        else if hk != ""
            this.TrySetKey(hk)
        UI.Later(() => this.Rebuild())
    }

    static SetKey(hk) {
        this.TrySetKey(hk)
        UI.Later(() => this.Rebuild())
    }

    static TrySetKey(hk) {
        if (problem := Keys.Problem(hk)) != ""
            this.msg := problem
        else if (other := this.KeyUsedBy(hk, this.orig))
            this.msg := Tr("Cette touche est déjà utilisée par « {1} ».", other.name)
        else
            this.draft.key := hk, this.msg := ""
    }

    static Save() {
        d := this.draft
        if d.target = "" || d.process = ""
            this.msg := Tr("Choisis d'abord une application.")
        else if d.key = ""
            this.msg := Tr("Choisis une touche.")
        else if (other := this.KeyUsedBy(d.key, this.orig))
            this.msg := Tr("Cette touche est déjà utilisée par « {1} ».", other.name)
        else {
            if d.name = ""
                d.name := RegExReplace(d.process, "i)\.exe$")
            if this.orig {
                for prop in ["name", "key", "type", "target", "process", "title"]
                    this.orig.%prop% := d.%prop%
                this.orig.hwnd := 0
            } else {
                d.hwnd := 0, d.error := ""
                Config.entries.Push(d)
            }
            this.Commit()
            return
        }
        UI.Later(() => this.Rebuild())
    }

    ; Suppression en deux clics : « Supprimer » puis « Confirmer » (évite les erreurs)
    static Delete() {
        if !this.confirmDel {
            this.confirmDel := true
            UI.Later(() => this.Rebuild())
            SetTimer(ObjBindMethod(this, "ResetDelete"), -4000)
            return
        }
        for i, e in Config.entries
            if e = this.orig {
                Config.entries.RemoveAt(i)
                break
            }
        this.Commit()
    }

    static ResetDelete() {
        if this.gui && this.confirmDel {
            this.confirmDel := false
            this.Rebuild()
        }
    }

    static Commit() {
        Config.Save()
        Engine.Apply()
        Tray.Update()
        this.Close()
        Settings.Rebuild()
    }

    static Close() {
        if KeyCapture.Active
            KeyCapture.Cancel(false)
        Picker.Close()
        if this.gui {
            ; réactiver la fenêtre principale AVANT de fermer, sinon Windows la renvoie derrière les autres
            if Settings.gui
                Settings.gui.Opt("-Disabled")
            this.gui.Destroy()
            this.gui := ""
            if Settings.gui
                WinActivate(Settings.gui.Hwnd)
        }
        this.capturing := false
        Hover.Prune()
    }
}
