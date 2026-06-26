# PRD: Align Mona App with Domain Model — Hybrid Tracking, Prediction UI, and Settings

## Problem Statement

Mona currently hardcodes a 28-day cycle throughout the app. The main screen shows today's date instead of the expected next period date — which is the one piece of information the user opens the app for. There is no settings screen, no tracking mode concept (manual vs automatic), and no historical averaging engine. The domain model was ambiguous about whether "cycle" means a fixed 28-day span or a variable-length interval, and the code reflected that confusion.

From the user's perspective: the app tells them what day it is, not when their next period is coming. It cannot learn from their history. And there is nowhere to adjust basic preferences like cycle length or reminder timing.

## Solution

Implement the full domain model as defined in CONTEXT.md:

1. **Hybrid tracking** — Manual mode (fixed length, default 28) is the default. Automatic mode is enabled by default and activates silently after 3 complete cycles exist. The user can switch between modes at any time via Settings.

2. **Dynamic cycle length** — Cycle length is no longer hardcoded at 28. It comes from the user's manual setting or is computed as the average of complete cycle lengths (capped at 42 days per cycle). All calculations (day of cycle, due date, reminder) use the current dynamic cycle length.

3. **Main screen shows expected date** — The caption changes from today's date to "Next: June 28" (the due date). When the period is due or overdue, the caption switches to "Period may start today" (through due +7 days), then "Log your new period."

4. **Settings screen** — Accessible via a gear icon in the app bar. Contains: tracking mode radio buttons, cycle length picker (21–45 days, manual mode) or read-only display (auto mode), reminder days picker (1–5 days), notifications ON/OFF toggle.

5. **Day counter capped at cycle length** — The cycle-day convention (1-based, capped at cycle length) is preserved and made dynamic. Phase colors (rose 1–6, green 11–17) are relative to the actual cycle length.

6. **Prediction engine** — The repository gains an `averageCycleLength()` function that computes the mean of complete cycle lengths, excluding gaps >42 days. Eligibility is checked via `hasMinimumCycles()` (3 or more complete cycles). Due date is always `lastPeriodStart + cycleLength`.

## User Stories

1. As a new user, I want to log my first period start, so that the app begins tracking my cycle.

2. As a new user, I want the app to assume a 28-day cycle until I customize it, so that I get immediate predictions without setup.

3. As a returning user, I want the main screen to show my current cycle day prominently, so that I know where I am in my cycle at a glance.

4. As a returning user, I want the main screen to show the expected date of my next period, so that I can plan ahead.

5. As a returning user, I want the caption to change to "Period may start today" when my period is due, so that I'm gently reminded.

6. As a returning user, I want the caption to change to "Log your new period" after 7 days past due, so that I'm prompted to log when the prediction was off.

7. As a user with an irregular cycle, I want the app to learn from my logged history and automatically adjust predictions, so that the predictions become more accurate over time.

8. As a user with enough history, I want automatic tracking to activate silently without requiring me to opt in, so that the experience improves without extra steps.

9. As a user who prefers a fixed cycle, I want to switch back to manual mode at any time, so that I stay in control of my tracking.

10. As a user, I want to see how the automatic cycle length was computed, so that I trust the prediction.

11. As a user, I want to set my cycle length manually between 21 and 45 days, so that the prediction matches my body.

12. As a user, I want to configure how many days before the due date I receive a reminder, so that I get notified at the right time for me.

13. As a user, I want to toggle notifications on and off, so that I can control interruptions.

14. As a user who turns notifications off, I want all pending reminders to be cancelled immediately, so that I stop getting alerts.

15. As a user who turns notifications back on, I want reminders to be rescheduled based on my current data, so that I don't miss a period.

16. As a user, I want to access settings via a gear icon in the app bar, so that the experience feels familiar and standard.

17. As a user in automatic mode, I want the cycle length row to show the computed average with an info icon explaining it, so that I understand how the prediction is derived.

18. As a user in manual mode, I want to tap the cycle length row to change it via a scroll picker, so that the interaction is constrained and error-free.

19. As a user who deletes periods, I want auto mode to fall back to manual 28 if fewer than 3 complete cycles remain, so that predictions don't become nonsensical.

20. As a user who logs a period on the main screen, I want the day counter, expected date, and due status to update immediately, so that the screen reflects my new state.

21. As a user who logs a past period from history, I want the main screen to reflect any change in the current period, so that all screens are consistent.

22. As a user who edits a period date, I want the prediction to recalculate automatically, so that I don't need to do anything extra.

23. As a user who edits the active (current) period, I want it to be allowed, so that I can correct mistakes even on my most recent log.

24. As a user, I want the day counter to show my cycle day up to the expected cycle length, and then plateau, so that I always know where I am relative to my expected cycle end.

25. As a user with a longer cycle (e.g. 35 days), I want the day counter to count up to 35 before plateauing, so that the numbers match my actual cycle.

## Implementation Decisions

### Data Model (Hive)

The `Period` model gains three new Hive fields:

- `trackingMode` (String) — `"automatic"` or `"manual"`. Default `"automatic"`.
- `manualCycleLength` (int) — User's fixed cycle length. Default 28. Only used when mode is `"manual"`.
- `reminderDaysBefore` (int) — Days before due date to send notification. Default 2.

All new fields use Hive's `defaultValue` for backward compatibility with existing users.

### Prediction Engine (`PeriodRepository`)

New methods on the repository:

- `currentCycleLength()` — Returns the effective cycle length based on current tracking mode. Delegates to `manualCycleLength` or `averageCycleLength()`.
- `averageCycleLength()` — Computes the mean of all complete cycle lengths (gaps between consecutive period starts) that are ≤ 42 days. Returns `null` if fewer than 3 complete cycles exist.
- `hasMinimumCycles()` — Returns true when 3 or more complete cycles are available.
- `eligibleForAuto()` — Returns true when automatic mode is active AND `hasMinimumCycles()` is true. If false, `currentCycleLength()` falls back to `manualCycleLength` (default 28).

