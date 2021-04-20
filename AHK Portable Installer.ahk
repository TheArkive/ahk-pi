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

#SingleInstance Off ; Allow multiple instances, for when running in non-portable mode.
                    ; This installer script is "consulted" when launching a script or when
                    ; launching the compiler.  So for a split second, there needs to be 2
                    ; instances of the script while this "consulting" takes place.  Once
                    ; the end result is finally launched, this 2nd instance closes.

SendMode "Input"  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

#INCLUDE inc\_JXON.ahk
#INCLUDE inc\_RegexInput.ahk
#INCLUDE inc\TheArkive_reg2.ahk
#INCLUDE inc\funcs.ahk

Global oGui := "", Settings := "", AhkPisVersion := "v1.16", regexList := Map(), mode := "gui"

OnExit(on_exit)

If (A_Is64BitOS)
    reg.view := 64

If (FileExist("Settings.json.blank") And !FileExist("Settings.json"))
    FileMove "Settings.json.blank", "Settings.json"

SettingsJSON := FileRead("Settings.json")
Settings := Jxon_Load(&SettingsJSON)
Settings["toggle"] := 0 ; load settings
regexList := Settings["regexList"]

If Settings["HideTrayIcon"]
    A_IconHidden := true

; ====================================================================================
; ====================================================================================
; Processing Parameters for launching scripts and the Compiler.
; - Creates a 2nd instance in non-portable mode for a split second.
; ====================================================================================

If A_Args.Length {
    mode := "cli"
    
    If (A_Args[1] != "Launch" And A_Args[1] != "Compile")
        throw Error("Invalid first parameter.",,"Param one must be LAUNCH or COMPILE.")
    
    If (A_Args.Length < 2)
        throw Error("Invalid second parameter.",,"There appears to be no script file specified.")
    
    in_file := A_Args[2], otherParams := ""
    If !FileExist(in_file)
        throw Error("Script file does not exist.",,in_file)
    
    If A_Args[1] = "Launch" {
        exe := proc_script(in_file)
        If (A_Args.Length > 3) {
            i := 3
            Loop (A_Args.Length - 2)
                otherParams .= ((i++>3)?" ":"") Chr(34) Chr(34)
        }
        
        Run Chr(34) exe Chr(34) " " Chr(34) in_file Chr(34) (otherParams?" " otherParams:"")
    } Else If A_Args[1] = "Compile" {
        exe := proc_script(in_file, true)
        Run Chr(34) exe Chr(34) " /in " Chr(34) in_file Chr(34) " /gui"
    }
    
    ExitApp ; Close this instance after deciding which AHK.exe / compiler to run.
}

; ====================================================================================
; ====================================================================================

If Settings["PickIcon"] = "Default" {
    ahkProps := GetAhkProps(Settings["ActiveVersionPath"])
    if ahkProps
        TraySetIcon(ahkProps["exePath"],0)
} Else TraySetIcon("AHK_pi_" Settings["PickIcon"] ".ico")

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
                  . "Modify settings as desired first, including templates.`r`nThen click this button."
                  
        Else If (hwnd = oGui["ExeList"].Hwnd)
            ToolTip "List of Base Versions to choose from.`r`n"
                  . "Double-click to activate.  Same as pressing [Activate EXE].`r`nBe sure to modify settings as desired first, including templates."
                  
        Else If (hwnd = oGui["CurrentPath"].Hwnd)
            ToolTip oGui["CurrentPath"].Value
            
        Else If (hwnd = oGui["Ahk2ExeHandler"].Hwnd)
            ToolTip "When the Ahk2Exe Handler is enabled, the [first-line version comment]`r`n"
                  . "is used to determine which compiler to launch.  When disabled, the compiler`r`n"
                  . "for the selected base version is launched.  The script file path and name`r`n"
                  . "will be pre-filled in the Source field."
                  
        Else If (hwnd = oGui["AhkLauncher"].Hwnd)
            ToolTip "When enabled, the [first-line version comment] in the script will determine which`r`n"
                  . "AutoHotkey EXE is used to run the script.  When disabled, the selected base version`r`n"
                  . "is always used to run every script."
                  
        Else If (hwnd = oGui["RegexExeAdd"].Hwnd)
            ToolTip "Add a parallel EXE match option.`r`n"
                  . "Each entry will specify a match pattern for the [first-line version comment],`r`n"
                  . "a match type (regex/exact), and which EXE to use to lauch a script."
            
        Else If (hwnd = oGui["RegexExeRemove"].Hwnd)
            ToolTip "Remove a parallel EXE match option."
            
        Else If (hwnd = oGui["AhkParallelList"].Hwnd)
            ToolTip "Double-click to edit."
        
        Else
            ToolTip
    }
}

