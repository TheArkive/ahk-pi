; AHK v2
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.
#NoTrayIcon

#INCLUDE Lib\_JXON.ahk
#INCLUDE Lib\_RegexInput.ahk

Global oGui, Settings, AhkPisVersion, regexList
AhkPisVersion := "v1.8"
regexList := Map()

If (A_Is64BitOs)
	SetRegView 64

If (FileExist("Settings.json.blank") And !FileExist("Settings.json"))
	FileMove "Settings.json.blank", "Settings.json"

SettingsJSON := FileRead("Settings.json"), Settings := Jxon_Load(SettingsJSON), Settings["toggle"] := 0 ; load settings
regexList := Settings["regexList"]

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
	oGui := GuiCreate("","AHK Portable Installer " AhkPisVersion)
	oGui.OnEvent("Close","gui_Close")
	
	Ahk1Version := (Settings.Has("Ahk1Version")) ? Settings["Ahk1Version"] : ""
	Ahk2Version := (Settings.Has("Ahk2Version")) ? Settings["Ahk2Version"] : ""
	Ahk1Html := "<a href=" Chr(34) StrReplace(Settings["Ahk1Url"],"version.txt","") Chr(34) ">AHKv1:</a>    " Ahk1Version
	Ahk2Html := "<a href=" Chr(34) StrReplace(Settings["Ahk2Url"],"version.txt","") Chr(34) ">AHKv2:</a>    " Ahk2Version
	
	oGui.Add("Link","vAhk1Version xm w220",Ahk1Html).OnEvent("Click","LinkEvents")
	oGui.Add("Link","vAhk2Version x+0 w220",Ahk2Html).OnEvent("Click","LinkEvents")
	oGui.Add("Edit","vActiveVersionDisp xm y+8 w440 -E0x200 ReadOnly","Installed:")
	
	LV := oGui.Add("ListView","xm y+0 r5 w460 vExeList","Description|Version|File Name|Full Path")
	LV.OnEvent("DoubleClick","GuiEvents"), LV.OnEvent("Click","ListClick")
	
	oGui.Add("Edit","vCurrentPath xm y+8 w440 -E0x200 ReadOnly","Path:    ")
	
	oGui.Add("Button","vToggleSettings y+0","Settings").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vHelp x+72","Help").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vWindowSpy x+0","Window Spy").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vUninstall x+0","Uninstall AHK").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vActivateExe x+65 yp","Activate EXE").OnEvent("Click","GuiEvents")
	
	tabs := oGui.Add("Tab","y+10 x2 w476 h255","Basics|Extras")
	
	oGui.Add("Text","xm y+10","Base AHK Folder:    (Leave blank for program directory)")
	oGui.Add("Edit","y+0 r1 w410 vBaseFolder ReadOnly")
	oGui.Add("Button","x+0 vPickBaseFolder","...").OnEvent("Click","GuiEvents")
	oGui.Add("Button","x+0 vClearBaseFolder","X").OnEvent("Click","GuiEvents")
	oGui.Add("Text","xm y+4","AutoHotkey v1 URL:")
	oGui.Add("Edit","y+0 r1 w460 vAhk1Url").OnEvent("Change","GuiEvents")
	oGui.Add("Text","xm y+4","AutoHotkey v2 URL:")
	oGui.Add("Edit","y+0 r1 w460 vAhk2Url").OnEvent("Change","GuiEvents")
	
	oGui.Add("Checkbox","vAutoUpdateCheck xm y+10","Automatically check for updates").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vCheckUpdateNow x+173 yp-4","Check Updates Now").OnEvent("Click","GuiEvents")
	
	oGui.Add("Text","xm y+4","Text Editor:")
	oGui.Add("Edit","xm y+0 w410 vTextEditorPath ReadOnly")
	oGui.Add("Button","x+0 vPickTextEditor","...").OnEvent("Click","GuiEvents")
	oGui.Add("Button","x+0 vDefaultTextEditor","X").OnEvent("Click","GuiEvents")
	
	oGui.Add("Button","vEditAhk1Template xm y+10 w230","Edit AHK v1 Template").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vEditAhk2Template x+0 w230","Edit AHK v2 Template").OnEvent("Click","GuiEvents")
	
	tabs.UseTab("Extras")
	oGui.Add("Checkbox","vAhk2ExeHandler xm y+10","Use fancy Ahk2Exe handler").OnEvent("Click","GuiEvents")
	oGui.Add("Checkbox","vAhk2ExeAutoStart x+30","Auto Start Compiler").OnEvent("Click","GuiEvents")
	oGui.Add("Checkbox","vAhk2ExeAutoClose x+30","Auto Close Compiler").OnEvent("Click","GuiEvents")
	
	; oGui.Add("Text","xm y+10","Ahk2Exe Path:    (Used with fancy Ahk2Exe handler)")
	; oGui.Add("Edit","vAhk2ExePath xm y+0 w410 ReadOnly")
	; oGui.Add("Button","vPickAhk2ExePath x+0","...").OnEvent("Click","GuiEvents")
	; oGui.Add("Button","vClearAhk2ExePath x+0","X").OnEvent("Click","GuiEvents")
	
	oGui.Add("Checkbox","vAhkLauncher xm y+20","Use AHK Launcher").OnEvent("Click","GuiEvents")
	oGui.Add("Checkbox","vDisableTooltips x+70","Disable Tooltips").OnEvent("Click","GuiEvents")
	; oGui.Add("Checkbox","vDebugNow x+30","Debug").OnEvent("click","GuiEvents")
	
	LV := oGui.Add("ListView","vAhkParallelList xm y+4 w460 h143","Label|Match String")
	LV.OnEvent("click","GuiEvents")
	LV.OnEvent("doubleclick","regex_edit")
	LV.ModifyCol(1,160), LV.ModifyCol(2,260)
	LV.SetFont("s8","Courier New")
	
	oGui.Add("Edit","vRegexExe xm y+0 w410 ReadOnly")
	oGui.Add("Button","vRegexExeAdd x+0 w25","+").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vRegexExeRemove x+0 w25","-").OnEvent("Click","GuiEvents")
	
	x := Settings["posX"], y := Settings["posY"]
	PopulateSettings()
	ListExes()
	
	newH := A_ScreenDPI = 96 ? 220 : 210 ; 125%
	oGui.Show("w480 h" newH " x" x " y" y)
	
	result := CheckUpdate()
	If (result And result != "NoUpdate")
		MsgBox result, "Update Check Failed", 0x10
}

