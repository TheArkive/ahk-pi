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
	
	SplitPath sInput, &ahkFile, &curDir
	isAhkH := false, var := "", installDir := curDir, ahkType := "", bitness := "", var := ""
	
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