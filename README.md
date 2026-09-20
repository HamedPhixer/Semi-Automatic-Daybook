# Semi-Automatic Daybook

A small always-on-top panel for the corner of your screen: today's tasks, the
habits you are trying to keep, how long you have been sitting, and where the
day actually went. Everything it records it also writes as plain markdown, one
file per day, so the record outlives the program.

**Semi-automatic** is the whole idea. It keeps the half of a journal that is
counting - hours, programs, streaks, what you ticked and when - and leaves the
half that is thinking to you. Neither half is much use on its own.

Windows only. AutoHotkey v1. **Beta** - everything here works and is tested,
but it has only ever run on one machine.

![The panel: habits with their streaks, today's tasks, long term tasks, and where the day went](https://raw.githubusercontent.com/HamedPhixer/Semi-Automatic-Daybook/main/docs/images/panel.png)

## What it does

**The bar across the top is a sit timer.** It fills as you sit, turns amber at
30 minutes and red at 45, and the red one breathes. The digits count *down*
inside the 45 minutes and *up* once you are past them, so overstaying is a
number you can see. It stops breathing after 15 minutes with no input at all -
pulsing at an empty chair is what makes people uninstall things like this.

It only counts time you were actually there. Presence comes from Windows' own
display-state signal rather than from watching the keyboard, which gets the one
case that matters right: video players ask Windows to keep the display awake
and music players do not, so two hours of silence with a film on counts and two
hours of silence with the room empty does not. Sound on any output device and
any input - mouse movement included - count too. Win+F1 declares a break by
hand when you want to be sure.

**Habits** are the things you mean to do every day. Each row is a tick box, a
name, a week of dots and a streak:

![A habit row: the tick box, the name, a week of dots and the streak](https://raw.githubusercontent.com/HamedPhixer/Semi-Automatic-Daybook/main/docs/images/habits.png)

Today is the dot on the right. Green is done, red is missed - yesterday
brightest - grey is still to do, and days before you added the habit have no
dot at all. **Every dot is a button**: click Tuesday's and Tuesday is ticked,
for the evening you did the thing and forgot to say so. The streak is green
once today is done, amber while the chain is alive and today is not, and dim at
zero.

**Tasks** are the ordinary kind: a list for today and a list for whatever is
further out. Tick one, cross one, and a small box opens beside it to say why -
optional, Esc skips. Anything still open when the day rolls over is not
deleted; it carries, and the + turns amber until you have said what happened.

**The app log** notes which program is in front while you are at the desk, by
process name, and only while you are present. Walking away with a browser
focused is not three hours of browsing.

**When there is more than fits**, the panel stops growing at the bottom of the
screen and scrolls instead: a slim bar appears down its right edge, and the
wheel moves it while you point at the panel. The top strip - the bar, the
status, the minutes and the break switch - stays put, because a readout you
have to scroll to is not a readout.

How wide it is and how tall it may get are both numbers in Settings, `[Look]
WidthPx` and `MaxHeightPx`. Width takes a reload; everything else in that
window does not.

## The journal

One `YYYY-MM-DD.md` per day, in a folder you choose. It is **append only** -
nothing already written is ever rewritten - which means a power cut can lose at
most the line being typed, and you can edit the files in Obsidian and Daybook
will never fight you.

```
09:14  + added: finish the habit tracker
11:02  ✓ read 20 pages   ·  12 in a row
14:30  ✓ finish the habit tracker
       ↳ took longer than the estimate, as usual

03:00  — day closed
       active 6h 12m
       chrome 2h 41m · Code 1h 58m · slack 22m

## habits

habits-done:: 2/3

- [x] read 20 pages  (streak:: 12)
- [x] workout  (streak:: 4)
- [ ] no sugar  (streak:: 0)
```

The habits block at the end of each day is real markdown checkboxes with
Dataview inline fields, so `TASK` queries can count them across months.
`Habits.md` in the same folder is a scoreboard - current streaks and a grid of
the last two weeks - and is the one generated file that gets rewritten.

If you do not want any of it, Settings → **Keep a journal** → no. Nothing is
written and nothing already there is touched; the panel, the timer and the
streaks carry on.

## Keys

Two, deliberately. Everything else is a click on the panel.

| | |
| --- | --- |
| `Win + F6` | hidden → SOLID → DIM → GHOST → hidden, a step a press |
| `Win + F1` | declare a break by hand, or end one |

GHOST is see-through *and* click-through: the mouse goes straight to whatever
is behind it. Win+F6 is the way back out, which is why the on-panel mode switch
only swaps SOLID and DIM - a click you could not click back from is a trap.

## Settings

![Settings: every setting in one window, each with a line saying what it does](https://raw.githubusercontent.com/HamedPhixer/Semi-Automatic-Daybook/main/docs/images/settings.png)

Tray icon → **Settings**. Every setting is in one window, saved as you change
it and in force the moment it is saved - there is no OK button. The same
settings live in `Daybook.ini` beside the script, where each one carries the
reason as well as the number; a link at the foot of the window opens it. The
file is read once at start, so editing it by hand needs a reload and the window
does not.

## Installing

1. Install [AutoHotkey v1.1](https://www.autohotkey.com/download/) (1.1.33 or
   later). Not v2 - this is written in v1 and says so on the first line.
2. Put this folder anywhere and run `Daybook.ahk`.

On the first run it writes `Daybook.ini` next to itself, with every setting
commented, and `Daybook-state.txt` for what it keeps while it runs. Neither is
in the repository; they are yours.

**Administrator is optional and off by default.** Turn it on with `[General]
RunAsAdmin=1` in `Daybook.ini` and Windows will ask each time you start it. The
only thing it buys is that Win+F6 and Win+F1 keep working while a window that is
itself running as administrator has the focus - Windows does not let an ordinary
program see keys meant for an elevated one. Everything else is the same either
way, and declining the prompt lets Daybook carry on rather than refusing to
start.

**To start it with Windows**, either put a shortcut in your Startup folder, or,
to keep the keys working over elevated windows, make a Task Scheduler task:

* General: *Run only when user is logged on*, *Run with highest privileges*
* Trigger: *At log on*
* Action: *Start a program* - the AutoHotkey v1 exe, with the full path to
  `Daybook.ahk` in quotes as the argument
* Settings: untick *Stop the task if it runs longer than...*

A task set to run with highest privileges does the administrator part for you,
which makes `RunAsAdmin` unnecessary.

## The code

`Daybook.ahk` only starts things. Everything else is in `lib\` -
[`lib\All.ahk`](lib/All.ahk) lists each part and what it does, in the order it
loads. The order matters for exactly the first three files and no others, and
that file explains why.

`tests\` checks the parts that can be checked without a screen - the streak
rules, the calendar arithmetic, and the state file round trip. Run
`tests\run-tests.ps1`.

## What it does to your machine

Worth stating plainly, because "an AutoHotkey script with a keyboard hook"
should make anyone pause:

- **It installs a keyboard and mouse hook, and records nothing from them.**
  The hook exists so Windows will keep `A_TimeIdleKeyboard` and
  `A_TimeIdlePhysical` up to date - "how long since any input" - which is how
  the timer knows whether you are there. No key is read, stored or looked at;
  the mouse hotkeys are pass-through and only write down the time. See
  `lib/Presence.ahk`.
- **It never opens a network connection.** No update check, no telemetry, no
  account, nothing to sign in to - grep for `WinHttp` or `UrlDownload` and you
  will find nothing. It creates exactly one COM object, and it is a local one:
  Windows' own audio meter, asked whether any output device is making a sound.
  That is `BindMeters()` in `lib/Presence.ahk`, and it reads a peak level, not
  audio.
- **It writes in two places**: its own folder (`Daybook.ini`,
  `Daybook-state.txt`) and the journal folder you choose. Nothing else is
  touched, and the daily notes are only ever appended to.
- **It reads which program is in front**, by process name, and only while you
  are at the desk. Not window titles - those carry document names and page
  titles, and this folder may well be syncing to your phone.

## Not yet

Things that are known to be missing rather than forgotten:

- **Long names are cut off with no sign that they were.** A task or habit whose
  name is wider than its card is simply clipped, and nothing says so. It wants
  an ellipsis at least, and the full text on hover.
- **The break rules are not written down here.** How long you have to be away
  for the clock to start clean, what a short break does instead, and what the
  panel says when you come back early - all of it is in the code and in
  `Daybook.ini`, and none of it is in this README.
- **Weeks, months and years.** Days accumulate and a folder of three hundred
  daily notes stops being readable. The plan is to roll them up: a weekly file
  built from the week's numbers - time at the machine, the programs, what was
  ticked and dropped, the habit grid - with the days it was built from moved
  into an archive folder, and the same again for months and years. Aggregated
  by Daybook, with the part that needs a human left blank for you.

## Licence

MIT. See [LICENSE](LICENSE).
