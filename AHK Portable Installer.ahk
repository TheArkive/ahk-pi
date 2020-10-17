; AHK v2
SendMode "Input"  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.
#NoTrayIcon

#INCLUDE inc\_JXON.ahk
#INCLUDE inc\_RegexInput.ahk
#INCLUDE inc\TheArkive_reg2.ahk

Global oGui := "", Settings := "", AhkPisVersion := "v1.10", regexList := Map()

If (A_Is64BitOS)
    reg.view := 64

If (FileExist("Settings.json.blank") And !FileExist("Settings.json"))
    FileMove "Settings.json.blank", "Settings.json"

SettingsJSON := FileRead("Settings.json"), Settings := Jxon_Load(SettingsJSON), Settings["toggle"] := 0 ; load settings
regexList := Settings["regexList"]

monitor := GetMonitorData()
If Settings["posX"] > monitor.right Or Settings["posX"] < monitor.left
    Settings["posX"] := 200
If Settings["posY"] > monitor.bottom Or Settings["posY"] < monitor.top
    Settings["posY"] := 200

OnMessage(0x0200,"WM_MOUSEMOVE") ; WM_MOUSEMOVE
WM_MOUSEMOVE(wParam, lParam, Msg, hwnd) {
    If (!Settings["DisableTooltips"]) {
        If (hwnd = oGui["ActivateExe"].Hwnd)
            ToolTip "Modify settings as desired first, including templates.`r`nThen click this button."
        Else If (hwnd = oGui["ExeList"].Hwnd)
            ToolTip "Double-click to activate.`r`nBe sure to modify settings as desired first, including templates."
        Else If (hwnd = oGui["CurrentPath"].Hwnd)
            ToolTip oGui["CurrentPath"].Value
        Else If (hwnd = oGui["Ahk2ExeHandler"].Hwnd)
            ToolTip "This changes the " Chr(34) "Compile" Chr(34) " context menu to use the handler`r`nwhich quickly pre-populates a destination EXE, icon if exists`r`nwith script file name, and the .bin file to use."
        Else If (hwnd = oGui["AhkLauncher"].Hwnd)
            ToolTip "Run AHK scripts of different versions side by side without needing a separate file association.`r`n`r`nAdd " Chr(34) ";AHKv#" Chr(34) " to the first line of the script." 
        Else If (hwnd = oGui["RegexExeAdd"].Hwnd)
            ToolTip "Add a parallel EXE match option."
        Else If (hwnd = oGui["RegexExeRemove"].Hwnd)
            ToolTip "Remove a parallel EXE match option."
        Else If (hwnd = oGui["AhkParallelList"].Hwnd)
            ToolTip "Double-click to edit."
        Else
            ToolTip
    }
}

runGui()

