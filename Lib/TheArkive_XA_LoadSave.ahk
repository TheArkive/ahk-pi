; =============================================================
; XA_Save(Array,BaseName := "Base")		>>> dumps XML text from associative array var
; XA_Load(XMLText)						>>> converts XML text to associative array
;		Originally posted by trueski
;		https://autohotkey.com/board/topic/85461-ahk-l-saveload-arrays/
;		Modified for AHKv2 by TheArkive
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Root node by default is called "Base".  It doesn't matter because it isn't
; used and is not part of the array after using XA_Load().
;
; User must choose how to handle output, ie.
;		1) Save XML to file after ... var := XA_Save()
;		2) Load XML text from file before converting with ... myArray := XA_Load()
; =============================================================
XA_Save(Array,BaseName := "Base") { ; XA_Save(Array, Path)
	outVar := "<?xml version=" Chr(34) "1.0" Chr(34) " encoding=" Chr(34) "UTF-8" Chr(34) "?>`n<" BaseName ">`n" . XA_ArrayToXML(Array) . "`n</" BaseName ">"
	return OutVar
}
XA_Load(XMLText) { ; orig param was ... XA_Load(Path) ... Path = XML file location
	Local XMLObj, XMLRoot, Root1, Root2 ; XMLText
	
	XMLObj    := XA_LoadXML(XMLText)
	XMLObj    := XMLObj.selectSingleNode("/*")
	If (IsObject(XMLObj)) { ; check if settings are blank
		XMLRoot   := XMLObj.nodeName
		outputArray := XA_XMLToArray(XMLObj.childNodes)
		return outputArray
	} Else
		return Map() ; if settings are blank return a blank Map()
}
XA_XMLToArray(nodes, NodeName:="") {
	If (VarSetCapacity(Obj) = 0)
		Obj := Map() ; AHKv2
		; Obj := {} ; AHKv1
	
	for node in nodes {
		if (node.nodeName != "#text") { ;NAME
			If (node.nodeName == "Invalid_Name" && node.getAttribute("ahk") == "True")
				NodeName := node.getAttribute("id")
			Else
				NodeName := node.nodeName
		} else { ;VALUE
			Obj := node.nodeValue
		}
		
		if node.hasChildNodes {
			Try {
				prevSib := node.previousSibling.nodeName
			} catch e {
				prevSib := ""
			}
			
			Try {
				nextSib := node.nextSibling.nodeName
			} catch e {
				nextSib := ""
			}
			
			If ((nextSib = node.nodeName || node.nodeName = prevSib) && node.nodeName != "Invalid_Name" && node.getAttribute("ahk") != "True") { ;Same node name was used for multiple nodes
				If (!prevSib) { ;Create object - previous -> !node.previousSibling.nodeName
					Obj[NodeName] := Map() ; AHKv2
					; Obj[NodeName] := {} ; AHKv1   or   Object()
					ItemCount := 0
				}
			  
				ItemCount++
			  
				If (node.getAttribute("id") != "") ;Use the supplied ID if available
					Obj[NodeName][node.getAttribute("id")] := XA_XMLToArray(node.childNodes, node.getAttribute("id"))
				Else ;Use ItemCount if no ID was provided
					Obj[NodeName][ItemCount] := XA_XMLToArray(node.childNodes, ItemCount)
			} Else {
				Obj[NodeName] := XA_XMLToArray(node.childNodes, NodeName)
			}
		}
	}
	
	return Obj
}
XA_LoadXML(ByRef data){
	o := ComObjCreate("MSXML2.DOMDocument.6.0")
	o.async := false
	o.LoadXML(data)
	return o
}
XA_ArrayToXML(theArray, tabCount:=1, NodeName:="") {     
    Local tabSpace, extraTabSpace, tag, val, theXML, root
	tabCount++
    tabSpace := "" 
    extraTabSpace := "" 
	
	if (!IsObject(theArray)) {
		root := theArray
		theArray := %theArray%
    }
	
	While (A_Index < tabCount) {
		tabSpace .= "`t" 
		extraTabSpace := tabSpace . "`t"
    } 
     
	for tag, val in theArray {
        If (!IsObject(val)) {
			If (XA_InvalidTag(tag))
				theXML .= "`n" . tabSpace . "<Invalid_Name id=" Chr(34) . XA_XMLEncode(tag) . Chr(34) " ahk=" Chr(34) "True" Chr(34) ">" . XA_XMLEncode(val) . "</Invalid_Name>"
			Else
				theXML .= "`n" . tabSpace . "<" . tag . ">" . XA_XMLEncode(val) . "</" . tag . ">"
		} Else {
			If (XA_InvalidTag(tag))
				theXML .= "`n" . tabSpace . "<Invalid_Name id=" Chr(34) . XA_XMLEncode(tag) . Chr(34) " ahk=" Chr(34) "True" Chr(34) ">" . "`n" . XA_ArrayToXML(val, tabCount, "") . "`n" . tabSpace . "</Invalid_Name>"
			Else
				theXML .= "`n" . tabSpace . "<" . tag . ">" . "`n" . XA_ArrayToXML(val, tabCount, "") . "`n" . tabSpace . "</" . tag . ">"
	    }
    } 
	
	theXML := SubStr(theXML, 2)
	Return theXML
} 
XA_InvalidTag(Tag) {
	Char1      := SubStr(Tag, 1, 1) 
	Chars3     := SubStr(Tag, 1, 3)
	StartChars := "~``!@#$%^&*()_-+={[}]|\:;" Chr(34) Chr(34) "'<,>.?/1234567890 	`n`r"
	Chars := Chr(34) Chr(34) "'<>=/ 	`n`r"
	
	Loop Parse StartChars
	{
		If (Char1 = A_LoopField)
		  Return 1
	}
	
	Loop Parse Chars
	{
		If (InStr(Tag, A_LoopField))
			Return 1
	}
	
	If (Chars3 = "xml")
		Return 1
	Else
		Return 0
}
XA_XMLEncode(Text) {
	Text := StrReplace(Text,"&","&")
	Text := StrReplace(Text,"<","<")
	Text := StrReplace(Text,">",">")
	Text := StrReplace(Text,Chr(34),Chr(34))
	Text := StrReplace(Text,"'","'")
	
	Return Text
}