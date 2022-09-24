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

Global oGui := "", Settings := ""

class app {
    Static ver := "v1.26"
         , lastClick := 0, last_click_diff := 1000, last_xy := 0
         , ReadOnly := false ; this is for launching a version of AHK, and is set to TRUE when doing so - prevents unnecessary saving settings to disk
         , toggle := 0, w := 480, h := 225
         , http := ComObject("Msxml2.XMLHTTP") ; Msxml2.XMLHTTP ; WinHttp.WinHttpRequest.5.1
         , http_url_list := []
         
         , latest_list := Map("AutoHotkey v1.1" ,{url:"https://www.autohotkey.com/download/1.1/version.txt"            , format:"html", filter:""}
                             ,"AutoHotkey v2.0" ,{url:"https://www.autohotkey.com/download/2.0/version.txt"            , format:"html", filter:""}
                             ,"Ahk2Exe"         ,{url:"https://api.github.com/repos/AutoHotkey/Ahk2Exe/releases/latest", format:"json", filter:"Ahk2Exe"}
                             ,"UPX"             ,{url:"https://api.github.com/repos/upx/upx/releases/latest"           , format:"json", filter:""})
         
         , get_list := Map("AutoHotkey v1.1"    ,{url:"https://www.autohotkey.com/download/1.1"                        , format:"html", filter:""}
                          ,"AutoHotkey v2.0"    ,{url:"https://www.autohotkey.com/download/2.0"                        , format:"html", filter:""}
                          ,"Ahk2Exe"            ,{url:"https://api.github.com/repos/AutoHotkey/Ahk2Exe/releases/latest", format:"json", filter:"Ahk2Exe"}
                          ,"UPX"                ,{url:"https://api.github.com/repos/upx/upx/releases/latest"           , format:"json", filter:""}
                          
                          ,"MPRESS" ,{url:"https://web.archive.org/web/20130516045244if_/http://www.matcode.com/mpress.219.zip", format:"zip", filter:""})
         
         , verUpdate := Map(), gui := ""
         , AhkDlVer := ["1.1","2.0"] ; versions of AHK inthe drop down menu, relates to the URL
}

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
Settings := (SettingsJSON && (SettingsJSON!='""')) ? Jxon_Load(&SettingsJSON) : Map()

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
(!Settings.Has("UpdateCheckDate")) ? Settings["UpdateCheckDate"] := "" : ""
(!Settings.Has("AddToPath")) ? Settings["AddToPath"] := 0 : ""
(!Settings.Has("CopyExe")) ? Settings["CopyExe"] := 0 : ""
(!Settings.Has("RegisterAHKexe")) ? Settings["RegisterAHKexe"] := 0 : ""

(!Settings.Has("ActiveVersionPath")) ? Settings["ActiveVersionPath"] := "" : ""
(!Settings.Has("ActiveVersionDisp")) ? Settings["ActiveVersionDisp"] := "" : ""

(!Settings.Has("TextEditorPath")) ? Settings["TextEditorPath"] := "notepad.exe" : ""

(!Settings.Has("DLVersion")) ? Settings["DLVersion"] := "2.0" : ""

(!Settings.Has("BaseFolder")) ? Settings["BaseFolder"] := "" : ""
(!Settings.Has("InstallProfile")) ? Settings["InstallProfile"] := "Current User" : ""
(!Settings.Has("reg")) ? Settings["reg"] := "HKEY_CURRENT_USER" : ""
(!Settings.Has("UPX")) ? Settings["UPX"] := "win32" : ""

If Settings["HideTrayIcon"] {
    A_IconHidden := true
}

app.latest_list["UPX"].filter := Settings["UPX"]
app.get_list["UPX"].filter := Settings["UPX"]
; ====================================================================================
; Processing Parameters for launching scripts and the Compiler.
; - Creates a 2nd instance in non-portable mode for a split second.
; ====================================================================================

