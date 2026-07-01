# PRD: Merge Reminder and Notifications Sections in Settings

## Problem Statement

The Settings screen currently has a conceptual disconnect between "Reminder" (when to send) and "Notifications" (whether to send) as two separate, visually unrelated sections. Users cannot tell that the reminder days-before setting only takes effect when notifications are enabled. There is no feedback when notifications are OFF — the days-before picker remains fully tappable despite having no effect.

Additionally, the notifications switch uses plural "Notifications" while the app only ever schedules a single notification.

## Solution

Merge the Reminder and Notifications sections into a single **Reminder** section with two interrelated controls:

1. **Days before** — a picker row that is enabled (tappable, with chevron) when notifications are ON, and disabled (gray text, no chevron, not tappable) when notifications are OFF.
2. **Notification** — an ON/OFF switch that gates the above row.

The merged section makes the dependency visually obvious. The value is preserved while disabled, matching how cycle length shows the manual value even in automatic mode.

## User Stories

1. As a user, I want the reminder timing control and the notification toggle to live under one section header, so that I understand they are part of the same feature.

2. As a user who turns notifications OFF, I want the "Days before" row to become disabled (grayed, no chevron), so that I know the setting won't take effect.

3. As a user who turns notifications OFF, I want the "Days before" value to remain unchanged, so that when I re-enable notifications my preferred timing is still set.

4. As a user who turns notifications ON, I want the "Days before" row to become enabled again (tappable, with chevron), so that I can adjust when the reminder fires.

5. As a user, I want the switch label to say "Notification" (singular), so that the label matches the actual behavior — one notification at a time.

6. As a user, I want to navigate to the Settings screen and see a clear, scannable layout, so that I can find and change the settings I need.

7. As a user enabling notifications, I want any pending reminder to be rescheduled with my latest data, so that the notification fires at the right time.

8. As a user disabling notifications, I want all pending reminders cancelled immediately, so that I stop getting alerts.

9. As a user editing settings, I want changes to persist across app restarts, so that I don't have to reconfigure every time I open the app.

## Implementation Decisions

### Section merge

The "Reminder" and "Notifications" section headers are merged into a single "Reminder" section containing both rows. The row formerly titled "Reminder" is renamed to "Days before". The switch label is renamed from "Notifications" to "Notification" (singular).

### Conditional disable pattern

The "Days before" row mirrors the existing cycle-length-in-automatic-mode pattern:

- **Notifications ON**: row is tappable, shows `"X days before"` in normal weight, includes a chevron icon. Tapping opens the scroll picker (1–5 days).
- **Notifications OFF**: row is not tappable, text is grayed, chevron is hidden. The value is preserved and visible.

### No data model change

The `reminderDaysBefore` field on the `Period` model is unchanged. The `_notificationsOn` state variable already exists as local widget state in `_SettingsScreenState` (not persisted — defaults to `true` on each app launch). The notification toggle's behavior (cancel/reschedule) is also unchanged.

### Notification service behavior

No changes to `NotificationService`. The existing toggle logic — cancel on OFF, reschedule on ON — remains the same. The label change ("Notifications" → "Notification") is purely a display change.

## Testing Decisions

### What makes a good test

Tests should verify external behavior: what the user sees and can interact with. They should not assert implementation details like section header widget types or internal state variable values.

### Seam: Widget tests (`test/widget_test.dart`)

A single testing seam at the widget level. No new files.

**Existing tests to update:**
- `Settings screen shows tracking mode options`: update assertions — "Reminder" section header still present but row label changes to "Days before"; "Notifications" section header removed; switch label changes to "Notification".
- `Settings: notifications switch toggles`: still works as-is (Switch remains at the same position in the widget tree).

**New tests:**
- `Settings shows merged Reminder section`: verify section header "Reminder", row label "Days before", switch label "Notification".
- `Days before row disabled when notifications OFF`: navigate to settings, find the Switch, toggle OFF, then verify the adjacent "Days before" row has no chevron, text appears gray, and tapping it does not open a picker.
- `Days before row enabled when notifications ON`: with notifications ON (default), verify the "Days before" row has a chevron and tapping opens the picker.

### Prior art

The existing `test/widget_test.dart` tests render `SettingsScreen` directly via `MaterialApp(home: SettingsScreen())` or navigate to it via the gear icon. New tests follow the same patterns. No mocking framework is used — Hive is initialized in a temp directory in `setUp`.

## Out of Scope

- Changing the notification message content or timing logic
- Persisting the notifications ON/OFF state across app restarts
- Adding new picker values (the 1–5 day range is unchanged)
- Any changes to the main screen, history screen, or other settings sections

## Further Notes

- The existing `// ignore_for_file: deprecated_member_use` at the top of `settings_screen.dart` was a Flutter 3.27.4 compat artifact and has been removed (app now targets 3.38.10).
