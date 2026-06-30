# Mona Domain Glossary

## Core Concepts

**Period** — A single recorded start date of menstruation. Each period is one event, logged as the day bleeding began.

**Cycle** — The span from one period start to the next. Variable length; default is 28 days.

**Cycle day** — The current day within the cycle (1-based), computed from the most recent period start. The maximum is the current cycle's length.

**Current period** — The most recently logged period start. Used to determine the current cycle day and phase.

**History** — The list of past period start dates, ordered newest first.

**First period** — The initial period start logged at first launch. There is no separate welcome screen; the "Start" button serves as the onboarding mechanism.

## Cycle Phases

**Period phase** — Days 1–6 of the cycle. The bleeding phase. Visually marked with rose.

**Fertile phase** — Days 11–17 of the cycle. The ovulation window. Visually marked with green.

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

**Due date** — The expected start of the next period, calculated as `lastPeriodStart + cycleLength`.

**Day counter cap** — The day counter plateaus at the cycle length. It represents cycle-day position, not raw days since last period. When overdue, the counter stays at the cap and the caption communicates the state.

**Overdue** — The period following the due date when no new period has been logged. Day counter is capped at cycle length. Caption shows "Period may start today" for 7 days past due, then switches to "Log your new period."

**Reminder** — A notification sent N days before the due date (default 2) at 09:00.

**Reminder days before** — Configurable number of days before due date to send the reminder.

## Main Screen

**Day counter** — Large cycle day number (1-based, capped at cycle length). Colored per phase (rose for 1–6, green for 11–17, black otherwise).

**Expected date** — The due date shown as "Next: June 28." Replaces today's date as the primary caption. When in due/overdue state, caption switches to state message.

**Start button** — Primary action to log a new period. Serves as implicit onboarding on first launch.

## Actions

**Log a period** — Recording a new period start date. Can be done for today (via the main button) or for a past date (via the history screen).

**Edit a period** — Changing the date of an existing period record. Allowed on any period, including the active one.

**Delete a period** — Removing a period record from history via swipe-to-delete. Any period can be deleted, including the active one. Protected by the Undo snackbar.

**Undo** — Reversing the most recent log, edit, or delete action. Recalculation runs on every change.

## User Input Principle

**Trust user input** — All logged dates are accepted as-is. No outlier detection. Users correct mistakes by editing or deleting the entry.

## Settings

**Settings entry** — A gear icon in the app bar. Standard, minimal, universally understood.

**Tracking mode toggle** — Radio buttons: "Automatic (learns from cycles)" / "Manual (fixed length)." Clear, explicit, one tap to switch.

**Cycle length row (manual)** — Tappable row with ">" arrow. Opens a scroll picker bounded at 21–45 days. Default 28.

**Cycle length row (automatic)** — Read-only. Shows the computed average without an arrow. A subtle info icon explains: "Based on your N recorded cycles."

**Days before row** — "Days before" row within the Reminder section, showing the configured value. Disabled (gray, no chevron, not tappable) when notifications are OFF. Enabled when notifications are ON, opens a scroll picker (1–5 days). Default 2.

**Notification toggle** — ON/OFF switch within the Reminder section. OFF cancels all pending reminders immediately. ON reschedules based on current data. The reminderDaysBefore config is preserved while OFF. Label is singular: "Notification".

## App

**Mona** — The period tracker application.