SetActiveVersionGui() {
	InstProd := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey","InstallProduct")
	ver := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey","Version")
	
	regVer := InstProd " " ver
	ActiveVersion := (Settings.Has("ActiveVersionDisp")) ? Settings["ActiveVersionDisp"] : ""
	
	oCtl := oGui["ActiveVersionDisp"]
	If (regVer != ActiveVersion)
		oCtl.Text := "AutoHotkey not installed!" ; this usually happens during a fresh install of Windows
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
		Settings["TextEditorPath"] := "notepad.exe"	; set default script text editor if blank
	If (!FileExist(Settings["TextEditorPath"]))
		Settings["TextEditorPath"] := "notepad.exe"	; set default script text editor if specified doesn't exist
	
	TextEditorPath := Settings["TextEditorPath"]
	oCtl := oGui["TextEditorPath"], oCtl.Value := TextEditorPath
	
	If (!Settings.Has("Ahk2ExeHandler"))
		Settings["Ahk2ExeHandler"] := 0
	oGui["Ahk2ExeHandler"].Value := Settings["Ahk2ExeHandler"]
	
	; If (!Settings.Has("Ahk2ExePath"))
		; Settings["Ahk2ExePath"] := ""
	; Ahk2ExePath := Settings["Ahk2ExePath"]
	; oGui["Ahk2ExePath"].Value := Ahk2ExePath
	
	; If (Settings["Ahk2ExeHandler"]) {
		; oGui["PickAhk2ExePath"].Enabled := True
		; oGui["ClearAhk2ExePath"].Enabled := True
	; } Else {
		; oGui["PickAhk2ExePath"].Enabled := False
		; oGui["ClearAhk2ExePath"].Enabled := False
	; }
	
	If (!Settings.Has("AhkLauncher"))
		Settings["AhkLauncher"] := 0
	oGui["AhkLauncher"].Value := Settings["AhkLauncher"]
	
	; If (!Settings["AhkLauncher"]) {
		; oGui["PickAhkLaunchV1"].Enabled := False, oGui["PickAhkLaunchV2"].Enabled := False
		; oGui["ClearAhkLaunchV1"].Enabled := False, oGui["ClearAhkLaunchV2"].Enabled := False
	; }
	
	; If (!Settings.Has("AhkLaunchV1"))
		; Settings["AhkLaunchV1"] := ""
	; If (!Settings.Has("AhkLaunchV2"))
		; Settings["AhkLaunchV2"] := ""
	
	; oGui["AhkLaunchV1"].Value := Settings["AhkLaunchV1"]
	; oGui["AhkLaunchV2"].Value := Settings["AhkLaunchV2"]
	
	; If (!Settings.Has("DebugNow"))
		; Settings["DebugNow"] := 0
	; oGui["DebugNow"].Value := Settings["DebugNow"]
	
	If (!Settings.Has("Ahk2ExeAutoStart"))
		Settings["Ahk2ExeAutoStart"] := 0
	oGui["Ahk2ExeAutoStart"].Value := Settings["Ahk2ExeAutoStart"]
	
	If (!Settings.Has("Ahk2ExeAutoClose"))
		Settings["Ahk2ExeAutoClose"] := 0
	oGui["Ahk2ExeAutoClose"].Value := Settings["Ahk2ExeAutoClose"]
	
	If (!Settings.Has("DisableTooltips"))
		Settings["DisableTooltips"] := 0
	oGui["DisableTooltips"].Value := Settings["DisableTooltips"]
	
	regexRelist()
	
	oCtl := ""
}

