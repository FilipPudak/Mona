# PRD: Main Screen Redesign — Icon Button, Bare Date, Uncapped Counter, Overdue Signals

## Problem Statement

The main screen currently uses a text "Start" button, a multi-state caption, and a day counter capped at cycle length. The caption does triple duty — showing the expected date, overdue warnings, and onboarding prompts — which creates visual clutter and semantic overlap. The "Start" label is ambiguous and doesn't match the domain term (Log a period). The day counter cap is confusing to users who see the same number for days on end without explanation.

From the user's perspective: the screen has too many words telling them what to do. The button says one thing, the caption says another. The day counter plateaus at the same number for weeks and looks broken.

## Solution

Strip the main screen to three elements, each with one job:

1. **Day counter** — Raw days since last period start (1-based). Uncapped up to 99, then displays `99+`. Colored per phase: rose (days 1–6), green (fertile window), black otherwise.
2. **Expected date** — Bare date below the counter. No prefix. Format is `DD/MM` (default EU) or `MM/DD` (US configurable in Settings).
3. **Log action** — A filled rose circle with a white `+` icon. Centered on first launch, bottom-anchored after the first period is logged. Transition animates.

When overdue (day after due date onward):
- Expected date goes dim
- Day counter text dims (if in default black phase)
- `+` button pulses subtly (scale oscillation)

The fertile window is no longer hardcoded at 11–17. It becomes dynamic: `ovulationDay = cycleLength - 14`, green range = `ovulationDay ± 3`.

## User Stories

