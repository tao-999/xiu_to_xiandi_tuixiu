// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disciple.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DiscipleAdapter extends TypeAdapter<Disciple> {
  @override
  final int typeId = 1;

  @override
  Disciple read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Disciple(
      id: fields[0] as String,
      name: fields[1] as String,
      gender: fields[2] as String,
      age: fields[3] as int,
      aptitude: fields[4] as int,
      hp: fields[5] as int,
      atk: fields[6] as int,
      def: fields[7] as int,
      loyalty: fields[8] as int,
      specialty: fields[9] as String,
      talents: (fields[10] as List).cast<String>(),
      lifespan: fields[11] as int,
      cultivation: fields[12] as int,
      breakthroughChance: fields[13] as int,
      skills: (fields[14] as List).cast<String>(),
      fatigue: fields[15] as int,
      isOnMission: fields[16] as bool,
      missionEndTimestamp: fields[17] as int?,
      imagePath: fields[18] as String,
      joinedAt: fields[19] as int?,
      assignedRoom: fields[20] as String?,
      description: fields[21] as String,
      favorability: fields[22] as int,
      role: fields[23] as String?,
      extraHp: fields[24] as double,
      extraAtk: fields[25] as double,
      extraDef: fields[26] as double,
      realmLevel: fields[27] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Disciple obj) {
    writer
      ..writeByte(28)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.gender)
      ..writeByte(3)
      ..write(obj.age)
      ..writeByte(4)
      ..write(obj.aptitude)
      ..writeByte(5)
      ..write(obj.hp)
      ..writeByte(6)
      ..write(obj.atk)
      ..writeByte(7)
      ..write(obj.def)
      ..writeByte(8)
      ..write(obj.loyalty)
      ..writeByte(9)
      ..write(obj.specialty)
      ..writeByte(10)
      ..write(obj.talents)
      ..writeByte(11)
      ..write(obj.lifespan)
      ..writeByte(12)
      ..write(obj.cultivation)
      ..writeByte(13)
      ..write(obj.breakthroughChance)
      ..writeByte(14)
      ..write(obj.skills)
      ..writeByte(15)
      ..write(obj.fatigue)
      ..writeByte(16)
      ..write(obj.isOnMission)
      ..writeByte(17)
      ..write(obj.missionEndTimestamp)
      ..writeByte(18)
      ..write(obj.imagePath)
      ..writeByte(19)
      ..write(obj.joinedAt)
      ..writeByte(20)
      ..write(obj.assignedRoom)
      ..writeByte(21)
      ..write(obj.description)
      ..writeByte(22)
      ..write(obj.favorability)
      ..writeByte(23)
      ..write(obj.role)
      ..writeByte(24)
      ..write(obj.extraHp)
      ..writeByte(25)
      ..write(obj.extraAtk)
      ..writeByte(26)
      ..write(obj.extraDef)
      ..writeByte(27)
      ..write(obj.realmLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscipleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
