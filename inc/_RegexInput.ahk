Global OpenLabel := "", regexGui := ""

guiAddRegex(label:="") {
    Global regexGui, OpenLabel, Settings
	regexGui := Gui("-DPIScale +Owner" oGui.hwnd,"Add Parallel Entry")
	regexGui.OnEvent("close",regex_close)
	regexGui.OnEvent("escape",regex_close)
	
	regexGui.Add("Text","y8 w70 Right","Label:")
	ctl := regexGui.Add("Edit","vRegexLabel x+2 yp-4 w150")
	If (label)
		ctl.Value := label
	
	regexGui.Add("Text","x+60 yp+4","Match Type:")
	ctl := regexGui.Add("DropDownList","vMatchType x+2 yp-4 w70",["Regex","Exact"])
	If (label)
		ctl.Value := regexList[label]["type"]
	
	regexGui.Add("Text","xm y+10 w70 Right","Match String:")
	ctl := regexGui.Add("Edit","vRegexString x+2 yp-4 w370")
	If (label)
		ctl.Value := regexList[label]["regex"]
	ctl.SetFont("s10","Courier New")
	
	regexGui.Add("Text","xm y+10 w70 Right","EXE:")
	ctl := regexGui.Add("Edit","vRegexExe x+2 yp-4 w345")
	If (label)
		ctl.Value := regexList[label]["exe"]
	
	regexGui.Add("Button","vSelectExe x+0","...").OnEvent("click",regex_events)
	
	regexGui.Add("Button","vRegexSave y+20 x+-100 w50","Save").OnEvent("click",regex_events)
	regexGui.Add("Button","vRegexCancel x+0 w50","Cancel").OnEvent("click",regex_events)
    
    If !Settings["PortableMode"]
        ctl := regexGui.Add("Text","xm yp+4","Don't forget to close the program for changes to take effect!")
	
	regexGui.Show()
	If (label)
		OpenLabel := label
	
	oGui.Opt("+Disabled")
}

regex_close(o) {
    Global regexGui, OpenLabel
	oGui.Opt("-Disabled"), OpenLabel := ""
	o.Destroy(), regexGui := ""
}

regex_edit(ctl,info) {
	r := ctl.GetNext(), label := ctl.GetText(r)
	guiAddRegex(label)
}

regex_events(ctl,info) {
    Global Settings, regexGui, OpenLabel, regexList
	g := ctl.gui
	If (ctl.Name = "RegexSave") {
		curLabel := g["RegexLabel"].Value
		curRegex := g["RegexString"].Value
		MatchType := g["MatchType"].Value
		curExe := g["RegexExe"].Value
		
		If (curLabel And curRegex And FileExist(curExe) And MatchType) {
			If (OpenLabel)
				regexList.Delete(OpenLabel), OpenLabel := ""
			
			newObj := Map("regex",curRegex,"exe",curExe,"type",MatchType)
			regexList[curLabel] := newObj, newObj := ""
			
            Settings["regexList"] := regexList
			
            LstV := oGui["AhkParallelList"]
            LstV.Modify(LstV.GetNext(), "Col2", curRegex)
			
			oGui.Opt("-Disabled")
			g.Destroy(), regexGui := ""
		} Else If (!FileExist(curExe))
			MsgBox "The specified EXE does not exist."
		Else
			Msgbox "Fill out all values, or click Cancel."
	} Else If (ctl.Name = "RegexCancel") {
		oGui.Opt("-Disabled"), OpenLabel := ""
		g.Destroy(), regexGui := ""
	} Else If (ctl.Name = "SelectExe") {
		baseFldr := Settings.Has("BaseFolder") ? Settings["BaseFolder"] : ""
		If (!baseFldr) {
			Msgbox "Set the Base Folder first."
			g.Destroy(), regexGui := ""
		} Else {
			regExe := FileSelect("",baseFldr,"Select AutoHotkey EXE:","Executable (*.exe)")
			If (regExe)
				g["RegexExe"].Value := regExe
		}
	}
}

regexRelist() {
    Global regexList
	LstV := oGui["AhkParallelList"]
	; ======================================
    ; old
    ; ======================================
    LstV.Delete()
	
	For label, obj in regexList
		regex := obj["regex"], LstV.Add("",label,regex)
	obj := ""
    ; ======================================
    ; new
    ; ======================================
    
    
}