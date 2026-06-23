# Mona — Period Tracker

## Design
Scandinavian-minimal Flutter period tracker. Light gray-white bg, black text, restrained purple seed color. ISOCPEUR typography.

## Tech Stack
- Flutter 3.44.1, Dart 3.x
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
- All SnackBars with actions must set `persist: false` (Flutter 3.44 breaking change)
- Cycle colors: day 1-6 #E68192, day 11-17 green, else black
- Main screen: formatted date caption (e.g. "Sunday, June 15"), "Period may start today" if due
- Day number: 50% bigger than default (1.5x textScaler override on top of 1.25x global)
- Global text scaling: 125% via `TextScaler.linear(1.25)` in `MediaQuery`
- Font: ISOCPEUR, bundled at `fonts/ISOCPEUR.ttf`
- `startedDate` on Period model is mutable (not final)
- No future dates or today in calendar; today logged from main screen button
- `FilledButton.styleFrom(textStyle: ...)` must include `fontFamily: 'ISOCPEUR'`
- `ThemeData.fontFamily: 'ISOCPEUR'` in main.dart

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
- Global font via `ThemeData.fontFamily` + font bundle in `pubspec.yaml`
- Explicit `fontFamily: 'ISOCPEUR'` on FilledButton text style
- Global 125% text scaling via `MediaQuery(textScaler: TextScaler.linear(1.25))`
- Button text: "Start"
- `persist: false` on all action SnackBars
- Main screen refreshes on return from history (await Navigator.push + setState)
- Day number at 1.5x textScaler (via inner MediaQuery in `day_counter.dart`)

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
- `fonts/ISOCPEUR.ttf`

## Developer Notes
- `textScaleFactor` is deprecated; use `TextScaler` instead
