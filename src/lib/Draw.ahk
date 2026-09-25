; Dessin anti-aliasé avec GDI+ (intégré à Windows) : cartes arrondies, interrupteurs,
; boutons, touches de clavier, logo. Tout est dessiné à la taille réelle de l'écran (DPI).

class Gdip {
    static token := 0, families := Map()

    static Start() {
        if this.token
            return
        DllCall("LoadLibrary", "str", "gdiplus", "ptr")
        si := Buffer(24, 0)
        NumPut("uint", 1, si)
        DllCall("gdiplus\GdiplusStartup", "ptr*", &tok := 0, "ptr", si, "ptr", 0)
        this.token := tok
    }

    ; Libère GDI+ quand aucune fenêtre n'est ouverte : AppToggle retombe à quelques Mo en arrière-plan.
    static Stop() {
        if !this.token
            return
        for , fam in this.families
            DllCall("gdiplus\GdipDeleteFontFamily", "ptr", fam)
        this.families := Map()
        DllCall("gdiplus\GdiplusShutdown", "ptr", this.token)
        this.token := 0
    }

    static Family(name) {
        if this.families.Has(name)
            return this.families[name]
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "wstr", name, "ptr", 0, "ptr*", &fam := 0)
        if !fam
            DllCall("gdiplus\GdipCreateFontFamilyFromName", "wstr", "Segoe UI", "ptr", 0, "ptr*", &fam := 0)
        return this.families[name] := fam
    }

    ; Largeur d'un texte, en pixels logiques
    static Measure(str, size, bold := false, font := "") {
        c := Canvas(1, 1, 0)
        s := Theme.s
        DllCall("gdiplus\GdipCreateFont", "ptr", this.Family(font = "" ? Theme.font : font), "float", size * s, "int", bold ? 1 : 0, "int", 2, "ptr*", &hf := 0)
        DllCall("gdiplus\GdipCreateStringFormat", "int", 0x1000, "int", 0, "ptr*", &fmt := 0)
        layout := Buffer(16, 0)
        NumPut("float", 0, "float", 0, "float", 10000, "float", 1000, layout)
        box := Buffer(16, 0)
        DllCall("gdiplus\GdipMeasureString", "ptr", c.g, "wstr", str, "int", -1, "ptr", hf, "ptr", layout, "ptr", fmt, "ptr", box, "ptr", 0, "ptr", 0)
        DllCall("gdiplus\GdipDeleteStringFormat", "ptr", fmt)
        DllCall("gdiplus\GdipDeleteFont", "ptr", hf)
        return NumGet(box, 8, "float") / s
    }
}

; Une image en mémoire sur laquelle on dessine. Coordonnées en pixels logiques (96 DPI),
; converties automatiquement en pixels réels.
class Canvas {
    __New(w, h, bg) {
        this.s := Theme.s, this.bgc := bg
        this.pw := Max(1, Round(w * this.s)), this.ph := Max(1, Round(h * this.s))
        DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", this.pw, "int", this.ph, "int", 0, "int", 0x26200A, "ptr", 0, "ptr*", &bmp := 0)
        DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", bmp, "ptr*", &g := 0)
        DllCall("gdiplus\GdipSetSmoothingMode", "ptr", g, "int", 4)          ; anti-aliasing
        DllCall("gdiplus\GdipSetPixelOffsetMode", "ptr", g, "int", 2)        ; bords nets
        DllCall("gdiplus\GdipSetTextRenderingHint", "ptr", g, "int", 3)      ; texte lissé
        DllCall("gdiplus\GdipGraphicsClear", "ptr", g, "uint", 0xFF000000 | bg)
        this.bmp := bmp, this.g := g
    }

    __Delete() {
        DllCall("gdiplus\GdipDeleteGraphics", "ptr", this.g)
        DllCall("gdiplus\GdipDisposeImage", "ptr", this.bmp)
    }

