; AHK v2
; =======================================================================================
; thanks to boiler
;       https://www.autohotkey.com/boards/viewtopic.php?f=6&t=76602&p=332166&hilit=boiler+RAAV#p332166
; thanks to Rapte_Of_Suzaku
;       https://autohotkey.com/board/topic/60985-get-paths-of-selected-items-in-an-explorer-window/
; thanks to TeaDrinker
;       https://www.autohotkey.com/boards/viewtopic.php?p=255169#p255169
; =======================================================================================
; The above users' contributions were crucial to AHK Portable Installer now being fully portable.
;
; Also thanks to hoppfrosch for initial testing which helped get the basics working.
; =======================================================================================

; "D:\Apps\DEV\AutoHotkey\AutoHotkey_2.0-a138-7538f26f\AutoHotkey64.exe" "D:\Drive\UserData\DEV\AHK\AHK_Portable_Installer\AHK Portable Installer.ahk"

#SingleInstance Off ; Allow multiple instances, for when running in non-portable mode.
                    ; This installer script is "consulted" when launching a script or when
                    ; launching the compiler.  So for a split second, there needs to be 2
                    ; instances of the script while this "consulting" takes place.  Once
                    ; the end result is finally launched, this 2nd instance closes.

SendMode "Input"  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

#INCLUDE inc\_JXON.ahk
#INCLUDE inc\TheArkive_reg2.ahk
#INCLUDE inc\funcs.ahk

class app {
    Static dclick := DllCall("User32\GetDoubleClickTime")
         , lastClick := 0
         , last_click_diff := 1000
         , last_xy := 0
         , verGui := {hwnd:0}
         , ReadOnly := false
         , sp := scriptParams()
         , toggle := 0
}

Global oGui := "", Settings := "", AhkPisVersion := "v1.20", regexList := Map()

OnExit(on_exit)

If !DirExist("temp")
    DirCreate "temp"
If !DirExist("versions")
    DirCreate "versions"

If (A_Is64BitOS)
    reg.view := 64

SettingsJSON := ""
If FileExist("Settings.json")
    SettingsJSON := FileRead("Settings.json")
Settings := (SettingsJSON && (SettingsJSON!=Chr(34) Chr(34))) ? Jxon_Load(&SettingsJSON) : Map()

(!Settings.Has("AhkVersions")) ? Settings["AhkVersions"] := Map() : ""
(!Settings.Has("posX")) ? Settings["posX"] := 300 : ""
(!Settings.Has("posY")) ? Settings["posY"] := 300 : ""

(!Settings.Has("DisableTooltips")) ? Settings["DisableTooltips"] := true : ""
(!Settings.Has("PortableMode")) ? Settings["PortableMode"] := 0 : ""
(!Settings.Has("ShowCompileScript")) ? Settings["ShowCompileScript"] := true : ""
(!Settings.Has("ShowEditScript")) ? Settings["ShowEditScript"] := true : ""
(!Settings.Has("ShowRunScript")) ? Settings["ShowRunScript"] := true : ""
(!Settings.Has("HideTrayIcon")) ? Settings["HideTrayIcon"] := true : ""
(!Settings.Has("MinimizeOnStart")) ? Settings["MinimizeOnStart"] := false : ""
(!Settings.Has("CloseToTry")) ? Settings["CloseToTray"] := 0 : ""
(!Settings.Has("SystemStartup")) ? Settings["SystemStartup"] := 0 : ""
(!Settings.Has("PickIcon")) ? Settings["PickIcon"] := "Default" : ""
(!Settings.Has("AutoUpdateCheck")) ? Settings["AutoUpdateCheck"] := true : ""
(!Settings.Has("CascadeMenu")) ? Settings["CascadeMenu"] := 0 : ""

(!Settings.Has("ActiveVersionPath")) ? Settings["ActiveVersionPath"] := "" : ""
(!Settings.Has("ActiveVersionDisp")) ? Settings["ActiveVersionDisp"] := "" : ""

(!Settings.Has("TextEditorPath")) ? Settings["TextEditorPath"] := "notepad.exe" : ""

(!Settings.Has("AhkUrl")) ? Settings["AhkUrl"] := "https://www.autohotkey.com/download/" : ""
(!Settings.Has("DLVersion")) ? Settings["DLVersion"] := "2.0" : ""
(!Settings.Has("VerList")) ? Settings["VerList"] := "1.1;2.0" : ""
(!Settings.Has("VerFile")) ? Settings["VerFile"] := "version.txt" : ""

(!Settings.Has("BaseFolder")) ? Settings["BaseFolder"] := "" : ""
(!Settings.Has("InstallProfile")) ? Settings["InstallProfile"] := "Current User" : ""
(!Settings.Has("reg")) ? Settings["reg"] := "HKEY_CURRENT_USER" : ""


If Settings["HideTrayIcon"]
    A_IconHidden := true

; ====================================================================================
; Processing Parameters for launching scripts and the Compiler.
; - Creates a 2nd instance in non-portable mode for a split second.
; ====================================================================================

If A_Args.Length {
    q := Chr(34), app.ReadOnly := true, in_file := A_Args[2], err := ""
    
    If !RegExMatch(A_Args[1],"(?:Compile|Launch(Admin)?)")
        err := "Invalid first parameter:`r`n`r`nParam one must be LAUNCH, LAUNCHADMIN, or COMPILE."
    Else If (A_Args.Length < 2)
        err := "Invalid second parameter.`r`n`r`nThere appears to be no script file specified."
    Else If !FileExist(in_file)
        err := "Script file does not exist:`r`n`r`n" in_file
    If err {
        Msgbox(err,"ERROR",0x10)
        ExitApp
    }
    
    obj := proc_script(in_file, ((A_Args[1]="Compile")?true:false))
    SplitPath in_file,,&dir
    If RegExMatch(A_Args[1],"Launch(?:Admin)?") {
        obj.admin := (A_Args[1] = "LaunchAdmin") ? true : false ; set admin mode
        ahkCmd := (obj.admin?"*RunAs ":"") q obj.exe q (obj.admin?" /restart ":" ") q in_file q (app.sp?" " app.sp:"")
    } Else If (A_Args[1] = "Compile")
        ahkCmd := q obj.exe q " /in " q in_file q " /gui"
    
    If obj.err {
        Msgbox obj.err
        ExitApp
    } Else If !FileExist(obj.exe) {
        msg := "The following EXE cannot be found:`r`n`r`n"
             . obj.exe "`r`n`r`n"
             . "Did you recently move or rename some folders?"
        Msgbox(msg,"File not found",0x10)
        ExitApp
    }
    
    Run(ahkCmd, dir)
    ExitApp ; Close this instance after deciding which AHK.exe / compiler to run.
}

