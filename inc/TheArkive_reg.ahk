; ======================================================================================
; Reg class - wrapper for the REG command.
; ======================================================================================
; This was made to attempt making a wider set of functionality for interacting with the
; registry feel more "native" to AutoHotkey.  Also, hopefully when a few instances of
; RegWrite() fail due to 'Access Denied', hopefully this script class will succeed.
;
; For testing, and when pulling arrays of sub-keys and values, it is recommended to use
; the JXON library [jxon_dump() function] to view the contents easily:
;
;   YEJP - Yet Another Json Parser
;   https://www.autohotkey.com/boards/viewtopic.php?f=83&t=74799
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Methods
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;   reg.query(key, value := "", recurse := false)
;
;       - This is the "REG QUERY" command.  It retrieves values from the registry.  If
;         you specify a "value" then it only gets that value and returns the result in
;         the same way as RegRead().  Otherwise, this method returns a Map() of keys
;         in the output, and each key in the Map() has a sub-Map() of values.  The blank
;         (or Default) values in a key are represented as "(Default)" within array output.
;
;       Usage Examples:
;
;           string := reg.query("HKCU\My_key", "my_value")
;
;               -> Returns the data stored in "my_value" as a string in the same manner as RegRead().
;
;           assoc_array := reg.query("HKCU\My_key",,true)
;
;               -> Returns a Map() of all values and sub-keys.
;
;           assoc_array := reg.query("HKCU\My_key","My_value",true)
;
;               -> Returns a Map() of all instances of "My_value" in each subkey.
;
;         + Getting data from an array after using reg.query()
;
;                my_data := arr["HKLM\sub_key"]["value"]["data"]
;           my_data_type := arr["HKLM\sub_key"]["value"]["data_type"]
;
;         + NOTE: If you need to loop through multiple registry values, it is better to
;                 use reg.query() to dump the full contents of your subkey into an array
;                 and loop through in a FOR loop, rather than using reg.query("key","value")
;                 to loop through in a Registry Loop.  If you use a Registry Loop, then
;                 stick with using RegRead() / RegWrite().
;
;   reg.add(key, value := "", data := "", rgType := "REG_SZ", sep := "\0")
;
;       - This is the "REG ADD" command.  It adds data or keys to the registry.  If adding
;         a subkey or value that does not exist, all non-existant subkeys will be created
;         as the subkey/value is written to the registry.  This method is almost identical
;         to RegWrite().  The return value only indicates success or failure (true/false).
;
;       Usage Examples:
;
;           boolean := reg.add("HKCU\Software\my_key")
;
;               -> Attempts to add "my_key" subkey to the registry key "HKCU\Software".
;
;           boolean := reg.add("HKCU\Software\my_key","my_value")
;
;               -> Attempts to add "my_value" to the registry key "HKCU\Software\my_key"
;                  with no data.
;
;           boolean := reg.add("HKCU\Software\my_key","my_value","some_data")
;               -> Attempts to add "my_value" to the registry key "HKCU\Software\my_key"
;                  with the string "some_data" as the string value.  The default data type
;                  is REG_SZ.
;
;           boolean := reg.add("HKCU\Software\my_key","my_value","some_data`r`n more_data","REG_MULTI_SZ", [sep := "\0"])
;               -> Attempts to add "my_value" to the registry key "HKCU\Software\my_key" with the
;                  string "some_data" as the data.  The data type "REG_MULTI_SZ" is specified.
;                  The default delimiter for REG_MULTI_SZ input is "`n" or "`r`n".  Refer to
;                  RegWrite() for further documentation on how to write other data types to the registry.
;
;   reg.delete(key, value := "", clearKey := false)
;
;       - Deletes the specified key or value.  If [clearKey] is specified then all values
;         in the specified key are removed.  This command is very similar to RegDelete().
;         The [clearKey] parameter is ignored if the [value] parameter is specified.
;
;           boolean := reg.delete("HKCU\Software\my_key")
;
;               -> Deletes registry key "HKCU\Software\my_key".
;
;           boolean := reg.delete("HKCU\Software\my_key",,true)
;
;               -> Deletes all values within the key "HKCU\Software\my_key".  All subkeys
;                  and values within subkeys are left intact, as well as the specified key.
;
;           boolean := reg.delete("HKCU\Software\my_key","my_value")
;
;               -> Delete value named "my_value" from registry key "HKCU\Software\my_key".
;
;   reg.export(key, file := "", overwrite := true)
;
;       - Exports the specified key to a .reg file.  If no file name is specified, then the name
;         of the specified subkey is used as the file name.  This may fail if the specified subkey
;         contains characters that are not valid for file names.  The default action is to overwrite
;         the .reg file if it exists.
;
;   reg.import(file)
;
;       - Imports the specified .reg file.
;
;   reg.save(key, file := "", overwrite := true)
;   reg.restore(key, file)
;
;       - The "REG SAVE" / "REG RESTORE" commands save or write .hiv files.  These are similar to
;         .reg files, but are also meant to be used with the "REG LOAD" / "REG UNLOAD" commands.
;         The SAVE / RESTORE metods can be used almost exactly the same as EXPORT / IMPORT commands
;         but the resulting .hiv files are not meant to be human-readable.
;
;   reg.load(key, file)
;   reg.unload(key)
;
;       - Currently I get "Access Denied" whenever I try to load a .hiv file.  I'm not yet sure of
;         the context this is meant to be used in.  Here is the online help docs from Microsoft:
;         https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/reg-load
;
;         It seems that UAC or some other "elevated" privelates may be needed for LOAD/UNLOAD to
;         properly funtion.  I currently am unable to use these commands with normal admin rights.
;         https://superuser.com/questions/993771/reg-un-load-access-denied
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Properties
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;   reg.regSide
;
;       - Default value = ""
;       - Other values = 32 or 64
;       - Specifies whether to look at the 32 or 64 bit side of the registry.  The default
;         value results in the default registry view based on OS architechture.  Normally
;         this property only affects 64-bit systems.  Changing this property is nearly
;         identical to the RegView command in AHK.
;
;   reg.reason
;
;       - Contains the full text of the output error message.  On no error, this value is blank.
;
;   reg.cmd
;
;       - Contains the full command line passed to CMD for troubleshooting.
;
;   Usage Examples:
;
;       cur_reg_view := reg.regSide ; gets the current reg view
;
;       reg.regSide  := new_regView ; sets the new reg view (32, 64, or "")
;
;       error_reason := reg.reason ; gets error message, when reg.method() returns false.
;
; ======================================================================================
; EXAMPLES
; ======================================================================================
;
; #INCLUDE _JXON.ahk ; https://www.autohotkey.com/boards/viewtopic.php?f=83&t=74799
; msgbox jxon_dump(reg.query("HKCU\Software\Classes","",true),4) ; gets all blank (Default) key value data in HKCU\Software\Classes
;
; ======================================================================================
;
; output_array := reg.query("HKEY_CLASSES_ROOT\*")
; msg_txt := ""

