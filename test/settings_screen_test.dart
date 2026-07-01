import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:mona/models/period.dart';
import 'package:mona/models/settings.dart';
import 'package:mona/screens/settings_screen.dart';
import 'package:mona/services/period_repository.dart';
import 'test_helpers.dart';

void main() {
  setUp(() async {
    Hive.init(Directory.systemTemp.createTempSync('.test').path);
    if (!Hive.isAdapterRegistered(PeriodAdapter().typeId)) {
      Hive.registerAdapter(PeriodAdapter());
    }
    if (!Hive.isAdapterRegistered(SettingsAdapter().typeId)) {
      Hive.registerAdapter(SettingsAdapter());
    }
    await Hive.openBox<Period>('periods');
    await Hive.openBox<Settings>('settings');
  });

  tearDown(() async {
    final box = Hive.box<Period>('periods');
    await box.close();
    final settings = Hive.box<Settings>('settings');
    await settings.close();
    await Hive.deleteBoxFromDisk('periods');
    await Hive.deleteBoxFromDisk('settings');
  });

  group('tracking mode', () {
    testWidgets('Cycle length row appears when Manual is selected',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final box = Hive.box<Settings>('settings');
        await box.add(Settings(trackingMode: 'manual'));
      });

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();

      expect(find.text('Cycle length'), findsOneWidget);
    });

    testWidgets('Cycle length row hides when Automatic is selected',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final box = Hive.box<Settings>('settings');
        await box.add(Settings(trackingMode: 'automatic'));
      });

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();

      expect(find.text('Cycle length'), findsNothing);
    });

    testWidgets('tapping radio updates tracking mode in store',
        (WidgetTester tester) async {
      await tester.runAsync(() => prepopulate());

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.text('Manual (fixed length)'));
        await tester.pumpAndSettle();
      });

      final repo = PeriodRepository(Hive.box<Period>('periods'));
      expect(repo.trackingMode, 'manual');
    });
  });

  group('date format', () {
    testWidgets('SegmentedButton has both format options',
        (WidgetTester tester) async {
      await tester.runAsync(() => prepopulate());

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();

      expect(find.text('DD/MM'), findsOneWidget);
      expect(find.text('MM/DD'), findsOneWidget);
    });

    testWidgets('tapping MM/DD updates dateFormat in store',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final box = Hive.box<Settings>('settings');
        await box.add(Settings(dateFormat: 'EU'));
      });

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.text('MM/DD'));
        await tester.pumpAndSettle();
      });

      final repo = PeriodRepository(Hive.box<Period>('periods'));
      expect(repo.dateFormat, 'US');
    });

    testWidgets('tapping DD/MM after US updates back to EU',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final box = Hive.box<Settings>('settings');
        await box.add(Settings(dateFormat: 'US'));
      });

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.text('DD/MM'));
        await tester.pumpAndSettle();
      });

      final repo = PeriodRepository(Hive.box<Period>('periods'));
      expect(repo.dateFormat, 'EU');
    });
  });

  testWidgets('all section headers render', (WidgetTester tester) async {
    await tester.runAsync(() => prepopulate());

    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump();

    expect(find.text('Tracking mode'), findsOneWidget);
    expect(find.text('Reminder'), findsAtLeastNWidgets(1));
    expect(find.text('Date format'), findsAtLeastNWidgets(1));
    expect(find.text('Privacy'), findsOneWidget);
  });
}
