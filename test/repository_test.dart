import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:mona/models/period.dart';
import 'package:mona/services/period_repository.dart';

void main() {
  late Box<Period> box;
  late PeriodRepository repo;

  setUp(() async {
    Hive.init(Directory.systemTemp.createTempSync('.test').path);
    if (!Hive.isAdapterRegistered(PeriodAdapter().typeId)) {
      Hive.registerAdapter(PeriodAdapter());
    }
    box = await Hive.openBox<Period>('periods');
    repo = PeriodRepository(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('periods');
  });

  group('currentPeriod', () {
    test('returns null when no periods recorded', () {
      expect(repo.currentPeriod(), isNull);
    });

    test('returns the only period when one exists', () async {
      final p = Period(startedDate: DateTime(2026, 6, 1));
      await box.add(p);
      expect(repo.currentPeriod(), equals(p));
    });

    test('returns the latest period when multiple exist', () async {
      final p1 = Period(startedDate: DateTime(2026, 5, 1));
      final p2 = Period(startedDate: DateTime(2026, 6, 1));
      await box.add(p1);
      await box.add(p2);
      expect(repo.currentPeriod(), equals(p2));
    });
  });

  group('history', () {
    test('returns empty list when no periods recorded', () {
      expect(repo.history(), isEmpty);
    });

    test('returns periods sorted newest first', () async {
      final p1 = Period(startedDate: DateTime(2026, 5, 1));
      final p2 = Period(startedDate: DateTime(2026, 6, 1));
      final p3 = Period(startedDate: DateTime(2026, 7, 1));
      await box.add(p1);
      await box.add(p2);
      await box.add(p3);
      final result = repo.history();
      expect(result, [p3, p2, p1]);
    });

    test('respects maxEntries limit', () async {
      for (final day in [1, 2, 3, 4, 5, 6, 7]) {
        await box.add(Period(startedDate: DateTime(2026, 6, day)));
      }
      expect(repo.history(maxEntries: 3).length, 3);
    });
  });

  group('hasPeriodOn', () {
    test('returns false when no periods exist', () {
      expect(repo.hasPeriodOn(DateTime(2026, 6, 1)), isFalse);
    });

    test('returns true when a period exists on that date', () async {
      await box.add(Period(startedDate: DateTime(2026, 6, 1)));
      expect(repo.hasPeriodOn(DateTime(2026, 6, 1)), isTrue);
    });

    test('returns false for a date without a period', () async {
      await box.add(Period(startedDate: DateTime(2026, 6, 1)));
      expect(repo.hasPeriodOn(DateTime(2026, 6, 2)), isFalse);
    });
  });

  group('recordPeriodStart', () {
    test('saves a new period and returns it', () async {
      final saved = await repo.recordPeriodStart(DateTime(2026, 6, 1));
      expect(saved, isNotNull);
      expect(saved!.startedDate, DateTime(2026, 6, 1));
      expect(box.length, 1);
    });

    test('returns null when a period already exists for that date', () async {
      await repo.recordPeriodStart(DateTime(2026, 6, 1));
      final duplicate = await repo.recordPeriodStart(DateTime(2026, 6, 1));
      expect(duplicate, isNull);
      expect(box.length, 1);
    });

    test('normalises time components to midnight', () async {
      final saved = await repo.recordPeriodStart(
        DateTime(2026, 6, 1, 14, 30),
      );
      expect(saved!.startedDate, DateTime(2026, 6, 1));
      expect(saved.startedDate.hour, 0);
    });
  });

  group('dayOfCycle', () {
    test('returns 1 when start is today', () {
      final today = DateTime(2026, 6, 26);
      expect(PeriodRepository.dayOfCycle(today, today), 1);
    });

    test('returns correct day for mid-cycle', () {
      final start = DateTime(2026, 6, 1);
      final today = DateTime(2026, 6, 15);
      expect(PeriodRepository.dayOfCycle(start, today), 15);
    });

    test('caps at cycleLength (28) when overdue', () {
      final start = DateTime(2026, 5, 1);
      final today = DateTime(2026, 6, 26);
      expect(PeriodRepository.dayOfCycle(start, today), 28);
    });

    test('clamps to minimum of 1', () {
      final start = DateTime(2026, 6, 26);
      final today = DateTime(2026, 6, 10);
      expect(PeriodRepository.dayOfCycle(start, today), 1);
    });
  });

  group('settings defaults', () {
    test('returns defaults when no periods exist', () {
      expect(repo.trackingMode, 'automatic');
      expect(repo.manualCycleLength, 28);
      expect(repo.reminderDaysBefore, 2);
    });

    test('reads from current period when one exists', () async {
      final p = Period(startedDate: DateTime(2026, 6, 1));
      p.trackingMode = 'manual';
      p.manualCycleLength = 35;
      p.reminderDaysBefore = 3;
      await box.add(p);
      expect(repo.trackingMode, 'manual');
      expect(repo.manualCycleLength, 35);
      expect(repo.reminderDaysBefore, 3);
    });

    test('setter updates trackingMode on current period', () async {
      await repo.recordPeriodStart(DateTime(2026, 6, 1));
      await repo.setTrackingMode('manual');
      expect(repo.trackingMode, 'manual');
    });

    test('setter updates manualCycleLength on current period', () async {
      await repo.recordPeriodStart(DateTime(2026, 6, 1));
      await repo.setManualCycleLength(35);
      expect(repo.manualCycleLength, 35);
    });

    test('setter updates reminderDaysBefore on current period', () async {
      await repo.recordPeriodStart(DateTime(2026, 6, 1));
      await repo.setReminderDaysBefore(3);
      expect(repo.reminderDaysBefore, 3);
    });
  });

  group('nextReminderDate', () {
    test('returns start + 26 days at 09:00', () {
      final start = DateTime(2026, 6, 1);
      final reminder = PeriodRepository.nextReminderDate(start);
      expect(reminder, DateTime(2026, 6, 27, 9));
    });
  });
}
