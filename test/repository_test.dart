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
      expect(saved!.startedDate, DateTime.utc(2026, 6, 1));
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
      expect(saved!.startedDate, DateTime.utc(2026, 6, 1));
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

    test('defaults to 28-day cap when no cycleLength given', () {
      final start = DateTime(2026, 5, 1);
      final today = DateTime(2026, 6, 26);
      expect(PeriodRepository.dayOfCycle(start, today), 28);
    });

    test('uses provided cycleLength as cap', () {
      final start = DateTime(2026, 6, 1);
      final today = DateTime(2026, 7, 1);
      expect(PeriodRepository.dayOfCycle(start, today, cycleLength: 35), 31);
    });

    test('caps at provided cycleLength when overdue', () {
      final start = DateTime(2026, 6, 1);
      final today = DateTime(2026, 7, 20);
      expect(PeriodRepository.dayOfCycle(start, today, cycleLength: 35), 35);
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

  group('prediction engine', () {
    group('hasEnoughHistory', () {
      test('returns false with 0, 1, 2, or 3 periods', () async {
        expect(repo.hasEnoughHistory(), isFalse);
        await repo.recordPeriodStart(DateTime(2026, 1, 1));
        expect(repo.hasEnoughHistory(), isFalse);
        await repo.recordPeriodStart(DateTime(2026, 2, 1));
        expect(repo.hasEnoughHistory(), isFalse);
        await repo.recordPeriodStart(DateTime(2026, 3, 1));
        expect(repo.hasEnoughHistory(), isFalse);
      });

      test('returns true with 4 periods (3 complete cycles)', () async {
        await repo.recordPeriodStart(DateTime(2026, 1, 1));
        await repo.recordPeriodStart(DateTime(2026, 2, 1));
        await repo.recordPeriodStart(DateTime(2026, 3, 1));
        await repo.recordPeriodStart(DateTime(2026, 4, 1));
        expect(repo.hasEnoughHistory(), isTrue);
      });
    });

    group('averageCycleLength', () {
      test('computes average of 30-day cycles', () async {
        await repo.recordPeriodStart(DateTime(2026, 1, 1));
        await repo.recordPeriodStart(DateTime(2026, 1, 31));
        await repo.recordPeriodStart(DateTime(2026, 3, 2));
        await repo.recordPeriodStart(DateTime(2026, 4, 1));
        expect(repo.averageCycleLength(), 30);
      });

      test('returns null with fewer than 4 periods', () async {
        await repo.recordPeriodStart(DateTime(2026, 1, 1));
        await repo.recordPeriodStart(DateTime(2026, 2, 1));
        await repo.recordPeriodStart(DateTime(2026, 3, 1));
        expect(repo.averageCycleLength(), isNull);
      });

      test('excludes gaps over 42 days', () async {
        await repo.recordPeriodStart(DateTime(2026, 1, 1));
        await repo.recordPeriodStart(DateTime(2026, 2, 1));
        await repo.recordPeriodStart(DateTime(2026, 3, 1));
        await repo.recordPeriodStart(DateTime(2026, 7, 1));
        // gap from Mar 1 to Jul 1 is 122 days > 42, so only 1 gap remains
        expect(repo.averageCycleLength(), isNull);
      });

      test('computes average excluding large gaps, keeping ≥3', () async {
        await repo.recordPeriodStart(DateTime(2026, 1, 1));
        await repo.recordPeriodStart(DateTime(2026, 2, 1));
        await repo.recordPeriodStart(DateTime(2026, 3, 1));
        await repo.recordPeriodStart(DateTime(2026, 4, 1));
        await repo.recordPeriodStart(DateTime(2026, 10, 1));
        // gaps: 31, 28, 31 (≤42), 183 (>42 excluded)
        // 3 valid gaps → (31+28+31)/3 = 30
        expect(repo.averageCycleLength(), 30);
      });

      test('returns null when exclusion drops valid gaps below 3', () async {
        await repo.recordPeriodStart(DateTime(2026, 1, 1));
        await repo.recordPeriodStart(DateTime(2026, 2, 1));
        await repo.recordPeriodStart(DateTime(2027, 3, 1));
        await repo.recordPeriodStart(DateTime(2027, 4, 1));
        await repo.recordPeriodStart(DateTime(2028, 5, 1));
        // gaps: 31 (Jan→Feb), 393 (>42 excluded), 31, 395 (>42 excluded)
        // only 2 valid gaps → null
        expect(repo.averageCycleLength(), isNull);
      });
    });

    group('currentCycleLength', () {
      test('returns manualCycleLength in manual mode', () async {
        await repo.recordPeriodStart(DateTime(2026, 6, 1));
        await repo.setManualCycleLength(35);
        await repo.setTrackingMode('manual');
        expect(repo.currentCycleLength(), 35);
      });

      test('falls back to manualCycleLength in auto mode with <4 periods',
          () async {
        await repo.recordPeriodStart(DateTime(2026, 6, 1));
        await repo.setManualCycleLength(35);
        expect(repo.currentCycleLength(), 35);
      });

      test('returns average in auto mode with 4+ periods', () async {
        await repo.recordPeriodStart(DateTime(2026, 1, 1));
        await repo.recordPeriodStart(DateTime(2026, 1, 31));
        await repo.recordPeriodStart(DateTime(2026, 3, 2));
        await repo.recordPeriodStart(DateTime(2026, 4, 1));
        expect(repo.currentCycleLength(), 30);
      });
    });

    group('eligibleForAuto', () {
      test('returns false when no periods exist', () {
        expect(repo.eligibleForAuto(), isFalse);
      });

      test('returns false with 1, 2, or 3 periods', () async {
        await repo.recordPeriodStart(DateTime(2026, 1, 1));
        expect(repo.eligibleForAuto(), isFalse);
        await repo.recordPeriodStart(DateTime(2026, 2, 1));
        expect(repo.eligibleForAuto(), isFalse);
        await repo.recordPeriodStart(DateTime(2026, 3, 1));
        expect(repo.eligibleForAuto(), isFalse);
      });

      test('returns true with 4 periods and valid gaps', () async {
        await repo.recordPeriodStart(DateTime(2026, 1, 1));
        await repo.recordPeriodStart(DateTime(2026, 1, 31));
        await repo.recordPeriodStart(DateTime(2026, 3, 2));
        await repo.recordPeriodStart(DateTime(2026, 4, 1));
        expect(repo.eligibleForAuto(), isTrue);
      });

      test('returns false in manual mode', () async {
        await repo.recordPeriodStart(DateTime(2026, 1, 1));
        await repo.recordPeriodStart(DateTime(2026, 1, 31));
        await repo.recordPeriodStart(DateTime(2026, 3, 2));
        await repo.recordPeriodStart(DateTime(2026, 4, 1));
        await repo.setTrackingMode('manual');
        expect(repo.eligibleForAuto(), isFalse);
      });

      test('returns false when all gaps exceed 42 days', () async {
        await repo.recordPeriodStart(DateTime(2026, 1, 1));
        await repo.recordPeriodStart(DateTime(2026, 5, 1));
        await repo.recordPeriodStart(DateTime(2026, 9, 1));
        await repo.recordPeriodStart(DateTime(2027, 1, 1));
        expect(repo.eligibleForAuto(), isFalse);
      });
    });
  });

  group('nextReminderDate', () {
    test('defaults to 28-day cycle, 2 days before', () {
      final start = DateTime(2026, 6, 1);
      final reminder = PeriodRepository.nextReminderDate(start);
      // due = start + 28 = June 29, reminder = due - 2 = June 27
      expect(reminder, DateTime(2026, 6, 27, 9));
    });

    test('uses provided cycleLength and reminderDaysBefore', () {
      final start = DateTime(2026, 6, 1);
      final reminder = PeriodRepository.nextReminderDate(
        start,
        cycleLength: 35,
        reminderDaysBefore: 3,
      );
      // due = start + 35 = July 6, reminder = due - 3 = July 3
      expect(reminder, DateTime(2026, 7, 3, 9));
    });
  });
}
