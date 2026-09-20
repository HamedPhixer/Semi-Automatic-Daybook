;================================================================================
; Persistence
;================================================================================
SaveState() {
    s := "day`t" CurDay "`n"
    s .= "sit`t" SitSec "`n"
    for _, t in Tasks
        s .= "task`t" t.list "`t" t.status "`t" t.carry "`t" t.born "`t" t.due "`t" t.text "`n"
    ; The name goes LAST on both kinds of line, so it is the only field that
    ; can contain anything - the days before it are a fixed shape.
    for _, h in Habits {
        days := ""
        for _, d in h.done
            days .= (days ? "," : "") d
        s .= "habit`t" h.born "`t" h.streak "`t" h.best "`t" h.total "`t" days "`t" h.text "`n"
    }
    for _, txt in ReviewQueue
        s .= "review`t" txt "`n"
    for exe, sec in AppSec
        s .= "app`t" exe "`t" sec "`n"
    for k, sec in HourSec
        s .= "hour`t" k "`t" sec "`n"
    tmp := StateFile ".tmp"
    FileDelete, %tmp%
    FileAppend, %s%, %tmp%, UTF-8
    FileMove, %tmp%, %StateFile%, 1
}

LoadState() {
    if (!FileExist(StateFile))
        return
    FileRead, s, *P65001 %StateFile%
    Loop, Parse, s, `n, `r
    {
        if (A_LoopField = "")
            continue
        StringSplit, p, A_LoopField, %A_Tab%
        if (p1 = "day")
            CurDay := p2
        else if (p1 = "sit")
            SitSec := p2 + 0
        else if (p1 = "task")
            Tasks.Push({list: p2, status: p3, carry: p4 + 0, born: p5
                      , due: p6, text: p7, asked: 0})
        else if (p1 = "habit") {
            days := []
            Loop, Parse, p6, `,
                if (A_LoopField != "")
                    days.Push(A_LoopField)
            Habits.Push({text: p7, born: p2, streak: p3 + 0, best: p4 + 0
                       , total: p5 + 0, done: days})
        }
        else if (p1 = "review")
            ReviewQueue.Push(p2)
        else if (p1 = "app")
            AppSec[p2] := p3 + 0
        else if (p1 = "hour")
            HourSec[p2] := p3 + 0
    }
}

; The panel's own state lives under [Saved], below the settings. It used to be
; under [Panel], before the file held settings too. Whatever is still there -
; an older file, or the old version of this script writing its state on the way
; out of a reload - is moved across once and the old section removed.
LoadIni() {
    old := CfgSection(IniFile, "Panel")
    for k, v in old {
        if k in X,Y,OpenToday,OpenLater,OpenLong,OpenStats,OpenHabits,PanelMode,Locked,OnTop,ClickThru
            IniWrite, %v%, %IniFile%, Saved, %k%
    }
    if (old.Count())
        IniDelete, %IniFile%, Panel
    IniRead, PanelX,    %IniFile%, Saved, X,         NONE
    IniRead, PanelY,    %IniFile%, Saved, Y,         NONE
    IniRead, OpenToday, %IniFile%, Saved, OpenToday, 1
    ; LATER TASKS became LONG TERM TASKS. An .ini written before that still says
    ; OpenLater, so the old key answers when the new one is not there - the same
    ; way ClickThru answers for PanelMode below.
    IniRead, OpenLong, %IniFile%, Saved, OpenLong, NONE
    if (OpenLong = "NONE" || OpenLong = "ERROR")
        IniRead, OpenLong, %IniFile%, Saved, OpenLater, 0
    IniRead, OpenStats, %IniFile%, Saved, OpenStats, 0
    IniRead, OpenHabits, %IniFile%, Saved, OpenHabits, 1
    IniRead, PanelLocked, %IniFile%, Saved, Locked, 0
    IniRead, PanelOnTop, %IniFile%, Saved, OnTop, 1
    ; PanelMode replaced the old two-state ClickThru flag. When the new key is
    ; missing the old one is read instead, so an existing Daybook.ini comes back
    ; in the mode it was left in: ClickThru 1 was today's GHOST, 0 today's DIM.
    IniRead, PanelMode, %IniFile%, Saved, PanelMode, NONE
    if (PanelMode = "NONE" || PanelMode = "ERROR") {
        IniRead, wasThru, %IniFile%, Saved, ClickThru, 0
        PanelMode := wasThru ? 2 : 1
    }
    if (PanelMode != 0 && PanelMode != 1 && PanelMode != 2)
        PanelMode := 1
    if (PanelX = "NONE" || PanelX = "ERROR")
        PanelX := A_ScreenWidth - PanelW - 24
    if (PanelY = "NONE" || PanelY = "ERROR")
        PanelY := 80
}

SaveIni() {
    global PanelX, PanelY
    if (PanelVisible) {
        WinGetPos, x, y, , , ahk_id %PanelHwnd%
        if (x != "")
            PanelX := x, PanelY := y
    }
    IniWrite, %PanelX%,    %IniFile%, Saved, X
    IniWrite, %PanelY%,    %IniFile%, Saved, Y
    IniWrite, %OpenToday%, %IniFile%, Saved, OpenToday
    IniWrite, %OpenLong%,  %IniFile%, Saved, OpenLong
    IniWrite, %OpenStats%, %IniFile%, Saved, OpenStats
    IniWrite, %OpenHabits%, %IniFile%, Saved, OpenHabits
    IniWrite, %PanelMode%,   %IniFile%, Saved, PanelMode
    IniWrite, %PanelLocked%, %IniFile%, Saved, Locked
    IniWrite, %PanelOnTop%,  %IniFile%, Saved, OnTop
}

