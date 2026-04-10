#SingleInstance,Force
global CurrentWsNode, CurrentWinNode, LastWsRow, LastWinRow, HotkeyTargetNode, HotkeyHwndCtrl
global settings:=new xml("settings")
global Version:="2.0"
IconPath := A_ScriptDir "\assets\workspaces.ico"
if(FileExist(IconPath))
	Menu,Tray,Icon,%IconPath%
Gui()
return
show:
WinShow,% hwnd([1])
WinActivate,% hwnd([1])
return
GuiClose:
	WinGet,max,minmax,% hwnd([1])
	if max=0
		WinHide,% hwnd([1])
	if (max=""){
		WinShow,% hwnd([1])
		WinActivate,% hwnd([1])
	}
return
Gui(){
	static wslv, winlv, wintv, wssearch
	SetTitleMatchMode,2
	Gui,+hwndhwnd
	hwnd(1,hwnd)
	BuildSettingsMenu()
	Hotkey,IfWinActive,% hwnd([1])
	Hotkey,Delete,Delete,On
	Hotkey,^down,movedown,On
	Hotkey,^up,moveup,On
	Hotkey,~Enter,Enter,On
	Hotkey,~NumpadEnter,Enter,On
	Hotkey,Tab,TabForward,On
	Hotkey,+Tab,TabBackward,On
	Hotkey,+Escape,keyExit,On
	Gui,Font,s9,Segoe UI
	; Left pane - search + workspace list
	Gui,Add,Edit,x10 y10 w250 vWsSearch gWsSearchUpdate hwndwssearch
	Gui,Add,ListView,x10 y+5 w250 h370 AltSubmit gWsListEvent hwndwslv +Grid,Workspace|Hotkey
	Gui,Add,Button,x10 y+5 w250 gcreateworkspace,&Create Workspace
	; Middle pane - window list
	Gui,Add,ListView,x270 y10 w250 h398 AltSubmit gWinListEvent hwndwinlv,Window
	Gui,Add,Button,x270 y+5 gcapture,&Add Windows
	Gui,Add,Button,x+5 gupdatepos,&Update Positions
	; Right pane - window settings tree + buttons
	Gui,Add,TreeView,x530 y10 w350 h398 AltSubmit gWinTvEvent hwndwintv
	Gui,Add,Button,x530 y+5 ghelp,&Help
	hwnd("wslv",wslv),hwnd("winlv",winlv),hwnd("wintv",wintv),hwnd("wssearch",wssearch)
	DllCall("SendMessage","Ptr",wssearch,"UInt",0x1501,"Int",1,"WStr","Search workspaces...")
	StyleListViewHeaders()
	Gui,Show,w890,Workspaces %Version%
	PopulateGroups()
	OnExit,Exit
	Menu,Tray,NoStandard
	Menu,Tray,Add,Show Workspaces,show
	Menu,Tray,Default,Show Workspaces
	Menu,Tray,Standard
	if win:=settings.ssn("//windows")
		win.ParentNode.RemoveChild(win)
}
BuildSettingsMenu(){
	top:=settings.ssn("//Settings")
	if !top
		top:=settings.Add({path:"Settings",att:{name:"Settings"}})
	for a,b in ["Hide/Show GUI","Toggle Current Workspace","Workspace Launcher"]
		if !XPathNode(top,"setting[@name='" b "']"){
			newset:=settings.under({under:top,node:"setting",att:{name:b}})
			if(b="Workspace Launcher")
				newset.SetAttribute("hotkey","^!Space")
		}
	try Menu,SettingsMenu,DeleteAll
	try Menu,MainMenuBar,DeleteAll
	slist:=settings.sn("//Settings/setting")
	while,ss:=slist.item[A_Index-1]{
		ea:=xml.ea(ss)
		hktext:=ea.hotkey?"`t" ea.hotkey:""
		Menu,SettingsMenu,Add,% ea.name hktext,MenuSettingAction
	}
	Menu,SettingsMenu,Add
	Menu,SettingsMenu,Add,Edit Hotkeys...,EditSettingsHotkeys
	Menu,SettingsMenu,Add
	Menu,SettingsMenu,Add,About...,AboutWorkspaces
	Menu,MainMenuBar,Add,Settings,:SettingsMenu
	Gui,1:Menu,MainMenuBar
}
MenuSettingAction:
	name:=RegExReplace(A_ThisMenuItem,"\t.*$","")
	node:=settings.ssn("//Settings/setting[@name='" name "']")
	if !node
		return
	ea:=xml.ea(node)
	if(ea.name="Hide/Show GUI"){
		GoSub,GuiClose
	}else if(ea.name="Toggle Current Workspace"){
		current:=settings.ssn("//workspace[@current]")
		if !current
			settings.ssn("//workspace").SetAttribute("current",1)
		else{
			if(next:=current.nextsibling){
				current.RemoveAttribute("current")
				next.SetAttribute("current",1)
			}else{
				current.RemoveAttribute("current")
				settings.ssn("//workspace").SetAttribute("current",1)
			}
		}
		current:=settings.ssn("//workspace[@current]")
		Restore(XPathNodes(current,"descendant::window"),1,1)
	}else if(ea.name="Workspace Launcher"){
		ShowLauncher()
	}
return
EditSettingsHotkeys:
	Gui,4:Destroy
	Gui,4:Default
	Gui,4:Font,s10,Segoe UI
	Gui,4:Add,Text,,Double-click a setting to edit its hotkey:
	Gui,4:Add,ListView,w350 h120 gSettingLvEvent AltSubmit,Setting|Hotkey
	Gui,4:ListView,SysListView321
	slist:=settings.sn("//Settings/setting")
	while,ss:=slist.item[A_Index-1]{
		ea:=xml.ea(ss)
		LV_Add("",ea.name,ea.hotkey?ea.hotkey:"(none)")
	}
	LV_ModifyCol(1,"AutoHdr")
	LV_ModifyCol(2,"AutoHdr")
	Gui,4:Show,,Edit Settings Hotkeys
return
4GuiEscape:
4GuiClose:
	Gui,4:Destroy
return
SettingLvEvent:
	if(A_GuiEvent="DoubleClick"){
		row:=A_EventInfo
		if !row
			return
		Gui,4:Default
		Gui,4:ListView,SysListView321
		LV_GetText(sname,row,1)
		Gui,4:Destroy
		node:=settings.ssn("//Settings/setting[@name='" sname "']")
		if node
			EditHotkey(node)
	}
