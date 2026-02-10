import 'package:hive/hive.dart';

part 'run.g.dart';

@HiveType(typeId: 1)
class Run extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String oderId;

  @HiveField(2)
  int distance; // in meters

  @HiveField(3)
  int duration; // in seconds

  @HiveField(4)
  double avgPace; // minutes per km

  @HiveField(5)
  List<RunPoint> route;

  @HiveField(6)
  int xpEarned;

  @HiveField(7)
  List<String> poisVisited;

  @HiveField(8)
  List<String> achievementsUnlocked;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  bool isSynced;

  Run({
    required this.id,
    required this.oderId,
    this.distance = 0,
    this.duration = 0,
    this.avgPace = 0,
    this.route = const [],
    this.xpEarned = 0,
    this.poisVisited = const [],
    this.achievementsUnlocked = const [],
    required this.createdAt,
    this.isSynced = false,
  });

  // Distance in km
  double get distanceKm => distance / 1000;

  // Formatted duration (mm:ss or hh:mm:ss)
  String get formattedDuration {
    int hours = duration ~/ 3600;
    int minutes = (duration % 3600) ~/ 60;
    int seconds = duration % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Formatted pace (m:ss /km)
  String get formattedPace {
    if (avgPace <= 0) return '--:--';
    int minutes = avgPace.floor();
    int seconds = ((avgPace - minutes) * 60).round();
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }
}

@HiveType(typeId: 2)
class RunPoint {
  @HiveField(0)
  double latitude;

  @HiveField(1)
  double longitude;

  @HiveField(2)
  DateTime timestamp;

  RunPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}
