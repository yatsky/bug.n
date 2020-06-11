/*
:title:     bug.n-x.min/configuration/custom-example

This file should include one of the configuration\*.ahk files as a template and any addi-
tional custom code (functions or modules). The file itself is included at the end of the 
main script and after the auto-execute section. The class `Customizations` is instantia-
ted after the class `Configuration` given, which allows overwriting configuration vari-
ables by putting them in `__New`. The function `Customizations._init` is called at the 
end of the auto-execute section, therewith commands can be executed after bug.n x.min 
started by putting them in there.
*/

#Include, %A_ScriptDir%\configuration\default.ahk

;; Custom code.
class Customizations {
  __New() {
    Global cfg, logger
		
    ;; Overwrite cfg.* variables.
    ;; If (A_ComputerName == <computer name>) {
    ;; }
		cfg.positions[11] := [  0,   0,  70, 100]	;; left 0.70
		this.environments := {ofc: [{id: "Kalender.* ahk_exe OUTLOOK.EXE", 			  					  workGroup: 1}
															, {id: "Posteingang.* ahk_exe OUTLOOK.EXE",     													position: 10}
															, {id: ".*Mozilla Firefox ahk_exe firefox.exe", 						workGroup: 2, position: 10}]
												, dev: [{id: ".*bug\.n.* ahk_exe explorer.exe", 			desktop: 2, workGroup: 1}
															, {id: ".*Textadept.* ahk_exe textadept.exe", 	desktop: 2, 							position: 11}]}
		
    SysGet, n, MonitorCount
		If (n > 1) {
			cfg.workAreas := [New Rectangle(   0,  30, 1680, 1020)
											, New Rectangle(1680, 656, 1200,  770)]
		}
		
    logger.info("**Custom** configuration loaded.", "Customizations.__New")
  }
  
  _init() {
    Global mgr
		
		mgr.switch("desktop", 1)
		this.setEnvironment("ofc")
		
    ;; Overwrite hotkeys.
    ;; funcObject := ObjBindMethod(mgr, <function name> [, <function arguments>])
    ;; Hotkey, <key name>, %funcObject%
  }
	
	setEnvironment(key) {
    Global mgr
		
		SetTitleMatchMode, RegEx
		For i, object in this.environments[key] {
			WinGet, winId, ID, % object.id
			winId := Format("0x{:x}", winId)
			If (object.HasKey("desktop")) {
				mgr.moveWindowToDesktop(winId, object.desktop)
			}
			If (object.HasKey("workGroup")) {
				mgr.moveWindowToWorkGroup(winId, object.workGroup)
			}
			If (object.HasKey("position")) {
				mgr.moveWindowToPosition(winId, object.position)
			}
		}
		SetTitleMatchMode, 3
	}
}

#+f::mgr.moveWindowToPosition(, 11)
#^d::custom.setEnvironment("dev")
#^o::custom.setEnvironment("ofc")
