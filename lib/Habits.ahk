;================================================================================
; Habits - the things you want to do EVERY day, and how long you have kept it up
;================================================================================
; A habit is not a task. A task is done once and gone; a habit comes back
; tomorrow whether you did it or not, and the only thing worth showing is
; whether you have kept the chain going.
;
; Each row carries a week of dots and one number, and the DOTS ARE BUTTONS:
; click the one for Tuesday and Tuesday is ticked. That is the answer to
; forgetting, and it is why the dots are there rather than a bare streak.
;
;     [v] read 20 pages          . . o o o o o     12
;      ^  ^                      ^                 ^
;      |  |                      |                 how many days in a row,
;      |  |                      |                 counting today if it is done
;      |  |                      seven days, oldest on the left, TODAY on the
;      |  |                      right. Green done, red missed, grey still to
;      |  |                      do, and nothing at all for the days before the
;      |  the name               habit existed
;      click it to tick today off - click again to take it back
;
; THE STREAK is the whole point, so it is kept honestly:
;   - ticking today adds one if yesterday was done, otherwise it starts at one
;   - unticking today takes that one back
;   - a day that passes with neither today nor yesterday done sets it to zero
;   - editing any OTHER day throws the number away and counts the chain again
;     along the calendar (HabitRecount), because a day filled in halfway
;     through a week can join two chains and no amount of adding one will see
;     that
; It survives a reboot, a crash and the script being closed for a week, because
; HabitSettle() checks it against the calendar rather than against how many
; times this code happened to run.
;
; WHAT IS KEPT is in Daybook-state.txt: the name, the day it was born, the
; streak, the best streak ever, the running total, and the last HabitKeep days
; it was done on. Only the dots need that list, so it is trimmed - the streak
; is a number of its own and does not depend on it.
;
; IN OBSIDIAN - see HabitDayBlock() and HabitBoard():
;   - each tick is a line in that day's note, with the streak it reached
;   - each day closes with a "## habits" block of real markdown checkboxes, so
;     Dataview's TASK queries can count them, plus a (streak:: n) inline field
;   - Habits.md in the journal folder is a scoreboard, rewritten on every
;     change: the streaks as they stand, and a grid of the last two weeks
;================================================================================

; A habit's whole record. Nothing else creates one.
HabitNew(text) {
    return {text: text, born: LogicalDay(), streak: 0, best: 0, total: 0, done: []}
}

HabitAdd(text) {
    global Habits
    text := Trim(RegExReplace(text, "[\r\n\t]+", " "))
    if (text = "")
        return
    for _, h in Habits
        if (h.text = text)               ; the same habit twice is never meant
            return
    Habits.Push(HabitNew(text))
    SaveState()
    HabitBoard()
    Refresh()
    Journal("+ habit: " text)
}

HabitRename(i, newText) {
    global Habits
    newText := Trim(RegExReplace(newText, "[\r\n\t]+", " "))
    h := Habits[i]
    if (!h || newText = "" || newText = h.text)
        return
    old := h.text
    h.text := newText
    SaveState()
    HabitBoard()
    Refresh()
    Journal("~ habit renamed: " old "   " Chr(0x2192) "   " newText)
}

HabitDelete(i) {
    global Habits
    h := Habits[i]
    if (!h)
        return
    ; RemoveAt shifts every index above this one, so nothing may be left
    ; pointing at a row by number - the same trap MenuDelete documents.
    if (!CancelMark("H", i))
        CommitMark()
    Habits.RemoveAt(i)
    SaveState()
    HabitBoard()
    Refresh()
    Journal("- habit dropped: " h.text)
}

; Was it done on this day?
HabitDid(h, day) {
    for _, d in h.done
        if (d = day)
            return true
    return false
}

HabitDidToday(h) {
    return HabitDid(h, LogicalDay())
}

