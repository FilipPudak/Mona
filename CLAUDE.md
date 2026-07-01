# Mona — Period Tracker

## Design
Scandinavian-minimal Flutter period tracker. Light gray-white bg, black text, restrained purple seed color. Segoe UI typography.

## Tech Stack
- Flutter 3.38.10 (all platforms), Dart 3.x
- Local-only: Hive (no accounts, network, analytics)
- Notifications: flutter_local_notifications
- Target: Android (emulator sdk gphone16k x86 64, API 37)

## Key UI Rules
- **One screen** main tracker + secondary history screen
- Main screen rose `+` circle button opens a list picker (range: last period+1 to today); centered on first launch, bottom-anchored after first period
- History `+` button opens calendar picker (past only, 365-day cap, dots on logged dates)
- List picker labels: "Today", "Yesterday", "X days ago" with absolute date
- Calendar: past dates selectable, today+future grayed, Cancel + Confirm; Confirm disabled when no date chosen
- Calendar: Cancel top-left, Confirm bottom-right
- Swipe-to-delete on history rows (all periods deletable, including active)
- Tap row to edit: opens calendar pre-selected to that record's date
- SnackBar Undo after every log, delete, and edit action (3.5s duration)
- Cycle colors: day 1-6 rose (#E68192), fertile window green (ovulationDay ± 3 where ovulationDay = cycleLength - 14), else black
- Day counter: raw days since last period (1-based), capped at 99 for display (99+)
- Expected date: bare date (`DD/MM` or `MM/DD`), no prefix text, no caption
- Overdue: day counter dims (0.38 opacity, except rose phase stays full), expected date dims, + button pulses (1.08x scale oscillation)
- Day number: 50% bigger than default (1.5x textScaler override on top of 1.25x global)
- Global text scaling: 125% via `TextScaler.linear(1.25)` in `MediaQuery`
- Font: Segoe UI (system font on Windows)
- `startedDate` on Period model is mutable (not final)
- No future dates or today in calendar; today logged from main screen button
- `FilledButton.styleFrom(textStyle: ...)` must include `fontFamily: 'Segoe UI'`
- `ThemeData.fontFamily: 'Segoe UI'` in main.dart
- Settings gear icon in app bar; radio buttons for tracking mode; cycle length picker bounded 21–45; days-before picker 1–5 (disabled when notification OFF); notification toggle cancels/reschedules
- Settings: merged "Reminder" section with "Days before" row + "Notification" switch (singular); days-before row grayed/disabled when notification OFF

## Project State
### Done
- List picker bottom sheet (`lib/widgets/period_list_picker.dart`)
- Calendar picker with dots, disabled dates, Cancel/Confirm (`lib/widgets/period_calendar.dart`)
- Main screen: rose `+` circle button, list picker, Undo snackbar, bare expected date, 99+ counter, dynamic fertile window, overdue dim/pulse (`lib/screens/period_tracker_screen.dart`)
- History screen: StatefulWidget, `+` button, calendar picker, swipe-to-delete (all periods), tap-to-edit, Undo (`lib/screens/history_screen.dart`)
- PeriodRow `onTap` callback (`lib/widgets/period_row.dart`)
- Day counter: raw days, 99+ cap, color parameter, 1.5x textScaler (`lib/widgets/day_counter.dart`)
- Period model (`lib/models/period.dart`)
- Settings model in dedicated Hive box (`lib/models/settings.dart`)
- Settings screen: merged Reminder section, "Days before" row, "Notification" (singular) switch, date format toggle (`lib/screens/settings_screen.dart`)
- `RadioGroup` widget replacing deprecated `RadioListTile.groupValue`/`onChanged` (`lib/widgets/radio_group.dart`)
- Repository: `dayOfCycle()` (raw, capped 99), `isOverdue()`, `fertileWindow()`, `phaseColor()`, `loggedDates()`, `rescheduleReminder()` (`lib/services/period_repository.dart`)
- Notification service: cancel all / reschedule reminder (`lib/services/notification_service.dart`)
- Global font via `ThemeData.fontFamily` in `main.dart`
- Explicit `fontFamily: 'Segoe UI'` on FilledButton text style
- Global 125% text scaling via `MediaQuery(textScaler: TextScaler.linear(1.25))`
- Main screen refreshes on return from history
- Number picker widget (`lib/widgets/number_picker.dart`)
- `pumpUntilSettled()` avoids `pumpAndSettle` deadlock from pulse animation (`test/test_helpers.dart`)
- `prepopulate()` seeds Hive boxes for tests (`test/test_helpers.dart`)

### All PRD items implemented

## Pre-commit Checks
- Run `scripts/pre-commit` before every commit: `dart format`, `flutter analyze`, `flutter test`
- Install the hook: `Copy-Item scripts/pre-commit .git/hooks/pre-commit -Force` (Windows) or `cp scripts/pre-commit .git/hooks/pre-commit` (macOS/Linux)
- Note: `set -e` is not used in the script because `dart format` would abort before `git add -A` re-stages formatted files.

## Build Scripts
- `scripts/build_ios.sh` — builds a release `.ipa` for SideStore sideloading (run on macOS; use `--debug` for debug builds)

## Relevant Files
- `lib/widgets/period_list_picker.dart`
- `lib/widgets/period_calendar.dart`
- `lib/screens/period_tracker_screen.dart`
- `lib/screens/history_screen.dart`
- `lib/screens/settings_screen.dart`
- `lib/widgets/day_counter.dart`
- `lib/widgets/period_row.dart`
- `lib/widgets/radio_group.dart`
- `lib/widgets/number_picker.dart`
- `lib/models/period.dart`
- `lib/models/settings.dart`
- `lib/services/period_repository.dart`
- `lib/services/notification_service.dart`
- `lib/main.dart`
- `test/test_helpers.dart`
- `test/widget_test.dart`
- `test/repository_test.dart`
- `pubspec.yaml`
- `docs/001-merged-reminder-section.md`
- `docs/002-main-screen-redesign.md`
- `docs/PRD.md`
- `docs/ProductBrief.md`
- `docs/CONTEXT.md`

## Domain Model (from CONTEXT.md — read before editing)
- **Tracking**: Hybrid mode (default automatic 28, auto enabled by default — kicks in silently after 3 complete cycles, always switchable)
- **Auto averaging**: caps individual cycle lengths at 42 days
- **Prediction**: `dueDate = lastPeriodStart + cycleLength`; `ovulationDay = cycleLength - 14`
- **Overdue**: `today > dueDate`; counter dims, date dims, button pulses; no caption text
- **Input**: no validation — trust user; correction via edit/delete
- **Editing**: allowed on any period, including active
- **Day counter**: raw days-since (1-based, capped at 99), not capped at cycle length
- **Fertile window**: green phase = `ovulationDay ± 3` (dynamic)
- **Settings**: saved to separate `Settings` Hive box (not on Period model); includes `trackingMode`, `manualCycleLength`, `reminderDaysBefore`, `dateFormat`
- **Notifications**: single notification; cancel on toggle OFF, reschedule on toggle ON; `rescheduleReminder()` handles both

## Developer Notes
- `textScaleFactor` is deprecated; use `TextScaler` instead
- Settings setters are void (fire-and-forget); `.then()` catches all errors, not just `HiveError`
- No migration code needed (`_migrateSettingsIfNeeded` removed — no users)
- No `// ignore_for_file: deprecated_member_use` needed (targeting Flutter 3.38.10)
- Test pattern: use `prepopulate()` in `setUp` to seed Hive boxes, `pumpUntilSettled()` to avoid pulse-animation deadlock
- Calendar Confirm button disabled when no date selected; Cancel always enabled
- `dart format` uses `--set-exit-if-changed` only in CI; pre-commit hook runs plain `dart format` + `git add -A`