runGui() {
    oGui := Gui.New("-DPIScale","AHK Portable Installer " AhkPisVersion)
    oGui.OnEvent("Close","gui_Close")
    
    Ahk1Version := (Settings.Has("Ahk1Version")) ? Settings["Ahk1Version"] : ""
    Ahk2Version := (Settings.Has("Ahk2Version")) ? Settings["Ahk2Version"] : ""
    Ahk1Html := "<a href=" Chr(34) StrReplace(Settings["Ahk1Url"],"version.txt","") Chr(34) ">AHKv1:</a>    " Ahk1Version
    Ahk2Html := "<a href=" Chr(34) StrReplace(Settings["Ahk2Url"],"version.txt","") Chr(34) ">AHKv2:</a>    " Ahk2Version
    
    oGui.Add("Link","vAhk1Version xm w220",Ahk1Html).OnEvent("Click","LinkEvents")
    oGui.Add("Link","vAhk2Version x+0 w220",Ahk2Html).OnEvent("Click","LinkEvents")
    oGui.Add("Edit","vActiveVersionDisp xm y+8 w440 -E0x200 ReadOnly","Installed:")
    
    LV := oGui.Add("ListView","xm y+0 r5 w460 vExeList",["Description","Version","File Name","Full Path"])
    LV.OnEvent("DoubleClick","GuiEvents"), LV.OnEvent("Click","ListClick")
    
    oGui.Add("Edit","vCurrentPath xm y+8 w440 -E0x200 ReadOnly","Path:    ")
    
    oGui.Add("Button","vToggleSettings y+0","Settings").OnEvent("Click","GuiEvents")
    oGui.Add("Button","vHelp x+72","Help").OnEvent("Click","GuiEvents")
    oGui.Add("Button","vWindowSpy x+0","Window Spy").OnEvent("Click","GuiEvents")
    oGui.Add("Button","vUninstall x+0","Uninstall AHK").OnEvent("Click","GuiEvents")
    oGui.Add("Button","vActivateExe x+65 yp","Activate EXE").OnEvent("Click","GuiEvents")
    
    tabs := oGui.Add("Tab","y+10 x2 w476 h275",["Basics","AHK Launcher","Other"])
    
    oGui.Add("Text","xm y+10","Base AHK Folder:    (Leave blank for program directory)")
    oGui.Add("Edit","y+0 r1 w410 vBaseFolder ReadOnly")
    oGui.Add("Button","x+0 vPickBaseFolder","...").OnEvent("Click","GuiEvents")
    oGui.Add("Button","x+0 vClearBaseFolder","X").OnEvent("Click","GuiEvents")
    oGui.Add("Text","xm y+4","AutoHotkey v1 URL:")
    oGui.Add("Edit","y+0 r1 w460 vAhk1Url").OnEvent("Change","GuiEvents")
    oGui.Add("Text","xm y+4","AutoHotkey v2 URL:")
    oGui.Add("Edit","y+0 r1 w460 vAhk2Url").OnEvent("Change","GuiEvents")
    
    oGui.Add("Checkbox","vAhk2ExeHandler xm y+10","Use Ahk2Exe handler").OnEvent("Click","GuiEvents")
    oGui.Add("Checkbox","vAhkLauncher x+30","Use AHK Launcher").OnEvent("Click","GuiEvents")
    oGui.Add("Checkbox","vDisableTooltips x+30","Disable Tooltips").OnEvent("Click","GuiEvents")
    
    oGui.Add("Checkbox","vAutoUpdateCheck xm y+10","Automatically check for updates").OnEvent("Click","GuiEvents")
    oGui.Add("Button","vCheckUpdateNow x+173 yp-4","Check Updates Now").OnEvent("Click","GuiEvents")
    
    oGui.Add("Text","xm y+4","Text Editor:")
    oGui.Add("Edit","xm y+0 w410 vTextEditorPath ReadOnly")
    oGui.Add("Button","x+0 vPickTextEditor","...").OnEvent("Click","GuiEvents")
    oGui.Add("Button","x+0 vDefaultTextEditor","X").OnEvent("Click","GuiEvents")
    
    oGui.Add("Button","vEditAhk1Template xm y+10 w230","Edit AHK v1 Template").OnEvent("Click","GuiEvents")
    oGui.Add("Button","vEditAhk2Template x+0 w230","Edit AHK v2 Template").OnEvent("Click","GuiEvents")
    
    tabs.UseTab("AHK Launcher")
    
    LV := oGui.Add("ListView","vAhkParallelList xm y+5 w460 h218",["Label","Match String"])
    LV.OnEvent("click","GuiEvents")
    LV.OnEvent("doubleclick","regex_edit")
    LV.ModifyCol(1,160), LV.ModifyCol(2,260)
    LV.SetFont("s8","Courier New")
    
    oGui.Add("Edit","vRegexExe xm y+0 w410 ReadOnly")
    oGui.Add("Button","vRegexExeAdd x+0 w25","+").OnEvent("Click","GuiEvents")
    oGui.Add("Button","vRegexExeRemove x+0 w25","-").OnEvent("Click","GuiEvents")
    
    tabs.UseTab("Other")
    
    oGui.Add("Text","xm y+4","Context Menu:")
    oGui.Add("Checkbox","vShowEditScript xm y+4","Show " Chr(34) "Edit Script" Chr(34)).OnEvent("Click","GuiEvents")
    oGui.Add("Checkbox","vShowCompileScript x+30","Show " Chr(34) "Compile Script" Chr(34)).OnEvent("Click","GuiEvents")
    oGui.Add("Checkbox","vShowRunScript x+30","Show " Chr(34) "Run Script" Chr(34)).OnEvent("Click","GuiEvents")
    
    ; oGui.Add("Checkbox","vAhk2ExeAutoStart x+30","Auto Start Compiler").OnEvent("Click","GuiEvents")
    ; oGui.Add("Checkbox","vAhk2ExeAutoClose x+30","Auto Close Compiler").OnEvent("Click","GuiEvents")
    
    ; oGui.Add("Checkbox","vCascadeMenu x+30","Cascade Menu").OnEvent("Click","GuiEvents")
    
    x := Settings["posX"], y := Settings["posY"]
    PopulateSettings()
    ListExes()
    
    oGui.Show("w480 h220 x" x " y" y)
    
    result := CheckUpdate()
    If (result And result != "NoUpdate")
        MsgBox result, "Update Check Failed", 0x10
}

