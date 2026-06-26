import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:mona/main.dart';
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

  testWidgets('App bar shows Mona', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Mona'), findsOneWidget);
  });

  testWidgets('App bar has gear icon for settings',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('Settings screen shows tracking mode options',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen()),
    );
    await tester.pump();

    expect(find.text('Tracking mode'), findsOneWidget);
    expect(find.text('Cycle length'), findsAtLeastNWidgets(1));
    expect(find.text('Reminder'), findsAtLeastNWidgets(1));
    expect(find.text('Notifications'), findsAtLeastNWidgets(1));
    expect(find.text('Your data stays on this device.'), findsOneWidget);
  });

  testWidgets('Empty state shows prompt and no day counter',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Tap below when your period starts.'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('Logged state shows "Next: Month Day" caption',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 10));
    await tester.runAsync(() async {
      final box = Hive.box<Period>('periods');
      await box.add(Period(startedDate: start));
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final dueDate = start.add(const Duration(days: 28));
    final expected = 'Next: ${_monthName(dueDate.month)} ${dueDate.day}';
    expect(find.text(expected), findsOneWidget);
    expect(find.text('Tap below when your period starts.'), findsNothing);
  });

  testWidgets('Due window shows "Period may start today."',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 28));
    await tester.runAsync(() async {
      final box = Hive.box<Period>('periods');
      await box.add(Period(startedDate: start));
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Period may start today.'), findsOneWidget);
  });

  testWidgets('Day 1 shows rose phase color', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Period>('periods');
      await box.add(Period(startedDate: DateTime.now()));
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final text = tester.widget<Text>(find.text('1'));
    expect(text.style?.color, const Color(0xFFE68192));
  });

  testWidgets('Day 12 shows green phase color', (WidgetTester tester) async {
    final start = DateTime.now().subtract(const Duration(days: 11));
    await tester.runAsync(() async {
      final box = Hive.box<Period>('periods');
      await box.add(Period(startedDate: start));
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final text = tester.widget<Text>(find.text('12'));
    expect(text.style?.color, Colors.green);
  });

  testWidgets('Day 18 shows default black color', (WidgetTester tester) async {
    final start = DateTime.now().subtract(const Duration(days: 17));
    await tester.runAsync(() async {
      final box = Hive.box<Period>('periods');
      await box.add(Period(startedDate: start));
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final text = tester.widget<Text>(find.text('18'));
    expect(text.style?.color, Colors.black87);
  });

  testWidgets('Day counter capped at cycle length when overdue',
      (WidgetTester tester) async {
    final start = DateTime.now().subtract(const Duration(days: 35));
    await tester.runAsync(() async {
      final box = Hive.box<Period>('periods');
      await box.add(Period(startedDate: start));
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('28'), findsOneWidget);
    expect(find.text('36'), findsNothing);
  });

  testWidgets('Overdue shows "Log your new period."',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 45));
    await tester.runAsync(() async {
      final box = Hive.box<Period>('periods');
      await box.add(Period(startedDate: start));
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Log your new period.'), findsOneWidget);
  });
}

String _monthName(int month) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return months[month - 1];
}
