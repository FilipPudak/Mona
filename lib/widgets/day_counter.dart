import 'package:flutter/material.dart';

class DayCounter extends StatelessWidget {
  const DayCounter({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.75),
      ),
      child: Text(
        label,
        style: theme.textTheme.displayLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}
