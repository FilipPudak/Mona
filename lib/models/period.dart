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

  /// Days elapsed since [startedDate] toward the next period.
  /// `0` = day 1 of the cycle. `-1` means the record is pending / not yet
  /// counted. Unused by the UI in v1; day X is computed at read time.
  @HiveField(1)
  int currentDayCounter = -1;

  Period({required this.startedDate});
}
