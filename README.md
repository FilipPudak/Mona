<p align="center">
  <img src="assets/mona_icon_foreground.png" alt="Mona icon" width="256">
</p>

# Mona

A Scandinavian-minimal Flutter period tracker. Local-only, private, no accounts, no network.

## Features

- **Hybrid tracking**: automatic mode silently learns from your history (averages cycles, caps at 42 days) or switch to a fixed manual length
- **Prediction**: main screen shows your cycle day prominently and the expected next period date; caption changes to "Period may start today" through due +7 days, then "Log your new period"
- **History**: scrollable list with swipe-to-delete, tap-to-edit, "+" calendar picker (past only, 365-day cap)
- **Day counter**: cycle-day convention (1-based, capped at cycle length) with phase colors (rose 1–6, green 11–17)
- **Reminders**: push notifications, configurable 1–5 days before due date, toggle on/off
- **Privacy**: your data stays on this device — no accounts, cloud sync, or analytics

## Tech Stack

- Flutter 3.44.1, Dart 3.x
- Hive (local storage)
- flutter_local_notifications

## Build & Run

```sh
flutter pub get
flutter run
```
