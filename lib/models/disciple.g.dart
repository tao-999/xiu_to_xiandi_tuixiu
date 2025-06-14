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
      realm: fields[8] as String,
      loyalty: fields[9] as int,
      specialty: fields[10] as String,
      talents: (fields[11] as List).cast<String>(),
      lifespan: fields[12] as int,
      cultivation: fields[13] as int,
      breakthroughChance: fields[14] as int,
      skills: (fields[15] as List).cast<String>(),
      fatigue: fields[16] as int,
      isOnMission: fields[17] as bool,
      missionEndTimestamp: fields[18] as int?,
      imagePath: fields[19] as String,
      joinedAt: fields[20] as int?,
      assignedRoom: fields[21] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Disciple obj) {
    writer
      ..writeByte(22)
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
      ..write(obj.realm)
      ..writeByte(9)
      ..write(obj.loyalty)
      ..writeByte(10)
      ..write(obj.specialty)
      ..writeByte(11)
      ..write(obj.talents)
      ..writeByte(12)
      ..write(obj.lifespan)
      ..writeByte(13)
      ..write(obj.cultivation)
      ..writeByte(14)
      ..write(obj.breakthroughChance)
      ..writeByte(15)
      ..write(obj.skills)
      ..writeByte(16)
      ..write(obj.fatigue)
      ..writeByte(17)
      ..write(obj.isOnMission)
      ..writeByte(18)
      ..write(obj.missionEndTimestamp)
      ..writeByte(19)
      ..write(obj.imagePath)
      ..writeByte(20)
      ..write(obj.joinedAt)
      ..writeByte(21)
      ..write(obj.assignedRoom);
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
