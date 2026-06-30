import 'package:flutter/material.dart';

class DayCounter extends StatelessWidget {
  const DayCounter({super.key, required this.day, required this.color});

  final int day;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.75),
      ),
      child: Text(
        '$day',
        style: theme.textTheme.displayLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}
