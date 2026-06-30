import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/period.dart';
import '../services/notification_service.dart';
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
    _repo = PeriodRepository(Hive.box<Period>(PeriodRepository.boxName));
    _load();
  }

  void _load() {
    setState(() {
      _entries = _repo.history();
    });
  }

  Set<DateTime> _loggedDates() {
    final box = Hive.box<Period>(PeriodRepository.boxName);
    return box.values
        .map((p) => DateTime(
            p.startedDate.year, p.startedDate.month, p.startedDate.day))
        .toSet();
  }

  Future<void> _onAddPastPeriod() async {
    final messenger = ScaffoldMessenger.of(context);
    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final lastDate = DateTime.now().subtract(const Duration(days: 1));

    final picked = await PeriodCalendar.show(
      context,
      firstDate: firstDate,
      lastDate: lastDate,
      loggedDates: _loggedDates(),
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

    final nextReminder = PeriodRepository.nextReminderDate(
      picked,
      cycleLength: _repo.currentCycleLength(),
      reminderDaysBefore: _repo.reminderDaysBefore,
    );
    if (!nextReminder.isBefore(DateTime.now())) {
      await NotificationService.instance.scheduleReminder(
        nextReminder,
        reminderDaysBefore: _repo.reminderDaysBefore,
      );
    }

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

    // Don't count the period being edited as "already logged"
    final logged = _loggedDates();
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
    setState(() {
      final idx = _entries.indexWhere((p) => p.key == period.key);
      if (idx != -1) _entries[idx] = period;
      _entries.sort((a, b) => b.startedDate.compareTo(a.startedDate));
    });

    period.save().then((_) {
      try {
        final current = _repo.currentPeriod();
        if (current != null) {
          final nextReminder = PeriodRepository.nextReminderDate(
            current.startedDate,
            cycleLength: _repo.currentCycleLength(),
            reminderDaysBefore: _repo.reminderDaysBefore,
          );
          if (!nextReminder.isBefore(DateTime.now())) {
            NotificationService.instance.scheduleReminder(
              nextReminder,
              reminderDaysBefore: _repo.reminderDaysBefore,
            );
          }
        }
      } on HiveError {
        // Box was closed
      }
    });

    messenger.showSnackBar(
      SnackBar(
        content:
            Text('Updated to ${picked.toLocal().toString().split(' ').first}.'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onDeletePeriod(Period period) {
    final messenger = ScaffoldMessenger.of(context);
    final dateStr = period.startedDate.toLocal().toString().split(' ').first;

    setState(() => _entries.removeWhere((p) => p.key == period.key));

    period.delete().then((_) {
      try {
        final current = _repo.currentPeriod();
        if (current != null) {
          final nextReminder = PeriodRepository.nextReminderDate(
            current.startedDate,
            cycleLength: _repo.currentCycleLength(),
            reminderDaysBefore: _repo.reminderDaysBefore,
          );
          if (!nextReminder.isBefore(DateTime.now())) {
            NotificationService.instance.scheduleReminder(
              nextReminder,
              reminderDaysBefore: _repo.reminderDaysBefore,
            );
          }
        } else {
          NotificationService.instance.cancelReminder();
        }
      } on HiveError {
        // Box was closed (e.g., during test teardown)
      }
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted $dateStr.'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        persist: false,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            final box = Hive.box<Period>(PeriodRepository.boxName);
            if (box.containsKey(period.key)) {
              setState(() => _entries = _repo.history());
              return;
            }
            final restored = Period(startedDate: period.startedDate)
              ..trackingMode = period.trackingMode
              ..manualCycleLength = period.manualCycleLength
              ..reminderDaysBefore = period.reminderDaysBefore;
            box.add(restored).then((_) {
              try {
                final nextReminder = PeriodRepository.nextReminderDate(
                  restored.startedDate,
                  cycleLength: _repo.currentCycleLength(),
                  reminderDaysBefore: _repo.reminderDaysBefore,
                );
                if (!nextReminder.isBefore(DateTime.now())) {
                  NotificationService.instance.scheduleReminder(
                    nextReminder,
                    reminderDaysBefore: _repo.reminderDaysBefore,
                  );
                }
              } on HiveError {
                // Box was closed
              }
            });
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
        title: const Text('History'),
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
