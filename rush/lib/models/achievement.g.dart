// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 3;

  @override
  Achievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Achievement(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      icon: fields[3] as String,
      xpReward: (fields[4] as num).toInt(),
      categoryIndex: (fields[5] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.xpReward)
      ..writeByte(5)
      ..write(obj.categoryIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UnlockedAchievementAdapter extends TypeAdapter<UnlockedAchievement> {
  @override
  final int typeId = 4;

  @override
  UnlockedAchievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnlockedAchievement(
      oderId: fields[0] as String,
      achievementId: fields[1] as String,
      unlockedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UnlockedAchievement obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.oderId)
      ..writeByte(1)
      ..write(obj.achievementId)
      ..writeByte(2)
      ..write(obj.unlockedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnlockedAchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