SetActiveVersionGui() {
    InstProd := "", ver := ""
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
        oCtl.Text := "Installed:    " ActiveVersion
    oCtl := ""
}

PopulateSettings() {
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
    
    oCtl := oGui["AutoUpdateCheck"], oCtl.Value := Settings["AutoUpdateCheck"]
    
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
    
    ; If (!Settings.Has("CascadeMenu"))
        ; Settings["CascadeMenu"] := 0
    ; oGui["CascadeMenu"].Value := Settings["CascadeMenu"]
    
    If (!Settings.Has("ShowEditScript"))
        Settings["ShowEditScript"] := 0
    oGui["ShowEditScript"].Value := Settings["ShowEditScript"]
    
    If (!Settings.Has("ShowCompileScript"))
        Settings["ShowCompileScript"] := 0
    oGui["ShowCompileScript"].Value := Settings["ShowCompileScript"]
    
    If (!Settings.Has("ShowRunScript"))
        Settings["ShowRunScript"] := 0
    oGui["ShowRunScript"].Value := Settings["ShowRunScript"]
    
    ; If (!Settings.Has("Ahk2ExeAutoStart"))
        ; Settings["Ahk2ExeAutoStart"] := 0
    ; oGui["Ahk2ExeAutoStart"].Value := Settings["Ahk2ExeAutoStart"]
    
    ; If (!Settings.Has("Ahk2ExeAutoClose"))
        ; Settings["Ahk2ExeAutoClose"] := 0
    ; oGui["Ahk2ExeAutoClose"].Value := Settings["Ahk2ExeAutoClose"]
    
    If (!Settings.Has("DisableTooltips"))
        Settings["DisableTooltips"] := 0
    oGui["DisableTooltips"].Value := Settings["DisableTooltips"]
    
    regexRelist()
    
    oCtl := ""
}