1. As a new user, I want a clear, immediate way to log my first period, so that I can start tracking without reading instructions.
2. As a new user opening the app for the first time, I want a `+` button centered on a clean screen, so that I know the one thing to do is tap it.
3. As a returning user, I want to see how many days it's been since my last period, so that I know where I am in my cycle.
4. As a returning user, I want the day counter to keep counting past my expected cycle length, so that I can see exactly how overdue I am.
5. As a returning user with a very long gap, I want the counter to show `99+` instead of a misleading big number, so that I'm not confused by an extreme value.
6. As a user with a history of periods, I want to see the date my next period is expected, so that I can plan ahead.
7. As a user, I want the expected date to be shown as a bare date without the word "Next:", so that the screen is clean and minimal.
8. As a user in the EU, I want dates in `DD/MM` format by default, so that they match my local convention.
9. As a user in the US, I want to switch dates to `MM/DD` format in Settings, so that the dates look familiar.
10. As a user whose period is overdue, I want the expected date to go dim and the `+` button to pulse, so that I'm gently reminded to log without being told what to do in words.
11. As a user whose period is overdue, I want the day counter to go dim (if it's in its default black phase), so that the screen feels visually quieter.
12. As a user who is in the period phase (days 1–6) and also overdue, I want the rose color to stay full opacity, so that the phase signal is not overridden by the stale signal.
13. As a user in the fertile window, I want the green to shift based on my actual cycle length, so that the visual cue is relevant to me.
14. As a user with a 35-day cycle, I want the green days to appear around days 18–24 rather than 11–17, so that the fertile estimate is more accurate.
15. As a user who logs a period, I want the `+` button to animate from center to bottom, so that the transition feels smooth and deliberate.
16. As a user who deletes all periods, I want the `+` button to return to center, so that I'm back to the first-launch experience.
17. As a user who is overdue, I want the `+` button to pulse, so that I'm gently re-engaged without a text prompt telling me what to do.
18. As a user, I want the screen to have no caption or instructional text, so that the interface is pure numbers and icon.

## Implementation Decisions

### Day counter semantics change

`dayOfCycle()` in the repository is changed: it no longer caps at cycle length. It returns raw `daysSinceStart + 1`, with a lower bound of 1 and an upper bound of 99. At 100+, it returns 99 and the display renders `99+`.

### Fertile phase becomes dynamic

A new static method `fertileWindow(cycleLength)` on `PeriodRepository` returns `(ovulationDay - 3, ovulationDay + 3)` where `ovulationDay = cycleLength - 14`. The screen uses this to determine the green range instead of hardcoded 11–17.

### Overdue detection

A new method `isOverdue(lastPeriodStart, today, cycleLength)` on `PeriodRepository` returns true when `today > dueDate`.

### Date format setting

A new `dateFormat` field on the `Period` model: `'EU'` or `'US'`. Default `'EU'`. Stored like other settings on the current period. A toggle in Settings switches between them.

### Button shape and behavior

The full-width FilledButton with "Start" text is replaced by a circular button (56px diameter) with a rose (`#E68192`) background and a white `+` icon. Its vertical position in the layout depends on whether any periods exist:

- **No periods**: centered vertically in the available space
- **1+ periods**: bottom-anchored at the same position as the current button

The transition is animated via `AnimatedPositioned` with a 300ms ease-in-out curve.

### Pulse animation

An `AnimationController` with a `Tween<double>(begin: 1.0, end: 1.08)` drives a `Transform.scale` on the button. The pulse runs only when `isOverdue` is true. The oscillation uses a sine curve with ~1.5s period.

### Layout restructure

The body's `Column` is replaced by a `Stack`. The day counter + expected date are centered in the stack. The `+` button is positioned with `AnimatedPositioned` that changes its bottom/center offset based on state.

### Caption removal

All caption logic and rendering code is deleted. The screen has no text other than the app bar, the app title, and the expected date.

### Expected date formatting

The expected date is formatted as a bare date string:
- EU: `DD/MM` (e.g. `28/06`)
- US: `MM/DD` (e.g. `06/28`)

No prefix, no month name. The `_monthName` helper in widget tests is no longer needed.

### Dimming

Dimming is implemented as reduced opacity on the relevant text widgets. The exact opacity value: 0.38 (matching Material Design's disabled text opacity). Only applies to the default black phase color. Rose and green phases retain full opacity always.

## Testing Decisions

### What makes a good test

Tests should verify external behavior, not implementation details. For repository tests, this means asserting output values of calculation methods. For widget tests, this means asserting what text, icons, and styles appear on screen given a particular data state.

### Seam 1: Repository tests (`test/repository_test.dart`)

Unit tests for `PeriodRepository` covering:

- `dayOfCycle` returns raw day number (not capped at cycle length)
- `dayOfCycle` caps at 99 (returns 99 for day 100+)
- `isOverdue` returns true/false based on due date comparison
- `fertileWindow` returns correct range for various cycle lengths (28, 21, 35, 45)
- `phaseColor` returns correct color for a given day and cycle length
- `phaseColor` with overlapping period+fertile phases (rose wins when cycle length < 14)

### Seam 2: Widget tests (`test/widget_test.dart`)

Screen-level tests for `PeriodTrackerScreen`:

- "Start" text button does not exist; `+` icon button exists
- No caption text appears anywhere on screen (verify caption strings removed)
- Day counter shows raw day number (e.g. day 30 shown as `30` when cycle length is 28)
- Day counter shows `99+` when overdue by 100+ days
- Expected date shown as bare `DD/MM` without "Next:" prefix
- `+` button is centered when no periods logged
- `+` button is bottom-anchored when a period exists
- Overdue state: expected date has reduced opacity (0.38)
- Default phase color has reduced opacity when overdue
- Rose phase color (day 3) retains full opacity even when overdue
- Fertile phase range depends on cycle length (not hardcoded 11-17)

### Prior art

The existing `test/widget_test.dart` tests use `flutter_test` with `WidgetTester` and initialize Hive in a temp directory. New tests follow the same setup pattern. The repository tests in `test/repository_test.dart` provide the pattern for testing calculation methods in isolation. No mocking framework is used.

## Out of Scope

- Changing the list picker bottom sheet or its labels
- Changing the history screen or calendar picker
- Changing the notification service or reminder logic
- Adding any new text/instructions to the main screen
- Fertility prediction or medical disclaimers — the fertile window remains a visual-only estimate
- Animated transition from centered to bottom on delete-all (hard-cut is acceptable)

## Further Notes

- The CONTEXT.md glossary has been updated throughout the grilling session that produced this PRD. All new terms and updated definitions are captured there.
- The `_monthName` helper function in `test/widget_test.dart` is dead code after this change and should be removed.
- Existing tests that assert "Tap below when your period starts.", "Period may start today.", "Log your new period.", or "Next: Month Day" must be removed or replaced.
- The existing test `'Day counter capped at cycle length when overdue'` must be replaced — the counter is no longer capped.
