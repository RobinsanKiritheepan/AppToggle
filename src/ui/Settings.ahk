; Fenêtre principale : état d'AppToggle, liste des raccourcis, options.

class Settings {
    static gui := "", ctl := Map(), rows := Map(), scroll := 0, scrollMax := 0
    static W := 560, M := 24, RowH := 64

    static Show() {
        if this.gui {
            this.gui.Show()
            return
        }
        this.Build()
    }

    static Rebuild() {
        if this.gui
            this.Build()
    }

    static Build() {
        Gdip.Start()
        T := Theme, W := this.W, M := this.M, cw := W - 2 * M
        old := this.gui, n := Config.entries.Length

        ; --- mise en page (pixels logiques) ---
        yStatus := 82, hStatus := 76
        ySec1 := yStatus + hStatus + 22
        yList := ySec1 + 36, hList := n ? n * this.RowH : 100
        ySec2 := yList + hList + 22
        yOpt := ySec2 + 36, hOptRow := 60, hOpt := 2 * hOptRow
        yFoot := yOpt + hOpt + 16
        H := yFoot + 20 + 16

        ; --- fond : cartes arrondies et séparateurs ---
        cv := Canvas(W, H, T.bg)
        cv.RoundRect(M, yStatus, cw, hStatus, 8, T.card, T.cardStroke)
        cv.RoundRect(M, yList, cw, hList, 8, T.card, T.cardStroke)
        cv.RoundRect(M, yOpt, cw, hOpt, 8, T.card, T.cardStroke)
        Loop n - 1
            cv.Rect(M + 1, yList + A_Index * this.RowH, cw - 2, 1, T.divider)
        cv.Rect(M + 1, yOpt + hOptRow, cw - 2, 1, T.divider)

        g := UI.NewWindow("AppToggle")
        g.OnEvent("Close", (*) => this.Close())
        g.OnEvent("Escape", (*) => this.Close())
        UI.Background(g, cv, W, H)
        this.ctl := Map(), this.rows := Map()

        ; --- en-tête ---
        UI.Text(g, "AppToggle", M, 14, 400, 34, T.text, T.bg, 18, 600, , T.fontTitle)
        UI.Text(g, "Ouvre et réduis tes applis avec une seule touche", M + 1, 48, 480, 20, T.text2, T.bg, 10)

        ; --- état général ---
        this.ctl["logo"] := g.Add("Picture", Format("x{} y{} w40 h40", M + 18, yStatus + 18), "HBITMAP:" Widgets.Logo(40, Config.active, T.card))
        this.ctl["stTitle"] := UI.Text(g, "", M + 72, yStatus + 14, 330, 24, T.text, T.card, 11, 600)
        this.ctl["stSub"] := UI.Text(g, "", M + 72, yStatus + 38, 340, 22, T.text2, T.card, 9)
        this.ctl["master"] := UI.Switch(g, W - M - 18 - 40, yStatus + 28, T.card, () => Config.active, (v) => App.SetActive(v))

        ; --- raccourcis ---
        UI.Text(g, "Raccourcis", M + 2, ySec1, 200, 28, T.text, T.bg, 10, 600)
        UI.Button(g, "Ajouter", W - M - 112, ySec1 - 2, 112, "secondary", T.bg, (*) => Editor.Open(), Chr(0xE710))
        for i, e in Config.entries
            this.AddRow(g, e, M, yList + (i - 1) * this.RowH, cw)
        if !n {
            UI.Text(g, "Aucun raccourci pour l'instant", M + 1, yList + 24, cw - 2, 24, T.text, T.card, 10, 600, "Center")
            UI.Text(g, "Ouvre l'appli que tu veux, puis clique sur « Ajouter »", M + 1, yList + 50, cw - 2, 22, T.text3, T.card, 9, 400, "Center")
        }

        ; --- options ---
        UI.Text(g, "Options", M + 2, ySec2, 200, 28, T.text, T.bg, 10, 600)
        this.AddOption(g, yOpt, "startup", "Lancer avec Windows", "AppToggle démarre tout seul quand tu allumes le PC"
            , () => Startup.IsOn(), (v) => (Startup.Set(v), Tray.Update()))
        this.AddOption(g, yOpt + hOptRow, "notify", "Notification au démarrage", "Un petit message confirme qu'AppToggle est prêt"
            , () => Config.notify, (v) => (Config.notify := v, Config.Save()))

        ; --- pied de page ---
        UI.Text(g, "Version " App.Version " · Logiciel libre, licence MIT", M + 2, yFoot, 300, 20, T.text3, T.bg, 9)
        UI.Link(g, "Code source sur GitHub", W - M - 200, yFoot - 1, 198, T.bg, (*) => Run(App.RepoUrl), "Right")

        ; --- affichage : si l'écran est trop petit, la fenêtre défile ---
        MonitorGetWorkArea(old ? UI.MonitorOf(old.Hwnd) : MonitorGetPrimary(), , &top, , &bottom)
        maxH := Floor((bottom - top) / T.s) - 60
        viewH := Min(H, maxH)
        this.scroll := 0, this.scrollMax := H - viewH, extraW := 0
        if this.scrollMax > 0 {
            g.Opt("+0x200000")                                  ; WS_VSCROLL
            extraW := Ceil(DllCall("GetSystemMetrics", "int", 2) / T.s)
            DllCall("uxtheme\SetWindowTheme", "ptr", g.Hwnd, "wstr", T.dark ? "DarkMode_Explorer" : "Explorer", "ptr", 0)
        }
        g.Show(Format("Hide w{} h{}", W + extraW, viewH))
        UI.WindowTheme(g)
        if this.scrollMax > 0
            this.SetScrollBar(g, H, viewH)
        if old {
            WinGetPos(&x, &y, , , old.Hwnd)
            WinMove(x, y, , , g.Hwnd)
        }
        g.Show()
        if old
            old.Destroy()
        this.gui := g
        this.Refresh()
        Hover.Prune()
    }

