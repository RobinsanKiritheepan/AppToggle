; AppToggle : ouvre, ramène ou réduit une appli avec une seule touche (ex. la touche Copilot).
; Licence MIT - https://github.com/RobinsanKiritheepan/AppToggle
#Requires AutoHotkey v2.0
#SingleInstance Off
#NoTrayIcon
Persistent()
KeyHistory(0)       ; aucune touche n'est gardée en mémoire
ListLines(false)

;@Ahk2Exe-SetName AppToggle
;@Ahk2Exe-SetProductName AppToggle
;@Ahk2Exe-SetDescription AppToggle - ouvre et réduit tes applis avec une touche
;@Ahk2Exe-SetVersion 2.1.0
;@Ahk2Exe-SetCompanyName Kiritheepan Robinsan
;@Ahk2Exe-SetCopyright Copyright (c) 2026 Kiritheepan Robinsan - Licence MIT
;@Ahk2Exe-SetOrigFilename AppToggle.exe
;@Ahk2Exe-SetMainIcon ..\assets\icon.ico
;@Ahk2Exe-AddResource ..\assets\icon-off.ico, 250

#Include %A_ScriptDir%\lib\Lang.ahk
#Include %A_ScriptDir%\lib\Theme.ahk
#Include %A_ScriptDir%\lib\Draw.ahk
#Include %A_ScriptDir%\lib\Config.ahk
#Include %A_ScriptDir%\lib\Keys.ahk
#Include %A_ScriptDir%\lib\Engine.ahk
#Include %A_ScriptDir%\lib\Tray.ahk
#Include %A_ScriptDir%\ui\Controls.ahk
#Include %A_ScriptDir%\ui\Settings.ahk
#Include %A_ScriptDir%\ui\Editor.ahk
#Include %A_ScriptDir%\ui\Picker.ahk

App.Main()

class App {
    static Version := "2.1.0"
    static RepoUrl := "https://github.com/RobinsanKiritheepan/AppToggle"
    static WM_SHOW := 0x8001        ; message privé : « affiche tes réglages »
    static mutex := 0

    static Main() {
        ; Sécurité : les DLL chargées ensuite viennent uniquement de System32, jamais du dossier de l'exe
        ; (évite qu'une fausse DLL posée à côté soit chargée à la place de celle de Windows)
        DllCall("SetDefaultDllDirectories", "uint", 0x800)     ; LOAD_LIBRARY_SEARCH_SYSTEM32

        atStartup := false
        for arg in A_Args
            if arg = "/startup"
                atStartup := true

        ; Une seule instance : si AppToggle tourne déjà, on lui demande d'ouvrir ses réglages
        if this.AlreadyRunning() {
            if !atStartup
                this.WakeOther()
            ExitApp()
        }
        DllCall("SetProp", "ptr", A_ScriptHwnd, "str", "AppToggle.Main", "ptr", 1)
        DllCall("ole32\CoInitialize", "ptr", 0)
        OnError(ObjBindMethod(this, "OnFail"))
        OnMessage(this.WM_SHOW, (*) => (UI.Later(() => Settings.Show()), 0))
        OnMessage(0x1A, ObjBindMethod(this, "OnSettingChange"))    ; WM_SETTINGCHANGE (thème changé)

        Theme.Init()
        Hover.Init()
        Config.Load()
        Lang.Init()
        Engine.Apply()
        Tray.Init()
        Startup.Repair()
        if atStartup {
            if Config.notify
                Tray.Greet()
        } else
            Settings.Show()
        this.TrimMemory()
    }

    static SetActive(on) {
        Config.active := on
        Config.Save()
        Engine.Apply()
        Tray.Update()
        Settings.Refresh()
    }

    static AlreadyRunning() {
        this.mutex := DllCall("CreateMutex", "ptr", 0, "int", 0, "str", "AppToggle.SingleInstance", "ptr")
        return A_LastError = 183                                   ; ERROR_ALREADY_EXISTS
    }

    static WakeOther() {
        DetectHiddenWindows(true)
        for hwnd in WinGetList("ahk_class AutoHotkey") {
            if DllCall("GetProp", "ptr", hwnd, "str", "AppToggle.Main", "ptr") {
                DllCall("AllowSetForegroundWindow", "uint", WinGetPID(hwnd))
                PostMessage(this.WM_SHOW, 0, 0, , hwnd)
                return
            }
        }
    }

    ; Passage mode clair <-> sombre ou changement de couleur d'accent : on redessine
    static OnSettingChange(wParam, lParam, *) {
        if lParam && StrGet(lParam) = "ImmersiveColorSet"
            UI.Later(ObjBindMethod(this, "ReTheme"))
    }

    static ReTheme() {
        was := [Theme.dark, Theme.accent]
        Theme.Init()
        if was[1] = Theme.dark && was[2] = Theme.accent
            return
        Tray.DarkMenus()
        if Settings.gui {
            Editor.Close()
            Settings.Rebuild()
        }
    }

    ; Erreur imprévue : on la note dans errors.log (à côté de l'exe) au lieu d'afficher une fenêtre technique
    static OnFail(err, mode) {
        try FileAppend(Format("[{}] {} {} (ligne {}, {})`r`n", FormatTime(, "yyyy-MM-dd HH:mm:ss"), err.Message, err.Extra, err.Line, err.What)
            , A_ScriptDir "\errors.log", "UTF-8")
        try Tray.Notify(Tr("AppToggle a rencontré un problème"), Tr("Les détails sont dans errors.log, à côté de l'application."), "Iconx")
        return 1
    }

    static Icon(size) {
        try return A_IsCompiled
            ? LoadPicture(A_ScriptFullPath, "Icon1 w" size " h" size, &t)
            : LoadPicture(A_ScriptDir "\..\assets\icon.ico", "w" size " h" size, &t)
        return 0
    }

    ; Rend la mémoire inutilisée à Windows (AppToggle reste à quelques Mo en arrière-plan)
    static TrimMemory() => DllCall("psapi\EmptyWorkingSet", "ptr", DllCall("GetCurrentProcess", "ptr"))
}