ListExes() {
	props := ["Name","Product version","File description"]
	oCtl := oGui["ExeList"] ; ListViewObject
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
	
	errMsg := ""
	Download Settings["Ahk1Url"], "version1.txt"
	If (ErrorLevel)
		errMsg := "Could not reach AHKv1 page."
	Download Settings["Ahk2Url"], "version2.txt"
	If (ErrorLevel)
		errMsg .= errMsg ? "`n`n" : "", errMsg .= "Could not reach AHKv2 page."
	
	If (!errMsg) {
		Settings["UpdateCheckDate"] := FormatTime(,"yyyy-MM-dd")
	}
	
	Ahk1Version := (Settings.Has("Ahk1Version")) ? Settings["Ahk1Version"] : ""
	If (!FileExist("version1.txt"))
		NewAhk1Version := Settings["Ahk1Version"]
	Else
		NewAhk1Version := Trim(FileRead("version1.txt")," `t`r`n")

	Ahk2Version := (Settings.Has("Ahk2Version")) ? Settings["Ahk2Version"] : ""
	If (!FileExist("version2.txt"))
		NewAhk2Version := Settings["Ahk2Version"]
	Else
		NewAhk2Version := Trim(FileRead("version2.txt")," `t`r`n")

	If (Ahk1Version != NewAhk1Version) {
		MsgBox "New AutoHotkey v1 update!"
		Settings["Ahk1Version"] := NewAhk1Version
	} Else
		MsgBox "No new updates for AutoHotkey v1."

	If (Ahk2Version != NewAhk2Version) {
		MsgBox "New AutoHotkey v2 update!"
		Settings["Ahk2Version"] := NewAhk2Version
	} Else
		MsgBox "No new updates for AutoHotkey v2."
	
	oGui["Ahk1Version"].Text := "<a href=" Chr(34) Settings["Ahk1Url"] Chr(34) ">AHKv1:</a>    " NewAhk1Version
	oGui["Ahk2Version"].Text := "<a href=" Chr(34) Settings["Ahk2Url"] Chr(34) ">AHKv2:</a>    " NewAhk2Version
	
	FileDelete "version1.txt"
	FileDelete "version2.txt"
	
	return errMsg
}

