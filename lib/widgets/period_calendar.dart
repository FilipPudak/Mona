import 'package:flutter/material.dart';

class PeriodCalendar extends StatefulWidget {
  const PeriodCalendar({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.loggedDates = const {},
    this.selectedDate,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final Set<DateTime> loggedDates;
  final DateTime? selectedDate;

  static Future<DateTime?> show(BuildContext context, {
    required DateTime firstDate,
    required DateTime lastDate,
    Set<DateTime> loggedDates = const {},
    DateTime? selectedDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PeriodCalendar(
        firstDate: firstDate,
        lastDate: lastDate,
        loggedDates: loggedDates,
        selectedDate: selectedDate,
      ),
    );
  }

  @override
  State<PeriodCalendar> createState() => _PeriodCalendarState();
}

class _PeriodCalendarState extends State<PeriodCalendar> {
  late DateTime _viewMonth;
  DateTime? _selected;
  late DateTime _today;

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> _shortWeekdays = [
    'M', 'T', 'W', 'T', 'F', 'S', 'S',
  ];

  @override
  void initState() {
    super.initState();
    _today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _selected = widget.selectedDate;
    _viewMonth = widget.selectedDate ?? _today;
  }

  bool _isDisabled(DateTime date) {
    if (date.isAfter(widget.lastDate)) return true;
    if (date.isAtSameMomentAs(_today) || date.isAfter(_today)) return true;
    return false;
  }

  bool _isLogged(DateTime date) {
    return widget.loggedDates.any((d) =>
      d.year == date.year && d.month == date.month && d.day == date.day);
  }

  void _prevMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_viewMonth.year, _viewMonth.month, 1).weekday;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Log a past period',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: _prevMonth,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('<', style: TextStyle(color: Colors.black54, fontSize: 18)),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${_months[_viewMonth.month - 1]} ${_viewMonth.year}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _nextMonth,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('>', style: TextStyle(color: Colors.black54, fontSize: 18)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: _shortWeekdays.map((d) => Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              )).toList(),
            ),
            const SizedBox(height: 4),
            ...List.generate(
              ((daysInMonth + firstWeekday - 1) / 7).ceil(),
              (weekIndex) {
                return Row(
                  children: List.generate(7, (weekdayIndex) {
                    final day = weekIndex * 7 + weekdayIndex - firstWeekday + 2;
                    if (day < 1 || day > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 40));
                    }
                    final date = DateTime(_viewMonth.year, _viewMonth.month, day);
                    final disabled = _isDisabled(date);
                    final logged = _isLogged(date);
                    final selected = _selected != null &&
                        _selected!.year == date.year &&
                        _selected!.month == date.month &&
                        _selected!.day == date.day;
                    final today = date.isAtSameMomentAs(_today);

                    return Expanded(
                      child: GestureDetector(
                        onTap: disabled
                            ? null
                            : () {
                                if (logged && (widget.selectedDate == null ||
                                    !(widget.selectedDate!.year == date.year &&
                                      widget.selectedDate!.month == date.month &&
                                      widget.selectedDate!.day == date.day))) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Already logged on ${_months[date.month - 1]} $day.'),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _selected = date);
                              },
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: selected
                              ? const BoxDecoration(
                                  color: Colors.purple,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : disabled
                                          ? Colors.black26
                                          : Colors.black87,
                                  fontSize: 14,
                                  fontWeight: today && !selected ? FontWeight.w600 : null,
                                ),
                              ),
                              if (logged)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    color: selected ? Colors.white : Colors.purple,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else
                                const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black54,
                      side: const BorderSide(color: Colors.black12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.of(context).pop(_selected),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.black12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _selected == null
                          ? 'Select a date'
                          : 'Log ${_months[_selected!.month - 1]} ${_selected!.day}',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