If A_Args.Length {
    If FileExist(A_Args[1]) && RegExMatch(A_Args[1],"i).+\.ahk$") {
        A_Args[1] := "Launch"
        While A_Args.Has(2)
            A_Args.RemoveAt(2)
        
        old_args := A_Args
        For i, arg in old_args
            A_Args.Push(arg)
    }
    
    app.ReadOnly := true, in_file := A_Args[2], err := ""
    
    If !RegExMatch(A_Args[1],"(?:Compile|Launch(Admin)?)")
        err := "Invalid first parameter:`n`nParam one must be LAUNCH, LAUNCHADMIN, or COMPILE."
    Else If (A_Args.Length < 2)
        err := "Invalid second parameter.`n`nThere appears to be no script file specified."
    Else If !FileExist(in_file) && (in_file != "*")
        err := "Script file does not exist:`n`n" in_file
    If err {
        Msgbox(err,"ERROR",0x10)
        ExitApp
    }
    
    obj := proc_script(in_file, ((A_Args[1]="Compile")?true:false))
    SplitPath in_file,,&dir
    If RegExMatch(A_Args[1],"Launch(?:Admin)?") {
        obj.admin := (A_Args[1] = "LaunchAdmin") ? true : false ; set admin mode
        ahkCmd := (obj.admin?"*RunAs ":"") '"' obj.exe '"' (obj.admin?" /restart ":" ") '"' in_file '"' (sp()?" " sp():"")
    } Else If (A_Args[1] = "Compile")
        ahkCmd := '"' obj.exe '" /in "' in_file '" /gui'
    
    If obj.err {
        Msgbox obj.err
        ExitApp
    } Else If !FileExist(obj.exe) && obj.exe { ; i suppose this might not happen very often, or ever?
        msg := "The following EXE cannot be found:`n`n"
             . obj.exe "`n`n"
             . "Did you recently move or rename some folders?"
        Msgbox(msg,"File not found",0x10)
        ExitApp
    } Else If !obj.exe {
        msg := "The following #REQUIRES directive could not find a match:`n`n"
             . obj.cond "`n`n"
             . "Did you recently move or rename some folders?"
        Msgbox(msg,"No match found",0x10)
    }
    
    Run(ahkCmd, dir)
    ExitApp ; Close this instance after deciding which AHK.exe / compiler to run.
}

