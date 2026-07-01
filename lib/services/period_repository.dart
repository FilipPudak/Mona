import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/period.dart';

/// Read/write access to period records. Backed by a single Hive box.
///
/// Only the most recent period is consulted in v1; the full box is preserved
/// for future history features.
class PeriodRepository {
  PeriodRepository(this._box);

  static const String boxName = 'periods';

  final Box<Period> _box;

  int get periodCount => _box.values.length;

  bool hasEnoughHistory() => periodCount >= 4;

  bool eligibleForAuto() =>
      trackingMode == 'automatic' && averageCycleLength() != null;

  int currentCycleLength() {
    if (eligibleForAuto()) return averageCycleLength()!;
    return manualCycleLength;
  }

  int? averageCycleLength() {
    final all = _box.values.toList()
      ..sort((a, b) => a.startedDate.compareTo(b.startedDate));
    if (all.length < 4) return null;
    final gaps = <int>[];
    for (int i = 1; i < all.length; i++) {
      final gap = all[i].startedDate.difference(all[i - 1].startedDate).inDays;
      if (gap <= 42) gaps.add(gap);
    }
    if (gaps.length < 3) return null;
    return (gaps.reduce((a, b) => a + b) / gaps.length).round();
  }

  String get trackingMode => currentPeriod()?.trackingMode ?? 'automatic';
  int get manualCycleLength => currentPeriod()?.manualCycleLength ?? 28;
  int get reminderDaysBefore => currentPeriod()?.reminderDaysBefore ?? 2;
  String get dateFormat => currentPeriod()?.dateFormat ?? 'EU';

  Future<void> setTrackingMode(String value) async {
    final period = currentPeriod();
    if (period == null) return;
    period.trackingMode = value;
    await period.save();
  }

  Future<void> setManualCycleLength(int value) async {
    final period = currentPeriod();
    if (period == null) return;
    period.manualCycleLength = value;
    await period.save();
  }

  Future<void> setReminderDaysBefore(int value) async {
    final period = currentPeriod();
    if (period == null) return;
    period.reminderDaysBefore = value;
    await period.save();
  }

  Future<void> setDateFormat(String value) async {
    final period = currentPeriod();
    if (period == null) return;
    period.dateFormat = value;
    await period.save();
  }

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
    final period =
        Period(startedDate: DateTime.utc(date.year, date.month, date.day));
    await _box.add(period);
    return period;
  }

  /// Raw day (1-based) since [start]. Lower bound 1, upper bound 99.
  static int dayOfCycle(DateTime start, DateTime today) {
    final startDay = DateTime(start.year, start.month, start.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    final diff = todayDay.difference(startDay).inDays + 1;
    if (diff < 1) return 1;
    if (diff > 99) return 99;
    return diff;
  }

  /// Returns `true` when [today] is after the due date for [start] and
  /// [cycleLength].
  static bool isOverdue(DateTime start, DateTime today, int cycleLength) {
    final due = DateTime(start.year, start.month, start.day)
        .add(Duration(days: cycleLength));
    return today.isAfter(due);
  }

  /// Returns the inclusive fertile window as `(start, end)` for a given
  /// [cycleLength]. The fertile window is `ovulationDay ± 3` where
  /// `ovulationDay = cycleLength - 14`.
  static (int, int) fertileWindow(int cycleLength) {
    final ovulationDay = cycleLength - 14;
    return (ovulationDay - 3, ovulationDay + 3);
  }

  /// Returns the phase color for a given [day] and [cycleLength].
  /// Period phase (rose, days 1–6) wins over fertile window overlap.
  static Color phaseColor(int day, int cycleLength) {
    if (day >= 1 && day <= 6) return const Color(0xFFE68192);
    final (start, end) = fertileWindow(cycleLength);
    if (day >= start && day <= end) return Colors.green;
    return Colors.black87;
  }

  /// Date/time at which the next reminder should fire: 09:00 local on
  /// `start + (cycleLength - reminderDaysBefore)`.
  static DateTime nextReminderDate(DateTime start,
      {int cycleLength = 28, int reminderDaysBefore = 2}) {
    final reminderDay = cycleLength - reminderDaysBefore;
    final day = DateTime(start.year, start.month, start.day)
        .add(Duration(days: reminderDay));
    return DateTime(day.year, day.month, day.day, 9);
  }
}
