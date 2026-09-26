;================================================================================
; The passive log
;================================================================================
SampleApp() {
    if (!LogApps || !Present())
        return
    WinGet, exe, ProcessName, A
    if (exe = "")
        return
    exe := RegExReplace(exe, "i)\.exe$")
    secs := SampleMs // 1000
    AppSec[exe] := (AppSec[exe] ? AppSec[exe] : 0) + secs
    hk := A_Hour "|" exe
    HourSec[hk] := (HourSec[hk] ? HourSec[hk] : 0) + secs
}

; Biggest first. Zero-padding makes a text sort numerically correct, which is
; cheaper than writing a comparator.
TopApps(limit := 0) {
    lines := ""
    for exe, sec in AppSec
        lines .= Format("{:09}", sec) "`t" exe "`n"
    Sort, lines, R
    out := []
    Loop, Parse, lines, `n, `r
    {
        if (A_LoopField = "")
            continue
        StringSplit, p, A_LoopField, %A_Tab%
        out.Push({exe: p2, sec: p1 + 0})
        if (limit && out.Length() >= limit)
            break
    }
    return out
}

HumanTime(sec) {
    h := sec // 3600, m := Mod(sec // 60, 60)
    return h ? h "h " m "m" : m "m"
}

TotalLogged() {
    total := 0
    for _, sec in AppSec
        total += sec
    return total
}

UpdateStats() {
    ; the heading carries the accumulation of everything under it, so the number
    ; is there whether or not the drawer is open
    GuiControl, Panel:, StatsTotal, % HumanTime(TotalLogged())
    names := "", vals := ""
    for _, a in TopApps(StatsTop) {
        names .= (names ? "`n" : "") a.exe
        vals  .= (vals  ? "`n" : "") HumanTime(a.sec)
    }
    GuiControl, Panel:, StatsTxt, % (names = "" ? "nothing yet" : names)
    GuiControl, Panel:, StatsVal, %vals%
}

StatsLines() {
    n := TopApps(StatsTop).Length()
    return n ? n : 1
}

; One line per hour, widest app first, one block per 5 minutes. Markdown only:
; this is something you read when reviewing, not while working.
HourStrip() {
    ; Keys are prefixed with "h" for a reason: AHK converts an object key that
    ; looks like an integer into one, so a bare "09" silently becomes 9 and then
    ; sorts AFTER "10" and "11". The prefix keeps it a string.
    hours := {}
    for k, sec in HourSec {
        StringSplit, p, k, |
        if (!hours.HasKey("h" p1))
            hours["h" p1] := {}
        hours["h" p1][p2] := sec
    }
    ; Sorted by hours since the day began, not by the clock: the day runs from
    ; DayStartHour to DayStartHour, so 01:00 comes AFTER 23:00, and a plain sort
    ; put the small hours at the top of the strip as if they started the day.
    keys := ""
    for h, _ in hours
        keys .= Format("{:02}", Mod(SubStr(h, 2) + 24 - DayStartHour, 24)) "`t" h "`n"
    Sort, keys
    out := ""
    Loop, Parse, keys, `n, `r
    {
        if (A_LoopField = "")
            continue
        key := SubStr(A_LoopField, InStr(A_LoopField, "`t") + 1)
        h := SubStr(key, 2)
        lines := ""
        for exe, sec in hours[key]
            lines .= Format("{:09}", sec) "`t" exe "`n"
        Sort, lines, R
        row := "", n := 0
        Loop, Parse, lines, `n, `r
        {
            if (A_LoopField = "")
                continue
            if (++n > 3)
                break
            StringSplit, p, A_LoopField, %A_Tab%
            bars := Round((p1 + 0) / 300)
            if (bars < 1)
                continue
            block := ""
            Loop % bars
                block .= Chr(0x2588)
            row .= (row ? "  " : "") block " " p2
        }
        if (row != "")
            out .= "       " h "  " row "`n"
    }
    return out
}

