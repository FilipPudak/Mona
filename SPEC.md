# MengaCloud Period Tracker — Spec

## 1. Overview
A Flutter Android app that helps a single user track their menstrual cycle. The user records the start of a period via a list picker (today through last period+1), the app displays the current cycle day number with phase-based coloring, and schedules a local reminder 2 days before the next predicted period. A secondary history screen allows viewing, editing, and deleting past records.

## 2. Goals
- One-screen main experience + secondary history screen.
- Scandinavian white UI: light gray-white background, black text, restrained purple accent.
- Local-only storage via Hive. No accounts, no network, no analytics.
- Local notification scheduled automatically on every period start log.
- Retroactive logging — user can log a period starting up to N days ago.
- Edit or delete past records with Undo.

## 3. Non-Goals
- No multi-user support.
- No prediction beyond a fixed 28-day cycle.
- No symptom logging, mood, flow intensity, or notes.
- No cloud sync, backup, or export.
- No onboarding, settings, or theming controls.
- No iOS in v1.

## 4. Domain Model
- `Period` (Hive typeId 0)
  - `startedDate: DateTime` — mutable, the calendar day the period started.
  - `createdAt: DateTime` — when the record was first logged.
- Only the **most recent** `Period` is used for cycle math. Older records are kept in the Hive box for history and future averaging.

## 5. Cycle Math
- Cycle length: fixed at 28 days.
- Current day: `daysBetween(today, period.startedDate) + 1`, clamped to 1..28.
  - Day 1 = the start date.
  - Day 28 = predicted next start.
- Cycle phase colors: day 1-6 red, day 11-17 green, else black.
- Notification target: `period.startedDate + 26 days` (2 days before day 28).

## 6. UI

### 6.1 Main Screen (`PeriodTrackerScreen`)
- Layout (top to bottom, centered):
  1. App title "MengaCloud" in app bar. Top-right: "History" text button → pushes history screen. On return, screen refreshes (await Navigator.push + setState).
  2. Large day number (50% bigger than default via inner MediaQuery at 1.5x textScaler, on top of global 1.25x) with cycle phase color.
  3. Date caption: formatted current date (e.g. "Sunday, June 15").
  4. Subtitle: "Period may start today." if day ≥ 28.
  5. Single primary button: "Start".
- Button opens a list picker bottom sheet (`PeriodListPicker`) with options from `lastPeriod.startedDate + 1` up to today. Labels: "Today", "Yesterday", "X days ago" with absolute date.
- Selecting a date logs a new period and shows a SnackBar with Undo (`persist: false`).

### 6.2 History Screen (`HistoryScreen`)
- StatefulWidget. "+" button in app bar opens calendar picker (`PeriodCalendar`) for logging a past period.
- Calendar: past dates only (today+future grayed), dots on dates that already have logs, 365-day cap back, Cancel + Confirm buttons.
- List of past periods (newest first) using `PeriodRow` widgets.
- Swipe-to-delete: latest/active period protected from deletion. Shows SnackBar with Undo (`persist: false`).
- Tap row: opens calendar pre-selected to that record's date for editing. Shows SnackBar with Undo on confirm.
- Empty state: "No periods logged yet." centered.

### 6.3 Palette
- Background `#F5F7FA`
- Surface (cards/button): `#FFFFFF`
- Primary text: `Colors.black87`
- Accent: `Colors.purple` (seed) — used sparingly for buttons.

### 6.4 Typography
- Font: ISOCPEUR, bundled at `fonts/ISOCPEUR.ttf`.
- `ThemeData.fontFamily: 'ISOCPEUR'` in main.dart for global inheritance.
- `FilledButton.styleFrom(textStyle: ...)` must include `fontFamily: 'ISOCPEUR'`.
- Global 125% text scaling via `MediaQuery(textScaler: TextScaler.linear(1.25))`.
- Day number: inner MediaQuery at `TextScaler.linear(1.5)` for 50% bigger than default.

## 7. Notifications
- Library: `flutter_local_notifications` (v17+).
- Channels: Android channel id `period_reminder`, name "Period reminders", high importance.
- Scheduling: on every period start log, cancel any pending reminders and schedule one at `startedDate + 26 days` at 09:00 local time.
- Notification body: "Your period may start in 2 days."
- Tapping notification opens app to main screen.

## 8. Persistence
- Hive box name: `periods`, type `Box<Period>`.
- Open in `main()` before `runApp()`.
- Reading the current period: `box.values.last` (sorted by `startedDate`).
- Writing: create a new `Period` and `box.add(period)`.
- Editing: update `startedDate` on existing record, then `record.save()`.
- Deleting: `record.delete()`.

## 9. SnackBar Rules
- Every log, delete, and edit action must show a SnackBar with an Undo action.
- All SnackBars with actions must set `persist: false` (Flutter 3.44 breaking change — default changed to `persist: true` causing non-dismissing snackbars).

## 10. File Layout
```
lib/
  main.dart
  models/period.dart
  screens/period_tracker_screen.dart
  screens/history_screen.dart
  services/notification_service.dart
  services/period_repository.dart
  widgets/day_counter.dart
  widgets/period_list_picker.dart
  widgets/period_calendar.dart
  widgets/period_row.dart
fonts/
  ISOCPEUR.ttf
```

## 11. Platform Setup
- Android: `minSdkVersion 21`, add `android.permission.POST_NOTIFICATIONS` and `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` in `AndroidManifest.xml`. Use `AndroidScheduleMode.exactAllowWhileIdle`.

## 12. Out-of-Scope / Future Work
- Cycle length averaging.
- iOS support.
- Localization beyond English.
- Dark mode.
