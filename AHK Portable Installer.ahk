; AHK v2
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

#INCLUDE Lib\_FileXpro.ahk
#INCLUDE Lib\TheArkive_XA_LoadSave.ahk

Global oGui, Settings, AhkPisVersion
AhkPisVersion := "v1.4"

If (FileExist("Settings.xml.blank"))
	FileMove "Settings.xml.blank", "Settings.xml"

SettingsXML := FileRead("Settings.xml"), Settings := XA_Load(SettingsXML), Settings["toggle"] := 0 ; load settings

OnMessage(0x0200,"WM_MOUSEMOVE") ; WM_MOUSEMOVE
WM_MOUSEMOVE(wParam, lParam, Msg, hwnd) {
	If (hwnd = oGui["ActivateExe"].Hwnd)
		ToolTip "Modify settings as desired first, including templates.`r`nThen click this button."
	Else If (hwnd = oGui["ExeList"].Hwnd)
		ToolTip "Double-click to activate.`r`nBe sure to modify settings as desired first, including templates."
	Else If (hwnd = oGui["CurrentPath"].Hwnd)
		ToolTip oGui["CurrentPath"].Value
	Else If (hwnd = oGui["Ahk2ExeHandler"].Hwnd)
		ToolTip "This changes the " Chr(34) "Compile" Chr(34) " context menu to use the handler`r`nwhich quickly pre-populates a destination EXE, icon if exists`r`nwith script file name, and the .bin file to use."
	Else If (hwnd = oGui["Ahk2ExePath"].Hwnd)
		ToolTip "This is useful if you want to dump all the .bin files in one place.  Make sure`r`nyou append " Chr(34) " v#" Chr(34) " to the file names so you don't overwrite them.  This is`r`nparticularly important if you use AHK v1 and v2 .bin files together in the`r`nsame Ahk2Exe folder."
	Else If (hwnd = oGui["AhkLauncher"].Hwnd)
		ToolTip "Run AHK v1 and v2 scripts side by side without needing a separate file association.`r`n`r`nAppend " Chr(34) "_AHKv#" Chr(34) " to the file name, or add " Chr(34) ";AHKv#" Chr(34) " to the first line of the script." 
	Else
		ToolTip
}

runGui()