If (Settings["MinimizeOnStart"]) {
    If !Settings["CloseToTray"]
        runGui(true)
} Else RunGui()

runGui(minimize:=false) {
    Global oGui, AhkPisVersion, Settings
    oGui := Gui("-DPIScale","AHK Portable Installer " AhkPisVersion)
    oGui.OnEvent("Close",gui_Close)
    
    Ahk1Version := (Settings.Has("Ahk1Version")) ? Settings["Ahk1Version"] : ""
    Ahk2Version := (Settings.Has("Ahk2Version")) ? Settings["Ahk2Version"] : ""
    Ahk1Html := "<a href=" Chr(34) StrReplace(Settings["Ahk1Url"],"version.txt","") Chr(34) ">AHKv1:</a>    " Ahk1Version
    Ahk2Html := "<a href=" Chr(34) StrReplace(Settings["Ahk2Url"],"version.txt","") Chr(34) ">AHKv2:</a>    " Ahk2Version
    
    oGui.Add("Link","vAhk1Version xm w220",Ahk1Html).OnEvent("Click",LinkEvents)
    oGui.Add("Link","vAhk2Version x+0 w220",Ahk2Html).OnEvent("Click",LinkEvents)
    oGui.Add("Edit","vActiveVersionDisp xm y+8 w440 -E0x200 ReadOnly","Base Version:")
    
    LV := oGui.Add("ListView","xm y+0 r5 w460 vExeList",["Description","Version","File Name","Full Path"])
    LV.OnEvent("DoubleClick",GuiEvents), LV.OnEvent("Click",ListClick)
    
    oGui.Add("Edit","vCurrentPath xm y+8 w440 -E0x200 ReadOnly","Path:    ")
    
    oGui.Add("Button","vToggleSettings y+0","Settings").OnEvent("Click",GuiEvents)
    oGui.Add("Button","vHelp x+40","Help").OnEvent("Click",GuiEvents)
    oGui.Add("Button","vCompiler x+0","Compiler").OnEvent("Click",GuiEvents)
    oGui.Add("Button","vWindowSpy x+0","Window Spy").OnEvent("Click",GuiEvents)
    oGui.Add("Button","vUninstall x+0","Uninstall AHK").OnEvent("Click",GuiEvents)
    oGui.Add("Button","vActivateExe x+40 yp","Activate EXE").OnEvent("Click",GuiEvents)
    
    tabs := oGui.Add("Tab","y+10 x2 w476 h275",["Basics","AHK Launcher","Options"])
    
    oGui.Add("Text","xm y+10","Base AHK Folder:    (Leave blank for program directory)")
    oGui.Add("Edit","y+0 r1 w410 vBaseFolder ReadOnly")
    oGui.Add("Button","x+0 vPickBaseFolder","...").OnEvent("Click",GuiEvents)
    oGui.Add("Button","x+0 vClearBaseFolder","X").OnEvent("Click",GuiEvents)
    oGui.Add("Text","xm y+4","AutoHotkey v1 URL:")
    oGui.Add("Edit","y+0 r1 w460 vAhk1Url").OnEvent("Change",GuiEvents)
    oGui.Add("Text","xm y+4","AutoHotkey v2 URL:")
    oGui.Add("Edit","y+0 r1 w460 vAhk2Url").OnEvent("Change",GuiEvents)
    
    oGui.Add("Checkbox","vAhk2ExeHandler xm y+10","Use Ahk2Exe handler").OnEvent("Click",GuiEvents)
    oGui.Add("Checkbox","vAhkLauncher x+30","Use AHK Launcher").OnEvent("Click",GuiEvents)
    oGui.Add("Checkbox","vDisableTooltips x+30","Disable Tooltips").OnEvent("Click",GuiEvents)
    
    oGui.Add("Checkbox","vAutoUpdateCheck xm y+10","Automatically check for updates").OnEvent("Click",GuiEvents)
    oGui.Add("Button","vCheckUpdateNow x+173 yp-4","Check Updates Now").OnEvent("Click",GuiEvents)
    
    oGui.Add("Text","xm y+4","Text Editor:")
    oGui.Add("Edit","xm y+0 w410 vTextEditorPath ReadOnly")
    oGui.Add("Button","x+0 vPickTextEditor","...").OnEvent("Click",GuiEvents)
    oGui.Add("Button","x+0 vDefaultTextEditor","X").OnEvent("Click",GuiEvents)
    
    oGui.Add("Button","vEditAhk1Template xm y+10 w230","Edit AHK v1 Template").OnEvent("Click",GuiEvents)
    oGui.Add("Button","vEditAhk2Template x+0 w230","Edit AHK v2 Template").OnEvent("Click",GuiEvents)
    
    tabs.UseTab("AHK Launcher")
    
    LV := oGui.Add("ListView","vAhkParallelList xm y+5 w460 h218",["Label","Match String"])
    LV.OnEvent("click",GuiEvents)
    LV.OnEvent("doubleclick",regex_edit)
    LV.ModifyCol(1,160), LV.ModifyCol(2,260)
    LV.SetFont("s8","Courier New")
    
    oGui.Add("Edit","vRegexExe xm y+0 w410 ReadOnly")
    oGui.Add("Button","vRegexExeAdd x+0 w25","+").OnEvent("Click",GuiEvents)
    oGui.Add("Button","vRegexExeRemove x+0 w25","-").OnEvent("Click",GuiEvents)
    
    tabs.UseTab("Options")
    
    oGui.Add("GroupBox","xm w456 h40 y+4","Context Menu - Only applies when Full Portable Mode is disabled")
    oGui.Add("Checkbox","vShowEditScript xp+10 yp+20","Show " Chr(34) "Edit Script" Chr(34)).OnEvent("Click",GuiEvents)
    oGui.Add("Checkbox","vShowCompileScript x+30","Show " Chr(34) "Compile Script" Chr(34)).OnEvent("Click",GuiEvents)
    oGui.Add("Checkbox","vShowRunScript x+30","Show " Chr(34) "Run Script" Chr(34)).OnEvent("Click",GuiEvents)
    
    oGui.Add("Checkbox","vPortableMode y+15 xm+10","Fully Portable Mode").OnEvent("Click",GuiEvents)
    oGui.Add("Checkbox","vHideTrayIcon x+25","Hide Tray Icon").OnEvent("Click",GuiEvents)
    oGui.Add("Checkbox","vCloseToTray x+67","Close to Tray").OnEvent("Click",GuiEvents)
    oGui.Add("Checkbox","vMinimizeOnStart y+10 xm+10","Minimize on Startup").OnEvent("Click",GuiEvents)
    
    oGui.Add("Text","x+26","Icon:")
    oGui.Add("DropDownList","vPickIcon w70 x+4 yp-3",["Default","Blue","Green","Orange","Pink","Red"]).OnEvent("Change",GuiEvents)
    
    oGui.Add("Checkbox","vSystemStartup x+61 yp+3","Run on system startup").OnEvent("Click",GuiEvents)
    
    x := Settings["posX"], y := Settings["posY"]
    PopulateSettings()
    ListExes()
    
    oGui.Show("w480 h220 x" x " y" y (minimize?" Minimize":""))
    
    result := CheckUpdate()
    If (result And result != "NoUpdate")
        MsgBox result, "Update Check Failed", 0x10
}

