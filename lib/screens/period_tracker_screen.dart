import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/period.dart';
import '../services/notification_service.dart';
import '../services/period_repository.dart';
import '../widgets/day_counter.dart';
import '../widgets/period_list_picker.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class PeriodTrackerScreen extends StatefulWidget {
  const PeriodTrackerScreen({super.key});

  @override
  State<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends State<PeriodTrackerScreen>
    with SingleTickerProviderStateMixin {
  late final PeriodRepository _repo;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _repo = PeriodRepository(Hive.box<Period>(PeriodRepository.boxName));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _updatePulse(bool overdue) {
    if (overdue && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!overdue && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
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
      setState(() {});
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
    final cycleLength = _repo.currentCycleLength();
    final day = period == null
        ? 0
        : PeriodRepository.dayOfCycle(period.startedDate, today);
    final dayLabel = period == null ? null : (day >= 99 ? '99+' : '$day');

    final dayColor = period == null
        ? Colors.black87
        : PeriodRepository.phaseColor(day, cycleLength);

    final bool overdue = period != null &&
        PeriodRepository.isOverdue(period.startedDate, today, cycleLength);
    _updatePulse(period == null || overdue);
    final Color effectiveDayColor = overdue && dayColor == Colors.black87
        ? dayColor.withValues(alpha: 0.38)
        : dayColor;

    String? expectedDate;
    if (period != null) {
      final dueDate = DateTime(
        period.startedDate.year,
        period.startedDate.month,
        period.startedDate.day,
      ).add(Duration(days: cycleLength));
      final dd = dueDate.day.toString().padLeft(2, '0');
      final mm = dueDate.month.toString().padLeft(2, '0');
      expectedDate = _repo.dateFormat == 'EU' ? '$dd/$mm' : '$mm/$dd';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mona', style: TextStyle(color: Color(0xFFE68192))),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HistoryScreen(),
                ),
              );
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double buttonSize = 56;
              const double bottomPadding = 32;
              final buttonTopCentered =
                  (constraints.maxHeight - buttonSize) / 2;
              final buttonTopBottom =
                  constraints.maxHeight - buttonSize - bottomPadding;

              return Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (period != null) ...[
                          DayCounter(
                              label: dayLabel!, color: effectiveDayColor),
                          const SizedBox(height: 8),
                          Opacity(
                            key: const Key('expected_date_opacity'),
                            opacity: overdue ? 0.38 : 1.0,
                            child: Text(
                              expectedDate!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: Colors.black54),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: (constraints.maxWidth - buttonSize) / 2,
                    width: buttonSize,
                    height: buttonSize,
                    top: period != null ? buttonTopBottom : buttonTopCentered,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      ),
                      child: SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: FloatingActionButton(
                          onPressed: _onLogPeriod,
                          backgroundColor: const Color(0xFFE68192),
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          child: const Icon(Icons.add),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