runGui() {
	oGui := GuiCreate("","AHK Portable Installer " AhkPisVersion)
	oGui.OnEvent("Close","gui_Close")
	
	Ahk1Version := (Settings.Has("Ahk1Version")) ? Settings["Ahk1Version"] : ""
	Ahk2Version := (Settings.Has("Ahk2Version")) ? Settings["Ahk2Version"] : ""
	Ahk1Html := "<a href=" Chr(34) Settings["Ahk1Url"] Chr(34) ">AHKv1:</a>    " Ahk1Version
	Ahk2Html := "<a href=" Chr(34) Settings["Ahk2Url"] Chr(34) ">AHKv2:</a>    " Ahk2Version
	
	oGui.Add("Link","vAhk1Version xm w220",Ahk1Html).OnEvent("Click","LinkEvents")
	oGui.Add("Link","vAhk2Version x+0 w220",Ahk2Html).OnEvent("Click","LinkEvents")
	oGui.Add("Edit","vActiveVersion xm y+8 w440 -E0x200 ReadOnly","Installed:")
	
	LV := oGui.Add("ListView","xm y+0 r5 w440 vExeList","Description|Version|File Name|Full Path")
	LV.OnEvent("DoubleClick","GuiEvents"), LV.OnEvent("Click","ListClick")
	
	oGui.Add("Edit","vCurrentPath xm y+8 w440 -E0x200 ReadOnly","Path:    ")
	
	oGui.Add("Button","vToggleSettings y+0","Settings").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vHelp x+62","Help").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vWindowSpy x+0","Window Spy").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vUninstall x+0","Uninstall AHK").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vActivateExe x+55 yp","Activate EXE").OnEvent("Click","GuiEvents")
	
	tabs := oGui.Add("Tab","y+10 x2 w456","Basics|Extras")
	
	oGui.Add("Text","xm y+10","Base AHK Folder:    (Leave blank for program directory)")
	oGui.Add("Edit","y+0 r1 w390 vBaseFolder ReadOnly")
	oGui.Add("Button","x+0 vPickBaseFolder","...").OnEvent("Click","GuiEvents")
	oGui.Add("Button","x+0 vClearBaseFolder","X").OnEvent("Click","GuiEvents")
	oGui.Add("Text","xm y+4","AutoHotkey v1 URL:")
	oGui.Add("Edit","y+0 r1 w440 vAhk1Url").OnEvent("Change","GuiEvents")
	oGui.Add("Text","xm y+4","AutoHotkey v2 URL:")
	oGui.Add("Edit","y+0 r1 w440 vAhk2Url").OnEvent("Change","GuiEvents")
	
	oGui.Add("Checkbox","vAutoUpdateCheck xm y+10","Automatically check for updates").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vCheckUpdateNow x+153 yp-4","Check Updates Now").OnEvent("Click","GuiEvents")
	
	oGui.Add("Text","xm y+4","Text Editor:")
	oGui.Add("Edit","xm y+0 w390 vTextEditorPath ReadOnly")
	oGui.Add("Button","x+0 vPickTextEditor","...").OnEvent("Click","GuiEvents")
	oGui.Add("Button","x+0 vDefaultTextEditor","X").OnEvent("Click","GuiEvents")
	
	oGui.Add("Button","vEditAhk1Template xm y+10 w220","Edit AHK v1 Template").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vEditAhk2Template x+0 w220","Edit AHK v2 Template").OnEvent("Click","GuiEvents")
	
	tabs.UseTab("Extras")
	oGui.Add("Checkbox","vAhk2ExeHandler xm y+10","Use fancy Ahk2Exe handler").OnEvent("Click","GuiEvents")
	oGui.Add("Checkbox","vAhk2ExeAutoStart x+20","Auto Start Compiler").OnEvent("Click","GuiEvents")
	oGui.Add("Checkbox","vAhk2ExeAutoClose x+20","Auto Close Compiler").OnEvent("Click","GuiEvents")
	
	oGui.Add("Text","xm y+10","Ahk2Exe Path:    (Used with fancy Ahk2Exe handler)")
	oGui.Add("Edit","vAhk2ExePath xm y+0 w390 ReadOnly")
	oGui.Add("Button","vPickAhk2ExePath x+0","...").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vClearAhk2ExePath x+0","X").OnEvent("Click","GuiEvents")
	
	oGui.Add("Checkbox","vAhkLauncher xm y+10","Use AHK Launcher").OnEvent("Click","GuiEvents")
	
	oGui.Add("Text","xm y+10","AHKv1 Path:")
	oGui.Add("Edit","vAhkLaunchV1 xm y+0 w390 ReadOnly")
	oGui.Add("Button","vPickAhkLaunchV1 x+0","...").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vClearAhkLaunchV1 x+0","X").OnEvent("Click","GuiEvents")
	
	oGui.Add("Text","xm y+4","AHKv2 Path:")
	oGui.Add("Edit","vAhkLaunchV2 xm y+0 w390 ReadOnly")
	oGui.Add("Button","vPickAhkLaunchV2 x+0","...").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vClearAhkLaunchV2 x+0","X").OnEvent("Click","GuiEvents")
	
	x := Settings["posX"], y := Settings["posY"]
	
	PopulateSettings()
	ListExes()
	; oGui.Show()
	oGui.Show("w460 h220 x" x " y" y)
	
	result := CheckUpdate()
	If (result And result != "NoUpdate")
		MsgBox result, "Update Check Failed", 0x10
}

