;
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

; #INCLUDE Lib\_XA_LoadSave.ahk
#INCLUDE Lib\_JXON.ahk

Global Settings, regexList

If (!FileExist("Settings.json")) {
	MsgBox "Can't read Settings.json`r`nHalting..."
	ExitApp
}

; SettingsXML := FileRead("Settings.xml"), Settings := XA_Load(SettingsXML)
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

SplitPath inFile,,fileDir,,fileTitle

scriptText := FileRead(inFile) ; isolate first line of text
Loop Parse scriptText, "`n", "`r"
{
	If (A_Index = 1) {
		firstLine := A_LoopField
		Break
	}
}


If (A_Is64BitOs)
	SetRegView 64
InstExe := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey","InstallExe")
If (Settings["DebugNow"])
	msgbox "InstExe: " InstExe

If (Settings["DebugNow"])
	Msgbox "firstLine: " firstLine

If (Settings.Has("AhkLauncher"))
	useLauncher := Settings["AhkLauncher"]
Else
	useLauncher := 0

If (useLauncher) { ; check for firstLine regex match
	For label, obj in regexList {
		regex := obj["regex"], exe := obj["exe"]
		If (RegexMatch(firstLine,regex)) {
			cmd := Chr(34) exe Chr(34) " " Chr(34) inFile Chr(34)
			If (Settings["DebugNow"])
				MsgBox label "`r`n`r`n" exe
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


GetAhkProps(sInput) {
	SplitPath sInput, ahkFile, curDir
	installDir := StrReplace(curDir,"\Win32a_MT"), installDir := StrReplace(installDir,"\Win32a")
	installDir := StrReplace(installDir,"\Win32w_MT"), installDir := StrReplace(installDir,"\Win32w")
	installDir := StrReplace(installDir,"\x64w_MT"), installDir := StrReplace(installDir,"\x64w")
	
	lastSlash := InStr(installDir,"\",false,-1)
	ahkPropStr := SubStr(installDir,lastSlash+1)
	propArr := StrSplit(ahkPropStr," ")
	ahkProduct := propArr[1], ahkVersion := propArr[2]
	
	variant := "" ; varient
	If (RegExMatch(ahkProduct,"i)^(AHK|AutoHotkey)[ _\-\.]*H$")) {
		If (InStr(ahkFile,"HA32MT.exe"))
			ahkType := "ANSI", bitness := "32-bit", variant := "MT"
		Else If (InStr(ahkFile,"HA32.exe"))
			ahkType := "ANSI", bitness := "32-bit"
		Else If (InStr(ahkFile,"HU32MT.exe"))
			ahkType := "Unicode", bitness := "32-bit", variant := "MT"
		Else If (InStr(ahkFile,"HU32.exe"))
			ahkType := "Unicode", bitness := "32-bit"
		Else if (InStr(ahkFile,"HU64MT.exe"))
			ahkType := "Unicode", bitness := "64-bit", variant := "MT"
		Else If (InStr(ahkFile,"HU64.exe"))
			ahkType := "Unicode", bitness := "64-bit"
	} Else If (RegExMatch(ahkProduct,"^(AHK|AutoHotkey)$")) {
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
	ahkProps["variant"] := variant, ahkProps["exeFile"] := ahkFile, ahkProps["exeDir"] := curDir
	
	If (ahkType = "" Or bitness = "")
		return ""
	Else
		return ahkProps
}
