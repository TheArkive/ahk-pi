; AHK v2 Template
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

; #INCLUDE Lib\_XA_LoadSave.ahk
#INCLUDE Lib\_JXON.ahk

Global Settings, inFile, oGui, fileDir, fileTitle, Ahk2ExeFullPath, Ahk2ExeBinPath, MajorVersion, dims, bf

If (!FileExist("Settings.json")) {
	MsgBox "Can't read Settings.json`r`nHalting..."
	ExitApp
}

; SettingsXML := FileRead("Settings.xml"), Settings := XA_Load(SettingsXML)
SettingsJSON := FileRead("Settings.json"), Settings := Jxon_Load(SettingsJSON)
DisableTooltips := Settings["DisableTooltips"]
Ahk2ExeHandler := Settings["Ahk2ExeHandler"]

OnMessage(0x0200,"WM_MOUSEMOVE") ; WM_MOUSEMOVE
WM_MOUSEMOVE(wParam, lParam, Msg, hwnd) {
	If (IsObject(oGui) And DisableTooltips) {
		If (hwnd = oGui["SelOption"].Hwnd)
			ToolTip "Select output EXE name.`r`nCustomize it in the edit box below.`r`nDouble-click to select and compile, or click OK."
		Else If (hwnd = oGui["CustomOption"].Hwnd)
			ToolTip "Type a custom EXE name and press OK.`r`nSelect (single-click) from the list above to auto-fill your selection."
		Else
			ToolTip
	} Else
		ToolTip
}

If (!A_Args.Length) {
	MsgBox "No parameters specified."
	ExitApp
}

inFile := A_Args[1]
If (inFile = "") {
	MsgBox "No input file specified."
	ExitApp
} Else If (!FileExist(inFile)) {
	MsgBox "Specified script does not exist."
	ExitApp
}

SplitPath inFile,,fileDir,,fileTitle

If (A_Is64BitOs)
	SetRegView 64

Ahk2ExeFullPath := RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe","Ahk2ExePath")
SplitPath Ahk2ExeFullPath,,Ahk2ExeDir

bf := RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe","BitFilter")
If (!bf)
	bf := "All"
bfStr := "All|32-Bit|64-bit|"
BitFilterStr := StrReplace(bfStr,bf "|",bf "||"), BitFilterStr := (SubStr(BitFilterStr,-2) = "||") ? BitFilterStr : Trim(BitFilterStr,"|")

; SetRegView 64
AhkPath := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey","InstallDir")
; SetRegView 32
; If (!AhkPath)
	; AhkPath := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\AutoHotkey","InstallDir")
If (!AhkPath){
	MsgBox "AHK install seems to be corrupt.  Please uninstall and reinstall."
	ExitApp
}

Ahk2ExeBinPath := Ahk2ExeDir "\*.bin"
; MajorVersion := RegRead("HKEY_CURRENT_USER\Software\AutoHotkey","MajorVersion")

fileList := Relist()

oGui := GuiCreate()
txt := oGui.Add("Text","",StrReplace(fileList,"|","`r`n"))
dims := txt.pos
oGui.Destroy(), oGui := ""

w := dims.w + 30
If (w < 200) {
	width := "w200"
	btn := "xm"
} Else {
	width := "w" w
	btn := "x" ((dims.w + 30) / 2) - 90
}

newList := FilterList(fileList)
runGui(newList,width,btn,BitFilterStr)

runGui(fileList,width,btn,BitFilterStr) {
	oGui := GuiCreate("AlwaysOnTop -SysMenu","Select EXE Output Name")
	oGui.OnEvent("Close","gui_Close")
	oGui.OnEvent("Escape","gui_Close")
	
	oGui.Add("DropDownList","vBitFilter xm w50",BitFilterStr).OnEvent("Change","GuiEvents")
	
	opt := "vSelOption xm y+4 " width " r9"
	LB := oGui.Add("ListBox",opt,fileList)
	LB.OnEvent("DoubleClick","GuiEvents")
	LB.OnEvent("Change","ListSel")
	ed := oGui.Add("Edit","vCustomOption xm " width)
	ed.OnEvent("Change","GuiEvents")
	
	oGui.Add("Button","vOkBtn " btn " w100","OK").OnEvent("Click","GuiEvents")
	oGui.Add("Button","vCancelBtn x+0 w100","Cancel").OnEvent("Click","GuiEvents")
	
	oGui.Show()
}

