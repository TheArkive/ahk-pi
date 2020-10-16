; AHK v2 32-bit
;@Ahk2Exe-Bin Unicode 32-bit.bin

SendMode "Input"  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

#INCLUDE inc\_JXON.ahk

Global Settings := "", regexList := "", DebugNow := 0

If (!FileExist("Settings.json")) {
	MsgBox "Can't read Settings.json`r`nHalting..."
	ExitApp
}

SettingsJSON := FileRead("Settings.json"), Settings := Jxon_Load(SettingsJSON)
regexList := Settings["regexList"]

If (DebugNow) { ; debug mode
	q := Chr(34)
	; inFile := A_ScriptDir "\" A_ScriptName
    inFile := A_Args[1]
	otherParams := q "param1" q " " q "param2" q
} Else { ; normal mode
	If (!A_Args.Length) {
		MsgBox "No parameters specified."
		ExitApp
	}

	inFile := A_Args[1] ; collect first arguement - inFile
	If (inFile = "" Or !FileExist(inFile)) {
		MsgBox "Specified script does not exist."
		ExitApp
	}

	otherParams := "" ; collect remaining arguements
	Loop A_Args.Length {
		If (A_Index >= 2)
			otherParams .= Chr(34) A_Args[A_Index] Chr(34) " "
	}
	otherParams := Trim(otherParams," `t`r`n")
}

SplitPath inFile,,fileDir,,fileTitle ; script bits

scriptText := FileRead(inFile) ; isolate first line of text
Loop Parse scriptText, "`n", "`r"
{
	If (A_Index = 1) {
		firstLine := A_LoopField, scriptText := ""
		Break
	}
}

finalExe := Settings["ActiveVersionPath"]

If (Settings.Has("Ahk2ExeHandler"))
	useLauncher := Settings["Ahk2ExeHandler"]
Else
	useLauncher := 0

If (useLauncher) { ; check for firstLine regex match
	runNow := false, exe := "", compilerExe := ""
	For label, obj in regexList {
		runNow := false, regex := obj["regex"], exe := obj["exe"], matchType := Trim(obj["type"])
        If (!FileExist(exe))
            Continue
		
		If (matchType = 2 And Trim(firstLine) = Trim(regex)) Or (matchType = 1 And RegExMatch(firstLine,"i)" regex,match))
			runNow := true
        
		If (IsObject(match)) ; for error messages only
			curMatch := match.Value(0)
		Else
			curMatch := firstLine
		
		If (runNow)
			Break
	}
}

If (!exe)
    exe := finalExe
p := GetAhkProps(exe)
installDir := p["installDir"]
compilerExe := installDir "\Compiler\Ahk2Exe.exe"

; keep this in case AHK_H command line options are possible
If (p["isAhkH"] And SubStr(p["ahkVersion"],1,1) = 1)        ; AHK_H v1
    cmd := Chr(34) compilerExe Chr(34) ; " /in " Chr(34) inFile Chr(34)
Else If (p["isAhkH"] And SubStr(p["ahkVersion"],1,1) = 2)   ; AHK_H v2
    cmd := Chr(34) compilerExe Chr(34) ; " /in " Chr(34) inFile Chr(34)
Else If (!p["isAhkH"])                                      ; AHK normal
    cmd := Chr(34) compilerExe Chr(34) ; " /in " Chr(34) inFile Chr(34)

If (!FileExist(compilerExe)) {
    Msgbox "Invalid EXE specified to run script.  Check your settings in the Extras tab.`r`n`r`nExe:`r`n" compilerExe "`r`n`r`nRegex:  " regex "`r`n`r`nMatch:    " curMatch "`r`n`r`nMatch Type: " matchType " (2 = exact / 1 = regex)`r`n`r`nFirst Line:`r`n" firstLine
    ExitApp
}

If (!DebugNow)
    Run cmd, fileDir,,PID ; run on match
Else
    msgbox "cmd: " cmd "`r`n`r`nfileDir: " fileDir

WinWait "ahk_pid " PID
ControlSetText inFile, "Edit1", "ahk_pid " PID

ExitApp









; If (!InstExe) { ; not using launcher, or doing fallback
	; MsgBox "AutoHotkey installation appears to be incomplete.  Select an EXE to re-activate / reinstall and try again."
	; ExitApp
; } Else {
    ; SplitPath exe, exeFile, exeDir
    ; compilerExe := exeDir "\Compiler\Ahk2Exe.exe"
	
	; If (!DebugNow) {
		; if (!otherParams)
			; Run cmd, fileDir
		; Else
			; Run cmd " " otherParams, fileDir
	; } Else {
		; MsgBox "cmd: " cmd "`r`n`r`n otherParams: " otherParams "`r`n`r`nfileDir: " fileDir
	; }
	; ExitApp
; }


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