sp() { ; script params
    op := "", i := 3
    If (A_Args.Length >= 3) ; concat otherParams
        Loop (A_Args.Length - 2)
            op .= ((i>3) ? " " : "") '"' A_Args[i++] '"'
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

If (Settings["MinimizeOnStart"]) {
    If !Settings["CloseToTray"]
        runGui(true)
} Else RunGui()

runGui(minimize:=false) {
    Global oGui, Settings
    oGui := Gui("","AHK Portable Installer " app.ver)
    oGui.OnEvent("Close",gui_Close)
    
    oGui.Add("Text","vActiveVersionDisp xm y+8 w409 -E0x200 ReadOnly","Base Version:")
    oGui.Add("Button","vVersionDisp x+2 yp-4 w50","Latest").OnEvent("Click",GuiEvents)
    
    LV := oGui.Add("ListView","xm y+0 r5 w460 vExeList -Multi",["Description","Version","File Name","Full Path"])
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
    ctl := oGui.Add("ListView","vDLList xm y+10 w460 h181 -Multi",["File","Date"])
    ctl.SetFont("s8","Consolas")
    
    tabs.UseTab("Basics")
    oGui.Add("Text","xm y+10","Custom Base Folder:    (optional)")
    oGui.Add("Edit","y+0 r1 w410 vBaseFolder ReadOnly")
    oGui.Add("Button","x+0 vPickBaseFolder","...").OnEvent("Click",GuiEvents)
    oGui.Add("Button","x+0 vClearBaseFolder","X").OnEvent("Click",GuiEvents)
    
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
    
    oGui.Add("Checkbox","vAddToPath xm+10 y+10","Add to PATH on Install").OnEvent("Click",GuiEvents)
    oGui.Add("Checkbox","vCopyExe x+10",'Copy Installed EXE to "AutoHotkey.exe" on Install').OnEvent("Click",GuiEvents)
    oGui.Add("Checkbox","vRegisterAHKexe xm+10 y+10"
            ,'Register "AutoHotkey.exe" with .ahk files instead of Launcher on Install').OnEvent("Click",GuiEvents)
    
    oGui.Add("Text","xm+10 y+10","UPX:")
    oGui.Add("DropDownList","x+4 yp-3 w55 vUPX",["win32","win64"]).OnEvent("change",GuiEvents)
    
    oGui.Add("GroupBox","vHotkeys1 xm+10 y+10 w456 h60 y+4 Hidden","Hotkeys")
    txt := "MButton:`t`tRuns SELECTED scrtips in Explorer window/on desktop.`r`n"
         . "SHIFT + MButton:`tOpen script file in specified text editor.`r`n"
         . "CTRL + MButton:`tOpen the compiler with the selected script pre-filled."
    oGui.Add("Text","vHotkeys2 xp+10 yp+15 Hidden",txt)
    
    tabs.UseTab()
    
    oGui.Add("StatusBar","vStatusBar")
    app.gui := oGui
    
    x := Settings["posX"], y := Settings["posY"]
    PopulateSettings()
    ListExes()
    
    If (A_ScreenDPI != 96)
        app.h := 210
    
    oGui.Show("w" app.w " h" app.h " x" x " y" y (minimize?" Minimize":""))
    oGui["StatusBar"].SetText("Administrator: " (A_IsAdmin?"YES":"NO"))
    
    If !Settings["AhkVersions"].Count
        CheckUpdate(1)
    Else If Settings["AutoUpdateCheck"]
        CheckUpdate(,true)
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
    oGui["InstallProfile"].Text := Settings["InstallProfile"]
    oGui["AutoUpdateCheck"].value := Settings["AutoUpdateCheck"]
    oGui["TextEditorPath"].Value := Settings["TextEditorPath"]
    oGui["ShowEditScript"].Value := Settings["ShowEditScript"]
    oGui["ShowCompileScript"].Value := Settings["ShowCompileScript"]
    oGui["ShowRunScript"].Value := Settings["ShowRunScript"]
    oGui["DisableTooltips"].Value := Settings["DisableTooltips"]
    oGui["PortableMode"].Value := Settings["PortableMode"]
    oGui["AddToPath"].Value := Settings["AddToPath"]
    oGui["CopyExe"].Value := Settings["CopyExe"]
    oGui["RegisterAHKexe"].Value := Settings["RegisterAHKexe"]
    
    If (Settings["PortableMode"]) {
        oGui["ActivateExe"].Text := "Select"
        oGui["Uninstall"].Enabled := false
        oGui["Hotkeys1"].Visible := true
        oGui["Hotkeys2"].Visible := true
    } Else {
        oGui["ActivateExe"].Text := "Install"
        oGui["Uninstall"].Enabled := true
        oGui["Hotkeys1"].Visible := false
        oGui["Hotkeys2"].Visible := false
    }
    
    oGui["HideTrayIcon"].Value := Settings["HideTrayIcon"]
    oGui["CloseToTray"].Value := Settings["CloseToTray"]
    oGui["MinimizeOnStart"].Value := Settings["MinimizeOnStart"]
    oGui["PickIcon"].Text := Settings["PickIcon"]
    oGui["SystemStartup"].Value := Settings["SystemStartup"]
    oGui["UPX"].Text := Settings["UPX"]
    
    oGui["DLVersion"].Add(app.AhkDlVer)
    oGui["DLVersion"].Text := Settings["DLVersion"]
    
    PopulateDLList()
    SetActiveVersionGui()
}

GuiEvents(oCtl,Info) {
    Global Settings, oGui
    If (oCtl.Name = "ToggleSettings") {
        oGui["ExeList"].Focus()
        (app.toggle) ? oGui.Show("w" app.w " h" app.h) : oGui.Show("w480 h" ((A_ScreenDPI = 96) ? 480 : 465))
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
        SaveSettings()
        
    } Else If (oCtl.Name = "CheckUpdateNow") {
        CheckUpdate(1)
            
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
        } Else TraySetIcon("resources\AHK_pi_" oCtl.Text ".ico")
        
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
        PopulateDLList()
    
    } Else If (oCtl.Name = "Download") {
        DLFile()
    
    } Else If (oCtl.Name = "OpenFolder") {
        dest := (Settings["BaseFolder"] ? Settings["BaseFolder"] : A_ScriptDir "\versions")
        Run "explorer.exe " Chr(34) dest Chr(34)
    
    } Else If (oCtl.Name = "OpenTemp") {
        Run "explorer.exe " Chr(34) A_ScriptDir "\temp" Chr(34)
    
    } Else If (oCtl.Name = "VersionDisp") {
        oCtl.GetPos(&x,&y,,&h)
        verGui(x,y+h)
    
    } Else If (oCtl.Name = "AddToPath") || (oCtl.Name = "CopyExe") || (oCtl.Name = "RegisterAHKexe") {
        Settings[oCtl.Name] := oCtl.Value
        
        If (oCtl.Name = "CopyExe" && !oCtl.Value) {
            oCtl.gui["RegisterAHKexe"].Value := false
            Settings["RegisterAHKexe"] := false
        } Else If (oCtl.Name = "RegisterAHKexe" && oCtl.Value) {
            oCtl.gui["CopyExe"].Value := true
            Settings["CopyExe"] := true
        }
    } Else if (oCtl.name = "UPX") {
        Settings["UPX"] := oCtl.text
        Loop Files, A_ScriptDir "\temp\upx*.zip"
            FileDelete(A_LoopFileFullPath)
    }
}

