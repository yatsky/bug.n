/*
:title:     bug.n-x.min/general-manager
:copyright: (c) 2019-2020 by joten <https://github.com/joten>
:license:   GNU General Public License version 3

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/

class GeneralManager {
  __New() {
		Global app, cfg, logger
		
		this.uiface := ""
    this.windows := {}
		this.workAreas := []
		this.workGroups := []
    
    ;; Initialize monitors and work areas.
    this.mMgr := New MonitorManager()
    this.detectTaskbars()
		If (cfg.HasKey("workAreas")) {
			this.workAreas := cfg.workAreas
		} Else {
			For i, m in this.mMgr.monitors {
				this.workAreas.push(m.monitorWorkArea)
			}
		}
		
    ;; Initialize desktops.
    this.dMgr := New DesktopManager(ObjBindMethod(this, "_onTaskbarCreated"))
		n := this.dMgr.getDesktopCount()
		logger.info(n . " desktop" . (n == 1 ? "" : "s") . " found.", "GeneralManager.__New")
		
		;; Initialize work groups.
		Loop, % this.dMgr.getDesktopCount() {
			i := A_Index
			this.workGroups[i] := []
			For j, rect in this.workAreas {
				this.workGroups[i][j] := New WorkGroup(j, rect)
				logger.debug("Work group ``" . j . "`` added to desktop ``" . i . "``.", "GeneralManager.__New")
			}
		}
		
		;; Initialize the user interface.
    this.uiface := New UserInterface(1)
		this.uiface["tip"] := app.name
		this.uiface["icon"] := app.logo
		this.uiface._init()
  }
  
  __Delete() {
    this.dMgr := ""
  }
  
  _onTaskbarCreated(wParam, lParam, msg, winId) {
    Global logger
    
    ;; Restart the virtual desktop accessor, when Explorer.exe crashes or restarts (e.g. when coming from a fullscreen game).
    result := this.dMgr.restartVirtualDesktopAccessor()
    If (result > 0) {
      logger.error("Restarting _virtual desktop accessor_ after a crash or restart of Explorer.exe failed.", "GeneralManager._onTaskbarCreated")
    } Else {
      logger.warning("_virtual desktop accessor_ restarted due to a crash or restart of Explorer.exe.", "GeneralManager._onTaskbarCreated")
    }
  }
	
	closeWindow(winId := 0) {
		wnd := this.getWindow(winId)
		If (IsObject(wnd.workGroup)) {
			grp := wnd.workGroup
			grp.removeWindow(wnd)
			grp.arrange()
		}
		wnd.runCommand("close")
	}
	
	getIndex(curIndex, delta, maxIndex, sequence := "closed") {
		;; Return a valid index, i.e. between 1 and maxIndex, starting at `curIndex`, in- or decreasing by `delta`,
		;; either not exceeding the lower or upper bound (sequence == "closed"),
		;; circling, i.e. resetting it to the lower or upper bound respectively by delta (sequence == "circle")
		;; or exceeding the upper bound (sequence == "half-open").
		Global logger
		
		index := curIndex
		If (sequence == "circle") {
			;; upper bound = maxIndex, lower bound = 1
			lowerBoundBasedIndex := Mod(index - 1 + delta, maxIndex)
			If (lowerBoundBasedIndex < 0) {
				lowerBoundBasedIndex += maxIndex
			}
			index := 1 + lowerBoundBasedIndex
		} Else {
			index += delta
		}
		index := Min(Max(index, 1), maxIndex + (sequence == "half-open" ? 1 : 0))
		logger.debug(curIndex . " +(" . delta . ") < " . maxIndex . " = " . index . " (" . sequence . ")", "GeneralManager.getIndex")
		
		Return, index
	}
	
	getIndices(objectType, wnd, index, delta, sequence) {
		Global cfg, logger
		
		d := this.dMgr.getCurrentDesktopIndex()
		g := (wnd != "" && wnd.workGroup != "") ? wnd.workGroup.index : 1 ;; this.getWorkGroup("empty", d)
		If (objectType == "desktop") {
			A := d
			n := this.dMgr.getDesktopCount()
		} Else If (objectType == "position") {
			A := 0
			n := cfg.positions.Length()
		} Else If (objectType == "window") {
			A := this.workGroups[d][g].getWindowIndex(wnd)
			n := this.workGroups[d][g].windows.Length()
		} Else If (objectType == "workGroup") {
			A := g
			n := this.workGroups[d].Length()
		} Else If (objectType == "workArea") {
			A := this.getCurrentWorkAreaIndex(wnd)
			n := this.mMgr.monitors.Length()
		}
		i := this.getIndex((index == 0) ? A : index, delta, n, sequence)
		logger.debug(objectType . " [" . d . ", " . g . "] " . index . " =0? | " . A . " +(" . delta . ") < " . n . " = " . i . " (" . sequence . ")", "GeneralManager.getIndices")
		
		Return, {cur: A, new: i, max: (i == n + 1 ? i : n), dsk: d, grp: g}
	}
  
  getWindow(winId := 0) {
    winId := Format("0x{:x}", (winId == 0 ? WinExist("A") : winId))
    wnd := ""
    If (this.windows.HasKey(winId)) {
      wnd := this.windows[winId]
      wnd.update()
    } Else {
      wnd := New Window(winId)
      this.windows[wnd.id] := wnd
    }
    Return, wnd
  }
	
	getCurrentWorkAreaIndex(wnd) {
		index := 0
		For i, rect in this.workAreas {
			If (rect.match(wnd)) {
				index := i
				Break
			}
		}
		Return, index
	}
	
	getWorkGroup(condition, desktopIndex, sequence := "half-open") {
		index := 0
		If (condition == "empty") {
			For i, grp in this.workGroups[desktopIndex] {
				If (grp.windows.Length() == 0) {
					index := i
					Break
				}
			}
			If (index == 0 && sequence == "half-open") {
				index := this.workGroups[desktopIndex].Length() + 1
				this.workGroups[desktopIndex][index] := New WorkGroup(index, this.workAreas[1])
			}
		}
		Return, index
	}
	
	pinWindowToDesktops(winId := 0, withWorkGroup := False) {
		wnd := this.getWindow(winId)
		windows := (withWorkGroup && IsObject(wnd.workGroup)) ? wnd.workGroup.windows : [wnd]
		For i, wnd in windows {
			this.dMgr.pinWindow(wnd.id)
		}
	}
	
  showWindowInformation(winId := 0) {
    Global app
    
    wnd := this.getWindow(winId)
    MsgBox, 3, % app.name . ": Window Information", % wnd.information . "`n`nCopy window information to clipboard?"
    IfMsgBox Yes
      Clipboard := wnd.information
  }
  
  toggleWindowHasCaption(winId := 0) {
    wnd := this.getWindow(winId)
    wnd.runCommand("toggleCaption")
    If (IsObject(wnd.workGroup)) {
      wnd.workGroup.arrange()
    }
  }
	
	switch(objectType, index := 0, delta := 0, sequence := "") {
		wnd := (objectType == "desktop") ? "" : this.getWindow()
		sequence := sequence == "" ? (objectType == "desktop" ? "closed" : "circle") : sequence
		idx := this.getIndices(objectType, wnd, index, delta, sequence)
		If (idx.new != idx.cur && idx.new > 0 && idx.new <= idx.max) {
			If (objectType == "desktop") {
				this.dMgr.goToDesktop(idx.new)
			} Else If (objectType == "window") {
				this.workGroups[idx.dsk][idx.grp].activateWindow(idx.new)
			} Else If (objectType == "workGroup") {
				n := this.workGroups[idx.dsk][idx.new].windows.Length()
				For i in this.workGroups[idx.dsk][idx.new].windows {
					this.workGroups[idx.dsk][idx.new].activateWindow(n - i + 1)
				}
			}
		}
	}
	
	;; Move objects.
	moveWindowToDesktop(winId := 0, index := 0, delta := 0, sequence := "half-open", withWorkGroup := False) {
		wnd := this.getWindow(winId)
		idx := this.getIndices("desktop", wnd, index, delta, sequence)
		If (idx.new > this.dMgr.getDesktopCount()) {
			this.dMgr.createDesktop()
		}
		;; (wnd.workGroup == "" && !withWorkGroup) ? no need to remove the window from a work group, ...
		;; (wnd.workGroup == "" &&  withWorkGroup) ? ... just move the window to the new desktop
		;; (wnd.workGroup != "" && !withWorkGroup) ? remove the window from the current work group, but do not add it to a new one
		;; (wnd.workGroup != "" &&  withWorkGroup) ? move all windows from the group by removing the window from the current and adding it to a new, empty one
		If ((idx.new != idx.cur || winId != 0) && wnd.workGroup != "" && withWorkGroup) {
			g := this.getWorkGroup("empty", idx.new)
			this.workGroups[idx.new][g].workArea := this.workAreas[this.getCurrentWorkAreaIndex(wnd)]
		}
		windows := (wnd.workGroup != "" && withWorkGroup) ? wnd.workGroup.windows : [wnd]
		For i, wnd in windows {
			If (this.dMgr.isPinnedWindow(wnd.id) == 1) {
				this.dMgr.unPinWindow(wnd.id)
			}
			grp := wnd.workGroup
			If ((idx.new != idx.cur || winId != 0) && grp != "") {
				grp.removeWindow(wnd)
				If (!withWorkGroup) {
					grp.arrange()
				} Else If (g > 0) {
					this.workGroups[idx.new][g].setWindowIndex(wnd)
				}
			}
			this.dMgr.moveWindowToDesktop(wnd.id, idx.new)
		}
		If (wnd.workGroup != "" && withWorkGroup && g > 0) {
			this.workGroups[idx.new][g].arrange()
		}
	}
	
	moveWindowToPosition(winId := 0, index := 0, delta := 0, sequence := "closed") {
		;; The current position is not defined, therefor `delta` is not really implemented!
		Global cfg, logger
		
		wnd := this.getWindow(winId)
		idx := this.getIndices("position", wnd, index, delta, sequence)
		logger.debug("Moving window with id ``" . wnd.id . "`` to position ``" . idx.new . "`` (``"
			. cfg.positions[idx.new][1] . "-" . cfg.positions[idx.new][2] . "-"
			. cfg.positions[idx.new][3] . "-" . cfg.positions[idx.new][4] . "``).", "GeneralManager.moveWindowToPosition")
		this.workGroups[idx.dsk][idx.grp].moveWindowToPosition(wnd, cfg.positions[idx.new])
		this.workGroups[idx.dsk][idx.grp].setWindowIndex(wnd, 1)
		this.workGroups[idx.dsk][idx.grp].arrange()
	}
	
	moveWindowInWorkGroup(winId := 0, index := 0, delta := 0, sequence := "circle") {
		Global logger
		
		wnd := this.getWindow(winId)
		sequence := (sequence == "half-open") ? "circle" : sequence
		idx := this.getIndices("window", wnd, index, delta, sequence)
		If (idx.new != idx.cur) {
			logger.debug("Moving window with id ``" . wnd.id . "`` from index ``" . idx.cur . "`` to ``" . idx.new . "``.", "GeneralManager.moveWindowInWorkGroup")
			If (idx.new == 1) {
				rect := this.workGroups[idx.dsk][idx.grp].windows[1]
				wnd.move(rect.x, rect.y, rect.w, rect.h)
			} Else If (idx.cur == 1) {
				this.workGroups[idx.dsk][idx.grp].windows[2].move(wnd.x, wnd.y, wnd.w, wnd.h)
			}
			this.workGroups[idx.dsk][idx.grp].setWindowIndex(wnd, idx.new)
			this.workGroups[idx.dsk][idx.grp].arrange()
		}
	}
	
	moveWindowToWorkGroup(winId := 0, index := 0, delta := 0, sequence := "half-open", withWorkGroup := False) {
		Global logger
		
		wnd := this.getWindow(winId)
		idx := this.getIndices("workGroup", wnd, index, delta, sequence)
		If (idx.new > this.workGroups[idx.dsk].Length()) {
			If (wnd.workGroup != "" && wnd.workGroup.windows.Length() == 1) {
				idx.new := wnd.workGroup.index
			} Else {
				this.workGroups[idx.dsk][idx.new] := New WorkGroup(idx.new, this.mMgr.monitors[this.getCurrentWorkAreaIndex(wnd)])
				logger.debug("Work group ``" . idx.new . "`` added to desktop ``" . idx.dsk . "`` and work area ``" . this.getCurrentWorkAreaIndex(wnd) . "``.", "GeneralManager.moveWindowToWorkGroup")
			}
		}
		windows := (wnd.workGroup != "" && withWorkGroup) ? wnd.workGroup.windows : [wnd]
		logger.debug("Moving " . windows.Length() . " window" . (windows.Length() == 1 ? "" : "s") . " to work group ``" . idx.new . "`` on desktop ``" . idx.dsk . "``.", "GeneralManager.moveWindowToWorkGroup")
		For i, wnd in windows {
			If (wnd.workGroup != "") {
				grp := wnd.workGroup
				grp.removeWindow(wnd)
				If (!withWorkGroup) {
					grp.arrange()
				}
			}
			this.workGroups[idx.dsk][idx.new].setWindowIndex(wnd)
		}
		this.workGroups[idx.dsk][idx.new].arrange()
	}
	
	moveWindowToWorkArea(winId := 0, index := 0, delta := 0, sequence := "closed", withWorkGroup := False, posIndex := 0) {
		Global cfg, logger
		
		wnd := this.getWindow(winId)
		idx := this.getIndices("workArea", wnd, index, delta, sequence)
		If (idx.new != idx.cur || winId != 0) {
			logger.debug("Moving window with id ``" . wnd.id . "`` to work area ``" . idx.new
				. "``, position ``" . (posIndex > 0 && posIndex <= cfg.positions.Length() ? posIndex : 1) . "``.", "GeneralManager.moveWindowToWorkArea")
			pos := (posIndex > 0 && posIndex <= cfg.positions.Length()) ? cfg.positions[posIndex] : cfg.positions[1]
			;; (wnd.workGroup == "" && !withWorkGroup) ? no need to remove the window from a work group, ...
			;; (wnd.workGroup == "" &&  withWorkGroup) ? ... but add it to a new or empty work group in any case in order to have a work area associated
			;; (wnd.workGroup != "" && !withWorkGroup) ? remove the window from the current work group and add it to a new one
			;; (wnd.workGroup != "" &&  withWorkGroup) ? move the whole group, no need to remove the window from it or find a new one
			If (wnd.workGroup == "" || !withWorkGroup) {
				g := this.getWorkGroup("empty", idx.dsk)
				this.workGroups[idx.dsk][g].workArea := this.workAreas[idx.new]
			} ;; Else If (wnd.workGroup != "" &&  withWorkGroup) g is the index of wnd.workGroup
			windows := (wnd.workGroup != "" && withWorkGroup) ? wnd.workGroup.windows : [wnd]
			For i, wnd in windows {
				grp := wnd.workGroup
				If (grp != "" && !withWorkGroup) {
					grp.removeWindow(wnd)
					grp.arrange()
				}
				If (grp == "" || !withWorkGroup) {
					this.workGroups[g].setWindowIndex(wnd)
					this.workGroups[g].moveWindowToPosition(wnd, pos)
					this.workGroups[g].arrange()
				} Else {	;; If (wnd.workGroup != "" &&  withWorkGroup)
					grp.workArea := this.workAreas[idx.new]
					grp.moveWindowToPosition(wnd, pos)
					grp.setWindowIndex(wnd, 1)
					grp.arrange()
				}
			}
		}
	}
}

class Rectangle {
  ;; A rectangle must have the following properties: x (x-coordinate), y (y-coordinate), w (width), h (height)
  __New(xCoordinate, yCoordinate, width := 0, height := 0) {
    this.x := xCoordinate
    this.y := yCoordinate
    this.w := width
    this.h := height
  }
  
  match(rect, dimensions := False, exhaustively := False, variation := 2) {
    ;; If `exactness == 0`, this function tests if the center of `rect` is inside `Rectangle`,
    ;; else it tests if `rect` has the position and size as `Rectangle` in the limits of `exactness`.
    ;; `exactness` should therefor be equal or greater than 0.
    Global logger
    
    result := False
    If (dimensions) {
      result := Abs(this.x - rect.x) < variation && Abs(this.y - rect.y) < variation && Abs(this.w - rect.w) < variation && Abs(this.h - rect.h) < variation
    } Else {
      coordinates := [{x: rect.x + rect.w / 2, y: rect.y + rect.h / 2}]
      If (exhaustively) {
        coordinates.push({x: rect.x + variation,          y: rect.y + variation})
        coordinates.push({x: rect.x + rect.w - variation, y: rect.y + rect.h - variation})
        coordinates.push({x: rect.x + variation,          y: rect.y + rect.h - variation})
        coordinates.push({x: rect.x + rect.w - variation, y: rect.y + variation})
      }
      For i, coord in coordinates {
        If (result := coord.x >= this.x && coord.y >= this.y && coord.x <= this.x + this.w && coord.y <= this.y + this.h) {
          logger.debug("Rectangle " . (this.HasKey("id") ? "with id " . this.id . " " : "") . "(" . this.x . ", " . this.y . ", " . this.w . ", " . this.h
                                                       . ") matches coordinates (" . i . ": " . coord.x . ", " . coord.y . ", " . coord.w . ", " . coord.h . ")"
                                                       . (this.HasKey("id") ? " from " . this.id : "") . ".", "Rectangle.match")
          Break
        }
      }
    }
    Return, result
  }
}
