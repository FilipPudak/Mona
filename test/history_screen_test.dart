import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:mona/main.dart';
import 'package:mona/models/period.dart';
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

  testWidgets('delete with Undo restores the period row',
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

    // Swipe to delete
    await tester.runAsync(() async {
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();
    });

    expect(find.byType(PeriodRow), findsNothing);
    expect(find.text('No periods logged yet.'), findsOneWidget);

    // Tap Undo (wrapped in runAsync for Hive I/O)
    await tester.runAsync(() async {
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
    });

    expect(find.byType(PeriodRow), findsOneWidget);
    expect(find.text('No periods logged yet.'), findsNothing);
  });

  testWidgets('tap on period row opens calendar for editing',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Period>('periods');
      await box.add(Period(startedDate: DateTime(2026, 6, 1)));
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    // Tap the period row
    await tester.tap(find.byType(PeriodRow));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Calendar should open with pre-selected date
    expect(find.text('Log a past period'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
