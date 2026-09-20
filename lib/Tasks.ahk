;================================================================================
; Tasks
;================================================================================
AddTask(text, list := "T", status := "open") {
    text := Trim(RegExReplace(text, "[\r\n\t]+", " "))
    if (text = "")
        return
    CommitMark()                     ; anything pending belongs to another task
    Tasks.Push({list: list, text: text, status: status, carry: 0
              , born: LogicalDay(), due: "", asked: 0})
    SaveState()
    Refresh()
    ; The line is not written yet - see CommitMark(). Held for MarkDelayMs, it
    ; absorbs a typo fix or a delete made in the next few seconds.
    PendMark("T", Tasks.Length(), (status = "done") ? "unplanned" : "add")
}

; Renaming inside the grace window costs nothing: the task's line has not been
; written, and CommitMark() builds it from the CURRENT text, so a typo fixed
; seconds after typing it leaves no trace of the typo at all.
;
; Past the window the old name is already on disk. The journal is append-only -
; that is what makes it crash-proof and safe to edit in Obsidian - so the honest
; move is to record the change rather than pretend it never happened.
RenameTask(i, newText) {
    newText := Trim(RegExReplace(newText, "[\r\n\t]+", " "))
    if (!Tasks[i] || newText = "" || newText = Tasks[i].text)
        return
    old := Tasks[i].text
    Tasks[i].text := newText
    SaveState()
    Refresh()
    if (PendMarkKind = "T" && PendMarkTask = i)
        return
    Journal("~ renamed: " old "   " Chr(0x2192) "   " newText)
}

SetStatus(i, status) {
    if (!Tasks[i])
        return
    Tasks[i].status := status
    SaveState()
    Refresh()
}

