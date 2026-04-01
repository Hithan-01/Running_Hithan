// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String,
      name: fields[1] as String,
      faculty: fields[2] as String?,
      semester: (fields[3] as num?)?.toInt(),
      xp: (fields[4] as num).toInt(),
      level: (fields[5] as num).toInt(),
      totalDistance: (fields[6] as num).toInt(),
      totalRuns: (fields[7] as num).toInt(),
      totalTime: (fields[8] as num).toInt(),
      currentStreak: (fields[9] as num).toInt(),
      bestStreak: (fields[10] as num).toInt(),
      createdAt: fields[11] as DateTime,
      lastRunAt: fields[12] as DateTime?,
      photoPath: fields[13] as String?,
      equippedTitleId: fields[14] as String?,
      coins: (fields[15] as num?)?.toInt() ?? 0,
      equippedAvatarColorId: fields[16] as String?,
      equippedAvatarFrameId: fields[17] as String?,
      equippedRouteColorId: fields[18] as String?,
      purchasedItemIds: (fields[19] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.faculty)
      ..writeByte(3)
      ..write(obj.semester)
      ..writeByte(4)
      ..write(obj.xp)
      ..writeByte(5)
      ..write(obj.level)
      ..writeByte(6)
      ..write(obj.totalDistance)
      ..writeByte(7)
      ..write(obj.totalRuns)
      ..writeByte(8)
      ..write(obj.totalTime)
      ..writeByte(9)
      ..write(obj.currentStreak)
      ..writeByte(10)
      ..write(obj.bestStreak)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.lastRunAt)
      ..writeByte(13)
      ..write(obj.photoPath)
      ..writeByte(14)
      ..write(obj.equippedTitleId)
      ..writeByte(15)
      ..write(obj.coins)
      ..writeByte(16)
      ..write(obj.equippedAvatarColorId)
      ..writeByte(17)
      ..write(obj.equippedAvatarFrameId)
      ..writeByte(18)
      ..write(obj.equippedRouteColorId)
      ..writeByte(19)
      ..write(obj.purchasedItemIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
