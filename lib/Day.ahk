;================================================================================
; The day
;================================================================================
LogicalDay() {
    shift := -DayStartHour
    t := A_Now
    t += %shift%, Hours
    FormatTime, d, %t%, yyyy-MM-dd
    return d
}

; A day, n days from this one. "2026-09-20", -1 -> "2026-09-19", and it is the
; calendar that answers, so month ends, leap days and the turn of the year all
; come out right without a single special case.
DayShift(day, n) {
    t := RegExReplace(day, "-") "000000"
    t += n, Days
    FormatTime, d, %t%, yyyy-MM-dd
    return d
}

RollIfNeeded() {
    CommitMark()                 ; a pending mark belongs to the day it happened
    today := LogicalDay()
    if (CurDay = today) {
        ; Not a new day, but the streaks still have to be right the first time
        ; this is called - the script may have been closed for a week.
        HabitSettle()
        return
    }
    if (CurDay != "")
        CloseDay()
    CurDay := today
    SitSec := 0, AwaySec := 0, CutShort := 0
    AppSec := {}, HourSec := {}
    HabitSettle()                ; yesterday is settled: chains kept or broken
    SaveState()
    Refresh()
}

; The day is over. Keep a record of it, write its note for the last time, then
; decide what survives into the next one.
;
; The record (Past) is what lets the day's note still be put right after it is
; over - the answer to "why not?" given the next morning goes onto that day's
; line, not into a new one. Everything on Today's list goes in, and a long term
; task only if it was finished that day.
;
; Unfinished work is never deleted: it stays, its carry count goes up, and it
; joins the review queue - knowing which day it belongs to - so the amber + has
; something to ask about. Finished work leaves the panel, long term included:
; it is done, and the note has it.
CloseDay() {
    global Tasks, Past, PastTime, ReviewQueue, CurDay
    day := CurDay
    ; A long term task finished before tasks remembered WHEN they were
    ; finished has no doneOn; it leaves the panel now like the rest, so it is
    ; recorded on this day rather than vanishing without a trace.
    for _, t in Tasks
        if (t.list = "T" || t.doneOn = day || (t.status != "open" && t.doneOn = ""))
            Past.Push({day: day, id: t.id, list: t.list, status: t.status
                     , carry: t.carry, note: TaskNote(t, day), text: t.text})
    PastTime[day] := DayTimeText()
    DayNoteWrite(day, true)              ; the last word, time and all
    open := [], keep := []
    for _, t in Tasks {
        if (t.status != "open")
            continue
        if (t.list = "T") {
            t.carry += 1
            open.Push({day: day, id: t.id, text: t.text})
        }
        t.notes := {}                    ; the day's notes are in Past now
        keep.Push(t)
    }
    Tasks := keep
    ReviewQueue := open
    PastPrune()
}

; Finished days are kept PastKeepDays, then let go. The day notes keep them for
; good - this is only what Daybook needs to be able to rewrite one.
PastPrune() {
    global Past, PastTime, PastKeepDays
    cut := DayShift(LogicalDay(), -PastKeepDays)
    keep := []
    for _, r in Past
        if !(r.day < cut)
            keep.Push(r)
    Past := keep
    for day in PastTime.Clone()
        if (day < cut)
            PastTime.Delete(day)
}
