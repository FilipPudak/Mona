# MengaCloud Period Tracker — Spec

## 1. Overview
A Flutter app for Android and iOS that helps a single user track their menstrual
cycle. The user records the start of a period with one tap, the app displays the
current cycle day (out of 28), and schedules a local reminder 2 days before the
next predicted period.

## 2. Goals
- One-screen experience: a single primary action ("Period Started Today").
- Scandinavian white UI: light gray-white background, plenty of whitespace, black
  text, restrained accent color.
- Local-only storage. No accounts, no network, no analytics.
- Local notification scheduled automatically on every "Period Started" tap.

## 3. Non-Goals
- No multi-user support.
- No prediction beyond a fixed 28-day cycle.
- No symptom logging, mood, flow intensity, or notes.
- No cloud sync, backup, or export.
- No onboarding, settings, or theming controls in v1.

## 4. Domain Model
- `Period` (Hive typeId 0)
  - `startedDate: DateTime` — the calendar day the user tapped the button.
  - `currentDayCounter: int` — days elapsed since `startedDate` (0 = day 1).
    - Stored value of `-1` means the record is pending (legacy/seeded).
- Only the **most recent** `Period` is used at runtime. Older records are kept
  in the Hive box for future averaging but are not consulted in v1.
- Tapping is only allowed once per day, guard added for this.

## 5. Cycle Math
- Cycle length: fixed at 28 days.
- Current day: `daysBetween(today, period.startedDate) + 1`, clamped to 1..28.
  - Day 1 = the start date.
  - Day 28 = predicted next start.
- Notification target: `period.startedDate + 26 days` (2 days before day 28).

## 6. UI
- Single home screen: `PeriodTrackerScreen`.
- Layout (top to bottom, centered):
  1. App title in app bar: "MengaCloud". Top-right action: a "History" text
     button that pushes the history screen via `Navigator.push`.
  2. Large display: `Day X` with a smaller `of 28` subtitle.
  3. Caption line: "Next period in N days" or "Period may start today" on day 28.
  4. Single primary button: "Period Started Today".
- Scandinavian palette:
  - Background `#F5F7FA`
  - Surface (cards/button): `#FFFFFF`
  - Primary text: `Colors.black87`
  - Accent: `Colors.purple` (seed) — used sparingly for the button.
- Typography: large number uses the default display medium style.

## 7. Notifications
- Library: `flutter_local_notifications` (v17+).
- Plugin added: replace the existing `workmanager` dependency with
  `flutter_local_notifications`, `timezone`, and `flutter_timezone`.
- Channels:
  - Android: channel id `period_reminder`, name "Period reminders",
    high importance.
  - iOS: request authorization on first launch.
- Scheduling:
  - On every "Period Started Today" tap, cancel any pending period reminders
    and schedule one new notification at `startedDate + 26 days` at 09:00
    local time.
  - Notification body: "Your period may start in 2 days."
- Tapping the notification: opens the app to `PeriodTrackerScreen`.

## 8. Persistence
- Hive box name: `periods`, type `Box<Period>`.
- Open in `main()` before `runApp()`.
- Reading the current period: `box.values.last` (sorted by `startedDate`).
- Writing: create a new `Period` and `box.add(period)`. No editing of past
  records in v1.

## 9. File Layout
```
lib/
  main.dart
  models/period.dart
  screens/period_tracker_screen.dart
  screens/history_screen.dart
  services/notification_service.dart
  services/period_repository.dart
  widgets/day_counter.dart
  widgets/period_row.dart
```

## 10. Platform Setup (out of code, in docs/README)
- Android: `minSdkVersion 21`, add
  `android.permission.POST_NOTIFICATIONS` and `SCHEDULE_EXACT_ALARM` /
  `USE_EXACT_ALARM` in `AndroidManifest.xml`. Use `AndroidScheduleMode.exactAllowWhileIdle`.
- iOS: add `NSUserNotificationsUsageDescription` if needed; request
  authorization at runtime.

## 11. History View

- Read-only list of the user's most recent periods, newest first.
- Capped at the 12 most recent entries; older records remain in storage
  but are not displayed. (See SPEC v2 decision: "last 12 cycles" rather
  than "last 12 calendar months".)
- Entry point: a "History" text button in the home screen app bar.
- Each row: full date in long format (e.g. "Monday, 10 June") with a
  hairline divider below. No card chrome, no icons, no per-row actions.
- Empty state: "No periods logged yet." centered on the screen.
- No edit, delete, cycle-length average, or calendar grid in v2.

## 12. Out-of-Scope / Future Work
- Cycle length averaging.
- History view of past periods.
- Edit/cancel a logged period.
- Localization beyond English.
- Dark mode.