verGui(x,y) {
    m := menu()
    For name, obj in Settings["AhkVersions"]
        m.Add(name ":  " obj["latest"] (app.verUpdate.Has(name) ? " *" : ""),(*) => "")
    m.Show(x,y)
}

PopulateDLList() {
    Global Settings
    LV := app.gui["DLList"]
    LV.Delete()
    name := "AutoHotkey v" app.gui["DLVersion"].Text
    LV.Opt("-Redraw")
    
    If (!name || !Settings["AhkVersions"].Has(name))
        return
    
    For _file, obj in Settings["AhkVersions"][name]["list"]
        If RegExMatch(_file,"\.zip$")
            LV.Add(,_file,obj["date"])
    
    LV.ModifyCol(1,300)
    LV.ModifyCol(2,120)
    LV.MOdifyCol(2,"SortDesc")
    LV.Opt("+Redraw")
}

DLFile() { ; download file if not already cached - then check hash if available
    Global Settings
    LV := app.gui["DLList"], name := "AutoHotkey v" app.gui["DLVersion"].Text, file_list := []
    If !(row := LV.GetNext()) {
        MsgBox "Select a download first."
        return
    }
    
    src := app.get_list[name].url "/"
    dest := (Settings["BaseFolder"] ? Settings["BaseFolder"] : A_ScriptDir "\versions") "\"
    destTemp := A_ScriptDir "\temp\"
    
    zipFile := LV.GetText(row)
    src_url := Settings["AhkVersions"][name]["list"][zipFile]["url"]
    SplitPath zipFile,,,,&fileTitle
    
    If !FileExist(destTemp zipFile) {
        app.gui["StatusBar"].SetText("Downloading " zipFile "...")
        Try Download src_url, destTemp zipFile
        Catch {
            Msgbox "Host could not be reached.  Check internet connection."
            return
        }
    }
    
    If (hash_file := check_hash()) {
        SplitPath hash_file,,,&hType
        
        src_url := Settings["AhkVersions"][name]["list"][hash_file]["url"]
        If !FileExist(destTemp hash_file)
            Download src hash_file, destTemp hash_file
        
        While !FileExist(destTemp hash_file)
            Sleep 100
        
        h1 := hash(destTemp zipFile,hType)
        h2 := FileRead(destTemp hash_file)
        
        If (h1 != h2) {
            Msgbox "File hash does not math!`r`n`r`nThe corrupt file will be deleted.`r`n`r`nTry redownloading the file."
            FileDelete destTemp zipFile
            FileDelete destTemp hash_file
            return
        }
    }
    
    dest := (Settings["BaseFolder"] ? Settings["BaseFolder"] : A_ScriptDir "\versions") "\" fileTitle
    If !DirExist(dest)
        DirCreate dest
    Else {
        Msgbox "Destination directory already exists.  Manually delete this folder and try again."
        return
    }
    
    app.gui["StatusBar"].SetText("Decompressing " zipFile "...")
    objShell := ComObject("Shell.Application")
    zipFile := objShell.NameSpace(A_ScriptDir "\temp\" zipFile)
    objShell.NameSpace(dest).CopyHere(zipFile.Items()), objShell := ""
    
    check_extras(dest)
    
    ListExes()
    app.gui["StatusBar"].SetText("")
    
    check_hash() {
        For i, hType in ["md2", "md4", "md5", "sha1", "sha256", "sha384", "sha512"] {
            If Settings["AhkVersions"][name]["list"].Has(zipFile "." hType)
                return zipFile "." hType
            Else If Settings["AhkVersions"][name]["list"].Has(zipFile "." StrUpper(hType))
                return zipFile "." StrUpper(hType)
        }
    }
}

check_extras(dest) {
    objShell := ComObject("Shell.Application")
    
    ahk2exe := check_github("Ahk2Exe")
    upx     := check_github("UPX")
    mpress  := check_mpress()
    
    If !DirExist(dest "\Compiler") { ; copy / extract Ahk2Exe if "Compiler" folder does not exist
        DirCreate dest "\Compiler"
        app.gui["StatusBar"].SetText("Decompressing " ahk2exe.update_file "...")
        zipFile := objShell.NameSpace(A_ScriptDir "\temp\" ahk2exe.update_file)
        objShell.NameSpace(dest "\Compiler").CopyHere(zipFile.Items())
    }
    
    If !FileExist(dest "\Compiler\upx.exe") { ; copy / extract upx.exe
        SplitPath upx.update_file,,,,&title
        objShell.NameSpace(dest "\Compiler").CopyHere(A_ScriptDir "\temp\" upx.update_file "\" title "\upx.exe")
    }
    
    If !FileExist(dest "\Compiler\mpress.exe") ; copy / extract mpress.exe
        objShell.NameSpace(dest "\Compiler").CopyHere(A_ScriptDir "\temp\" mpress.update_file "\mpress.exe")
    
    objShell := ""
}

check_mpress() {
    if !FileExist(A_ScriptDir "\temp\mpress.219.zip") {
        Try Download app.get_list["MPRESS"].url, A_ScriptDir "\temp\mpress.219.zip"
        Catch
            Msgbox "Checking MPRESS...`n`nHost could not be reached.  Check internet connection."
    }
    return obj := {file:"mpress.219.zip"
                 , ver:"2.19"
                 , update_file:"mpress.219.zip"
                 , update_url:""
                 , update_ver:""
                 , update_path:""
                 , path:A_ScriptDir "\temp\mpress.219.zip"}
}

check_github(name:="") {
    Global Settings
    result := "", path:="", update := Settings["AhkVersions"][name]
    github := file_check()
    
    If !(github.file) || (update["latest"] != github.ver) {
        If FileExist(github.path)
            FileDelete github.path
        
        Try Download github.update_url, A_ScriptDir "\temp\" github.update_file
        Catch
            Msgbox "Checking " name "...`n`nHost could not be reached.  Check internet connection."
    }
    
    return github
    
    file_check() {
        Loop Files A_ScriptDir "\temp\" name "*.zip"
            result := A_LoopFileName, path := A_LoopFileFullPath
        
        Switch name {
            Case "Ahk2Exe": ver := RegExReplace(result,"i)^Ahk2Exe(.+)\.zip","$1")
            Case "UPX"    : ver := RegExReplace(result,"i)^upx\-([^\-]+)\-","$1")
            Default: ver := ""
        }
        
        obj := {file:result
              , ver:ver
              , update_file:update["list"]["file"]
              , update_url:update["list"]["url"]
              , update_ver:update["latest"]
              , update_path:A_ScriptDir "\temp\" update["list"]["file"]
              , path:path}
        return obj
    }
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
        UninstallAhk()
    
    hive := Settings["reg"]
    launcher := (Settings["RegisterAHKexe"]) ? "AutoHotkey.exe" : "AHK_Portable_Installer.exe"
    
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
    
    ; reg.delete(hive "\Software\AutoHotkey")
    Sleep 350 ; make it easier to see something happenend when re-installing over same version
    
    ; define ProgID
    root := hive "\SOFTWARE\Classes\AutoHotkeyScript\Shell"
    If reg.add(hive "\SOFTWARE\Classes\AutoHotkeyScript","","AutoHotkey Script")    ; ProgID title
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add(hive "\SOFTWARE\Classes\AutoHotkeyScript\DefaultIcon","",'"' exeFullPath '",1')
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add(root,"","Open")
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    
    ; Compiler Context Menu (Ahk2Exe)
    If Settings["ShowCompileScript"] {
        If reg.add(root "\Compile","","Compile Script")                             ; Compile context menu entry
            MsgBox reg.reason "`r`n`r`n" reg.lastKey
        
        If (Settings["RegisterAHKexe"])
            compiler := '"' f.exeDir '\Compiler\Ahk2Exe.exe" /in "%1" /gui'
        Else
            compiler := '"' A_ScriptDir '\AHK_Portable_Installer.exe" "' A_ScriptFullPath '" Compile "%1"'
        
        If reg.add(root "\Compile\Command","",compiler)
            MsgBox reg.reason "`r`n`r`n" reg.lastKey
    }
    
    ; Edit Script
    If Settings["ShowEditScript"] {
        If reg.add(root "\Edit","","Edit Script")                                   ; Edit context menu entry
            MsgBox reg.reason "`r`n`r`n" reg.lastKey
        If reg.add(root "\Edit\Command","",'"' Settings["TextEditorPath"] '" "%1"') ; Edit command
            MsgBox reg.reason "`r`n`r`n" reg.lastKey
    } 
    
    ; Run Script
    If reg.add(root "\Open","","Run Script")
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    
    If (!Settings["RegisterAHKexe"])
        launcher := '"' A_ScriptDir '\AHK_Portable_Installer.exe" "' A_ScriptFullPath '" Launch "%1" %*'
    Else
        launcher := '"' A_ScriptDir '\AutoHotkey.exe" "%1" %*'
    
    If reg.add(root "\Open\Command","",launcher)                 ; Open verb/command
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    
    ; Run Script as Admin
    If Settings["ShowRunScript"] {
        If reg.add(root "\RunAs","","Run Script as Admin")
            MsgBox reg.reason "`r`n`r`n" reg.lastKey
        
        If (!Settings["RegisterAHKexe"])
            launcher := '"' A_ScriptDir '\AHK_Portable_Installer.exe" "' A_ScriptFullPath '" LaunchAdmin "%1" %*'
        Else
            launcher := '"' A_ScriptDir '\AutoHotkey.exe" "%1" %*'
        
        If reg.add(root "\RunAs\Command","",launcher)       ; RunAs verb/command
            MsgBox reg.reason "`r`n`r`n" reg.lastKey
    }
    
    ; Ahk2Exe entries
    If reg.add("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe","LastBinFile",f.type " " f.bitness "-bit.bin")   ; auto set .bin file
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe","LastUseMPRESS",mpress)      ; auto set mpress usage
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
    
    If reg.add(hive "\Software\AutoHotkey","MajorVersion",f.majVersion)         ; just in case it's helpful
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add(hive "\Software\AutoHotkey","InstallExe",exeFullPath)
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add(hive "\Software\AutoHotkey","InstallBitness",f.bitness "-bit")
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    If reg.add(hive "\Software\AutoHotkey","InstallProduct",Settings["ActiveVersionDisp"])
        MsgBox reg.reason "`r`n`r`n" reg.lastKey
    
    AddToPath() ; always run this to have opportunity to remove the ahk-pi path

    If FileExist("AutoHotkey.exe")
        FileDelete A_ScriptDir "\AutoHotkey.exe"
    
    If Settings["CopyExe"] {
        _file := FileRead(Settings["ActiveVersionPath"],"RAW")
        FileAppend _file, "AutoHotkey.exe", "RAW"
    }
    
    DllCall("shell32\SHChangeNotify", "uint", 0x08000000, "uint", 0, "int", 0, "int", 0) ; thanks lexikos!
    
    SetActiveVersionGui()
}

AddToPath() {
    Global Settings
    
    hive := Settings["reg"]
    
    key := hive . ((hive="HKEY_CURRENT_USER") ? "\Environment" : "\SYSTEM\CurrentControlSet\Control\Session Manager\Environment")
    list := StrSplit(orig_list := RegRead(key,"Path"),";")
    
    list.Push(A_ScriptDir) ; testing final result
    
    new_list := []
    For i, _path in list
        If (_path && !RegExMatch(_path,"i)^\Q" A_ScriptDir "\E")) ; clear old ahk PATH contribution
            new_list.Push(_path)
    
    If (Settings["AddToPath"] && (hive = "HKEY_CURRENT_USER") || (hive = "HKEY_LOCAL_MACHINE" && A_IsAdmin))
        new_list.Push(A_ScriptDir) ; only add path under proper conditions (previous line)
    
    str := ""
    For i, _path in new_list
        str .= _path ";"
    
    If (str != orig_list)                           ; Only modify the path if there is a change.
        RegWrite str, "REG_EXPAND_SZ", key, "Path"  ; This can be a removal or adding of ahk-pi path.
}

UninstallAhk() {
    Global Settings, oGui
    
    userchoice := true, result := "yes"
    Try RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ahk\UserChoice","Hash")
    Catch
        userchoice := false
    
    If userchoice {
        msg := "UserChoice for the .ahk extension has been activated.  This will interfere with the normal functionality of AHK PI.`n`n"
             . "This usually happens when the user uses 'Open With' and checks the checkbox to 'always use' the selected app to open .ahk files."
             . "To remove this key, simply click 'Yes' to continue."
             
        If msgbox(msg,"User Attention Required",4) != "yes"
            userchoice := false
    }
    
    If userchoice
        reg.delete("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ahk\UserChoice")
    
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
    
    DllCall("shell32\SHChangeNotify", "uint", 0x08000000, "uint", 0, "int", 0, "int", 0) ; thanks lexikos!
}

gui_Close(o) {
    Global Settings
    
    app.gui.GetPos(&x,&y,&w,&h), dims := {x:x, y:y, w:w, h:h}
    Settings["posX"] := dims.x, Settings["posY"] := dims.y
    
    If Settings["CloseToTray"] {
        app.gui.Destroy()
        return
    }
    
    ExitApp
}

on_exit(*) {
    Global Settings
    If (!app.ReadOnly) ; don't re-save every time script is launched by the registry
        SaveSettings()
}

SaveSettings() {
    Global Settings
    Try FileDelete "Settings.json"
    SettingsJSON := Jxon_Dump(Settings,4)
    FileAppend SettingsJSON, "Settings.json"
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
        
        regVer := (InstProd && ver) ? (InstProd) : ""
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
    Global Settings
    
    If (!override) {
        If (Settings["AutoUpdateCheck"] = 0)
            return
        Else If ( Settings["UpdateCheckDate"] = FormatTime(,"yyyy-MM-dd") )
            return
    }
    
    app.verUpdate := Map() ; reset recorded updates
    
    For name, obj in app.latest_list
        app.http_url_list.Push({url:obj.url, name:name, type:"version", format:obj.format, confirm:confirm, filter:obj.filter})
    ProcessURLs()
}

ProcessURLs() {
    If !app.http_url_list.Length
        return
    
    obj := app.http_url_list[1]
    Try {
        app.http.Open("GET", obj.url, true)
        app.http.onreadystatechange := CheckUpdate_callback.Bind(obj)
        app.http.Send()
    } Catch Error {
        msg := "Could not reach " obj.name " page."
        Msgbox msg, "Update Check Failed", 0x10
    }
}

CheckUpdate_callback(obj) {
    Global Settings
    
    if (app.http.readyState != 4) ; not ready yet
        return
    
    If (obj.type = "version") {
        
        if (app.http.Status != 200) {
            
            obj.confirm := false
            obj.status := "failed: " app.http.Status
            msg := "Could not reach " obj.name " page."
            MsgBox(msg, "Update Check Failed", 0x10)
            app.http_url_list := []     ; url clear list
            app.verUpdate := Map()      ; clear current updates list
            
        } else {
            result := app.http.ResponseText
            if obj.format = "json"
                result := jxon_load(&result), result := RegExReplace(result["name"],"i)^" obj.name " *v?")
            
            If  (!Settings["AhkVersions"].Has(obj.name)
              || (Settings["AhkVersions"][obj.name]["latest"] != result)
              || (Settings["AhkVersions"][obj.name]["list"].Count = 0)) { ; need to get download list for indicatd name
                
                app.http_url_list.Push({    url:app.get_list[obj.name].url ; add url to get download list
                                      ,    name:obj.name
                                      ,    type:"list"
                                      ,  format:app.get_list[obj.name].format
                                      , confirm:obj.confirm
                                      ,  filter:app.get_list[obj.name].filter})
                
                app.verUpdate[obj.name] := result
                Settings["AhkVersions"][obj.name] := Map("latest",result,"list",Map())
            }
            
            Settings["UpdateCheckDate"] := FormatTime(,"yyyy-MM-dd")
            app.http_url_list.RemoveAt(1) ; remove processed item
            ProcessURLs() ; process next url
        }
    } Else if (obj.type = "list") {
        
        If (response:=app.http.ResponseText) && (obj.format = "html")
            list := format_html(response)
        else
            list := format_json(response,obj.filter)
        
        Settings["AhkVersions"][obj.name]["list"] := list
        
        app.http_url_list.RemoveAt(1) ; remove processed item
        ProcessURLs() ; process next url
    
        if !app.http_url_list.Length { ; when finished, display confirmation if enabled
            if (obj.confirm) {
                if (app.verUpdate.Count) {
                    If !InStr(title := app.gui.Title,"Update Available")
                        app.gui.Title := title "   (Update Available!)"
                }
            }
            
            Settings["UpdateCheckDate"] := FormatTime(,"yyyy-MM-dd")
            PopulateDLList()
        }
    }
    
    format_html(txt) {
        list := Map(), ver := RegExReplace(obj.name,"AutoHotkey *v?","")
        Loop Parse, txt, "`n", "`r"
        {
            If (r1 := RegExMatch(A_LoopField,'<a href="([^>]+)">',&m)
            && (r2 := RegExMatch(A_LoopField,'<td align="right">([^<]+)',&n))) {
                If (m[1] = "/") || (m[1] = "/download/") || (m[1] = "version.txt")
                || (m[1] = "_AHK-binaries.zip") || (m[1] = "zip%20versions/") || InStr(m[1],"Ahk2Exe")
                    Continue
                If InStr(m[1],".zip") {
                    item := Map("date",Trim(n[1]," `t"),"url",obj.url "/" m[1])
                    list[m[1]] := item
                }
            }
        }
        return list
    }
    
    format_json(txt,filter:="") {
        _map := jxon_load(&txt), idx := 1
        
        While _map["assets"].Has(idx) {
            url := _map["assets"][idx]["browser_download_url"]
            _file := (arr:=StrSplit(url,"/"))[arr.Length]
            If InStr(url,filter)
                return Map("date",_map["published_at"],"url" ,url,"file",_file)
            idx++
        }
    }
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