; Tick or untick TODAY. The streak moves by exactly one either way, so pressing
; it twice leaves everything exactly as it was - which is what makes a misclick
; free.
HabitToggle(i) {
    global Habits, HabitKeep
    h := Habits[i]
    if (!h)
        return
    today := LogicalDay()
    if (HabitDid(h, today)) {
        idx := 0
        for k, d in h.done
            if (d = today)
                idx := k
        if (idx)
            h.done.RemoveAt(idx)
        h.streak := (h.streak > 0) ? h.streak - 1 : 0
        h.total  := (h.total  > 0) ? h.total  - 1 : 0
        ; Untick inside the grace window and the tick was never written, so
        ; neither is this. Past it, the tick is already on disk and the honest
        ; thing is to say it was taken back - the journal is append only.
        if (!CancelMark("H", i)) {
            CommitMark()
            Journal(Chr(0x2717) " habit unticked: " h.text)
        }
        SaveState()
        HabitBoard()
        Refresh()
        return
    }
    h.done.InsertAt(1, today)
    while (h.done.Length() > HabitKeep)
        h.done.Pop()
    h.streak := HabitDid(h, DayShift(today, -1)) ? h.streak + 1 : 1
    h.total += 1
    if (h.streak > h.best)
        h.best := h.streak
    SaveState()
    HabitBoard()
    Refresh()
    CommitMark()                         ; another row was still pending
    PendMark("H", i, "done")             ; held, like a task's tick - see CommitMark()
}

; Tick or untick ANY day the dots show - for the evening you did the thing and
; forgot to say so. Today goes through HabitToggle, which has the grace period
; and writes the journal line; a past day is a correction, so it is written
; plainly and at once.
;
; The day has to be one you can see: not the future, not before the habit
; existed, and no further back than the dots go. That last rule is what keeps
; the streak exact - HabitRecount can only count as far as the history kept.
HabitSetDay(i, day) {
    global Habits, HabitDays
    h := Habits[i]
    if (!h)
        return
    today := LogicalDay()
    if (day = today) {
        HabitToggle(i)
        return
    }
    if (day > today || day < h.born || day < DayShift(today, -HabitDays))
        return
    if (HabitDid(h, day)) {
        idx := 0
        for k, d in h.done
            if (d = day)
                idx := k
        h.done.RemoveAt(idx)
        h.total := (h.total > 0) ? h.total - 1 : 0
        note := Chr(0x2717) " habit unticked for " day ": "
    } else {
        HabitInsertDay(h, day)
        h.total += 1
        note := Chr(0x2713) " habit ticked for " day ": "
    }
    HabitRecount(h)
    SaveState()
    HabitBoard()
    Refresh()
    CommitMark()                         ; a row was pending; it is not this one
    Journal(note h.text)
}

; Keep h.done newest first, which is what the trimming in HabitToggle assumes.
HabitInsertDay(h, day) {
    global HabitKeep
    at := h.done.Length() + 1
    for k, d in h.done {
        if (d < day) {
            at := k
            break
        }
    }
    h.done.InsertAt(at, day)
    while (h.done.Length() > HabitKeep)
        h.done.Pop()
}

; The streak, counted along the calendar rather than kept up by hand. Ticking a
; day in the middle of the week can lengthen a chain, shorten it or split it in
; two, and none of that can be done by adding one to a number - so once a day
; other than today is edited, the number is thrown away and counted again.
;
; It walks back from today, or from yesterday when today is not done yet, and
; stops at the first day that is not. That means it can only see as far as
; HabitKeep - a streak longer than that, mended by hand, comes back as
; HabitKeep. A year is far enough that it will not come up.
HabitRecount(h) {
    today := LogicalDay()
    d := HabitDid(h, today) ? today : DayShift(today, -1)
    n := 0
    while (HabitDid(h, d)) {
        n += 1
        d := DayShift(d, -1)
    }
    h.streak := n
    if (n > h.best)
        h.best := n
}

; Called at start and whenever the day rolls. A streak only survives while
; either today or yesterday is done; anything older means a whole day went by
; untouched, and the chain is broken whether this script was running or not.
HabitSettle() {
    global Habits
    today := LogicalDay()
    yday  := DayShift(today, -1)
    for _, h in Habits {
        if (h.streak > 0 && !HabitDid(h, today) && !HabitDid(h, yday))
            h.streak := 0
        if (h.streak > h.best)
            h.best := h.streak
    }
}

; How many are ticked today.
HabitsDone() {
    global Habits
    n := 0
    for _, h in Habits
        if (HabitDidToday(h))
            n++
    return n
}

; What one dot means. "none" is a day before the habit existed and is not drawn
; at all - a habit added on Thursday has nothing to say about Monday.
HabitDayState(h, day, today) {
    if (day < h.born)
        return "none"
    if (HabitDid(h, day))
        return "done"
    if (day = today)
        return "todo"
    return (day = DayShift(today, -1)) ? "miss" : "old"
}

; Yesterday is the one that stings, so it keeps the full red. Older misses fade
; to the dark red the overdue bar breathes through - still red, still countable
; at a glance, but not a wall of alarm every morning.
HabitDotColour(state) {
    global CGreen, CRed, CTrack
    if (state = "done")
        return CGreen
    if (state = "miss")
        return CRed
    if (state = "todo")
        return CTrack
    return "8A2A3C"                      ; "old"
}

