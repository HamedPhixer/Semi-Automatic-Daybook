; Day.test.ahk - a whole day in Obsidian: the note, the board, the close
;
; Loads the real lib\Day.ahk, Journal.ahk, Board.ahk, Tasks.ahk, Habits.ahk and
; Log.ahk, and writes real notes into tests\journal\day\. The panel is stubbed;
; SaveState does what the real one does for Obsidian and nothing else. Runs on
; the real calendar - yesterday is the day being lived, today the one it rolls
; into - so it is the real RollIfNeeded() that closes it.
;
; Run it with run-tests.ps1 in this folder, or on its own.
#NoEnv
#SingleInstance off
SetBatchLines -1

global DayStartHour := 3, HabitKeep := 372, HabitDays := 7, PastKeepDays := 42
global JournalOn := 1, BoardOn := 1, JournalDir := A_ScriptDir "\journal\day"
global Tasks := [], Habits := [], Past := [], PastTime := {}, ReviewQueue := []
global CurDay := "", NextTaskId := 1
global AppSec := {}, HourSec := {}, LogApps := 1, SampleMs := 30000, StatsTop := 8
global SitSec := 0, AwaySec := 0, CutShort := 0
global PendMarkKind := "", PendMarkTask := 0
global CGreen := "0", CAmber := "0", CRed := "0", CTrack := "0", CDim := "0"
global Fails := 0, Log := ""
global StateFile := A_ScriptDir "\journal\day-state.txt"   ; backups\notes goes beside it

SaveState() {
    BoardWrite()
    DayNoteWrite(CurDay)
}
Refresh() {
}
CommitMark() {
}
CancelMark(kind, i) {
    return false
}
PendMark(kind, i, status) {
}
Present() {
    return true
}

#Include %A_ScriptDir%\..\lib\Day.ahk
#Include %A_ScriptDir%\..\lib\Journal.ahk
#Include %A_ScriptDir%\..\lib\Board.ahk
#Include %A_ScriptDir%\..\lib\Tasks.ahk
#Include %A_ScriptDir%\..\lib\Habits.ahk
#Include %A_ScriptDir%\..\lib\Log.ahk

Ok(name, got, want) {
    global Fails, Log
    if (got . "" = want . "")
        Log .= "  ok   " name "`n"
    else
        Log .= "  FAIL " name ": got [" got "] want [" want "]`n", Fails += 1
}
Has(name, hay, needle) {
    Ok(name, InStr(hay, needle, true) ? 1 : 0, 1)
}
Hasnt(name, hay, needle) {
    Ok(name, InStr(hay, needle, true) ? 1 : 0, 0)
}
Count(hay, needle) {
    StrReplace(hay, needle, needle, n)
    return n
}
Note(day) {
    FileRead, s, % "*P65001 " JournalFile(day)
    return s
}
Put(day, s) {
    f := JournalFile(day)
    FileDelete, %f%
    FileAppend, %s%, *%f%, UTF-8
}

FileRemoveDir, %JournalDir%, 1
FileCreateDir, %JournalDir%
today := LogicalDay()
yday  := DayShift(today, -1)
d2    := DayShift(today, -2)
tick  := Chr(0x2713), cross := Chr(0x2717), box := Chr(0x2610), dash := Chr(0x2014)
dot   := Chr(0x00B7)

; ---- a day being lived -------------------------------------------------------
CurDay := yday
AddTask("buy milk")
AddTask("call mom")
AddTask("fix the bike")
AddTask("make a game", "L")
HabitAdd("painting")
HabitAdd("exercise")
Habits[1].born := d2, Habits[2].born := d2
SetStatus(1, "done")
TaskSetNote(Tasks[1].id, yday, "got the oat one")
SetStatus(3, "failed")
SetStatus(4, "done")
AppSec := {"ck3": 3600}, HourSec := {"14|ck3": 3600}   ; rides along with the next change
HabitSetDay(1, yday)
f := Note(yday)
Has("note: made with its heading",   f, "# " yday "`n`n## my notes`n")
Has("block: starts with its marker", f, "%% daybook:")
Has("block: a task with its note",   f, "- " tick " buy milk  " dash " got the oat one`n")
Has("block: crossed",                f, "- " cross " fix the bike`n")
Has("block: still open",             f, "- " box " call mom`n")
Has("block: long term done that day", f, "- " tick " make a game  " dot " long term`n")
Has("block: habit count",            f, "1 of 2 done")
Has("block: habit with its run",     f, "- " tick " painting  " dot " 1 in a row`n")
Has("block: habit not done",         f, "- " box " exercise`n")
Has("block: time",                   f, "### time at the machine`n`nactive 1h 0m")
Has("block: ends with its marker",   f, "%% /daybook %%")

; ---- your writing, above and below, is never touched ------------------------
f := StrReplace(f, "## my notes`n`n`n", "## my notes`n`nA long day. I liked it.`n`n")
f .= "`nPS written under the block`n"
Put(yday, f)
SetStatus(2, "done")
f := Note(yday)
Has("rewritten: the change is in",   f, "- " tick " call mom`n")
Ok("your words above, once",         Count(f, "A long day. I liked it."), 1)
Ok("your words below, once",         Count(f, "PS written under the block"), 1)
Ok("one block, not two",             Count(f, "%% daybook:"), 1)

