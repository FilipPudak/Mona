import 'package:flutter/services.dart';

class DeviceTimezone {
  static const _channel = MethodChannel('device_timezone');

  static Future<String> getLocalTimezone() async {
    try {
      return await _channel.invokeMethod('getLocalTimezone');
    } catch (_) {
      return 'UTC';
    }
  }
}