    static AddRow(g, e, x, y, w) {
        T := Theme, h := this.RowH
        g.Add("Picture", Format("x{} y{} w32 h32", x + 16, y + 16), "HBITMAP:" Widgets.AppIcon(e, 32, T.card))
        kc := Widgets.Keycaps(Keys.Labels(e.key), T.card)
        editX := x + w - 12 - 32
        swX := editX - 12 - 40
        kcX := swX - 18 - kc.w
        nameW := kcX - (x + 62) - 12
        r := {}
        r.name := UI.Text(g, e.name, x + 62, y + 11, nameW, 22, T.text, T.card, 10, 600)
        r.sub := UI.Text(g, "", x + 62, y + 33, nameW, 20, T.text3, T.card, 9)
        if kc.w
            g.Add("Picture", Format("x{} y{} w{} h{}", kcX, y + (h - kc.h) // 2, kc.w, kc.h), "HBITMAP:" kc.hbm)
        r.sw := UI.Switch(g, swX, y + (h - 20) // 2, T.card, () => e.enabled, (v) => this.SetEnabled(e, v))
        UI.IconButton(g, Chr(0xE70F), editX, y + (h - 32) // 2, T.card, T.text2, (*) => Editor.Open(e))
        r.name.OnEvent("Click", (*) => Editor.Open(e))
        Hover.Add(r.name, () => 0, () => 0)
        this.rows[e] := r
    }

    static AddOption(g, y, key, title, sub, get, set) {
        T := Theme, M := this.M
        UI.Text(g, title, M + 18, y + 9, 380, 22, T.text, T.card, 10)
        UI.Text(g, sub, M + 18, y + 31, 400, 18, T.text3, T.card, 9)
        this.ctl[key] := UI.Switch(g, this.W - M - 18 - 40, y + 20, T.card, get, set)
    }

    ; Met à jour l'affichage sans reconstruire la fenêtre
    static Refresh() {
        if !this.gui
            return
        T := Theme, on := Config.active, ready := 0, issues := 0
        for e in Config.entries {
            if !e.enabled
                continue
            if e.error = ""
                ready++
            else
                issues++
        }
        this.ctl["logo"].Value := "HBITMAP:" Widgets.Logo(40, on, T.card)
        this.ctl["stTitle"].Value := on ? "AppToggle est actif" : "AppToggle est en pause"
        this.ctl["stSub"].Value := !on ? "Tes touches fonctionnent normalement, rien n'est intercepté"
            : issues ? issues " raccourci" (issues > 1 ? "s" : "") " à vérifier"
            : ready ? ready " raccourci" (ready > 1 ? "s" : "") " prêt" (ready > 1 ? "s" : "")
            : "Ajoute un raccourci pour commencer"
        for e, r in this.rows {
            bad := on && e.enabled && e.error != ""
            r.name.SetFont("c" T.Hex(e.enabled ? T.text : T.text3))
            r.sub.SetFont("c" T.Hex(bad ? T.danger : T.text3))
            r.sub.Value := bad ? e.error : (e.enabled ? "" : "Désactivé · ") e.process " · " e.TypeLabel
            r.name.Redraw()
            UI.RedrawSwitch(r.sw)
        }
        for key in ["master", "startup", "notify"]
            UI.RedrawSwitch(this.ctl[key])
    }

    static SetEnabled(e, v) {
        e.enabled := v
        Config.Save()
        Engine.Apply()
        Tray.Update()
        this.Refresh()
    }

    static Close() {
        Editor.Close()
        if this.gui
            this.gui.Destroy()
        this.gui := "", this.ctl := Map(), this.rows := Map()
        Hover.Prune()
        UI.switchDraw := Map()
        Gdip.Stop()
        if !Config.hintShown {
            Config.hintShown := true
            Config.Save()
            Tray.Notify("AppToggle continue en arrière-plan", "Tes raccourcis restent actifs. Clique sur l'icône près de l'horloge pour revenir ici.")
        }
        App.TrimMemory()
    }

    ; --- défilement (seulement sur les petits écrans) ---
    static SetScrollBar(g, total, view) {
        s := Theme.s
        si := Buffer(28, 0)                                     ; SCROLLINFO
        NumPut("uint", 28, "uint", 0x7, "int", 0, "int", Round(total * s) - 1, "uint", Round(view * s), "int", 0, si)
        DllCall("SetScrollInfo", "ptr", g.Hwnd, "int", 1, "ptr", si, "int", 1)
        static hooked := false
        if !hooked {
            OnMessage(0x115, ObjBindMethod(this, "OnScroll"))   ; WM_VSCROLL
            OnMessage(0x20A, ObjBindMethod(this, "OnWheel"))    ; WM_MOUSEWHEEL
            hooked := true
        }
    }

    static ScrollTo(pos) {
        s := Theme.s, maxPx := Round(this.scrollMax * s)
        pos := Max(0, Min(maxPx, Round(pos)))
        dy := this.scroll - pos
        if !dy
            return
        this.scroll := pos
        DllCall("ScrollWindow", "ptr", this.gui.Hwnd, "int", 0, "int", dy, "ptr", 0, "ptr", 0)
        DllCall("SetScrollPos", "ptr", this.gui.Hwnd, "int", 1, "int", pos, "int", 1)
    }

    static OnScroll(wParam, lParam, msg, hwnd) {
        if !this.gui || hwnd != this.gui.Hwnd || this.scrollMax <= 0
            return
        step := Round(40 * Theme.s)
        switch wParam & 0xFFFF {
            case 0: this.ScrollTo(this.scroll - step)            ; SB_LINEUP
            case 1: this.ScrollTo(this.scroll + step)            ; SB_LINEDOWN
            case 2: this.ScrollTo(this.scroll - step * 5)        ; SB_PAGEUP
            case 3: this.ScrollTo(this.scroll + step * 5)        ; SB_PAGEDOWN
            case 4, 5: this.ScrollTo(wParam >> 16)               ; SB_THUMBTRACK / SB_THUMBPOSITION
        }
        return 0
    }

    static OnWheel(wParam, lParam, msg, hwnd) {
        if !this.gui || this.scrollMax <= 0
            return
        if hwnd != this.gui.Hwnd && DllCall("GetAncestor", "ptr", hwnd, "uint", 2, "ptr") != this.gui.Hwnd
            return
        delta := (wParam >> 16) & 0xFFFF
        delta := delta > 0x7FFF ? delta - 0x10000 : delta
        this.ScrollTo(this.scroll - delta / 120 * 60 * Theme.s)
        return 0
    }
}
