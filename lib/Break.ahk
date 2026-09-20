;================================================================================
; A break you declared by hand - Win+F1, or the break switch
;================================================================================
; Ground truth, entered by hand. Pressing it says "I am not at this desk" no
; matter what the keyboard, the audio meter or the monitor happen to think.
; The sit clock stops while it is on and nothing is logged to any app. Ending it
; follows the same rule as walking away (CreditBreak): five minutes or more and
; the clock starts clean, less and it carries on from where it was.
ToggleBreak() {
    global BreakMode
    if (BreakMode)
        EndBreak()
    else
        StartBreak()
}

StartBreak() {
    global BreakMode, BreakStart, Away, AwaySec, AwayIdleMs, EdgeState, LastShownMin
    BreakMode := 1
    BreakStart := A_TickCount
    Away := 0, AwaySec := 0, AwayIdleMs := 0
    EdgeState := -1, LastShownMin := 9999
    ApplySitState()
    UpdateTimerText()
}

EndBreak() {
    global BreakMode, Away, AwaySec, AwayIdleMs, EdgeState, LastShownMin, BreakStart
    BreakMode := 0
    Away := 0, AwaySec := 0, AwayIdleMs := 0
    CreditBreak((A_TickCount - BreakStart) // 1000)   ; same rule as walking away
    EdgeState := -1, LastShownMin := 9999
    ApplySitState()
    UpdateTimerText()
}

