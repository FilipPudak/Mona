import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/period.dart';
import '../services/period_repository.dart';
import '../widgets/period_calendar.dart';
import '../widgets/period_row.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late PeriodRepository _repo;
  List<Period> _entries = [];

  @override
  void initState() {
    super.initState();
    _repo = PeriodRepository(_repoBox);
    _load();
  }

  Box<Period> get _repoBox => Hive.box<Period>(PeriodRepository.boxName);

  void _load() {
    setState(() {
      _entries = _repo.history();
    });
  }

  Future<void> _onAddPastPeriod() async {
    final messenger = ScaffoldMessenger.of(context);
    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final lastDate = DateTime.now().subtract(const Duration(days: 1));

    final picked = await PeriodCalendar.show(
      context,
      firstDate: firstDate,
      lastDate: lastDate,
      loggedDates: _repo.loggedDates(),
    );
    if (picked == null) return;

    final saved = await _repo.recordPeriodStart(picked);
    if (saved == null) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Already logged for that date.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _repo.rescheduleReminder();

    if (!mounted) return;
    setState(() => _entries.insert(0, saved));
    messenger.showSnackBar(
      SnackBar(
        content: Text(
            'Logged period for ${picked.toLocal().toString().split(' ').first}.'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        persist: false,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            saved.delete();
            if (!mounted) return;
            setState(() => _entries.removeWhere((p) => p.key == saved.key));
          },
        ),
      ),
    );
  }

  Future<void> _onEditPeriod(Period period) async {
    final messenger = ScaffoldMessenger.of(context);
    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final lastDate = DateTime.now().subtract(const Duration(days: 1));
    final oldDate = period.startedDate;

    final logged = _repo.loggedDates();
    logged.remove(DateTime(
      period.startedDate.year,
      period.startedDate.month,
      period.startedDate.day,
    ));

    final picked = await PeriodCalendar.show(
      context,
      firstDate: firstDate,
      lastDate: lastDate,
      loggedDates: logged,
      selectedDate: period.startedDate,
    );
    if (picked == null) return;

    if (picked.year == period.startedDate.year &&
        picked.month == period.startedDate.month &&
        picked.day == period.startedDate.day) {
      return;
    }

    if (_repo.hasPeriodOn(picked)) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Already logged for that date.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    period.startedDate = DateTime.utc(picked.year, picked.month, picked.day);
    if (!mounted) return;

    try {
      await period.save();
    } catch (e) {
      if (!mounted) return;
      period.startedDate = oldDate;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not update: $e'),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    await _repo.rescheduleReminder();

    if (!mounted) return;
    setState(() {
      final idx = _entries.indexWhere((p) => p.key == period.key);
      if (idx != -1) _entries[idx] = period;
      _entries.sort((a, b) => b.startedDate.compareTo(a.startedDate));
    });

    messenger.showSnackBar(
      SnackBar(
        content:
            Text('Updated to ${picked.toLocal().toString().split(' ').first}.'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        persist: false,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            period.startedDate = oldDate;
            try {
              await period.save();
              await _repo.rescheduleReminder();
              if (!mounted) return;
              setState(() {
                final idx = _entries.indexWhere((p) => p.key == period.key);
                if (idx != -1) _entries[idx] = period;
                _entries.sort((a, b) => b.startedDate.compareTo(a.startedDate));
              });
            } on HiveError {
              // Box was closed
            }
          },
        ),
      ),
    );
  }

  void _onDeletePeriod(Period period) {
    final messenger = ScaffoldMessenger.of(context);
    final dateStr = period.startedDate.toLocal().toString().split(' ').first;

    setState(() => _entries.removeWhere((p) => p.key == period.key));

    // Fire-and-forget delete; the future is captured so Undo can serialise
    // after it, avoiding the race where the delete completes mid-Undo.
    final deleteFuture = period.delete();
    deleteFuture.then((_) async {
      try {
        await _repo.rescheduleReminder();
      } catch (_) {
        // Intentionally ignored — fire-and-forget
      }
    });

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted $dateStr.'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        persist: false,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            final restored = Period(startedDate: period.startedDate)
              ..trackingMode = period.trackingMode
              ..manualCycleLength = period.manualCycleLength
              ..reminderDaysBefore = period.reminderDaysBefore;
            Hive.box<Period>(PeriodRepository.boxName).add(restored);
            _repo.rescheduleReminder().catchError((_) {});
            if (!mounted) return;
            setState(() => _entries = _repo.history());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('History', style: TextStyle(color: Color(0xFFE68192))),
        actions: [
          TextButton(
            onPressed: _onAddPastPeriod,
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
            child: const Text('+',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300)),
          ),
        ],
      ),
      body: SafeArea(
        child: _entries.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final period = _entries[index];
                  return Dismissible(
                    key: ValueKey(period),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red.shade400,
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                    onDismissed: (_) => _onDeletePeriod(period),
                    child: PeriodRow(
                      period: period,
                      dateFormat: _repo.dateFormat,
                      onTap: () => _onEditPeriod(period),
                    ),
                  );
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
