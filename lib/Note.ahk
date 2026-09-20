;================================================================================
; The note box - opens flush against the row it belongs to, so it reads as part
; of that task rather than as a dialog that appeared somewhere.
;================================================================================
BuildNote() {
    global
    Gui, Note:New, +AlwaysOnTop -Caption +ToolWindow +HwndNoteHwnd
    ShapeWindow(NoteHwnd, PanelRound)    ; the same corners as the panel
    Gui, Note:Margin, 12, 10
    Gui, Note:Color, %CBg%, %CCard%
    Gui, Note:Font, s8 Norm, Segoe UI
    Gui, Note:Add, Text, vNoteHdr w300 c%CAmber%,
    Gui, Note:Font, s10, Segoe UI
    Gui, Note:Add, Edit, vNoteEdit w300 h26 c%CText% -E0x200
    Gui, Note:Font, s8, Segoe UI
    Gui, Note:Add, Text, vNoteHint w300 c%CDim%, % "Enter save  " Chr(0x00B7) " Esc skip"
}

ShowNote(header, rowY := 0) {
    global
    GuiControl, Note:, NoteEdit,
    GuiControl, Note:, NoteHdr, %header%
    LivePanel(px, py, pw, ph)
    w := (pw > NoteW) ? pw : NoteW
    GuiControl, Note:Move, NoteEdit, % "w" (w - 24)
    GuiControl, Note:Move, NoteHdr,  % "w" (w - 24)
    GuiControl, Note:Move, NoteHint, % "w" (w - 24)
    x := px - w - 8                       ; beside the panel, on whichever side
    if (x < 10)                           ; has room
        x := px + pw + 8
    y := py + (rowY ? rowY - 8 : 40)      ; level with the row it belongs to
    ClampWin(x, y, w, 96)
    Gui, Note:Show, x%x% y%y% AutoSize, Daybook note
    GuiControl, Note:Focus, NoteEdit
}

OpenNote(i, mode, rowY := 0) {
    ShowNote((mode = "failed") ? "what blocked it?  (optional)"
                               : "anything worth remembering?  (optional)", rowY)
}

#IfWinActive Daybook note ahk_class AutoHotkeyGUI
Enter::SaveNote()
NumpadEnter::SaveNote()
Escape::SkipNote()
#IfWinActive

SaveNote() {
    GuiControlGet, txt, Note:, NoteEdit
    Gui, Note:Hide
    txt := Trim(txt)
    if (txt != "") {
        CommitMark()          ; you typed something, so you meant the mark
        JournalNote(txt)
    }
    if (ReviewIdx)
        NextReview()
}

SkipNote() {
    Gui, Note:Hide
    if (ReviewIdx)
        NextReview()
}