; ---- the time alone does not rewrite a note you may be typing in ------------
AppSec["ck3"] := 7200
SaveState()
Has("time alone: not rewritten yet", Note(yday), "active 1h 0m")
SetStatus(2, "open")
f := Note(yday)
Has("time rides along with a real change", f, "active 2h 0m")

; ---- the day closes -----------------------------------------------------------
RollIfNeeded()
Ok("rolled to today",                CurDay, today)
Ok("only the unfinished stay",       Tasks.Length(), 1)
Ok("and it is the open one",         Tasks[1].text, "call mom")
Ok("carried",                        Tasks[1].carry, 1)
Ok("the day is kept",                Past.Length(), 4)
Ok("a question is owed, about yday", ReviewQueue[1].day, yday)
f := Note(yday)
Has("closed note: still open",       f, "- " box " call mom`n")
Has("closed note: time kept",        f, "active 2h 0m")
Ok("closed note: your words still once", Count(f, "A long day. I liked it."), 1)
t := Note(today)
Has("today's note made",             t, "# " today "`n`n## my notes")
Has("today: the carried task",       t, "- " box " call mom  " dot " carried " Chr(0xD7) "2`n")
Hasnt("today: not yesterday's done", t, "buy milk")

; ---- the answer to "why not?", the next morning, goes onto that day ---------
TaskSetNote(ReviewQueue[1].id, yday, "ran out of time")
f := Note(yday)
Has("answer on yesterday's line",    f, "- " box " call mom  " dash " ran out of time`n")
Ok("and your words are still there", Count(f, "A long day. I liked it."), 1)
Hasnt("not on today's",              Note(today), "ran out of time")

; ---- a note today, edited, then taken away -----------------------------------
TaskSetNote(Tasks[1].id, today, "ring after six")
Has("today: note on the task",       Note(today), "carried " Chr(0xD7) "2  " dash " ring after six`n")
TaskSetNote(Tasks[1].id, today, "")
Hasnt("today: note taken away",      Note(today), "ring after six")

; ---- the board ---------------------------------------------------------------
b := ""
FileRead, b, % "*P65001 " JournalDir "\Daybook.md"
Has("board: today",                  b, "## today`n`n- " box " call mom  " dot " carried")
Has("board: long term, empty",       b, "## long term`n`nnothing here`n")
Has("board: streaks",                b, "| painting | ")
Has("board: two weeks",              b, "### the last two weeks")
Hasnt("board: no checkboxes to click", b, "- [ ]")

; ---- a note from before this version is left exactly as it is -------------
old := "# " d2 "`n`n10:00  + added: something`n"
Put(d2, old)
HabitSetDay(2, d2)
Ok("old note untouched by a late tick", Note(d2) == old ? 1 : 0, 1)
DayNoteWrite(d2, true)
Ok("old note untouched by a rewrite",   Note(d2) == old ? 1 : 0, 1)

; ---- a late tick rewrites the day it belongs to ------------------------------
HabitSetDay(2, yday)
; the day before it was ticked just above, so the run that day was two
Has("late tick in yesterday's note", Note(yday), "- " tick " exercise  " dot " 2 in a row`n")
Has("and the count with it",         Note(yday), "2 of 2 done")

; ---- journal off: nothing is written -----------------------------------------
JournalOn := 0
before := Note(today)
AddTask("while off")
Ok("journal off: today's note unchanged", Note(today) == before ? 1 : 0, 1)
JournalOn := 1

; ---- a note read short is never written back --------------------------------
cut := "# " yday "`n`n## my notes`n`nhalf a thought`n`n%% daybook: written by Daybook and rewr"
Put(yday, cut)
TaskSetNote(ReviewQueue[1].id, yday, "a later answer")     ; wants to rewrite it
Ok("cut note: left exactly as found", Note(yday) == cut ? 1 : 0, 1)
Ok("the note was copied aside before Daybook first touched it"
  , FileExist(A_ScriptDir "\journal\backups\notes\" yday ".md") ? 1 : 0, 1)

; ---- old days are let go -----------------------------------------------------
Past.Push({day: DayShift(today, -60), id: 99, list: "T", status: "done", carry: 0, note: "", text: "long ago"})
PastTime[DayShift(today, -60)] := "x"
PastPrune()
gone := 1
for _, r in Past
    if (r.id = 99)
        gone := 0
Ok("pruned: the record",   gone, 1)
Ok("pruned: its time",     PastTime.HasKey(DayShift(today, -60)) ? 0 : 1, 1)
Ok("kept: yesterday",      PastTime.HasKey(yday) ? 1 : 0, 1)

FileDelete, %A_ScriptDir%\results-Day.txt
FileAppend, % (Fails ? Fails " FAILED`n" : "all passed`n") Log
    , %A_ScriptDir%\results-Day.txt, UTF-8
ExitApp
