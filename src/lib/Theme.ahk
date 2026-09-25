; Couleurs et polices : suit le mode sombre/clair de Windows et sa couleur d'accent.
class Theme {
    static Init() {
        this.dark := !RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme", 1)
        this.s := A_ScreenDPI / 96
        this.win11 := VerCompare(A_OSVersion, "10.0.22000") >= 0
        this.font := this.FontExists("Segoe UI Variable Text") ? "Segoe UI Variable Text" : "Segoe UI"
        this.fontTitle := this.FontExists("Segoe UI Variable Display") ? "Segoe UI Variable Display" : "Segoe UI"
        this.icons := this.FontExists("Segoe Fluent Icons") ? "Segoe Fluent Icons" : "Segoe MDL2 Assets"

        if this.dark {
            this.bg := 0x202020, this.card := 0x2B2B2B, this.cardStroke := 0x1D1D1D, this.divider := 0x1D1D1D
            this.text := 0xFFFFFF, this.text2 := 0xC5C5C5, this.text3 := 0x9D9D9D
            this.ctrl := 0x373737, this.ctrlHover := 0x3D3D3D, this.ctrlStroke := 0x454545
            this.subtleHover := 0x383838
            this.field := 0x313131, this.fieldStroke := 0x464646
            this.key := 0x3A3A3A, this.keyStroke := 0x4F4F4F
            this.offStroke := 0xA0A0A0, this.offThumb := 0xCFCFCF, this.offHover := 0x333333
            this.danger := 0xFF99A4, this.dangerFill := 0xC42B1C
            this.onAccent := 0x000000
        } else {
            this.bg := 0xF3F3F3, this.card := 0xFBFBFB, this.cardStroke := 0xE5E5E5, this.divider := 0xEAEAEA
            this.text := 0x1B1B1B, this.text2 := 0x5D5D5D, this.text3 := 0x8B8B8B
            this.ctrl := 0xFFFFFF, this.ctrlHover := 0xF5F5F5, this.ctrlStroke := 0xDCDCDC
            this.subtleHover := 0xEFEFEF
            this.field := 0xFFFFFF, this.fieldStroke := 0xD4D4D4
            this.key := 0xF3F3F3, this.keyStroke := 0xD0D0D0
            this.offStroke := 0x8A8A8A, this.offThumb := 0x5D5D5D, this.offHover := 0xF0F0F0
            this.danger := 0xC42B1C, this.dangerFill := 0xC42B1C
            this.onAccent := 0xFFFFFF
        }
        this.accent := this.ReadAccent()
        this.accentHover := this.Blend(this.accent, this.dark ? this.card : this.bg, 0.9)
        this.accentText := this.accent
    }

    ; Palette d'accent de Windows : 8 couleurs RRGGBBAA. En sombre Windows 11 utilise la 2e (claire), en clair la 5e (foncée).
    static ReadAccent() {
        try {
            pal := RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent", "AccentPalette")
            return Integer("0x" SubStr(pal, (this.dark ? 1 : 4) * 8 + 1, 6))
        }
        return this.dark ? 0x4CC2FF : 0x005FB8
    }

    static FontExists(name) {
        hdc := DllCall("GetDC", "ptr", 0, "ptr")
        lf := Buffer(92, 0)
        NumPut("uchar", 1, lf, 23)                        ; lfCharSet = DEFAULT_CHARSET
        StrPut(name, lf.Ptr + 28, 32, "UTF-16")          ; lfFaceName
        res := {found: false}
        cb := CallbackCreate((*) => (res.found := true, 0), "F", 4)
        DllCall("gdi32\EnumFontFamiliesExW", "ptr", hdc, "ptr", lf, "ptr", cb, "ptr", 0, "uint", 0)
        CallbackFree(cb)
        DllCall("ReleaseDC", "ptr", 0, "ptr", hdc)
        return res.found
    }

    static Hex(c) => Format("{:06X}", c)
    static BGR(c) => ((c & 0xFF) << 16) | (c & 0xFF00) | ((c >> 16) & 0xFF)

    static Blend(c1, c2, t) {
        r := Round(((c1 >> 16) & 0xFF) * t + ((c2 >> 16) & 0xFF) * (1 - t))
        g := Round(((c1 >> 8) & 0xFF) * t + ((c2 >> 8) & 0xFF) * (1 - t))
        b := Round((c1 & 0xFF) * t + (c2 & 0xFF) * (1 - t))
        return (r << 16) | (g << 8) | b
    }
}
