; AHK v2
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

#INCLUDE Lib\_JXON.ahk

Global Settings, inFile, oGui, regexList, ahkProps, ActiveVersionPath, binSelect, matchFound
Global DisableTooltips, scriptDir, scriptTitle, Ahk2ExeFullPath, Ahk2ExeBinPath, AhkExeFullPath

If (!FileExist("Settings.json")) {
	MsgBox "Can't read Settings.json`r`nHalting..."
	ExitApp
}

If (A_Is64BitOs)
	SetRegView 64

; === define settings ====================================================================
SettingsJSON := FileRead("Settings.json"), Settings := Jxon_Load(SettingsJSON)
DisableTooltips := Settings["DisableTooltips"]
Ahk2ExeHandler := Settings["Ahk2ExeHandler"]
DebugNow := Settings["DebugNow"]
regexList := Settings["regexList"]
ActiveVersionPath := Settings["ActiveVersionPath"]

OnMessage(0x0200,"WM_MOUSEMOVE") ; WM_MOUSEMOVE
WM_MOUSEMOVE(wParam, lParam, Msg, hwnd) {
	If (IsObject(oGui) And !DisableTooltips) {
		If (hwnd = oGui["SelOption"].Hwnd) {
			ToolTip "Select a base file and output EXE name."
			  . "`r`nCustomize it in the edit box below."
			  . "`r`nDouble-click to select and compile, or click OK."
		} Else If (hwnd = oGui["CustomOption"].Hwnd) {
			ToolTip "Optionally customize the EXE name and press OK."
			  . "`r`nSelect (single-click) from the list above to auto-fill your selection."
		} Else
			ToolTip
	} Else
		ToolTip
}

; === check no params ====================================================================
If (DebugNow) {
	; do nothing
} Else If (!A_Args.Length) {
	; MsgBox "No parameters specified."
	ExitApp
}

; === dump params into var ====================================================================
If (!DebugNow)
	inFile := A_Args[1]
Else If (DebugNow And FileExist(A_Args[1]))
	inFile := A_Args[1]
Else
	inFile := "test file.ahk"
SplitPath inFile,,scriptDir,,scriptTitle

; === check if params are invalid ====================================================================
If (DebugNow) {
	; do nothing
} Else If (inFile = "") {
	MsgBox "No input file specified."
	ExitApp
} Else If (!FileExist(inFile)) {
	MsgBox "Specified script does not exist."
	ExitApp
}

; === read firstLine of script ====================================================================
scriptText := FileRead(inFile) ; extract first line of script

Loop Parse scriptText, "`n", "`r"
{
	If (A_Index = 1) {
		firstLine := A_LoopField
		Break
	}
}

; === look for match ====================================================================
For label, obj in regexList { ; match EXE to firstLine
	regex := obj["regex"], exe := obj["exe"], matchType := Trim(obj["type"])
	
	If (matchType = 2 And Trim(firstLine) = Trim(regex))
		matchFound := true
	Else If (matchType = 1 And RegexMatch(firstLine,regex))
		matchFound := true
	
	If matchFound
		break
	
	matchFound := false
}
; msgbox "match: " matchFound
If (DebugNow)
	Msgbox "Match exe: " exe "`r`n`r`nfirstLine: " firstLine

; === set ahkProps ====================================================================
If (!matchFound) {
	ahkProps := GetAhkProps(ActiveVersionPath)	; setup fallback version
	AhkExeFullPath := ActiveVersionPath
} Else {
	ahkProps := GetAhkProps(exe)				; setup match version
	If (IsObject(ahkProps))
		AhkExeFullPath := ahkProps["exePath"]
}

If (!IsObject(ahkProps) Or !FileExist(ahkProps["exePath"])) { ; if EXE is invalid / not found
	Msgbox "Invalid EXE specified to run script.  Check your settings in the Extras tab."
	ExitApp
}

; === set Ahk2Exe.exe full path ====================================================================
Ahk2ExeFullPath := ahkProps["installDir"] "\Compiler\Ahk2Exe.exe" ; set Ahk2Exe.exe full path

; === set bin/exe/dll path ====================================================================
If (ahkProps["isAhkH"]) {
	Ahk2ExeBinPath := ahkProps["installDir"] "\*AutoHotkey*"
} Else
	Ahk2ExeBinPath := ahkProps["installDir"] "\Compiler\*.bin"

fileList := Relist()

runGui(fileList)

