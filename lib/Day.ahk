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
    HabitBoard()
    SaveState()
    Refresh()
}

; Write the closing day's summary, then decide what survives. Unfinished work is
; never deleted: it stays, its carry count goes up, and it joins the review
; queue so the amber + has something to ask about.
CloseDay() {
    open := [], keep := []
    for _, t in Tasks {
        if (t.list = "L") {
            keep.Push(t)
            continue
        }
        if (t.status = "open") {
            t.carry += 1
            open.Push(t.text)
            keep.Push(t)
        }
    }
    body := "`n" TS() "  " Chr(0x2014) " day closed`n"
    body .= "       active " HumanTime(TotalLogged()) "`n"
    tops := ""
    for _, a in TopApps(8)
        tops .= (tops ? " " Chr(0x00B7) " " : "") a.exe " " HumanTime(a.sec)
    if (tops != "")
        body .= "       " tops "`n"
    strip := HourStrip()
    if (strip != "")
        body .= "`n" strip
    if (open.Length()) {
        body .= "`n       unfinished:`n"
        for _, txt in open
            body .= "       - " txt "`n"
    }
    ; The habits go in LAST and as real markdown, under a heading of their own -
    ; the plain indented lines above are for reading, the checkboxes below are
    ; for Obsidian to count. See HabitDayBlock().
    body .= HabitDayBlock(CurDay)
    JournalRaw(CurDay, body)
    Tasks := keep
    ReviewQueue := open
}

