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

  /// Returns up to [maxEntries] most recent periods, newest first.
  /// Older records remain in storage but are not returned.
  List<Period> history({int maxEntries = 12}) {
    if (_box.isEmpty) return const [];
    final all = _box.values.toList()
      ..sort((a, b) => b.startedDate.compareTo(a.startedDate));
    if (all.length <= maxEntries) return all;
    return all.sublist(0, maxEntries);
  }

  /// Returns `true` if a period was already recorded for [date]'s calendar
  /// day (in local time).
  bool hasPeriodOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    for (final p in _box.values) {
      final pDay = DateTime(
        p.startedDate.year,
        p.startedDate.month,
        p.startedDate.day,
      );
      if (pDay == day) return true;
    }
    return false;
  }

  /// Stores a new period record if one does not already exist for [date]'s
  /// calendar day. Returns the saved instance, or `null` if a record for
  /// that day was already present.
  Future<Period?> recordPeriodStart(DateTime date) async {
    if (hasPeriodOn(date)) return null;
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
        .add(const Duration(days: reminderOffsetDays));
    return DateTime(day.year, day.month, day.day, 9);
  }
}
