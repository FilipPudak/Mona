import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mona/services/device_timezone.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceTimezone', () {
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('device_timezone'), null);
    });

    test('returns UTC when no channel handler is set', () async {
      final tz = await DeviceTimezone.getLocalTimezone();
      expect(tz, 'UTC');
    });

    test('returns the timezone from the channel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('device_timezone'),
        (MethodCall call) async => 'America/New_York',
      );

      final tz = await DeviceTimezone.getLocalTimezone();
      expect(tz, 'America/New_York');
    });

    test('returns UTC when channel throws an error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('device_timezone'),
        (MethodCall call) async => throw Exception('channel error'),
      );

      final tz = await DeviceTimezone.getLocalTimezone();
      expect(tz, 'UTC');
    });
  });
}