runGui(fileList) {
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

	oGui := GuiCreate("AlwaysOnTop -SysMenu","Select EXE Output Name")
	oGui.OnEvent("Close","gui_Close")
	oGui.OnEvent("Escape","gui_Close")
	
	oGui.Add("Text","xm",ahkProps["ahkProduct"] " v" ahkProps["ahkVersion"])
	bfCtl := oGui.Add("DropDownList","vBitFilter xm y+8 w50","All|32-bit|64-bit")
	bfCtl.OnEvent("Change","GuiEvents")
	bf := Settings.Has("BitFilter") ? Settings["BitFilter"] : 1
	bfCtl.Value := bf
	
	If (ahkProps["isAhkH"]) {
		ctl := oGui.Add("Checkbox","vMtFilter x+30 yp+4","MT")
		ctl.OnEvent("click","GuiEvents")
		
		ctl := oGui.Add("Checkbox","vFileSuffix x+30","Add type + bitness")
		ctl.OnEvent("click","GuiEvents")
	} Else {
		bfCtl.Value := 1, bf := 1
		ctl := oGui.Add("Checkbox","vFileSuffix x+30 yp+4","Add type + bitness")
		ctl.OnEvent("click","GuiEvents")
	}
	mt := ahkProps["isAhkH"] ? ctl.value : 0
	fileList := FilterList(fileList,bf,mt)
	
	opt := "vSelOption xm y+8 " width " r9"
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
	oCtl.Value := scriptTitle ".exe"
}

ListEvent(oCtl) { ; selection event
	outFile := oCtl.Text
	Settings["BitFilter"] := oCtl.gui["BitFilter"].value
	
	sillySepArr := StrSplit(outFile,">")
	curBinFile := Trim(sillySepArr[1])
	filePart := sillySepArr[sillySepArr.Length]
	curType := ahkProps["isAhkH"] ? sillySepArr[2] : sillySepArr[1]
	
	t := InStr(curType,"ANSI") ? "A" : "U"
	b := InStr(curType,"32-bit") ? "32" : "64"
	filePart := oCtl.gui["FileSuffix"].Value ? StrReplace(filePart,".exe","") t b ".exe" : filePart
	oGui["CustomOption"].Value := filePart
	
	baseDir := ahkProps["installDir"]
	
	If (ahkProps["isAhkH"]) {
		typePart := sillySepArr[2]
		t := InStr(typePart,"ANSI") ? "a" : "w"
		b := InStr(typePart,"64") ? "x64" : "Win32"
		mt := InStr(typePart,"MT") ? "_MT" : ""
		binPart := "\" b t mt
		majVer := SubStr(ahkProps["ahkVersion"],1,1)
		
		If (majVer = 1)
			binPath := baseDir "\Compiler\.." binPart "\" curBinFile
		Else If (majVer = 2)
			binPath := baseDir binPart "\" curBinFile
		
		RegWrite binPath, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastBinFile"
	} Else {
		RegWrite curBinFile, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe", "LastBinFile"
	}
	
	return outFile
}

ListSel(oCtl,Info) {
	worthless := ListEvent(oCtl)
}

GuiEvents(oCtl,Info) {
	If (oCtl.Name = "SelOption") { ; double-click event
		outFile := ListEvent(oCtl) ; user selected file name
		binFile := oCtl.Value
		If (outFile And binFile)
			DoCompile(outFile) ; do compile
	} Else If (oCtl.Name = "OkBtn") {
		outFile := oGui["CustomOption"].Text
		binFile := oGui["SelOption"].Value
		If (outFile And binFile)
			DoCompile(outFile) ; do compile
		Else
			MsgBox "Select a base file, and define an output EXE, or click Cancel."
	} Else If (oCtl.Name = "CancelBtn") {
		ExitHandler()
	} Else If (oCtl.Name = "BitFilter") {
		Settings["BitFilter"] := oCtl.Value
		bf := oCtl.Value
		mt := ahkProps["isAhkH"] ? oCtl.Gui["MtFilter"].value : 0
		fileList := ReList()
		fileList := FilterList(fileList,bf,mt)
		oCtl.gui["SelOption"].Delete()
		oCtl.gui["SelOption"].Add(fileList)
	} Else If (oCtl.Name = "MtFilter") {
		mt := ahkProps["isAhkH"] ? oCtl.Value : 0
		bf := oCtl.Gui["BitFilter"].Value
		fileList := ReList()
		fileList := FilterList(fileList,bf,mt)
		oCtl.gui["SelOption"].Delete()
		oCtl.gui["SelOption"].Add(fileList)
	} Else If (oCtl.Name = "FileSuffix") {
		If (oGui["SelOption"].Value) {
			curText := oGui["SelOption"].Text
			curArr := StrSplit(curText,">")
			curType := ahkProps["isAhkH"] ? curArr[2] : curArr[1]
			filePart := curArr[curArr.Length]
			
			t := InStr(curType,"ANSI") ? "A" : "U"
			b := InStr(curType,"32-bit") ? "32" : "64"
			
			outText := oCtl.Value ? StrReplace(filePart,".exe","") t b ".exe" : filePart
			oGui["CustomOption"].Value := outText
		}
	}
}

