import 'package:flutter/material.dart';

/// Large "Day X" display with a smaller "of 28" subtitle. Scandinavian style:
/// black text on white, no decorations.
class DayCounter extends StatelessWidget {
  const DayCounter({super.key, required this.day, this.total = 28, required this.color});

  final int day;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Day $day',
          style: theme.textTheme.displayMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'of $total',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.black54,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