scriptParams() {
    op := "", q := Chr(34)
    If (A_Args.Length >= 3) && (i := 3) ; concat otherParams
        Loop (A_Args.Length - 2)
            op .= ((i>3) ? " " : "") q A_Args[i++] q
    return op
}


; ====================================================================================
; ====================================================================================

If Settings["PickIcon"] = "Default" {
    f := GetAhkProps(Settings["ActiveVersionPath"])
    if f
        TraySetIcon(f.exePath,0)
} Else TraySetIcon("resources\AHK_pi_" Settings["PickIcon"] ".ico")

If A_IsCompiled {
    Loop 2
        A_TrayMenu.Delete("1&")
} Else {
    Loop 9
        A_TrayMenu.Delete("1&")
}
A_TrayMenu.Insert("1&","Open",tray_menu)
A_TrayMenu.Default := "Open"

tray_menu(txt, pos, m) {
    If (txt="Open")
        runGui()
    Else If (txt="Exit")
        ExitApp
}

monitor := GetMonitorData()
If Settings["posX"] > monitor.right Or Settings["posX"] < monitor.left
    Settings["posX"] := 200
If Settings["posY"] > monitor.bottom Or Settings["posY"] < monitor.top
    Settings["posY"] := 200

OnMessage(0x0200,WM_MOUSEMOVE) ; WM_MOUSEMOVE
WM_MOUSEMOVE(wParam, lParam, Msg, hwnd) {
    Global Settings, oGui
    
    If (!Settings["DisableTooltips"]) {
    
        If (hwnd = oGui["ActivateExe"].Hwnd)
            ToolTip "Sets the Base Version.`r`n`r`n"
                  . "Modify settings as desired first, including templates.`r`n"
                  . "Then click this button."
                  
        Else If (hwnd = oGui["ExeList"].Hwnd)
            ToolTip "List of Base Versions to choose from.`r`n"
                  . "Select then click the [Install/Select] button.`r`n"
                  . "Be sure to modify settings as desired first, like`r`n"
                  . "context-menu items and Text Editor."
                  
        Else If (hwnd = oGui["CurrentPath"].Hwnd)
            ToolTip oGui["CurrentPath"].Value
        
        Else
            ToolTip
    }
}

OnMessage(0x6,WM_ACTIVATE)
WM_ACTIVATE(wParam, lParam, Msg, hwnd) {
    Global oGui
    wp := (wParam & 0xFFFF)
    
    If (app.verGui.hwnd) && (hwnd != app.verGui.hwnd) && (hwnd = oGui.hwnd) && (wp > 0)
        app.verGui.Destroy()
      , app.verGui := {hwnd:0}
      , Sleep(100)
      , oGui["ExeList"].Focus()
      , dbg("is main: " (hwnd = oGui.hwnd) " / " wp)
}


If (Settings["MinimizeOnStart"]) {
    If !Settings["CloseToTray"]
        runGui(true)
} Else RunGui()

