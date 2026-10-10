;================================================================================
; SeenAt.ahk - is this window the one you actually see at a point on the screen
;================================================================================
; A panel that reacts to the pointer usually asks "is the pointer inside my
; rectangle". That is wrong whenever another window sits on top of the panel:
; the pointer is on THAT window, yet the panel lights up, changes its opacity,
; or pops a tooltip over somebody else's app.
;
; WindowFromPoint asks Windows which window is really under the point. It skips
; hidden and cloaked windows, and the ones the mouse passes through
; (WS_EX_TRANSPARENT - GHOST mode, the OSDs) - and that last part means a GHOST
; panel never answers for itself. So when the window found is not ours, walk the
; z-order (the front-to-back stacking of windows) from ours towards the front:
; meeting the window found means it is in front of ours and covers it; running
; out means it is behind ours, and ours is the one on top at that point.
;
; Shared as it is between scripts kept apart: AHK\lib (Hub, Stats, TTS) and a
; copy in Daybook\lib, which is its own repo. Keep the copies identical - edit both.
;================================================================================
WindowSeenAt(hwnd, x, y) {
    ; a POINT goes by value - 8 bytes, x in the low half
    hit := DllCall("WindowFromPoint", "Int64", (y << 32) | (x & 0xFFFFFFFF), "Ptr")
    if (!hit)
        return false
    root := DllCall("GetAncestor", "Ptr", hit, "UInt", 2, "Ptr")     ; GA_ROOT
    if (root = hwnd)
        return true
    w := hwnd
    Loop, 2000 {
        w := DllCall("GetWindow", "Ptr", w, "UInt", 3, "Ptr")        ; GW_HWNDPREV: one nearer the front
        if (!w)
            return true
        if (w = root)
            return false
    }
    return true
}
