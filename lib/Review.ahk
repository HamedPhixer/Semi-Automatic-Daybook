;================================================================================
; Review - what the amber + is for. ReviewItem() takes one task on purpose,
; so a due-time timer can call it for a single task later without any of this
; needing to change.
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

ReviewItem(text) {
    ShowNote("yesterday: " text "  -  why not?")
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

