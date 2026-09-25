; Briques communes aux fenêtres : survol de la souris, boutons et interrupteurs dessinés,
; textes, champs de saisie, barre de titre sombre.

class Hover {
    static items := Map(), current := 0

    static Init() {
        OnMessage(0x200, ObjBindMethod(this, "OnMove"))       ; WM_MOUSEMOVE
        OnMessage(0x2A3, ObjBindMethod(this, "OnLeave"))      ; WM_MOUSELEAVE
        OnMessage(0x20, ObjBindMethod(this, "OnSetCursor"))   ; WM_SETCURSOR
    }

    static Add(ctrl, enter, leave) => this.items[ctrl.Hwnd] := {enter: enter, leave: leave}
    static IsOver(ctrl) => this.current = ctrl.Hwnd

    static OnMove(wParam, lParam, msg, hwnd) {
        if hwnd = this.current
            return
        this.Leave()
        if !this.items.Has(hwnd)
            return
        this.current := hwnd
        tme := Buffer(24, 0)                                  ; TRACKMOUSEEVENT : prévenir quand la souris sort
        NumPut("uint", 24, tme, 0), NumPut("uint", 2, tme, 4), NumPut("ptr", hwnd, tme, 8)
        DllCall("TrackMouseEvent", "ptr", tme)
        try this.items[hwnd].enter.Call()
    }

    static OnLeave(wParam, lParam, msg, hwnd) {
        if hwnd = this.current
            this.Leave()
    }

    static Leave() {
        h := this.current, this.current := 0
        if h && this.items.Has(h)
            try this.items[h].leave.Call()
    }

    ; Curseur « main » sur tout ce qui est cliquable
    static OnSetCursor(wParam, lParam, msg, hwnd) {
        if this.items.Has(wParam) {
            DllCall("SetCursor", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", 32649, "ptr"))
            return 1
        }
    }

    ; Oublie les contrôles des fenêtres fermées
    static Prune() {
        dead := []
        for hwnd in this.items
            if !DllCall("IsWindow", "ptr", hwnd)
                dead.Push(hwnd)
        for hwnd in dead
            this.items.Delete(hwnd)
        if this.current && !DllCall("IsWindow", "ptr", this.current)
            this.current := 0
        dead := []
        for hwnd in UI.switchDraw
            if !DllCall("IsWindow", "ptr", hwnd)
                dead.Push(hwnd)
        for hwnd in dead
            UI.switchDraw.Delete(hwnd)
    }
}

class UI {
    static switchDraw := Map()

    static Later(fn) => SetTimer(fn, -1)

    ; Texte sur une ligne, centré verticalement, avec « … » s'il est trop long
    static Text(g, str, x, y, w, h, color, bg, size := 10, weight := 400, extra := "", font := "") {
        g.SetFont(Format("norm s{} w{} c{}", size, weight, Theme.Hex(color)), font = "" ? Theme.font : font)
        return g.Add("Text", Format("x{} y{} w{} h{} +0x4200 Background{} {}", x, y, w, h, Theme.Hex(bg), extra), str)
    }

    static Button(g, text, x, y, w, style, bg, onClick, icon := "", iconAfter := false) {
        b := g.Add("Picture", Format("x{} y{} w{} h32", x, y, w), "HBITMAP:" Widgets.Button(text, w, style, false, bg, icon, iconAfter))
        b.OnEvent("Click", onClick)
        Hover.Add(b, () => b.Value := "HBITMAP:" Widgets.Button(text, w, style, true, bg, icon, iconAfter)
            , () => b.Value := "HBITMAP:" Widgets.Button(text, w, style, false, bg, icon, iconAfter))
        return b
    }

    static IconButton(g, glyph, x, y, bg, color, onClick) {
        b := g.Add("Picture", Format("x{} y{} w32 h32", x, y), "HBITMAP:" Widgets.IconButton(glyph, 32, false, bg, color))
        b.OnEvent("Click", onClick)
        Hover.Add(b, () => b.Value := "HBITMAP:" Widgets.IconButton(glyph, 32, true, bg, color)
            , () => b.Value := "HBITMAP:" Widgets.IconButton(glyph, 32, false, bg, color))
        return b
    }

