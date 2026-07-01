import 'package:hive/hive.dart';

part 'period.g.dart';

/// A single recorded period start.
///
/// Only the most recent record is used at runtime in v1. Older records are
/// kept in the Hive box for future averaging features.
@HiveType(typeId: 0)
class Period extends HiveObject {
  @HiveField(0)
  DateTime startedDate;

  @HiveField(2, defaultValue: 'automatic')
  String trackingMode = 'automatic';

  @HiveField(3, defaultValue: 28)
  int manualCycleLength = 28;

  @HiveField(4, defaultValue: 2)
  int reminderDaysBefore = 2;

  @HiveField(5, defaultValue: 'EU')
  String dateFormat = 'EU';

  Period({required DateTime startedDate})
      : startedDate = startedDate.hour == 0 && startedDate.minute == 0
            ? DateTime.utc(startedDate.year, startedDate.month, startedDate.day)
            : startedDate.toUtc();
}
