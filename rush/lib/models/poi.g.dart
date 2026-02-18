// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poi.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PoiAdapter extends TypeAdapter<Poi> {
  @override
  final int typeId = 5;

  @override
  Poi read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Poi(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      latitude: (fields[3] as num).toDouble(),
      longitude: (fields[4] as num).toDouble(),
      categoryIndex: (fields[5] as num).toInt(),
      xpReward: (fields[6] as num).toInt(),
      icon: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Poi obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.categoryIndex)
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
      other is PoiAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VisitedPoiAdapter extends TypeAdapter<VisitedPoi> {
  @override
  final int typeId = 6;

  @override
  VisitedPoi read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VisitedPoi(
      oderId: fields[0] as String,
      poiId: fields[1] as String,
      visitedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, VisitedPoi obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.oderId)
      ..writeByte(1)
      ..write(obj.poiId)
      ..writeByte(2)
      ..write(obj.visitedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitedPoiAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