; The number at the end of the row: green while today is already done, amber
; while the chain is alive but today is not, dim at zero.
HabitStreakColour(h) {
    global CGreen, CAmber, CDim
    if (h.streak <= 0)
        return CDim
    return HabitDidToday(h) ? CGreen : CAmber
}

;================================================================================
; The Obsidian side
;================================================================================
; Habits.md, in the journal folder beside the daily notes. It is the one file
; here that IS rewritten - it is a scoreboard, not a record, and the record is
; in the daily notes, where nothing is ever overwritten. Written through a temp
; file and a move, so a crash halfway cannot leave half a table behind.
HabitBoard() {
    global Habits, JournalDir, HabitBoardOn
    if (!HabitBoardOn)
        return
    if (!InStr(FileExist(JournalDir), "D"))
        FileCreateDir, %JournalDir%
    today := LogicalDay()
    FormatTime, stamp, , yyyy-MM-dd HH:mm
    s := "# Habits`n`n"
    s .= "Written by Daybook at " stamp ", and rewritten whenever a habit"
    s .= " changes - anything you type in this file will be lost. The daily"
    s .= " notes are the record; this is only the scoreboard.`n`n"
    if (!Habits.Length()) {
        s .= "No habits yet. Add one from the + beside HABITS on the panel.`n"
        HabitWriteFile(JournalDir "\Habits.md", s)
        return
    }
    s .= "| habit | streak | best | days done | since |`n"
    s .= "| --- | ---: | ---: | ---: | --- |`n"
    for _, h in Habits
        s .= "| " h.text " | " h.streak " | " h.best " | " h.total " | " h.born " |`n"

    s .= "`n## the last two weeks`n`n"
    s .= "| habit |"
    Loop 14
        s .= " " SubStr(DayShift(today, A_Index - 14), 9, 2) " |"
    s .= "`n| --- |"
    Loop 14
        s .= " :-: |"
    s .= "`n"
    for _, h in Habits {
        s .= "| " h.text " |"
        Loop 14 {
            st := HabitDayState(h, DayShift(today, A_Index - 14), today)
            mark := (st = "done") ? Chr(0x2705)      ; white heavy check
                  : (st = "none") ? " "
                  : (st = "todo") ? Chr(0x2B1C)      ; white large square
                  : Chr(0x274C)                      ; cross mark
            s .= " " mark " |"
        }
        s .= "`n"
    }

    ; A Dataview block, in a file Dataview will try to RUN. The fence has to be
    ; built rather than typed, or this scoreboard would execute its own example.
    ; qq is a double quote, which cannot be written plainly inside a string here.
    q  := Chr(0x0060) Chr(0x0060) Chr(0x0060)
    qq := Chr(0x0022)
    s .= "`n## counting them yourself`n`n"
    s .= "Every day's note ends with a ## habits block of real checkboxes, so"
    s .= " Dataview can add them up:`n`n"
    s .= q "dataview`nTASK`nWHERE checked AND contains(text, " qq "(streak::" qq ")`n"
    s .= "GROUP BY text`nSORT rows.file.name DESC`n" q "`n"
    HabitWriteFile(JournalDir "\Habits.md", s)
}

HabitWriteFile(path, text) {
    tmp := path ".tmp"
    FileDelete, %tmp%
    FileAppend, %text%, %tmp%, UTF-8
    FileMove, %tmp%, %path%, 1
}

; The block appended to the closing day's note. Real markdown checkboxes on
; purpose: Obsidian renders them, Dataview's TASK queries count them and a
; habit plugin can read them - none of which a line of prose would give you.
HabitDayBlock(day) {
    global Habits
    if (!Habits.Length())
        return ""
    done := 0, live := 0
    for _, h in Habits {
        if (day < h.born)
            continue
        live++
        if (HabitDid(h, day))
            done++
    }
    if (!live)
        return ""
    body := "`n## habits`n`n"
    body .= "habits-done:: " done "/" live "`n`n"
    for _, h in Habits {
        if (day < h.born)
            continue
        box := HabitDid(h, day) ? "x" : " "
        body .= "- [" box "] " h.text "  (streak:: " h.streak ")`n"
    }
    ; The blank line matters. Without it the next thing appended to this file -
    ; the first line of a session that starts before the day rolls again - is
    ; read by markdown as a continuation of the last checkbox and disappears
    ; into it.
    return body "`n"
}
