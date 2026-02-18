// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MissionAdapter extends TypeAdapter<Mission> {
  @override
  final int typeId = 7;

  @override
  Mission read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Mission(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      typeIndex: (fields[3] as num).toInt(),
      goalTypeIndex: (fields[4] as num).toInt(),
      goalValue: (fields[5] as num).toInt(),
      xpReward: (fields[6] as num).toInt(),
      icon: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Mission obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.typeIndex)
      ..writeByte(4)
      ..write(obj.goalTypeIndex)
      ..writeByte(5)
      ..write(obj.goalValue)
      ..writeByte(6)
      ..write(obj.xpReward)
      ..writeByte(7)
      ..write(obj.icon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActiveMissionAdapter extends TypeAdapter<ActiveMission> {
  @override
  final int typeId = 8;

  @override
  ActiveMission read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActiveMission(
      oderId: fields[0] as String,
      missionId: fields[1] as String,
      currentProgress: (fields[2] as num).toInt(),
      isCompleted: fields[3] as bool,
      assignedAt: fields[4] as DateTime,
      completedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ActiveMission obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.oderId)
      ..writeByte(1)
      ..write(obj.missionId)
      ..writeByte(2)
      ..write(obj.currentProgress)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.assignedAt)
      ..writeByte(5)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveMissionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
