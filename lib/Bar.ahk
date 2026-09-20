;================================================================================
; Sit timer -> the top bar
;================================================================================
ApplySitState() {
    global EdgeState
    if (BreakMode)
        want := 3
    else if (Away)
        want := 4
    else {
        mins := SitSec / 60
        want := (mins >= SitBreakMin) ? 2 : (mins >= SitWarnMin) ? 1 : 0
    }
    if (want != EdgeState) {
        EdgeState := want
        if (want = 3)
            SetBarColour(CBreak)
        else if (want = 4)
            SetBarColour(CDim)
        else if (want < 2)
            SetBarColour(want ? CAmber : CGreen)
        SetStatusText()
    }
    ; the fill moves with the clock even when the colour has not changed
    pct := BreakMode ? 0 : Round(SitSec / (SitBreakMin * 60) * 100)
    GuiControl, Panel:, TopBar, % (pct > 100 ? 100 : pct)
    ; NagLevel > 0 would escalate from here.
}

SetStatusText() {
    if (EdgeState = 3)
        txt := "ON A BREAK", col := CBreak
    else if (EdgeState = 4)
        txt := "AWAY", col := CDim
    else if (EdgeState = 2)
        txt := "BREAK OVERDUE", col := CRed
    else if (EdgeState = 1)
        txt := "SITTING " SitWarnMin "M+", col := CAmber
    else
        txt := "FOCUS", col := CGreen
    GuiControl, Panel:, StatusTxt, %txt%
    GuiControl, Panel:+c%col%, StatusTxt
    GuiControl, Panel:, StatusTxt, %txt%      ; re-set so the colour repaints
    SetBreakBtn()
}

; the button in the header says what pressing it will do
SetBreakBtn() {
    col := BreakMode ? CBreak : CDim       ; into a variable first - see PlaceRows
    GuiControl, Panel:+c%col%, BreakBtn
    GuiControl, Panel:, BreakBtn, % BreakMode ? "back" : "break"
}

; Same shape as the break switch above: the word says what the panel is, and
; the colour is what makes it readable at a glance from across the desk.
SetLockBtn() {
    col := PanelLocked ? CText : CDim
    GuiControl, Panel:+c%col%, LockBtn
    GuiControl, Panel:, LockBtn, % PanelLocked ? "locked" : "lock"
}

; The two switches beside the lock. The mode is spelled out here because the
; circle beside the minutes goes away while the panel is not on top; the on-top
; switch is bright while it is on, the way the lock is bright while locked.
SetFootBtns() {
    GuiControl, Panel:, ModeBtn, % Format("{:L}", ModeName())
    col := PanelOnTop ? CText : CDim
    GuiControl, Panel:+c%col%, TopBtn
    GuiControl, Panel:, TopBtn, % PanelOnTop ? "on top" : "top"
}

SetBarColour(colour) {
    GuiControl, Panel:+c%colour%, TopBar
}

; The only animation, and it gives up on an empty chair. One tick per shade over
; eight shades is a ~1.2s cycle - still breathing rather than blinking, but with
; some urgency to it.
Breathe() {
    global BreathStep
    if (EdgeState != 2)
        return
    if (SeenMs() > RedQuietMin * 60000) {
        SetBarColour(CRed)
        return
    }
    static shades := ["8A2A3C", "A33049", "C03A57", "FF4D6D", "C03A57", "A33049"
                    , "8A2A3C", "742536"]
    BreathStep := Mod(BreathStep, shades.Length()) + 1
    SetBarColour(shades[BreathStep])
}

; Counts DOWN inside the 45 minutes, UP once past it. Minutes only, repainted
; once a minute - see the note at the top about why there are no seconds here.
; LastShownMin is a key for what is on screen, prefixed by state, so switching
; state always repaints even when the minute number happens to match.
UpdateTimerText() {
    global LastShownMin
    if (BreakMode || Away) {
        if (BreakMode)
            m := (A_TickCount - BreakStart) // 60000, col := CBreak
        else {
            s := AwayIdleMs // 1000
            m := ((s > AwaySec) ? s : AwaySec) // 60, col := CDim
        }
        key := (BreakMode ? "b" : "a") m
        if (key == LastShownMin)
            return
        LastShownMin := key
        GuiControl, Panel:+c%col%, TimerTxt
        GuiControl, Panel:, TimerTxt, % "away " m "m"
        return
    }
    left := SitBreakMin * 60 - SitSec
    m := (left >= 0) ? Ceil(left / 60) : -Floor(left / 60)
    key := ((left >= 0) ? "l" : CutShort ? "c" : "o") m
    if (key == LastShownMin)
        return
    LastShownMin := key
    ; Overdue and back early from a break: still counting up, but saying why the
    ; bar is still red rather than looking as if the break never happened.
    if (left >= 0)
        txt := m "m left"
    else
        txt := CutShort ? "break cut short +" m "m" : "+" m "m over"
    col := (left >= 0) ? CText : CRed
    ; a colour change on a Text control only shows once its text is set again,
    ; hence the second assignment rather than a redundant one
    GuiControl, Panel:+c%col%, TimerTxt
    GuiControl, Panel:, TimerTxt, %txt%
}

