import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 1)
class Settings extends HiveObject {
  @HiveField(0, defaultValue: 'automatic')
  String trackingMode;

  @HiveField(1, defaultValue: 28)
  int manualCycleLength;

  @HiveField(2, defaultValue: 2)
  int reminderDaysBefore;

  @HiveField(3, defaultValue: 'EU')
  String dateFormat;

  Settings({
    this.trackingMode = 'automatic',
    this.manualCycleLength = 28,
    this.reminderDaysBefore = 2,
    this.dateFormat = 'EU',
  });
}
