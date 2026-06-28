import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mona/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    late List<MethodCall> localNotificationsCalls;
    late NotificationService service;

    setUp(() {
      localNotificationsCalls = [];

      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (MethodCall call) async {
          localNotificationsCalls.add(call);
          return true;
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('device_timezone'),
        (MethodCall call) async => 'UTC',
      );

      service = NotificationService.testing();
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('device_timezone'),
        null,
      );
    });

    test('scheduleReminder does not schedule when date is in the past',
        () async {
      final past = DateTime.now().subtract(const Duration(days: 1));

      await service.scheduleReminder(past);

      final zonedScheduleCalls = localNotificationsCalls
          .where((c) => c.method == 'zonedSchedule')
          .length;
      expect(zonedScheduleCalls, 0);
    });

    test('scheduleReminder cancels previous reminder before scheduling',
        () async {
      final future = DateTime.now().add(const Duration(days: 10));

      await service.scheduleReminder(future);

      final cancelCalls =
          localNotificationsCalls.where((c) => c.method == 'cancel').length;
      expect(cancelCalls, greaterThanOrEqualTo(1));
    });

    test('cancelReminder calls cancel on the plugin', () async {
      await service.cancelReminder();

      final cancelCalls =
          localNotificationsCalls.where((c) => c.method == 'cancel');
      expect(cancelCalls, isNotEmpty);
    });
  });
}