    ; Rectangle arrondi : remplissage et/ou contour (couleurs RGB, -1 = rien)
    RoundRect(x, y, w, h, r, fill := -1, stroke := -1, strokeW := 1) {
        s := this.s
        if fill >= 0 {
            path := this.Path(x * s, y * s, w * s, h * s, r * s)
            DllCall("gdiplus\GdipCreateSolidFill", "uint", 0xFF000000 | fill, "ptr*", &br := 0)
            DllCall("gdiplus\GdipFillPath", "ptr", this.g, "ptr", br, "ptr", path)
            DllCall("gdiplus\GdipDeleteBrush", "ptr", br)
            DllCall("gdiplus\GdipDeletePath", "ptr", path)
        }
        if stroke >= 0 {
            sw := Max(1, Round(strokeW * s)), half := sw / 2
            path := this.Path(x * s + half, y * s + half, w * s - sw, h * s - sw, Max(0, r * s - half))
            DllCall("gdiplus\GdipCreatePen1", "uint", 0xFF000000 | stroke, "float", sw, "int", 2, "ptr*", &pen := 0)
            DllCall("gdiplus\GdipDrawPath", "ptr", this.g, "ptr", pen, "ptr", path)
            DllCall("gdiplus\GdipDeletePen", "ptr", pen)
            DllCall("gdiplus\GdipDeletePath", "ptr", path)
        }
    }

    RoundRectGradient(x, y, w, h, r, c1, c2) {
        s := this.s
        path := this.Path(x * s, y * s, w * s, h * s, r * s)
        rc := Buffer(16)
        NumPut("float", x * s, "float", y * s, "float", w * s, "float", h * s, rc)
        ; mode 2 = diagonale haut-gauche -> bas-droite ; wrap 3 évite un liseré sur les bords
        DllCall("gdiplus\GdipCreateLineBrushFromRect", "ptr", rc, "uint", 0xFF000000 | c1, "uint", 0xFF000000 | c2, "int", 2, "int", 3, "ptr*", &br := 0)
        DllCall("gdiplus\GdipFillPath", "ptr", this.g, "ptr", br, "ptr", path)
        DllCall("gdiplus\GdipDeleteBrush", "ptr", br)
        DllCall("gdiplus\GdipDeletePath", "ptr", path)
    }

    Rect(x, y, w, h, color) {
        s := this.s
        DllCall("gdiplus\GdipCreateSolidFill", "uint", 0xFF000000 | color, "ptr*", &br := 0)
        DllCall("gdiplus\GdipFillRectangle", "ptr", this.g, "ptr", br, "float", Round(x * s), "float", Round(y * s), "float", Max(1, Round(w * s)), "float", Max(1, Round(h * s)))
        DllCall("gdiplus\GdipDeleteBrush", "ptr", br)
    }

    Circle(cx, cy, r, color) {
        s := this.s
        DllCall("gdiplus\GdipCreateSolidFill", "uint", 0xFF000000 | color, "ptr*", &br := 0)
        DllCall("gdiplus\GdipFillEllipse", "ptr", this.g, "ptr", br, "float", (cx - r) * s, "float", (cy - r) * s, "float", 2 * r * s, "float", 2 * r * s)
        DllCall("gdiplus\GdipDeleteBrush", "ptr", br)
    }

