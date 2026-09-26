; Log.test.ahk - the day's totals and the hour strip
;
; Loads the real lib\Log.ahk. The strip is what the closing day's note carries,
; and the one thing it has to get right is order: a day runs from DayStartHour
; to DayStartHour, so the small hours come LAST.
;
; Run it with run-tests.ps1 in this folder, or on its own.
#NoEnv
#SingleInstance off
SetBatchLines -1
global DayStartHour := 3
global AppSec := {}, HourSec := {}
global LogApps := 1, SampleMs := 30000, StatsTop := 8
global Fails := 0, Log := ""
Present() {
    return true
}
#Include %A_ScriptDir%\..\lib\Log.ahk
Ok(name, got, want) {
    global Fails, Log
    if (got . "" = want . "")
        Log .= "  ok   " name "`n"
    else
        Log .= "  FAIL " name ": got [" got "] want [" want "]`n", Fails += 1
}

; ---- the hour strip runs in the order the day did ---------------------------
HourSec["01|firefox"] := 600
HourSec["23|claude"]  := 600
HourSec["03|WINWORD"] := 600
HourSec["09|ck3"]     := 600
HourSec["02|Telegram"] := 600
order := ""
Loop, Parse, % HourStrip(), `n
    if (A_LoopField != "")
        order .= SubStr(Trim(A_LoopField), 1, 2) " "
Ok("03 first, the small hours last", Trim(order), "03 09 23 01 02")

DayStartHour := 0
order := ""
Loop, Parse, % HourStrip(), `n
    if (A_LoopField != "")
        order .= SubStr(Trim(A_LoopField), 1, 2) " "
Ok("a day starting at midnight is the clock", Trim(order), "01 02 03 09 23")

; ---- under five minutes in an hour draws nothing ---------------------------
HourSec := {"10|notepad": 60}
Ok("a minute is not a block", HourStrip(), "")

; ---- totals --------------------------------------------------------------
AppSec := {"a": 3600, "b": 60, "c": 7200}
Ok("total",          TotalLogged(), 10860)
Ok("biggest first",  TopApps(1)[1].exe, "c")
Ok("human time",     HumanTime(3660), "1h 1m")
Ok("under an hour",  HumanTime(59 * 60), "59m")

FileDelete, %A_ScriptDir%\results-Log.txt
FileAppend, % (Fails ? Fails " FAILED`n" : "all passed`n") Log
    , %A_ScriptDir%\results-Log.txt, UTF-8
ExitApp
