; Fenêtre « Choisir une appli ouverte » : liste les fenêtres visibles et détecte tout seul
; s'il s'agit d'une appli du Microsoft Store ou d'un programme classique.

class Picker {
    static gui := "", lv := "", items := [], cb := ""
    static W := 460, M := 20

    static Open(cb) {
        if !Editor.gui
            return
        this.Close()
        this.cb := cb
        T := Theme, W := this.W, M := this.M, cw := W - 2 * M
        yList := 80, hList := 300, yBtn := yList + hList + 18, H := yBtn + 32 + 18

        cv := Canvas(W, H, T.bg)
        cv.RoundRect(M, yList, cw, hList, 8, T.card, T.cardStroke)
        g := UI.NewWindow(Tr("Choisir une application"), "-MinimizeBox +Owner" Editor.gui.Hwnd)
        g.OnEvent("Close", (*) => this.Close())
        g.OnEvent("Escape", (*) => this.Close())
        UI.Background(g, cv, W, H)
        UI.Text(g, Tr("Choisir une appli ouverte"), M, 14, cw, 32, T.text, T.bg, 14, 600, , T.fontTitle)
        UI.Text(g, Tr("Ton appli n'est pas dans la liste ? Ouvre-la, puis clique sur Actualiser."), M + 1, 46, cw, 20, T.text2, T.bg, 9)

        g.SetFont(Format("norm s10 c{}", T.Hex(T.text)), T.font)
        lv := g.Add("ListView", Format("x{} y{} w{} h{} -Hdr -Multi -E0x200 +LV0x10000 Background{} c{}"
            , M + 6, yList + 6, cw - 12, hList - 12, T.Hex(T.card), T.Hex(T.text)), ["Application", "Processus"])
        DllCall("uxtheme\SetWindowTheme", "ptr", lv.Hwnd, "wstr", T.dark ? "DarkMode_ItemsView" : "ItemsView", "ptr", 0)
        SendMessage(0x127, 0x10001, 0, lv)                     ; WM_CHANGEUISTATE : pas de cadre pointillé
        lv.OnEvent("DoubleClick", (ctrl, row) => this.Pick(row))
        this.lv := lv

        UI.Button(g, Tr("Actualiser"), M, yBtn, 124, "secondary", T.bg, (*) => this.Fill(), Chr(0xE72C))
        UI.Button(g, Tr("Choisir"), W - M - 120, yBtn, 120, "primary", T.bg, (*) => this.Pick(this.lv.GetNext()))
        UI.Button(g, Tr("Annuler"), W - M - 120 - 8 - 110, yBtn, 110, "secondary", T.bg, (*) => this.Close())

        g.Show(Format("Hide w{} h{}", W, H))
        UI.WindowTheme(g)
        UI.CenterOn(g, Editor.gui)
        Editor.gui.Opt("+Disabled")
        g.Show()
        this.gui := g
        this.Fill()
    }

    ; Vue « mosaïque » de Windows : icône, nom de l'appli, et le processus en gris en dessous
    static Fill() {
        lv := this.lv
        lv.Opt("-Redraw")
        lv.Delete()
        this.items := this.OpenApps()
        ps := Round(32 * Theme.s)
        il := DllCall("comctl32\ImageList_Create", "int", ps, "int", ps, "uint", 0x20, "int", 8, "int", 8, "ptr")  ; ILC_COLOR32
        for it in this.items
            lv.Add("Icon" this.AddIcon(il, it, ps), it.name, it.process)
        if (old := lv.SetImageList(il, 0))
            IL_Destroy(old)

        SendMessage(0x108E, 4, 0, lv)                           ; LVM_SETVIEW : LV_VIEW_TILE
        rc := Buffer(16, 0)
        DllCall("GetClientRect", "ptr", lv.Hwnd, "ptr", rc)
        tvi := Buffer(40, 0)                                    ; LVTILEVIEWINFO : tuiles pleine largeur, 1 ligne sous le titre
        NumPut("uint", 40, "uint", 0x3, "uint", 0x1, "int", NumGet(rc, 8, "int") - DllCall("GetSystemMetrics", "int", 2), "int", 0, "int", 1, tvi)
        SendMessage(0x10A2, 0, tvi.Ptr, lv)                     ; LVM_SETTILEVIEWINFO
        cols := Buffer(4, 0), fmts := Buffer(4, 0)
        NumPut("uint", 1, cols)                                 ; afficher la colonne « Processus »
        ti := Buffer(32, 0)                                     ; LVTILEINFO
        Loop this.items.Length {
            NumPut("uint", 32, ti, 0), NumPut("int", A_Index - 1, ti, 4), NumPut("uint", 1, ti, 8)
            NumPut("ptr", cols.Ptr, ti, 16), NumPut("ptr", fmts.Ptr, ti, 24)
            SendMessage(0x10A4, 0, ti.Ptr, lv)                  ; LVM_SETTILEINFO
        }
        lv.Opt("+Redraw")
        if this.items.Length
            lv.Modify(1, "Select Focus")
        lv.Focus()
    }

