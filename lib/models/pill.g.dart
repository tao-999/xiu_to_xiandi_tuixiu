// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pill.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PillAdapter extends TypeAdapter<Pill> {
  @override
  final int typeId = 2;

  @override
  Pill read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Pill(
      name: fields[0] as String,
      level: fields[1] as int,
      type: fields[2] as PillType,
      count: fields[3] as int,
      bonusAmount: fields[4] as int,
      createdAt: fields[5] as DateTime,
      iconPath: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Pill obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.count)
      ..writeByte(4)
      ..write(obj.bonusAmount)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.iconPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PillAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PillTypeAdapter extends TypeAdapter<PillType> {
  @override
  final int typeId = 10;

  @override
  PillType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PillType.attack;
      case 1:
        return PillType.defense;
      case 2:
        return PillType.health;
      default:
        return PillType.attack;
    }
  }

  @override
  void write(BinaryWriter writer, PillType obj) {
    switch (obj) {
      case PillType.attack:
        writer.writeByte(0);
        break;
      case PillType.defense:
        writer.writeByte(1);
        break;
      case PillType.health:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PillTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
