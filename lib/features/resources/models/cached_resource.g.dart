// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_resource.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedResourceAdapter extends TypeAdapter<CachedResource> {
  @override
  final int typeId = 1;

  @override
  CachedResource read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedResource(
      id: fields[0] as String,
      fileName: fields[1] as String,
      localPath: fields[2] as String,
      subject: fields[3] as String,
      semester: fields[4] as String,
      uploaderName: fields[5] as String,
      downloadedAt: fields[6] as DateTime,
      fileType: fields[7] as String,
      remoteUpdatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedResource obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fileName)
      ..writeByte(2)
      ..write(obj.localPath)
      ..writeByte(3)
      ..write(obj.subject)
      ..writeByte(4)
      ..write(obj.semester)
      ..writeByte(5)
      ..write(obj.uploaderName)
      ..writeByte(6)
      ..write(obj.downloadedAt)
      ..writeByte(7)
      ..write(obj.fileType)
      ..writeByte(8)
      ..write(obj.remoteUpdatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedResourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
