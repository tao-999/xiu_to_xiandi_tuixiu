// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dead_boss_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeadBossEntryAdapter extends TypeAdapter<DeadBossEntry> {
  @override
  final int typeId = 17;

  @override
  DeadBossEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeadBossEntry(
      tileKey: fields[0] as String,
      x: fields[1] as double,
      y: fields[2] as double,
      bossType: fields[3] as String,
      width: fields[4] as double,
      height: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, DeadBossEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.tileKey)
      ..writeByte(1)
      ..write(obj.x)
      ..writeByte(2)
      ..write(obj.y)
      ..writeByte(3)
      ..write(obj.bossType)
      ..writeByte(4)
      ..write(obj.width)
      ..writeByte(5)
      ..write(obj.height);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeadBossEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