return
AboutWorkspaces:
	Gui,5:Destroy
	Gui,5:Font,s12 Bold,Segoe UI
	Gui,5:Add,Text,,Workspaces v%Version%
	Gui,5:Font,s9 Norm,Segoe UI
	Gui,5:Add,Text,y+10,Originally created by maestrith.
	Gui,5:Add,Text,,Updated to v2.0 (workspace launcher and 3-pane GUI)`nby capeably with the help of a friend named Claude.
	Gui,5:Font,s9 Underline cBlue,Segoe UI
	Gui,5:Add,Text,y+15 gAboutOpenRepo,github.com/capeably/AutoHotkey-Scripts
	Gui,5:Font,s9 Norm c000000,Segoe UI
	Gui,5:Add,Button,y+15 w80 g5GuiClose Default,OK
	Gui,5:Show,,About Workspaces
return
AboutOpenRepo:
	Run,https://github.com/capeably/AutoHotkey-Scripts/tree/master/AHK-Workspaces
return
5GuiEscape:
5GuiClose:
	Gui,5:Destroy
return
; ========== Left Pane Event Handlers ==========
WsListEvent:
	Gui,1:Default
	Gui,1:ListView,% hwnd("wslv")
	if(A_GuiEvent="DoubleClick"){
		row:=A_EventInfo
		if row
			WsDoubleClick(row)
		return
	}
	row:=LV_GetNext()
	if(row>0&&row!=LastWsRow){
		LastWsRow:=row
		; Save expand state of current window settings before switching
		SaveWindowSettingsState()
		LV_GetText(name,row,1)
		ws:=settings.ssn("//workspace[@title='" name "']")
		if IsObject(ws){
			CurrentWsNode:=ws
			PopulateWindows(ws)
		}
	}
return
WsDoubleClick(row){
	global CurrentWsNode
	if !row
		return
	VarSetCapacity(POINT,8,0)
	DllCall("GetCursorPos","Ptr",&POINT)
	DllCall("ScreenToClient","Ptr",hwnd("wslv"),"Ptr",&POINT)
	mouseX:=NumGet(POINT,0,"Int")
	SendMessage,0x101D,0,0,,% "ahk_id " hwnd("wslv")
	col1Width:=ErrorLevel
	Gui,1:Default
	Gui,1:ListView,% hwnd("wslv")
	LV_GetText(name,row,1)
	ws:=settings.ssn("//workspace[@title='" name "']")
	if !IsObject(ws)
		return
	if(mouseX<col1Width){
		InputBox,newTitle,Rename Workspace,Enter new name for this workspace,,,,,,,,% name
		if(ErrorLevel||newTitle=""||newTitle=name)
			return
		if settings.ssn("//workspaces/workspace[@title='" newTitle "']")
			return ShowMessage("A workspace with that name already exists.")
		ws.SetAttribute("title",newTitle)
		PopulateGroups(1)
	}else{
		EditHotkey(ws)
	}
}
WsSearchUpdate:
	FilterWorkspaceList()
return
FilterWorkspaceList(){
	global CurrentWsNode, CurrentWinNode, LastWsRow
	Gui,1:Default
	GuiControlGet,filter,,% hwnd("wssearch")
	selectedTitle:=""
	if IsObject(CurrentWsNode)
		selectedTitle:=XPathNode(CurrentWsNode,"@title").text
	Gui,1:ListView,% hwnd("wslv")
	GuiControl,-Redraw,% hwnd("wslv")
	LV_Delete()
	selectRow:=0, rowNum:=0
	workspaces:=settings.sn("//workspaces/workspace")
	while,ws:=workspaces.item[A_Index-1]{
		ea:=xml.ea(ws)
		title:=ea.title, hk:=ea.hotkey?ea.hotkey:""
		if(filter!=""&&!InStr(title,filter)&&!InStr(hk,filter))
			continue
		rowNum++
		LV_Add("",title,hk)
		if(title=selectedTitle)
			selectRow:=rowNum
	}
	LV_ModifyCol(1,"AutoHdr")
	LV_ModifyCol(2,"AutoHdr")
	if(!selectRow&&LV_GetCount()>0)
		selectRow:=1
	LastWsRow:=selectRow
	if selectRow{
		LV_Modify(selectRow,"Select Focus Vis")
		LV_GetText(wsname,selectRow,1)
		if(wsname!=selectedTitle){
			CurrentWsNode:=settings.ssn("//workspace[@title='" wsname "']")
			CurrentWinNode:=""
			PopulateWindows(CurrentWsNode)
		}
	}else if(selectedTitle!=""){
		CurrentWsNode:=""
		CurrentWinNode:=""
		PopulateWindows("")
	}
	GuiControl,+Redraw,% hwnd("wslv")
}
; ========== Middle Pane Event Handlers ==========
WinListEvent:
	Gui,1:Default
	Gui,1:ListView,% hwnd("winlv")
	if(A_GuiEvent="DoubleClick"){
		row:=A_EventInfo
		if row
			WinListDoubleClick(row)
		return
	}
	if(A_GuiEvent="RightClick"){
		row:=A_EventInfo
		if row
			ActivateWindow(row)
		return
	}
	row:=LV_GetNext()
	if(row>0&&row!=LastWinRow){
		LastWinRow:=row
		SaveWindowSettingsState()
		LV_GetText(name,row,1)
		if IsObject(CurrentWsNode){
			winNode:=CurrentWsNode.SelectSingleNode("window[@title='" name "']")
			if IsObject(winNode){
				CurrentWinNode:=winNode
				PopulateWindowSettings(winNode)
			}
		}
	}
return
WinListDoubleClick(row){
	global CurrentWinNode, CurrentWsNode
	if !row
		return
	Gui,1:Default
	Gui,1:ListView,% hwnd("winlv")
	LV_GetText(name,row,1)
	if !IsObject(CurrentWsNode)
		return
	winNode:=CurrentWsNode.SelectSingleNode("window[@title='" name "']")
	if !IsObject(winNode)
		return
	InputBox,newTitle,Edit Window Title,Enter a new title for this window,,,,,,,,% name
	if(ErrorLevel||newTitle=""||newTitle=name)
		return
	winNode.SetAttribute("title",newTitle)
	CurrentWinNode:=winNode
	PopulateGroups(1)
}
ActivateWindow(row){
	global CurrentWsNode
	Gui,1:Default
	Gui,1:ListView,% hwnd("winlv")
	LV_GetText(name,row,1)
	if !IsObject(CurrentWsNode)
		return
	node:=CurrentWsNode.SelectSingleNode("window[@title='" name "']")
	if !IsObject(node)
		return
	ea:=xml.ea(node)
	pos:=[]
	prev:=SetWinMatchMode(node),wintitle:=BuildWinTitle(node,ea)
	if !WinExist(wintitle){
		run:=XPathNode(node,"item[@title='Run']/@value").text
		if RegExMatch(run,"i)^(.*?\.exe)\s+(.*)",exeMatch){
			SplitPath,exeMatch1,,dir
			Run,"%exeMatch1%" %exeMatch2%,%dir%
		}else{
			SplitPath,run,file,dir
			if !file
				Run,%dir%
			else
				Run,%file%,%dir%
		}
	}
	WinGet,max,MinMax,% wintitle
	if(max=-1)
		WinRestore,% wintitle
	WinActivate,% wintitle
	SysGet,count,MonitorCount
	position:=(XPathNode(node,"*[@title='Monitor Count'][@value='" count "']/position/@value").text)
	position:=position?position:XPathNode(node,"descendant::position/@value").text
	for a,b in StrSplit(position," ")
		pos[SubStr(b,1,1)]:=SubStr(b,2)
	if(getvalue(node,"Maximize")){
		WinRestore,% wintitle
		WinMaximize,% wintitle
	}else
		WinMove,% wintitle,,% pos.x,% pos.y,% pos.w,% pos.h
	RestoreWinMatchMode(prev)
	WinActivate,% hwnd([1])
}
; ========== Right Pane Event Handler ==========
WinTvEvent:
	Gui,1:Default
	Gui,1:TreeView,% hwnd("wintv")
	if(A_GuiEvent="doubleclick"){
		node:=settings.ssn("//*[@tv='" A_EventInfo "']"),ea:=xml.ea(node)
		if !node
			return
		if(ea.title="Run"){
			InputBox,run,New Run Value,Enter a file path/folder to run,,,,,,,,% ea.value
			if(ErrorLevel||run="")
				return
			node.SetAttribute("value",run),PopulateGroups(1)
			return
		}if(ea.title="position"){
			InputBox,newpos,New Position,Edit the windows position,,,,,,,,% ea.value
			if(ErrorLevel||newpos="")
				return
			node.SetAttribute("value",newpos),PopulateGroups(1)
			return
		}
	}else if(A_GuiEvent="RightClick"){
		node:=settings.ssn("//*[@tv='" A_EventInfo "']")
		if !node
			return
		ea:=xml.ea(node)
		if(ea.title="run"){
			FileSelectFolder,dir,,,Select a folder to open
			if ErrorLevel
				return
			node.SetAttribute("value",dir),PopulateGroups(1)
		}
	}
return
; ========== Core Functions ==========
capture(){
	static node
	global CurrentWsNode
	node:=CurrentWsNode
	if !IsObject(node)
		return ShowMessage("Please select or create a workspace to add windows to")
	Gui,2:Destroy
	Gui,2:Default
	Gui,Add,ListView,w600 h200,Window|hwnd
	Gui,Add,Button,gchoose Default,Add Selected
	WinGet,list,list
	Loop,%list%{
		WinGetTitle,title,% "ahk_id" list%A_Index%
		WinGet,max,MinMax,% "ahk_id" list%A_Index%
		if(max!=0||title="")
			continue
		if(title="program manager")
			Continue
		WinGetPos,x,y,w,h,% "ahk_id" list%A_Index%
		if title
			LV_Add("",title,list%A_Index%)
	}
	windows:=settings.sn("//window")
	while,ww:=windows.item[A_Index-1],ea:=xml.ea(ww)
		LV_Add("",ea.title)
	Loop,3
		LV_ModifyCol(A_Index,"AutoHDR")
	Gui,Show,,% "Select Windows To Add To : " XPathNode(node,"@title").text
	return
	choose:
	WorkSpaceState(),next:=0
	Gui,2:Default
	Gui,2:ListView,SysListView321
	while,next:=LV_GetNext(next){
		LV_GetText(win,next,2)
		if(win=""){
			LV_GetText(title,next,1)
			if(XPathNode(node,"window[@title='" title "']"))
				Continue
			copy:=settings.ssn("//window[@title='" title "']")
			clone:=copy.clonenode(1)
			node.AppendChild(clone),node.SetAttribute("expand",1)
			Continue
		}
		for Item in ComObjCreate("Shell.Application").Windows
			if(item.hwnd=win)
				run:=RegExReplace(SubStr(uridecode(item.locationurl),9),"\/","\")
		aid:="ahk_id" win
		WinGetTitle,title,%aid%
		WinGetClass,class,%aid%
		WinGetPos,x,y,w,h,%aid%
		Position:="x" x " y" y " w" w " h" h
		WinGet,list,list
		if(run=""){
			Loop,%list%{
				hwnd:=list%A_Index%
				WinGetTitle,wintitle,% "ahk_id" hwnd
				if (wintitle==title){
					WinGet,Run,processpath,ahk_id%hwnd%
					Break
				}
			}
		}
		WinGet,maximize,MinMax,%title%
		SysGet,count,MonitorCount
		WinRestore,% hwnd([1])
		WinActivate,% hwnd([1])
		if !XPathNode(node,"window[@title='" title "']"){
			WinGet,exe,ProcessName,%aid%
			top:=settings.under({under:node,node:"window",att:{title:title}})
			for a,b in {"Window Match Mode":"contains",Class:class,Exe:exe,Run:Run,"Auto Close":0,"Auto Open":0,Maximize:0}
				settings.under({under:top,node:"item",att:{title:a,value:b}})
			mc:=settings.under({under:top,node:"monitor",att:{title:"Monitor Count",value:count}})
			settings.under({under:mc,node:"position",att:{title:"Position",value:position}})
			node.SetAttribute("expand",1)
		}
		run:=""
	}
	Gui,2:Destroy
	PopulateGroups()
	return
}
Create_Workspace(){
	createworkspace:
	InputBox,workspace,Workspace Name,Enter the name for the new workspace
	if(ErrorLevel||workspace="")
		return
	if settings.ssn("//workspaces/workspace[@title='" workspace "']")
		return ShowMessage("Workspace exists.")
	select:=settings.sn("//*[@select]")
	while,ss:=select.item[A_Index-1]
		ss.RemoveAttribute("select")
	ws:=settings.Add({path:"workspaces/workspace",att:{title:workspace,select:1},dup:1})
	PopulateGroups()
	return
}
delete(){
	delete:
	global CurrentWsNode, CurrentWinNode
	Gui,1:Default
	focusHwnd:=DllCall("GetFocus","Ptr")
	if(focusHwnd=hwnd("wslv")){
		; Delete workspace
		if !IsObject(CurrentWsNode)||CurrentWsNode.nodename!="workspace"
			return
		MsgBox,308,Are you sure?,This action can not be undone.
		IfMsgBox,No
			return
		CurrentWsNode.ParentNode.RemoveChild(CurrentWsNode)
		CurrentWsNode:=""
		CurrentWinNode:=""
		PopulateGroups(1)
	}else if(focusHwnd=hwnd("winlv")){
		; Delete window from middle pane
		if !IsObject(CurrentWinNode)||CurrentWinNode.nodename!="window"
			return
		winTitle:=XPathNode(CurrentWinNode,"@title").text
		MsgBox,308,Delete Window?,% "Remove """ winTitle """ from this workspace?`n`nThis action can not be undone."
		IfMsgBox,No
			return
		CurrentWinNode.ParentNode.RemoveChild(CurrentWinNode)
		CurrentWinNode:=""
		PopulateGroups(1)
	}else if(focusHwnd=hwnd("wintv")){
		; Clear Run value in settings pane
		Gui,1:TreeView,% hwnd("wintv")
		sel:=TV_GetSelection()
		node:=settings.ssn("//*[@tv='" sel "']")
		if !node
			return
		ea:=xml.ea(node)
		if(ea.title="run")
			node.SetAttribute("value",""),PopulateGroups(1)
	}
	return
}
exit(){
	keyexit:
	ExitApp
	Exit:
	WorkSpaceState()
	for a,b in ["tv","tvselect"]{
		rem:=settings.sn("//*[@" b "]")
		while,rr:=rem.item[A_Index-1]
			rr.RemoveAttribute(b)
	}
	settings.save(1)
	ExitApp
	return
}
help:
	MsgBox,,Workspaces Help,% "Workspaces v" Version "`n`n"
		. "LEFT PANE - Workspace List:`n"
		. "  Click to select a workspace`n"
		. "  Double-click name to rename`n"
		. "  Double-click hotkey to edit`n"
		. "  Press Enter to edit hotkey`n"
		. "  Press Delete to remove workspace`n`n"
		. "MIDDLE PANE - Window List:`n"
		. "  Click to view window settings`n"
		. "  Double-click or Enter to edit title`n"
		. "  Right-click to activate/position window`n"
		. "  Ctrl+Up/Down to reorder windows`n"
		. "  Press Delete to remove a window`n`n"
		. "RIGHT PANE - Window Settings:`n"
		. "  Press Enter to edit selected item`n"
		. "  Double-click Run or Position to edit`n"
		. "  Press Delete to clear Run value`n`n"
		. "SETTINGS MENU:`n"
		. "  Click actions to execute them`n"
		. "  Edit Hotkeys to change keybindings"
