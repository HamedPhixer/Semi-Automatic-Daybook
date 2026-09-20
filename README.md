# Semi-Automatic Daybook

An always-on-top day panel for Windows. Habits, tasks, and a sit timer that
only counts time you were actually there - all of it written out as plain
markdown, one file per day.

Semi-automatic: it keeps the half of a journal that is counting, and leaves the
half that is thinking to you.

AutoHotkey v1 · Windows only · beta, it has only ever run on one machine

![The panel: habits with their streaks, today's tasks, long term tasks, and where the day went](https://raw.githubusercontent.com/HamedPhixer/Semi-Automatic-Daybook/main/docs/images/panel.png)

## What it does

**Habits.** A tick box, a week of dots and a streak. Green done, red missed,
grey still to do. **Every dot is a button** - click Tuesday's and Tuesday is
ticked, for the evening you did the thing and forgot to say so.

**Tasks.** One list for today, one for later. Tick or cross one and a small box
opens to say why. Anything unfinished carries to tomorrow and asks.

**A sit timer.** Green, amber at 30 minutes, red and breathing at 45. It only
counts time you were there: it watches Windows' own display state, so a film
counts and an empty chair does not.

**An app log.** Which program was in front, by process name, and only while you
were at the desk.

<details>
<summary><b>When does the sit clock reset?</b></summary>

It only counts while you are there. A dark screen, a lock screen or a
screensaver means gone, and so does five minutes without touching anything.
Sound playing counts as sitting - you are watching something - for up to two
hours after your last keypress, so a player left running overnight does not
hold the clock open.

**Five minutes away resets it to zero.** Less than five and it carries on from
where it was, so a coffee or a lock screen never wipes the time you built up,
and a red bar stays red until you actually take the whole five. Come back early
from a break you started while already red and the digits say `break cut
short`.

`Win + F1` declares a break by hand, and that outranks every sensor above - for
when no signal can tell sitting from standing. It ends when you type or click,
but not on mouse movement, so nudging the mouse to keep the screen awake does
not end it.

Amber at 30 minutes and red at 45, five minutes for a break: all settings.

</details>

## The journal

One `YYYY-MM-DD.md` per day, append-only. Nothing already written is ever
rewritten, so you can edit it in Obsidian and Daybook will never fight you.

```
09:14  + added: finish the habit tracker
11:02  ✓ read 20 pages   ·  12 in a row
14:30  ✓ finish the habit tracker
       ↳ took longer than the estimate, as usual

03:00  — day closed
       active 6h 12m
       chrome 2h 41m · Code 1h 58m · slack 22m

## habits

- [x] read 20 pages  (streak:: 12)
- [ ] workout  (streak:: 0)
```

Real checkboxes with Dataview fields, so you can count them across months.
Don't want any of it? Settings → **Keep a journal** → no.

## Keys

| | |
| --- | --- |
| `Win + F6` | hidden → solid → dim → ghost → hidden |
| `Win + F1` | start or end a break |

Everything else is a click on the panel.

## Install

From [Releases](https://github.com/HamedPhixer/Semi-Automatic-Daybook/releases),
either one:

- **`-portable.zip`** - unzip it, run `Start Daybook.bat`. AutoHotkey is in the
  folder; nothing is installed and nothing is left behind.
- **the plain zip** - run `Daybook.ahk`, if you already have
  [AutoHotkey v1.1](https://www.autohotkey.com/download/) (not v2).

It makes its own `Daybook.ini` next to itself, with every setting commented.
Tray icon → **Settings** is the same thing in a window.

![Settings: every setting in one window, each with a line saying what it does](https://raw.githubusercontent.com/HamedPhixer/Semi-Automatic-Daybook/main/docs/images/settings.png)

<details>
<summary><b>Does it spy on me?</b></summary>

No, and here is how to check.

It installs a keyboard hook - and **records nothing from it**. The hook is only
there so Windows keeps its "how long since any input" counters up to date,
which is how the timer knows you are present. No key is read or stored; see
`lib/Presence.ahk`.

**No network, ever.** No update check, no telemetry, no account. Grep for
`WinHttp` or `UrlDownload` and you will find nothing. The one COM object it
creates is Windows' own audio meter, asked whether a sound is playing.

**It writes in two places:** its own folder, and the journal folder you pick.

**Process names, not window titles** - titles carry document names and page
titles, and that folder may be syncing to your phone.

Administrator is off by default. Turning it on (`[General] RunAsAdmin`) buys
one thing: the two keys keep working over windows that are themselves elevated.

</details>

<details>
<summary><b>Not yet</b></summary>

- Long task and habit names are clipped with nothing to show it.
- Weeks, months and years: rolling the daily notes up into a weekly file, then
  monthly, then yearly, with the days moved to an archive.

</details>

## The code

`Daybook.ahk` only starts things; everything else is in `lib/`, listed in
[`lib/All.ahk`](lib/All.ahk). Tests: `tests/run-tests.ps1`. Both zips are built
on GitHub from the tag, by `build.ps1`, after those tests pass.

MIT - see [LICENSE](LICENSE).