DoCompile(outStr) {
	sillySepArr := StrSplit(outStr,">")
	binFile := sillySepArr[1], outFile := sillySepArr[sillySepArr.Length]
	
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
	ControlSetText scriptDir "\" outFile, "Edit2", "ahk_pid " pid
	
	icoFile := scriptDir "\" scriptTitle ".ico"
	If (FileExist(icoFile))
		ControlSetText icoFile, "Edit3", "ahk_pid " pid
	
	If (Settings["Ahk2ExeAutoStart"]) {
		If (!ahkProps["isAhkH"])
			ControlSend "{Space}", "Button7", "ahk_pid " pid
		Else
			ControlSend "{Space}", "Button10", "ahk_Pid " pid
	}
	
	If (Settings["Ahk2ExeAutoClose"]) {
		WinWait "ahk_pid " pid, "Conversion complete."
		WinClose "ahk_pid " pid, "Conversion complete."
		WinClose "ahk_pid " pid
	}
	
	ExitHandler()
}

ReList() {
	recurse := ahkProps["isAhkH"] ? "R" : ""
	
	Loop Files Ahk2ExeBinPath, recurse
	{
		curBin := A_LoopFileName
		majVer := InStr(ahkProps["ahkVersion"],1,1)
		
		If (!InStr(curBin,".chm")) {
			If (ahkProps["isAhkH"]) {
				dirPart := StrReplace(A_LoopFileDir,ahkProps["installDir"] "\","")
				
				curType := InStr(dirPart,"Win32a") ? "ANSI" : "Unicode"
				mt := InStr(dirPart,"MT") ? " MT" : ""
				t := SubStr(curType,1,1)
				b := InStr(dirPart,"32") ? "32" : "64"
				
				fileList .= curBin " > " curType " " b "-bit" mt " > " scriptTitle ".exe|"
			} Else If (curBin != "AutoHotkeySC.bin") {
				props := StrSplit(curBin," ")
				curType := props[1], t := SubStr(curType,1,1)
				b := (props.Length >= 2) ? SubStr(props[2],1,2) : ""
				fileList .= curBin " > " scriptTitle ".exe|"
			}
		}
	}
	fileList := Sort(fileList,"U D|")
	fileList := Trim(fileList,"|")
	
	return fileList
}

FilterList(fileList,bf,mt) {
	If (bf = 1)
		bitness := "All"
	Else If (bf = 2)
		bitness := "32-bit"
	Else If (bf = 3)
		bitness := "64-bit"
	
	Loop Parse fileList, "|"
	{
		m1 := false
		If (mt And InStr(A_LoopField,"MT"))
			m1 := true
		Else If (!mt And !InStr(A_LoopField,"MT"))
			m1 := true
		Else
			m1 := false
		
		m2 := false
		If (bf = 1)
			m2 := true
		Else If (bf = 2 And InStr(A_LoopField,bitness))
			m2 := true
		Else If (bf = 3 And InStr(A_LoopField,bitness))
			m2 := true
		
		If (m1 And m2)
			fileListFilter .= A_LoopField "|"
	}
	fileListFilter := Trim(fileListFilter,"|")
	
	return fileListFilter
}

gui_Close(o) {
	ExitHandler()
}

ExitHandler() {
	SettingsStr := Jxon_Dump(Settings,4)
	if (SettingsStr) {
		FileDelete "Settings.json"
		FileAppend SettingsStr, "Settings.json"
	} Else
		Msgbox "Settings are blank!"
	
	ExitApp
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
;    - ahkVersion = v1.32.00.....   as typed, but leading "v" will be stripped
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