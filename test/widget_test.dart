import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:mona/main.dart';
import 'package:mona/models/period.dart';
import 'package:mona/services/period_repository.dart';

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

  testWidgets('Empty state shows prompt and no day counter',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Tap below when your period starts.'), findsOneWidget);
    // Day counter should not render when no period is logged (no large digits)
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('Logged state shows day counter and caption',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final box = Hive.box<Period>('periods');
    await box.add(Period(startedDate: yesterday));

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Day counter shows day 2 (yesterday = day 1, today = day 2)
    expect(find.text('2'), findsOneWidget);
    // Empty-state prompt should not appear
    expect(
      find.text('Tap below when your period starts.'),
      findsNothing,
    );
    // Caption shows today's date in "Weekday, day Month" format
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final expectedCaption =
        '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
    expect(find.text(expectedCaption), findsOneWidget);
  });
}
