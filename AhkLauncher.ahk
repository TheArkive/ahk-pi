; AHK v2
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

#INCLUDE Lib\_JXON.ahk

Global Settings, regexList

If (!FileExist("Settings.json")) {
	MsgBox "Can't read Settings.json`r`nHalting..."
	ExitApp
}

SettingsJSON := FileRead("Settings.json"), Settings := Jxon_Load(SettingsJSON)
regexList := Settings["regexList"]

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

SplitPath inFile,,fileDir,,fileTitle ; script bits

scriptText := FileRead(inFile) ; isolate first line of text
Loop Parse scriptText, "`n", "`r"
{
	If (A_Index = 1) {
		firstLine := A_LoopField
		Break
	}
}

InstExe := Settings["ActiveVersionPath"]

If (Settings.Has("AhkLauncher"))
	useLauncher := Settings["AhkLauncher"]
Else
	useLauncher := 0

If (useLauncher) { ; check for firstLine regex match
	For label, obj in regexList {
		regex := obj["regex"], exe := obj["exe"], matchType := Trim(obj["type"])
		cmd := Chr(34) exe Chr(34) " " Chr(34) inFile Chr(34)
		cmd := otherParams ? cmd " " otherParams : cmd
		runNow := false
		
		If (matchType = 2 And Trim(firstLine) = Trim(regex))
			runNow := true
		Else If (matchType = 1 And RegexMatch(firstLine,regex))
			runNow := true
		
		If (runNow) {
			Run cmd, fileDir ; run on match
			ExitApp
		}
	}
} 



If (!InstExe) { ; not using launcher, or doing fallback
	MsgBox "AutoHotkey installation appears to be incomplete.  Select an EXE to re-activate / reinstall and try again."
	ExitApp
} Else {
	cmd := Chr(34) InstExe Chr(34) " " Chr(34) inFile Chr(34)
	if (!otherParams)
		Run cmd, fileDir
	Else
		Run cmd " " otherParams, fileDir
	
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
