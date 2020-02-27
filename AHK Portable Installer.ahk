; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

#INCLUDE ..\_INCLUDE\_LibraryV2
#INCLUDE _FileXpro.ahk
#INCLUDE TheArkive_XA_LoadSave.ahk

Global oGui, Settings
SettingsXML := FileRead("Settings.xml"), Settings := XA_Load(SettingsXML), Settings["toggle"] := 0 ; load settings

OnMessage(0x0200,"WM_MOUSEMOVE") ; WM_MOUSEMOVE
WM_MOUSEMOVE(wParam, lParam, Msg, hwnd) {
	If (hwnd = oGui["ActivateExe"].Hwnd)
		ToolTip "Modify settings as desired first, including templates.`r`nThen click this button."
	Else If (hwnd = oGui["ExeList"].Hwnd)
		ToolTip "Double-click to activate."
	Else
		ToolTip
}

runGui()

runGui() {
	oGui := GuiCreate("","AHK Portable Installer")
	oGui.OnEvent("Close","gui_Close")
	
	Ahk1Version := (Settings.Has("Ahk1Version")) ? Settings["Ahk1Version"] : ""
	Ahk2Version := (Settings.Has("Ahk2Version")) ? Settings["Ahk2Version"] : ""
	Ahk1Html := "<a href=" Chr(34) Settings["Ahk1Url"] Chr(34) ">AHKv1:</a>    " Ahk1Version
	Ahk2Html := "<a href=" Chr(34) Settings["Ahk2Url"] Chr(34) ">AHKv2:</a>    " Ahk2Version
	
	oGui.Add("Link","vAhk1Version xm w220",Ahk1Html).OnEvent("Click","LinkEvents")
	oGui.Add("Link","vAhk2Version x+0 w220",Ahk2Html).OnEvent("Click","LinkEvents")
	oGui.Add("Text","vActiveVersion xm y+8 w440","Installed:")
	
	oGui.Add("ListView","xm y+8 r5 w440 vExeList","Description|Version|File Name|Full Path").OnEvent("DoubleClick","GuiEvents")
	oGui.Add("Button","vToggleSettings","Settings").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vHelp x+62","Help").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vWindowSpy x+0","Window Spy").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vUninstall x+0","Uninstall AHK").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vActivateExe x+55 yp","Activate EXE").OnEvent("Click","GuiEvents")
	
	oGui.Add("Text","xm y+10","Base AHK Folder:    (Leave blank for program directory)")
	oGui.Add("Edit","y+0 r1 w390 vBaseFolder ReadOnly")
	oGui.Add("Button","x+0 vPickBaseFolder","...").OnEvent("Click","GuiEvents")
	oGui.Add("Button","x+0 vClearBaseFolder","X").OnEvent("Click","GuiEvents")
	oGui.Add("Text","xm y+4","AutoHotkey v1 URL:")
	oGui.Add("Edit","y+0 r1 w440 vAhk1Url").OnEvent("Change","GuiEvents")
	oGui.Add("Text","xm y+4","AutoHotkey v2 URL:")
	oGui.Add("Edit","y+0 r1 w440 vAhk2Url").OnEvent("Change","GuiEvents")
	
	oGui.Add("Checkbox","vAutoUpdateCheck xm y+8","Automatically check for updates").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vCheckUpdateNow x+153 yp-4","Check Updates Now").OnEvent("Click","GuiEvents")
	
	oGui.Add("Text","xm y+4","Script Text Editor:")
	oGui.Add("Edit","xm y+0 w390 vTextEditorPath ReadOnly")
	oGui.Add("Button","x+0 vPickTextEditor","...").OnEvent("Click","GuiEvents")
	oGui.Add("Button","x+0 vDefaultTextEditor","X").OnEvent("Click","GuiEvents")
	
	oGui.Add("Button","vEditAhk1Template xm w220","Edit AHK v1 Template").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vEditAhk2Template x+0 w220","Edit AHK v2 Template").OnEvent("Click","GuiEvents")
	
	PopulateSettings()
	ListExes()
	; oGui.Show()
	oGui.Show("w460 h195")
	
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
	
	BaseFolder := (!Settings.Has("BaseFolder") Or Settings["BaseFolder"] = "") ? "" : Settings["BaseFolder"]
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
	oCtl.ModifyCol(1,170), oCtl.ModifyCol(2,120), oCtl.ModifyCol(3,120), oCtl.ModifyCol(4,0)
	oCtl.Opt("+Redraw")
	
	ActiveVersionPath := (Settings.Has("ActiveVersionPath")) ? Settings["ActiveVersionPath"] : ""
	rows := oCtl.GetCount()
	
	If (ActiveVersionPath and rows) {
		Loop rows {
			curPath := oCtl.GetText(A_Index,4)
			If (ActiveVersionPath = curPath) {
				oCtl.Modify(A_Index,"Vis Select")
				break
			}
		}
	}
	oCtl.Focus(), oCtl := ""
}

