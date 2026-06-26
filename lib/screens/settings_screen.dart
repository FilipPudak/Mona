import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/period.dart';
import '../services/notification_service.dart';
import '../services/period_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final PeriodRepository _repo;
  bool _notificationsOn = true;

  @override
  void initState() {
    super.initState();
    _repo = PeriodRepository(Hive.box<Period>(PeriodRepository.boxName));
  }

  Future<void> _setTrackingMode(String mode) async {
    await _repo.setTrackingMode(mode);
    setState(() {});
  }

  Future<void> _showCycleLengthPicker() async {
    final current = _repo.manualCycleLength;
    await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => _NumberPickerSheet(
        title: 'Cycle length',
        currentValue: current,
        min: 21,
        max: 45,
        onSelected: (v) async {
          await _repo.setManualCycleLength(v);
          if (mounted) setState(() {});
        },
      ),
    );
  }

  Future<void> _showReminderPicker() async {
    final current = _repo.reminderDaysBefore;
    await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => _NumberPickerSheet(
        title: 'Reminder',
        currentValue: current,
        min: 1,
        max: 5,
        suffix: (v) => ' day${v == 1 ? '' : 's'} before',
        onSelected: (v) async {
          await _repo.setReminderDaysBefore(v);
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _onInfoTap() {
    final count = _repo.periodCount;
    final eligible = _repo.eligibleForAuto();
    final avg = _repo.averageCycleLength();
    final message = eligible
        ? 'Based on your $count recorded cycle${count == 1 ? '' : 's'}. Average: $avg days.'
        : 'Not enough cycles yet (need at least 4 logged periods).';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleNotifications(bool on) {
    setState(() => _notificationsOn = on);
    if (on) {
      final period = _repo.currentPeriod();
      if (period != null) {
        final nextReminder = PeriodRepository.nextReminderDate(
          period.startedDate,
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
    } else {
      NotificationService.instance.cancelReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackingMode = _repo.trackingMode;
    final isAuto = trackingMode == 'automatic';
    final cycleLength = _repo.currentCycleLength();
    final manualLength = _repo.manualCycleLength;
    final reminderDays = _repo.reminderDaysBefore;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Tracking mode'),
          RadioGroup<String>(
            groupValue: trackingMode,
            onChanged: (v) => v != null ? _setTrackingMode(v) : null,
            child: const Column(
              children: [
                RadioListTile<String>(
                  title: Text('Automatic (learns from cycles)'),
                  value: 'automatic',
                ),
                RadioListTile<String>(
                  title: Text('Manual (fixed length)'),
                  value: 'manual',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const _SectionHeader(title: 'Cycle length'),
          ListTile(
            title: const Text('Cycle length'),
            trailing: isAuto
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$cycleLength days'),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _onInfoTap,
                        child: Icon(Icons.info_outline,
                            size: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$manualLength days'),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
            onTap: isAuto ? null : _showCycleLengthPicker,
          ),
          const Divider(height: 1),
          const _SectionHeader(title: 'Reminder'),
          ListTile(
            title: const Text('Reminder'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$reminderDays day${reminderDays == 1 ? '' : 's'} before'),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: _showReminderPicker,
          ),
          const Divider(height: 1),
          const _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            title: const Text('Notifications'),
            value: _notificationsOn,
            onChanged: _toggleNotifications,
          ),
          const Divider(height: 1),
          const _SectionHeader(title: 'Privacy'),
          const ListTile(
            title: Text('Your data stays on this device.'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _NumberPickerSheet extends StatefulWidget {
  const _NumberPickerSheet({
    required this.title,
    required this.currentValue,
    required this.min,
    required this.max,
    this.suffix,
    required this.onSelected,
  });

  final String title;
  final int currentValue;
  final int min;
  final int max;
  final String Function(int value)? suffix;
  final ValueChanged<int> onSelected;

  @override
  State<_NumberPickerSheet> createState() => _NumberPickerSheetState();
}

class _NumberPickerSheetState extends State<_NumberPickerSheet> {
  late int _selectedValue;
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.currentValue;
    _controller = FixedExtentScrollController(
      initialItem: widget.currentValue - widget.min,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.max - widget.min + 1;
    return SizedBox(
      height: 260,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                Text(
                  widget.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () {
                    widget.onSelected(_selectedValue);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListWheelScrollView(
              controller: _controller,
              itemExtent: 44,
              diameterRatio: 1.5,
              onSelectedItemChanged: (index) {
                setState(() => _selectedValue = widget.min + index);
              },
              children: List.generate(count, (index) {
                final value = widget.min + index;
                final isSelected = value == _selectedValue;
                return Center(
                  child: Text(
                    '$value${widget.suffix != null ? widget.suffix!(value) : ''}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.black : Colors.grey,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