runGui(minimize:=false) {
    Global oGui, AhkPisVersion, Settings
    oGui := Gui("-DPIScale","AHK Portable Installer " AhkPisVersion)
    oGui.OnEvent("Close",gui_Close)
    
    oGui.Add("Text","vActiveVersionDisp xm y+8 w409 -E0x200 ReadOnly","Base Version:")
    oGui.Add("Button","vVersionDisp x+2 yp-4 w50","Latest").OnEvent("Click",GuiEvents)
    
    LV := oGui.Add("ListView","xm y+0 r5 w460 vExeList",["Description","Version","File Name","Full Path"])
    LV.OnEvent("DoubleClick",GuiEvents), LV.OnEvent("Click",ListClick)
    LV.OnEvent("ContextMenu",conEvent)
    
    oGui.Add("Edit","vCurrentPath xm y+8 w440 -E0x200 ReadOnly","Path:    ")
    
    oGui.Add("Button","vToggleSettings y+0","Settings").OnEvent("Click",GuiEvents)
    oGui.Add("Button","vHelp x+40","Help").OnEvent("Click",GuiEvents)
    oGui.Add("Button","vCompiler x+0","Compiler").OnEvent("Click",GuiEvents)
    oGui.Add("Button","vWindowSpy x+0","Window Spy").OnEvent("Click",GuiEvents)
    oGui.Add("Button","vUninstall x+0","Uninstall AHK").OnEvent("Click",GuiEvents)
    oGui.Add("Button","vActivateExe x+40 yp w78","Install").OnEvent("Click",GuiEvents)
    
    tabs := oGui.Add("Tab","y+10 x2 w476 h275",["Downloads","Basics","Options"])
    
    tabs.UseTab("Downloads")
    
    oGui.Add("Text","xm y+10","Version:")
    oGui.Add("DropDownList","vDLVersion x+2 yp-4 w40").OnEvent("change",GuiEvents)
    oGui.Add("Button","vDownload xm+253 yp","Download").OnEvent("click",GuiEvents)
    oGui.Add("Button","vOpenFolder x+0 yp","Base Folder").OnEvent("click",GuiEvents)
    oGui.Add("Button","vOpenTemp x+0 yp","Temp Folder").OnEvent("click",GuiEvents)
    ctl := oGui.Add("ListView","vDLList xm y+10 w460 h181",["File","Date"])
    ctl.SetFont("s8","Consolas")
    
    tabs.UseTab("Basics")
    oGui.Add("Text","xm y+10","Custom Base Folder:    (optional)")
    oGui.Add("Edit","y+0 r1 w410 vBaseFolder ReadOnly")
    oGui.Add("Button","x+0 vPickBaseFolder","...").OnEvent("Click",GuiEvents)
    oGui.Add("Button","x+0 vClearBaseFolder","X").OnEvent("Click",GuiEvents)
    
    oGui.Add("Text","xm y+4 Section","AutoHotkey download URL:")
    oGui.Add("Edit","y+0 r1 w250 vAhkUrl").OnEvent("Change",GuiEvents)
    
    oGui.Add("Text","x+2 ys","Version File:")
    oGui.Add("Edit","vVerFile y+0 xp w75").OnEvent("Change",GuiEvents)
    
    oGui.Add("Text","x+2 ys","Versions:")
    oGui.Add("Edit","vVerList y+0 xp w75 vVerList").OnEvent("Change",GuiEvents)
    
    oGui.Add("Text","xm y+4 Section","Install For:")
    oGui.Add("DropDownList","vInstallProfile y+0 r2 w100",["Current User","All Users"]).OnEvent("Change",GuiEvents)
    
    oGui.Add("Checkbox","vDisableTooltips xm y+10","Disable Tooltips").OnEvent("Click",GuiEvents)
    
    oGui.Add("Checkbox","vAutoUpdateCheck x+30 yp","Automatically check for updates").OnEvent("Click",GuiEvents)
    oGui.Add("Button","vCheckUpdateNow x+44 yp-4","Check Updates Now").OnEvent("Click",GuiEvents)
    
    oGui.Add("Text","xm y+4","Text Editor:")
    oGui.Add("Edit","xm y+0 w410 vTextEditorPath ReadOnly")
    oGui.Add("Button","x+0 vPickTextEditor","...").OnEvent("Click",GuiEvents)
    oGui.Add("Button","x+0 vDefaultTextEditor","X").OnEvent("Click",GuiEvents)
    
    oGui.Add("Button","vEditAhk1Template xm y+10 w230","Edit AHK v1 Template").OnEvent("Click",GuiEvents)
    oGui.Add("Button","vEditAhk2Template x+0 w230","Edit AHK v2 Template").OnEvent("Click",GuiEvents)
    
    tabs.UseTab("Options")
    
    oGui.Add("GroupBox","xm w456 h40 y+4","Context Menu - Only applies when Full Portable Mode is disabled")
    oGui.Add("Checkbox","vShowEditScript xp+10 yp+20","Show " Chr(34) "Edit Script" Chr(34)).OnEvent("Click",GuiEvents)
    oGui.Add("Checkbox","vShowCompileScript x+30","Show " Chr(34) "Compile Script" Chr(34)).OnEvent("Click",GuiEvents)
    oGui.Add("Checkbox","vShowRunScript x+30","Show " Chr(34) "Run as Admin" Chr(34)).OnEvent("Click",GuiEvents)
    
    oGui.Add("Checkbox","vPortableMode y+15 xm+10","Fully Portable Mode").OnEvent("Click",GuiEvents)
    oGui.Add("Checkbox","vHideTrayIcon x+25","Hide Tray Icon").OnEvent("Click",GuiEvents)
    oGui.Add("Checkbox","vCloseToTray x+67","Close to Tray").OnEvent("Click",GuiEvents)
    oGui.Add("Checkbox","vMinimizeOnStart y+10 xm+10","Minimize on Startup").OnEvent("Click",GuiEvents)
    
    oGui.Add("Text","x+26","Icon:")
    oGui.Add("DropDownList","vPickIcon w70 x+4 yp-3",["Default","Blue","Green","Orange","Pink","Red"]).OnEvent("Change",GuiEvents)
    
    oGui.Add("Checkbox","vSystemStartup x+61 yp+3","Run on system startup").OnEvent("Click",GuiEvents)
    
    oGui.Add("GroupBox","vHotkeys1 xm+10 y+10 w456 h60 y+4 Hidden","Hotkeys")
    txt := "MButton:`t`tRuns SELECTED scrtips in Explorer window/on desktop.`r`n"
         . "SHIFT + MButton:`tOpen script file in specified text editor.`r`n"
         . "CTRL + MButton:`tOpen the compiler with the selected script pre-filled."
    oGui.Add("Text","vHotkeys2 xp+10 yp+15 Hidden",txt)
    
    tabs.UseTab()
    
    oGui.Add("StatusBar","vStatusBar")
    
    x := Settings["posX"], y := Settings["posY"]
    PopulateSettings()
    ListExes()
    
    oGui.Show("w480 h225 x" x " y" y (minimize?" Minimize":""))
    oGui["StatusBar"].SetText("Administrator: " (A_IsAdmin?"YES":"NO"))
    
    If !Settings["AhkVersions"].Count
        CheckUpdate(1)
    
    If ((result := CheckUpdate(,false)) != "NoUpdate")
        MsgBox result, "Update Check Failed", 0x10
}

conEvent(g, row, rc, x, y) {
    Global oGui
    m := Menu()
    Click()
    m.Add("Copy version text",conMenu)
    m.Add()
    m.Add("Remove this version",conMenu)
    m.row := row
    m.show()
}

conMenu(iName, iPos, m) {
    Global oGui
    LV := oGui["ExeList"]
    If (iName = "Remove this version") {
        msg := "Are you sure you want to remove this version?`r`n`r`n"
             . "AutoHotkey v" LV.GetText(m.row, 2)
        If Msgbox(msg, "Remove Version",4) = "No"
            return
        
        dir := RegExReplace(oGui["ExeList"].GetText(m.row,4),"^Path: +")
        SplitPath dir,,&oDir
        
        Try DirDelete oDir, true
        Catch error as e {
            Msgbox "Access is denied, or an executable is still running."
            return
        }
        
        ticks := A_TickCount
        While (!(exist := DirExist(oDir)) && (A_TickCount - ticks) <= 500)
            Sleep 50
        
        If exist
            Msgbox "The delete command appears to have succeeded, but the folder still remains.  Please delete it manually."
        
        ListExes()
    } Else If (iName = "Copy version text") {
        A_Clipboard := LV.GetText(m.row,2)
    }
}

