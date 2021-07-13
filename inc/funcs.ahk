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
;    - product = AHK / AutoHotkey / AHK_H / AutoHotkey_H ... however it is typed
;    - version = Ex:  1.1.32.00
;    - majVersion = first char of version
;    - type = Unicode / ANSI
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
    ahkProduct := arr[1], bitness := StrReplace(arr[arr.Length],"-bit","")
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
    
    ahkProps := {exePath:sInput, installDir:installDir, product:ahkProduct, version:ahkVersion, majVersion:SubStr(ahkVersion,1,1)
               , type:ahkType, bitness:bitness, variant:var, exeFile:ahkFile, exeDir:curDir, isAhkH:isAhkH}
    
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
Explorer_GetSelection(hwnd:=0, usePath:=false) { ; thanks to boiler, from his RAAV script, slightly modified
    hWnd := (!hwnd) ? WinExist("A") : hwnd
    winClass := WinGetClass("ahk_id " . hwnd)
    
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
    Global Settings
    admin := false, exe := "", err := ""
    _bitness := bitness := A_Is64BitOS ? 64 : 32
    baseFolder := Settings["BaseFolder"] ? Settings["BaseFolder"] : A_ScriptDir "\versions"
    
    If !FileExist(in_script)
        return {exe:"", admin:false, err:"File does not exist."}
    
    script_text := FileRead(in_script)
    
    If RegExMatch(script_text,"im)^(?:;?[ `t]+)?#Requires.*",&m) {
        arr := StrSplit(Trim(m[0],";`t "),";")
        vArr := StrSplit(Trim(RegExReplace(arr[1],"(#Requires|\" Chr(34) ")",""),";`t ")," ")
        
        If !vArr.Has(2)
            return {exe:"", admin:false, err:"Specify the product (AutoHotkey / AutoHotkey_H) when using #REQUIRES directive."}
        
        isAhkH := ((prod := vArr[1])="AutoHotkeyH") ? true : false
        ver := (SubStr(vArr[2],1,1) = "v") ? SubStr(vArr[2],2) : vArr[2]
        
        If arr.Has(2) {
            For i, opt in StrSplit(Trim(arr[2]," `t")," ")
                If InStr(opt,"-bit") || (opt = 32 || opt = 64)
                    _bitness := StrReplace(opt,"-bit","")
                Else If (opt = "admin")
                    admin := true
        }
        
        If (_bitness > bitness)
            return {exe:"", admin:false, err:"64-bit executable specified on 32-bit system - halting."}
        Else bitness := _bitness
        
        exeList := ""
        Loop Files baseFolder "\AutoHotkey*.exe", "R"
        {
            f := GetAhkProps(A_LoopFileFullPath)
            If ((A_LoopFileName = "AutoHotkey.exe") && (!f.isAhkH))
            || RegExMatch(A_LoopFileFullPath,"i)\\(_*OLD_*|Compiler)\\")
                Continue
            
            If (!isAhkH && f.isAhkH) || (isAhkH && !f.isAhkH) ; matching exclusive for AHK_H status
                Continue
            
            If (f.majVersion = SubStr(ver,1,1)) ; (VerCompare(f.version,ver) >= 0)
            && (bitness = f.bitness) && InStr(f.version,ver)
                exeList .= (exeList?"`r`n":"") f.version "|" f.exePath
        }
        
        Loop Parse Sort(exeList,"N"), "`n", "`r"
            exe := SubStr(A_LoopField,InStr(A_LoopField,"|")+1)
    } Else
        exe := Settings["ActiveVersionPath"]
    
    If (compiler) {
        f := GetAhkProps(exe)
        exe := f.installDir "\Compiler\Ahk2Exe.exe"
    }
    
    If (!exe && !Settings["ActiveVersionPath"])
        err := "You need to select / install a version of AutoHotkey from the main UI."
    
    return {exe:exe, admin:admin, err:err}
}


; =======================================================================
; hash() - Supports MD2, MD4, MD5, SHA1, SHA256, SHA384, SHA512
;    buf = can be a buffer, a string, or a file name (string)
;    hashType = pick one [MD2, MD4, MD5, SHA1, SHA256, SHA384, SHA512]
; =======================================================================
hash(buf,hashType:="sha256") {
    If (Type(buf) = "String") && FileExist(buf) ; to expand:  https://www.phdcc.com/cryptorc4.htm
        buf := FileRead(buf,"RAW")
    Else If (Type(buf) = "String")
        buf := Buffer(StrPut(txt := buf),0)
      , StrPut(txt, buf)
    Else if (Type(buf) != "Buffer")
        return -1 ; invalid value passed in buffer
    
    hashList := {MD2:0x8001, MD4:0x8002, MD5:0x8003, SHA:0x8004, SHA1:0x8004
               , SHA256:0x800C, SHA384:0x800D, SHA512:0x800E}
    
    r1 := DllCall("advapi32\CryptAcquireContext","UPtr*",&hProv:=0,"Ptr",0,"Ptr",0
                                                ,"UInt",PROV_RSA_AES:=0x18,"UInt",0xF0000000)
    
    r3 := DllCall("advapi32\CryptCreateHash","UPtr",hProv,"UInt",hashList.%hashType% ; 0x800C
                                            ,"UInt",0,"UInt",0,"UPtr*",&hHash:=0)
    
    r5 := DllCall("advapi32\CryptHashData","UPtr",hHash,"UPtr",buf.ptr,"UInt",buf.size,"UInt",0)
    
    r6 := DllCall("advapi32\CryptGetHashParam","UPtr",hHash,"UInt",HP_HASHVAL:=0x2
                                              ,"UPtr",0,"UInt*",&iSize1:=0,"UInt",0)
    outHash := Buffer(iSize1,0), outVal := ""
    r7 := DllCall("advapi32\CryptGetHashParam","UPtr",hHash,"UInt",HP_HASHVAL:=0x2
                                              ,"UPtr",outHash.ptr,"UInt*",&iSize2:=iSize1,"UInt",0)
    Loop iSize2
        outVal .= Format("{:02X}",NumGet(outHash,A_Index-1,"UChar"))
    
    r4 := DllCall("advapi32\CryptDestroyHash","UPtr",hHash)
    r2 := DllCall("advapi32\CryptReleaseContext","UPtr",hProv,"UInt",0)
    
    return outVal
}

