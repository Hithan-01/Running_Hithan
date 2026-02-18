import 'package:hive_ce/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? faculty;

  @HiveField(3)
  int? semester;

  @HiveField(4)
  int xp;

  @HiveField(5)
  int level;

  @HiveField(6)
  int totalDistance; // in meters

  @HiveField(7)
  int totalRuns;

  @HiveField(8)
  int totalTime; // in seconds

  @HiveField(9)
  int currentStreak; // consecutive days

  @HiveField(10)
  int bestStreak;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime? lastRunAt;

  User({
    required this.id,
    required this.name,
    this.faculty,
    this.semester,
    this.xp = 0,
    this.level = 1,
    this.totalDistance = 0,
    this.totalRuns = 0,
    this.totalTime = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    required this.createdAt,
    this.lastRunAt,
  });

  // XP needed for each level
  static const List<int> levelThresholds = [
    0,      // Level 1: Rookie Runner
    500,    // Level 2: Campus Jogger
    1500,   // Level 3: Fitness Explorer
    3500,   // Level 4: Trail Master
    7000,   // Level 5: UM Athlete
    15000,  // Level 6: Campus Legend
  ];

  static const List<String> levelNames = [
    'Rookie Runner',
    'Campus Jogger',
    'Fitness Explorer',
    'Trail Master',
    'UM Athlete',
    'Campus Legend',
  ];

  String get levelName => levelNames[level - 1];

  int get xpForCurrentLevel => level > 1 ? levelThresholds[level - 1] : 0;

  int get xpForNextLevel =>
      level < levelThresholds.length ? levelThresholds[level] : levelThresholds.last;

  double get levelProgress {
    if (level >= levelThresholds.length) return 1.0;
    int currentLevelXp = xp - xpForCurrentLevel;
    int xpNeeded = xpForNextLevel - xpForCurrentLevel;
    return currentLevelXp / xpNeeded;
  }

  void addXp(int amount) {
    xp += amount;
    while (level < levelThresholds.length && xp >= levelThresholds[level]) {
      level++;
    }
  }
}
