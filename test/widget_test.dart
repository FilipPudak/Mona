import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:mona/main.dart';
import 'package:mona/models/period.dart';
import 'package:mona/screens/settings_screen.dart';
import 'package:mona/widgets/period_row.dart';

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
    expect(find.text('Notification'), findsAtLeastNWidgets(1));
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

  testWidgets('Settings shows merged Reminder section with correct labels',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen()),
    );
    await tester.pump();

    expect(find.text('Reminder'), findsAtLeastNWidgets(1));
    expect(find.text('Days before'), findsAtLeastNWidgets(1));
    expect(find.text('Notification'), findsAtLeastNWidgets(1));
    expect(find.text('Notifications'), findsNothing);
  });

  testWidgets('Days before row disabled when notifications OFF',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen()),
    );
    await tester.pump();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.chevron_right), findsNothing);

    await tester.tap(find.text('Days before'));
    await tester.pumpAndSettle();
    expect(find.byType(ListWheelScrollView), findsNothing);
  });

  testWidgets('Days before row enabled when notifications ON',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen()),
    );
    await tester.pump();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Days before'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ListWheelScrollView), findsOneWidget);
  });

  testWidgets('Settings: notifications switch toggles',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, isFalse);
  });

  testWidgets('History shows empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('No periods logged yet.'), findsOneWidget);
  });

  testWidgets('History shows period rows when periods exist',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Period>('periods');
      await box.add(Period(startedDate: DateTime(2026, 6, 1)));
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.byType(PeriodRow), findsOneWidget);
  });

  testWidgets('Swipe-to-delete removes row and shows empty state',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Period>('periods');
      await box.add(Period(startedDate: DateTime(2026, 6, 1)));
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.byType(PeriodRow), findsOneWidget);

    // Wrap the swipe in runAsync so fire-and-forget Hive I/O completes
    // before teardown, preventing box.close() from hanging.
    await tester.runAsync(() async {
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();
    });

    expect(find.byType(PeriodRow), findsNothing);
    expect(find.text('No periods logged yet.'), findsOneWidget);
  });

  testWidgets('Log period: Start button opens picker',
      (WidgetTester tester) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(Size.zero);
    });
    await tester.binding.setSurfaceSize(const Size(800, 1000));

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Period started on?'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });
}

String _monthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return months[month - 1];
}