; For key, key_contents in output_array { ; looping through reg.query() output in a FOR loop
    ; msg_txt .= key "`r`n"
    ; For value, val_info in key_contents {
        ; msg_txt .= "    VALUE:  " value " (TYPE: " val_info["type"] ")`r`n"
        ; msg_txt .= "        DATA: " val_info["data"] "`r`n"
    ; }
; }
; msgbox msg_txt
;
; ======================================================================================
;
; msgbox "value:  " reg.query("HKEY_CLASSES_ROOT\*","ConflictPrompt")
; msgbox reg.export("HKEY_CLASSES_ROOT\*","HKCR-astrisk.reg") ; exports HKCR\* to a .reg file
;
; ======================================================================================
class reg {
    Static null := Chr(3), reason := "", cli := "", regSide := "" ; regSide = 64 / 32 / ("" = default)
    
    Static query(key, value := "", recurse := false) {
        v := ((value="") ? " /ve" : (value!=this.null ? " /v " value : ""))
        r := (this.regSide = 32) ? " /reg:32" : (this.regSide = 64) ? " /reg:64" : ""   ; like RegView command
        this.cmd := "reg query " key v (recurse?" /s":"") r
        result := this.cliData(this.cmd)
        return this.validate(result,value,recurse)
    }
    Static add(key, value := "", data := "", rgType := "REG_SZ", sep := "\0") {
        q := (InStr(rgType,"_SZ") ? Chr(34) : "") ; enclose ONLY string values in "quotes"
        v := ((value="") ? " /ve" : (value != this.null ? " /v " value : ""))
        r := (this.regSide = 32) ? " /reg:32" : (this.regSide = 64) ? " /reg:64" : ""
        t := (rgType != "REG_SZ") ? " /t " rgType : ""                      ; registry data type
        s := (sep != "\0") ? " /s " sep : ""                                ; specify different separator
        d := StrReplace(data,Chr(34),"\" Chr(34))                           ; escape Chr(34)
        d := (rgType = "REG_MULTI_SZ") ? RegExReplace(d,"`n|`r`n",sep) : d  ; conversion for REG_MULTI_SZ
        d := (data != "") ? " /d " q d q : ""                               ; data to be written
        
        this.cmd := "reg add " key v (v ? t s d : "") " /f" r
        result := this.cliData(this.cmd)
        return this.validate(result)
    }
    Static delete(key, value := "", clearKey := false) {
        v := ((value="") ? " /ve" : (value != this.null ? " /v " value : clearKey ? " /va" : ""))
        r := (this.regSide = 32) ? " /reg:32" : (this.regSide = 64) ? " /reg:64" : ""
        this.cmd := "reg delete " key v " /f" r
        result := this.cliData(this.cmd)
        return this.validate(result)
    }
    Static export(key, file := "", overwrite := true) {
        SplitPath key, endKey, pathKey, ext
        file := (file="") ? endKey ".reg" : file   ; default file name is key name
        file := (SubStr(file,-4) != ".reg") ? file ".reg" : file
        r := (this.regSide = 32) ? " /reg:32" : (this.regSide = 64) ? " /reg:64" : ""
        o := (overwrite ? " /y" : "")       ; check for overwrite
        v := this.validateFileName(file)    ; validate provided file/path
        this.cmd := "reg export " key " " Chr(34) file  Chr(34) o r
        result := ((v And o) Or (v And !FileExist(file) And o)) ? this.cliData(this.cmd) : false
        return this.validate(result)
    }
    Static import(file) {
        r := (this.regSide = 32) ? " /reg:32" : (this.regSide = 64) ? " /reg:64" : ""
        v := this.validateFileName(file)
        this.cmd := "reg import " Chr(34) file Chr(34) r
        result := v ? this.cliData(this.cmd) : false
        return this.validate(result)
    }
    Static save(key, file := "", overwrite := true) {
        SplitPath key, endKey, pathKey, ext
        file := (file="") ? endKey ".hiv" : file   ; default file name is key name
        file := (SubStr(file,-4) != ".hiv") ? file ".hiv" : file
        r := (this.regSide = 32) ? " /reg:32" : (this.regSide = 64) ? " /reg:64" : ""
        o := (overwrite ? " /y" : "")       ; check for overwrite
        v := this.validateFileName(file)    ; validate provided file/path
        this.cmd := "reg export " key " " Chr(34) file  Chr(34) o r
        result := ((v And o) Or (v And !FileExist(file) And o)) ? this.cliData(this.cmd) : false
        return this.validate(result)
    }
    Static restore(key, file) {
        r := (this.regSide = 32) ? " /reg:32" : (this.regSide = 64) ? " /reg:64" : ""
        this.cmd := "reg restore " key " " Chr(34) file Chr(34) r
        result := FileExist(file) ? this.cliData(this.cmd) : false
        return this.validate(result)
    }
    Static load(key, file) {
        r := (this.regSide = 32) ? " /reg:32" : (this.regSide = 64) ? " /reg:64" : ""
        this.cmd := "reg load " key " " Chr(34) file Chr(34) r
        result := FileExist(file) ? this.cliData(this.cmd) : false
        return this.validate(result)
    }
    Static unload(key) {
        this.cmd := "reg unload " key
        return this.validate(this.cliData(this.cmd))
    }
    Static output_to_array(sInput, value := "", recurse := false) {
        sInput := RegExReplace(sInput,"(`r`n){2,}","`r`n") ; simplify text, remove extra CRLFs
        a := StrSplit(sInput,"`n","`r"), main := Map(), curKey := "", main.CaseSense := false
        
        If RegExMatch(sInput,"^HKEY_") { ; only convert to array if output data starts with "HKEY_"
            For i, t in a {
                If RegExMatch(t,"i)^(HKEY_|End of search)") {
                    If (InStr(t,"End of search") = 1)
                        Break ; parsing query output is done
                    curKey ? (main[curKey] := curElem) : "" ; write previous curElem before starting new one
                    main[curKey := t] := "", curElem := Map(), curElem.CaseSense := false
                } Else {
                    p := RegExMatch(t,"    (REG_SZ|REG_MULTI_SZ|REG_EXPAND_SZ|REG_DWORD|REG_QWORD|REG_BINARY|REG_NONE)(    )?",match)
                    typ := match.Value(1)                       ; extract reg data type
                    vn := SubStr(t,5,p-5)                ; value name
                    data := SubStr(t,p+8+StrLen(typ))           ; data associated with value name
                    data := (typ = "REG_MULTI_SZ") ? StrReplace(data,"\0","`n") : data ; replace "\0" with "`n" for REG_MULTI_SZ
                    curElem[((vn="(Default)") ? "Default" : vn)] := Map("data",data,"type",typ)
                }
            }
            main[curKey] := curElem ; write final element
        }
        return (value != this.null And !recurse) ? data : curKey ? main : sInput ; queried value, array of keys/values, or text data
    }
    Static validate(sInput, value := "", recurse := false) { ; catch and handle error messages, or return output
        reason := StrReplace(sInput,"`r`nType " Chr(34) "REG EXPORT /?" Chr(34) " for usage.","")
        If (RegExMatch(sInput,"^ERROR\:")) Or (sInput = "End of search: 0 match(es) found.")
            result := false
        Else If (sInput = "The operation completed successfully.")
            reason := "", result := true
        Else
            reason := "", result := this.output_to_array(sInput, value, recurse)
        
        this.reason := reason
        return result
    }
    Static validateFileName(inPath) {
        SplitPath inPath, outFile, outDir
        result := (outDir ? FileExist(outDir) : true), invalidChars := "><:/\|?*" Chr(34)
        Loop Parse invalidChars
            result := !result ? false : !InStr(outFile, A_LoopField)
        return result
    }
    Static CliData(CmdLine, WorkingDir:="", Codepage:="CP0") { ; inspired by SKAN's RunCMD() https://www.autohotkey.com/boards/viewtopic.php?f=6&t=74647
        enc := !StrLen(Chr(0xFFFF))?"UTF-8":"UTF-16", p4 := (A_PtrSize=4), p := A_PtrSize, output := ""
        bCmd := BufferAlloc(bSize := StrPut(CmdLine,enc),0), StrPut(CmdLine, bCmd, enc)
        bWD := BufferAlloc(bSize := StrPut(workingDir,enc),0), StrPut(workingDir, bWD, enc)
        
        DllCall("CreatePipe","Ptr*",hPr:=0,"Ptr*",hPw:=0,"Ptr",0,"UInt",0), DllCall("SetHandleInformation","Ptr",hPw,"Uint",1,"Uint",1)
        pi := BufferAlloc(p4?16:24, 0), si := BufferAlloc(siSize:=p4?68:104,0) ; PROCESS_INFORMATION / STARTUPINFO
        NumPut("UInt", siSize, si, 0), NumPut("UInt", 0x101, si, p4?44:60) ; dwFlags = 0x100 STARTF_USESTDHANDLES || 0x1 = check wShowWindow
        NumPut("Ptr", hPw, si, p4?60:88), NumPut("Ptr", hPw, si, p4?64:96) ; set stdOut / stdErr handle for process
        
        If DllCall("CreateProcess", "Ptr", 0, "Ptr", bCmd.ptr, "Uint", 0, "Uint", 0, "Int", true, "Uint", 0x10
                    , "Uint", 0, "Ptr", WorkingDir ? bWD.ptr : 0, "Ptr", si.ptr, "Ptr", pi.ptr) {
            pID := NumGet(pi, p*2, "UInt"), tID := NumGet(pi, (p*2)+4, "UInt") ; pID, tID, hProc, hThread = process/thread handles and IDs
            hProc := NumGet(pi,0,"UPtr"), hThread := NumGet(pi,p,"UPtr")
            f := FileOpen(hPr, "h", Codepage) ; create file object for StdOut
            While DllCall("GetExitCodeProcess", "Ptr",hProc, "Ptr*",ExitCode:=0) { ; check if thread still active
                output .= f.Read()
                If (ExitCode != 259 And f.AtEOF)
                    Break ; if not STILL_ACTIVE, then break
            }
        }
        c := "CloseHandle"
        DllCall(c, "Ptr", hPw), DllCall(c, "Ptr", hPr), DllCall(c, "Ptr", hProc), DllCall(c, "Ptr", hThread)
        return Trim(output," `r`n`t")
    }
}