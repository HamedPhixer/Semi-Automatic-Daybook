# Changelog

Notable changes, newest first. The version is in `lib\Config.ahk`
(`DaybookVersion`).

## 0.9.0-beta.1

First release as a folder of its own. Beta because it has only ever run on one
machine: everything here works and is tested, but nothing has met a second
screen size, a second Windows, or anyone else's habits yet.

### Added
- **Habits.** A section of its own at the top of the panel: a tick box, a name,
  a week of dots and a streak. Every dot is a button, so a day you forgot to
  tick can still be ticked. Streaks are checked against the calendar, so they
  survive a reboot, a crash, and the script being closed for a week.
- **The Obsidian side of habits.** Each tick is a line in that day's note; each
  day closes with a `## habits` block of real markdown checkboxes carrying
  Dataview inline fields; `Habits.md` in the journal folder is a scoreboard
  with a grid of the last two weeks.
- **A settings window** (tray → Settings). Every setting in one place, saved as
  you change it and in force at once. It scrolls and can be dragged taller.
- **The journal can be switched off** - `[Journal] Write`. Nothing is written
  and nothing already there is touched; the panel, the timer and the streaks
  carry on.
- **Scrolling.** The panel stops growing at the bottom of the screen and
  scrolls instead - a slim bar down its right edge, the wheel while you point
  at it - with the sit timer and the status pinned at the top. `[Look]
  MaxHeightPx` caps it lower if you would rather.
- **The panel's width is a setting** - `[Look] WidthPx`, 240 to 700. Every
  horizontal position inside it is worked out from that one number.
- **Square corners everywhere, or round ones everywhere.** `[Look]
  RoundedCorners` decides for the panel, the settings window and the two little
  boxes at once; square is the default. Windows 10 ignores it.
- **Administrator is now optional and off by default** - `[General]
  RunAsAdmin`. It only ever bought the two keys working over elevated windows;
  a first run no longer opens with a UAC prompt, and declining one lets Daybook
  carry on instead of refusing to start.
- The footer - the keys, and the mode / on top / lock switches - **stays on the
  bottom edge** while the rest scrolls, the same way the sit timer stays on top.
- The tray icon is no longer a row in the settings window. It is still
  `[Files] TrayIcon` in the .ini, where its explanation is.
- The settings window's scrollbar is **painted, not a Windows scrollbar** - the
  same three-pixel strip the panel draws, so the two windows look like one
  program. Click or drag it, or use the wheel.
- `tests\run-tests.ps1`, covering the streak rules, the calendar arithmetic and
  the state file round trip.

### Changed
- Split from one 2,400-line file into `Daybook.ahk` plus `lib\`, listed in
  `lib\All.ahk`.
- Panel order is now HABITS, TODAY'S TASKS, LONG TERM TASKS, TIME AT THE
  MACHINE. "LATER TASKS" was renamed "LONG TERM TASKS"; an existing `.ini`
  still opens the section as you left it.
- Settings used to be two tray items doing the same thing. Now it is one
  window, with a link at its foot to the file.
- The tray icon defaults to the built-in one, and a bare file name in the
  `.ini` means a file next to `Daybook.ahk`, so an icon travels with the folder.
- Sound is read from every playback device rather than only the default one,
  and any input counts as presence, mouse movement included.