SetActiveVersionGui() {
	ActiveVersion := (Settings.Has("ActiveVersion")) ? Settings["ActiveVersion"] : ""
	oCtl := oGui["ActiveVersion"], oCtl.Text := "Installed:    " ActiveVersion, oCtl := ""
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
	
	If (!Settings.Has("Ahk2ExePath"))
		Settings["Ahk2ExePath"] := ""
	Ahk2ExePath := Settings["Ahk2ExePath"]
	oGui["Ahk2ExePath"].Value := Ahk2ExePath
	
	If (!Settings.Has("Ahk2ExeHandler"))
		Settings["Ahk2ExeHandler"] := 0
	oGui["Ahk2ExeHandler"].Value := Settings["Ahk2ExeHandler"]
	
	If (Settings["Ahk2ExeHandler"]) {
		oGui["PickAhk2ExePath"].Enabled := True
		oGui["ClearAhk2ExePath"].Enabled := True
	} Else {
		oGui["PickAhk2ExePath"].Enabled := False
		oGui["ClearAhk2ExePath"].Enabled := False
	}
	
	If (!Settings.Has("AhkLauncher"))
		Settings["AhkLauncher"] := 0
	oGui["AhkLauncher"].Value := Settings["AhkLauncher"]
	
	If (!Settings["AhkLauncher"]) {
		oGui["PickAhkLaunchV1"].Enabled := False, oGui["PickAhkLaunchV2"].Enabled := False
		oGui["ClearAhkLaunchV1"].Enabled := False, oGui["ClearAhkLaunchV2"].Enabled := False
	}
	
	If (!Settings.Has("AhkLaunchV1"))
		Settings["AhkLaunchV1"] := ""
	If (!Settings.Has("AhkLaunchV2"))
		Settings["AhkLaunchV2"] := ""
	
	oGui["AhkLaunchV1"].Value := Settings["AhkLaunchV1"]
	oGui["AhkLaunchV2"].Value := Settings["AhkLaunchV2"]
	
	If (!Settings.Has("Ahk2ExeAutoStart"))
		Settings["Ahk2ExeAutoStart"] := 0
	oGui["Ahk2ExeAutoStart"].Value := Settings["Ahk2ExeAutoStart"]
	
	If (!Settings.Has("Ahk2ExeAutoClose"))
		Settings["Ahk2ExeAutoClose"] := 0
	oGui["Ahk2ExeAutoClose"].Value := Settings["Ahk2ExeAutoClose"]
	
	oCtl := ""
}

ListExes() {
	props := ["Name","Product version","File description"]
	oCtl := oGui["ExeList"]
	oCtl.Opt("-Redraw"), oCtl.Delete()
	
	BaseFolder := (!Settings.Has("BaseFolder") Or Settings["BaseFolder"] = "") ? A_ScriptDir : Settings["BaseFolder"]
	
	Loop Files BaseFolder "\*.exe", "R"
	{
		If (InStr(A_LoopFileName,"AutoHotkey") And !InStr(A_LoopFileName,"setup") And A_LoopFileName != "AutoHotkey.exe") {
			outProps := FileXpro(A_LoopFileFullPath,props*)
			oCtl.Add("",outProps["File description"],outProps["Product version"],outProps["Name"],A_LoopFileFullPath)
		}
	}
	oCtl.ModifyCol(1,170), oCtl.ModifyCol(2,120), oCtl.ModifyCol(3,128), oCtl.ModifyCol(4,0)
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
	Download Settings["Ahk1Url"] "version.txt", "version1.txt"
	If (ErrorLevel)
		errMsg := "Could not reach AHKv1 page."
	Download Settings["Ahk2Url"] "version.txt", "version2.txt"
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
	}

	If (Ahk2Version != NewAhk2Version) {
		MsgBox "New AutoHotkey v2 update!"
		Settings["Ahk2Version"] := NewAhk2Version
	}
	
	oGui["Ahk1Version"].Text := "<a href=" Chr(34) Settings["Ahk1Url"] Chr(34) ">AHKv1:</a>    " NewAhk1Version
	oGui["Ahk2Version"].Text := "<a href=" Chr(34) Settings["Ahk2Url"] Chr(34) ">AHKv2:</a>    " NewAhk2Version

	FileDelete "version1.txt"
	FileDelete "version2.txt"
	
	return errMsg
}

