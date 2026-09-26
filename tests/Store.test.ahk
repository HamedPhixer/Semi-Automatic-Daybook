; Store.test.ahk - Daybook-state.txt, written and read back
;
; Loads the real lib\Store.ahk and lib\Settings.ahk. It checks the thing a
; state file has to do and nothing else: a task, two habits with history and
; one without, and every field the same on the way out as it was on the way in.
; It writes state-test.txt beside itself and leaves it there to look at.
;
; Run it with run-tests.ps1 in this folder, or on its own.
#NoEnv
#SingleInstance off
SetBatchLines -1
global CurDay := "2026-09-20", SitSec := 1234
global Tasks := [], Habits := [], ReviewQueue := [], AppSec := {}, HourSec := {}
global StateFile := A_ScriptDir "\state-test.txt"
global IniFile := ""
global Fails := 0, Log := ""
global NextTaskId := 1
global Past := [], PastTime := {}
global StateQuiet := 1, StateNoSave := 0
FileRemoveDir, %A_ScriptDir%\backups, 1
FileDelete, %A_ScriptDir%\state-test.txt
BoardWrite() {
}
LogRaw(text) {
}
DayNoteWrite(day, force := false) {
}
TaskIndex(id) {
    for i, t in Tasks
        if (t.id = id)
            return i
    return 0
}
#Include %A_ScriptDir%\..\lib\Store.ahk
Ok(name, got, want) {
    global Fails, Log
    if (got . "" = want . "")
        Log .= "  ok   " name "`n"
    else
        Log .= "  FAIL " name ": got [" got "] want [" want "]`n", Fails += 1
}
Tasks.Push({list: "T", text: "a task with, commas", status: "open", carry: 2
          , born: "2026-09-18", due: "", asked: 0, id: 7})
NextTaskId := 9
Habits.Push({text: "read 20 pages", born: "2026-09-01", streak: 12, best: 30
           , total: 143, done: ["2026-09-20", "2026-09-19", "2026-09-17"]})
Habits.Push({text: "workout", born: "2026-09-15", streak: 0, best: 2
           , total: 4, done: [], kind: "W", n: 3, rest: ["2026-09-18", "2026-09-16"], unit: "D"})
ReviewQueue.Push({text: "something", day: "2026-09-19", id: 7})
Tasks[1].notes := {"2026-09-20": "a note, with commas"}
Tasks[1].doneOn := "2026-09-20"
Past.Push({day: "2026-09-19", id: 5, list: "T", status: "failed", carry: 1
         , note: "shop was closed", text: "fix the bike"})
Past.Push({day: "2026-09-19", id: 6, list: "L", status: "done", carry: 0
         , note: "", text: "make a game"})
PastTime["2026-09-19"] := "active 2h 5m`n`nck3 1h`n`n       14  ███ ck3`n"
AppSec["chrome.exe"] := 99
HourSec["10"] := 60
SaveState()
Tasks := [], Habits := [], ReviewQueue := [], AppSec := {}, HourSec := {}
Past := [], PastTime := {}
CurDay := "", SitSec := 0
LoadState()
Ok("day",   CurDay, "2026-09-20")
Ok("sit",   SitSec, 1234)
Ok("tasks", Tasks.Length(), 1)
Ok("task text kept", Tasks[1].text, "a task with, commas")
Ok("habits", Habits.Length(), 2)
h := Habits[1]
Ok("habit text",   h.text,   "read 20 pages")
Ok("habit born",   h.born,   "2026-09-01")
Ok("habit streak", h.streak, 12)
Ok("habit best",   h.best,   30)
Ok("habit total",  h.total,  143)
Ok("habit days",   h.done.Length(), 3)
Ok("day order",    h.done[1], "2026-09-20")
Ok("last day",     h.done[3], "2026-09-17")
Ok("streak is a number", h.streak + 1, 13)
g := Habits[2]
Ok("empty history", g.done.Length(), 0)
Ok("second name",   g.text, "workout")
Ok("rule kept",     g.kind " " g.n, "W 3")
Ok("counted in days kept", g.unit, "D")
Ok("and weeks by default", h.unit, "W")
Ok("rest days kept", g.rest.Length() " " g.rest[2], "2 2026-09-16")
Ok("a habit with no rule line is every day", h.kind " " h.n, "D 1")
Ok("review kept",   ReviewQueue[1].text, "something")
Ok("review day",    ReviewQueue[1].day, "2026-09-19")
Ok("review id",     ReviewQueue[1].id, 7)
Ok("note kept",     Tasks[1].notes["2026-09-20"], "a note, with commas")
Ok("done on kept",  Tasks[1].doneOn, "2026-09-20")
Ok("past kept",     Past.Length(), 2)
Ok("past note",     Past[1].note, "shop was closed")
Ok("past status",   Past[1].status, "failed")
Ok("past empty note stays empty", Past[2].note, "")
Ok("past text after an empty note", Past[2].text, "make a game")
Ok("day's time kept, lines and all", PastTime["2026-09-19"] == "active 2h 5m`n`nck3 1h`n`n       14  ███ ck3`n" ? 1 : 0, 1)
Ok("app kept",      AppSec["chrome.exe"], 99)
Ok("task id kept",  Tasks[1].id, 7)
Ok("id counter kept", NextTaskId, 9)

; ---- a file from before ids -------------------------------------------------
; Seven fields and no tid line: every task gets an id, all different, and the
; counter ends up past them.
FileDelete, %StateFile%
old := "day`t2026-09-20`ntask`tT`topen`t0`t2026-09-18`t`tfirst`n"
     . "task`tL`topen`t0`t2026-09-18`t`tsecond`n"
