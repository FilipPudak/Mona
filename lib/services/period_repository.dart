import 'package:hive/hive.dart';

import '../models/period.dart';

/// Read/write access to period records. Backed by a single Hive box.
///
/// Only the most recent period is consulted in v1; the full box is preserved
/// for future history features.
class PeriodRepository {
  PeriodRepository(this._box);

  static const String boxName = 'periods';
  static const int cycleLength = 28;
  static const int reminderOffsetDays = 26; // 2 days before day 28

  final Box<Period> _box;

  /// Returns the most recent period, or `null` if none has been recorded.
  Period? currentPeriod() {
    if (_box.isEmpty) return null;
    final all = _box.values.toList()
      ..sort((a, b) => a.startedDate.compareTo(b.startedDate));
    return all.last;
  }

  /// Stores a new period record. Returns the saved instance.
  Future<Period> recordPeriodStart(DateTime date) async {
    final period = Period(startedDate: DateTime(date.year, date.month, date.day));
    await _box.add(period);
    return period;
  }

  /// Cycle day (1-based) for [today] given a period starting on [start].
  /// Clamped to 1..[cycleLength].
  static int dayOfCycle(DateTime start, DateTime today) {
    final startDay = DateTime(start.year, start.month, start.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    final diff = todayDay.difference(startDay).inDays + 1;
    if (diff < 1) return 1;
    if (diff > cycleLength) return cycleLength;
    return diff;
  }

  /// Date/time at which the next reminder should fire: 09:00 local on
  /// `start + reminderOffsetDays`.
  static DateTime nextReminderDate(DateTime start) {
    final day = DateTime(start.year, start.month, start.day)
        .add(Duration(days: reminderOffsetDays));
    return DateTime(day.year, day.month, day.day, 9);
  }
}
