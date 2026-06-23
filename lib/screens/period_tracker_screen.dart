import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/period.dart';
import '../services/notification_service.dart';
import '../services/period_repository.dart';
import '../widgets/day_counter.dart';
import '../widgets/period_list_picker.dart';
import 'history_screen.dart';

class PeriodTrackerScreen extends StatefulWidget {
  const PeriodTrackerScreen({super.key});

  @override
  State<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends State<PeriodTrackerScreen> {
  late final PeriodRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = PeriodRepository(Hive.box<Period>(PeriodRepository.boxName));
  }

  Future<void> _onLogPeriod() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final current = _repo.currentPeriod();
      final firstDate = current != null
          ? current.startedDate.add(const Duration(days: 1))
          : DateTime.now().subtract(const Duration(days: 27));
      final lastDate = DateTime.now();

      final picked = await PeriodListPicker.show(
        context,
        firstDate: firstDate,
        lastDate: lastDate,
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

      final nextReminder = PeriodRepository.nextReminderDate(picked);
      if (!nextReminder.isBefore(DateTime.now())) {
        await NotificationService.instance.scheduleReminder(nextReminder);
      }

      if (!mounted) return;
      setState(() {});
      messenger.showSnackBar(
        SnackBar(
          content: Text('Logged period for ${picked.toLocal().toString().split(' ').first}.'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          persist: false,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await saved.delete();
              if (mounted) setState(() {});
            },
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('PeriodTracker: log failed: $e\n$st');
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not log period: $e'),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final period = _repo.currentPeriod();
    final today = DateTime.now();
    final day = period == null ? 0 : PeriodRepository.dayOfCycle(period.startedDate, today);
    final daysUntilNext = (28 - day).clamp(0, 28);

    Color dayColor = Colors.black87;
    if (day >= 1 && day <= 6) {
      dayColor = const Color(0xFFE68192);
    } else if (day >= 11 && day <= 17) {
      dayColor = Colors.green;
    }

    String caption;
    if (period == null) {
      caption = 'Tap below when your period starts.';
    } else if (daysUntilNext == 0) {
      caption = 'Period may start today.';
    } else {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      const weekdays = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday',
      ];
      caption = '${weekdays[today.weekday - 1]}, ${today.day} ${months[today.month - 1]}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mona'),
        actions: [
          TextButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HistoryScreen(),
                ),
              );
              if (mounted) setState(() {});
            },
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
            child: const Text('History'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              if (period != null) ...[
                DayCounter(day: day, color: dayColor),
                const SizedBox(height: 16),
              ],
              Text(
                caption,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black54,
                    ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                  child: FilledButton(
                    onPressed: _onLogPeriod,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.black12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'ISOCPEUR',
                      ),
                    ),
                    child: const Text('Start'),
                  ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
