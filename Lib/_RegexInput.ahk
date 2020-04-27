Global OpenLabel, regexGui

guiAddRegex(label:="") {
	regexGui := GuiCreate("+Owner" oGui.hwnd,"Add Parallel Entry")
	regexGui.OnEvent("close","regex_close")
	regexGui.OnEvent("escape","regex_close")
	
	regexGui.AddText("y8 w40 Right","Label:")
	ctl := regexGui.AddEdit("vRegexLabel x+2 yp-4 w400")
	If (label)
		ctl.Value := label
	
	regexGui.AddText("xm y+10 w40 Right","Regex:")
	ctl := regexGui.AddEdit("vRegexString x+2 yp-4 w400")
	If (label)
		ctl.Value := regexList[label]["regex"]
	ctl.SetFont("s10","Courier New")
	
	regexGui.AddText("xm y+10 w40 Right","EXE:")
	ctl := regexGui.AddEdit("vRegexExe x+2 yp-4 w375")
	If (label)
		ctl.Value := regexList[label]["exe"]
	
	regexGui.AddButton("vSelectExe x+0","...").OnEvent("click","regex_events")
	
	regexGui.AddButton("vRegexSave y+20 x+-100 w50","Save").OnEvent("click","regex_events")
	regexGui.AddButton("vRegexCancel x+0 w50","Cancel").OnEvent("click","regex_events")
	
	regexGui.Show()
	If (label)
		OpenLabel := label
	
	oGui.Opt("+Disabled")
}

regex_close(o) {
	oGui.Opt("-Disabled"), OpenLabel := ""
	o.Destroy(), regexGui := ""
}

regex_edit(ctl,info) {
	r := ctl.GetNext(), label := ctl.GetText(r)
	guiAddRegex(label)
}

regex_events(ctl,info) {
	g := ctl.gui
	If (ctl.Name = "RegexSave") {
		curLabel := g["RegexLabel"].Value
		curRegex := g["RegexString"].Value
		curExe := g["RegexExe"].Value
		
		If (curLabel And curRegex And FileExist(curExe)) {
			If (OpenLabel)
				regexList.Delete(OpenLabel), OpenLabel := ""
			
			newObj := Map("regex",curRegex,"exe",curExe)
			regexList[curLabel] := newObj, newObj := ""
			
			regexRelist()
			
			oGui.Opt("-Disabled")
			g.Destroy(), regexGui := ""
		} Else
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
	LV := oGui["AhkParallelList"] ; ListViewObject
	LV.Delete()
	
	For label, obj in regexList
		regex := obj["regex"], LV.Add("",label,regex)
	obj := ""
}