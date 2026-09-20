;================================================================================
; Panel events
;================================================================================
DragPanel:
    if (!Ghost() && !PanelLocked)
        PostMessage, 0xA1, 2, , , ahk_id %PanelHwnd%    ; WM_NCLBUTTONDOWN, HTCAPTION
Return

; SaveIni() writes the position as well as the flag, so locking pins the spot
; the panel is standing on at the moment you press it.
LockClick:
    PanelLocked := !PanelLocked
    SaveIni()
    SetLockBtn()
Return

ModeClick:
    SetPanelMode(PanelMode = 0 ? 1 : 0)
Return

TopClick:
    ToggleOnTop()
Return

ToggleToday:
    OpenToday := !OpenToday
    SaveIni()
    Relayout()
Return

ToggleLong:
    OpenLong := !OpenLong
    SaveIni()
    Relayout()
Return

ToggleStats:
    OpenStats := !OpenStats
    SaveIni()
    Relayout()
Return

ToggleHabits:
    OpenHabits := !OpenHabits
    SaveIni()
    Relayout()
Return

; The + carries what the separate dot used to: if yesterday is still owed an
; answer, pressing it starts that review; otherwise it just opens capture.
AddClick:
    if (ReviewQueue.Length())
        StartReview()
    else
        QuickAdd("T")
Return

LongAddClick:
    QuickAdd("L")
Return

HabAddClick:
    QuickAdd("H")
Return

; One click is the whole interaction: tick today off, or take it back. There is
; no cross and no note box - a habit you did not do today is simply not ticked,
; and tomorrow it asks again.
HabChkClick:
    HabitToggle(HabRow[SubStr(A_GuiControl, 7)])
Return

BreakClick:
    ToggleBreak()
Return

RowChkClick:
    RowAction(SubStr(A_GuiControl, 7), "done")
Return

RowXClick:
    RowAction(SubStr(A_GuiControl, 5), "failed")
Return

; Right-click anywhere on a row.
;
; This used to read A_GuiControl and pick the row out of the control's name.
; That quietly broke the moment RowTxt lost its g-label: without one a Static
; has no SS_NOTIFY, so it reports HTTRANSPARENT and the right-click is delivered
; to the PANEL instead of the label. A_GuiControl came back empty and the menu
; never opened - except directly on the tick box or the cross, which still had
; g-labels. Hence "sometimes it works".
;
; Hit-testing the pointer against the row rectangles has no such dependency: it
; works over the text, the glyphs and the empty part of the card alike.
PnlContextMenu:
    ctxCard := CardUnderCursor()
    if (ctxCard) {
        ctx := Cards[ctxCard]
        if (ctx.kind = "H" && HabRow[ctx.pool])
            HabMenu(HabRow[ctx.pool])
        else if (ctx.kind = "T" && RowTask[ctx.pool])
            RowMenu(RowTask[ctx.pool])
    }
Return

; Which card the pointer is over, as an index into Cards, or 0. Every card on
; the panel is in that one list whatever section it came from, so this answers
; for a habit exactly the way it answers for a task.
CardUnderCursor() {
    global PanelHwnd, Cards, RowH
    WinGetPos, px, py, , , ahk_id %PanelHwnd%
    if (px = "")
        return 0
    CoordMode, Mouse, Screen
    MouseGetPos, , my
    ry := my - py
    for k, card in Cards
        if (ry >= card.y && ry < card.y + RowH)
            return k
    return 0
}

RowAction(n, status) {
    i := RowTask[n]
    if (!i || !Tasks[i])
        return
    if (Tasks[i].status = status) {          ; clicking the same mark undoes it
        CancelMark("T", i)
        SetStatus(i, "open")
        return
    }
    CommitMark()                             ; a different row was still pending
    SetStatus(i, status)
    PendMark("T", i, status)
    OpenNote(i, status, RowY[n])
}

; A tick or a cross is NOT written to the journal at the moment you click it.
;
; The journal is append-only, which is what makes it crash-proof and safe to
; edit in Obsidian - but it also means a misclick is permanent, and unticking
; cannot take it back. So the line is held for MarkDelayMs first: undo inside
; that window and nothing is ever written. Past it the record stands, because by
; then it was a decision rather than a slip.
;
; Esc on the note box deliberately does NOT commit early. It only means "no
; note"; the grace period keeps running, so Esc is still undoable.
; Start the clock on one. Only ever one thing is pending at a time, so whoever
; calls this has already flushed or cancelled whatever was there before.
PendMark(kind, i, status) {
    global PendMarkKind, PendMarkTask, PendMarkStatus, MarkDelayMs
    PendMarkKind := kind, PendMarkTask := i, PendMarkStatus := status
    SetTimer, MarkTick, % -MarkDelayMs
}

