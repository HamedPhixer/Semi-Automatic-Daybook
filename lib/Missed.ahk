;================================================================================
; Missed - what a day ended without
;================================================================================
; When a day closes, whatever on Today's list was left open moves to MISSED.
; Nothing is decided for you there: a task waits until you say what happened,
; and the section is not on the panel at all while it is empty. Each row has
; three buttons:
;
;   tick   did it - a menu of the days since it was missed, and it is recorded
;          as done on the day you pick. A past day's note is rewritten to say so.
;   cross  drop it - asks why first, and Esc keeps it, so a misclick costs
;          nothing.
;   arrow  back onto Today's list - asks, once, why it was not done. However
;          many days it waited, it is one question, and the answer goes onto
;          the day it was meant for.
;
; t.since is that day - the last day it was on Today's list and not done.
; t.carry is how many days it has been left undone in all: the xN before its
; name.
;
; This replaced the review queue, where the amber + asked "not done yesterday -
; why?" of every carried task. That queue was easy to miss, forgot its question
; if a day went by unanswered, and had no way to say "I did it, I just did not
; tick it".
;================================================================================

; The note a finished day holds for this task - what the box opens with, so
; answering again changes it rather than piling a second one on.
PastNote(id, day) {
    global Past
    for _, r in Past
        if (r.id = id && r.day = day)
            return r.note
    return ""
}

; Where the pool row showing this task is now, for the note box to open level
; with it - 0 when it is scrolled off or the section is closed.
RowYOf(i) {
    global RowTask, RowY
    for n, ti in RowTask
        if (ti = i)
            return RowY[n]
    return 0
}

;--------------------------------------------------------------------------------
; tick: which day was it done?
;--------------------------------------------------------------------------------
; Today, then back a day at a time to the day it was missed - two weeks at
; most, and never past what Past still holds, since that is what lets an
; earlier day's note be rewritten.
MissDidMenu(i) {
    global MissMenuId, MissMenuDays, PastKeepDays
    t := Tasks[i]
    if (!t)
        return
    today := LogicalDay()
    from := (t.since != "" && t.since < today) ? t.since : DayShift(today, -1)
    MissMenuId := t.id, MissMenuDays := {}
    Menu, Did, Add, placeholder, MenuNoop     ; so DeleteAll cannot fail first time
    Menu, Did, DeleteAll
    Menu, Did, Add, did it on..., MenuNoop
    Menu, Did, Disable, did it on...
    Menu, Did, Add
    day := today
    Loop % (PastKeepDays < 14 ? PastKeepDays : 14) {
        name := MissDayName(day)
        MissMenuDays[name] := day
        Menu, Did, Add, %name%, MenuMissDid
        if (day <= from)
            break
        day := DayShift(day, -1)
    }
    Menu, Did, Show
}

MenuMissDid:
    MissDone(MissMenuId, MissMenuDays[A_ThisMenuItem])
Return

; Done today: it goes onto Today's list ticked, like any task done today, and
; leaves at the end of the day. Done on an earlier day: it goes onto THAT day
; and off the panel - it is finished, and the day's note has it.
MissDone(id, day) {
    global Past, CurDay, NoteFor
    i := TaskIndex(id)
    if (!i || day = "")
        return
    CommitMark()                         ; see DeleteTask - indices are about to move
    t := Tasks[i]
    if (day = CurDay) {
        t.list := "T", t.status := "done", t.doneOn := CurDay
        Journal(Chr(0x2713) " " t.text "   (missed " MissSinceText(t.since) ")")
        SaveState()
        Refresh()
        OpenNote(i, "done", RowYOf(i))
        return
    }
    found := false
    for _, r in Past
        if (r.id = id && r.day = day)
            r.status := "done", found := true
    if (!found)
        Past.Push({day: day, id: id, list: "T", status: "done", carry: t.carry
                 , note: "", text: t.text})
    Journal(Chr(0x2713) " " t.text "   (done " day ", ticked late)")
    Tasks.RemoveAt(i)
    SaveState()
    Refresh()
    DayNoteWrite(day, true)
    NoteFor := {id: id, day: day}
    ShowNote("done " MissDayName(day) " - anything worth remembering?  (optional)"
           , 0, PastNote(id, day))
}

;--------------------------------------------------------------------------------
; cross: drop it
;--------------------------------------------------------------------------------
; The box comes first and the drop only happens on Enter. Esc keeps the task,
; which is what makes the cross safe to have beside the tick.
MissDropAsk(i, rowY := 0) {
    global NoteFor
    t := Tasks[i]
    if (!t)
        return
    NoteFor := {id: t.id, day: t.since, drop: true}
    ShowNote("drop it?  why was it not done  (optional)   " t.text, rowY
           , PastNote(t.id, t.since), "Enter drop  " Chr(0x00B7) " Esc keep it")
}

; The day it was meant for keeps it, crossed, with the reason beside it.
MissDropNow(id, day, txt) {
    global Past, CurDay
    i := TaskIndex(id)
    if (!i)
        return
    CommitMark()
    for _, r in Past
        if (r.id = id && r.day = day)
            r.status := "failed"
    Journal("- dropped: " Tasks[i].text "   (missed " MissSinceText(day) ")")
    if (txt != "")
        JournalNote(txt)
    Tasks.RemoveAt(i)
    TaskSetNote(id, day, txt)            ; saves, and rewrites that day's note
}

;--------------------------------------------------------------------------------
; arrow: back onto Today
;--------------------------------------------------------------------------------
; It moves first, whatever is said in the box: the box is only the one
; question, and Esc skips it.
MissToToday(i) {
    global NoteFor
    t := Tasks[i]
    if (!t)
        return
    CommitMark()
    t.list := "T", t.status := "open", t.doneOn := ""
    Journal(Chr(0x2193) " back on today: " t.text "   (missed " MissSinceText(t.since) ")")
    SaveState()
    Refresh()
    NoteFor := {id: t.id, day: t.since}
    ShowNote("not done " MissSinceText(t.since) " - why?  (optional)   " t.text
           , RowYOf(i), PastNote(t.id, t.since))
}
