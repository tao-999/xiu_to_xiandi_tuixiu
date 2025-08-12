// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gongfa.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GongfaAdapter extends TypeAdapter<Gongfa> {
  @override
  final int typeId = 14;

  @override
  Gongfa read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Gongfa(
      id: fields[0] as String,
      name: fields[1] as String,
      level: fields[2] as int,
      type: fields[3] as GongfaType,
      description: fields[4] as String,
      atkBoost: fields[5] as double,
      defBoost: fields[6] as double,
      hpBoost: fields[7] as double,
      iconPath: fields[8] as String,
      isLearned: fields[9] as bool,
      acquiredAt: fields[10] as DateTime?,
      count: fields[11] as int,
      moveSpeedBoost: fields[12] as double,
      attackSpeed: fields[13] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Gongfa obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.level)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.atkBoost)
      ..writeByte(6)
      ..write(obj.defBoost)
      ..writeByte(7)
      ..write(obj.hpBoost)
      ..writeByte(8)
      ..write(obj.iconPath)
      ..writeByte(9)
      ..write(obj.isLearned)
      ..writeByte(10)
      ..write(obj.acquiredAt)
      ..writeByte(11)
      ..write(obj.count)
      ..writeByte(12)
      ..write(obj.moveSpeedBoost)
      ..writeByte(13)
      ..write(obj.attackSpeed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GongfaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GongfaTypeAdapter extends TypeAdapter<GongfaType> {
  @override
  final int typeId = 15;

  @override
  GongfaType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GongfaType.attack;
      case 1:
        return GongfaType.defense;
      case 2:
        return GongfaType.movement;
      case 3:
        return GongfaType.support;
      case 4:
        return GongfaType.special;
      case 5:
        return GongfaType.passive;
      default:
        return GongfaType.attack;
    }
  }

  @override
  void write(BinaryWriter writer, GongfaType obj) {
    switch (obj) {
      case GongfaType.attack:
        writer.writeByte(0);
        break;
      case GongfaType.defense:
        writer.writeByte(1);
        break;
      case GongfaType.movement:
        writer.writeByte(2);
        break;
      case GongfaType.support:
        writer.writeByte(3);
        break;
      case GongfaType.special:
        writer.writeByte(4);
        break;
      case GongfaType.passive:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GongfaTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
