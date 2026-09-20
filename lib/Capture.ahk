;================================================================================
; Quick capture - the whole point is that this takes under two seconds
;================================================================================
BuildCapture() {
    global
    Gui, Cap:New, +AlwaysOnTop -Caption +ToolWindow +HwndCapHwnd
    ShapeWindow(CapHwnd, PanelRound)     ; the same corners as the panel
    Gui, Cap:Margin, 12, 10
    ; The SECOND parameter is the one that matters. A per-control
    ; "Background" option is silently ignored on an Edit, which left a white
    ; box with near-white text in it - invisible while typing.
    Gui, Cap:Color, %CBg%, %CCard%
    Gui, Cap:Font, s10 Norm, Segoe UI
    Gui, Cap:Add, Edit, vCapEdit w360 h26 c%CText% -E0x200
    Gui, Cap:Font, s8, Segoe UI
    ; two lines on purpose: on one line this hint was wider than the panel, and
    ; AutoSize then stretched the whole box past it
    CapHintAdd := "Enter add   " Chr(0x00B7) " Shift+Enter already did it`n"
                . "Ctrl+Enter long term   " Chr(0x00B7) " Esc cancel"
    Gui, Cap:Add, Text, vCapHint w360 c%CDim%, %CapHintAdd%
}

; User-initiated, so this one DOES take focus - you just asked for somewhere to
; type. Nothing that appears on its own ever takes it.
QuickAdd(list := "T") {
    global CapMode, CapTask, CapList, CapHintAdd
    CapMode := "add", CapTask := 0
    CapList := list                        ; plain Enter goes to whichever list
    ; A habit has nowhere else to go, so the three-way hint would be a lie -
    ; every Enter here makes a habit. See CommitAdd().
    if (list = "H")
        ShowCapture("", "Enter  a habit, every day from now on   "
                      . Chr(0x00B7) "   Esc cancel")
    else
        ShowCapture("", CapHintAdd)        ; the + you pressed belongs to
}

; Renaming a habit goes through the same box as everything else, and back out
; through the same Enter - CommitAdd() sorts out which it was.
StartHabitRename(i) {
    global CapMode, CapTask, Habits
    if (!Habits[i])
        return
    CapMode := "habit", CapTask := i
    ShowCapture(Habits[i].text, "Enter save   " Chr(0x00B7) " Esc cancel")
}

; Rename reuses the capture box rather than growing another window: same place,
; same key, already prefilled.
StartRename(i) {
    global CapMode, CapTask
    if (!Tasks[i])
        return
    CapMode := "rename", CapTask := i
    ShowCapture(Tasks[i].text, "Enter save   " Chr(0x00B7) " Esc cancel")
}

ShowCapture(prefill, hint) {
    global
    GuiControl, Cap:, CapEdit, %prefill%
    GuiControl, Cap:, CapHint, %hint%
    LivePanel(px, py, pw, ph)
    w := (pw > CapW) ? pw : CapW
    GuiControl, Cap:Move, CapEdit, % "w" (w - 24)
    GuiControl, Cap:Move, CapHint, % "w" (w - 24)
    x := px + pw - w
    y := py
    ClampWin(x, y, w, 76)
    Gui, Cap:Show, x%x% y%y% AutoSize, Daybook capture
    GuiControl, Cap:Focus, CapEdit
    if (prefill != "") {                   ; caret at the end, nothing selected,
        GuiControlGet, hEd, Cap:Hwnd, CapEdit    ; so you can tweak rather than
        SendMessage, 0xB1, -1, -1, , ahk_id %hEd%   ; retype (EM_SETSEL)
    }
}

; The panel's ACTUAL position right now.
;
; PanelX/PanelY are only rewritten when something gets saved, so anything that
; positions itself against the panel has to ask the window rather than trust the
; variables - otherwise, after you drag the panel, these boxes keep opening at
; the old spot until you happen to collapse a section.
LivePanel(ByRef x, ByRef y, ByRef w, ByRef h) {
    global PanelHwnd, PanelX, PanelY, PanelW, PanelH
    WinGetPos, x, y, w, h, ahk_id %PanelHwnd%
    if (x = "")
        x := PanelX, y := PanelY, w := PanelW, h := PanelH
}

; Keep a popup inside the monitor it sits on. The panel lives against a screen
; edge by design, so a box placed relative to it will hang off the side unless
; something pulls it back.
ClampWin(ByRef x, ByRef y, w, h) {
    SysGet, count, MonitorCount
    best := 0
    cx := x + w // 2
    Loop % count {
        SysGet, m, MonitorWorkArea, %A_Index%
        if (cx >= mLeft && cx <= mRight && y >= mTop && y <= mBottom) {
            best := A_Index
            break
        }
    }
    SysGet, m, MonitorWorkArea, % best ? best : 1
    if (x + w > mRight)
        x := mRight - w
    if (x < mLeft)
        x := mLeft
    if (y + h > mBottom)
        y := mBottom - h
    if (y < mTop)
        y := mTop
}

#IfWinActive Daybook capture ahk_class AutoHotkeyGUI
Enter::CommitAdd("", "open")
NumpadEnter::CommitAdd("", "open")
+Enter::CommitAdd("T", "done")
+NumpadEnter::CommitAdd("T", "done")
^Enter::CommitAdd("L", "open")
^NumpadEnter::CommitAdd("L", "open")
Escape::CloseCapture()
#IfWinActive

CommitAdd(list, status) {
    global CapMode, CapTask, CapList
    GuiControlGet, txt, Cap:, CapEdit
    Gui, Cap:Hide
    if (CapMode = "rename") {              ; every Enter variant just saves here
        CapMode := "add"
        RenameTask(CapTask, txt)
        return
    }
    if (CapMode = "habit") {
        CapMode := "add"
        HabitRename(CapTask, txt)
        return
    }
    if (list = "")
        list := CapList
    ; Opened from the HABITS +, so Shift and Ctrl have nothing to offer: there
    ; is no other list to put it in and no such thing as a habit you already did.
    if (CapList = "H") {
        HabitAdd(txt)
        return
    }
    AddTask(txt, list, status)
}

CloseCapture() {
    global CapMode
    CapMode := "add"
    Gui, Cap:Hide
}

