; AHKv2
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

; #INCLUDE Lib\_FileXpro.ahk
#INCLUDE Lib\TheArkive_XA_LoadSave.ahk

Global Settings

If (!FileExist("Settings.xml")) {
	MsgBox "Can't read Settings.xml`r`nHalting..."
	ExitApp
}

SettingsXML := FileRead("Settings.xml"), Settings := XA_Load(SettingsXML)

If (!A_Args.Length) {
	MsgBox "No parameters specified."
	ExitApp
}

inFile := A_Args[1]
If (inFile = "" Or !FileExist(inFile)) {
	MsgBox "Specified script does not exist."
	ExitApp
}

otherParams := ""
Loop A_Args.Length {
	If (A_Index >= 2)
		otherParams .= Chr(34) A_Args[A_Index] Chr(34) " "
}
otherParams := Trim(otherParams," `t`r`n")

SplitPath inFile,,fileDir,,fileTitle

fileIndic := SubStr(fileTitle,-6) ; extract last 6 chars of file name

scriptText := FileRead(inFile) ; try to match "; AHK v#"
Loop Parse scriptText, "`r", "`n"
{
	If (A_Index = 1) {
		firstLine := A_LoopField
		Break
	}
}

matchResult := RegExMatch(firstLine,"^;[ ]*AHK[ ]?v([12])",match) ; try to match "_AHKv#"
If (IsObject(match) And match.Count())
	curMatch := match.Value(1)
Else
	curMatch := ""

AhkLaunchV1 := Settings["AhkLaunchV1"], AhkLaunchV2 := Settings ["AhkLaunchV2"] ; load settings

If (fileIndic = "_AHKv1") ; determine exe
	mainExe := AhkLaunchV1
Else If (fileIndic = "_AHKv2")
	mainExe := AhkLaunchV2
Else If (curMatch) {
	If (curMatch = "1")
		mainExe := AhkLaunchV1
	Else If (curMatch = "2")
		mainExe := AhkLaunchV2
}


cmd := Chr(34) mainExe Chr(34) " " Chr(34) inFile Chr(34)
If (otherParams)
	cmd .= " " otherParams


If (Settings.Has("AhkLauncher"))
	useLauncher := Settings["AhkLauncher"]
Else
	useLauncher := 0


If (useLauncher and mainExe)
	Run cmd, fileDir
Else { ; fall back to installed EXE
	If (A_Is64bitOS)
		SetRegView 64
	
	InstDir := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey","InstallDir")
	InstExe := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey","InstallExe")
	
	If (!InstDir And !InstExe) {
		SetRegView 32
		InstDir := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey","InstallDir")
		InstExe := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey","InstallExe")
	}
	
	SetRegView "Default"
	
	If (!InstDir Or !InstExe) {
		MsgBox "AutoHotkey installation appears to be incomplete.  Select an EXE to activate, and optionally define the EXEs to use with the AhkLauncher."
	} Else {
		cmd := Chr(34) InstDir "\" InstExe Chr(34) " " Chr(34) inFile Chr(34)
		if (!otherParams)
			Run cmd, fileDir
		Else
			Run cmd " " otherParams, fileDir
	}
}


ExitApp
