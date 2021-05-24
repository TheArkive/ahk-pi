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


; sFile := FileSelect()
; If !sFile
    ; exitapp    
; SplitPath sFile, &_FileExt, &_Dir, &_Ext, &_File, &_Drv
; objShl := ComObject("Shell.Application")
; objDir := objShl.NameSpace(_Dir)
; objItm := objDir.ParseName(_FileExt)
; msgbox "Product Name:`t" objItm.ExtendedProperty("{0CEF7D53-FA64-11D1-A203-0000F81FEDEE} 7") "`r`n"
     ; . "File Desc:`t" objItm.ExtendedProperty("{0CEF7D53-FA64-11D1-A203-0000F81FEDEE} 3") "`r`n"
     ; . "Product Ver:`t" objItm.ExtendedProperty("{0CEF7D53-FA64-11D1-A203-0000F81FEDEE} 8") "`r`n" ; (not listed in propkey.h)
     ; . "Copyright:`t" objItm.ExtendedProperty("{64440492-4C8B-11D1-8B70-080036B11A03} 11") 
     
     
GetAhkProps(sInput) {
    If (!FileExist(sInput))
        return ""
    
    SplitPath sInput, &ahkFile, &curDir
    objShl := ComObject("Shell.Application")
    objDir := objShl.NameSpace(curDir)
    objItm := objDir.ParseName(ahkFile)
    FileDesc    := objItm.ExtendedProperty("{0CEF7D53-FA64-11D1-A203-0000F81FEDEE} 3")
    ahkVersion  := objItm.ExtendedProperty("{0CEF7D53-FA64-11D1-A203-0000F81FEDEE} 8")
    
    arr := StrSplit(FileDesc," ")
    ahkProduct := arr[1], bitness := arr[arr.Length]
    isAhkH := (ahkProduct = "AutoHotkey_H")?true:false
    ahkType := (arr.Length = 3) ? arr[2] : "Unicode"
    
    var := "", installDir := curDir
    
    If (InStr(sInput,"\Win32a_MT\"))
        installDir := StrReplace(installDir,"\Win32a_MT"), var := "MT"
    Else If (InStr(sInput,"\Win32a\"))
        installDir := StrReplace(installDir,"\Win32a")
    Else If (InStr(sInput,"\Win32w_MT\"))
        installDir := StrReplace(installDir,"\Win32w_MT"), var := "MT"
    Else If (InStr(sInput,"\Win32w\"))
        installDir := StrReplace(installDir,"\Win32w")
    Else If (InStr(sInput,"\x64w_MT\"))
        installDir := StrReplace(installDir,"\x64w_MT"), var := "MT"
    Else If (InStr(sInput,"\x64w\"))
        installDir := StrReplace(installDir,"\x64w")
    
    ahkProps := Map()
    ahkProps["exePath"] := sInput, ahkProps["installDir"] := installDir, ahkProps["ahkProduct"] := ahkProduct
    ahkProps["ahkVersion"] := ahkVersion, ahkProps["ahkType"] := ahkType, ahkProps["bitness"] := bitness
    ahkProps["variant"] := var, ahkProps["exeFile"] := ahkFile, ahkProps["exeDir"] := curDir, ahkProps["isAhkH"] := isAhkH
    
    If (ahkType = "" Or bitness = "")
        return ""
    Else
        return ahkProps
}

; ===========================================================================
; created by TheArkive
; Usage: Specify X/Y coords to get info on which monitor that point is on,
;        and the bounds of that monitor.  If no X/Y is specified then the
;        current mouse X/Y coords are used.
; ===========================================================================
GetMonitorData(x:="", y:="") {
    CoordMode "Mouse", "Screen" ; CoordMode Mouse, Screen ; AHK v1
    If (x = "" Or y = "")
        MouseGetPos &x, &y
    actMon := 0
    
    monCount := MonitorGetCount() ; SysGet, monCount, MonitorCount ; AHK v1
    Loop monCount { ; Loop % monCount { ; AHK v1
        MonitorGet(A_Index,&mLeft,&mTop,&mRight,&mBottom) ; SysGet, m, Monitor, A_Index ; AHK v1
        
        If (mLeft = "" And mTop = "" And mRight = "" And mBottom = "")
            Continue
        
        If (x >= (mLeft) And x <= (mRight-1) And y >= mTop And y <= (mBottom-1)) {
            monList := {}, monList.left := mLeft, monList.right := mRight
            monList.top := mTop, monList.bottom := mBottom, monList.active := A_Index
            monList.x := x, monList.y := y
            monList.Cx := ((mRight - mLeft) / 2) + mLeft
            monList.Cy := ((mBottom - mTop) / 2) + mTop
            monList.w := mRight - mLeft, monList.h := mBottom - mTop
            Break
        }
    }
    
    return monList
}

; ====================================================================================
; Explorer_GetSelection()
; ====================================================================================
; thanks to boiler
;       https://www.autohotkey.com/boards/viewtopic.php?f=6&t=76602&p=332166&hilit=boiler+RAAV#p332166
; thanks to Rapte_Of_Suzaku
;       https://autohotkey.com/board/topic/60985-get-paths-of-selected-items-in-an-explorer-window/
; thanks to TeaDrinker
;       https://www.autohotkey.com/boards/viewtopic.php?p=255169#p255169
; ====================================================================================
Explorer_GetSelection(usePath:=false) { ; thanks to boiler, from his RAAV script, slightly modified
    winClass := WinGetClass("ahk_id " . hWnd := WinExist("A"))
    
    if !(winClass ~= "((Cabinet|Explore)WClass|WorkerW|Progman)") ; add checking for icons on desktop
        Return
    
    for window in ComObject("Shell.Application").Windows
        if (hWnd = window.HWND) && (oShellFolderView := window.document)
            break
    
    result := ""
    If (winClass = "WorkerW" Or winClass = "Progman") {
        root := (SubStr(A_Desktop,-1)=="\") ? SubStr(A_Desktop,1,-1) : A_Desktop
        
        items := ListViewGetContent("Selected", "SysListView321", hwnd)
        Loop Parse items, "`n", "`r"
            result .= ((A_Index>1)?"`n":"") root "\" SubStr(A_LoopField,1,InStr(A_LoopField,Chr(9))-1)
    } Else {
        root := oShellFolderView.Folder.Self.Path
        
        for item in oShellFolderView.SelectedItems
            result .= (result = "" ? "" : "`n") . item.path
    }
    
    if !result And usePath
        result := root
    
    Return result
}

; ====================================================================================
; This func parses the first line of a script, and checks for
; a "first-line version comment" match.  If one is found then
; the corresponding AutoHotkey.exe or Ahk2Exe.exe is returned.
; Otherwise, the user selected "base version" EXE (or base
; version compiler exe) is returned.
; ====================================================================================
proc_script(in_script, compiler:=false) {
    Global regexList := Settings["regexList"]
    
    If !FileExist(in_script)
        return
    
    script_text := FileRead(in_script)
    firstLine := StrReplace(SubStr(script_text,1,InStr(script_text,"`n")-1),"`r","")
    
    For label, obj in regexList {
        regex := obj["regex"], exe := obj["exe"], matchType := Trim(obj["type"])
        runNow := false
        
        If (matchType = 2 And Trim(firstLine) = Trim(regex))
            runNow := true
        Else If (matchType = 1 And RegExMatch(firstLine,"i)" regex))
            runNow := true
        
        If (runNow)
            Break
    }
    
    If (!compiler) {
        If !Settings["AhkLauncher"] ; If not using AHK Launcher, always use Base Version.
            return Settings["ActiveVersionPath"]
        Else                        ; If using AHK Launcher, check for "first-line version comment" match first.
            return (exe and runNow) ? exe : Settings["ActiveVersionPath"]
    } Else {
        base_ver := GetAhkProps(Settings["ActiveVersionPath"])
        
        If !Settings["Ahk2ExeHandler"]
            return base_ver["installDir"] "\Compiler\Ahk2Exe.exe"
        Else If (exe and runNow) {
            exe_ver := GetAhkProps(exe)
            return exe_ver["installDir"] "\Compiler\Ahk2Exe.exe"
        }
    }
}