# Mona Domain Glossary

## Core Concepts

**Period** — A single recorded start date of menstruation. Each period is one event, logged as the day bleeding began.

**Cycle** — The span from one period start to the next. Variable length; default is 28 days.

**Cycle day** — The current day since the last period start (1-based). Computed from the most recent period start. Used for phase coloring. Maximum displayed value is 99.

**Current period** — The most recently logged period start. Used to determine the current cycle day and phase.

**History** — The list of past period start dates, ordered newest first.

**First period** — The initial period start logged at first launch. There is no separate welcome screen; the `+` button centered on the blank screen serves as the onboarding mechanism.

## Cycle Phases

**Period phase** — Days 1–6 of the cycle. The bleeding phase. Visually marked with rose.

**Fertile phase** — A visual estimate of the fertile window: ovulation day (`cycleLength - 14`) ± 3 days. Shifts with cycle length. Displayed in green. Not a medical guarantee — a visual cue only.

## Tracking

**Cycle length** — The number of days between consecutive period starts. Default is 28.

**Complete cycle** — A cycle with both a start and a subsequent period start logged. Only complete cycles are used for automatic averaging.

**Auto averaging cap** — Individual cycle lengths longer than 42 days are excluded from automatic averaging. They are assumed to be missed-log gaps, not real cycles.

**Automatic eligibility** — Automatic mode is enabled by default and activates silently once 3 or more complete cycles exist. No prompt, no opt-in. If history later shrinks below 3 (via deletion), automatic mode falls back to manual 28.

**Tracking mode** — Whether the cycle length is determined manually (user-set fixed value) or automatically (average of historical cycles).

**Manual mode** — Tracking mode where cycle length is a user-set fixed value.

**Automatic mode** — Tracking mode where cycle length is computed as the average of complete cycle lengths in history.

**Switch back** — The user may switch from automatic to manual mode at any time.

**Cycle length source** — Whether the current cycle length originates from manual or automatic calculation.

## Prediction

**Due date** — The expected start of the next period, calculated as `lastPeriodStart + cycleLength`. Displayed as a bare date below the day counter.

**Overdue** — The period following the due date when no new period has been logged. Starting the day after the due date: the expected date goes dim, the day counter text dims (if in default black), and the `+` button begins pulsing. No text prompt.

**Reminder** — A notification sent N days before the due date (default 2) at 09:00.

**Reminder days before** — Configurable number of days before due date to send the reminder.

## Main Screen

**Day counter** — Large day number (1-based, raw days since last period start). Uncapped up to 99, then shows `99+`. Colored per phase (rose for 1–6, green for 11–17, black otherwise). When overdue, the default black color goes dim; phase colors (rose, green) retain full opacity.

**Expected date** — The due date shown as a bare date below the day counter. Format is `DD/MM` (default EU) or `MM/DD` (US configurable). Goes dim when overdue.

**Log action** — A rose (`#E68192`) circular button with a white `+` icon. Serves as primary action to log a new period and as implicit onboarding on first launch. Position is centered on first launch (no periods logged) and bottom-anchored after the first period is recorded. Transition between positions is animated. Pulses subtly (scale oscillation) when overdue — starting the day after the due date — as a re-engagement cue.

## Actions

**Log a period** — Recording a new period start date. Can be done for today (via the `+` button on the main screen) or for a past date (via the history screen).

**Edit a period** — Changing the date of an existing period record. Allowed on any period, including the active one.

**Delete a period** — Removing a period record from history via swipe-to-delete. Any period can be deleted, including the active one. Protected by the Undo snackbar.

**Undo** — Reversing the most recent log, edit, or delete action. Recalculation runs on every change.

## User Input Principle

**Trust user input** — All logged dates are accepted as-is. No outlier detection. Users correct mistakes by editing or deleting the entry.

## Settings

**Date format** — The format for the expected date on the main screen. Default is EU (`DD/MM`). User may switch to US (`MM/DD`) via a toggle in Settings.

**Settings entry** — A gear icon in the app bar. Standard, minimal, universally understood.

**Tracking mode toggle** — Radio buttons: "Automatic (learns from cycles)" / "Manual (fixed length)." Clear, explicit, one tap to switch.

**Cycle length row (manual)** — Tappable row with ">" arrow. Opens a scroll picker bounded at 21–45 days. Default 28.

**Cycle length row (automatic)** — Read-only. Shows the computed average without an arrow. A subtle info icon explains: "Based on your N recorded cycles."

**Days before row** — "Days before" row within the Reminder section, showing the configured value. Disabled (gray, no chevron, not tappable) when notifications are OFF. Enabled when notifications are ON, opens a scroll picker (1–5 days). Default 2.

**Notification toggle** — ON/OFF switch within the Reminder section. OFF cancels all pending reminders immediately. ON reschedules based on current data. The reminderDaysBefore config is preserved while OFF. Label is singular: "Notification".

## App

**Mona** — The period tracker application.
