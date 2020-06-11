/*
:title:     bug.n/custom

This file should include (`#Include`)

* one of the modules\configuration\*.ahk files
* selected modules\layouts\*-layout.ahk files
* selected modules\user-interfaces\*-user-interface.ahk files

and any additional custom code (functions or modules). This file itself is included at 
the end of the main script and after the auto-execute section.
The class `Customizations` is instantiated after the class `Configuration` given by 
`#Include, %A_ScriptDir%\modules\configuration\*.ahk`, which allows overwriting 
configuration variables by putting them in `__New`. The function 
`Customizations._init` is called at the end of the auto-execute section, therewith 
commands can be executed after bug.n started by putting them in there.
*/

#Include, %A_ScriptDir%\modules\configuration\default.ahk

#Include, %A_ScriptDir%\modules\layouts\dwm-bottom-stack-layout.ahk
#Include, %A_ScriptDir%\modules\layouts\dwm-monocle-layout.ahk
#Include, %A_ScriptDir%\modules\layouts\dwm-tile-layout.ahk
#Include, %A_ScriptDir%\modules\layouts\floating-layout.ahk
#Include, %A_ScriptDir%\modules\layouts\i3wm-layout.ahk
;; If you remove one of the `layouts\*-layout.ahk` includes above and are using the `configuration\default`, 
;; you will also have to remove the corresponding item from `cfg.defaultLayouts` by redefining it below.

#Include, %A_ScriptDir%\modules\user-interfaces\tray-icon-user-interface.ahk
#Include, %A_ScriptDir%\modules\user-interfaces\app-user-interface.ahk
#Include, %A_ScriptDir%\modules\user-interfaces\system-status-bar-user-interface.ahk
;; If you remove one of the `user-interfaces\*-user-interface.ahk` includes above and are using the `configuration\default`,
;; you will also have to remove the corresponding item from `cfg.userInterfaces` by redefining it below.

;; Custom code.
class Customizations {
  __New() {
    Global cfg, logger
		
    ;; Overwrite cfg.* variables.
    ;; If (A_ComputerName == <computer name>) {
    ;; }
    
    logger.info("<b>Custom</b> configuration loaded.", "Customizations.__New")
  }
  
  _init() {
    Global mgr
    
    ;; Overwrite hotkeys.
    ;; funcObject := ObjBindMethod(mgr, <function name> [, <function arguments>])
    ;; Hotkey, <key name>, %funcObject%
  }
}