    static AddIcon(il, it, ps) {
        hbm := Shell.Image(it.type = "store" ? "shell:AppsFolder\" it.target : it.target, ps)
        if hbm {
            bm := Buffer(32, 0)
            DllCall("GetObject", "ptr", hbm, "int", 32, "ptr", bm)
            if NumGet(bm, 4, "int") != ps || Abs(NumGet(bm, 8, "int")) != ps {
                framed := Widgets.OnBackground(hbm, ps, Theme.card)
                DllCall("DeleteObject", "ptr", hbm)
                hbm := framed
            }
        } else
            hbm := Widgets.Avatar(it.name, 32, Theme.card)
        i := DllCall("comctl32\ImageList_Add", "ptr", il, "ptr", hbm, "ptr", 0, "int")
        DllCall("DeleteObject", "ptr", hbm)
        return i + 1
    }

    ; Une ligne par appli (même si elle a plusieurs fenêtres), triée par nom
    static OpenApps() {
        out := [], seen := Map(), me := ProcessExist()
        for hwnd in WinGetList() {
            try {
                if !Engine.IsMainWindow(hwnd) || WinGetPID(hwnd) = me
                    continue
                if WinGetClass(hwnd) ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd|Windows\.UI\.Core\.CoreWindow)$"
                    continue
                proc := WinGetProcessName(hwnd)
                ; les applis « UWP » anciennes partagent toutes ApplicationFrameHost : impossible de les distinguer par processus
                if proc ~= "i)^(ApplicationFrameHost|TextInputHost|SearchHost|StartMenuExperienceHost|ShellExperienceHost|LockApp)\.exe$"
                    continue
                aumid := this.PackageId(WinGetPID(hwnd))
                path := WinGetProcessPath(hwnd)
                id := StrLower(aumid != "" ? aumid : path)
                if seen.Has(id)
                    continue
                seen[id] := true
                name := aumid != "" ? Shell.DisplayName("shell:AppsFolder\" aumid) : this.ExeName(path)
                if name = ""
                    name := WinGetTitle(hwnd)
                out.Push({name: name, process: proc, type: aumid != "" ? "store" : "exe", target: aumid != "" ? aumid : path})
            }
        }
        Loop out.Length - 1 {                                   ; tri par insertion (listes courtes)
            i := A_Index + 1, cur := out[i], j := i - 1
            while j >= 1 && StrCompare(out[j].name, cur.name) > 0
                out[j + 1] := out[j], j--
            out[j + 1] := cur
        }
        return out
    }

    ; Identifiant Microsoft Store du processus (vide si c'est un programme classique)
    static PackageId(pid) {
        h := DllCall("OpenProcess", "uint", 0x1000, "int", 0, "uint", pid, "ptr")   ; PROCESS_QUERY_LIMITED_INFORMATION
        if !h
            return ""
        len := 0, aumid := ""
        if DllCall("GetApplicationUserModelId", "ptr", h, "uint*", &len, "ptr", 0) = 122 {   ; tampon trop petit : on connaît la taille
            buf := Buffer(len * 2)
            if DllCall("GetApplicationUserModelId", "ptr", h, "uint*", &len, "ptr", buf) = 0
                aumid := StrGet(buf, "UTF-16")
        }
        DllCall("CloseHandle", "ptr", h)
        return aumid
    }

    ; Nom lisible d'un programme (ex. « Google Chrome »), lu dans les propriétés du .exe
    static ExeName(path) {
        for field in ["FileDescription", "ProductName"]
            if (v := Trim(this.VersionString(path, field))) != ""
                return v
        SplitPath(path, , , , &base)
        return base
    }

    static VersionString(path, field) {
        size := DllCall("version\GetFileVersionInfoSizeW", "wstr", path, "ptr", 0, "uint")
        if !size
            return ""
        buf := Buffer(size)
        if !DllCall("version\GetFileVersionInfoW", "wstr", path, "uint", 0, "uint", size, "ptr", buf)
            return ""
        if !DllCall("version\VerQueryValueW", "ptr", buf, "wstr", "\VarFileInfo\Translation", "ptr*", &tr := 0, "uint*", &len := 0) || len < 4
            return ""
        sub := Format("\StringFileInfo\{:04X}{:04X}\{}", NumGet(tr, 0, "ushort"), NumGet(tr, 2, "ushort"), field)
        if DllCall("version\VerQueryValueW", "ptr", buf, "wstr", sub, "ptr*", &p := 0, "uint*", &len) && len
            return StrGet(p, "UTF-16")
        return ""
    }

    static Pick(row) {
        if !row || row > this.items.Length
            return
        it := this.items[row], cb := this.cb
        this.Close()
        cb.Call(it)
    }

    static Close() {
        if !this.gui
            return
        if Editor.gui
            Editor.gui.Opt("-Disabled")
        this.gui.Destroy()
        this.gui := "", this.lv := ""
        if Editor.gui
            WinActivate(Editor.gui.Hwnd)
        Hover.Prune()
    }
}
