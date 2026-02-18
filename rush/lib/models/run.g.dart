// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RunAdapter extends TypeAdapter<Run> {
  @override
  final int typeId = 1;

  @override
  Run read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Run(
      id: fields[0] as String,
      oderId: fields[1] as String,
      distance: (fields[2] as num).toInt(),
      duration: (fields[3] as num).toInt(),
      avgPace: (fields[4] as num).toDouble(),
      route: (fields[5] as List).cast<RunPoint>(),
      xpEarned: (fields[6] as num).toInt(),
      poisVisited: (fields[7] as List).cast<String>(),
      achievementsUnlocked: (fields[8] as List).cast<String>(),
      createdAt: fields[9] as DateTime,
      isSynced: fields[10] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Run obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.oderId)
      ..writeByte(2)
      ..write(obj.distance)
      ..writeByte(3)
      ..write(obj.duration)
      ..writeByte(4)
      ..write(obj.avgPace)
      ..writeByte(5)
      ..write(obj.route)
      ..writeByte(6)
      ..write(obj.xpEarned)
      ..writeByte(7)
      ..write(obj.poisVisited)
      ..writeByte(8)
      ..write(obj.achievementsUnlocked)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RunPointAdapter extends TypeAdapter<RunPoint> {
  @override
  final int typeId = 2;

  @override
  RunPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RunPoint(
      latitude: (fields[0] as num).toDouble(),
      longitude: (fields[1] as num).toDouble(),
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RunPoint obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