return
enter(){
	enter:
	Gui,1:Default
	focusHwnd:=DllCall("GetFocus","Ptr")
	if(focusHwnd=hwnd("wslv")){
		; Edit workspace hotkey
		ws:=GetSelectedWorkspace()
		if IsObject(ws)
			EditHotkey(ws)
	}else if(focusHwnd=hwnd("winlv")){
		; Edit window title
		global CurrentWinNode
		if !IsObject(CurrentWinNode)
			return
		title:=XPathNode(CurrentWinNode,"@title").text
		InputBox,newTitle,Edit Window Title,Enter a new title for this window,,,,,,,,% title
		if(ErrorLevel||newTitle=""||newTitle=title)
			return
		CurrentWinNode.SetAttribute("title",newTitle)
		PopulateGroups(1)
	}else if(focusHwnd=hwnd("wintv")){
		; Edit settings item
		Gui,1:TreeView,% hwnd("wintv")
		sel:=TV_GetSelection()
		current:=settings.ssn("//*[@tv='" sel "']")
		if !current
			return
		ea:=xml.ea(current)
		if(ea.title~="(Auto Close|Auto Open|Maximize)"){
			current.SetAttribute("value",ea.value?0:1)
		}else if(ea.title="Window Match Mode"){
			modes:=["contains","exact","startswith","endswith","regex"]
			cur:=ea.value?ea.value:"contains"
			Loop,% modes.Length()
				if(modes[A_Index]=cur){
					next:=A_Index<modes.Length()?A_Index+1:1
					break
				}
			current.SetAttribute("value",modes[next])
		}else if(ea.title="Exe"){
			InputBox,newexe,Edit Exe,Enter the process name (e.g. chrome.exe),,,,,,,,% ea.value
			if(!ErrorLevel&&newexe!="")
				current.SetAttribute("value",newexe)
		}else if(ea.title="run"){
			file:=ea.value
			SplitPath,file,,dir
			FileSelectFile,newinfo,,%dir%,Please select the program to run: Escape for Folder Select
			if(FileExist(newinfo)=""||newinfo="")
				return
			current.SetAttribute("value",newinfo)
		}else if(ea.title="position")
			return updatepos(current),current.SetAttribute("tvselect",1),PopulateGroups()
		current.SetAttribute("tvselect",1)
		PopulateGroups(1)
	}
	return
}
EditHotkey(targetNode){
	global HotkeyTargetNode, HotkeyHwndCtrl
	HotkeyTargetNode:=targetNode
	KeyWait,Enter,U
	Gui,2:Destroy
	Gui,2:Default
	currentHk:=XPathNode(targetNode,"@hotkey").text
	Gui,Add,Hotkey,w200 vhotkey hwndHotkeyHwndCtrl,% currentHk
	Gui,Add,Edit,w200 vedit gedithotkey
	Gui,Add,Button,gsavehotkey Default,Save Hotkey
	Gui,Show,,Edit Hotkey
}
edithotkey:
	Gui,2:Submit,Nohide
	GuiControl,2:,%HotkeyHwndCtrl%,%edit%
