;================================================================================
; Review - what the amber + is for. ReviewItem() takes one task on purpose,
; so a due-time timer can call it for a single task later without any of this
; needing to change.
;
; Each entry is {day, id, text}: the day the task was left undone, so the
; answer goes onto that day - see SaveNote().
;================================================================================
StartReview() {
    global ReviewIdx
    if (!ReviewQueue.Length()) {
        QuickAdd()                     ; nothing owed: the dot meant "empty list"
        return
    }
    ReviewIdx := 1
    ReviewItem(ReviewQueue[1])
}

ReviewItem(r) {
    ShowNote("not done " ReviewDayName(r.day) "  -  why?   " r.text)
}

; "yesterday" when it was, the date when the PC was off in between.
ReviewDayName(day) {
    if (day = "" || day = DayShift(LogicalDay(), -1))
        return "yesterday"
    return day
}

NextReview() {
    global ReviewIdx, ReviewQueue
    ReviewIdx += 1
    if (ReviewIdx > ReviewQueue.Length()) {
        ReviewIdx := 0
        ReviewQueue := []
        SaveState()
        Refresh()
        return
    }
    ReviewItem(ReviewQueue[ReviewIdx])
}
