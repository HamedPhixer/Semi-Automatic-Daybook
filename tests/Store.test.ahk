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
#Include %A_ScriptDir%\..\lib\Store.ahk
Ok(name, got, want) {
    global Fails, Log
    if (got . "" = want . "")
        Log .= "  ok   " name "`n"
    else
        Log .= "  FAIL " name ": got [" got "] want [" want "]`n", Fails += 1
}
Tasks.Push({list: "T", text: "a task with, commas", status: "open", carry: 2
          , born: "2026-09-18", due: "", asked: 0})
Habits.Push({text: "read 20 pages", born: "2026-09-01", streak: 12, best: 30
           , total: 143, done: ["2026-09-20", "2026-09-19", "2026-09-17"]})
Habits.Push({text: "workout", born: "2026-09-15", streak: 0, best: 2
           , total: 4, done: []})
ReviewQueue.Push("something")
AppSec["chrome.exe"] := 99
HourSec["10"] := 60
SaveState()
Tasks := [], Habits := [], ReviewQueue := [], AppSec := {}, HourSec := {}
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
Ok("review kept",   ReviewQueue[1], "something")
Ok("app kept",      AppSec["chrome.exe"], 99)
FileDelete, %A_ScriptDir%\results-Store.txt
FileAppend, % (Fails ? Fails " FAILED`n" : "all passed`n") Log, %A_ScriptDir%\results-Store.txt, UTF-8
ExitApp

#Include %A_ScriptDir%\..\lib\Settings.ahk
