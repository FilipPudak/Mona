import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:mona/main.dart';
import 'package:mona/models/period.dart';
import 'package:mona/models/settings.dart';

/// Pre-populate settings (preventing _migrateSettingsIfNeeded writes during
/// widget construction) and optionally seed a period.
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

/// Pump enough frames for route transitions and dialog animations to settle.
Future<void> pumpUntilSettled(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
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

  testWidgets('shows day counter when period exists',
      (WidgetTester tester) async {
    await tester.runAsync(() => prepopulate(periodDate: DateTime.now()));

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('shows empty state when no period exists',
      (WidgetTester tester) async {
    await tester.runAsync(() => prepopulate());

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('1'), findsNothing);
  });

  testWidgets('expected date shows dd/mm when period logged',
      (WidgetTester tester) async {
    final start = DateTime.now().subtract(const Duration(days: 10));
    await tester.runAsync(() => prepopulate(periodDate: start));

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final dueDate = start.add(const Duration(days: 28));
    final dd = dueDate.day.toString().padLeft(2, '0');
    final mm = dueDate.month.toString().padLeft(2, '0');
    expect(find.text('$dd/$mm'), findsOneWidget);
  });

  testWidgets('+ button shown, Start text absent', (WidgetTester tester) async {
    await tester.runAsync(() => prepopulate());

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('Start'), findsNothing);
  });

  testWidgets('+ button opens list picker', (WidgetTester tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(Size.zero));
    await tester.binding.setSurfaceSize(const Size(800, 1000));

    await tester.runAsync(() => prepopulate());

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Period started on?'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });
}