PopulateSettings() {
    Global Settings, oGui
    
    oGui["BaseFolder"].Value := Settings["BaseFolder"]
    oGui["AhkUrl"].Value := Settings["AhkUrl"]
    oGui["VerFile"].Value := Settings["VerFile"]
    oGui["VerList"].Value := VerList := Settings["VerList"]
    oGui["InstallProfile"].Text := Settings["InstallProfile"]
    oGui["AutoUpdateCheck"].value := Settings["AutoUpdateCheck"]
    oGui["TextEditorPath"].Value := Settings["TextEditorPath"]
    oGui["ShowEditScript"].Value := Settings["ShowEditScript"]
    oGui["ShowCompileScript"].Value := Settings["ShowCompileScript"]
    oGui["ShowRunScript"].Value := Settings["ShowRunScript"]
    oGui["DisableTooltips"].Value := Settings["DisableTooltips"]
    oGui["PortableMode"].Value := Settings["PortableMode"]
    
    If (Settings["PortableMode"])
        oGui["ActivateExe"].Text := "Select"
      , oGui["Uninstall"].Enabled := false
      , oGui["Hotkeys1"].Visible := true
      , oGui["Hotkeys2"].Visible := true
    Else
        oGui["ActivateExe"].Text := "Install"
      , oGui["Uninstall"].Enabled := true
      , oGui["Hotkeys1"].Visible := false
      , oGui["Hotkeys2"].Visible := false
    
    oGui["HideTrayIcon"].Value := Settings["HideTrayIcon"]
    oGui["CloseToTray"].Value := Settings["CloseToTray"]
    oGui["MinimizeOnStart"].Value := Settings["MinimizeOnStart"]
    oGui["PickIcon"].Text := Settings["PickIcon"]
    oGui["SystemStartup"].Value := Settings["SystemStartup"]
    
    oGui["DLVersion"].Add(StrSplit(VerList,";"))
    oGui["DLVersion"].Text := Settings["DLVersion"]
    
    PopulateDLList()
    SetActiveVersionGui()
}

GuiEvents(oCtl,Info) {
    Global regexList, Settings, oGui
    If (oCtl.Name = "ToggleSettings") {
        oGui["ExeList"].Focus()
        (app.toggle) ? oGui.Show("w480 h225") : oGui.Show("w480 h480")
        app.toggle := !app.toggle
    } Else If (oCtl.Name = "Compiler") {
        If !Settings["ActiveVersionPath"] {
            Msgbox "Install/Select an AutoHotkey version first."
            return
        }
        
        f := GetAhkProps(Settings["ActiveVersionPath"])
        Run f.installDir "\Compiler\Ahk2Exe.exe"
        
    } Else If (oCtl.Name = "ActivateExe" or oCtl.Name = "ExeList") {
        If !oGui["ExeList"].GetNext() {
            Msgbox "Select an AutoHotkey version from the main list first."
            return
        }
        ActivateEXE()
        
    } Else If (oCtl.Name = "CheckUpdateNow") {
        result := CheckUpdate(1)
        If (result)
            MsgBox result, "Update Check Failed", 0x10
            
    } Else If (oCtl.Name = "AutoUpdateCheck") {
        Settings["AutoUpdateCheck"] := oCtl.Value
        
    } Else If (oCtl.Name = "ClearBaseFolder") {
        Settings["BaseFolder"] := "", oGui["BaseFolder"].Value := ""
        ListExes()
        
    } Else If (oCtl.Name = "PickBaseFolder") {
        BaseFolder := (Settings.Has("BaseFolder")) ? Settings["BaseFolder"] : A_ScriptDir
        BaseFolder := FileSelect("D1",BaseFolder,"Select the base AHK folder:")
        
        If (BaseFolder And DirExist(BaseFolder)) {
            oGui["BaseFolder"].Value := BaseFolder
            Settings["BaseFolder"] := BaseFolder
            ListExes()
        } Else If (!DirExist(BaseFolder) And BaseFolder != "")
            MsgBox "Chosen folder does not exist."
            
    } Else If (oCtl.Name = "AhkUrl") {
        Settings["AhkUrl"] := oCtl.Value
        
    } Else If (oCtl.Name = "VerFile") {
        Settings["VerFile"] := oCtl.Value
    
    } Else If (oCtl.Name = "VerList") {
        Settings["VerList"] := oCtl.Value
    
    } Else If (oCtl.Name = "InstallProfile") {
        Settings["InstallProfile"] := oCtl.Text
        If (oCtl.Text = "Current User")
            Settings["reg"] := "HKEY_CURRENT_USER"
        Else If (oCtl.Text = "All Users")
            Settings["reg"] := "HKEY_LOCAL_MACHINE"
    
    } Else If (oCtl.Name = "DefaultTextEditor") {
        oGui["TextEditorPath"].Value := "notepad.exe", Settings["TextEditorPath"] := "notepad.exe"
        
    } Else If (oCtl.Name = "PickTextEditor") {
        textPath := (Settings["TextEditorPath"] = "notepad.exe") ? A_WinDir "\notepad.exe" : Settings["TextEditorPath"]
        TextEditorPath := FileSelect("1",textPath,"Select desired text editor:","Executable (*.exe)")
        
        If (TextEditorPath) {
            oGui["TextEditorPath"].Value := TextEditorPath
            Settings["TextEditorPath"] := TextEditorPath
        }
        
    } Else If (oCtl.Name = "Help") {
        If !Settings["ActiveVersionPath"] {
            Msgbox "Install/Select an AutoHotkey version first."
            return
        }
        
        curExe := Settings["ActiveVersionPath"]
        If (FileExist(curExe)) {
            f := GetAhkProps(curExe)
            
            Loop Files f.installDir "\*.chm"
            {
                If (A_Index = 1) {
                    helpFile := A_LoopFileFullPath
                    Break
                }
            }        
            
            If (helpFile)
                Run helpFile,, "Max"
            Else
                Msgbox "No help file found."
        }
        
    } Else If (oCtl.Name = "EditAhk1Template") {
        Run Chr(34) Settings["TextEditorPath"] Chr(34) " " Chr(34) "resources\TemplateV1.ahk"
        
    } Else If (oCtl.Name = "EditAhk2Template") {
        Run Chr(34) Settings["TextEditorPath"] Chr(34) " " Chr(34) "resources\TemplateV2.ahk"
        
    } Else If (oCtl.Name = "WindowSpy") {
        If (Settings.Has("ActiveVersionPath") And FileExist(Settings["ActiveVersionPath"])) {
            SplitPath Settings["ActiveVersionPath"], &exeFile, &exeDir
            winSpy := exeDir "\WindowSpy.ahk"
            If (FileExist(winSpy))
                Run Chr(34) exeDir "\WindowSpy.ahk" Chr(34)
            Else
                Msgbox "WindowSpy.ahk not found."
        }
        Else Msgbox "Install/Select an AutoHotkey version first."
        
    } Else If (oCtl.Name = "Uninstall") {
        If (MsgBox("Remove AutoHotkey from registry?","Uninstall AutoHotkey",0x24) = "Yes")
            UninstallAhk()
            
    } Else If (oCtl.Name = "DisableTooltips") {
        Settings[oCtl.Name] := oCtl.Value
        
    } Else If (oCtl.Name = "DebugNow") {
        Settings["DebugNow"] := oCtl.Value
        
    } Else If (oCtl.Name = "ShowEditScript") { ; context menu
        Settings["ShowEditScript"] := oCtl.Value
        
    } Else If (oCtl.Name = "ShowCompileScript") { ; context menu
        Settings["ShowCompileScript"] := oCtl.Value
        
    } Else If (oCtl.Name = "ShowRunScript") { ; context menu
        Settings["ShowRunScript"] := oCtl.Value
        
    } Else If (oCtl.Name = "PortableMode") {
        Settings["PortableMode"] := oCtl.value
        If (oCtl.value)
            oCtl.gui["ActivateExe"].Text := "Select"
          , oGui["Uninstall"].Enabled := false
          , oGui["Hotkeys1"].Visible := true
          , oGui["Hotkeys2"].Visible := true
        Else
            oCtl.gui["ActivateExe"].Text := "Install"
          , oGui["Uninstall"].Enabled := true
          , oGui["Hotkeys1"].Visible := false
          , oGui["Hotkeys2"].Visible := false
        
    } Else If (oCtl.Name = "HideTrayIcon") {
        If (!oGui["HideTrayIcon"].Value And !oGui["CloseToTray"].value)
            oCtl.Value := 1
        
        Settings["HideTrayIcon"] := oCtl.value
        oGui["CloseToTray"].Value := 0
        Settings["CloseToTray"] := 0
        A_IconHidden := true
        
    } Else if (oCtl.Name = "CloseToTray") {
        If (!oGui["HideTrayIcon"].Value And !oGui["CloseToTray"].value)
            oCtl.Value := 1
        
        Settings["CloseToTray"] := oCtl.value
        oGui["HideTrayIcon"].Value := 0
        Settings["HideTrayIcon"] := 0
        A_IconHidden := false
        
    } Else if (oCtl.Name = "MinimizeOnStart") {
        Settings["MinimizeOnStart"] := oCtl.Value
        
    } Else If (oCtl.Name = "PickIcon") {
        Settings["PickIcon"] := oCtl.Text
        If oCtl.Text = "Default" {
            f := GetAhkProps(Settings["ActiveVersionPath"])
            TraySetIcon(f.exePath,0)
        } Else TraySetIcon("AHK_pi_" oCtl.Text ".ico")
        
    } Else If (oCtl.Name = "SystemStartup") {
        Settings["SystemStartup"] := oCtl.Value
        lnk := A_AppData "\Microsoft\Windows\Start Menu\Programs\Startup\AHK Portable Installer.lnk"
        exe := A_ScriptDir "\AHK Portable Installer.exe"
        
        If !FileExist(exe) {
            msgbox "AHK Portable Installer.exe does not exist.`r`n`r`n"
                 . "You need to download the latest AHK v2 zip package, and copy one of the EXE files into the main script folder "
                 . "then you need to rename that EXE to:`r`n`r`n"
                 . "AHK Portable Installer.exe"
            return
        }
        
        If oCtl.value {
            If Settings["PickIcon"] = "Default" {
                f := GetAhkProps(Settings["ActiveVersionPath"])
                icon := f.exePath
            } Else icon := A_ScriptDir "\resources\AHK_pi_" Settings["PickIcon"] ".ico"
            
            FileCreateShortcut exe, lnk,,,,icon
        } Else If FileExist(lnk)
            FileDelete lnk
    } Else If (oCtl.Name = "DLVersion") {
        Settings["DLVersion"] := oCtl.Text
        ; If !Settings["AhkVersions"].Count
            ; CheckUpdate(1)
        PopulateDLList()
    } Else If (oCtl.Name = "Download") {
        DLFile()
    } Else If (oCtl.Name = "OpenFolder") {
        dest := (Settings["BaseFolder"] ? Settings["BaseFolder"] : A_ScriptDir "\versions")
        Run "explorer.exe " Chr(34) dest Chr(34)
    } Else If (oCtl.Name = "OpenTemp") {
        Run "explorer.exe " Chr(34) A_ScriptDir "\temp" Chr(34)
    } Else If (oCtl.Name = "VersionDisp") {
        If !(app.verGui.hwnd) {
            app.verGui := verGui()
        } Else {
            app.verGui.Destroy()
            app.verGui := {hwnd:0}
        }
    }
}

