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

  void _setTrackingMode(String mode) {
    _repo.setTrackingMode(mode);
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
        onSelected: (v) {
          _repo.setManualCycleLength(v);
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
        onSelected: (v) {
          _repo.setReminderDaysBefore(v);
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _toggleNotifications(bool on) {
    setState(() => _notificationsOn = on);
    if (on) {
      _repo.rescheduleReminder();
    } else {
      NotificationService.instance.cancelReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackingMode = _repo.trackingMode;
    final manualLength = _repo.manualCycleLength;
    final reminderDays = _repo.reminderDaysBefore;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Settings', style: TextStyle(color: Color(0xFFE68192))),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Tracking mode'),
          RadioGroup<String>(
            groupValue: trackingMode,
            onChanged: (v) {
              if (v != null) _setTrackingMode(v);
            },
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
          if (trackingMode == 'manual')
            ListTile(
              contentPadding:
                  const EdgeInsetsDirectional.only(start: 72, end: 16),
              title: const Text('Cycle length'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$manualLength days',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: _showCycleLengthPicker,
            ),
          const Divider(height: 1),
          const _SectionHeader(title: 'Reminder'),
          ListTile(
            title: Text('Days before',
                style: TextStyle(
                  color: _notificationsOn ? null : Colors.grey,
                )),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$reminderDays day${reminderDays == 1 ? '' : 's'} before',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _notificationsOn ? null : Colors.grey,
                        )),
                if (_notificationsOn) const Icon(Icons.chevron_right),
              ],
            ),
            onTap: _notificationsOn ? _showReminderPicker : null,
          ),
          SwitchListTile(
            title: const Text('Notification'),
            value: _notificationsOn,
            onChanged: _toggleNotifications,
          ),
          const Divider(height: 1),
          const _SectionHeader(title: 'Date format'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'EU', label: Text('DD/MM')),
                ButtonSegment(value: 'US', label: Text('MM/DD')),
              ],
              selected: {_repo.dateFormat},
              onSelectionChanged: (Set<String> selection) {
                _repo.setDateFormat(selection.first);
                setState(() {});
              },
            ),
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