make_ahk2exe_menu(x,y) {
    MouseGetPos &x, &y
    
}

PopulateSettings() {
    Global Settings, oGui
    SetActiveVersionGui()
    
    If (!Settings.Has("BaseFolder"))
        Settings["BaseFolder"] := ""
    BaseFolder := Settings["BaseFolder"]
    oCtl := oGui["BaseFolder"], oCtl.Value := BaseFolder
    
    Ahk1Url := (!Settings.Has("Ahk1Url") Or Settings["Ahk1Url"] = "") ? "" : Settings["Ahk1Url"]
    oCtl := oGui["Ahk1Url"], oCtl.Value := Ahk1Url
    
    Ahk2Url := (!Settings.Has("Ahk2Url") Or Settings["Ahk2Url"] = "") ? "" : Settings["Ahk2Url"]
    oCtl := oGui["Ahk2Url"], oCtl.Value := Ahk2Url
    
    If (!Settings.Has("AutoUpdateCheck"))
        Settings["AutoUpdateCheck"] := 0
    oGui["AutoUpdateCheck"].value := Settings["AutoUpdateCheck"]
    
    If (!Settings.Has("TextEditorPath") Or Settings.Has("TextEditorPath") = "")
        Settings["TextEditorPath"] := "notepad.exe"    ; set default script text editor if blank
    If (!FileExist(Settings["TextEditorPath"]))
        Settings["TextEditorPath"] := "notepad.exe"    ; set default script text editor if specified doesn't exist
    
    TextEditorPath := Settings["TextEditorPath"]
    oCtl := oGui["TextEditorPath"], oCtl.Value := TextEditorPath
    
    If (!Settings.Has("Ahk2ExeHandler"))
        Settings["Ahk2ExeHandler"] := 0
    oGui["Ahk2ExeHandler"].Value := Settings["Ahk2ExeHandler"]
    
    If (!Settings.Has("AhkLauncher"))
        Settings["AhkLauncher"] := 0
    oGui["AhkLauncher"].Value := Settings["AhkLauncher"]
    
    If (!Settings.Has("ShowEditScript"))
        Settings["ShowEditScript"] := 0
    oGui["ShowEditScript"].Value := Settings["ShowEditScript"]
    
    If (!Settings.Has("ShowCompileScript"))
        Settings["ShowCompileScript"] := 0
    oGui["ShowCompileScript"].Value := Settings["ShowCompileScript"]
    
    If (!Settings.Has("ShowRunScript"))
        Settings["ShowRunScript"] := 0
    oGui["ShowRunScript"].Value := Settings["ShowRunScript"]
    
    If (!Settings.Has("DisableTooltips"))
        Settings["DisableTooltips"] := 0
    oGui["DisableTooltips"].Value := Settings["DisableTooltips"]
    
    If (!Settings.Has("PortableMode"))
        Settings["PortableMode"] := 0
    oGui["PortableMode"].Value := Settings["PortableMode"]
    
    If (!Settings.Has("HideTrayIcon"))
        Settings["HideTrayIcon"] := 0
    oGui["HideTrayIcon"].Value := Settings["HideTrayIcon"]
    
    If (!Settings.Has("CloseToTray"))
        Settings["CloseToTray"] := 0
    oGui["CloseToTray"].Value := Settings["CloseToTray"]
    
    If (!Settings.Has("MinimizeOnStart"))
        Settings["MinimizeOnStart"] := 0
    oGui["MinimizeOnStart"].Value := Settings["MinimizeOnStart"]
    
    If (!Settings.Has("PickIcon"))
        Settings["PickIcon"] := 0
    oGui["PickIcon"].Text := Settings["PickIcon"]
    
    If (!Settings.Has("SystemStartup"))
        Settings["SystemStartup"] := 0
    oGui["SystemStartup"].Value := Settings["SystemStartup"]
    
    regexRelist()
    
    oCtl := ""
}

