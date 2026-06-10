import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/period.dart';
import '../services/period_repository.dart';
import '../widgets/period_row.dart';

/// Read-only list of the user's most recent periods, newest first.
/// Capped at the most recent 12 entries.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PeriodRepository(Hive.box<Period>(PeriodRepository.boxName));
    final entries = repo.history();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: entries.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  return PeriodRow(period: entries[index]);
                },
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No periods logged yet.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.black54,
            ),
      ),
    );
  }
}
