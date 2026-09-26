# Changelog

Notable changes, newest first. The version is in `lib\Config.ahk`
(`DaybookVersion`).

## 0.9.0-beta.2

The road to 1.0: making what is here dependable, and making the journal
something you can read back.

- **The day note is a summary now, not a click log.** Each day's note is yours
  at the top - it opens with a "## my notes" heading waiting for you - and
  Daybook keeps one block at the bottom, between two markers: the day's tasks
  with their notes, the habits with the run each had reached, and the time at
  the machine. Daybook rewrites only that block, as the day goes; whatever you
  write outside it is never touched. Notes from before this version are left
  exactly as they are.
- **Notes belong to their task.** Right-click a task -> Add a note / Edit note,
  and resting the pointer on the task shows it. The note sits beside the task
  in the day's note in Obsidian. Answering "why not?" the next morning puts the
  answer on the day it is about, not on a new day.
- **Daybook.md is where things stand**: today's list and the long term one with
  their notes, the streaks, and two weeks of habits - written by Daybook, one
  way. It replaces Habits.md, which is no longer written and can be deleted.
- **The click log** - added, ticked, renamed, dropped - moved out of the vault
  to log\ beside Daybook, where it is there if a number ever looks wrong.
- **Finished long term tasks** leave the panel when the day closes, the same
  as today's; the day's note has them.
- **Long names** end in "..." instead of being cut mid-letter, and resting the
  pointer on one for half a second shows all of it just under the row.
- **The note box and the task box wrap and grow** as you type, a line at a
  time up to six, instead of sliding the start of what you wrote out of sight
  to the left. Renaming a long task opens the box already tall enough for it.
- **Habits have a rule: every day, every N days, or N times a week** (weeks
  start on Monday, and are what a weekly habit's streak counts). A day the
  rule lets you skip is grey, not red.
- **Rest days**: sick, away, a day off on purpose. A rest day keeps the
  streak alive without adding to it; in a weekly habit it takes one off that
  week's target. Two a month per habit by default (Settings -> Rest days a
  month).
- **Streaks, best and days done are measured, never kept by hand** - worked
  out from the history every time it changes, so a tick taken back, a day
  filled in late, a fortnight with the PC off or a long streak brought in all
  come out right. The whole history is kept (it used to be a year), and any
  day of it can be filled in, not only the week the dots show. By hand, the
  best could outlive the tick that set it, and never saw a run filled in
  afterwards that stops short of today: the 21st to the 24th ticked late, with
  the 25th empty, still said best 3.
- **Edit habit...** (right-click a habit): the name, how often, a month
  calendar - click a day and it goes done, rest day, not done, as far back as
  the habit goes - the streak and the rest days left, and a box to bring in a
  streak you already had somewhere else, 778 days of Duolingo say.
- **The dots explain themselves**: rest the pointer on one and it says which
  day it is, how it stands, and what a click will do.
- **A weekly habit's streak says it is weeks** - 112w on the panel, "112
  weeks" in the window and on the board - rather than looking like a lost
  number of days. Or switch it to count in days (Edit habit -> count in:
  days): the same unbroken run, as the days done inside it.
- **Daybook-state.txt is guarded**: every save is written aside, read back and
  checked before it replaces the file; the file ends by saying how long it is,
  so one cut short is recognised; a backup is kept for each day (backups\, the
  newest 10 and one a month for six months); and a file that cannot be read is
  set aside, never saved over, with the newest good backup loaded instead. A
  day note is copied to backups\notes\ before Daybook first rewrites it, and
  one read back incomplete is never rewritten at all.
- **Ticking a habit for an earlier day** rewrites that day's note too, so the
  note never disagrees with the dots.
- **Time at the machine** kept its morning total in the heading all day
  unless the section was open. It now moves every minute either way.
- **The hour strip** put the small hours at the top. It now runs in the order
  the day did - 03:00 first, 02:00 last.
- **Renaming only the case** of a task or habit ("buy milk" to "buy Milk")
  was ignored. It is a rename now.
- **Tick, then cross** on the same task inside the undo window logged both;
  now only the cross. Unticking after the window logs a reopen.
- **Tasks have ids**, a number each keeps for life, which is what notes and
  finished days are kept by. Daybook-state.txt gains fields at the end of its
  lines, and the version before still reads it.

## 0.9.0-beta.1

First release. Beta because it has only ever run on one machine: everything
here works and is tested, but nothing has met a second screen size, a second
Windows, or anyone else's habits yet.

- **Habits.** A tick box, a week of dots and a streak. Every dot is a button,
  so an evening you forgot can still be ticked, and streaks are worked out from
  the calendar rather than counted up - they survive a reboot or a week away.
- **Tasks**, for today and for the long term. Unfinished ones carry over and
  ask; ticking or dropping one opens a small box to say why.
- **A sit timer** that only counts time you were actually at the desk, and an
  app log by process name.
- **The journal.** One markdown file a day, append-only, closing with a
  `## habits` block of real Dataview checkboxes. It can be switched off
  entirely, and then nothing is written and nothing already there is touched.
- **A settings window** (tray -> Settings) for everything in `Daybook.ini`,
  saved as you change it and in force at once.
- **The panel scrolls** once it outgrows the screen, with the timer pinned to
  the top, and the lock and on-top switches pinned to the bottom.
- **Administrator is off by default**, so a first run opens with no UAC prompt.
- **Two downloads, built on GitHub from the tag** - portable with AutoHotkey in
  the folder, or the app on its own - neither published unless the tests pass.