GuiEvents(oCtl,Info) { ; Ahk2ExeHandler
    Global regexList, Settings, oGui
    If (oCtl.Name = "ToggleSettings") {
        toggle := Settings["toggle"]
        
        If (toggle)
            oGui.Show("w480 h220"), Settings["toggle"] := 0
        Else
            oGui.Show("w480 h500"), Settings["toggle"] := 1
            
    } Else If (oCtl.Name = "Compiler") {
        ahkProps := GetAhkProps(Settings["ActiveVersionPath"])
        Run ahkProps["installDir"] "\Compiler\Ahk2Exe.exe"
        
    } Else If (oCtl.Name = "ActivateExe" or oCtl.Name = "ExeList") {
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
        BaseFolder := DirSelect("*" BaseFolder,"","Select the base AHK folder:")
        
        If (BaseFolder And DirExist(BaseFolder)) {
            oGui["BaseFolder"].Value := BaseFolder
            Settings["BaseFolder"] := BaseFolder
            ListExes()
        } Else If (!DirExist(BaseFolder) And BaseFolder != "")
            MsgBox "Chosen folder does not exist."
            
    } Else If (oCtl.Name = "Ahk1Url") {
        Settings["Ahk1Url"] := oCtl.Value
        
    } Else If (oCtl.Name = "Ahk2Url") {
        Settings["Ahk2Url"] := oCtl.Value
        
    } Else If (oCtl.Name = "DefaultTextEditor") {
        oGui["TextEditorPath"].Value := "notepad.exe", Settings["TextEditorPath"] := "notepad.exe"
        
    } Else If (oCtl.Name = "PickTextEditor") {
        textPath := (Settings["TextEditorPath"] = "notepad.exe") ? A_WinDir "\notepad.exe" : Settings["TextEditorPath"]
        TextEditorPath := FileSelect("",textPath,"Select desired text editor:","Executable (*.exe)")
        
        If (TextEditorPath) {
            oGui["TextEditorPath"].Value := TextEditorPath
            Settings["TextEditorPath"] := TextEditorPath
        }
        
    } Else If (oCtl.Name = "Help") {
        curExe := Settings["ActiveVersionPath"]
        If (FileExist(curExe)) {
            ahkProps := GetAhkProps(curExe)
            installDir := ahkProps["installDir"]
            
            Loop Files installDir "\*.chm"
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
        
    } Else If (oCtl.Name = "Uninstall") {
        If (MsgBox("Remove AutoHotkey from registry?","Uninstall AutoHotkey",0x24) = "Yes")
            UninstallAhk()
            
    } Else If (oCtl.Name = "Ahk2ExeHandler") {
        Settings["Ahk2ExeHandler"] := oCtl.value
        
    } Else If (oCtl.Name = "AhkLauncher") {
        Settings["AhkLauncher"] := oCtl.Value
        
    } Else If (oCtl.Name = "DisableTooltips") {
        Settings[oCtl.Name] := oCtl.Value
        
    } Else if (oCtl.Name = "RegexExeAdd") {
        guiAddRegex()
        oCtl.gui["RegexExe"].Value := ""
        
    } Else If (oCtl.Name = "RegexExeRemove") {
        LstV := oCtl.gui["AhkParallelList"] ; ListView
        curRow := LstV.GetNext(), curKey := LstV.GetText(curRow,1)
        regexList.Delete(curKey)
        regexRelist()
        oCtl.Gui["RegexExe"].Value := ""
        
    } Else If (oCtl.Name = "AhkParallelList") {
        curLabel := oCtl.GetText(oCtl.GetNext())
        If (oCtl.GetNext()) {
            curExe := regexList[curLabel]["exe"]
            oCtl.gui["RegexExe"].Value := curExe
        }
        
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
            ahkProps := GetAhkProps(Settings["ActiveVersionPath"])
            TraySetIcon(ahkProps["exePath"],0)
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
                ahkProps := GetAhkProps(Settings["ActiveVersionPath"])
                icon := ahkProps["exePath"]
            } Else icon := A_ScriptDir "\AHK_pi_" Settings["PickIcon"] ".ico"
            
            FileCreateShortcut exe, lnk,,,,icon
        } Else If FileExist(lnk)
            FileDelete lnk
    }
}

