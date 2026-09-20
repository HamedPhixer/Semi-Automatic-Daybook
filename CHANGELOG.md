# Changelog

Notable changes, newest first. The version is in `lib\Config.ahk`
(`DaybookVersion`).

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