GuiEvents(oCtl,Info) {
	If (oCtl.Name = "ToggleSettings") {
		newH := 480
		p := oGui.Pos, scrW := SysGet(78), scrH := SysGet(79)
		
		If ((p.y + newH) > scrH)
			diff := (p.y + newH) - scrH + SysGet(4) + (SysGet(8) * 2) + (SysGet(6) * 2) + (SysGet(33) * 2)
		Else
			diff := 0
		
		toggle := Settings["toggle"]
		If (toggle) {
			newY := Settings["curPosY"]
			oGui.Show("w460 h220 y" newY), Settings["toggle"] := 0
		} Else {
			newY := p.y - diff
			Settings["curPosX"] := p.x, Settings["curPosY"] := p.y
			oGui.Show("w460 h" newH " y" newY), Settings["toggle"] := 1
		}
	} Else If (oCtl.Name = "ActivateExe" or oCtl.Name = "ExeList") { ; <---------------------------------- activate exe
		LV := oGui["ExeList"]
		row := LV.GetNext(), exeFullPath := LV.GetText(row,4), ver := LV.GetText(row,2), desc := LV.GetText(row,1)
		bitness := (InStr(desc,"32-bit")) ? "32-bit" : "64-bit", ahkType := (InStr(desc,"ANSI")) ? "ANSI" : "Unicode"
		majorVer := SubStr(ver,1,1), template := "TemplateV" majorVer ".ahk"
		
		ActiveVersion := desc " " ver
		Settings["ActiveVersion"] := ActiveVersion, Settings["ActiveVersionPath"] := exeFullPath
		
		; clear active version
		dispCtl := oGui["ActiveVersion"], dispCtl.Text := "Installed:    ", dispCtl := ""
		
		SplitPath exeFullPath, exeFile, exeDir
		
		Ahk2ExeHandler := Settings["Ahk2ExeHandler"]
		Ahk2ExePath := (Settings["Ahk2ExePath"] And Ahk2ExeHandler) ? Settings["Ahk2ExePath"] : exeDir "\Compiler\Ahk2Exe.exe"
		TextEditorPath := Settings["TextEditorPath"]
		Ahk2ExeBin := ahkType " " bitness ".bin"
		mpress := (FileExist(exeDir "\Compiler\mpress.exe")) ? 1 : 0
		
		templateText := FileRead("resources\" template)
		
		; .ahk extension and template settings
		RegWrite "AutoHotkeyScript", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.ahk" ; defines ProgID - this should NOT CHANGE!
		RegWrite "AutoHotkey Script v" majorVer, "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.ahk\ShellNew", "ItemName" ; defines context menu > New text
		RegWrite "Template.ahk", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.ahk\ShellNew", "FileName" ; specify template path, default = %WinDir%\ShellNew
		
		; update template accordingn to majorVer
		FileDelete A_WinDir "\ShellNew\Template.ahk"
		FileAppend templateText, A_WinDir "\ShellNew\Template.ahk"
		
		SetRegView 64
		Run "reg delete HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\AutoHotkey /f /reg:64",,"Hide"
		Run "reg delete HKEY_LOCAL_MACHINE\Software\AutoHotkey /f /reg:64",,"Hide"
		SetRegView 32
		Run "reg delete HKEY_LOCAL_MACHINE\Software\AutoHotkey /f /reg:32",,"Hide"
		SetRegView "Default"
		
		Sleep 500
		
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
		RegWrite exeDir, "REG_SZ", "HKEY_LOCAL_MACHINE\Software\AutoHotkey", "InstallDir"				; Default entries
		RegWrite exeFile, "REG_SZ", "HKEY_LOCAL_MACHINE\Software\AutoHotkey", "InstallExe"
		RegWrite "AutoHotkey", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\AutoHotkey", "StartMenuFolder"		; Default entries
		RegWrite ver, "REG_SZ", "HKEY_LOCAL_MACHINE\Software\AutoHotkey", "Version"						; Default entries
		RegWrite majorVer, "REG_SZ", "HKEY_LOCAL_MACHINE\Software\AutoHotkey", "MajorVersion"			; just in case it's helpful
		
		; Copy selected version to AutoHotkey.exe
		FileDelete exeDir "\AutoHotkey.exe"
		FileCopy exeFullPath, exeDir "\AutoHotkey.exe"
		
		SetRegView "Default"
		
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
		regDir := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey","InstallDir")
		helpFile := regDir "\AutoHotkey.chm"
		Run helpFile,, "Max"
	} Else If (oCtl.Name = "EditAhk1Template") {
		Run Chr(34) Settings["TextEditorPath"] Chr(34) " " Chr(34) "resources\TemplateV1.ahk"
	} Else If (oCtl.Name = "EditAhk2Template") {
		Run Chr(34) Settings["TextEditorPath"] Chr(34) " " Chr(34) "resources\TemplateV2.ahk"
	} Else If (oCtl.Name = "WindowSpy") {
		If (Settings.Has("ActiveVersionPath") And Settings["ActiveVersionPath"] != "") {
			SplitPath Settings["ActiveVersionPath"], exeFile, exeDir
			Run Chr(34) exeDir "\WindowSpy.ahk" Chr(34)
		}
	} Else If (oCtl.Name = "Uninstall") {
		If (MsgBox("Remove AutoHotkey from registry?","Uninstall AutoHotkey",0x24) = "Yes") {
			SetRegView 32
			Run "regedit.exe /s resources\Uninstall_AHK.reg"
			
			SetRegView 64
			Run "regedit.exe /s resources\Uninstall_AHK.reg"
			RegDelete "HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey"
			
			Settings["ActiveVersion"] := "", Settings["ActiveVersionPath"] := ""
			SetActiveVersionGui()
			
			SetRegView "Default"
		}
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
		
		If (Settings["Ahk2ExeHandler"]) {
			oGui["PickAhk2ExePath"].Enabled := True
			oGui["ClearAhk2ExePath"].Enabled := True
		} Else {
			oGui["PickAhk2ExePath"].Enabled := False
			oGui["ClearAhk2ExePath"].Enabled := False
		}
	} Else If (oCtl.Name = "AhkLauncher") {
		Settings["AhkLauncher"] := oCtl.Value
		If (oCtl.Value) {
			oGui["PickAhkLaunchV1"].Enabled := True, oGui["PickAhkLaunchV2"].Enabled := True
			oGui["ClearAhkLaunchV1"].Enabled := True, oGui["ClearAhkLaunchV2"].Enabled := True
		} Else {
			oGui["PickAhkLaunchV1"].Enabled := False, oGui["PickAhkLaunchV2"].Enabled := False
			oGui["ClearAhkLaunchV1"].Enabled := False, oGui["ClearAhkLaunchV2"].Enabled := False
		}
	} Else If (oCtl.Name = "PickAhkLaunchV1" Or oCtl.Name = "PickAhkLaunchV2") {
		curName := StrReplace(oCtl.Name,"Pick",""), ver := StrReplace(oCtl.Name,"PickAhkLaunch")
		AhkLaunchVar := Settings[curName], pickerPath := AhkLaunchVar
		pickerPath := !pickerPath ? Settings["BaseFolder"] : pickerPath
		
		AhkLaunchVar := FileSelect("",pickerPath,"Choose Autohotkey.exe for " ver ":","Executable (*.exe)")
		If (AhkLaunchVar) {
			Settings[curName] := AhkLaunchVar
			oGui[curName].Value := AhkLaunchVar
		}
	} Else if (oCtl.Name = "ClearAhkLaunchV1" Or oCtl.Name = "ClearAhkLaunchV2") {
		curName := StrReplace(oCtl.Name,"Clear","")
		Settings[curName] := "", oGui[curName].Value := ""
	} Else If (oCtl.Name = "Ahk2ExeAutoStart") {
		Settings[oCtl.Name] := oCtl.Value
	} Else If (oCtl.Name = "Ahk2ExeAutoClose") {
		Settings[oCtl.Name] := oCtl.Value
	}
	oCtl := ""
}

gui_Close(o) {
	Settings["BaseFolder"] := o["BaseFolder"].Value
	dims := oGui.Pos
	Settings["posX"] := dims.x, Settings["posY"] := dims.y
	FileDelete "Settings.xml"
	SettingsXML := XA_Save(Settings)
	FileAppend SettingsXML, "Settings.xml"
	ExitApp
}

