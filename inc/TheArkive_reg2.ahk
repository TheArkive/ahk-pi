; ======================================================================================
; Reg class - wrapper for the REG command.
; ======================================================================================
; This was made to attempt making a wider set of functionality for interacting with the
; registry feel more "native" to AutoHotkey.  Also, less errors are thrown, for example
; when trying to read the (Default) value of a key, you will get "" if the data of the
; (Default) value is a zero-length string, or is unset.  But you can still check if the
; value is actually unset.  Read more below.
;
; Much of this class mirrors what AHK already does with registry related commands and
; functions, and of course adds to it.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Methods
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;   reg.query(key, value := "", recurse := false)
;
;       - Similar to the REG QUERY command.
;
;       - If recurse = false, specify only a key to query all values, as well as a list
;         of keys (and their default values) in the specified key.  If you also specifify
;         a value, then only that value's data is returned.
;
;       - If recurse = true, specify only a key to query all values in all subkeys.  If
;         you also specify a value, then all instaces of that value in all subkeys is
;         queried.
;
;       - Output is a Map(), listing the key queried, and all subkeys.
;
;       - If value = "", that queries the (Default) value of a key/subkey.
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
;               -> Returns a Map() of all instances of "My_value" in the specified key and subkeys.
;
;         + Getting data from an array after using reg.query()
;
;                my_data := arr["HKLM\sub_key"]["value"]["data"]
;           my_data_type := arr["HKLM\sub_key"]["value"]["data_type"]
;  (boolean) check_unset := arr["HKLM\sub_key"]["value"]["unset"]       ; only true when (Default) value is unset.
;
;            - ["unset"] will indicate if the return value of "" is zero-length or actually unset.
;
;   reg.add(key, value := "", data := "", rgType := "REG_SZ")
;
;       - Specify only a key, to add a registry key with the (Default) value unset.
;
;       - Specify a key and value, to write data to that value.
;
;       - The default data type is REG_SZ.
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
;                  with no data (a zero-length string).
;
;           boolean := reg.add("HKCU\Software\my_key","my_value","some_data")
;
;               -> Attempts to add "my_value" to the registry key "HKCU\Software\my_key"
;                  with the string "some_data" as the string value.
;
;           boolean := reg.add("HKCU\Software\my_key","my_value","some_data`r`n more_data","REG_MULTI_SZ")
;
;               -> Attempts to add "my_value" to the registry key "HKCU\Software\my_key" with the
;                  string "some_data" as the data.  The data type "REG_MULTI_SZ" is specified.
;                  The default delimiter for REG_MULTI_SZ input is "`n" or "`r`n".
;
;   reg.delete(key, value := "", clearKey := false)
;
;       - Specify only a key to delete that key.
;
;       - Specify a key and value to delete the value.
;
;       - If clearKey = true, then the specified key's values are cleared.  All subkeys and
;         values in those subkeys are not touched.  If value is specified in this case, it
;         is ignored.
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
;         the .reg file if it exists in the destination directory.
;
;   reg.import(file)
;
;       - Imports the specified .reg file.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Properties
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;   reg.view
;
;       - Default value = ""
;       - Other values = 32 or 64
;       - Specifies whether to look at the 32 or 64 bit side of the registry.  Changing
;         this value to 32 or 64 will invoke SetRegView.  Reading this value will return
;         the current contents of A_RegView, however if the current reg view is "Default"
;         then the returned value will be "".
;       - If the user attempts to apply any other value besides 32, 64, or "", then ""
;         is automatically applied (which is the same as "Default" for SetRegView).
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;       The .reason, .LastError, and .cmd properties are reset when a method() is called.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;   reg.reason
;
;       - Contains text describing error message.  On no error, this value is blank.
;
;   reg.LastError
;
;       - Contains A_LastError code, or the most appropriate equivalent value.  A value of
;         zero indicates success.
;
;   reg.cmd
;
;       - Contains the full command line passed to RunWait() in case you want to double check it.
;
;   Usage Examples:
;
;       cur_reg_view := reg.view ; gets the current reg view
;
;       reg.view  := new_regView ; sets the new reg view (32, 64, or "")
;
;       error_reason := reg.reason ; gets error message, when reg.method() returns false.
;
;       err_code := reg.LastError
;
; ======================================================================================
; EXAMPLES
; ======================================================================================
;
; #INCLUDE _JXON.ahk ; https://www.autohotkey.com/boards/viewtopic.php?f=83&t=74799
; test := jxon_dump(reg.query("HKCR\*","AttributeMask",true),4) ; gets all data from values named "AttributeMask" in HKCR\* (recursive)
; A_Clipboard := test
; msgbox test
;
; ======================================================================================
;
; #INCLUDE _JXON.ahk ; https://www.autohotkey.com/boards/viewtopic.php?f=83&t=74799
; test := jxon_dump(reg.query("HKCR\*","",true),4) ; gets all (Default) values from all subkeys (recursive)
; A_Clipboard := test
; msgbox test
;
; ======================================================================================
;
; #INCLUDE _JXON.ahk ; https://www.autohotkey.com/boards/viewtopic.php?f=83&t=74799
; test := jxon_dump(reg.query("HKCR\*",""),4) ; gets all (Default) values from specified key and 1st level subkeys (not recursive)
; A_Clipboard := test
; msgbox test
;
; ======================================================================================
;
; output_array := reg.query("HKEY_CLASSES_ROOT\*") ; looping through array returned by reg.query()
; msg_txt := ""
; For key, key_contents in output_array { ; looping through reg.query() output in a FOR loop
    ; msg_txt .= key "`r`n"
    ; For value, val_info in key_contents {
        ; msg_txt .= "    VALUE:  " value " (TYPE: " val_info["type"] ")`r`n"
        ; msg_txt .= "        DATA: " (val_info["unset"] ? "(value not set)" : val_info["data"]) "`r`n"
    ; }
; }
; msgbox msg_txt
;
; ======================================================================================
;
; test := reg.read("HKCU\*","") ; reads default value of key "HKCR\*" and doesn't throw an error
; msgbox "default value: " test "`r`nunset?  " (reg.unset ? "yes" : "no") ; check reg.unset for determining if a (Default) value is unset
;
; ======================================================================================
;
; reg.add("HKCU\Software\AutoHotkey\test1\test2")                       ; adds only a key
; reg.add("HKCU\Software\AutoHotkey\test1\test2","test3")               ; adds a blank value named "test3"
; reg.add("HKCU\Software\AutoHotkey\test1\test2","test3","value data")  ; adds value "test3" set to "value data"
;
; ======================================================================================
;
; reg.add("HKCU\Software\AutoHotkey\test1\test2\test3","","test")     ; add a simple test key with (Default) value data set
; reg.add("HKCU\Software\AutoHotkey\test1\test2\test3","test_value","data for test value") ; add test value
; Msgbox "test key, test value, and (Default) data set"
; reg.delete("HKCU\Software\AutoHotkey\test1\test2\test3","")         ; clears default value of test key
; msgbox "default value of test key cleared"
; reg.add("HKCU\Software\AutoHotkey\test1\test2\test3","test_value")  ; overwrite test_value with zero-length string
; msgbox "overwrites test value with zero-length string"
; reg.delete("HKCU\Software\AutoHotkey\test1\test2\test3","test_value") ; removes test_value
; msgbox "test value removed"
; reg.delete("HKCU\Software\AutoHotkey\test1")                        ; remove the key
; msgbox "test key removed"
;
; ======================================================================================
;
; msgbox "adding dummy test values"
; reg.add("HKCU\Software\AutoHotkey","","test")
; reg.add("HKCU\Software\AutoHotkey","poof1","test1")
; reg.add("HKCU\Software\AutoHotkey","poof2","test2")
; msgbox "now .delete() and set clearKey = true"
; reg.delete("HKCU\Software\AutoHotkey",,true)
; msgbox "now refresh the registry/RegEdit.  All test values should be cleared."
;
; ======================================================================================
;
; msgbox "WARNING:  Please move through this example SLOWLY."
; msgbox "EXPORTING`r`n`r`nzero means success: " reg.export("HKCU\Software\AutoHotkey","HKCU-Ahk-registry.reg") ; exports HKCR\* to a .reg file
; msgbox "reg hive exported`r`n`r`nCheck exported file contents if you wish.`r`n`r`nRename AutoHotkey in HKCU\Software to AutoHotkey2 now for this test"
; msgbox "IMPORTING`r`n`r`nzero means success: " reg.import("HKCU-Ahk-registry.reg") "`r`n`r`nManuall refresh registry/RegEdit now (F5)."
; msgbox "registry import done`r`n`r`nIt is safe to delete AutoHotkey2 key now."
; FileDelete "HKCU-Ahk-registry.reg"
; msgbox "test reg file deleted"
;
; ======================================================================================
; Examples testing error messages.
; ======================================================================================
;
; msgbox reg.read("HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\NetDrivers","") ; should be restricted
; msgbox "Error info: " reg.LastError " / " reg.reason "`r`n`r`nActual last error: " A_LastError
;
; msgbox reg.export("HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\NetDrivers","test.reg") ; should be restricted
; msgbox "Error info: " reg.LastError " / " reg.reason "`r`n`r`nActual last error: " A_LastError
;
; msgbox reg.add("HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\NetDrivers","","test data") ; should be restricted
; msgbox "Error info: " reg.LastError " / " reg.reason "`r`n`r`nActual last error: " A_LastError
;
; msgbox reg.delete("HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\NetDrivers","") ; should be restricted
; msgbox "Error info: " reg.LastError " / " reg.reason "`r`n`r`nActual last error: " A_LastError
;
; ======================================================================================
; The following .reg file contents should fail, this key should be restricted.
; Copy below contents to a error_test.reg file and place it in the same folder as
; this script.  Attempt to import with commands below to see error codes/messages.
; If for some reason you have access to this key, it is recommended you remove the
; default value from the specified key below.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Windows Registry Editor Version 5.00
;
; [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\NetDrivers]
; @="testing"
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; msgbox reg.import("error_test.reg")
; msgbox "Error info: " reg.LastError " / " reg.reason "`r`n`r`nActual last error: " A_LastError
; RegDelete "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\NetDrivers" ; ONLY run this if for some reason the above commands
;                                                                        ; actually write to this key's default value.
;
; ======================================================================================
;
; msgbox "result: " reg.export("HKCU\Software\AutoHotkey","overwrite_test.reg") ; overwrite test
; msgbox "should fail: " reg.export("HKCU\Software\AutoHotkey","overwrite_test.reg",false) ; should fail
; FileDelete "overwrite_test.reg" ; clean up test file
;
; ======================================================================================