CommitMark() {
    if (!PendMarkTask)
        return
    kind := PendMarkKind, i := PendMarkTask, st := PendMarkStatus
    PendMarkKind := "", PendMarkTask := 0, PendMarkStatus := ""
    SetTimer, MarkTick, Off
    if (kind = "H") {
        h := Habits[i]
        ; unticked again inside the window, or deleted: it never happened
        if (!h || !HabitDidToday(h))
            return
        Journal(Chr(0x2713) " habit: " h.text "   " Chr(0x00B7) " " h.streak " in a row")
        return
    }
    if (!Tasks[i])                  ; deleted inside the window: it never happened
        return
    t := Tasks[i]
    ; built from the task as it stands NOW, which is what lets a rename inside
    ; the window correct the line before it is ever written
    if (st = "add")
        Journal("+ added: " t.text ((t.list = "L") ? "   [long term]" : ""))
    else if (st = "unplanned")
        Journal(Chr(0x2713) " (unplanned) " t.text)
    else if (t.status = st)         ; changed its mind in the meantime: drop it
        Journal((st = "done" ? Chr(0x2713) : Chr(0x2717)) " " t.text)
}

; True if there WAS one to cancel, which is how a caller tells "undone inside
; the grace window, so write nothing" from "undone later, so say so".
CancelMark(kind, i) {
    global PendMarkKind, PendMarkTask, PendMarkStatus
    if (PendMarkKind != kind || PendMarkTask != i)
        return false
    PendMarkKind := "", PendMarkTask := 0, PendMarkStatus := ""
    SetTimer, MarkTick, Off
    return true
}

RowMenu(i) {
    global MenuTask
    MenuTask := i
    Menu, Row, Add, placeholder, MenuNoop     ; so DeleteAll cannot fail first time
    Menu, Row, DeleteAll
    Menu, Row, Add, Rename, MenuRename
    Menu, Row, Add, % (Tasks[i].list = "T" ? "Move to Long term" : "Move to Today"), MenuMove
    Menu, Row, Add, Delete, MenuDelete
    Menu, Row, Show
}

; Right-click a habit. Deleting one throws its streak away, which is a real
; loss, so it lives in a menu rather than beside the tick box.
HabMenu(i) {
    global MenuHabit
    MenuHabit := i
    Menu, Hab, Add, placeholder, MenuNoop     ; so DeleteAll cannot fail first time
    Menu, Hab, DeleteAll
    Menu, Hab, Add, Rename, MenuHabRename
    Menu, Hab, Add, Delete habit, MenuHabDelete
    Menu, Hab, Show
}

MenuHabRename:
    StartHabitRename(MenuHabit)
Return

MenuHabDelete:
    HabitDelete(MenuHabit)
Return

MenuNoop:
Return

MenuRename:
    StartRename(MenuTask)
Return

MenuMove:
    Tasks[MenuTask].list := (Tasks[MenuTask].list = "T") ? "L" : "T"
    SaveState()
    Refresh()
Return

MenuDelete:
    ; Added and dropped inside the grace window: it never happened, so nothing
    ; is written at all - not the add, not the drop. Otherwise flush whatever
    ; was pending (it belongs to a different task) and record the drop.
    ; Either way nothing stays pending, which matters: RemoveAt shifts every
    ; index above it and a pending one would then point at the wrong task.
    if (!CancelMark("T", MenuTask)) {
        CommitMark()
        Journal("- dropped: " Tasks[MenuTask].text)
    }
    Tasks.RemoveAt(MenuTask)
    SaveState()
    Refresh()
Return

; Opacity, and the row under the pointer. Polled rather than driven by
; WM_MOUSEMOVE, because the message that matters - the mouse LEAVING - never
; arrives, and in click-through mode no mouse messages arrive at all.
HoverCheck() {
    global Hot, HotCard
    if (!PanelVisible)
        return
    WinGetPos, px, py, pw, ph, ahk_id %PanelHwnd%
    if (px = "")
        return
    CoordMode, Mouse, Screen
    MouseGetPos, mx, my
    inside := (mx >= px && mx <= px + pw && my >= py && my <= py + ph)

    if (inside != Hot) {
        Hot := inside
        ; SOLID does not move at all, DIM comes forward, GHOST retreats
        a := !inside ? RestAlpha() : HotAlpha()
        WinSet, Transparent, %a%, ahk_id %PanelHwnd%
    }

    want := (inside && !Ghost()) ? CardUnderCursor() : 0
    if (want != HotCard) {
        was := HotCard
        HotCard := want                ; set first: OnErase reads it when painting
        InvalidateCard(was)
        InvalidateCard(want)
    }
}

TogglePanel() {
    global PanelVisible
    if (PanelVisible) {
        SaveIni()
        Gui, Panel:Hide
        PanelVisible := 0
    } else
        ShowPanel()
}

; Win+F6: hidden -> SOLID -> DIM -> GHOST -> hidden, one step a press. Coming
; back from hidden always lands on SOLID, the mode you can read and click.
CyclePanel() {
    global PanelVisible, PanelMode
    if (!PanelVisible) {
        PanelMode := 0
        SetTrayMode()
        ShowPanel()                     ; applies the mode on its way up
        SaveIni()
    } else if (PanelMode = 2) {
        TogglePanel()
    } else {
        SetPanelMode(PanelMode + 1)
    }
}

