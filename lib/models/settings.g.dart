// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 1;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings(
      trackingMode: fields[0] == null ? 'automatic' : fields[0] as String,
      manualCycleLength: fields[1] == null ? 28 : fields[1] as int,
      reminderDaysBefore: fields[2] == null ? 2 : fields[2] as int,
      dateFormat: fields[3] == null ? 'EU' : fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.trackingMode)
      ..writeByte(1)
      ..write(obj.manualCycleLength)
      ..writeByte(2)
      ..write(obj.reminderDaysBefore)
      ..writeByte(3)
      ..write(obj.dateFormat);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
