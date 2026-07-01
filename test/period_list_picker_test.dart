import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mona/widgets/period_list_picker.dart';

void main() {
  group('PeriodListPicker', () {
    testWidgets('shows title, Today label, and Log Period button',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final firstDate = today.subtract(const Duration(days: 3));

      await tester.pumpWidget(
        MaterialApp(home: _TestScreen(firstDate: firstDate, lastDate: today)),
      );
      await tester.pump();

      expect(find.text('Period started on?'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Log Period'), findsOneWidget);
    });

    testWidgets('shows Yesterday and relative day labels',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final firstDate = today.subtract(const Duration(days: 3));

      await tester.pumpWidget(
        MaterialApp(home: _TestScreen(firstDate: firstDate, lastDate: today)),
      );
      await tester.pump();

      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('2 days ago'), findsOneWidget);
      expect(find.text('3 days ago'), findsOneWidget);
    });

    testWidgets('tapping a date and confirming returns it',
        (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(Size.zero));
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      DateTime? result;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final firstDate = today.subtract(const Duration(days: 3));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await PeriodListPicker.show(
                    context,
                    firstDate: firstDate,
                    lastDate: today,
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

      // Tap "2 days ago" instead of default "Today"
      await tester.tap(find.text('2 days ago'));
      await tester.pump();

      await tester.tap(find.text('Log Period'));
      await tester.pump();

      expect(result, isNotNull);
      final expected = today.subtract(const Duration(days: 2));
      expect(result!.day, expected.day);
      expect(result!.month, expected.month);
      expect(result!.year, expected.year);
    });

    testWidgets('Log Period returns default today date when no selection',
        (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(Size.zero));
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      DateTime? result;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final firstDate = today.subtract(const Duration(days: 2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await PeriodListPicker.show(
                    context,
                    firstDate: firstDate,
                    lastDate: today,
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

      await tester.tap(find.text('Log Period'));
      await tester.pump();

      expect(result, isNotNull);
      expect(result!.day, today.day);
      expect(result!.month, today.month);
      expect(result!.year, today.year);
    });
  });
}

/// Helper that renders PeriodListPicker directly (no bottom sheet).
class _TestScreen extends StatelessWidget {
  const _TestScreen({
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime firstDate;
  final DateTime lastDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PeriodListPicker(
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }
}