LinkEvents(oCtl,Info,href) {
	If (href)
		Run href
}

GuiEvents(oCtl,Info) {
	If (oCtl.Name = "ToggleSettings") {
		toggle := Settings["toggle"]
		If (toggle)
			oGui.Show("w460 h195"), Settings["toggle"] := 0
		Else
			oGui.Show("w460 h415"), Settings["toggle"] := 1
	} Else If (oCtl.Name = "ActivateExe" or oCtl.Name = "ExeList") { ; <---------------------------------- activate exe
		LV := oGui["ExeList"]
		row := LV.GetNext(), exeFullPath := LV.GetText(row,4), ver := LV.GetText(row,2), desc := LV.GetText(row,1)
		bitness := (InStr(desc,"32-bit")) ? "32-bit" : "64-bit", ahkType := (InStr(desc,"ANSI")) ? "ANSI" : "Unicode"
		majorVer := SubStr(ver,1,1), template := "Ahk" majorVer "Template"
		
		ActiveVersion := desc " " ver
		Settings["ActiveVersion"] := ActiveVersion, Settings["ActiveVersionPath"] := exeFullPath
		SetActiveVersionGui()
		
		SplitPath exeFullPath, exeFile, exeDir
		Ahk2ExePath := exeDir "\Compiler\Ahk2Exe.exe", TextEditorPath := Settings["TextEditorPath"]
		Ahk2ExeBin := ahkType " " bitness ".bin"
		mpress := (FileExist(exeDir "\Compiler\mpress.exe")) ? 1 : 0
		
		Ahk1Template := FileRead("resources\TemplateV1.ahk"), Ahk2Template := FileRead("resources\TemplateV2.ahk")
		
		If (bitness = "64-bit")
			SetRegView 64
		Else
			SetRegView 32
		; .ahk extension and template settings
		RegWrite "AutoHotkeyScript", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.ahk" ; defines ProgID - this should NOT CHANGE!
		RegWrite "AutoHotkey Script v" majorVer, "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.ahk\ShellNew", "ItemName" ; defines context menu > New text
		RegWrite "Template.ahk", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.ahk\ShellNew", "FileName" ; specify template path, default = %WinDir%\ShellNew
		
		; update template accordingn to majorVer
		FileDelete A_WinDir "\ShellNew\Template.ahk"
		FileAppend %template%, A_WinDir "\ShellNew\Template.ahk"
		
		; update ProgID
		RegWrite "AutoHotkey Script v" majorVer, "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript"	; ProgID title, asthetic only?
		RegWrite exeFullPath ",1", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\DefaultIcon"		; default icon
		RegWrite "Open", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell"
		RegWrite "Compile Script", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell\Compile"	; Compile context menu entry
		regVal := Chr(34) Ahk2ExePath Chr(34) "/in " Chr(34) "%1" Chr(34)
		RegWrite regVal, "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell\Compile\Command"		; Compile command
		RegWrite "Edit Script", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell\Edit"			; Edit context menu entry
		regVal := Chr(34) TextEditorPath Chr(34) " " Chr(34) "%1" Chr(34)
		RegWrite regVal, "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell\Edit\Command"		; Edit command
		RegWrite "Run Script", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell\Open"			; Open context menu entry
		regVal := Chr(34) exeFullPath Chr(34) " " Chr(34) "%1" Chr(34) " %*"
		RegWrite regVal, "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AutoHotkeyScript\Shell\Open\Command"		; Open command
		
		; Ahk2Exe entries
		RegWrite Ahk2ExeBin, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe", "LastBinFile"	; auto set .bin file
		RegWrite mpress, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe", "LastUseMPRESS"		; auto set mpress usage
		
		; HK_User / Software / AutoHotkey install and version info
		RegWrite exeDir, "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey", "InstallDir"				; Default entries
		RegWrite "AutoHotkey", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey", "StartMenuFolder"	; Default entries
		RegWrite ver, "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey", "Version"						; Default entries
		RegWrite majorVer, "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey", "MajorVersion"			; just in case it's helpful
		
		; Copy selected version to AutoHotkey.exe
		FileDelete exeDir "\AutoHotkey.exe"
		FileCopy exeFullPath, exeDir "\AutoHotkey.exe"
		
		SetRegView "Default"
		
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
		SetRegView 32
		Run "regedit.exe /s resources\Uninstall_AHK.reg"
		SetRegView 64
		Run "regedit.exe /s resources\Uninstall_AHK.reg"
		
		Settings["ActiveVersion"] := "", Settings["ActiveVersionPath"] := ""
		SetActiveVersionGui()
		
		SetRegView "Default"
	}
	oCtl := ""
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

gui_Close(o) {
	Settings["BaseFolder"] := o["BaseFolder"].Value
	FileDelete "Settings.xml"
	SettingsXML := XA_Save(Settings)
	FileAppend SettingsXML, "Settings.xml"
	ExitApp
}