return
savehotkey:
	Gui,2:Submit,Nohide
	if(hotkey=""&&edit){
		MsgBox,36,Non-Standard Hotkey,This is a non-standard hotkey. Use it?
		IfMsgBox,No
			return
		hotkey:=edit
	}
	HotkeyTargetNode.SetAttribute("hotkey",hotkey),PopulateGroups(1)
	Gui,2:Destroy
return
2GuiEscape:
2GuiClose:
	Gui,2:Destroy
return
; ========== State & Navigation ==========
GetSelectedWorkspace(){
	Gui,1:Default
	Gui,1:ListView,% hwnd("wslv")
	row:=LV_GetNext()
	if !row
		return ""
	LV_GetText(name,row,1)
	return settings.ssn("//workspace[@title='" name "']")
}
SaveWindowSettingsState(){
	Gui,1:Default
	Gui,1:TreeView,% hwnd("wintv")
	tv:=0
	while,tv:=TV_GetNext(tv,"F"){
		node:=settings.ssn("//*[@tv='" tv "']")
		if node{
			if TV_Get(tv,"E")
				node.SetAttribute("expand",1)
			else
				try node.RemoveAttribute("expand")
		}
	}
}
WorkSpaceState(){
	global CurrentWsNode, CurrentWinNode
	Gui,1:Default
	for a,b in ["VisFirst","expand","select"]{
		rem:=settings.sn("//*[@" b "]")
		while,rr:=rem.Item[A_Index-1]
			rr.RemoveAttribute(b)
	}
	if IsObject(CurrentWsNode)
		CurrentWsNode.SetAttribute("select",1)
	if IsObject(CurrentWinNode)
		CurrentWinNode.SetAttribute("select",1)
	SaveWindowSettingsState()
}
Move_Windows(){
	movedown:
	global CurrentWinNode
	Gui,1:Default
	focusHwnd:=DllCall("GetFocus","Ptr")
	if(focusHwnd!=hwnd("winlv"))
		return
	if !IsObject(CurrentWinNode)||CurrentWinNode.nodename!="window"
		return
	if(CurrentWinNode.nextsibling.xml="")
		return
	WorkSpaceState(),root:=CurrentWinNode.ParentNode
	if next:=CurrentWinNode.nextsibling.nextsibling
		root.insertbefore(CurrentWinNode,next)
	else
		root.AppendChild(CurrentWinNode)
	PopulateGroups(1)
	return
	moveup:
	global CurrentWinNode
	Gui,1:Default
	focusHwnd:=DllCall("GetFocus","Ptr")
	if(focusHwnd!=hwnd("winlv"))
		return
	if !IsObject(CurrentWinNode)||CurrentWinNode.nodename!="window"
		return
	if((prev:=CurrentWinNode.previoussibling).xml="")
		return
	WorkSpaceState(),root:=CurrentWinNode.ParentNode,root.InsertBefore(CurrentWinNode,prev),PopulateGroups(1)
	return
}
TabNav(){
	TabForward:
	Gui,1:Default
	focusHwnd:=DllCall("GetFocus","Ptr")
	if(focusHwnd=hwnd("wslv")){
		ControlFocus,,% "ahk_id " hwnd("winlv")
		return
	}
	if(focusHwnd=hwnd("winlv")){
		ControlFocus,,% "ahk_id " hwnd("wintv")
		return
	}
	Hotkey,Tab,Off
	Send,{Tab}
	Hotkey,Tab,On
	return
	TabBackward:
	Gui,1:Default
	focusHwnd:=DllCall("GetFocus","Ptr")
	if(focusHwnd=hwnd("wintv")){
		ControlFocus,,% "ahk_id " hwnd("winlv")
		return
	}
	if(focusHwnd=hwnd("winlv")){
		ControlFocus,,% "ahk_id " hwnd("wslv")
		return
	}
	Hotkey,+Tab,Off
	Send,+{Tab}
	Hotkey,+Tab,On
	return
}
; ========== Populate Functions ==========
PopulateGroups(save:=0){
	static lastkeys:=[]
	global CurrentWsNode, CurrentWinNode, LastWsRow
	Gui,1:Default
	if save
		WorkSpaceState()
	BackfillWindowItems()
	for a in lastkeys{
		Hotkey,IfWinActive
		try Hotkey,%a%,Hotkey,Off
	}
	lastkeys:=[]
	GuiControlGet,filter,,% hwnd("wssearch")
	selectedTitle:=""
	if IsObject(CurrentWsNode)
		selectedTitle:=XPathNode(CurrentWsNode,"@title").text
	if(selectedTitle=""){
		savedSel:=settings.ssn("//workspace[@select]")
		if savedSel
			selectedTitle:=XPathNode(savedSel,"@title").text
	}
	Gui,1:ListView,% hwnd("wslv")
	GuiControl,-Redraw,% hwnd("wslv")
	LV_Delete()
	selectRow:=0, rowNum:=0
	workspaces:=settings.sn("//workspaces/workspace")
	while,ws:=workspaces.item[A_Index-1]{
		ea:=xml.ea(ws)
		title:=ea.title, hk:=ea.hotkey?ea.hotkey:""
		if(filter!=""&&!InStr(title,filter)&&!InStr(hk,filter))
			continue
		rowNum++
		LV_Add("",title,hk)
		if(title=selectedTitle)
			selectRow:=rowNum
	}
	LV_ModifyCol(1,"AutoHdr")
	LV_ModifyCol(2,"AutoHdr")
	if(!selectRow&&LV_GetCount()>0)
		selectRow:=1
	LastWsRow:=selectRow
	if selectRow
		LV_Modify(selectRow,"Select Focus Vis")
	GuiControl,+Redraw,% hwnd("wslv")
	; Register workspaces root hotkey
	wsRoot:=settings.ssn("//workspaces")
	if wsRoot{
		rootEa:=xml.ea(wsRoot)
		if(rootEa.hotkey){
			Hotkey,IfWinActive
			Hotkey,% rootEa.hotkey,hotkey,On
			lastkeys[rootEa.hotkey]:=1
		}
	}
	; Register workspace hotkeys
	allws:=settings.sn("//workspaces/workspace")
	while,ws:=allws.item[A_Index-1]{
		ea:=xml.ea(ws)
		if(ea.hotkey){
			Hotkey,IfWinActive
			Hotkey,% ea.hotkey,hotkey,On
			lastkeys[ea.hotkey]:=1
		}
	}
	; Register settings hotkeys
	slist:=settings.sn("//Settings/setting")
	while,ss:=slist.item[A_Index-1]{
		ea:=xml.ea(ss)
		if(ea.hotkey){
			Hotkey,IfWinActive
			Hotkey,% ea.hotkey,hotkey,On
			lastkeys[ea.hotkey]:=1
		}
	}
	BuildSettingsMenu()
	; Populate windows for selected workspace
	if selectRow{
		Gui,1:ListView,% hwnd("wslv")
		LV_GetText(wsname,selectRow,1)
		CurrentWsNode:=settings.ssn("//workspace[@title='" wsname "']")
		PopulateWindows(CurrentWsNode)
	}else{
		CurrentWsNode:=""
		CurrentWinNode:=""
		PopulateWindows("")
	}
}
PopulateWindows(wsNode){
	global CurrentWinNode, LastWinRow
	Gui,1:Default
	Gui,1:ListView,% hwnd("winlv")
	GuiControl,-Redraw,% hwnd("winlv")
	LV_Delete()
	if !IsObject(wsNode){
		CurrentWinNode:=""
		GuiControl,+Redraw,% hwnd("winlv")
		PopulateWindowSettings("")
		return
	}
	; Find previously selected window
	selectedTitle:=""
	if IsObject(CurrentWinNode)
		selectedTitle:=XPathNode(CurrentWinNode,"@title").text
	if(selectedTitle=""){
		savedSel:=wsNode.SelectSingleNode("window[@select]")
		if savedSel
			selectedTitle:=XPathNode(savedSel,"@title").text
	}
	selectRow:=0, rowNum:=0
	windows:=XPathNodes(wsNode,"window")
	while,ww:=windows.item[A_Index-1]{
		ea:=xml.ea(ww)
		rowNum++
		LV_Add("",ea.title)
		if(ea.title=selectedTitle)
			selectRow:=rowNum
	}
	LV_ModifyCol(1,"AutoHdr")
	if(!selectRow&&LV_GetCount()>0)
		selectRow:=1
	LastWinRow:=selectRow
	if selectRow{
		LV_Modify(selectRow,"Select Focus Vis")
		LV_GetText(winname,selectRow,1)
		CurrentWinNode:=wsNode.SelectSingleNode("window[@title='" winname "']")
		PopulateWindowSettings(CurrentWinNode)
	}else{
		CurrentWinNode:=""
		PopulateWindowSettings("")
	}
	GuiControl,+Redraw,% hwnd("winlv")
}
PopulateWindowSettings(winNode){
	Gui,1:Default
	Gui,1:TreeView,% hwnd("wintv")
	GuiControl,-Redraw,% hwnd("wintv")
	TV_Delete()
	; Clear ALL stale tv attributes to prevent handle reuse collisions
	stale:=settings.sn("//*[@tv]")
	while,ss:=stale.item[A_Index-1]
		ss.RemoveAttribute("tv")
	if !IsObject(winNode){
		GuiControl,+Redraw,% hwnd("wintv")
		return
	}
	items:=XPathNodes(winNode,"*")
	while,ii:=items.item[A_Index-1]{
		iea:=xml.ea(ii)
		if(ii.nodename="item"){
			value:=iea.value!=""?" = " iea.value:""
			childtv:=TV_Add(iea.title value,0)
			ii.SetAttribute("tv",childtv)
		}else if(ii.nodename="monitor"){
			montv:=TV_Add("Monitor Count = " iea.value,0)
			ii.SetAttribute("tv",montv)
			positions:=XPathNodes(ii,"position")
			while,pp:=positions.item[A_Index-1]{
				pea:=xml.ea(pp)
				ptv:=TV_Add("Position = " pea.value,montv)
				pp.SetAttribute("tv",ptv)
			}
		}
	}
	; Restore expand state
	expanded:=XPathNodes(winNode,"descendant::*[@expand]")
	while,ee:=expanded.item[A_Index-1]{
		tvid:=XPathNode(ee,"@tv").text
		if tvid
			TV_Modify(tvid+0,"Expand")
	}
	; Restore TreeView selection if a setting was just edited
	selNode:=winNode.SelectSingleNode("descendant::*[@tvselect]")
	if selNode{
		tvid:=XPathNode(selNode,"@tv").text
		if tvid
			TV_Modify(tvid+0,"Select Vis")
		selNode.RemoveAttribute("tvselect")
	}
	GuiControl,+Redraw,% hwnd("wintv")
}
; ========== Header Styling ==========
StyleListViewHeaders(){
	; Get header control HWNDs via LVM_GETHEADER (0x101F)
	SendMessage,0x101F,0,0,,% "ahk_id " hwnd("wslv")
	hwnd("wslv_hdr",ErrorLevel)
	SendMessage,0x101F,0,0,,% "ahk_id " hwnd("winlv")
	hwnd("winlv_hdr",ErrorLevel)
	; Create bold font from current header font
	hFont:=DllCall("SendMessage","Ptr",hwnd("wslv_hdr"),"UInt",0x31,"Ptr",0,"Ptr",0,"Ptr")
	VarSetCapacity(LF,92,0)
	DllCall("GetObject","Ptr",hFont,"Int",92,"Ptr",&LF)
	NumPut(700,LF,16,"Int")
	hwnd("hdrBoldFont",DllCall("CreateFontIndirect","Ptr",&LF,"Ptr"))
	; Disable visual themes on headers so custom draw takes full effect
	DllCall("uxtheme\SetWindowTheme","Ptr",hwnd("wslv_hdr"),"Ptr",0,"WStr","")
	DllCall("uxtheme\SetWindowTheme","Ptr",hwnd("winlv_hdr"),"Ptr",0,"WStr","")
	; Subclass both ListViews to intercept header NM_CUSTOMDRAW
	cb:=RegisterCallback("HeaderDrawProc","",6)
	hwnd("hdrCallback",cb)
	DllCall("comctl32\SetWindowSubclass","Ptr",hwnd("wslv"),"Ptr",cb,"UPtr",1,"UPtr",0)
	DllCall("comctl32\SetWindowSubclass","Ptr",hwnd("winlv"),"Ptr",cb,"UPtr",2,"UPtr",0)
}
HeaderDrawProc(hctl,msg,wParam,lParam,uIdSubclass,dwRefData){
	Critical
	if(msg=0x4E){
		hdrFrom:=NumGet(lParam+0,0,"Ptr")
		code:=NumGet(lParam+0,A_PtrSize*2,"Int")
		if(code=-12&&(hdrFrom=hwnd("wslv_hdr")||hdrFrom=hwnd("winlv_hdr"))){
			if(A_PtrSize=8)
				stg_os:=24,hdc_os:=32,rc_os:=40,itm_os:=56
			else
				stg_os:=12,hdc_os:=16,rc_os:=20,itm_os:=36
			stage:=NumGet(lParam+0,stg_os,"UInt")
			if(stage=0x1)
				return 0x20
			if(stage=0x10001){
				hdc:=NumGet(lParam+0,hdc_os,"Ptr")
				left:=NumGet(lParam+0,rc_os,"Int")
				top:=NumGet(lParam+0,rc_os+4,"Int")
				right:=NumGet(lParam+0,rc_os+8,"Int")
				bottom:=NumGet(lParam+0,rc_os+12,"Int")
				idx:=NumGet(lParam+0,itm_os,"UPtr")
				; Fill background with light grey
				VarSetCapacity(RC,16,0)
				NumPut(left,RC,0,"Int"),NumPut(top,RC,4,"Int")
				NumPut(right,RC,8,"Int"),NumPut(bottom,RC,12,"Int")
				hBr:=DllCall("CreateSolidBrush","UInt",0xF0F0F0,"Ptr")
				DllCall("FillRect","Ptr",hdc,"Ptr",&RC,"Ptr",hBr)
				DllCall("DeleteObject","Ptr",hBr)
				; Get header item text via HDM_GETITEMW (0x120B)
				VarSetCapacity(buf,520,0)
				VarSetCapacity(HDI,A_PtrSize=8?72:48,0)
				NumPut(0x2,HDI,0,"UInt")
				NumPut(&buf,HDI,8,"Ptr")
				NumPut(260,HDI,A_PtrSize=8?24:16,"Int")
				DllCall("SendMessage","Ptr",hdrFrom,"UInt",0x120B,"Ptr",idx,"Ptr",&HDI)
				text:=StrGet(&buf,"UTF-16")
				; Draw text with bold font
				DllCall("SelectObject","Ptr",hdc,"Ptr",hwnd("hdrBoldFont"))
				DllCall("SetBkMode","Ptr",hdc,"Int",1)
				DllCall("SetTextColor","Ptr",hdc,"UInt",0x333333)
				VarSetCapacity(RC2,16,0)
				NumPut(left+6,RC2,0,"Int"),NumPut(top,RC2,4,"Int")
				NumPut(right-6,RC2,8,"Int"),NumPut(bottom,RC2,12,"Int")
				DllCall("DrawText","Ptr",hdc,"WStr",text,"Int",-1,"Ptr",&RC2,"UInt",0x8024)
				; Draw thick bottom border (2px grey line)
				hPen:=DllCall("CreatePen","Int",0,"Int",2,"UInt",0xA0A0A0,"Ptr")
				hOld:=DllCall("SelectObject","Ptr",hdc,"Ptr",hPen,"Ptr")
				DllCall("MoveToEx","Ptr",hdc,"Int",left,"Int",bottom-1,"Ptr",0)
				DllCall("LineTo","Ptr",hdc,"Int",right,"Int",bottom-1)
				DllCall("SelectObject","Ptr",hdc,"Ptr",hOld,"Ptr")
				DllCall("DeleteObject","Ptr",hPen)
				return 0x4
			}
		}
	}
	return DllCall("comctl32\DefSubclassProc","Ptr",hctl,"UInt",msg,"Ptr",wParam,"Ptr",lParam,"Ptr")
}
; ========== Utility Functions ==========
hwnd(win,hwnd=""){
	static window:=[]
	if win=get
		return window
	if (win.rem){
		Gui,1:-Disabled
		Gui,1:Default
		WindowTracker.Exit(win.rem)
		if !window[win.rem]
			Gui,% win.rem ":Destroy"
		Else
			DllCall("DestroyWindow",uptr,window[win.rem])
		window[win.rem]:=""
	}
	if IsObject(win)
		return "ahk_id" window[win.1]
	if !hwnd
		return window[win]
	window[win]:=hwnd
}
ShowMessage(x*){
	for a,b in x
		list.=b "`n"
	MsgBox,,AHK Studio,% list
}
ShowTooltip(x*){
	for a,b in x
		list.=b "`n"
	ToolTip,% list
}
BackfillWindowItems(){
	; Desired item order (monitor nodes stay at the end automatically)
	order:=["Window Match Mode","Class","Exe","Run","Auto Close","Auto Open","Maximize"]
	defaults:={"Exe":"","Window Match Mode":"contains"}
	windows:=settings.sn("//window")
	while,ww:=windows.item[A_Index-1]{
		try {
			; Rename legacy "Match Mode" to "Window Match Mode"
			if(old:=XPathNode(ww,"item[@title='Match Mode']"))
				old.SetAttribute("title","Window Match Mode")
			; Backfill missing items
			for itemName,itemDefault in defaults{
				if !XPathNode(ww,"item[@title='" itemName "']")
					settings.under({under:ww,node:"item",att:{title:itemName,value:itemDefault}})
			}
			; Reorder items to match desired sequence
			for idx,name in order{
				node:=XPathNode(ww,"item[@title='" name "']")
				if node
					ww.AppendChild(node)
			}
			; Move monitor nodes to end (after all items)
			monList:=[]
			monitors:=XPathNodes(ww,"monitor")
			while,mm:=monitors.item[A_Index-1]
				monList.Push(mm)
			for i,mm in monList
				ww.AppendChild(mm)
		}
	}
}
UriDecode(Uri) {
	Pos := 1
	While Pos := RegExMatch(Uri, "i)(%[\da-f]{2})+", Code, Pos)
	{
		VarSetCapacity(Var, StrLen(Code) // 3, 0), Code := SubStr(Code,2)
		Loop, Parse, Code, `%
			NumPut("0x" A_LoopField, Var, A_Index-1, "UChar")
		Decoded := StrGet(&Var, "UTF-8")
		Uri := SubStr(Uri, 1, Pos-1) . Decoded . SubStr(Uri, Pos+StrLen(Code)+1)
		Pos += StrLen(Decoded)+1
	}
	Return, Uri
}
getvalue(node,value){
	return XPathNode(node,"descendant::*[@title='" value "']/@value").text
}
; ========== Window Matching ==========
SetWinMatchMode(ww){
	mode:=getvalue(ww,"Window Match Mode")
	if(mode=""||mode="contains")
		mode:=2
	else if(mode="exact")
		mode:=3
	else if(mode="startswith")
		mode:=1
	else if(mode="endswith"||mode="regex")
		mode:="RegEx"
	prev:=A_TitleMatchMode
	SetTitleMatchMode,%mode%
	return prev
}
BuildWinTitle(ww,ea:=""){
	if !IsObject(ea)
		ea:=xml.ea(ww)
	title:=ea.title
	mode:=getvalue(ww,"Window Match Mode")
	if(mode="endswith")
		title:=title "$"
	wintitle:=title
	class:=getvalue(ww,"Class")
	if(class)
		wintitle.=" ahk_class " class
	exe:=getvalue(ww,"Exe")
	if(exe)
		wintitle.=" ahk_exe " exe
	return wintitle
}
WinMatch(title,pattern,mode){
	if(mode=""||mode="contains")
		return InStr(title,pattern)
	else if(mode="exact")
		return (title==pattern)
	else if(mode="startswith")
		return (SubStr(title,1,StrLen(pattern))==pattern)
	else if(mode="endswith")
		return (SubStr(title,1-StrLen(pattern))==pattern)
	else if(mode="regex")
		return RegExMatch(title,pattern)
	return InStr(title,pattern)
}
RestoreWinMatchMode(prev){
	SetTitleMatchMode,%prev%
}
; ========== Hotkey Handler ==========
Hotkey(){
	static
	hotkey:
	current:=settings.ssn("//*[@hotkey='" A_ThisHotkey "']")
	if(current.nodename="workspaces"){
		if Visible
			return ShowTooltip(),visible:=0
		list:=settings.sn("//workspace[@hotkey]"),keylist:=""
		while,ll:=list.item[A_Index-1],ea:=xml.ea(ll)
			keylist.=ea.title " = " ea.hotkey "`n"
		Visible:=1
		return ShowTooltip(keylist)
	}else if(current.nodename="setting"),ea:=xml.ea(current){
		if(ea.name="Hide/Show GUI"){
			GoSub,GuiClose
			return
		}else if(ea.name="Toggle Current Workspace"){
			current:=settings.ssn("//workspace[@current]")
			if !current
				settings.ssn("//workspace").SetAttribute("current",1)
			else{
				if(next:=current.nextsibling){
					current.RemoveAttribute("current")
					next.SetAttribute("current",1)
				}else{
					current.RemoveAttribute("current")
					settings.ssn("//workspace").SetAttribute("current",1)
				}
			}
			current:=settings.ssn("//workspace[@current]")
			Restore(XPathNodes(current,"descendant::window"),1,1)
		}else if(ea.name="Workspace Launcher"){
			ShowLauncher()
			return
		}
	}
	windows:=settings.sn("//*[@hotkey='" A_ThisHotkey "']/descendant::window"),minimized:=""
	SysGet,count,MonitorCount
	while,ww:=windows.item[A_Index-1],ea:=xml.ea(ww){
		prev:=SetWinMatchMode(ww),wintitle:=BuildWinTitle(ww,ea)
		if(WinActive(wintitle)){
			RestoreWinMatchMode(prev)
			position:=(XPathNode(ww,"*[@title='Monitor Count'][@value='" count "']/position/@value").text),position:=position?position:XPathNode(ww,"descendant::position/@value").text
			WinGetPos,x,y,w,h,% wintitle
			for a,b in {x:x,y:y,w:w,h:h}{
				RegExMatch(position,"Oi)" a "(-?\d+)",found)
				if(found.1!=b){
					minimized:=1
					Goto,hkbottom
				}
			}
			minimized:=0
			goto,hkbottom
		}
		RestoreWinMatchMode(prev)
	}Minimized:=1
	hkbottom:
	Restore(windows,minimized)
	return
}
; ========== Restore & Positions ==========
Restore(windows,minimized,skipwait:=0){
	while,ww:=windows.item[windows.length-(A_Index)],ea:=xml.ea(ww){
		prev:=SetWinMatchMode(ww),wintitle:=BuildWinTitle(ww,ea)
		if(minimized){
			if (WinExist(wintitle)=0){
				if !getvalue(ww,"Auto Open"){
					RestoreWinMatchMode(prev)
					Continue
				}
				file:=getvalue(ww,"Run")
				if RegExMatch(file,"i)^(.*?\.exe)\s+(.*)",exeMatch){
					SplitPath,exeMatch1,,dir
					Run,"%exeMatch1%" %exeMatch2%,%dir%
				}else{
					SplitPath,file,filename,dir
					if !filename
						Run,%dir%
					else
						Run,%filename%,%dir%
				}
				WinWait,% wintitle,,1
			}
			WinActivate,% wintitle
			pos:=[]
			SysGet,count,MonitorCount
			position:=(XPathNode(ww,"*[@title='Monitor Count'][@value='" count "']/position/@value").text),position:=position?position:XPathNode(ww,"descendant::position/@value").text
			for a,b in StrSplit(position," ")
				pos[SubStr(b,1,1)]:=SubStr(b,2)
			if(getvalue(ww,"Maximize")){
				WinWaitActive,% wintitle
				WinMaximize,% wintitle
			}else
				WinMove,% wintitle,,% pos.x,% pos.y,% pos.w,% pos.h
		}else{
			WinGet,list,list,% "ahk_class" XPathNode(ww,"*[@title='Class']/@value").text
			match:=[]
			Loop,%list%
			{
				WinGetTitle,title,% "ahk_id" list%A_Index%
				if WinMatch(title,ea.title,getvalue(ww,"Window Match Mode"))
					match[title]:=list%A_Index%
			}
			for a,b in match{
				if(getvalue(ww,"Auto Close"))
					WinClose,ahk_id %b%
				else
					WinMinimize,ahk_id %b%
			}
		}
		RestoreWinMatchMode(prev)
	}ShowTooltip()
}
Update_Positions(){
	updatepos:
	global CurrentWsNode
	if !IsObject(CurrentWsNode)
		return ShowMessage("Please select a workspace first")
	wl:=XPathNodes(CurrentWsNode,"descendant::window")
	while,ww:=wl.item[A_Index-1]{
		win:=XPathNode(ww,"@title").text
		WinGet,max,MinMax,%win%
		if (max=0)
			updatepos(ww)
	}PopulateGroups(1)
	return
}
updatepos(current){
	SysGet,count,MonitorCount
	parent:=XPathNode(current,"ancestor-or-self::window")
	WinGetPos,x,y,w,h,% XPathNode(parent,"@title").text
	if !position:=XPathNode(parent,"*[@title='Monitor Count'][@value='" count "']")
		position:=settings.under({under:parent,node:"monitor",att:{title:"Monitor Count",value:count}})
	if !pos:=XPathNode(position,"position")
		pos:=settings.under({under:position,node:"position",att:{title:"Position"}})
	if(x!=""&&y!=""&&w!=""&&h!=""){
		pos.SetAttribute("value","x" x " y" y " w" w " h" h)
	}else{
		InputBox,newinfo,New Position,Enter a new position for this window,,,,,,,,% ea.position
		if(ErrorLevel||newinfo="")
			return ShowMessage("Please enter a value for this window")
		pos.SetAttribute("value",newinfo)
	}
	WorkSpaceState(),pos.SetAttribute("select",1)
}
; ========== XML Class ==========
class xml{
	keep:=[]
	__New(param*){
		if !FileExist(A_ScriptDir "\lib")
			FileCreateDir,%A_ScriptDir%\lib
		root:=param.1,file:=param.2
		file:=file?file:root ".xml"
		try
			temp:=ComObjCreate("MSXML2.DOMDocument")
		catch e
			return ShowMessage("Failed to create XML COM object: " e.Message)
		temp.setProperty("SelectionLanguage","XPath")
		this.xml:=temp
		if FileExist(file){
			ff:=FileOpen(file,"r","utf-16")
			if !ff
				return ShowMessage("Failed to open file for reading: " file)
			info:=ff.Read(ff.length)
			if(info=""){
				this.xml:=this.CreateElement(temp,root)
				FileDelete,%file%
			}else{
				try
					temp.loadxml(info),this.xml:=temp
				catch e
					return ShowMessage("Failed to parse XML in " file ": " e.Message)
			}
		}else
			this.xml:=this.CreateElement(temp,root)
		this.file:=file
		xml.keep[root]:=this
	}
	CreateElement(doc,root){
		return doc.AppendChild(this.xml.CreateElement(root)).parentnode
	}
	lang(info){
		info:=info=""?"XPath":"XSLPattern"
		this.xml.setProperty("SelectionLanguage",info)
	}
	unique(info){
		if (info.check&&info.text)
			return
		if info.under{
			if info.check
				find:=info.under.SelectSingleNode("*[@" info.check "='" info.att[info.check] "']")
			if info.Text
				find:=this.cssn(info.under,"*[text()='" info.text "']")
			if !find
				find:=this.under({under:info.under,att:info.att,node:info.path})
			for a,b in info.att
				find.SetAttribute(a,b)
		}
		else
		{
			if info.check
				find:=this.ssn("//" info.path "[@" info.check "='" info.att[info.check] "']")
			else if info.text
				find:=this.ssn("//" info.path "[text()='" info.text "']")
			if !find
				find:=this.add({path:info.path,att:info.att,dup:1})
			for a,b in info.att
				find.SetAttribute(a,b)
		}
		if info.text
			find.text:=info.text
		return find
	}
	Add(info){
		path:=info.path,p:="/",dup:=this.ssn("//" path)?1:0
		if next:=this.ssn("//" path)?this.ssn("//" path):this.ssn("//*")
			Loop,Parse,path,/
				last:=A_LoopField,p.="/" last,next:=this.ssn(p)?this.ssn(p):next.appendchild(this.xml.CreateElement(last))
		if (info.dup&&dup)
			next:=next.parentnode.appendchild(this.xml.CreateElement(last))
		for a,b in info.att
			next.SetAttribute(a,b)
		for a,b in StrSplit(info.list,",")
			next.SetAttribute(b,info.att[b])
		if info.text!=""
			next.text:=info.text
		return next
	}
	under(info){
		new:=info.under.appendchild(this.xml.createelement(info.node))
		for a,b in info.att
			new.SetAttribute(a,b)
		for a,b in StrSplit(info.list,",")
			new.SetAttribute(b,info.att[b])
		if info.text
			new.text:=info.text
		return new
	}
	findsn(node,find){
		if InStr(find,"'")
			return this.xml.SelectNodes(node "[contains(.,concat('" RegExReplace(find,"'","'," Chr(34) "'" Chr(34) ",'") "'))]/..")
		else
			return this.xml.SelectNodes(node "[.='" find "']/..")
	}
	find(node,find){
		if InStr(find,"'")
			return this.xml.SelectSingleNode(node "[contains(.,concat('" RegExReplace(find,"'","'," Chr(34) "'" Chr(34) ",'") "'))]/..")
		else
			return this.xml.SelectSingleNode(node "[.='" find "']/..")
	}
	ssn(node){
		return this.xml.SelectSingleNode(node)
	}
	sn(node){
		return this.xml.SelectNodes(node)
	}
	__Get(x=""){
		return this.xml.xml
	}
	Get(path,Default){
		return value:=this.ssn(path).text!=""?this.ssn(path).text:Default
	}
	transform(){
		static
		if !IsObject(xsl){
			xsl:=ComObjCreate("MSXML2.DOMDocument")
			style=
			(
			<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
			<xsl:output method="xml" indent="yes" encoding="UTF-8"/>
			<xsl:template match="@*|node()">
			<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
			<xsl:for-each select="@*">
			<xsl:text></xsl:text>
			</xsl:for-each>
			</xsl:copy>
			</xsl:template>
			</xsl:stylesheet>
			)
			xsl.loadXML(style),style:=null
		}
		this.xml.transformNodeToObject(xsl,this.xml)
	}
	save(x*){
		if x.1=1
			this.Transform()
		filename:=this.file?this.file:x.1.1
		file:=fileopen(filename,"rw","Utf-16")
		if !file
			return ShowMessage("Failed to open file for writing: " filename)
		if(this.xml.xml==file.read(file.length))
			return
		file.seek(0),file.write(this[]),file.length(file.position)
	}
	remove(rem){
		if !IsObject(rem)
			rem:=this.ssn(rem)
		rem.ParentNode.RemoveChild(rem)
	}
	ea(path){
		list:=[]
		if nodes:=path.nodename
			nodes:=path.SelectNodes("@*")
		else if path.text
			nodes:=this.sn("//*[text()='" path.text "']/@*")
		else if !IsObject(path)
			nodes:=this.sn(path "/@*")
		else
			for a,b in path
				nodes:=this.sn("//*[@" a "='" b "']/@*")
		while,n:=nodes.item(A_Index-1)
			list[n.nodename]:=n.text
		return list
	}
}
XPathNode(node,path){
	return node.SelectSingleNode(path)
}
XPathNodes(node,path){
	return node.SelectNodes(path)
}
; ========== Workspace Launcher (Launchy-style search) ==========
ShowLauncher(){
	global LauncherHwnd,LauncherEditHwnd,LauncherListHwnd,LauncherItems,LauncherSel,LauncherQuery,LauncherCreated
	if(!LauncherCreated){
		Gui,9:+AlwaysOnTop -Caption +Border +ToolWindow +HwndLauncherHwnd
		Gui,9:Margin,0,0
		Gui,9:Color,F5F5F5
		Gui,9:Font,s9 cAAAAAA,Segoe UI
		Gui,9:Add,Text,x0 y0 w364 h26 Center BackgroundDDDDDD,Workspace Launcher
		Gui,9:Margin,12,12
		Gui,9:Font,s9 c888888,Segoe UI
		Gui,9:Add,Text,xm w340,Type to search workspaces:
		Gui,9:Font,s14 c000000,Segoe UI
		OnMessage(0x84,"LauncherHitTest")
		Gui,9:Add,Edit,w340 vLauncherQuery gLauncherKeyStroke hwndLauncherEditHwnd
		Gui,9:Font,s11 c000000,Segoe UI
		Gui,9:Add,ListBox,w340 r8 hwndLauncherListHwnd
		LauncherPopulate("")
		SysGet,Mon,MonitorWorkArea
		gx:=(MonRight-364)//2,gy:=(MonBottom-350)//3
		Gui,9:Show,x%gx% y%gy%,Workspace Launcher
		Hotkey,IfWinActive,ahk_id %LauncherHwnd%
		Hotkey,Enter,LauncherGo,On
		Hotkey,Escape,LauncherClose,On
		Hotkey,Down,LauncherNextItem,On
		Hotkey,Up,LauncherPrevItem,On
		Hotkey,NumpadEnter,LauncherGo,On
		Hotkey,IfWinActive
		LauncherCreated:=1
	}else{
		Gui,9:Show
		SendMessage,0xB1,0,-1,,ahk_id %LauncherEditHwnd%
		Gui,9:Submit,NoHide
		LauncherPopulate(LauncherQuery)
	}
	SetTimer,LauncherFocusCheck,100
}
LauncherFocusCheck:
	IfWinNotActive,ahk_id %LauncherHwnd%
	{
		Gui,9:Hide
		SetTimer,LauncherFocusCheck,Off
	}
return
LauncherPopulate(query){
	global LauncherListHwnd,LauncherItems,LauncherSel
	LauncherItems:=[],items:=""
	workspaces:=settings.sn("//workspace")
	while,ws:=workspaces.item[A_Index-1]{
		title:=XPathNode(ws,"@title").text
		if(query=""||InStr(title,query))
			items.="|" title,LauncherItems.Push(title)
	}
	GuiControl,9:,%LauncherListHwnd%,%items%
	LauncherSel:=LauncherItems.Length()>0?1:0
	if(LauncherSel>0)
		GuiControl,9:Choose,%LauncherListHwnd%,1
}
LauncherKeyStroke:
	Gui,9:Submit,NoHide
	LauncherPopulate(LauncherQuery)
return
LauncherNextItem:
	global LauncherListHwnd,LauncherItems,LauncherSel
	if(LauncherSel<LauncherItems.Length())
		LauncherSel++
	GuiControl,9:Choose,%LauncherListHwnd%,%LauncherSel%
return
LauncherPrevItem:
	global LauncherListHwnd,LauncherItems,LauncherSel
	if(LauncherSel>1)
		LauncherSel--
	GuiControl,9:Choose,%LauncherListHwnd%,%LauncherSel%
return
LauncherGo:
	global LauncherItems,LauncherSel
	Gui,9:Hide
	SetTimer,LauncherFocusCheck,Off
	if(LauncherSel>0&&LauncherSel<=LauncherItems.Length()){
		selected:=LauncherItems[LauncherSel]
		ws:=settings.ssn("//workspace[@title='" selected "']")
		if ws{
			windows:=XPathNodes(ws,"descendant::window")
			Restore(windows,1)
		}
	}
return
LauncherClose:
9GuiEscape:
	Gui,9:Hide
	SetTimer,LauncherFocusCheck,Off
return
LauncherHitTest(wParam,lParam,msg,hwnd){
	global LauncherHwnd
	if(hwnd!=LauncherHwnd)
		return
	CoordMode,Mouse,Window
	MouseGetPos,,mouseY
	if(mouseY<=26)
		return 2
}