class reg {
    Static null := Chr(3), cmd := "", unset := false, reason := "", LastError := 0
    
    Static query(key, value := "", recurse := false) { ; REG QUERY simulated
        this.unset := false, this.LastError := 0, this.result := "", this.cmd := ""
        If (this.access_test(key)) ; test for access denied - this is very appropriate here
            return this.LastError
        
        output := Map(), output.CaseSense := false, readValue := true                   ; init base array
        If (value = "") {                                                           ; only append first default value if (value = "")
            d := Map(), d.CaseSense := false, d["data"] := "", d["type"] := "REG_SZ"    ; init default value for base key
            Try d["data"] := RegRead(key,"")                                            ; try to look up first default key
            d["unset"] := (A_LastError = 2) ? true : false                              ; check if first default value is unset
            output[this.ExpandRoot(key)] := Map("(Default)",d)                          ; write first default value
        }
        
        Loop Reg key, (recurse ? "VKR" : "VK")
        {
            k := A_LoopRegKey, v := A_LoopRegName, t := A_LoopRegType, m := A_LoopRegTimeModified
            (t = "KEY") ? (k := k "\" v, v := "", t := "REG_SZ") : ""
            readValue := (value = this.null) ? true : (value = v) ? true : false ; read value based on params/filters
            
            If (readValue) {
                If !output.Has(k)
                    n := Map(), n.CaseSense := false, output[k] := n
                d := Map(), d.CaseSense := false, d["data"] := "", d["type"] := t
                Try d["data"] := RegRead(k,v)
                d["unset"] := (A_LastError = 2) ? true : false
                output[k][!v ? "(Default)" : v] := d
            }
        }
        this.LastError := 0, this.reason := ""
        return output
    }
    Static read(key, value := "") {
        result := "", this.cmd := ""
        Try result := RegRead(key,value)
        this.LastError := A_LastError
        this.reason := this.validate_error(A_LastError)
        this.unset := (this.LastError = 2) ? true : false
        return result
    }
    Static add(key, value := "", data := "", rgType := "REG_SZ") {
        this.unset := false, this.LastError := 0, this.result := "", this.cmd := ""
        If (value = this.null And data = "") {  ; write a blank vlaue
            Try RegWrite data, rgType, key
            If !A_LastError
                Try RegDelete key
        } Else                                  ; write a value
            Try RegWrite data, rgType, key, value
        this.reason := this.validate_error(A_LastError), this.LastError := A_LastError
        return this.LastError
    }
    Static delete(key, value := "", clearKey := false) {
        this.unset := false, this.LastError := 0, this.result := "", this.cmd := "", curValue := ""
        If (value = this.null And !clearKey) {
            Try RegDeleteKey key
        } Else If (value = this.null And clearKey) {
            Loop Reg key
            {
                curValue := A_LoopRegName
                Try RegDelete A_LoopRegKey, A_LoopRegName
                If A_LastError
                    Break
            }
            If !A_LastError
                curValue := ""
        } Else
            Try RegDelete key, value
        
        this.reason := this.validate_error(A_LastError) (curValue ? "`r`n`r`n   Key: " key "`r`nValue:  " curValue : "")
        this.LastError := A_LastError
        return this.LastError
    }
    Static export(key, file := "", overwrite := true) {
        this.unset := false, this.LastError := 0, this.result := "", this.cmd := ""
        If (this.access_test(key)) ; test for access denied
            return this.LastError
        
        SplitPath key, &endKey, &pathKey
        file := (file="") ? endKey ".reg" : file   ; default file name is key name
        file := (SubStr(file,-4) != ".reg") ? file ".reg" : file
        v := this.validateFileName(file)    ; validate provided file/path
        
        If (!v) {
            this.reason := "Invalid Filename", this.LastError := 1
        } Else If (!overwrite And FileExist(file))
            this.reason := "File exists, no overwrite", this.LastError := 1
        Else {
            r := (this.view = 32) ? " /reg:32" : (this.view = 64) ? " /reg:64" : ""
            o := (overwrite ? " /y" : "")       ; check for overwrite, adjust command line
            this.cmd := "reg export " key " " Chr(34) file  Chr(34) o r
            result := RunWait(this.cmd)
            If A_LastError
                this.reason := this.validate_error(A_LastError), this.LastError := A_LastError
            Else If result
                this.reason := "Key may not exist", this.LastError := 1
        }
        return this.LastError
    }
    Static import(file, key := "") { ; specify key if you want to test for access first
        this.unset := false, this.LastError := 0, this.result := "", this.cmd := ""
        If (key And this.access_test(key))  ; test for access denied
            return this.LastError
        
        v := this.validateFileName(file)    ; validate provided file/path
        r := (this.view = 32) ? " /reg:32" : (this.view = 64) ? " /reg:64" : ""
        
        If !v
            this.LastError := 1, this.reason := "Invalid file name."
        if FileExist(file) {
            this.cmd := "reg import " Chr(34) file Chr(34) r
            result := RunWait(this.cmd)
            If A_LastError
                this.reason := this.validate_error(A_LastError), this.LastError := A_LastError
            Else If result
                this.reason := "Key may not exist, or access is denied", this.LastError := 1
        } Else
            this.LastError := 1, this.reason := "File does not exist."
        
        return this.LastError
    }
    Static access_test(key) {
        Try test := RegRead(key,"")
        If (A_LastError = 5) {                                                          ; test for access rights / access denied
            this.LastError := A_LastError, this.reason := this.validate_error(A_LastError)
            return this.LastError
        } Else
            return 0
    }
    Static validate_error(errNum) {
        If (errNum = 1)
            result := "General failure.  Key/value/file may not exist, or may not be invalid."
        Else If (errNum = 2)
            result := "File not found"
        Else if (errNum = 5)
            result := "Access Denied"
        Else
            result := errNum
        
        return result
    }
    Static validateFileName(inPath) {
        If !inPath
            return false
        SplitPath inPath, &outFile, &outDir
        result := (outDir ? FileExist(outDir) : true), invalidChars := "><:/\|?*" Chr(34)
        Loop Parse invalidChars
            result := !result ? false : !InStr(outFile, A_LoopField)
        return result
    }
    Static ExpandRoot(key) {
        key := RegExReplace(key,"i)^HKCR\\","HKEY_CLASSES_ROOT\",,1) , key := RegExReplace(key,"i)^HKCU\\","HKEY_CURRENT_USER\",,1)
        key := RegExReplace(key,"i)^HKLM\\","HKEY_LOCAL_MACHINE\",,1), key := RegExReplace(key,"i)^HKU\\" ,"HKEY_USERS\",,1)
        key := RegExReplace(key,"i)^HKCC\\","HKEY_CURRENT_CONFIG",,1), key := RegExReplace(key,"i)^HKPD\\","HKEY_PERFORMANCE_DATA",,1)
        return key
    }
    Static CollapseRoot(key) {
        key := RegExReplace(key,"i)^HKEY_CLASSES_ROOT\\","HKCR\",,1)  , key := RegExReplace(key,"i)^HKEY_CURRENT_USER\\","HKCU\",,1)
        key := RegExReplace(key,"i)^HKEY_LOCAL_MACHINE\\","HKLM\",,1) , key := RegExReplace(key,"i)^HKEY_USERS\\","HKU\",,1)
        key := RegExReplace(key,"i)^HKEY_CURRENT_CONFIG\\","HKCC\",,1), key := RegExReplace(key,"i)^HKEY_PERFORMANCE_DATA\\","HKPD\",,1)
        return key
    }
    Static view { ; handle reg view natively with AHK
        Set {
            SetRegView ((value = 32 Or value = 64) ? value : "Default" )
        }
        Get {
            return ((A_RegView = "Default") ? "" : A_RegView)
        }
    }
}