ListExes() {
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

; =================================================================
; ahkProps := GetAhkProps(sInput)
;    Returns ahk properties in a Map().
;    > sInput assumes the following path format:
;    - X:\path\base_path\AhkName AhkVersion\[AHK_H subfolder\]AutoHotkey[type].exe
;    - [type] = A32 / U32 / U64 / HA32 / HA32_MT / HU32 / HU32_MT / HU64 / HU64_MT
;
;    props: ahkProduct, ahkVersion, installDir, ahkType, bitness, exeFile, exePath, exeDir, variant
;
;    ahkprop key values:
;    - ahkProduct = AHK / AutoHotkey / AHK_H / AutoHotkey_H ... however it is typed
;    - ahkVersion = 1.32.00.....   as typed, but leading "v" will be stripped
;    - ahkType = Unicode / ANSI
;    - bitness = 32-bit / 64-bit
;    - installDir = base folder where Ahk2Exe and help file resides
;    - exeFile = full name of exe file
;    - exePath = full path to and including the exe file
;    - exeDir = dir exe is located in
;    - variant = MT for "multi-threading" or blank ("")

GetAhkProps(sInput) {
    If (!FileExist(sInput))
        return ""
    
    SplitPath sInput, ahkFile, curDir
    isAhkH := false, var := "", installDir := curDir
    bitness := "", ahkType := ""
    
    If (InStr(sInput,"\Win32a_MT\"))
        installDir := StrReplace(installDir,"\Win32a_MT"), isAhkH := true, ahkType := "ANSI", bitness := "32-bit", var := "MT"
    Else If (InStr(sInput,"\Win32a\"))
        installDir := StrReplace(installDir,"\Win32a"), isAhkH := true, ahkType := "ANSI", bitness := "32-bit"
    Else If (InStr(sInput,"\Win32w_MT\"))
        installDir := StrReplace(installDir,"\Win32w_MT"), isAhkH := true, ahkType := "Unicode", bitness := "32-bit", var := "MT"
    Else If (InStr(sInput,"\Win32w\"))
        installDir := StrReplace(installDir,"\Win32w"), isAhkH := true, ahkType := "Unicode", bitness := "32-bit"
    Else If (InStr(sInput,"\x64w_MT\"))
        installDir := StrReplace(installDir,"\x64w_MT"), isAhkH := true, ahkType := "Unicode", bitness := "64-bit", var := "MT"
    Else If (InStr(sInput,"\x64w\"))
        installDir := StrReplace(installDir,"\x64w"), isAhkH := true, ahkType := "Unicode", bitness := "64-bit"
    
    lastSlash := InStr(installDir,"\",false,-1)
    ahkPropStr := SubStr(installDir,lastSlash+1)
    propArr := StrSplit(ahkPropStr," ")
    ahkProduct := propArr[1]
    ahkVersion := propArr.Has(2) ? propArr[2] : ""
    ahkVersion := (SubStr(ahkVersion,1,1) = "v") ? SubStr(ahkVersion,2) : ahkVersion
    
    If (!isAhkH) {
        If (InStr(ahkFile,"A32.exe"))
            ahkType := "ANSI", bitness := "32-bit"
        Else If (InStr(ahkFile,"U32.exe"))
            ahkType := "Unicode", bitness := "32-bit"
        Else If (InStr(ahkFile,"U64.exe"))
            ahkType := "Unicode", bitness := "64-bit"
    }
    
    ahkProps := Map()
    ahkProps["exePath"] := sInput, ahkProps["installDir"] := installDir, ahkProps["ahkProduct"] := ahkProduct
    ahkProps["ahkVersion"] := ahkVersion, ahkProps["ahkType"] := ahkType, ahkProps["bitness"] := bitness
    ahkProps["variant"] := var, ahkProps["exeFile"] := ahkFile, ahkProps["exeDir"] := curDir, ahkProps["isAhkH"] := isAhkH
    
    If (ahkType = "" Or bitness = "")
        return ""
    Else
        return ahkProps
}

DisplayPathGui(oCtl,curRow) {
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

CheckUpdate(override:=0) {
    If (!override) {
        If (!Settings.Has("AutoUpdateCheck") Or Settings["AutoUpdateCheck"] = 0)
            return "NoUpdate"
        Else If (Settings.Has("UpdateCheckDate") And Settings["UpdateCheckDate"] = FormatTime(,"yyyy-MM-dd"))
            return "NoUpdate"
    }
    
    errMsg := "", NewAhk1Version := "", NewAhk2Version := ""
    Try {
        ; Download Settings["Ahk1Url"], "version1.txt"
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", Settings["Ahk1Url"])
        whr.Send()
        whr.WaitForResponse()
        NewAhk1Version := whr.ResponseText
    } Catch e {
        errMsg := "Could not reach AHKv1 page."
    }
    
    Try {
        ; Download Settings["Ahk2Url"], "version2.txt"
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", Settings["Ahk2Url"])
        whr.Send()
        whr.WaitForResponse()
        NewAhk2Version := whr.ResponseText
    } Catch e {
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

GuiEvents(oCtl,Info) {
    If (oCtl.Name = "ToggleSettings") {
        toggle := Settings["toggle"]
        
        If (toggle)
            oGui.Show("w480 h220"), Settings["toggle"] := 0
        Else
            oGui.Show("w480 h500"), Settings["toggle"] := 1
    } Else If (oCtl.Name = "ActivateExe" or oCtl.Name = "ExeList") { ; <---------------------------------- activate exe
        LV := oGui["ExeList"] ; ListView
        row := LV.GetNext(), exeFullPath := LV.GetText(row,4)
        
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
        
        ; If (cascade) {
            ; reg.add("HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell\AutoHotkey","SubCommands","")
            ; reg.add("HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell\AutoHotkey","Icon",Chr(34) exeFullPath Chr(34) ",1")
        ; }
        
        If reg.add("HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\DefaultIcon","",Chr(34) exeFullPath Chr(34) ",1")
            MsgBox reg.reason "`r`n`r`n" reg.cmd
        If reg.add(root,"","Open")
            MsgBox reg.reason "`r`n`r`n" reg.cmd
        
        ; Compiler Context Menu (Ahk2Exe)
        If Settings["ShowCompileScript"] {
            If reg.add(root "\Compile","","Compile Script")                                                ; Compile context menu entry
                MsgBox reg.reason "`r`n`r`n" reg.cmd
            regVal := Chr(34) (!Settings["Ahk2ExeHandler"] ? Ahk2ExePath Chr(34) "/in " : A_ScriptDir "\Ahk2Exe_Handler.exe" Chr(34) " ") Chr(34) "%1" Chr(34)
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
        
        regVal := Chr(34) (!Settings["AhkLauncher"] ? exeFullPath : A_ScriptDir "\AhkLauncher.exe") Chr(34) " " Chr(34) "%1" Chr(34) " %*"
        
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
            SplitPath Settings["ActiveVersionPath"], exeFile, exeDir
            winSpy := exeDir "\WindowSpy.ahk"
            If (FileExist(winSpy))
                Run Chr(34) exeDir "\WindowSpy.ahk" Chr(34)
            Else
                Msgbox "WindowSpy.ahk not found."
        }
    } Else If (oCtl.Name = "Uninstall") {
        If (MsgBox("Remove AutoHotkey from registry?","Uninstall AutoHotkey",0x24) = "Yes")
            UninstallAhk()
    } Else If (oCtl.Name = "PickAhk2ExePath") {
        Ahk2ExePath := Settings["Ahk2ExePath"], pickerPath := Ahk2ExePath
        pickerPath := (!pickerPath) ? Settings["BaseFolder"] : pickerPath
        
        Ahk2ExePath := FileSelect("",pickerPath,"Choose Ahk2Exe.exe:","Executable (*.exe)")
        If (Ahk2ExePath) {
            Settings["Ahk2ExePath"] := Ahk2ExePath
            oGui["Ahk2ExePath"].Value := Ahk2ExePath
        }
    } Else If (oCtl.Name = "ClearAhk2ExePath") {
        oGui["Ahk2ExePath"].Value := "", Settings["Ahk2ExePath"] := ""
    } Else If (oCtl.Name = "Ahk2ExeHandler") {
        Settings["Ahk2ExeHandler"] := oCtl.value
    } Else If (oCtl.Name = "AhkLauncher") {
        Settings["AhkLauncher"] := oCtl.Value
    } Else If (oCtl.Name = "CascadeMenu") {
        Settings["CascadeMenu"] := oCtl.Value
    ; } Else If (oCtl.Name = "Ahk2ExeAutoStart") {
        ; Settings[oCtl.Name] := oCtl.Value
    ; } Else If (oCtl.Name = "Ahk2ExeAutoClose") {
        ; Settings[oCtl.Name] := oCtl.Value
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
    } Else If (oCtl.Name = "ShowEditScript") {
        Settings["ShowEditScript"] := oCtl.Value
    } Else If (oCtl.Name = "ShowCompileScript") {
        Settings["ShowCompileScript"] := oCtl.Value
    } Else If (oCtl.Name = "ShowRunScript") {
        Settings["ShowRunScript"] := oCtl.Value
    }
    oCtl := ""
}

UninstallAhk() {
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
    
    ; MsgBox k1 ": " k1k "`r`n" k2 ": " k2k "`r`n" k3 ": " k3k "`r`n" k4 ": " k4k "`r`n" k5 ": " k5k "`r`n" k6 ": " k6k "`r`n" k7 ": " k7k "`r`n"
    
    Settings["ActiveVersionPath"] := ""
    SetActiveVersionGui()
}

gui_Close(o) {
    Settings["BaseFolder"] := o["BaseFolder"].Value
    oGui.GetPos(x,y,w,h), dims := {x:x, y:y, w:w, h:h}
    Settings["posX"] := dims.x, Settings["posY"] := dims.y
    Settings["regexList"] := regexList
    
    Try FileDelete "Settings.json"
    SettingsJSON := Jxon_Dump(Settings,4)
    
    FileAppend SettingsJSON, "Settings.json"
    ExitApp
}

; ===========================================================================
; created by TheArkive
; Usage: Specify X/Y coords to get info on which monitor that point is on,
;        and the bounds of that monitor.  If no X/Y is specified then the
;        current mouse X/Y coords are used.
; ===========================================================================
GetMonitorData(x:="", y:="") {
	CoordMode "Mouse", "Screen" ; CoordMode Mouse, Screen ; AHK v1
	If (x = "" Or y = "")
		MouseGetPos x, y
	actMon := 0
	
	monCount := MonitorGetCount() ; SysGet, monCount, MonitorCount ; AHK v1
	Loop monCount { ; Loop % monCount { ; AHK v1
		MonitorGet(A_Index,mLeft,mTop,mRight,mBottom) ; SysGet, m, Monitor, A_Index ; AHK v1
		
		If (mLeft = "" And mTop = "" And mRight = "" And mBottom = "")
			Continue
		
		If (x >= (mLeft) And x <= (mRight-1) And y >= mTop And y <= (mBottom-1)) {
			monList := {}, monList.left := mLeft, monList.right := mRight
			monList.top := mTop, monList.bottom := mBottom, monList.active := A_Index
			monList.x := x, monList.y := y
			monList.Cx := ((mRight - mLeft) / 2) + mLeft
			monList.Cy := ((mBottom - mTop) / 2) + mTop
			monList.w := mRight - mLeft, monList.h := mBottom - mTop
			Break
		}
	}
	
	return monList
}

#HotIf IsObject(regexGui) And WinActive("ahk_id " regexGui.hwnd)
Enter::regex_events(regexGui["RegexSave"],"")

