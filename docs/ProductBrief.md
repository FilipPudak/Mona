# Product Brief: Minimalist Period Reminder App

## 1. Product Vision

Create a simple, private, minimalist period tracking application focused on one core purpose:

**Help users understand when their next period is likely to start and remind them two days beforehand.**

The product should feel calm, premium, Scandinavian, and effortless.

This is not intended to be a fertility tracker, medical application, wellness journal, or social platform.

The goal is to create a beautiful utility app that does one thing extremely well.

---

# 2. Target User

The target user wants:

* A simple reminder for their next period
* Minimal interaction
* No account creation
* No unnecessary features
* Privacy and control over their data
* A calm, elegant user experience

The user should understand the app immediately after opening it.

---

# 3. Product Principles

## Design Philosophy

The app should follow Scandinavian design principles:

* White backgrounds
* Large typography
* Generous whitespace
* Minimal UI elements
* Soft neutral colours
* Calm and premium feeling

Avoid:

* Complex dashboards
* Excessive charts
* Gamification
* Medical-style interfaces
* Too many options
* Unnecessary notifications

---

# 4. Core User Journey

## First Launch

The user opens the app.

Display:

```
Welcome

A simple period reminder.

Let's set up your cycle.
```

User provides:

* Date of last period start
* Optional cycle length preference

Default cycle length:

```
28 days
```

The app then creates the first prediction.

---

# 5. Main Screen

The home screen is the central experience.

Example:

```
Day 12

16 days until your next period

Expected:
June 28


[ Period Started Today ]
```

The user should always understand:

1. Current cycle day
2. Days remaining until expected period
3. Expected period date
4. How to reset the cycle

The main screen should contain only the information needed for this.

---

# 6. Core MVP Features

## Feature 1: Period Start Logging

Primary action:

```
Period Started Today
```

When pressed:

* Save today's date
* Reset the cycle
* Recalculate the next expected period
* Reschedule notifications

This is the most important interaction in the app.

---

# Feature 2: Cycle Calculation

The app supports two tracking approaches.

---

## Mode A: Manual Cycle Length

The user selects their expected cycle length.

Example:

```
Cycle length:
28 days
```

Calculation:

```
Next period = Last period start + cycle length
```

Advantages:

* Simple
* Predictable
* Easy to explain

---

## Mode B: Automatic Historical Tracking

The app learns from previous period starts.

Example:

```
Previous cycles:

28 days
29 days
30 days
29 days
```

The app calculates:

```
Average cycle:
29 days
```

This becomes the prediction basis.

---

# 7. Recommended Hybrid Tracking System

The recommended approach is a hybrid model.

## New Users

For users with limited history:

```
Use default cycle length:
28 days
```

or:

```
Use user-selected cycle length
```

---

## After Enough History Exists

Once the user has logged multiple cycles:

Example:

```
Your cycle appears to average 29 days.

Would you like to switch to automatic tracking?
```

User chooses whether to enable it.

---

## Mature Tracking

The app uses historical data:

Example:

```
Your usual cycle:
29 days

Based on:
6 recorded periods
```

The app should explain why it made the prediction.

---

# 8. Settings Design

Settings should remain minimal.

Recommended structure:

```
Settings


Cycle Tracking

Automatic
Learns from previous cycles

or

Manual
Use a fixed cycle length


Cycle Length

28 days >


Reminder

2 days before >


Notifications

On >


Privacy

Your data stays on this device
```

---

# 9. Notifications

Notifications must be local device notifications.

No backend should be required.

Example:

```
Your period may start in about 2 days.
```

Requirements:

* User can enable or disable notifications
* Reminder timing can be configured later
* Works offline

---

# 10. History Screen

Keep history simple.

Example:

```
History

June 1
May 3
April 5
March 7
```

Purpose:

* Build trust
* Show previous cycle starts

Do not create a complex calendar view initially.

---

# 11. Privacy Requirements

Privacy is a key product differentiator.

Requirements:

* No account creation
* No login
* No cloud database
* No personal data leaving the device
* Local storage only

Positioning:

```
Private by design.
Your data stays on your phone.
```

---

# 12. Explicitly Out of Scope

Do not implement initially:

* Fertility tracking
* Ovulation prediction
* Pregnancy mode
* Symptom tracking
* Mood tracking
* AI chatbot
* Community features
* Social sharing
* Subscriptions
* Complex analytics

---

# 13. Technical Requirements

Preferred technology:

* Flutter
* iOS + Android support
* Local storage
* Local notifications
* No backend

Suggested architecture:

```
User Input

↓

Local Storage

↓

Cycle Calculation Engine

↓

Notification Scheduler

↓

User Interface
```

---

# 14. Data Model

Example:

```json
{
  "trackingMode": "automatic",
  "manualCycleLength": 28,
  "periodStarts": [
    "2026-01-03",
    "2026-02-01",
    "2026-03-02"
  ],
  "reminderDaysBefore": 2
}
```

---

# 15. MVP Success Criteria

The first version is successful if a new user can:

1. Install the app
2. Set up their cycle
3. Understand when their next period is expected
4. Receive a reminder
5. Reset the cycle after their period begins

The entire experience should take less than one minute.

---

# 16. Product Positioning

The app should feel like:

> "A beautifully designed reminder app that quietly learns your cycle."

It should not feel like:

> "A complex medical tracking platform."

The primary goal is simplicity, trust, privacy, and elegance.
