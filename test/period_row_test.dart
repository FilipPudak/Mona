import 'package:flutter_test/flutter_test.dart';

import 'package:mona/widgets/period_row.dart';

void main() {
  group('PeriodRow.formatDate', () {
    final thisYear = DateTime.now().year;
    final lastYear = thisYear - 1;

    test('EU format shows DD/MM for same-year date', () {
      final date = DateTime(thisYear, 6, 15);
      expect(PeriodRow.formatDate(date, 'EU'), '15/06');
    });

    test('EU format shows DD/MM/YYYY for different-year date', () {
      final date = DateTime(lastYear, 1, 1);
      expect(PeriodRow.formatDate(date, 'EU'), '01/01/$lastYear');
    });

    test('US format shows MM/DD for same-year date', () {
      final date = DateTime(thisYear, 6, 15);
      expect(PeriodRow.formatDate(date, 'US'), '06/15');
    });

    test('US format shows MM/DD/YYYY for different-year date', () {
      final date = DateTime(lastYear, 1, 1);
      expect(PeriodRow.formatDate(date, 'US'), '01/01/$lastYear');
    });
  });
}
