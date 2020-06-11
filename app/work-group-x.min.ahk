/*
:title:     bug.n-x.min/work-group
:copyright: (c) 2020 by joten <https://github.com/joten>
:license:   GNU General Public License version 3

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/

class WorkGroup {
  __New(index, workArea) {
		Global logger
		
		this.index := index		;; The index is relative to the current desktop.
		this.tilingAreas := []
		this.windows := []
		this.workArea := workArea
		logger.debug("Work group " . this.index . " created with work area ``" . this.workArea.x . "-" . this.workArea.y . "-" . this.workArea.w . "-" . this.workArea.h . "``.", "WorkGroup.__New")
	}
	
	activateWindow(index) {
		If (index > 0 && index <= this.windows.Length()) {
			this.windows[index].runCommand("activate")
		}
	}
	
	arrange() {
		Global logger
		
		If (this.windows.Length() > 1) {
			wnd := this.windows[1]
			wnd.getProperties()
			logger.debug("Window with id ``" . wnd.id . "`` found as the first window in group " . this.index . ".", "WorkGroup.arrange")
			this.getTilingAreas(wnd)
			windows := this.windows.Clone()
			logger.debug("Arranging " . windows.Length() . " window" . (windows.Length() == 1 ? "" : "s") . ".", "WorkGroup.arrange")
			For i in this.windows {
				If (i == this.tilingAreas.Length()) {
					this.tilingAreas[i].tile(windows)
				} Else {
					this.tilingAreas[i].tile([windows[1]])
					windows.RemoveAt(1)
				}
			}
		}
	}
	
	getTilingAreas(wnd) {
		Global logger
		
		;; Get sub-areas.
		rectangles := {}
		;; Minimal Windows Explorer width: 242px and height: h365px.
		For i, key in ["N", "W", "E", "S"] {
			x := Format("{:d}", wnd.x)
			y := Format("{:d}", wnd.y)
			w := Format("{:d}", wnd.w)
			h := Format("{:d}", wnd.h)
			If (key == "N") {
				y := Format("{:d}", this.workArea.y)
				h := Format("{:d}", wnd.y - this.workArea.y)
				condition := (h > 364)
			} Else If (key == "W") {
				x := Format("{:d}", this.workArea.x)
				w := Format("{:d}", wnd.x - this.workArea.x)
				condition := (w > 241)
			} Else If (key == "E") {
				x := Format("{:d}", wnd.x + wnd.w)
				w := Format("{:d}", (this.workArea.x + this.workArea.w) - (wnd.x + wnd.w))
				condition := (w > 241)
			} Else If (key == "S") {
				y := Format("{:d}", wnd.y + wnd.h)
				h := Format("{:d}", (this.workArea.y + this.workArea.h) - (wnd.y + wnd.h))
				condition := (h > 364)
			}
			If (condition) {
				rectangles[key] := New Rectangle(x, y, w, h)
				logger.debug("Rectangle **" . key . "** found with signature ``" . x . "-" . y . "-" . w . "-" . h . "``.", "WorkGroup.getTilingAreas")
			}
		}
		;; NW, NE, SW, SE
		For i, key in [["N", "W"], ["N", "E"], ["S", "W"], ["S", "E"]] {
			If (rectangles.HasKey(key[1]) && rectangles.HasKey(key[2])) {
				rectangles[key[1] . key[2]] := New Rectangle(rectangles[key[2]].x, rectangles[key[1]].y, rectangles[key[2]].w, rectangles[key[1]].h)
				logger.debug("Rectangle **" . key[1] . key[2] . "** found with key ``" . rectangles[key[2]].x . "-" . rectangles[key[1]].y . "-" . rectangles[key[2]].w . "-" . rectangles[key[1]].h . "``.", "WorkGroup.getTilingAreas")
			}
		}
		logger.debug(rectangles.Count() . " rectangle" . (rectangles.Count() == 1 ? "" : "s") . " found.", "WorkGroup.getTilingAreas")
		
		;; The last area pushed to the array must have a direction set other than "".
		If (rectangles.Count() == 0) {
			;; dwm monocle.
			this.tilingAreas := [New TilingArea(wnd, "z")]
			logger.debug("Layout **dwm monocle** set with " . this.tilingAreas.Length() . " area" . (this.tilingAreas.Length() == 1 ? "" : "s"), "WorkGroup.getTilingAreas")
		} Else If (rectangles.Count() == 1 && rectangles.HasKey("E")) {
			;; dwm tile.
			this.tilingAreas := [New TilingArea(wnd, "")]
			this.tilingAreas.push(New TilingArea(rectangles["E"], "y"))
			logger.debug("Layout **dwm tile** set with " . this.tilingAreas.Length() . " area" . (this.tilingAreas.Length() == 1 ? "" : "s"), "WorkGroup.getTilingAreas")
		} Else If (rectangles.Count() == 1 && rectangles.HasKey("W")) {
			;; dwm right master.
			this.tilingAreas := [New TilingArea(wnd, "")]
			this.tilingAreas.push(New TilingArea(rectangles["W"], "y"))
			logger.debug("Layout **dwm right master** set with " . this.tilingAreas.Length() . " area" . (this.tilingAreas.Length() == 1 ? "" : "s"), "WorkGroup.getTilingAreas")
		} Else If (rectangles.Count() == 1 && rectangles.HasKey("S")) {
			;; dwm bottom stack.
			this.tilingAreas := [New TilingArea(wnd, "")]
			this.tilingAreas.push(New TilingArea(rectangles["S"], "x"))
			logger.debug("Layout **dwm bottom stack** set with " . this.tilingAreas.Length() . " area" . (this.tilingAreas.Length() == 1 ? "" : "s"), "WorkGroup.getTilingAreas")
		} Else If (rectangles.Count() == 3 && rectangles.HasKey("S") && rectangles.HasKey("E") && rectangles.HasKey("SE")) {
			;; Two master windows with stack.
			this.tilingAreas := [New TilingArea(wnd, "")]
			this.tilingAreas.push(New TilingArea(rectangles["S"], ""))
			this.tilingAreas.push(New TilingArea(New Rectangle(rectangles["E"].x, rectangles["E"].y, rectangles["E"].w, rectangles["E"].h + rectangles["SE"].h), "y"))
			logger.debug("Layout **Two master windows with stack** set with " . this.tilingAreas.Length() . " area" . (this.tilingAreas.Length() == 1 ? "" : "s"), "WorkGroup.getTilingAreas")
		} Else {
			this.tilingAreas := [New TilingArea(wnd, "")]
			For i, rect in rectangles {
				this.tilingAreas.push(New TilingArea(rect, (i == rectangles.Length()) ? "z" : ""))
			}
			logger.debug("Layout **x** set with " . this.tilingAreas.Length() . " area" . (this.tilingAreas.Length() == 1 ? "" : "s"), "WorkGroup.getTilingAreas")
		}
	}
  
  getWindowIndex(wnd) {
    index := 0
    For i, item in this.windows {
      If (item.id == wnd.id) {
        index := i
        Break
      }
    }
    Return, index
  }
	
	moveWindowToPosition(wnd, pos) {
		If (pos.Length() == 4 
				&& pos[1] >= 0 && pos[1] <= 100
				&& pos[2] >= 0 && pos[2] <= 100
				&& pos[3] >= 0 && pos[3] <= 100
				&& pos[4] >= 0 && pos[4] <= 100) {
			wnd.move(Round(this.workArea.x + this.workArea.w * pos[1] / 100), Round(this.workArea.y + this.workArea.h * pos[2] / 100)
						 , Round(this.workArea.w * pos[3] / 100), Round(this.workArea.h * pos[4] / 100))
		}
	}
	
  removeWindow(wnd) {
		i := this.getWindowIndex(wnd)
		If (i > 0) {
			this.windows.RemoveAt(i)
			wnd.workGroup := ""
		}
  }
	
  setWindowIndex(wnd, index := 0) {
		Global logger
		
		index := (index < 1) ? this.windows.Length() + index + 1 : index
		i := this.getWindowIndex(wnd)
		If (i > 0) {
			this.windows.RemoveAt(i)
		}
		If (index > 0 && index <= this.windows.Length() + 1) {
			this.windows.InsertAt(index, wnd)
			wnd.workGroup := this
			logger.debug("Window with id ``" . wnd.id . "`` added to work group ``" . this.index . "`` at inde ``" . index . "``.", "WorkGroup.setWindowIndex")
		}
  }
}

class TilingArea extends Rectangle {
	__New(rect, direction := "") {
		;; direction: "x", (side-by-side), "y" (stack), "z" (deck), "" (none)
		this.x := rect.x
		this.y := rect.y
		this.w := rect.w
		this.h := rect.h
		this.direction := direction
	}
	
	tile(windows) {
		Global logger
		
		n := windows.Length()
		If (n > 0) {
			logger.debug("Tiling " . n . " window" . (n == 1 ? "" : "s") . ".", "TilingArea.tile")
			If (n > 1) {
				wndW := (this.direction == "x") ? Round(this.w / n) : this.w
				wndH := (this.direction == "y") ? Round(this.h / n) : this.h
				xIncrement := (this.direction == "x") ? wndW : 0
				yIncrement := (this.direction == "y") ? wndH : 0
				For i, wnd in windows {
					wnd.move(this.x + (i - 1) * xIncrement, this.y + (i - 1) * yIncrement, wndW, wndH)
				}
			} Else {
				windows[1].move(this.x, this.y, this.w, this.h)
			}
		}
	}
}
