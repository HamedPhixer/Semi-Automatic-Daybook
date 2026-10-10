;================================================================================
; Taskbar.ahk - a taskbar button of a script's own
;================================================================================
; Windows puts every window of the same program file under one taskbar button,
; and every v1 script runs on the same AutoHotkeyU64.exe - so two scripts' own
; windows end up behind one button. A window that carries an app id
; (AppUserModelID, the name tag the taskbar groups by) gets a button of its
; own; windows with the same id share one. The button's picture is the
; window's own icon.
;
; Call it on the new, still hidden window, before its first Show: the taskbar
; reads the id when it makes the button. Pass "" to take the id off again - do
; that before a window is destroyed, so the shell lets go of it.
;
; A compiled script is its own .exe and has its own button already, and a
; shortcut pinned to that .exe only matches windows WITHOUT an id - so there
; nothing is done.
;
; Shared as it is between scripts kept apart: AHK\lib (Hub, STT) and a copy in
; Daybook\lib, which is its own repo. Keep the copies identical - edit both.
;================================================================================
TaskbarId(hwnd, id) {
    if (A_IsCompiled)
        return false
    VarSetCapacity(iid, 16, 0)
    DllCall("ole32\CLSIDFromString", "wstr", "{886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99}", "ptr", &iid)  ; IPropertyStore
    ps := 0
    if (DllCall("shell32\SHGetPropertyStoreForWindow", "ptr", hwnd, "ptr", &iid, "ptr*", ps) || !ps)
        return false
    VarSetCapacity(pk, 20, 0)                                              ; PKEY_AppUserModel_ID
    DllCall("ole32\CLSIDFromString", "wstr", "{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}", "ptr", &pk)
    NumPut(5, pk, 16, "uint")
    VarSetCapacity(pv, 24, 0)                                              ; VT_EMPTY takes it off
    if (id != "") {
        NumPut(31, pv, 0, "ushort")                                        ; VT_LPWSTR
        NumPut(&id, pv, 8, "ptr")
    }
    hr := DllCall(NumGet(NumGet(ps+0) + 6*A_PtrSize), "ptr", ps, "ptr", &pk, "ptr", &pv)  ; SetValue
    if (hr = 0)
        hr := DllCall(NumGet(NumGet(ps+0) + 7*A_PtrSize), "ptr", ps)      ; Commit
    ObjRelease(ps)
    return hr = 0
}
