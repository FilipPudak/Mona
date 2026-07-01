import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:mona/models/period.dart';
import 'package:mona/screens/settings_screen.dart';

void main() {
  setUp(() async {
    Hive.init(Directory.systemTemp.createTempSync('.test').path);
    if (!Hive.isAdapterRegistered(PeriodAdapter().typeId)) {
      Hive.registerAdapter(PeriodAdapter());
    }
    await Hive.openBox<Period>('periods');
  });

  tearDown(() async {
    final box = Hive.box<Period>('periods');
    await box.close();
    await Hive.deleteBoxFromDisk('periods');
  });

  group('tracking mode', () {
    testWidgets('Cycle length row appears when Manual is selected',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final box = Hive.box<Period>('periods');
        await box.add(Period(startedDate: DateTime(2026, 6, 1)));
      });

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();

      expect(find.text('Cycle length'), findsNothing);

      // Tap Manual and let Hive I/O complete
      await tester.runAsync(() async {
        await tester.tap(find.text('Manual (fixed length)'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.text('Cycle length'), findsOneWidget);
    });

    testWidgets('Cycle length row hides when Automatic is selected',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final box = Hive.box<Period>('periods');
        await box.add(Period(startedDate: DateTime(2026, 6, 1)));
      });

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.text('Manual (fixed length)'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.text('Cycle length'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.text('Automatic (learns from cycles)'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.text('Cycle length'), findsNothing);
    });

    testWidgets('tapping radio updates tracking mode in store',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final box = Hive.box<Period>('periods');
        await box.add(Period(startedDate: DateTime(2026, 6, 1)));
      });

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.text('Manual (fixed length)'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      final period = Hive.box<Period>('periods').values.first;
      expect(period.trackingMode, 'manual');
    });
  });

  group('date format', () {
    testWidgets('SegmentedButton has both format options',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final box = Hive.box<Period>('periods');
        await box.add(Period(startedDate: DateTime(2026, 6, 1)));
      });

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();

      expect(find.text('DD/MM'), findsOneWidget);
      expect(find.text('MM/DD'), findsOneWidget);
    });

    testWidgets('tapping MM/DD updates dateFormat in store',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final box = Hive.box<Period>('periods');
        await box.add(Period(startedDate: DateTime(2026, 6, 1)));
      });

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.text('MM/DD'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      final period = Hive.box<Period>('periods').values.first;
      expect(period.dateFormat, 'US');
    });

    testWidgets('tapping DD/MM after US updates back to EU',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final box = Hive.box<Period>('periods');
        final p = Period(startedDate: DateTime(2026, 6, 1));
        p.dateFormat = 'US';
        await box.add(p);
      });

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.text('DD/MM'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      final period = Hive.box<Period>('periods').values.first;
      expect(period.dateFormat, 'EU');
    });
  });

  testWidgets('all section headers render', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump();

    expect(find.text('Tracking mode'), findsOneWidget);
    expect(find.text('Reminder'), findsAtLeastNWidgets(1));
    expect(find.text('Date format'), findsAtLeastNWidgets(1));
    expect(find.text('Privacy'), findsOneWidget);
  });
}
