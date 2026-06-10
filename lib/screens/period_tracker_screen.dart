import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/period.dart';
import '../services/notification_service.dart';
import '../services/period_repository.dart';
import '../widgets/day_counter.dart';

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

  Future<void> _onPeriodStartedToday() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final today = DateTime.now();
      final saved = await _repo.recordPeriodStart(today);
      debugPrint('PeriodTracker: recorded ${saved.startedDate}');
      await NotificationService.instance
          .scheduleReminder(PeriodRepository.nextReminderDate(today));
      debugPrint('PeriodTracker: reminder scheduled');
      if (!mounted) return;
      setState(() {});
      messenger.showSnackBar(
        SnackBar(
          content: Text('Logged period for ${saved.startedDate.toLocal().toString().split(' ').first}.'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, st) {
      debugPrint('PeriodTracker: tap failed: $e\n$st');
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
    final day = period == null ? 1 : PeriodRepository.dayOfCycle(period.startedDate, today);
    final daysUntilNext = (28 - day).clamp(0, 28);

    String caption;
    if (period == null) {
      caption = 'Tap below when your period starts.';
    } else if (daysUntilNext == 0) {
      caption = 'Period may start today.';
    } else {
      caption = 'Next period in $daysUntilNext ${daysUntilNext == 1 ? "day" : "days"}.';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('MengaCloud')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              DayCounter(day: day),
              const SizedBox(height: 16),
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
                  onPressed: _onPeriodStartedToday,
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
                    ),
                  ),
                  child: const Text('Period Started Today'),
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