verGui() {
    oGui.GetClientPos(&x1,&y1)
    oGui["VersionDisp"].GetPos(&x2,&y2,&w2,&h2)
    
    Global Settings, oGui
    g := Gui("-Caption +Owner" oGui.hwnd)
    disp := ""
    For ver, obj in Settings["AhkVersions"]
        disp .= (disp?"`r`n":"") "AutoHotkey v" ver ":  " obj["latest"]
    g.Add("Text",,disp)
    g.Show("x" (x := x1+x2+w2) " y" (y := y1+y2+h2) " hide")
    g.GetClientPos(,,&w3,)
    g.Show("x" (x - w3) " y" y)
    return g
}

RefreshDLList(url) {
    Global Settings, oGui
    Static q := Chr(34)
    
    whr := ComObject("WinHttp.WinHttpRequest.5.1")
    whr.Open("GET",url )
    Try whr.Send()
    Catch {
        Msgbox "Host could not be reached.  Check internet connection."
        whr := ""
        return false
    }
    whr.WaitForResponse()
    
    list := Map()
    txt := whr.ResponseText
    
    Loop Parse, txt, "`n", "`r"
    {
        If (r1 := RegExMatch(A_LoopField,"<a href=" q "([^>]+)" q ">",&m)
        && (r2 := RegExMatch(A_LoopField,"<td align=" q "right" q ">([^<]+)",&n))) {
            If (m[1] = "/") || (m[1] = "/download/") || (m[1] = "version.txt")
            || (m[1] = "_AHK-binaries.zip") || (m[1] = "zip%20versions/")
                continue
            list[m[1]] := Trim(n[1]," `t")
        }
    }
    
    return list
}