FileAppend, %old%, %StateFile%, UTF-8
Tasks := [], NextTaskId := 1
LoadState()
Ok("old: text still read", Tasks[2].text, "second")
Ok("old: ids handed out", (Tasks[1].id && Tasks[2].id && Tasks[1].id != Tasks[2].id) ? 1 : 0, 1)
Ok("old: counter past them", NextTaskId > Tasks[2].id ? 1 : 0, 1)

; ---- the version before reads a new file -----------------------------------
; It splits on tabs and takes field 7 as the text; the id after it must not
; change what that sees.
SaveState()
FileRead, s, %StateFile%
RegExMatch(s, "m`n)^task\t.*$", line)     ; `n: the file ends its lines in `n alone
StringSplit, q, line, %A_Tab%
Ok("new file, old reader: text is field 7", q7, "first")

;================================================================================
; Keeping it safe
;================================================================================
bk := A_ScriptDir "\backups"
FileRead, s, *P65001 %StateFile%
Ok("the file says where it ends",    RegExMatch(s, "\nend\t\d+\n$") ? 1 : 0, 1)
Ok("  and so it reads as whole",     StateValid(s) ? 1 : 0, 1)
Ok("cut short, it does not",         StateValid(SubStr(s, 1, StrLen(s) // 2)) ? 1 : 0, 0)
Ok("cut before its end line",        StateValid(RegExReplace(s, "end\t\d+\n$")) ? 1 : 0, 0)
Ok("a line lost in the middle",      StateValid(RegExReplace(s, "m`n)^sit\t.*\n")) ? 1 : 0, 0)
Ok("an old file with no end line",   StateValid("day`t2026-09-20`nsit`t5`n") ? 1 : 0, 1)
Ok("nothing at all",                 StateValid("") ? 1 : 0, 0)

; a backup a day, of the file as it stood, and only one
FormatTime, today, , yyyy-MM-dd
Ok("the first save today backed it up", FileExist(bk "\Daybook-state-" today ".txt") ? 1 : 0, 1)
FileGetTime, t1, % bk "\Daybook-state-" today ".txt"
SaveState()
FileGetTime, t2, % bk "\Daybook-state-" today ".txt"
Ok("later saves leave today's alone",   t1 = t2 ? 1 : 0, 1)

; a file that will not read is set aside and the newest good backup loaded
FileDelete, %bk%\*.txt
good := "daybook-state`t2`nday`t2026-09-18`nsit`t0`ntask`tT`topen`t0`t2026-09-18`t`tfrom the backup`t1`t`nend`t4`n"
FileCreateDir, %bk%
FileAppend, %good%, *%bk%\Daybook-state-2026-09-18.txt, UTF-8
FileAppend, not a state file, *%bk%\Daybook-state-2026-09-19.txt, UTF-8
FileDelete, %StateFile%
FileAppend, % SubStr(s, 1, 40), *%StateFile%, UTF-8     ; cut short
Tasks := [], Habits := [], CurDay := ""
LoadState()
Ok("unreadable: the newest GOOD backup is loaded", Tasks.Length() " " Tasks[1].text, "1 from the backup")
Ok("  the day with it",                             CurDay, "2026-09-18")
aside := 0
Loop, Files, %A_ScriptDir%\Daybook-state.unreadable-*.txt
    aside++, keptBad := A_LoopFileFullPath
Ok("  the broken file is kept, not saved over",     aside, 1)
FileRead, badText, *P65001 %keptBad%
Ok("  and it is exactly what it was",               badText == SubStr(s, 1, 40) ? 1 : 0, 1)
FileDelete, %keptBad%

; a file that could not be read OR set aside: nothing may be saved over it
FileRead, before, *P65001 %StateFile%
StateNoSave := 1
Tasks := [], Habits := []
SaveState()
FileRead, after, *P65001 %StateFile%
Ok("refusing to save leaves the file as it was", after == before ? 1 : 0, 1)
StateNoSave := 0

; the backups kept: the newest 10, and the oldest of each of the last 6 months
FileDelete, %bk%\*.txt
FileCreateDir, %bk%
for _, d in ["2026-01-05", "2026-02-03", "2026-02-20", "2026-03-01", "2026-04-02", "2026-05-06"
           , "2026-06-01", "2026-06-15", "2026-07-01", "2026-08-01", "2026-09-01", "2026-09-02"
           , "2026-09-03", "2026-09-04", "2026-09-05", "2026-09-06", "2026-09-07", "2026-09-08"
           , "2026-09-09", "2026-09-10"]
    FileAppend, x, %bk%\Daybook-state-%d%.txt
StatePrune()
left := ""
for _, n in StateBackups()
    left .= SubStr(n, 15, 10) " "
Ok("pruned to 10 newest + 6 month-firsts"
  , Trim(left), "2026-04-02 2026-05-06 2026-06-01 2026-07-01 2026-08-01 2026-09-01 2026-09-02"
  . " 2026-09-03 2026-09-04 2026-09-05 2026-09-06 2026-09-07 2026-09-08 2026-09-09 2026-09-10")
FileRemoveDir, %bk%, 1

FileDelete, %A_ScriptDir%\results-Store.txt
FileAppend, % (Fails ? Fails " FAILED`n" : "all passed`n") Log, %A_ScriptDir%\results-Store.txt, UTF-8
ExitApp

#Include %A_ScriptDir%\..\lib\Settings.ahk