fillCustom(oCtl,Info) {
	oCtl.Value := fileTitle ".exe"
}

ListSel(oCtl,Info) {
	outFile := oCtl.Text
	sillySep := InStr(outFile,">")
	
	If (sillySep) {
		binType := SubStr(outFile,1,sillySep-2)
		outFile := SubStr(outFile,sillySep+2)
	}
	
	oGui["CustomOption"].Value := outFile
	If (binType)
		RegWrite binType ".bin", "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe", "LastBinFile"
}

GuiEvents(oCtl,Info) {
	If (oCtl.Name = "SelOption") { ; double-click event
		outFile := oCtl.Text
		sillySep := InStr(outFile,">")
		
		If (sillySep) {
			binType := SubStr(outFile,1,sillySep-2)
			outFile := SubStr(outFile,sillySep+2)
		}
		oGui["CustomOption"].Value := outFile ; fill edit box
		
		If (binType)
			RegWrite binType ".bin", "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe", "LastBinFile" ; write registry
		
		DoCompile(outFile) ; do comile
	} Else If (oCtl.Name = "OkBtn") {
		custOpt := oGui["CustomOption"].Text
		If (custOpt)
			DoCompile(custOpt)
	} Else If (oCtl.Name = "CancelBtn") {
		ExitApp
	} Else If (oCtl.Name = "CustomOption") {
		oGui["SelOption"].Value := 0
	} Else If (oCtl.Name = "BitFilter") {
		bf := oCtl.Text
		RegWrite bf, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe", "BitFilter"
		fileList := Relist()
		newList := FilterList(fileList)
		oGui["SelOption"].Delete(), oGui["SelOption"].Add(newList)
	}
}

DoCompile(outFile) {
	If (RegExMatch(outFile,"^.*[\\/?<>\:*|]+.*$")) {
		MsgBox "Out File: " outFile "`r`n`r`nDo not use any of these characters in the output file name:`r`n`r`n\ / ? < > \ : * |"
		return
	}
	
	compileStr := Chr(34) Ahk2ExeFullPath Chr(34)
	
	oGui.Destroy(), oGui := ""
	ToolTip
	
	Run compileStr,,, pid
	
	WinWaitActive "ahk_pid " pid
	ControlSetText inFile, "Edit1", "ahk_pid " pid
	ControlSetText fileDir "\" outFile, "Edit2", "ahk_pid " pid
	
	icoFile := fileDir "\" fileTitle ".ico"
	If (FileExist(icoFile))
		ControlSetText icoFile, "Edit3", "ahk_pid " pid
	
	If (Settings["Ahk2ExeAutoStart"]) {
		; msgbox "ready!"
		; ControlClick "Button7", "ahk_pid " pid
		ControlSend "{Space}", "Button7", "ahk_pid " pid
	}
	
	If (Settings["Ahk2ExeAutoClose"]) {
		WinWait "ahk_pid " pid, "Conversion complete."
		WinClose "ahk_pid " pid, "Conversion complete."
		WinClose "ahk_pid " pid
	}
	
	ExitApp
}

ReList() {
	Loop Files Ahk2ExeBinPath
	{
		curBin := SubStr(A_LoopFileName,1,-4)
		props := StrSplit(curBin," ")
		curType := SubStr(props[1],1,1)
		curBitness := (props.Length >= 2) ? props[2] : ""
		majVer := (props.Length >= 3) ? props[3] : ""
		
		If (curBitness)
			curBitness := SubStr(curBitness,1,2)
		
		majVer := StrReplace(majVer,"v","")
		Ending := curType curBitness

		If (InStr(A_LoopFileName,"AutoHotkeySC")) {
			fileList .= curBin " > " fileTitle ".exe|"
		} Else {
			fileList .= curBin " > " fileTitle ".exe|" curBin " > " fileTitle " " curBitness ".exe|" curBin " > " fileTitle " " Ending ".exe|"
		}
	}
	fileList := Trim(fileList,"|")
	return fileList
}

FilterList(fileList) {
	If (bf != "All") {
		Loop Parse fileList, "|"
		{
			If (InStr(A_LoopField,bf))
				fileListFilter .= A_LoopField "|"
		}
		fileListFilter := Trim(fileListFilter,"|")
	} Else
		fileListFilter := fileList
	return fileListFilter
}

gui_Close(o) {
	ExitApp
}