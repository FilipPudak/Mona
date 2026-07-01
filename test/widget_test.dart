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

  testWidgets('Empty state shows no day counter and no caption',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('Tap below when your period starts.'), findsNothing);
  });

  testWidgets('Logged state shows bare expected date without prefix',
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
    final dd = dueDate.day.toString().padLeft(2, '0');
    final mm = dueDate.month.toString().padLeft(2, '0');
    expect(find.text('$dd/$mm'), findsOneWidget);
    expect(find.textContaining('Next:'), findsNothing);
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

  testWidgets('Day counter dims in black phase when overdue',
      (WidgetTester tester) async {
    final start = DateTime.now().subtract(const Duration(days: 35));
    await tester.runAsync(() async {
      final box = Hive.box<Period>('periods');
      await box.add(Period(startedDate: start));
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final dayText = tester.widget<Text>(find.text('36'));
    expect(dayText.style?.color, Colors.black87.withValues(alpha: 0.38));
  });

  testWidgets('Expected date dims when overdue', (WidgetTester tester) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 35));
    await tester.runAsync(() async {
      final box = Hive.box<Period>('periods');
      await box.add(Period(startedDate: start));
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final opacityWidget =
        tester.widget<Opacity>(find.byKey(const Key('expected_date_opacity')));
    expect(opacityWidget.opacity, 0.38);
  });

  testWidgets('Day counter shows 99+ when day exceeds 99',
      (WidgetTester tester) async {
    final start = DateTime.now().subtract(const Duration(days: 120));
    await tester.runAsync(() async {
      final box = Hive.box<Period>('periods');
      await box.add(Period(startedDate: start));
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('99+'), findsOneWidget);
    expect(find.text('121'), findsNothing);
  });

  testWidgets('Day counter shows uncapped value past cycle length',
      (WidgetTester tester) async {
    final start = DateTime.now().subtract(const Duration(days: 35));
    await tester.runAsync(() async {
      final box = Hive.box<Period>('periods');
      await box.add(Period(startedDate: start));
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('36'), findsOneWidget);
  });

  testWidgets('Settings shows date format control',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen()),
    );
    await tester.pump();

    expect(find.text('Date format'), findsAtLeastNWidgets(1));
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

    final daysBeforeTile = find.text('Days before');
    expect(tester.widget<Text>(daysBeforeTile).style?.color, Colors.grey);

    await tester.tap(daysBeforeTile);
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

  testWidgets('App bar has history icon to navigate to records',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byIcon(Icons.history), findsOneWidget);
  });

  testWidgets('History shows empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.history));
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

    await tester.tap(find.byIcon(Icons.history));
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

    await tester.tap(find.byIcon(Icons.history));
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

  testWidgets('Rose circle + button replaces Start text',
      (WidgetTester tester) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(Size.zero);
    });
    await tester.binding.setSurfaceSize(const Size(800, 1000));

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Start'), findsNothing);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Log period: + button opens picker', (WidgetTester tester) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(Size.zero);
    });
    await tester.binding.setSurfaceSize(const Size(800, 1000));

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Period started on?'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });
}
