import 'package:flutter/material.dart';

class PeriodListPicker extends StatefulWidget {
  const PeriodListPicker({
    super.key,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime firstDate;
  final DateTime lastDate;

  static Future<DateTime?> show(BuildContext context, {
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      builder: (_) => PeriodListPicker(
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }

  @override
  State<PeriodListPicker> createState() => _PeriodListPickerState();
}

class _PeriodListPickerState extends State<PeriodListPicker> {
  late List<DateTime> _dates;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final days = widget.lastDate.difference(widget.firstDate).inDays;
    _dates = List.generate(days + 1, (i) => widget.lastDate.subtract(Duration(days: i)));
    _selected = widget.lastDate;
  }

  String _label(DateTime date) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final diff = today.difference(DateTime(date.year, date.month, date.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _dateString(DateTime d) {
    return '${_months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Period started on?',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _dates.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFEAECEF)),
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  final selected = date == _selected;
                  return InkWell(
                    onTap: () => setState(() => _selected = date),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Colors.purple
                                    : const Color(0xFFCCCCCC),
                                width: selected ? 6 : 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _label(date),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _dateString(date),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Log Period'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
