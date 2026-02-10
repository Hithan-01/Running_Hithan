import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user.dart';
import '../models/run.dart';
import '../models/achievement.dart';
import '../models/poi.dart';
import '../models/mission.dart';
import 'database_service.dart';
import 'sync_service.dart';

class GamificationService extends ChangeNotifier {
  User? _user;
  List<ActiveMission> _activeMissions = [];
  List<String> _unlockedAchievementIds = [];
  List<String> _visitedPoiIds = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Callbacks for UI notifications
  Function(Achievement)? onAchievementUnlocked;
  Function(int)? onLevelUp;
  Function(ActiveMission, Mission)? onMissionCompleted;

  User? get user => _user;
  List<ActiveMission> get activeMissions => _activeMissions;
  int get xp => _user?.xp ?? 0;
  int get level => _user?.level ?? 1;
  String get levelName => _user?.levelName ?? 'Rookie Runner';
  double get levelProgress => _user?.levelProgress ?? 0;

  // XP rewards
  static const int xpPerKm = 50;
  static const int xpPerMinute = 2;

  // Initialize service with user
  Future<void> init() async {
    _user = DatabaseService.getCurrentUser();
    if (_user != null) {
      _loadUserData();
      // Intentar sincronizar carreras pendientes al iniciar
      _syncPendingRuns();
      // Escuchar cambios de conectividad para auto-sincronizar
      _setupConnectivityListener();
    }
    notifyListeners();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      // Si recuperamos conexión, intentar sincronizar
      if (!result.contains(ConnectivityResult.none)) {
        debugPrint('🌐 Conexión detectada, sincronizando carreras pendientes...');
        _syncPendingRuns();
      }
    });
  }

  Future<void> _syncPendingRuns() async {
    if (_user == null) return;

    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      final syncedCount = await SyncService().syncPendingRuns(
        firebaseUser.uid,
        _user!.id,
      );
      if (syncedCount > 0) {
        debugPrint('✅ Se sincronizaron $syncedCount carreras');
      }
    } catch (e) {
      debugPrint('⚠️ Error en sincronización automática: $e');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _loadUserData() {
    if (_user == null) return;
    _activeMissions = DatabaseService.getActiveMissions(_user!.id);
    _unlockedAchievementIds = DatabaseService.getUnlockedAchievements(
      _user!.id,
    ).map((a) => a.achievementId).toList();
    _visitedPoiIds = DatabaseService.getVisitedPois(
      _user!.id,
    ).map((p) => p.poiId).toList();
  }

  // Create or get user
  Future<User> ensureUser(String name, {String? faculty, int? semester}) async {
    _user = DatabaseService.getCurrentUser();
    if (_user == null) {
      _user = await DatabaseService.createUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        faculty: faculty,
        semester: semester,
      );
      // Assign initial daily missions
      await assignDailyMissions();
      // Create mock runs for testing
      await _createMockRuns();
    }
    _loadUserData();
    notifyListeners();
    return _user!;
  }

  // Create mock runs for testing/screenshots
  Future<void> _createMockRuns() async {
    if (_user == null) return;

    final now = DateTime.now();

    // Run 1: Today
    final run1 = Run(
      id: 'mock_run_1',
      oderId: _user!.id,
      distance: 3500, // 3.5 km
      duration: 1800, // 30 min
      avgPace: 5.14,
      xpEarned: 235,
      poisVisited: ['biblioteca', 'cafeteria'],
      route: [],
      createdAt: now,
    );
    await DatabaseService.saveRun(run1);

    // Run 2: Yesterday
    final run2 = Run(
      id: 'mock_run_2',
      oderId: _user!.id,
      distance: 5200, // 5.2 km
      duration: 2700, // 45 min
      avgPace: 5.19,
      xpEarned: 310,
      poisVisited: ['gimnasio'],
      route: [],
      createdAt: now.subtract(const Duration(days: 1)),
    );
    await DatabaseService.saveRun(run2);

    // Run 3: 3 days ago
    final run3 = Run(
      id: 'mock_run_3',
      oderId: _user!.id,
      distance: 2100, // 2.1 km
      duration: 1200, // 20 min
      avgPace: 5.71,
      xpEarned: 145,
      poisVisited: [],
      route: [],
      createdAt: now.subtract(const Duration(days: 3)),
    );
    await DatabaseService.saveRun(run3);

    // Update user stats
    _user!.totalDistance = 10800;
    _user!.totalRuns = 3;
    _user!.totalTime = 5700;
    _user!.currentStreak = 2;
    _user!.addXp(690);
    await DatabaseService.updateUser(_user!);
  }

  // Regenerate mock runs (for testing)
  Future<void> regenerateMockRuns() async {
    if (_user == null) return;
    await _createMockRuns();
    _loadUserData();
    notifyListeners();
  }

  // Add XP (for testing AnimatedContainer)
  Future<void> addTestXp(int amount) async {
    if (_user == null) return;
    _user!.addXp(amount);
    await DatabaseService.updateUser(_user!);
    notifyListeners();
  }

  // Update user name
  Future<void> updateUserName(String newName) async {
    if (_user == null) return;
    _user!.name = newName;
    await DatabaseService.updateUser(_user!);
    notifyListeners();
  }

  // Process completed run
  Future<RunResult> processRun(Run run) async {
    if (_user == null) throw Exception('No user found');

    final result = RunResult();
    int totalXp = 0;

    // XP from distance
    int distanceXp = (run.distanceKm * xpPerKm).round();
    totalXp += distanceXp;
    result.distanceXp = distanceXp;

    // XP from duration
    int durationXp = (run.duration ~/ 60) * xpPerMinute;
    totalXp += durationXp;
    result.durationXp = durationXp;

    // Process POI visits
    for (final poiId in run.poisVisited) {
      if (!_visitedPoiIds.contains(poiId)) {
        final poi = CampusPois.getById(poiId);
        if (poi != null) {
          await DatabaseService.visitPoi(_user!.id, poiId);
          _visitedPoiIds.add(poiId);
          totalXp += poi.xpReward;
          result.poisXp += poi.xpReward;
          result.newPois.add(poi);
        }
      }
    }

    // Save run
    run.xpEarned = totalXp;
    await DatabaseService.saveRun(run);

    // Update user stats
    int previousLevel = _user!.level;
    _user!.addXp(totalXp);
    _user!.totalDistance += run.distance;
    _user!.totalRuns++;
    _user!.totalTime += run.duration;
    _updateStreak();
    await DatabaseService.updateUser(_user!);

    result.totalXp = totalXp;

    // Check level up
    if (_user!.level > previousLevel) {
      result.newLevel = _user!.level;
      onLevelUp?.call(_user!.level);
    }

    // Check achievements
    final newAchievements = await _checkAchievements(run);
    for (final achievement in newAchievements) {
      totalXp += achievement.xpReward;
      result.achievementXp += achievement.xpReward;
    }
    result.newAchievements = newAchievements;

    // Update mission progress
    await _updateMissionProgress(run);

    notifyListeners();
    return result;
  }

  void _updateStreak() {
    if (_user == null) return;

    final now = DateTime.now();
    final lastRun = _user!.lastRunAt;

    if (lastRun == null) {
      _user!.currentStreak = 1;
    } else {
      final daysDiff = now.difference(lastRun).inDays;
      if (daysDiff == 0) {
        // Same day, no change
      } else if (daysDiff == 1) {
        // Consecutive day
        _user!.currentStreak++;
      } else {
        // Streak broken
        _user!.currentStreak = 1;
      }
    }

    if (_user!.currentStreak > _user!.bestStreak) {
      _user!.bestStreak = _user!.currentStreak;
    }

    _user!.lastRunAt = now;
  }

  Future<List<Achievement>> _checkAchievements(Run run) async {
    if (_user == null) return [];

    final List<Achievement> newlyUnlocked = [];

    for (final achievement in Achievements.all) {
      if (_unlockedAchievementIds.contains(achievement.id)) continue;

      bool shouldUnlock = false;

      switch (achievement.id) {
        // First run
        case 'first_run':
          shouldUnlock = _user!.totalRuns >= 1;
          break;

        // Distance achievements
        case 'first_km':
          shouldUnlock = run.distance >= 1000;
          break;
        case 'five_km':
          shouldUnlock = run.distance >= 5000;
          break;
        case 'ten_km':
          shouldUnlock = run.distance >= 10000;
          break;
        case 'total_25km':
          shouldUnlock = _user!.totalDistance >= 25000;
          break;
        case 'total_50km':
          shouldUnlock = _user!.totalDistance >= 50000;
          break;

        // POI achievements
        case 'first_poi':
          shouldUnlock = _visitedPoiIds.isNotEmpty;
          break;
        case 'five_pois':
          shouldUnlock = _visitedPoiIds.length >= 5;
          break;
        case 'all_pois':
          shouldUnlock = _visitedPoiIds.length >= CampusPois.all.length;
          break;

        // Consistency achievements
        case 'streak_3':
          shouldUnlock = _user!.currentStreak >= 3;
          break;
        case 'streak_7':
          shouldUnlock = _user!.currentStreak >= 7;
          break;
        case 'ten_runs':
          shouldUnlock = _user!.totalRuns >= 10;
          break;

        // Speed achievements
        case 'pace_6':
          shouldUnlock =
              run.avgPace > 0 && run.avgPace < 6 && run.distance >= 1000;
          break;
        case 'pace_5':
          shouldUnlock =
              run.avgPace > 0 && run.avgPace < 5 && run.distance >= 1000;
          break;

        // Secret achievements
        case 'pi_run':
          double km = run.distanceKm;
          shouldUnlock = km >= 3.13 && km <= 3.15;
          break;
        case 'early_bird':
          shouldUnlock = run.createdAt.hour < 6;
          break;
      }

      if (shouldUnlock) {
        await DatabaseService.unlockAchievement(_user!.id, achievement.id);
        _unlockedAchievementIds.add(achievement.id);
        _user!.addXp(achievement.xpReward);
        newlyUnlocked.add(achievement);
        onAchievementUnlocked?.call(achievement);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      await DatabaseService.updateUser(_user!);
    }

    return newlyUnlocked;
  }

  Future<void> _updateMissionProgress(Run run) async {
    for (final activeMission in _activeMissions) {
      if (activeMission.isCompleted) continue;

      final mission = Missions.getById(activeMission.missionId);
      if (mission == null) continue;

      int progress = activeMission.currentProgress;

      switch (mission.goalType) {
        case MissionGoalType.distance:
          progress += run.distance;
          break;
        case MissionGoalType.duration:
          progress += run.duration;
          break;
        case MissionGoalType.pois:
          progress += run.poisVisited.length;
          break;
        case MissionGoalType.runs:
          progress += 1;
          break;
      }

      activeMission.currentProgress = progress;

      if (progress >= mission.goalValue && !activeMission.isCompleted) {
        await DatabaseService.completeMission(activeMission);
        _user!.addXp(mission.xpReward);
        await DatabaseService.updateUser(_user!);
        onMissionCompleted?.call(activeMission, mission);
      } else {
        await DatabaseService.updateMissionProgress(activeMission);
      }
    }

    // Reload missions
    _activeMissions = DatabaseService.getActiveMissions(_user!.id);
  }

  // Assign daily missions
  Future<void> assignDailyMissions() async {
    if (_user == null) return;

    // Clear old daily missions
    await DatabaseService.clearDailyMissions(_user!.id);

    // Assign 2-3 random daily missions
    final dailyMissions = List<Mission>.from(Missions.dailyMissions)..shuffle();
    final toAssign = dailyMissions.take(3);

    for (final mission in toAssign) {
      await DatabaseService.assignMission(_user!.id, mission.id);
    }

    _activeMissions = DatabaseService.getActiveMissions(_user!.id);
    notifyListeners();
  }

  // Check if achievement is unlocked
  bool isAchievementUnlocked(String achievementId) {
    return _unlockedAchievementIds.contains(achievementId);
  }

  // Check if POI is visited
  bool isPoiVisited(String poiId) {
    return _visitedPoiIds.contains(poiId);
  }

  // Get visited POI count
  int get visitedPoiCount => _visitedPoiIds.length;

  // Get user stats
  Map<String, dynamic> getStats() {
    if (_user == null) return {};
    return DatabaseService.getUserStats(_user!.id);
  }
}

// Result of processing a run
class RunResult {
  int totalXp = 0;
  int distanceXp = 0;
  int durationXp = 0;
  int poisXp = 0;
  int achievementXp = 0;
  List<Poi> newPois = [];
  List<Achievement> newAchievements = [];
  int? newLevel;
}