ActivateEXE() {
    Global Settings, oGui
    
    LV := oGui["ExeList"] ; ListView
    row := LV.GetNext(), exeFullPath := LV.GetText(row,4)
    
    If !Settings["PortableMode"]
        UninstallAhk() ; ... shouldn't need this
    
    ; props: ahkProduct, ahkVersion, installDir, ahkType, bitness, exeFile, exePath, exeDir, variant
    ahkProps := GetAhkProps(exeFullPath)
    exeDir := ahkProps["exeDir"]
    exeFile := ahkProps["exeFile"]
    
    ver := ahkProps["ahkVersion"]
    prod := ahkProps["ahkProduct"]
    ahkType := ahkProps["ahkType"]
    isAhkH := ahkProps["isAhkH"]
    bitness := ahkProps["bitness"]
    MT := ahkProps["variant"]
    installDir := ahkProps["installDir"]
    
    installProduct := prod " " ahkType " " bitness
    majorVer := SubStr(ver,1,1) = "v" ? SubStr(ver,2,1) : SubStr(ver,1,1)
    
    ActiveVersion := Trim(prod " " ahkType " " bitness " " MT) " " ver
    Settings["ActiveVersionDisp"] := ActiveVersion
    Settings["ActiveVersionPath"] := exeFullPath
    
    dispCtl := oGui["ActiveVersionDisp"], dispCtl.Text := "Installed:    ", dispCtl := "" ; clear active version
    
    Ahk2ExeHandler := Settings["Ahk2ExeHandler"]
    Ahk2ExePath := installDir "\Compiler\Ahk2Exe.exe" ; new Ahk2Exe ...
    TextEditorPath := Settings["TextEditorPath"]
    Ahk2ExeBin := ahkType " " bitness ".bin"
    mpress := (FileExist(installDir "\Compiler\mpress.exe")) ? 1 : 0
    
    template := "TemplateV" majorVer ".ahk"
    templateText := FileRead("resources\" template)
    
    If Settings["PortableMode"] {
        SetActiveVersionGui()
        return
    }
    
    ; .ahk extension and template settings
    If reg.add("HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.ahk","","AutoHotkeyScript")
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    If reg.add("HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.ahk\ShellNew","ItemName","AutoHotkey Script v" majorVer)
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    If reg.add("HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.ahk\ShellNew","FileName","Template.ahk")
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    
    ; update template according to majorVer
    If !FileExist(A_WinDir "\ShellNew")
        DirCreate A_WinDir "\ShellNew"
    Try FileDelete A_WinDir "\ShellNew\Template.ahk"
    FileAppend templateText, A_WinDir "\ShellNew\Template.ahk"
    
    reg.delete("HKEY_LOCAL_MACHINE\Software\AutoHotkey")
    
    Sleep 350 ; make it easier to see something happenend when re-installing over same version
    
    ; define ProgID
    root := "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell" (Settings["CascadeMenu"] ? "\AutoHotkey\Shell" : "")
    If reg.add("HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript","","AutoHotkey Script v" majorVer) ; ProgID title, asthetic only?
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    If reg.add("HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\DefaultIcon","",Chr(34) exeFullPath Chr(34) ",1")
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    If reg.add(root,"","Open")
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    
    ; Compiler Context Menu (Ahk2Exe)
    If Settings["ShowCompileScript"] {
        If reg.add(root "\Compile","","Compile Script")                                                ; Compile context menu entry
            MsgBox reg.reason "`r`n`r`n" reg.cmd
        
        _step1 := Chr(34) A_ScriptDir "\AHK Portable Installer.exe" Chr(34) " " Chr(34) A_ScriptFullPath Chr(34)
        regVal := _step1 " Compile " Chr(34) "%1" Chr(34) 
        
        If reg.add(root "\Compile\Command","",regVal)
            MsgBox reg.reason "`r`n`r`n" reg.cmd
    }
    
    ; Edit Script
    If Settings["ShowEditScript"] {
        If reg.add(root "\Edit","","Edit Script")                                                      ; Edit context menu entry
            MsgBox reg.reason "`r`n`r`n" reg.cmd
        If reg.add(root "\Edit\Command","",Chr(34) TextEditorPath Chr(34) " " Chr(34) "%1" Chr(34))    ; Edit command
            MsgBox reg.reason "`r`n`r`n" reg.cmd
    }
    
    ; Run Script
    If reg.add(root "\Open","","Run Script")
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    
    _step1 := Chr(34) A_ScriptDir "\AHK Portable Installer.exe" Chr(34) " " Chr(34) A_ScriptFullPath Chr(34)
    regVal := _step1 " Launch " Chr(34) "%1" Chr(34) " %*"
    
    If reg.add(root "\Open\Command","",regVal)                                                 ; Open verb/command
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    
    ; Ahk2Exe entries
    If reg.add("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe","LastBinFile",Ahk2ExeBin)   ; auto set .bin file
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    If reg.add("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe","LastUseMPRESS",mpress)     ; auto set mpress usage
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    If reg.add("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe","Ahk2ExePath",Ahk2ExePath)  ; for easy reference...
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    If reg.add("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe","BitFilter",bitness)
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    
    ; HKLM / Software / AutoHotkey install and version info
    If reg.add("HKEY_LOCAL_MACHINE\Software\AutoHotkey","InstallDir",installDir)              ; Default entries
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    If reg.add("HKEY_LOCAL_MACHINE\Software\AutoHotkey","StartMenuFolder","AutoHotkey")       ; Default entries
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    If reg.add("HKEY_LOCAL_MACHINE\Software\AutoHotkey","Version",ver)                        ; Default entries
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    
    If reg.add("HKEY_LOCAL_MACHINE\Software\AutoHotkey","MajorVersion",majorVer)            ; just in case it's helpful
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    If reg.add("HKEY_LOCAL_MACHINE\Software\AutoHotkey","InstallExe",exeFullPath)
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    If reg.add("HKEY_LOCAL_MACHINE\Software\AutoHotkey","InstallBitness",bitness)
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    If reg.add("HKEY_LOCAL_MACHINE\Software\AutoHotkey","InstallProduct",InstallProduct)
        MsgBox reg.reason "`r`n`r`n" reg.cmd
    
    ; Copy selected version to AutoHotkey.exe
    If (!isAhkH) {
        Try FileDelete exeDir "\AutoHotkey.exe"
        FileCopy exeFullPath, exeDir "\AutoHotkey.exe"
    }
    
    SetActiveVersionGui()
}

UninstallAhk() {
    Global Settings, oGui
    k1 := reg.delete(k1k := "HKLM\SOFTWARE\AutoHotkey")
    k2 := reg.delete(k2k := "HKLM\SOFTWARE\Classes\.ahk")
    k3 := reg.delete(k3k := "HKLM\SOFTWARE\Classes\AutoHotkeyScript")
    
    k4 := reg.delete(k4k := "HKCU\Software\AutoHotkey")
    k5 := reg.delete(k5k := "HKCU\Software\Classes\AutoHotkey")
    k6 := reg.delete(k6k := "HKCU\Software\Classes\AutoHotkeyScript")
    
    k7 := "x", k7k := ""
    If (A_Is64BitOs) {
        reg.view := 32
        k7 := reg.delete(k7k := "HKLM\SOFTWARE\AutoHotkey")
        reg.view := 64
    }
    
    Settings["ActiveVersionPath"] := ""
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
    Global Settings, mode
    
    If (mode = "gui") { ; don't re-save ever time script is launched by the registry
        Try FileDelete "Settings.json"
        SettingsJSON := Jxon_Dump(Settings,4)
        FileAppend SettingsJSON, "Settings.json"
    }
}

SetActiveVersionGui() {
    Global Settings, oGui
    InstProd := "", ver := ""
    
    If Settings["PortableMode"] {
        ActiveVersion := (Settings.Has("ActiveVersionDisp")) ? Settings["ActiveVersionDisp"] : ""
        oGui["ActiveVersionDisp"].Text := "Base Version:    " ActiveVersion
    } Else {
        Try InstProd := reg.read("HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey","InstallProduct")
        Try ver := reg.read("HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey","Version")
        
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

LinkEvents(oCtl,Info,href) {
    If (href)
        Run href
}

ListClick(oCtl,Info) {
    DisplayPathGui(oCtl,Info)
}

ListExes() {
    Global Settings, oGui
    props := ["Name","Product version","File description"]
    oCtl := oGui["ExeList"] ; ListView
    oCtl.Opt("-Redraw"), oCtl.Delete()
    
    BaseFolder := (!Settings.Has("BaseFolder") Or Settings["BaseFolder"] = "") ? A_ScriptDir : Settings["BaseFolder"]
    
    Loop Files BaseFolder "\*.exe", "R"
    {
        f := A_LoopFileName
        If (InStr(f,"AutoHotkeySC.exe") Or InStr(f,"setup"))
            continue
        
        ahkProps := GetAhkProps(A_LoopFileFullPath)
        isAhkH := (ahkProps = "") ? false : ahkProps["isAhkH"]
        
        If (IsObject(ahkProps)) {
            ahkName := ahkProps["ahkProduct"] " " ahkProps["ahkType"] " " ahkProps["bitness"]
            ahkVer := ahkProps["ahkVersion"], exeFile := ahkProps["exeFile"]
            oCtl.Add("",ahkName,ahkVer,exeFile,A_LoopFileFullPath)
        }
    }
    oCtl.ModifyCol(1,180), oCtl.ModifyCol(2,120), oCtl.ModifyCol(3,138), oCtl.ModifyCol(4,0)
    oCtl.ModifyCol(1,"Sort"), oCtl.ModifyCol(2,"Sort")
    oCtl.Opt("+Redraw")
    
    ActiveVersionPath := (Settings.Has("ActiveVersionPath")) ? Settings["ActiveVersionPath"] : ""
    rows := oCtl.GetCount(), curRow := 0
    
    If (ActiveVersionPath and rows) {
        Loop rows {
            curPath := oCtl.GetText(A_Index,4)
            If (ActiveVersionPath = curPath) {
                curRow := A_Index
                oCtl.Modify(curRow,"Vis Select")
                break
            }
        }
    }
    
    If (curRow)
        DisplayPathGui(oCtl,curRow)
    
    oCtl.Focus(), oCtl := ""
}

CheckUpdate(override:=0) {
    Global Settings, oGui
    If (!override) {
        If (!Settings.Has("AutoUpdateCheck") Or Settings["AutoUpdateCheck"] = 0)
            return "NoUpdate"
        Else If (Settings.Has("UpdateCheckDate") And Settings["UpdateCheckDate"] = FormatTime(,"yyyy-MM-dd"))
            return "NoUpdate"
    }
    
    errMsg := "", NewAhk1Version := "", NewAhk2Version := ""
    Try {
        ; Download Settings["Ahk1Url"], "version1.txt"
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", Settings["Ahk1Url"])
        whr.Send()
        whr.WaitForResponse()
        NewAhk1Version := whr.ResponseText
    } Catch {
        errMsg := "Could not reach AHKv1 page."
    }
    
    Try {
        ; Download Settings["Ahk2Url"], "version2.txt"
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", Settings["Ahk2Url"])
        whr.Send()
        whr.WaitForResponse()
        NewAhk2Version := whr.ResponseText
    } Catch {
        errMsg .= errMsg ? "`n`n" : "", errMsg .= "Could not reach AHKv2 page."
    }
    
    If (!errMsg) {
        Settings["UpdateCheckDate"] := FormatTime(,"yyyy-MM-dd")
    }
    
    Ahk1Version := (Settings.Has("Ahk1Version")) ? Settings["Ahk1Version"] : ""
    Ahk2Version := (Settings.Has("Ahk2Version")) ? Settings["Ahk2Version"] : ""
    
    If (Ahk1Version != NewAhk1Version) {
        resultMsg := "New AutoHotkey v1 update!"
        Settings["Ahk1Version"] := NewAhk1Version
    } Else
        resultMsg := ""

    If (Ahk2Version != NewAhk2Version) {
        resultMsg .= "`r`n`r`nNew AutoHotkey v2 update!"
        Settings["Ahk2Version"] := NewAhk2Version
    } Else
        resultMsg .= ""
    
    If (resultMsg)
        MsgBox resultMsg
    
    oGui["Ahk1Version"].Text := "<a href=" Chr(34) Settings["Ahk1Url"] Chr(34) ">AHKv1:</a>    " NewAhk1Version
    oGui["Ahk2Version"].Text := "<a href=" Chr(34) Settings["Ahk2Url"] Chr(34) ">AHKv2:</a>    " NewAhk2Version
    
    return errMsg
}

LaunchScript() {
    Global Settings
    sel := Explorer_GetSelection()
    
    If sel {
        a := StrSplit(sel,"`n","`r")
        Loop a.Length {
            exe_file := proc_script(a[A_index])
            Run exe_file " " Chr(34) a[A_Index] Chr(34)
        }
    }
}

LaunchCompiler(_in:="") {
    Global Settings
    sel := Explorer_GetSelection()
    
    Loop Parse sel, "`n", "`r"
    {
        exe := proc_script(A_LoopField, true)
        Run Chr(34) exe Chr(34) " /in " Chr(34) A_LoopField Chr(34) " /gui"
    }
}

LaunchEditor() {
    Global Settings
    sel := Explorer_GetSelection()
    
    Loop Parse sel, "`n", "`r"
        Run Chr(34) Settings["TextEditorPath"] Chr(34) " " Chr(34) A_LoopField Chr(34)
}

#HotIf IsObject(regexGui) And WinActive("ahk_id " regexGui.hwnd)
Enter::regex_events(regexGui["RegexSave"],"")

; ====================================================================================
; MButton:          Runs the selected script(s).
; SHIFT + MButton:  Opens selected script(s) in text editor.
; CTRL  + MButton:  Launches Ahk2Exe with selected script(s) filled in.  One instance per selection.
; ====================================================================================
#HotIf WinActive("ahk_exe explorer.exe")
MButton::LaunchScript()
+MButton::LaunchEditor()
^MButton::LaunchCompiler()

