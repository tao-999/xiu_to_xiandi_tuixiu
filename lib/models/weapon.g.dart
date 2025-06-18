// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weapon.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeaponAdapter extends TypeAdapter<Weapon> {
  @override
  final int typeId = 7;

  @override
  Weapon read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Weapon(
      name: fields[0] as String,
      level: fields[1] as int,
      type: fields[2] as String,
      createdAt: fields[3] as DateTime,
      attackBoost: fields[4] as int,
      defenseBoost: fields[5] as int,
      hpBoost: fields[6] as int,
      specialEffects: (fields[7] as List).cast<String>(),
      iconPath: fields[8] as String,
      equippedById: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Weapon obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.attackBoost)
      ..writeByte(5)
      ..write(obj.defenseBoost)
      ..writeByte(6)
      ..write(obj.hpBoost)
      ..writeByte(7)
      ..write(obj.specialEffects)
      ..writeByte(8)
      ..write(obj.iconPath)
      ..writeByte(9)
      ..write(obj.equippedById);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeaponAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
