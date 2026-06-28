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
- Main "Start" button opens a list picker (range: last period+1 to today)
- History "+" button opens calendar picker (past only, 365-day cap, dots on logged dates)
- List picker labels: "Today", "Yesterday", "X days ago" with absolute date
- Calendar: past dates selectable, today+future grayed, Cancel + Confirm
- Swipe-to-delete on history rows (latest/active period protected)
- Tap row to edit: opens calendar pre-selected to that record's date
- SnackBar Undo after every log, delete, and edit action
- Cycle colors: day 1-6 #E68192, day 11-17 green, else black
- Main screen: day counter (capped at cycle length) + expected date caption ("Next: June 28"), "Period may start today" through due+7d, then "Log your new period"
- Day number: 50% bigger than default (1.5x textScaler override on top of 1.25x global)
- Global text scaling: 125% via `TextScaler.linear(1.25)` in `MediaQuery`
- Font: Segoe UI (system font on Windows)
- `startedDate` on Period model is mutable (not final)
- No future dates or today in calendar; today logged from main screen button
- `FilledButton.styleFrom(textStyle: ...)` must include `fontFamily: 'Segoe UI'`
- `ThemeData.fontFamily: 'Segoe UI'` in main.dart
- Settings gear icon in app bar; radio buttons for tracking mode; cycle length picker bounded 21–45; reminder picker 1–5 days; notifications toggle cancels/reschedules

## Project State
### Done
- List picker bottom sheet (`lib/widgets/period_list_picker.dart`)
- Calendar picker with dots, disabled dates, Cancel/Confirm (`lib/widgets/period_calendar.dart`)
- Main screen: button, list picker, Undo snackbar, date caption, cycle color phases (`lib/screens/period_tracker_screen.dart`)
- History screen: StatefulWidget, "+" button, calendar picker, swipe-to-delete, tap-to-edit, Undo (`lib/screens/history_screen.dart`)
- PeriodRow `onTap` callback (`lib/widgets/period_row.dart`)
- Day counter shows just day number with color parameter (`lib/widgets/day_counter.dart`)
- Period model with mutable `startedDate` (`lib/models/period.dart`)
- Const lint fix (`lib/services/period_repository.dart`)
- Global font via `ThemeData.fontFamily` in `main.dart`
- Explicit `fontFamily: 'Segoe UI'` on FilledButton text style
- Global 125% text scaling via `MediaQuery(textScaler: TextScaler.linear(1.25))`
- Button text: "Start"
- Main screen refreshes on return from history (await Navigator.push + setState)
- Day number at 1.5x textScaler (via inner MediaQuery in `day_counter.dart`)

### All PRD items implemented

## Pre-commit Checks
- Run `scripts/pre-commit` before every commit: `dart format`, `flutter analyze`, `flutter test`
- Install the hook: `Copy-Item scripts/pre-commit .git/hooks/pre-commit -Force` (Windows) or `cp scripts/pre-commit .git/hooks/pre-commit` (macOS/Linux)

## Build Scripts
- `scripts/build_ios.sh` — builds a debug `.ipa` for SideStore deployment (run on macOS)

## Relevant Files
- `lib/widgets/period_list_picker.dart`
- `lib/widgets/period_calendar.dart`
- `lib/screens/period_tracker_screen.dart`
- `lib/screens/history_screen.dart`
- `lib/widgets/day_counter.dart`
- `lib/widgets/period_row.dart`
- `lib/models/period.dart`
- `lib/services/period_repository.dart`
- `lib/services/notification_service.dart`
- `lib/main.dart`
- `pubspec.yaml`
- `fonts/ISOCPEUR.ttf` (replaced by system Segoe UI)
- `docs/PRD.md`
- `docs/ProductBrief.md`

## Domain Model (from CONTEXT.md — read before editing)
- **Tracking**: Hybrid mode (manual default 28, auto enabled by default — kicks in silently after 3 complete cycles, always switchable)
- **Auto averaging**: caps individual cycle lengths at 42 days
- **Prediction**: `dueDate = lastPeriodStart + cycleLength`
- **Overdue**: day counter plateaus at cycle length; caption "Period may start today" for 7 days, then "Log your new period"
- **Input**: no validation — trust user; correction via edit/delete
- **Editing**: allowed on any period, including active
- **Day counter**: cycle-day convention (1-based, capped at cycle length), not raw days-since

## Developer Notes
- `textScaleFactor` is deprecated; use `TextScaler` instead
