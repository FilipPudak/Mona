// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:mona/main.dart';
import 'package:mona/models/period.dart';

void main() {
  setUp(() async {
    Hive.init(Directory.systemTemp.createTempSync('.test').path);
    Hive.registerAdapter(PeriodAdapter());
    await Hive.openBox<Period>('periods');
  });

  testWidgets('App bar shows Mona', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Mona'), findsOneWidget);
  });
}