    ; Interrupteur : get() lit l'état, set(valeur) l'applique
    static Switch(g, x, y, bg, get, set) {
        sw := g.Add("Picture", Format("x{} y{} w40 h20", x, y), "HBITMAP:" Widgets.Switch(get(), false, bg))
        draw := (hover) => sw.Value := "HBITMAP:" Widgets.Switch(get(), hover, bg)
        this.switchDraw[sw.Hwnd] := draw
        sw.OnEvent("Click", (*) => (set(!get()), draw(Hover.IsOver(sw))))
        Hover.Add(sw, () => draw(true), () => draw(false))
        return sw
    }

    static RedrawSwitch(sw) {
        if this.switchDraw.Has(sw.Hwnd)
            this.switchDraw[sw.Hwnd].Call(Hover.IsOver(sw))
    }

    ; Lien texte (couleur d'accent, souligné au survol)
    static Link(g, text, x, y, w, bg, onClick, extra := "") {
        l := this.Text(g, text, x, y, w, 22, Theme.accentText, bg, 10, 400, extra)
        l.OnEvent("Click", onClick)
        Hover.Add(l, () => l.SetFont("underline"), () => l.SetFont("norm"))
        return l
    }

    ; Champ de saisie sans bordure 3D : le cadre arrondi est dessiné dans le fond de la fenêtre
    static Edit(g, x, y, w, value) {
        g.SetFont(Format("norm s10 c{}", Theme.Hex(Theme.text)), Theme.font)
        ed := g.Add("Edit", Format("x{} y{} w{} h22 -E0x200 -VScroll -Wrap Background{}", x + 10, y + 6, w - 20, Theme.Hex(Theme.field)), value)
        DllCall("uxtheme\SetWindowTheme", "ptr", ed.Hwnd, "wstr", Theme.dark ? "DarkMode_CFD" : "CFD", "ptr", 0)
        return ed
    }

    ; Image de fond de la fenêtre, placée tout en dessous des autres contrôles
    static Background(g, cv, w, h) {
        bg := g.Add("Picture", Format("x0 y0 w{} h{} +0x4000000", w, h), "HBITMAP:" cv.HBITMAP())
        DllCall("SetWindowPos", "ptr", bg.Hwnd, "ptr", 1, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x13)  ; HWND_BOTTOM
        return bg
    }

    static NewWindow(title, opts := "") {
        g := Gui("-MaximizeBox " opts, title)
        g.BackColor := Theme.Hex(Theme.bg)
        g.MarginX := 0, g.MarginY := 0
        return g
    }

    ; Barre de titre assortie au thème + icône d'AppToggle
    static WindowTheme(g) {
        T := Theme, hwnd := g.Hwnd
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 20, "int*", T.dark ? 1 : 0, "uint", 4)  ; mode sombre
        if T.win11 {
            DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 35, "uint*", T.BGR(T.bg), "uint", 4)    ; couleur de la barre
            DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 36, "uint*", T.BGR(T.text), "uint", 4)  ; couleur du titre
        }
        for size in [DllCall("GetSystemMetrics", "int", 49), DllCall("GetSystemMetrics", "int", 11)]
            if (hIcon := App.Icon(size))
                SendMessage(0x80, A_Index - 1, hIcon, , hwnd)   ; WM_SETICON petite puis grande icône
    }

    ; Place une fenêtre au centre d'une autre, sans dépasser de l'écran
    static CenterOn(g, owner) {
        WinGetPos(&ox, &oy, &ow, &oh, owner.Hwnd)
        WinGetPos(, , &w, &h, g.Hwnd)
        MonitorGetWorkArea(this.MonitorOf(owner.Hwnd), &l, &t, &r, &b)
        x := Max(l, Min(ox + (ow - w) // 2, r - w))
        y := Max(t, Min(oy + (oh - h) // 2, b - h))
        WinMove(x, y, , , g.Hwnd)
    }

    static MonitorOf(hwnd) {
        WinGetPos(&x, &y, &w, &h, hwnd)
        cx := x + w // 2, cy := y + h // 2
        Loop MonitorGetCount() {
            MonitorGet(A_Index, &l, &t, &r, &b)
            if cx >= l && cx < r && cy >= t && cy < b
                return A_Index
        }
        return MonitorGetPrimary()
    }
}
