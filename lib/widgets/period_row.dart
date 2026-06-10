import 'package:flutter/material.dart';

import '../models/period.dart';

/// A single row in the history list: the full date in long format with a
/// hairline divider below. Read-only; no actions, no icons.
class PeriodRow extends StatelessWidget {
  const PeriodRow({super.key, required this.period});

  final Period period;

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  String _format(DateTime d) {
    final weekday = _weekdays[d.weekday - 1];
    final month = _months[d.month - 1];
    return '$weekday, ${d.day} $month';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            _format(period.startedDate),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEAECEF)),
      ],
    );
  }
}