`dayOfCycle()` and `nextReminderDate()` become instance methods (or accept a cycleLength parameter) instead of using the hardcoded 28 constant. The day counter caps at `cycleLength`, not at 28.

`cycleLength` static constant is removed. `reminderOffsetDays` static constant is removed.

### Main Screen (`PeriodTrackerScreen`)

Caption logic changes:

- **No period logged**: "Tap below when your period starts." (unchanged)
- **Period logged**: Show `"Next: $formattedDate"` where formattedDate is the due date in "Month Day" format (e.g. "June 28").
- **Due window (due date to due +7 days)**: Show `"Period may start today."`
- **Overdue (due +8 days or more)**: Show `"Log your new period."`

The day counter uses the dynamic `currentCycleLength()` for its cap. Phase colors remain the same (1–6 rose, 11–17 green) but cap at cycle length for short cycles (if cycle length is 25, fertile phase still shows 11–17, period phase still 1–6).

`daysUntilNext` variable is removed; the caption derivation replaces it.

### Settings Screen (new)

A `SettingsScreen` widget with the following structure:

- **Tracking mode**: Two radio buttons — "Automatic (learns from cycles)" and "Manual (fixed length)". Selecting one updates `trackingMode` and recalculates the prediction/reminder immediately.
- **Cycle length**: When in manual mode, a tappable row showing current value with ">" arrow. Tapping opens a scroll picker bottom sheet bounded at 21–45 days, default 28. When in automatic mode, the row shows the computed average (e.g. "29 days") with an info icon. Tapping the icon shows: "Based on your N recorded cycles."
- **Reminder**: A tappable row showing "X days before" with ">" arrow. Tapping opens a scroll picker (1–5 days). Default 2.
- **Notifications**: A switch. OFF cancels all pending reminders via `NotificationService.cancelReminder()`. ON reschedules based on current data via `NotificationService.scheduleReminder()`.
- **Privacy**: A static row: "Your data stays on this device." Informational, not interactive.

Entry point: a gear icon in the app bar, to the left of the "History" text button. Tapping it pushes the SettingsScreen via `Navigator.push`. The main screen refreshes on return (same pattern as History).

### Notification Service

- The hardcoded `"Your period may start in 2 days."` message is parameterized to use the configured `reminderDaysBefore` value: `"Your period may start in $reminderDaysBefore days."`.
- `scheduleReminder` accepts the current cycle length as a parameter for computing the firing date.

## Testing Decisions

### What makes a good test

Tests should verify external behavior, not implementation details. For repository tests, this means exercising the public API (`currentCycleLength()`, `averageCycleLength()`, `hasMinimumCycles()`, `dayOfCycle()`, `nextReminderDate()`) with various data states and asserting the correct output. For widget tests, this means verifying that the correct text and visual elements appear given a particular data state.

### Seam 1: Repository tests (`test/repository_test.dart`)

Unit tests for `PeriodRepository` covering:

- `dayOfCycle` with a 28-day cycle length (existing behavior preserved)
- `dayOfCycle` with a 35-day cycle length (dynamic cap)
- `dayOfCycle` on an overdue date (returns cycle length)
- `averageCycleLength` with 0, 1, 2 cycles (returns null / not eligible)
- `averageCycleLength` with 3+ cycles (returns correct mean)
- `averageCycleLength` when a cycle exceeds 42 days (excluded from average)
- `averageCycleLength` when all cycles exceed 42 days (returns null)
- `currentCycleLength` in manual mode (returns manualCycleLength)
- `currentCycleLength` in automatic mode with <3 cycles (falls back to manualCycleLength)
- `currentCycleLength` in automatic mode with 3+ cycles (returns average)
- `nextReminderDate` with different cycle lengths and reminder offsets
- Settings CRUD: `trackingMode`, `manualCycleLength`, `reminderDaysBefore` get/set

### Seam 2: Widget tests (`test/widget_test.dart`, expanded)

Screen-level tests for `PeriodTrackerScreen` covering:

- App bar shows "Mona" (existing test preserved)
- Empty state: shows "Tap below when your period starts." and no day counter
- Logged period, normal state: shows day counter + "Next: June 28"
- Due window: shows day counter + "Period may start today"
- Overdue: shows day counter + "Log your new period"
- Day counter shows correct number and color per phase
- Day counter capped at cycle length (not raw days)

### Prior art

The existing `test/widget_test.dart` uses `flutter_test` with `WidgetTester` and initializes Hive in a temp directory. New tests follow the same setup pattern. No mocking framework is used; tests write directly to a temp Hive box, which is the simplest and most reliable approach for a local-only app.

## Out of Scope

- Fertility tracking or ovulation prediction
- Symptom, mood, or flow logging
- Pregnancy mode
- Any onboarding or welcome screen beyond the "Start" button
- Cloud sync, accounts, or data export
- Cycle phase descriptions or educational content
- Calendar view on the main screen (history-only)
- Any charts, graphs, or analytics
- Multiple cycle length tracking modes per cycle (e.g. luteal phase tracking)
- Wearable device integration

## Further Notes

- The existing `currentDayCounter` field on the Period model is unused dead code. It should be removed during this work.
- All SnackBars with actions must continue to use `persist: false` (Flutter 3.44 requirement).
- The `pubspec.yaml` description should be updated from "28-day cycle notification" to reflect hybrid tracking.
- The CONTEXT.md glossary is authoritative for all domain terminology. Any code that contradicts it should be updated.
