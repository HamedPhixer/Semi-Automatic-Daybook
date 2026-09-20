;================================================================================
; Hotkeys
;================================================================================
; Mode and always on top are switches on the panel, and adding a task is its +.
#F6::CyclePanel()
#F1::ToggleBreak()

; Mouse clicks and wheel events count as presence; mouse MOVEMENT does not.
; "~" passes every one of them straight through, so nothing is swallowed or
; delayed - these exist only to leave a timestamp. IdleMs() explains why it has
; to be done by hand instead of read from a built-in variable.
~LButton::
~RButton::
~MButton::
~XButton1::
~XButton2::
~WheelUp::
~WheelDown::
~WheelLeft::
~WheelRight::
    LastClickTick := A_TickCount
Return

; The wheel, while the pointer is on a panel that has more in it than fits.
;
; It has to be a hotkey rather than a WM_MOUSEWHEEL handler: the wheel goes to
; whatever holds the keyboard focus, and this panel is built never to take the
; focus from anything (WS_EX_NOACTIVATE), so the message would never arrive.
; These take the wheel rather than passing it on - scrolling the window behind
; a panel you are pointing at is not what anybody means - and the plain
; ~WheelUp above still answers everywhere else.
#If PanelCanScroll()
WheelUp::PanelScroll(-1)
WheelDown::PanelScroll(1)
#If

