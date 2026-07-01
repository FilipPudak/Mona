import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:mona/models/period.dart';
import 'package:mona/models/settings.dart';

/// Pre-populate settings (preventing _migrateSettingsIfNeeded writes during
/// widget construction) and optionally seed a period.
Future<void> prepopulate({DateTime? periodDate}) async {
  final box = Hive.box<Period>('periods');
  if (periodDate != null) {
    await box.add(Period(startedDate: periodDate));
  }
  final settings = Hive.box<Settings>('settings');
  if (settings.isEmpty) {
    await settings.add(Settings());
  }
}

/// Pump enough frames for route transitions and dialog animations to settle.
/// Avoids [pumpAndSettle] which never settles when the main screen's pulse
/// animation ([AnimationController.repeat]) is running.
Future<void> pumpUntilSettled(WidgetTester tester,
    {Duration step = const Duration(milliseconds: 100),
    int maxSteps = 50}) async {
  await tester.pump();
  for (int i = 0; i < maxSteps; i++) {
    if (!tester.binding.hasScheduledFrame) break;
    await tester.pump(step);
  }
}