    ; align : 0 gauche, 1 centre, 2 droite (centré verticalement dans la boîte)
    Text(str, x, y, w, h, color, size := 14, bold := false, font := "", align := 1) {
        s := this.s
        DllCall("gdiplus\GdipCreateFont", "ptr", Gdip.Family(font = "" ? Theme.font : font), "float", size * s, "int", bold ? 1 : 0, "int", 2, "ptr*", &hf := 0)
        DllCall("gdiplus\GdipCreateStringFormat", "int", 0x1000, "int", 0, "ptr*", &fmt := 0)
        DllCall("gdiplus\GdipSetStringFormatAlign", "ptr", fmt, "int", align)
        DllCall("gdiplus\GdipSetStringFormatLineAlign", "ptr", fmt, "int", 1)
        DllCall("gdiplus\GdipSetStringFormatTrimming", "ptr", fmt, "int", 3)
        rc := Buffer(16)
        NumPut("float", x * s, "float", y * s, "float", w * s, "float", h * s, rc)
        DllCall("gdiplus\GdipCreateSolidFill", "uint", 0xFF000000 | color, "ptr*", &br := 0)
        DllCall("gdiplus\GdipDrawString", "ptr", this.g, "wstr", str, "int", -1, "ptr", hf, "ptr", rc, "ptr", fmt, "ptr", br)
        DllCall("gdiplus\GdipDeleteBrush", "ptr", br)
        DllCall("gdiplus\GdipDeleteStringFormat", "ptr", fmt)
        DllCall("gdiplus\GdipDeleteFont", "ptr", hf)
    }

    Path(x, y, w, h, r) {
        DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &p := 0)
        d := Min(r * 2, w, h)
        if d <= 0 {
            DllCall("gdiplus\GdipAddPathRectangle", "ptr", p, "float", x, "float", y, "float", w, "float", h)
            return p
        }
        DllCall("gdiplus\GdipAddPathArc", "ptr", p, "float", x, "float", y, "float", d, "float", d, "float", 180, "float", 90)
        DllCall("gdiplus\GdipAddPathArc", "ptr", p, "float", x + w - d, "float", y, "float", d, "float", d, "float", 270, "float", 90)
        DllCall("gdiplus\GdipAddPathArc", "ptr", p, "float", x + w - d, "float", y + h - d, "float", d, "float", d, "float", 0, "float", 90)
        DllCall("gdiplus\GdipAddPathArc", "ptr", p, "float", x, "float", y + h - d, "float", d, "float", d, "float", 90, "float", 90)
        DllCall("gdiplus\GdipClosePathFigure", "ptr", p)
        return p
    }

    HBITMAP() {
        DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", this.bmp, "ptr*", &hbm := 0, "uint", 0xFF000000 | this.bgc)
        return hbm
    }
}

; Les éléments visuels. Chaque fonction renvoie une image (HBITMAP) dessinée sur la couleur de fond donnée.
class Widgets {
    ; Interrupteur façon Windows 11 (40 x 20)
    static Switch(on, hover, bg) {
        T := Theme, c := Canvas(40, 20, bg)
        if on {
            c.RoundRect(0, 0, 40, 20, 10, hover ? T.accentHover : T.accent)
            c.Circle(30, 10, hover ? 7 : 6, T.onAccent)
        } else {
            c.RoundRect(0, 0, 40, 20, 10, hover ? T.offHover : bg, T.offStroke)
            c.Circle(10, 10, hover ? 7 : 6, T.offThumb)
        }
        return c.HBITMAP()
    }

