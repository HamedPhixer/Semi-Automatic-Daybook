;================================================================================
; Journal - append only, never rewritten
;================================================================================
JournalFile(day) {
    return JournalDir "\" day ".md"
}

TS() {
    FormatTime, t, , HH:mm
    return t
}

Journal(line) {
    JournalRaw(LogicalDay(), TS() "  " line "`n")
}

JournalNote(line) {
    JournalRaw(LogicalDay(), "       " Chr(0x21B3) " " line "`n")
}

; The one door every journal line goes through, which is what makes turning the
; journal off a single check rather than a flag tested in twenty places.
JournalRaw(day, text) {
    if (!JournalOn)
        return
    if (!InStr(FileExist(JournalDir), "D"))
        FileCreateDir, %JournalDir%
    f := JournalFile(day)
    if (!FileExist(f))
        FileAppend, % "# " day "`n`n", %f%, UTF-8
    FileAppend, %text%, %f%, UTF-8
}

