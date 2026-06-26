// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PeriodAdapter extends TypeAdapter<Period> {
  @override
  final int typeId = 0;

  @override
  Period read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Period(
      startedDate: fields[0] as DateTime,
    )
      ..trackingMode = fields[2] == null ? 'automatic' : fields[2] as String
      ..manualCycleLength = fields[3] == null ? 28 : fields[3] as int
      ..reminderDaysBefore = fields[4] == null ? 2 : fields[4] as int;
  }

  @override
  void write(BinaryWriter writer, Period obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.startedDate)
      ..writeByte(2)
      ..write(obj.trackingMode)
      ..writeByte(3)
      ..write(obj.manualCycleLength)
      ..writeByte(4)
      ..write(obj.reminderDaysBefore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