    ; style : primary (couleur d'accent), secondary, danger (rouge plein), subtle-danger (texte rouge)
    static Button(text, w, style, hover, bg, icon := "") {
        T := Theme, h := 32, c := Canvas(w, h, bg)
        switch style {
            case "primary":
                c.RoundRect(0, 0, w, h, 4, hover ? T.accentHover : T.accent)
                fg := T.onAccent
            case "danger":
                c.RoundRect(0, 0, w, h, 4, hover ? T.Blend(T.dangerFill, bg, 0.88) : T.dangerFill)
                fg := 0xFFFFFF
            case "subtle-danger":
                if hover
                    c.RoundRect(0, 0, w, h, 4, T.subtleHover)
                fg := T.danger
            default:
                c.RoundRect(0, 0, w, h, 4, hover ? T.ctrlHover : T.ctrl, T.ctrlStroke)
                fg := T.text
        }
        if icon = "" {
            c.Text(text, 0, 0, w, h, fg, 14)
        } else {
            tw := Gdip.Measure(text, 14), iw := 16, gap := 8
            x0 := (w - (iw + gap + tw)) / 2
            c.Text(icon, x0, 0, iw, h, fg, 14, false, T.icons)
            c.Text(text, x0 + iw + gap, 0, tw + 2, h, fg, 14, false, "", 0)
        }
        return c.HBITMAP()
    }

    ; Bouton icône carré (ex. le crayon « modifier »)
    static IconButton(glyph, size, hover, bg, color) {
        c := Canvas(size, size, bg)
        if hover
            c.RoundRect(0, 0, size, size, 4, Theme.subtleHover)
        c.Text(glyph, 0, 0, size, size, color, 16, false, Theme.icons)
        return c.HBITMAP()
    }

    ; Touches de clavier dessinées (ex. ["Ctrl", "Alt", "C"]). Renvoie {hbm, w, h}.
    static Keycaps(labels, bg) {
        T := Theme, h := 26, gap := 4, widths := [], total := 0
        if !labels.Length
            return {hbm: 0, w: 0, h: h}
        for lab in labels {
            kw := Max(28, Round(Gdip.Measure(lab, 12)) + 14)
            widths.Push(kw), total += kw
        }
        total += gap * (labels.Length - 1)
        c := Canvas(total, h, bg), x := 0
        for i, lab in labels {
            c.RoundRect(x, 0, widths[i], h, 5, T.key, T.keyStroke)
            c.Text(lab, x, 0, widths[i], h, T.text, 12)
            x += widths[i] + gap
        }
        return {hbm: c.HBITMAP(), w: total, h: h}
    }

    ; Logo AppToggle (identique à l'icône) : coloré = actif, gris = en pause
    static Logo(size, on, bg) {
        c := Canvas(size, size, bg)
        if on
            c.RoundRectGradient(0, 0, size, size, size * 0.22, 0x3B82F6, 0x8B5CF6)
        else
            c.RoundRectGradient(0, 0, size, size, size * 0.22, 0x8E8E93, 0x5A5A5F)
        pw := size * 0.625, ph := size * 0.375, px := (size - pw) / 2, py := (size - ph) / 2
        c.RoundRect(px, py, pw, ph, ph / 2, 0xFFFFFF)
        inset := ph * 0.16, d := ph - 2 * inset
        tx := on ? px + pw - inset - d : px + inset
        c.Circle(tx + d / 2, py + ph / 2, d / 2, on ? 0x636FF6 : 0x76767B)
        return c.HBITMAP()
    }

    ; Pastille avec l'initiale, quand Windows ne fournit pas d'icône
    static Avatar(name, size, bg) {
        static colors := [0x0078D4, 0x8764B8, 0x00B294, 0xE3008C, 0xCA5010, 0x498205, 0x038387, 0x5C2E91]
        h := 0
        Loop Parse name
            h := Mod(h * 31 + Ord(A_LoopField), 997)
        c := Canvas(size, size, bg)
        c.RoundRect(0, 0, size, size, size * 0.22, colors[Mod(h, colors.Length) + 1])
        c.Text(StrUpper(SubStr(name, 1, 1)), 0, 0, size, size, 0xFFFFFF, size * 0.45, true)
        return c.HBITMAP()
    }

    ; Emplacement vide (« aucune appli choisie »)
    static Placeholder(size, bg) {
        c := Canvas(size, size, bg)
        c.RoundRect(0, 0, size, size, size * 0.22, Theme.field, Theme.fieldStroke)
        c.Text(Chr(0xE710), 0, 0, size, size, Theme.text3, 16, false, Theme.icons)
        return c.HBITMAP()
    }

    ; Icône de l'appli (fournie par Windows), sinon pastille avec l'initiale
    static AppIcon(e, size, bg) {
        ps := Round(size * Theme.s)
        if (hbm := Shell.Image(e.ParsingName, ps)) {
            out := this.OnBackground(hbm, ps, bg)
            DllCall("DeleteObject", "ptr", hbm)
            return out
        }
        return this.Avatar(e.name != "" ? e.name : e.process, size, bg)
    }

    ; Pose une image avec transparence sur une couleur de fond (les contrôles Picture ne gèrent pas l'alpha)
    static OnBackground(src, ps, bg) {
        bm := Buffer(32, 0)
        DllCall("GetObject", "ptr", src, "int", 32, "ptr", bm)
        sw := NumGet(bm, 4, "int"), sh := Abs(NumGet(bm, 8, "int"))
        dw := Min(sw, ps), dh := Min(sh, ps)
        sdc := DllCall("GetDC", "ptr", 0, "ptr")
        dst := DllCall("CreateCompatibleDC", "ptr", sdc, "ptr")
        srcDC := DllCall("CreateCompatibleDC", "ptr", sdc, "ptr")
        out := DllCall("CreateCompatibleBitmap", "ptr", sdc, "int", ps, "int", ps, "ptr")
        o1 := DllCall("SelectObject", "ptr", dst, "ptr", out, "ptr")
        o2 := DllCall("SelectObject", "ptr", srcDC, "ptr", src, "ptr")
        br := DllCall("CreateSolidBrush", "uint", Theme.BGR(bg), "ptr")
        rc := Buffer(16, 0)
        NumPut("int", ps, rc, 8), NumPut("int", ps, rc, 12)
        DllCall("FillRect", "ptr", dst, "ptr", rc, "ptr", br)
        DllCall("DeleteObject", "ptr", br)
        ; BLENDFUNCTION {AC_SRC_OVER, 0, 255, AC_SRC_ALPHA}
        DllCall("msimg32\AlphaBlend", "ptr", dst, "int", (ps - dw) // 2, "int", (ps - dh) // 2, "int", dw, "int", dh
            , "ptr", srcDC, "int", 0, "int", 0, "int", sw, "int", sh, "uint", 0x01FF0000)
        DllCall("SelectObject", "ptr", dst, "ptr", o1, "ptr")
        DllCall("SelectObject", "ptr", srcDC, "ptr", o2, "ptr")
        DllCall("DeleteDC", "ptr", dst)
        DllCall("DeleteDC", "ptr", srcDC)
        DllCall("ReleaseDC", "ptr", 0, "ptr", sdc)
        return out
    }
}

; Ce que l'Explorateur Windows sait des applis : icône et nom affiché.
; « shell:AppsFolder\<id> » désigne une appli du Store, sinon c'est le chemin d'un .exe.
class Shell {
    static Image(parsingName, px) {
        static IID := Shell.GUID("{BCC18B79-BA16-442F-80C4-8A59C30C463B}")    ; IShellItemImageFactory
        if parsingName = ""
            return 0
        factory := 0, hbm := 0
        if DllCall("shell32\SHCreateItemFromParsingName", "wstr", parsingName, "ptr", 0, "ptr", IID, "ptr*", &factory, "int") != 0
            return 0
        try ComCall(3, factory, "int64", px | (px << 32), "int", 0x4, "ptr*", &hbm)  ; GetImage, icône seule
        ObjRelease(factory)
        return hbm
    }

    static DisplayName(parsingName) {
        static IID := Shell.GUID("{43826D1E-E718-42EE-BC55-A1E261C37BFE}")    ; IShellItem
        item := 0, name := ""
        if DllCall("shell32\SHCreateItemFromParsingName", "wstr", parsingName, "ptr", 0, "ptr", IID, "ptr*", &item, "int") != 0
            return ""
        try {
            ComCall(5, item, "uint", 0, "ptr*", &p := 0)                         ; GetDisplayName
            name := StrGet(p, "UTF-16")
            DllCall("ole32\CoTaskMemFree", "ptr", p)
        }
        ObjRelease(item)
        return name
    }

    static GUID(str) {
        buf := Buffer(16)
        DllCall("ole32\CLSIDFromString", "wstr", str, "ptr", buf)
        return buf
    }
}