PopulateDLList() {
    Global Settings, oGui
    LV := oGui["DLList"], LV.Delete(), ver := oGui["DLVersion"].Text
    LV.Opt("-Redraw")
    
    If (!ver || !Settings.Has("AhkVersions") || !Settings["AhkVersions"].Has(ver))
        return
    
    For _file, _date in Settings["AhkVersions"][ver]["list"]
        If !RegExMatch(_file,"\.exe$")
            LV.Add(,_file,_date)
    
    LV.ModifyCol(1,300)
    LV.ModifyCol(2,120)
    LV.MOdifyCol(2,"SortDesc")
    LV.Opt("+Redraw")
}

DLFile() {
    Global Settings, oGui
    LV := oGui["DLList"], ver := oGui["DLVersion"].Text
    If !(row := LV.GetNext()) {
        MsgBox "Select a download first."
        return
    }
    
    SplitPath (zipFile := oGui["DLList"].GetText(row)),,,,&fileTitle
    dest := (Settings["BaseFolder"] ? Settings["BaseFolder"] : A_ScriptDir "\versions") "\"
    destTemp := A_ScriptDir "\temp\"
    src := Settings["AhkUrl"] oGui["DLVersion"].Text "/"
    
    If !FileExist(destTemp zipFile) {
        oGui["StatusBar"].SetText("Downloading " zipFile "...")
        Try Download src zipFile, destTemp zipFile
        Catch {
            Msgbox "Host could not be reached.  Check internet connection."
            return
        }
    }
    
    For _file, _date in Settings["AhkVersions"][ver]["list"] { ; verify sha256 hash - need wincrypt wrapper
        If InStr(_file,zipFile ".sha") {
            SplitPath _file,,,&hType
            If !FileExist(destTemp _file)
                Download src _file, destTemp _file
            
            While !FileExist(destTemp _file)
                Sleep 100
            h1 := hash(destTemp zipFile,hType)
            h2 := FileRead(destTemp _file)
            
            If (h1 != h2) {
                Msgbox "File hash does not math!`r`n`r`nTry redownloading the file"
                FileDelete destTemp zipFile
                FileDelete destTemp _file
                return
            }
            Break
        }
    }
    
    dest := (Settings["BaseFolder"] ? Settings["BaseFolder"] : A_ScriptDir "\versions") "\" fileTitle
    If !DirExist(dest)
        DirCreate dest
    Else {
        Msgbox "Destination directory already exists.  Manually delete this folder and try again."
        return
    }
    
    oGui["StatusBar"].SetText("Decompressing " zipFile "...")
    objShell := ComObject("Shell.Application")
    zipFile := objShell.NameSpace(A_ScriptDir "\temp\" zipFile)
    objShell.NameSpace(dest).CopyHere(zipFile.Items())
    objShell := ""
    
    ListExes()
    oGui["StatusBar"].SetText("")
}

ActivateEXE() {
    Global Settings, oGui
    
    If (Settings["reg"] = "HKEY_LOCAL_MACHING") && !A_IsAdmin {
        Msgbox "This program does not currently have Administrative privileges and cannot install for all users.`r`n`r`n"
             . "Change the install type to 'Current User' or re-run this program as Administrator."
        return
    }
    
    LV := oGui["ExeList"] ; ListView
    row := LV.GetNext(), exeFullPath := LV.GetText(row,4)
    
    If !Settings["PortableMode"]
        UninstallAhk() ; ... shouldn't need this
    
    hive := Settings["reg"]
    
    ; props: product, version, installDir, type, bitness, exeFile, exePath, exeDir, variant
    f := GetAhkProps(exeFullPath)
    
    Settings["ActiveVersionDisp"] := Trim(f.product " " f.type " " f.bitness "-bit " f.variant) " " f.version
    Settings["ActiveVersionPath"] := exeFullPath
    
    oGui["ActiveVersionDisp"].Text := "Installed:    " ; clear active version
    mpress := (FileExist(f.installDir "\Compiler\mpress.exe")) ? 1 : 0
    
    If Settings["PortableMode"] {
        SetActiveVersionGui()
        return
    }
    
    ; .ahk extension and template settings
    If reg.add(hive "\SOFTWARE\Classes\.ahk","","AutoHotkeyScript") {
        MsgBox reg.reason "`r`n`r`nTry running this script as Administrator."
        return
    }
    If reg.add(hive "\SOFTWARE\Classes\.ahk\ShellNew","ItemName","AutoHotkey Script")
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add(hive "\SOFTWARE\Classes\.ahk\ShellNew","NullFile","")
        MsgBox reg.reason "`r`n`r`n" reg.lastKey    
    
    ; update template according to majVersion
    If (hive = "HKEY_LOCAL_MACHINE") {
        If reg.add(hive "\SOFTWARE\Classes\.ahk\ShellNew","FileName","Template.ahk")
            MsgBox reg.reason "`r`n`r`n" reg.lastKey
         
        templateText := FileRead("resources\" "TemplateV" f.majVersion ".ahk")
        If !FileExist(A_WinDir "\ShellNew")
            DirCreate A_WinDir "\ShellNew"
        Try FileDelete A_WinDir "\ShellNew\Template.ahk"
        FileAppend templateText, A_WinDir "\ShellNew\Template.ahk"
    }
    
    reg.delete(hive "\Software\AutoHotkey")
    Sleep 350 ; make it easier to see something happenend when re-installing over same version
    
    ; define ProgID
    root := hive "\SOFTWARE\Classes\AutoHotkeyScript\Shell" (Settings["CascadeMenu"] ? "\AutoHotkey\Shell" : "")
    If reg.add(hive "\SOFTWARE\Classes\AutoHotkeyScript","","AutoHotkey Script") ; ProgID title, asthetic only?
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add(hive "\SOFTWARE\Classes\AutoHotkeyScript\DefaultIcon","",Chr(34) exeFullPath Chr(34) ",1")
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add(root,"","Open")
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    
    ; Compiler Context Menu (Ahk2Exe)
    If Settings["ShowCompileScript"] {
        If reg.add(root "\Compile","","Compile Script")                                                ; Compile context menu entry
            MsgBox reg.reason "`r`n`r`n" reg.lastKey
        
        _step1 := Chr(34) A_ScriptDir "\AHK Portable Installer.exe" Chr(34) " " Chr(34) A_ScriptFullPath Chr(34)
        regVal := _step1 " Compile " Chr(34) "%1" Chr(34) 
        
        If reg.add(root "\Compile\Command","",regVal)
            MsgBox reg.reason "`r`n`r`n" reg.lastKey
    }
    
    ; Edit Script
    If Settings["ShowEditScript"] {
        If reg.add(root "\Edit","","Edit Script")                                                      ; Edit context menu entry
            MsgBox reg.reason "`r`n`r`n" reg.lastKey
        If reg.add(root "\Edit\Command","",Chr(34) Settings["TextEditorPath"] Chr(34) " " Chr(34) "%1" Chr(34))    ; Edit command
            MsgBox reg.reason "`r`n`r`n" reg.lastKey
    }
    
    ; Run Script
    If reg.add(root "\Open","","Run Script")
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    
    _step1 := Chr(34) A_ScriptDir "\AHK Portable Installer.exe" Chr(34) " " Chr(34) A_ScriptFullPath Chr(34)
    regVal := _step1 " Launch " Chr(34) "%1" Chr(34) " %*"
    
    If reg.add(root "\Open\Command","",regVal)                                                 ; Open verb/command
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    
    ; Run Script as Admin
    If Settings["ShowRunScript"] {
        If reg.add(root "\RunAs","","Run Script as Admin")
            MsgBox reg.reason "`r`n`r`n" reg.lastKey
        
        _step1 := Chr(34) A_ScriptDir "\AHK Portable Installer.exe" Chr(34) " " Chr(34) A_ScriptFullPath Chr(34)
        regVal := _step1 " LaunchAdmin " Chr(34) "%1" Chr(34) " %*"
        
        If reg.add(root "\RunAs\Command","",regVal)                                                 ; RunAs verb/command
            MsgBox reg.reason "`r`n`r`n" reg.lastKey
    }
    
    ; Ahk2Exe entries
    If reg.add("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe","LastBinFile",f.type " " f.bitness "-bit.bin")   ; auto set .bin file
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe","LastUseMPRESS",mpress)     ; auto set mpress usage
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe","Ahk2ExePath",f.installDir "\Compiler\Ahk2Exe.exe")  ; for easy reference...
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe","BitFilter",f.bitness "-bit")
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    
    ; HKLM / Software / AutoHotkey install and version info
    If reg.add(hive "\Software\AutoHotkey","InstallDir",f.installDir)           ; Default entries
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add(hive "\Software\AutoHotkey","StartMenuFolder","AutoHotkey")      ; Default entries
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add(hive "\Software\AutoHotkey","Version",f.version)                 ; Default entries
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    
    If reg.add(hive "\Software\AutoHotkey","MajorVersion",f.majVersion)           ; just in case it's helpful
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add(hive "\Software\AutoHotkey","InstallExe",exeFullPath)
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add(hive "\Software\AutoHotkey","InstallBitness",f.bitness "-bit")
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add(hive "\Software\AutoHotkey","InstallProduct",f.Product " " f.type " " f.bitness "-bit")
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    
    SetActiveVersionGui()
}

UninstallAhk() {
    Global Settings, oGui
    k1 := reg.delete(k1k := "HKLM\SOFTWARE\AutoHotkey")
    k2 := reg.delete(k2k := "HKLM\SOFTWARE\Classes\.ahk")
    k3 := reg.delete(k3k := "HKLM\SOFTWARE\Classes\AutoHotkeyScript")
    
    k4 := reg.delete(k4k := "HKCU\Software\AutoHotkey")
    k5 := reg.delete(k5k := "HKCU\Software\Classes\AutoHotkey")
    k6 := reg.delete(k6k := "HKCU\SOFTWARE\Classes\.ahk")
    k7 := reg.delete(k7k := "HKCU\Software\Classes\AutoHotkeyScript")
    
    If (A_Is64BitOs) {
        reg.view := 32
        k8  := reg.delete(k8k  := "HKLM\SOFTWARE\AutoHotkey")
        k9  := reg.delete(k9k  := "HKLM\SOFTWARE\Classes\.ahk")
        k10 := reg.delete(k10k := "HKLM\SOFTWARE\Classes\AutoHotkeyScript")
        reg.view := 64
    }
    
    Try FileDelete A_WinDir "\ShellNew\Template.ahk"
    
    Settings["ActiveVersionPath"] := ""
    Settings["ActiveVersionDisp"] := ""
    SetActiveVersionGui()
}

gui_Close(o) {
    Global Settings, oGui
    
    oGui.GetPos(&x,&y,&w,&h), dims := {x:x, y:y, w:w, h:h}
    Settings["posX"] := dims.x, Settings["posY"] := dims.y
    
    If Settings["CloseToTray"] {
        oGui.Destroy()
        oGui := ""
        return
    }
    
    ExitApp
}

on_exit(*) {
    Global Settings
    If (!app.ReadOnly) { ; don't re-save ever time script is launched by the registry
        Try FileDelete "Settings.json"
        SettingsJSON := Jxon_Dump(Settings,4)
        FileAppend SettingsJSON, "Settings.json"
    }
}

SetActiveVersionGui() {
    Global Settings, oGui
    InstProd := "", ver := "", hive := Settings["reg"]
    
    If Settings["PortableMode"] {
        ActiveVersion := (Settings.Has("ActiveVersionDisp")) ? Settings["ActiveVersionDisp"] : ""
        oGui["ActiveVersionDisp"].Text := "Base Version:    " ActiveVersion
    } Else {
        Try InstProd := reg.read(hive "\SOFTWARE\AutoHotkey","InstallProduct")
        Try ver := reg.read(hive "\SOFTWARE\AutoHotkey","Version")
        
        regVer := InstProd " " ver
        ActiveVersion := (Settings.Has("ActiveVersionDisp")) ? Settings["ActiveVersionDisp"] : ""
        
        oCtl := oGui["ActiveVersionDisp"]
        If (regVer = "")
            oCtl.Text := "AutoHotkey not installed!"
        Else If (regVer != ActiveVersion or ActiveVersion = "")
            oCtl.Text := "AutoHotkey version mismatch!  Please reinstall!" ; this usually happens during a fresh install of Windows
        Else
            oCtl.Text := "Base Version:    " ActiveVersion
        oCtl := ""
    }
}

DisplayPathGui(oCtl,curRow) {
    Global Settings, oGui
    curPath := oCtl.GetText(curRow,4)
    oGui["CurrentPath"].Text := "Path:    " curPath
}

ListClick(oCtl,Info) {
    DisplayPathGui(oCtl,Info)
}

ListExes() {
    Global Settings, oGui
    props := ["Name","Product version","File description"]
    LV := oGui["ExeList"] ; ListView
    LV.Opt("-Redraw"), LV.Delete()
    
    BaseFolder := (Settings["BaseFolder"] = "") ? A_ScriptDir "\versions" : Settings["BaseFolder"]
    
    Loop Files BaseFolder "\AutoHotkey*.exe", "R"
    {
        f := GetAhkProps(A_LoopFileFullPath)
        If ((A_LoopFileName = "AutoHotkey.exe") && (!f.isAhkH))
        || RegExMatch(A_LoopFileFullPath,"i)\\(_*OLD_*|Compiler)\\")
            continue
        
        If (IsObject(f))
            LV.Add("",f.product " " f.Type " " f.bitness "-bit",f.Version,f.exeFile,A_LoopFileFullPath)
    }
    
    LV.ModifyCol(1,180), LV.ModifyCol(2,120), LV.ModifyCol(3,138), LV.ModifyCol(4,0)
    LV.ModifyCol(1,"Sort"), LV.ModifyCol(2,"Sort")
    LV.Opt("+Redraw")
    
    ActiveVersionPath := (Settings.Has("ActiveVersionPath")) ? Settings["ActiveVersionPath"] : ""
    rows := LV.GetCount(), curRow := 0
    
    If (ActiveVersionPath and rows) {
        Loop rows {
            curPath := LV.GetText(A_Index,4)
            If (ActiveVersionPath = curPath) {
                curRow := A_Index
                LV.Modify(curRow,"Vis Select")
                break
            }
        }
    }
    
    If (curRow)
        DisplayPathGui(LV,curRow)
    
    LV.Focus()
}

CheckUpdate(override:=0,confirm:=true) {
    Global Settings, oGui
    ahkUrl := Settings["AhkUrl"], verFile := Settings["VerFile"]
    
    If (!override) {
        If (!Settings.Has("AutoUpdateCheck") Or Settings["AutoUpdateCheck"] = 0)
            return "NoUpdate"
        Else If Settings.Has("UpdateCheckDate") And (Settings["UpdateCheckDate"] = FormatTime(,"yyyy-MM-dd"))
            return "NoUpdate"
    }
    
    errMsg := "", resultMsg := "", verList := Map()
    whr := ComObject("WinHttp.WinHttpRequest.5.1")
    
    For i, ver in StrSplit(Settings["VerList"],";") {
        ver := String(ver), url := ahkUrl ver "/" verFile
        Try {
            whr.Open("GET", ahkUrl ver "/" verFile)
            whr.Send()
            whr.WaitForResponse()
            verList[ver] := Map("latest",(newVer := Trim(whr.ResponseText," `t`r`n")))
            verList[ver]["list"] := (!Settings["AhkVersions"].Has(ver)) ? Map() : Settings["AhkVersions"][ver]["list"]
            
            If (!Settings["AhkVersions"].Has(ver) || Settings["AhkVersions"][ver]["latest"] != newVer)
                resultMsg .= (resultMsg?"`r`n`r`n":"") "New AutoHotkey v" ver " update!"
              , verList[ver]["list"] := RefreshDLList(ahkUrl ver "/")
        } Catch {
            errMsg .= (errMsg?"`r`n`r`n":"") "Could not reach AHK v" ver " page."
            msgbox whr.ResponseText
        }
    }
    whr := "" ; free whr obj
    
    (!errMsg) ? Settings["UpdateCheckDate"] := FormatTime(,"yyyy-MM-dd") : ""
    
    If (resultMsg) {
        Settings["AhkVersions"] := verList
        PopulateDLList()
        
        MsgBox resultMsg
    } Else If (confirm && !errMsg)
        Msgbox "No updates available."
    
    return errMsg
}

LaunchScript(hk:="") {
    Global Settings
    obj := {exe:0}
    
    If (sel := Explorer_GetSelection()) {
        a := StrSplit(sel,"`n","`r")
        Loop a.Length {
            SplitPath a[A_index],,,&ext
            If (ext != "ahk")
                Continue
            
            obj := proc_script(a[A_index])
            cmd := (obj.admin?"*RunAs ":"") obj.exe (obj.admin?" /restart ":" ") Chr(34) a[A_Index] Chr(34)
            (obj.exe) ? Run(cmd) : ""
        }
    }
    
    return !!obj.exe
}

LaunchCompiler(hk:="") {
    If (sel := Explorer_GetSelection()) {
        Loop Parse Explorer_GetSelection(), "`n", "`r"
        {
            SplitPath A_LoopField,,,&ext
            If (ext != "ahk")
               Continue
            obj := proc_script(A_LoopField, true)
            Run Chr(34) obj.exe Chr(34) " /in " Chr(34) A_LoopField Chr(34) " /gui"
        }
    }
}

LaunchEditor(hk:="") {
    Global Settings
    
    If (sel := Explorer_GetSelection()) {
        Loop Parse , "`n", "`r"
        {
            SplitPath A_LoopField,,,&ext
            If (ext != "ahk")
               Continue
            Run Chr(34) Settings["TextEditorPath"] Chr(34) " " Chr(34) A_LoopField Chr(34)
        }
    }
}

dbg(_in) {
    Loop Parse _in, "`n", "`r"
        OutputDebug "AHK: " A_LoopField
}

; ====================================================================================
; MButton:          Runs the selected script(s).
; SHIFT + MButton:  Opens selected script(s) in text editor.
; CTRL  + MButton:  Launches Ahk2Exe with selected script(s) filled in.  One instance per selection.
; ====================================================================================
#HotIf WinActive("ahk_exe explorer.exe")
MButton::LaunchScript(A_ThisHotkey)
+MButton::LaunchEditor(A_ThisHotkey)
^MButton::LaunchCompiler(A_ThisHotkey)

