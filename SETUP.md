# Platform Setup — Verification

The Dart code is in `lib/`. The platform shells were generated with
`flutter create .` and then patched for local notifications.

## Files touched for platform support
- `android/app/src/main/AndroidManifest.xml` — added notification permissions.
- `android/app/build.gradle.kts` — pinned `minSdk = 21`.
- `ios/Runner/Info.plist` — added `NSUserNotificationsUsageDescription`.

## Build & run

### Android
```
flutter run -d <device-id>
```

On first launch Android 13+ will prompt for notification permission. Tap Allow.

To verify the scheduled alarm without waiting 26 days, temporarily edit
`lib/services/period_repository.dart` and change:

```dart
static const int reminderOffsetDays = 26; // 2 days before day 28
```

to something like `0` (fires immediately) or `1` (fires tomorrow at 09:00),
tap the button, then check the system notification shade. Revert the constant
before committing.

You can also list pending alarms via:
```
adb shell dumpsys alarm | grep mengacloud_period_tracker
```

### iOS
```
cd ios && pod install && cd ..
flutter run -d <device-id>
```

Grant notification permission when prompted. The scheduled notification will
appear at the chosen date/time even if the app is closed.

## Permissions reference

### Android (manifest)
- `POST_NOTIFICATIONS` — show notifications on Android 13+.
- `SCHEDULE_EXACT_ALARM` — required for `AndroidScheduleMode.exactAllowWhileIdle`.
- `USE_EXACT_ALARM` — Android 13+ equivalent for apps that qualify.
- `RECEIVE_BOOT_COMPLETED` — re-register scheduled alarms after a reboot.
- `WAKE_LOCK` — allow the alarm to wake the device briefly to fire.
- `VIBRATE` — optional haptic on the reminder.

### iOS (Info.plist)
- `NSUserNotificationsUsageDescription` — message shown with the system
  permission prompt. Set to a friendly sentence explaining the reminder.

## What's intentionally not done
- No app icon customization — the default Flutter launcher icon is used.
- No release signing config — `flutter run --release` is signed with debug
  keys (TODO in `build.gradle.kts`).
- No bundle identifier change — still `com.example.mengacloud_period_tracker`.
  Update before publishing.
