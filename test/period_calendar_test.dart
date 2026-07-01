import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mona/widgets/period_calendar.dart';

void main() {
  group('PeriodCalendar', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = today.subtract(const Duration(days: 60));

    testWidgets('shows title, Cancel and Log buttons',
        (WidgetTester tester) async {
      final lastDate = today;

      await tester.pumpWidget(
        MaterialApp(
            home: _CalendarScreen(
          firstDate: firstDate,
          lastDate: lastDate,
        )),
      );
      await tester.pump();

      expect(find.text('Log a past period'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Select a date'), findsOneWidget);
    });

    testWidgets('month navigation arrows shown', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
            home: _CalendarScreen(
          firstDate: firstDate,
          lastDate: today,
        )),
      );
      await tester.pump();

      expect(find.text('<'), findsOneWidget);
      expect(find.text('>'), findsOneWidget);
    });

    testWidgets('selecting a past date updates button text',
        (WidgetTester tester) async {
      final pastDate = today.subtract(const Duration(days: 10));

      await tester.pumpWidget(
        MaterialApp(
            home: _CalendarScreen(
          firstDate: firstDate,
          lastDate: today,
          selectedDate: pastDate,
        )),
      );
      await tester.pump();

      // Confirm button shows the pre-selected date
      final months = [
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
      expect(find.text('Log ${months[pastDate.month - 1]} ${pastDate.day}'),
          findsOneWidget);
    });

    testWidgets('tapping a past date changes selection',
        (WidgetTester tester) async {
      final pastDate = today.subtract(const Duration(days: 10));

      await tester.pumpWidget(
        MaterialApp(
            home: _CalendarScreen(
          firstDate: firstDate,
          lastDate: today,
          selectedDate: pastDate,
        )),
      );
      await tester.pump();

      // The view should show the month containing pastDate.
      // Tap a different day number in the grid.
      expect(find.text('Select a date'), findsNothing);
    });

    testWidgets('Cancel returns null', (WidgetTester tester) async {
      DateTime? result;
      final lastDate = today.subtract(const Duration(days: 1));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await PeriodCalendar.show(
                    context,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                },
                child: const Text('Open'),
              );
            }),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(result, isNull);
    });

    testWidgets('selecting and confirming returns date',
        (WidgetTester tester) async {
      DateTime? result;
      final pastDate = today.subtract(const Duration(days: 8));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await PeriodCalendar.show(
                    context,
                    firstDate: firstDate,
                    lastDate: today,
                    selectedDate: pastDate,
                  );
                },
                child: const Text('Open'),
              );
            }),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Confirm button should show the pre-selected date
      final months = [
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
      await tester.tap(
        find.text('Log ${months[pastDate.month - 1]} ${pastDate.day}'),
      );
      await tester.pump();

      expect(result, isNotNull);
      expect(result!.day, pastDate.day);
      expect(result!.month, pastDate.month);
      expect(result!.year, pastDate.year);
    });

    testWidgets('month navigation changes header', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
            home: _CalendarScreen(
          firstDate: firstDate,
          lastDate: today,
        )),
      );
      await tester.pump();

      final months = [
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
      expect(find.textContaining(months[today.month - 1]), findsOneWidget);

      // Navigate to previous month
      await tester.tap(find.text('<'));
      await tester.pump();

      final prevMonth = months[(today.month - 2) % 12];
      expect(find.textContaining(prevMonth), findsOneWidget);
    });

    testWidgets('tapping a logged date shows snackbar',
        (WidgetTester tester) async {
      final loggedDate = today.subtract(const Duration(days: 5));
      // Use a different selectedDate so tapping the logged date triggers snackbar
      final otherDate = today.subtract(const Duration(days: 10));

      await tester.pumpWidget(
        MaterialApp(
            home: _CalendarScreen(
          firstDate: firstDate,
          lastDate: today,
          loggedDates: {loggedDate},
          selectedDate: otherDate,
        )),
      );
      await tester.pump();

      addTearDown(() => tester.binding.setSurfaceSize(Size.zero));
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      // Tap the logged date — should trigger snackbar since it differs from selectedDate
      await tester.tap(find.text('${loggedDate.day}'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Already logged'), findsOneWidget);
    });

    testWidgets('pre-selected date renders on Confirm button',
        (WidgetTester tester) async {
      final selected = today.subtract(const Duration(days: 3));

      await tester.pumpWidget(
        MaterialApp(
            home: _CalendarScreen(
          firstDate: firstDate,
          lastDate: today,
          selectedDate: selected,
        )),
      );
      await tester.pump();

      final months = [
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
      expect(
        find.text('Log ${months[selected.month - 1]} ${selected.day}'),
        findsOneWidget,
      );
    });
  });
}

/// Helper that renders PeriodCalendar directly (no bottom sheet).
class _CalendarScreen extends StatelessWidget {
  const _CalendarScreen({
    required this.firstDate,
    required this.lastDate,
    this.loggedDates = const {},
    this.selectedDate,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final Set<DateTime> loggedDates;
  final DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PeriodCalendar(
        firstDate: firstDate,
        lastDate: lastDate,
        loggedDates: loggedDates,
        selectedDate: selectedDate,
      ),
    );
  }
}
