import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user.dart';
import '../models/run.dart';
import '../models/achievement.dart';
import '../models/poi.dart';
import '../models/mission.dart';
import '../models/notification_item.dart';
import '../models/run_title.dart';
import '../models/store_item.dart';
import 'package:uuid/uuid.dart';
import 'database_service.dart';
import 'notification_service.dart';
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

  // Coin rewards
  static const int coinsPerKm = 10;
  static const int coinsPerDailyMission = 15;
  static const int coinsPerWeeklyMission = 25;
  static const int coinsPerLevelUp = 50;

  int get coins => _user?.coins ?? 0;

  // Initialize service with user
  Future<void> init() async {
    final uid = auth.FirebaseAuth.instance.currentUser?.uid;
    _user = uid != null ? DatabaseService.getUser(uid) : null;
    if (_user != null) {
      _loadUserData();
      await _checkAndResetMissions();
      _syncPendingRuns();
      _setupConnectivityListener();
    }
    notifyListeners();
  }

  Future<void> _checkAndResetMissions() async {
    if (_user == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // --- Daily reset ---
    final lastDaily = DatabaseService.getLastDailyAssignmentDate(_user!.id);
    final lastDailyDay = lastDaily != null
        ? DateTime(lastDaily.year, lastDaily.month, lastDaily.day)
        : null;
    if (lastDailyDay == null || lastDailyDay.isBefore(today)) {
      await assignDailyMissions();
    }

    // --- Weekly reset (Monday of current week) ---
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final lastWeekly = DatabaseService.getLastWeeklyAssignmentDate(_user!.id);
    final lastWeeklyDay = lastWeekly != null
        ? DateTime(lastWeekly.year, lastWeekly.month, lastWeekly.day)
        : null;
    final activeWeeklyCount = _activeMissions
        .where((m) => Missions.getById(m.missionId)?.type == MissionType.weekly)
        .length;
    if (lastWeeklyDay == null ||
        lastWeeklyDay.isBefore(monday) ||
        activeWeeklyCount < Missions.weeklyMissions.length) {
      await assignWeeklyMissions();
    }
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
    _autoEquipTitle();
  }

  // Create or get user
  Future<User> ensureUser(
    String uid,
    String name, {
    String? faculty,
    int? semester,
  }) async {
    _user = DatabaseService.getUser(uid);

    // Local looks empty → try to restore from Firestore
    // (covers: first login, wiped device, or local data corrupted to 0)
    final localEmpty = _user == null || (_user!.xp == 0 && _user!.totalRuns == 0);

    if (localEmpty) {
      final remote = await SyncService().getUserStats(uid);
      final remoteXp = (remote?['xp'] as num?)?.toInt() ?? 0;

      if (remote != null && remoteXp > 0) {
        // Restore from Firestore
        final distKm    = (remote['totalDistance'] as num?)?.toDouble() ?? 0.0;
        final runs      = (remote['totalRuns'] as num?)?.toInt() ?? 0;
        final rName     = remote['name'] as String? ?? name;
        final rFac      = remote['faculty'] as String? ?? faculty;
        final rSem      = (remote['semester'] as num?)?.toInt() ?? semester;
        final rTime     = (remote['totalTime'] as num?)?.toInt() ?? 0;
        final rStreak   = (remote['currentStreak'] as num?)?.toInt() ?? 0;
        final rBest     = (remote['bestStreak'] as num?)?.toInt() ?? 0;
        final rCoins    = (remote['coins'] as num?)?.toInt() ?? 0;
        final rPurchased = (remote['purchasedItemIds'] as List?)
            ?.map((e) => e.toString()).toList() ?? [];
        final rTitle    = remote['equippedTitleId'] as String?;
        final rAvatarColor = remote['equippedAvatarColorId'] as String?;
        final rAvatarFrame = remote['equippedAvatarFrameId'] as String?;
        final rRouteColor  = remote['equippedRouteColorId'] as String?;
        final rAchievements = (remote['unlockedAchievementIds'] as List?)
            ?.map((e) => e.toString()).toList() ?? [];
        final rPois = (remote['visitedPoiIds'] as List?)
            ?.map((e) => e.toString()).toList() ?? [];

        if (_user == null) {
          _user = await DatabaseService.createUser(
            id: uid, name: rName, faculty: rFac, semester: rSem,
          );
        } else {
          _user!.name     = rName;
          _user!.faculty  = rFac;
          _user!.semester = rSem;
        }

        _user!.xp            = remoteXp;
        _user!.totalDistance = (distKm * 1000).round();
        _user!.totalRuns     = runs;
        _user!.totalTime     = rTime;
        _user!.currentStreak = rStreak;
        _user!.bestStreak    = rBest;
        _user!.coins         = rCoins;
        _user!.purchasedItemIds   = rPurchased;
        _user!.equippedTitleId    = rTitle;
        _user!.equippedAvatarColorId = rAvatarColor;
        _user!.equippedAvatarFrameId = rAvatarFrame;
        _user!.equippedRouteColorId  = rRouteColor;

        // Recalculate level from restored XP
        _user!.level = 1;
        for (int i = 1; i < User.levelThresholds.length; i++) {
          if (remoteXp >= User.levelThresholds[i]) {
            _user!.level = i + 1;
          } else {
            break;
          }
        }
        await DatabaseService.updateUser(_user!);

        // Restore achievements to Hive
        for (final id in rAchievements) {
          await DatabaseService.unlockAchievement(uid, id);
        }
        // Restore visited POIs to Hive
        for (final id in rPois) {
          await DatabaseService.visitPoi(uid, id);
        }

        debugPrint('✅ Restaurado: $remoteXp XP, ${distKm.toStringAsFixed(1)} km, '
            '${rAchievements.length} logros, ${rPois.length} POIs');
        await assignDailyMissions();
      } else if (_user == null) {
        // Truly new account — initialize in Firestore
        _user = await DatabaseService.createUser(
          id: uid, name: name, faculty: faculty, semester: semester,
        );
        await SyncService().initNewUser(uid, name, faculty: faculty, semester: semester);
        await assignDailyMissions();
      }
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

  // Update user profile (name, faculty, semester)
  Future<void> updateUserProfile({
    required String name,
    String? faculty,
    int? semester,
  }) async {
    if (_user == null) return;
    _user!.name = name;
    _user!.faculty = faculty;
    _user!.semester = semester;
    await DatabaseService.updateUser(_user!);
    notifyListeners();
    // Sync to Firestore
    final uid = auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await SyncService().updateUserProfile(uid, name: name, faculty: faculty, semester: semester);
    }
  }

  // Update profile photo path
  Future<void> updateUserPhoto(String photoPath) async {
    if (_user == null) return;
    _user!.photoPath = photoPath;
    await DatabaseService.updateUser(_user!);
    notifyListeners();
  }

  // Process completed run
  Future<RunResult> processRun(Run run) async {
    if (_user == null) throw Exception('No user found');

    final result = RunResult();
    int totalXp = 0;
    int totalCoins = 0;

    // XP + coins from distance
    int distanceXp = (run.distanceKm * xpPerKm).round();
    int distanceCoins = (run.distanceKm * coinsPerKm).round();
    totalXp += distanceXp;
    totalCoins += distanceCoins;
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
      totalCoins += coinsPerLevelUp;
      onLevelUp?.call(_user!.level);
      await _logNotification(
        title: 'Subiste al nivel ${_user!.level}!',
        body: 'Ahora eres ${_user!.levelName}. Sigue acumulando XP!',
        type: 'level_up',
      );
    }

    // Check achievements
    final newAchievements = await _checkAchievements(run);
    for (final achievement in newAchievements) {
      totalXp += achievement.xpReward;
      result.achievementXp += achievement.xpReward;
      totalCoins += (achievement.xpReward / 5).round();
    }
    result.newAchievements = newAchievements;

    // Update mission progress
    await _updateMissionProgress(run);

    // Reschedule notifications (streak reminder skips today since lastRunAt is now)
    await NotificationService.scheduleAllNotifications(_user!);

    // Save earned coins
    result.coinsEarned = totalCoins;
    _user!.addCoins(totalCoins);
    await DatabaseService.updateUser(_user!);

    // Celebrate streak if active
    if (_user!.currentStreak >= 2) {
      await NotificationService.showStreakCelebration(_user!.currentStreak);
      await _logNotification(
        title: 'Llevas ${_user!.currentStreak} dias de racha!',
        body: 'Sigue asi! La consistencia es clave para subir de nivel.',
        type: 'streak',
      );
    }

    _syncProgress();
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

        // Mission achievements
        case 'first_mission':
          shouldUnlock = DatabaseService.getCompletedMissionsCount(_user!.id) >= 1;
          break;
        case 'ten_missions':
          shouldUnlock = DatabaseService.getCompletedMissionsCount(_user!.id) >= 10;
          break;
        case 'fifty_missions':
          shouldUnlock = DatabaseService.getCompletedMissionsCount(_user!.id) >= 50;
          break;

        // Secret achievements
        case 'pi_run':
          double km = run.distanceKm;
          shouldUnlock = km >= 3.13 && km <= 3.15;
          break;
        case 'early_bird':
          shouldUnlock = run.createdAt.hour < 6;
          break;
        case 'three_am':
          shouldUnlock = run.createdAt.hour == 3;
          break;
        case 'night_owl':
          shouldUnlock = run.createdAt.hour >= 22;
          break;
        case 'speed_demon':
          shouldUnlock =
              run.avgPace > 0 && run.avgPace < 4.0 && run.distance >= 1000;
          break;
        case 'golden_hour':
          final h = run.createdAt.hour;
          shouldUnlock = h >= 18 && h < 20;
          break;
      }

      if (shouldUnlock) {
        await DatabaseService.unlockAchievement(_user!.id, achievement.id);
        _unlockedAchievementIds.add(achievement.id);
        _user!.addXp(achievement.xpReward);
        newlyUnlocked.add(achievement);
        onAchievementUnlocked?.call(achievement);
        await _logNotification(
          title: 'Logro desbloqueado: ${achievement.name}',
          body: '${achievement.description} (+${achievement.xpReward} XP)',
          type: 'achievement',
        );
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
          if (mission.targetPoiId != null) {
            progress += run.poisVisited.contains(mission.targetPoiId) ? 1 : 0;
          } else {
            progress += run.poisVisited.length;
          }
          break;
        case MissionGoalType.runs:
          progress += 1;
          break;
      }

      activeMission.currentProgress = progress;

      if (progress >= mission.goalValue && !activeMission.isCompleted) {
        await DatabaseService.completeMission(activeMission);
        _user!.addXp(mission.xpReward);
        final missionCoins = mission.type == MissionType.weekly
            ? coinsPerWeeklyMission
            : coinsPerDailyMission;
        _user!.addCoins(missionCoins);
        await DatabaseService.updateUser(_user!);
        onMissionCompleted?.call(activeMission, mission);
        await _logNotification(
          title: 'Mision completada: ${mission.name}',
          body: '${mission.description} (+${mission.xpReward} XP · +$missionCoins 🪙)',
          type: 'mission',
        );
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

    await DatabaseService.clearDailyMissions(_user!.id);

    final dailyMissions = List<Mission>.from(Missions.dailyMissions)..shuffle();
    for (final mission in dailyMissions.take(3)) {
      await DatabaseService.assignMission(_user!.id, mission.id);
    }

    _activeMissions = DatabaseService.getActiveMissions(_user!.id);
    notifyListeners();
  }

  // Assign weekly missions
  Future<void> assignWeeklyMissions() async {
    if (_user == null) return;

    await DatabaseService.clearWeeklyMissions(_user!.id);

    final pool = List<Mission>.from(Missions.weeklyMissions)..shuffle();
    for (final mission in pool.take(4)) {
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

  // All visited POI ids (for map filtering)
  List<String> get visitedPoiIds => List.unmodifiable(_visitedPoiIds);

  // POI ids that are targets of specific active missions
  List<String> get activeMissionTargetPoiIds {
    return _activeMissions
        .where((am) => !am.isCompleted)
        .map((am) => Missions.getById(am.missionId))
        .whereType<Mission>()
        .where((m) => m.targetPoiId != null)
        .map((m) => m.targetPoiId!)
        .toList();
  }

  // ── Store ─────────────────────────────────────────────────────────────────

  List<String> get purchasedItemIds => _user?.purchasedItemIds ?? [];

  bool hasItem(String itemId) => _user?.hasItem(itemId) ?? false;

  String? get equippedAvatarColorId => _user?.equippedAvatarColorId;
  String? get equippedAvatarFrameId => _user?.equippedAvatarFrameId;
  String? get equippedRouteColorId => _user?.equippedRouteColorId;

  /// Returns null if can't afford or already owned. Returns item on success.
  Future<StoreItem?> purchaseItem(StoreItem item) async {
    if (_user == null) return null;
    if (_user!.hasItem(item.id)) return null;
    if (_user!.coins < item.price) return null;

    _user!.coins -= item.price;
    _user!.purchaseItem(item.id);

    // Auto-equip on first purchase of that category
    _equipItem(item);

    await DatabaseService.updateUser(_user!);
    _syncProgress();
    notifyListeners();
    return item;
  }

  Future<void> equipStoreItem(StoreItem item) async {
    if (_user == null) return;
    if (!_user!.hasItem(item.id)) return;
    _equipItem(item);
    await DatabaseService.updateUser(_user!);
    _syncProgress();
    notifyListeners();
  }

  void _equipItem(StoreItem item) {
    switch (item.category) {
      case StoreCategory.avatarColor:
        _user!.equippedAvatarColorId = item.id;
      case StoreCategory.avatarFrame:
        _user!.equippedAvatarFrameId = item.id;
      case StoreCategory.routeColor:
        _user!.equippedRouteColorId = item.id;
    }
  }

/// Sube el progreso completo a Firestore (coins, logros, POIs, etc.)
  void _syncProgress() {
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || _user == null) return;
    SyncService().syncUserProgress(
      firebaseUser.uid,
      xp: _user!.xp,
      level: _user!.level,
      totalDistanceKm: _user!.totalDistance / 1000.0,
      totalRuns: _user!.totalRuns,
      totalTimeSeconds: _user!.totalTime,
      currentStreak: _user!.currentStreak,
      bestStreak: _user!.bestStreak,
      coins: _user!.coins,
      purchasedItemIds: _user!.purchasedItemIds,
      equippedTitleId: _user!.equippedTitleId,
      equippedAvatarColorId: _user!.equippedAvatarColorId,
      equippedAvatarFrameId: _user!.equippedAvatarFrameId,
      equippedRouteColorId: _user!.equippedRouteColorId,
      unlockedAchievementIds: _unlockedAchievementIds,
      visitedPoiIds: _visitedPoiIds,
    );
  }

  // ── Titles ────────────────────────────────────────────────────────────────

  List<RunTitle> get unlockedTitles {
    return RunTitles.all.where((t) {
      switch (t.unlockType) {
        case TitleUnlockType.always:
          return true;
        case TitleUnlockType.level:
          return (_user?.level ?? 1) >= (t.requiredLevel ?? 1);
        case TitleUnlockType.achievement:
          return _unlockedAchievementIds.contains(t.requiredAchievementId);
      }
    }).toList();
  }

  RunTitle? get equippedTitle {
    final id = _user?.equippedTitleId;
    if (id == null) return null;
    return RunTitles.getById(id);
  }

  Future<void> equipTitle(String titleId) async {
    if (_user == null) return;
    _user!.equippedTitleId = titleId;
    await DatabaseService.updateUser(_user!);
    _syncProgress();
    notifyListeners();
  }

  // Auto-equip first unlocked title if none equipped yet
  void _autoEquipTitle() {
    if (_user == null || _user!.equippedTitleId != null) return;
    final titles = unlockedTitles;
    if (titles.isNotEmpty) {
      _user!.equippedTitleId = titles.first.id;
    }
  }

  // True if there's an active generic POI mission (show all POIs)
  bool get hasActiveGenericPoiMission {
    return _activeMissions
        .where((am) => !am.isCompleted)
        .map((am) => Missions.getById(am.missionId))
        .whereType<Mission>()
        .any((m) => m.goalType == MissionGoalType.pois && m.targetPoiId == null);
  }

  // Log an in-app notification to the activity feed
  Future<void> _logNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    if (_user == null) return;
    final item = NotificationItem(
      id: const Uuid().v4(),
      userId: _user!.id,
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
    );
    await DatabaseService.addNotificationItem(item);
  }

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
  int coinsEarned = 0;
  List<Poi> newPois = [];
  List<Achievement> newAchievements = [];
  int? newLevel;
}
