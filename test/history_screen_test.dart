import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:mona/main.dart';
import 'package:mona/models/period.dart';
import 'package:mona/models/settings.dart';
import 'package:mona/widgets/period_row.dart';

/// Helper: pre-populate Hive boxes inside real async so I/O completes.
Future<void> prepopulate({DateTime? periodDate}) async {
  final box = Hive.box<Period>('periods');
  if (periodDate != null) {
    await box.add(Period(startedDate: periodDate));
  }
  final settings = Hive.box<Settings>('settings');
  if (settings.isEmpty) {
    await settings.add(Settings());
  }
}

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

  testWidgets('tap on period row opens calendar for editing',
      (WidgetTester tester) async {
    await tester.runAsync(() => prepopulate(periodDate: DateTime(2026, 6, 28)));

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.history));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Tap the period row
    await tester.tap(find.byType(PeriodRow));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Calendar should open with pre-selected date
    expect(find.text('Log a past period'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('shows empty state when no period exists',
      (WidgetTester tester) async {
    await tester.runAsync(() => prepopulate());

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.history));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('No periods logged yet.'), findsOneWidget);
  });
}