GuiEvents(oCtl,Info) {
	If (oCtl.Name = "ToggleSettings") {
		; newH := A_ScreenDPI = 96 ? 480 : 470 ; * (A_ScreenDPI / 96)
		newH := 480
		p := oGui.Pos, scrW := SysGet(78), scrH := SysGet(79) 
		
		If ((p.y + newH) > scrH)
			diff := (p.y + newH) - scrH + SysGet(4) + (SysGet(8) * 2) + (SysGet(33) * 2) ; (SysGet(6) * 2)
		Else
			diff := 0
		
		toggle := Settings["toggle"]
		
		If (toggle) {
			newY := Settings["curPosY"]
			newH := A_ScreenDPI = 96 ? 220 : 210 ; * (A_ScreenDPI / 96) ;      orig 220 @ 100% / 210 @ 125% ???
			oGui.Show("w480 h" newH " y" newY), Settings["toggle"] := 0
		} Else {
			newY := p.y - diff
			Settings["curPosX"] := p.x, Settings["curPosY"] := p.y
			oGui.Show("w480 h" newH " y" newY), Settings["toggle"] := 1
		}
	} Else If (oCtl.Name = "ActivateExe" or oCtl.Name = "ExeList") { ; <---------------------------------- activate exe
		LV := oGui["ExeList"]
		row := LV.GetNext(), exeFullPath := LV.GetText(row,4)
		
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
		Settings["ActiveVersionDisp"] := ActiveVersion, Settings["ActiveVersionPath"] := exeFullPath
		
		dispCtl := oGui["ActiveVersionDisp"], dispCtl.Text := "Installed:    ", dispCtl := "" ; clear active version
		
		Ahk2ExeHandler := Settings["Ahk2ExeHandler"]
		; Ahk2ExePath := Settings["Ahk2ExePath"]
		; Ahk2ExePath := (FileExist(Ahk2ExePath) And Ahk2ExeHandler) ? Ahk2ExePath : installDir "\Compiler\Ahk2Exe.exe" ; old Ahk2Exe ...
		Ahk2ExePath := installDir "\Compiler\Ahk2Exe.exe" ; new Ahk2Exe ...
		TextEditorPath := Settings["TextEditorPath"]
		Ahk2ExeBin := ahkType " " bitness ".bin"
		mpress := (FileExist(installDir "\Compiler\mpress.exe")) ? 1 : 0
		
		template := "TemplateV" majorVer ".ahk"
		templateText := FileRead("resources\" template)
		
		; .ahk extension and template settings
		RegWrite "AutoHotkeyScript", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.ahk" ; defines ProgID - this should NOT CHANGE!
		RegWrite "AutoHotkey Script v" majorVer, "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.ahk\ShellNew", "ItemName" ; defines context menu > New text
		RegWrite "Template.ahk", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.ahk\ShellNew", "FileName" ; specify template path, default = %WinDir%\ShellNew
		
		; update template accordingn to majorVer
		FileDelete A_WinDir "\ShellNew\Template.ahk"
		FileAppend templateText, A_WinDir "\ShellNew\Template.ahk"
		
		If (A_Is64BitOs)
			Run "reg delete HKEY_LOCAL_MACHINE\Software\AutoHotkey /f /reg:64",,"Hide"
		Else
			Run "reg delete HKEY_LOCAL_MACHINE\Software\AutoHotkey /f /reg:32",,"Hide"
		
		; UninstallAhk() ; ... shouldn't need this
		
		Sleep 350
		
		; update ProgID
		RegWrite "AutoHotkey Script v" majorVer, "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript"	; ProgID title, asthetic only?
		RegWrite exeFullPath ",1", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\DefaultIcon"		; default icon
		RegWrite "Open", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell"
		
		; Compiler Context Menu (Ahk2Exe)
		RegWrite "Compile Script", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell\Compile"	; Compile context menu entry
		If (!Settings["Ahk2ExeHandler"]) {
			regVal := Chr(34) Ahk2ExePath Chr(34) "/in " Chr(34) "%1" Chr(34)
			RegWrite regVal, "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell\Compile\Command"		; Compile command
		} Else {
			regVal := Chr(34) A_ScriptDir "\Ahk2Exe_Handler.exe" Chr(34) " " Chr(34) "%1" Chr(34)
			RegWrite regVal, "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell\Compile\Command"		; Compile command to handler
		}
		
		; text Editor
		RegWrite "Edit Script", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell\Edit"			; Edit context menu entry
		regVal := Chr(34) TextEditorPath Chr(34) " " Chr(34) "%1" Chr(34)
		RegWrite regVal, "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell\Edit\Command"		; Edit command
		
		; Run Script
		RegWrite "Run Script", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell\Open"			; Open context menu entry
		If (Settings["AhkLauncher"] = 0)
			regVal := Chr(34) exeFullPath Chr(34) " " Chr(34) "%1" Chr(34) " %*"									; Open Cmd - legit
		Else
			regVal := Chr(34) A_ScriptDir "\AhkLauncher.exe" Chr(34) " " Chr(34) "%1" Chr(34) " %*"					; Open Cmd - AhkLauncher
		RegWrite regVal, "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell\Open\Command"		; Open command
		
		; Ahk2Exe entries
		RegWrite Ahk2ExeBin, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe", "LastBinFile"	; auto set .bin file
		RegWrite mpress, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe", "LastUseMPRESS"		; auto set mpress usage
		RegWrite Ahk2ExePath, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe", "Ahk2ExePath"	; for easy reference...
		RegWrite bitness, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe", "BitFilter"
		
		; HKLM / Software / AutoHotkey install and version info
		RegWrite installDir, "REG_SZ", "HKEY_LOCAL_MACHINE\Software\AutoHotkey", "InstallDir"				; Default entries
		RegWrite "AutoHotkey", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\AutoHotkey", "StartMenuFolder"		; Default entries
		RegWrite ver, "REG_SZ", "HKEY_LOCAL_MACHINE\Software\AutoHotkey", "Version"						; Default entries
		
		RegWrite majorVer, "REG_SZ", "HKEY_LOCAL_MACHINE\Software\AutoHotkey", "MajorVersion"			; just in case it's helpful
		RegWrite exeFullPath, "REG_SZ", "HKEY_LOCAL_MACHINE\Software\AutoHotkey", "InstallExe"
		RegWrite bitness, "REG_SZ", "HKEY_LOCAL_MACHINE\Software\AutoHotkey", "InstallBitness"
		RegWrite installProduct, "REG_SZ", "HKEY_LOCAL_MACHINE\Software\AutoHotkey", "InstallProduct"
		
		; Copy selected version to AutoHotkey.exe
		If (!isAhkH) {
			FileDelete exeDir "\AutoHotkey.exe"
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
		
		; If (Settings["Ahk2ExeHandler"]) {
			; oGui["PickAhk2ExePath"].Enabled := True
			; oGui["ClearAhk2ExePath"].Enabled := True
		; } Else {
			; oGui["PickAhk2ExePath"].Enabled := False
			; oGui["ClearAhk2ExePath"].Enabled := False
		; }
	} Else If (oCtl.Name = "AhkLauncher") {
		Settings["AhkLauncher"] := oCtl.Value
	} Else If (oCtl.Name = "Ahk2ExeAutoStart") {
		Settings[oCtl.Name] := oCtl.Value
	} Else If (oCtl.Name = "Ahk2ExeAutoClose") {
		Settings[oCtl.Name] := oCtl.Value
	} Else If (oCtl.Name = "DisableTooltips") {
		Settings[oCtl.Name] := oCtl.Value
	} Else if (oCtl.Name = "RegexExeAdd") {
		guiAddRegex()
		oCtl.gui["RegexExe"].Value := ""
	} Else If (oCtl.Name = "RegexExeRemove") {
		LV := oCtl.gui["AhkParallelList"]
		curRow := LV.GetNext(), curKey := LV.GetText(curRow,1)
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
	}
	oCtl := ""
}

UninstallAhk() {
	regType := A_Is64BitOs ? " /reg:64" : ""
	
	Run "reg delete HKLM\SOFTWARE\AutoHotkey /f" regType,, "Hide"
	Run "reg delete HKLM\SOFTWARE\Classes\.ahk /f" regType,, "Hide"
	Run "reg delete HKLM\SOFTWARE\Classes\AutoHotkeyScript /f" regType,, "Hide"
	
	Run "reg delete HKCU\Software\AutoHotkey /f" regType,, "Hide"
	Run "reg delete HKCU\Software\Classes\AutoHotkey /f" regType,, "Hide"
	Run "reg delete HKCU\Software\Classes\AutoHotkeyScript /f" regType,, "Hide"
	
	If (A_Is64BitOs)
		Run "reg delete HKLM\SOFTWARE\WOW6432Node\AutoHotkey /f" regType,, "Hide"
	
	Settings["ActiveVersionPath"] := ""
	SetActiveVersionGui()
}

gui_Close(o) {
	Settings["BaseFolder"] := o["BaseFolder"].Value
	dims := oGui.Pos
	Settings["posX"] := dims.x, Settings["posY"] := dims.y
	Settings["regexList"] := regexList
	
	FileDelete "Settings.json"
	SettingsJSON := Jxon_Dump(Settings,4)
	
	FileAppend SettingsJSON, "Settings.json"
	ExitApp
}

#If IsObject(regexGui) And WinActive("ahk_id " regexGui.hwnd)
Enter::regex_events(regexGui["RegexSave"],"")

