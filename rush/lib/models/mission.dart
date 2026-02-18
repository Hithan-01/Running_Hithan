import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

part 'mission.g.dart';

// Icon mapping for missions
class MissionIcons {
  static const Map<String, IconData> _icons = {
    'wb_sunny': Icons.wb_sunny_rounded,
    'directions_run': Icons.directions_run_rounded,
    'timer': Icons.timer_rounded,
    'map': Icons.map_rounded,
    'check_circle': Icons.check_circle_rounded,
    'calendar_today': Icons.calendar_today_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'flag': Icons.flag_rounded,
  };

  static IconData getIcon(String iconName) {
    return _icons[iconName] ?? Icons.help_outline_rounded;
  }
}

enum MissionType {
  daily,
  weekly,
  event,
}

enum MissionGoalType {
  distance,    // Run X meters
  duration,    // Run for X seconds
  pois,        // Visit X POIs
  runs,        // Complete X runs
}

@HiveType(typeId: 7)
class Mission {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int typeIndex;

  @HiveField(4)
  final int goalTypeIndex;

  @HiveField(5)
  final int goalValue;

  @HiveField(6)
  final int xpReward;

  @HiveField(7)
  final String icon;

  MissionType get type => MissionType.values[typeIndex];
  MissionGoalType get goalType => MissionGoalType.values[goalTypeIndex];

  const Mission({
    required this.id,
    required this.name,
    required this.description,
    required this.typeIndex,
    required this.goalTypeIndex,
    required this.goalValue,
    required this.xpReward,
    required this.icon,
  });
}

@HiveType(typeId: 8)
class ActiveMission extends HiveObject {
  @HiveField(0)
  String oderId;

  @HiveField(1)
  String missionId;

  @HiveField(2)
  int currentProgress;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  DateTime assignedAt;

  @HiveField(5)
  DateTime? completedAt;

  ActiveMission({
    required this.oderId,
    required this.missionId,
    this.currentProgress = 0,
    this.isCompleted = false,
    required this.assignedAt,
    this.completedAt,
  });
}

// Predefined missions
class Missions {
  // Daily missions
  static const List<Mission> dailyMissions = [
    Mission(
      id: 'daily_1km',
      name: 'Carrera Matutina',
      description: 'Corre 1 km hoy',
      typeIndex: 0,
      goalTypeIndex: 0,
      goalValue: 1000,
      xpReward: 50,
      icon: 'wb_sunny',
    ),
    Mission(
      id: 'daily_2km',
      name: 'Doble Esfuerzo',
      description: 'Corre 2 km hoy',
      typeIndex: 0,
      goalTypeIndex: 0,
      goalValue: 2000,
      xpReward: 80,
      icon: 'directions_run',
    ),
    Mission(
      id: 'daily_15min',
      name: 'Cuarto de Hora',
      description: 'Corre por 15 minutos',
      typeIndex: 0,
      goalTypeIndex: 1,
      goalValue: 900,
      xpReward: 60,
      icon: 'timer',
    ),
    Mission(
      id: 'daily_poi',
      name: 'Explorador del Dia',
      description: 'Visita 2 POIs diferentes',
      typeIndex: 0,
      goalTypeIndex: 2,
      goalValue: 2,
      xpReward: 70,
      icon: 'map',
    ),
    Mission(
      id: 'daily_run',
      name: 'Activo',
      description: 'Completa una carrera',
      typeIndex: 0,
      goalTypeIndex: 3,
      goalValue: 1,
      xpReward: 40,
      icon: 'check_circle',
    ),
  ];

  // Weekly missions
  static const List<Mission> weeklyMissions = [
    Mission(
      id: 'weekly_10km',
      name: 'Meta Semanal',
      description: 'Corre 10 km esta semana',
      typeIndex: 1,
      goalTypeIndex: 0,
      goalValue: 10000,
      xpReward: 200,
      icon: 'calendar_today',
    ),
    Mission(
      id: 'weekly_5runs',
      name: 'Consistencia',
      description: 'Completa 5 carreras esta semana',
      typeIndex: 1,
      goalTypeIndex: 3,
      goalValue: 5,
      xpReward: 250,
      icon: 'fitness_center',
    ),
    Mission(
      id: 'weekly_allpois',
      name: 'Tour del Campus',
      description: 'Visita 5 POIs diferentes esta semana',
      typeIndex: 1,
      goalTypeIndex: 2,
      goalValue: 5,
      xpReward: 180,
      icon: 'flag',
    ),
  ];

  static List<Mission> get all => [...dailyMissions, ...weeklyMissions];

  static Mission? getById(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
