import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/run.dart';
import '../models/achievement.dart';
import '../models/poi.dart';
import '../models/mission.dart';

class DatabaseService {
  static const String userBoxName = 'users';
  static const String runBoxName = 'runs';
  static const String achievementBoxName = 'achievements';
  static const String poiBoxName = 'visited_pois';
  static const String missionBoxName = 'active_missions';

  static late Box<User> _userBox;
  static late Box<Run> _runBox;
  static late Box<UnlockedAchievement> _achievementBox;
  static late Box<VisitedPoi> _poiBox;
  static late Box<ActiveMission> _missionBox;

  // Initialize Hive and open all boxes
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(RunAdapter());
    Hive.registerAdapter(RunPointAdapter());
    Hive.registerAdapter(AchievementAdapter());
    Hive.registerAdapter(UnlockedAchievementAdapter());
    Hive.registerAdapter(PoiAdapter());
    Hive.registerAdapter(VisitedPoiAdapter());
    Hive.registerAdapter(MissionAdapter());
    Hive.registerAdapter(ActiveMissionAdapter());

    // Open boxes
    _userBox = await Hive.openBox<User>(userBoxName);
    _runBox = await Hive.openBox<Run>(runBoxName);
    _achievementBox = await Hive.openBox<UnlockedAchievement>(achievementBoxName);
    _poiBox = await Hive.openBox<VisitedPoi>(poiBoxName);
    _missionBox = await Hive.openBox<ActiveMission>(missionBoxName);

    debugPrint('Database initialized successfully');
  }

  // ============ USER METHODS ============

  static User? getCurrentUser() {
    if (_userBox.isEmpty) return null;
    return _userBox.values.first;
  }

  static Future<User> createUser({
    required String id,
    required String name,
    String? faculty,
    int? semester,
  }) async {
    final user = User(
      id: id,
      name: name,
      faculty: faculty,
      semester: semester,
      createdAt: DateTime.now(),
    );
    await _userBox.put(id, user);
    return user;
  }

  static Future<void> updateUser(User user) async {
    await user.save();
  }

  // ============ RUN METHODS ============

  static List<Run> getAllRuns(String oderId) {
    return _runBox.values
        .where((run) => run.oderId == oderId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<Run> getUnsyncedRuns(String oderId) {
    return _runBox.values
        .where((run) => run.oderId == oderId && !run.isSynced)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Oldest first for sync
  }

  static Future<void> saveRun(Run run) async {
    await _runBox.put(run.id, run);
  }

  static Future<void> markRunAsSynced(String runId) async {
    final run = _runBox.get(runId);
    if (run != null) {
      run.isSynced = true;
      await run.save();
    }
  }

  static Run? getRunById(String id) {
    return _runBox.get(id);
  }

  static Future<void> deleteRun(String id) async {
    await _runBox.delete(id);
  }

  // ============ ACHIEVEMENT METHODS ============

  static List<UnlockedAchievement> getUnlockedAchievements(String oderId) {
    return _achievementBox.values
        .where((a) => a.oderId == oderId)
        .toList();
  }

  static bool isAchievementUnlocked(String oderId, String achievementId) {
    return _achievementBox.values.any(
      (a) => a.oderId == oderId && a.achievementId == achievementId,
    );
  }

  static Future<void> unlockAchievement(String oderId, String achievementId) async {
    if (isAchievementUnlocked(oderId, achievementId)) return;

    final unlocked = UnlockedAchievement(
      oderId: oderId,
      achievementId: achievementId,
      unlockedAt: DateTime.now(),
    );
    await _achievementBox.add(unlocked);
  }

  // ============ POI METHODS ============

  static List<VisitedPoi> getVisitedPois(String oderId) {
    return _poiBox.values
        .where((p) => p.oderId == oderId)
        .toList();
  }

  static bool isPoiVisited(String oderId, String poiId) {
    return _poiBox.values.any(
      (p) => p.oderId == oderId && p.poiId == poiId,
    );
  }

  static Future<void> visitPoi(String oderId, String poiId) async {
    if (isPoiVisited(oderId, poiId)) return;

    final visited = VisitedPoi(
      oderId: oderId,
      poiId: poiId,
      visitedAt: DateTime.now(),
    );
    await _poiBox.add(visited);
  }

  // ============ MISSION METHODS ============

  static List<ActiveMission> getActiveMissions(String oderId) {
    return _missionBox.values
        .where((m) => m.oderId == oderId && !m.isCompleted)
        .toList();
  }

  static Future<void> assignMission(String oderId, String missionId) async {
    // Check if already assigned
    final existing = _missionBox.values.any(
      (m) => m.oderId == oderId && m.missionId == missionId && !m.isCompleted,
    );
    if (existing) return;

    final mission = ActiveMission(
      oderId: oderId,
      missionId: missionId,
      assignedAt: DateTime.now(),
    );
    await _missionBox.add(mission);
  }

  static Future<void> updateMissionProgress(ActiveMission mission) async {
    await mission.save();
  }

  static Future<void> completeMission(ActiveMission mission) async {
    mission.isCompleted = true;
    mission.completedAt = DateTime.now();
    await mission.save();
  }

  // Clear daily missions (call at midnight)
  static Future<void> clearDailyMissions(String oderId) async {
    final dailyMissions = _missionBox.values.where((m) =>
        m.oderId == oderId &&
        Missions.getById(m.missionId)?.type == MissionType.daily);

    for (final mission in dailyMissions) {
      await mission.delete();
    }
  }

  // ============ STATS METHODS ============

  static Map<String, dynamic> getUserStats(String oderId) {
    final runs = getAllRuns(oderId);
    final pois = getVisitedPois(oderId);
    final achievements = getUnlockedAchievements(oderId);

    int totalDistance = 0;
    int totalTime = 0;

    for (final run in runs) {
      totalDistance += run.distance;
      totalTime += run.duration;
    }

    return {
      'totalRuns': runs.length,
      'totalDistance': totalDistance,
      'totalTime': totalTime,
      'poisVisited': pois.length,
      'achievementsUnlocked': achievements.length,
    };
  }
}
