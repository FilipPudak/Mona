import 'package:flutter/material.dart';

import '../models/period.dart';

/// A single row in the history list: the full date in long format with a
/// hairline divider below. Read-only; no actions, no icons.
class PeriodRow extends StatelessWidget {
  const PeriodRow({
    super.key,
    required this.period,
    required this.dateFormat,
    this.onTap,
  });

  final Period period;
  final String dateFormat;
  final VoidCallback? onTap;

  static String formatDate(DateTime date, String dateFormat) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    final formatted = dateFormat == 'US' ? '$mm/$dd' : '$dd/$mm';
    if (date.year != DateTime.now().year) return '$formatted/$yyyy';
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              formatDate(period.startedDate, dateFormat),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEAECEF)),
        ],
      ),
    );
  }
}
