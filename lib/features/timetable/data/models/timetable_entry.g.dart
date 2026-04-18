// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimetableEntryAdapter extends TypeAdapter<TimetableEntry> {
  @override
  final int typeId = 0;

  @override
  TimetableEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimetableEntry(
      id: fields[0] as String,
      subjectName: fields[1] as String,
      subjectCode: fields[2] as String,
      weekday: fields[3] as int,
      startTime: fields[4] as String,
      endTime: fields[5] as String,
      room: fields[6] as String,
      professorName: fields[7] as String,
      batch: fields[8] as String,
      userId: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TimetableEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectName)
      ..writeByte(2)
      ..write(obj.subjectCode)
      ..writeByte(3)
      ..write(obj.weekday)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.room)
      ..writeByte(7)
      ..write(obj.professorName)
      ..writeByte(8)
      ..write(obj.batch)
      ..writeByte(9)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
