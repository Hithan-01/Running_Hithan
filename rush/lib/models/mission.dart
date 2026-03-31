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
    'bolt': Icons.bolt_rounded,
    'explore': Icons.explore_rounded,
    'location_on': Icons.location_on_rounded,
    'star': Icons.star_rounded,
    'local_fire_department': Icons.local_fire_department_rounded,
    'repeat': Icons.repeat_rounded,
    'terrain': Icons.terrain_rounded,
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

  final String? targetPoiId;

  const Mission({
    required this.id,
    required this.name,
    required this.description,
    required this.typeIndex,
    required this.goalTypeIndex,
    required this.goalValue,
    required this.xpReward,
    required this.icon,
    this.targetPoiId,
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
  // Daily missions pool (3 random assigned each day)
  static const List<Mission> dailyMissions = [
    Mission(
      id: 'daily_500m',
      name: 'Calentamiento',
      description: 'Corre 500m hoy',
      typeIndex: 0, goalTypeIndex: 0, goalValue: 500,
      xpReward: 30, icon: 'wb_sunny',
    ),
    Mission(
      id: 'daily_1km',
      name: 'Carrera Matutina',
      description: 'Corre 1 km hoy',
      typeIndex: 0, goalTypeIndex: 0, goalValue: 1000,
      xpReward: 50, icon: 'directions_run',
    ),
    Mission(
      id: 'daily_2km',
      name: 'Doble Esfuerzo',
      description: 'Corre 2 km hoy',
      typeIndex: 0, goalTypeIndex: 0, goalValue: 2000,
      xpReward: 80, icon: 'bolt',
    ),
    Mission(
      id: 'daily_3km',
      name: 'Triple Ruta',
      description: 'Corre 3 km hoy',
      typeIndex: 0, goalTypeIndex: 0, goalValue: 3000,
      xpReward: 110, icon: 'terrain',
    ),
    Mission(
      id: 'daily_5km',
      name: 'Cinco de Poder',
      description: 'Corre 5 km hoy',
      typeIndex: 0, goalTypeIndex: 0, goalValue: 5000,
      xpReward: 160, icon: 'star',
    ),
    Mission(
      id: 'daily_10min',
      name: 'Diez Minutos',
      description: 'Corre por 10 minutos',
      typeIndex: 0, goalTypeIndex: 1, goalValue: 600,
      xpReward: 40, icon: 'timer',
    ),
    Mission(
      id: 'daily_15min',
      name: 'Cuarto de Hora',
      description: 'Corre por 15 minutos',
      typeIndex: 0, goalTypeIndex: 1, goalValue: 900,
      xpReward: 60, icon: 'timer',
    ),
    Mission(
      id: 'daily_30min',
      name: 'Media Hora',
      description: 'Corre por 30 minutos',
      typeIndex: 0, goalTypeIndex: 1, goalValue: 1800,
      xpReward: 100, icon: 'local_fire_department',
    ),
    Mission(
      id: 'daily_1run',
      name: 'Activo',
      description: 'Completa una carrera',
      typeIndex: 0, goalTypeIndex: 3, goalValue: 1,
      xpReward: 40, icon: 'check_circle',
    ),
    Mission(
      id: 'daily_2runs',
      name: 'Doble Turno',
      description: 'Completa 2 carreras hoy',
      typeIndex: 0, goalTypeIndex: 3, goalValue: 2,
      xpReward: 75, icon: 'repeat',
    ),
    // Specific POI missions
    Mission(
      id: 'daily_poi_biblioteca',
      name: 'Visita la Biblioteca',
      description: 'Pasa corriendo por la Biblioteca',
      typeIndex: 0, goalTypeIndex: 2, goalValue: 1,
      xpReward: 60, icon: 'location_on', targetPoiId: 'biblioteca',
    ),
    Mission(
      id: 'daily_poi_gym',
      name: 'Entrena en el Gym',
      description: 'Pasa corriendo por el Gym',
      typeIndex: 0, goalTypeIndex: 2, goalValue: 1,
      xpReward: 60, icon: 'location_on', targetPoiId: 'gym',
    ),
    Mission(
      id: 'daily_poi_rectoria',
      name: 'Visita Rectoría',
      description: 'Pasa corriendo por Rectoría',
      typeIndex: 0, goalTypeIndex: 2, goalValue: 1,
      xpReward: 55, icon: 'location_on', targetPoiId: 'rectoria',
    ),
    Mission(
      id: 'daily_poi_comedor',
      name: 'Hora del Comedor',
      description: 'Pasa corriendo por el Comedor',
      typeIndex: 0, goalTypeIndex: 2, goalValue: 1,
      xpReward: 50, icon: 'location_on', targetPoiId: 'comedor',
    ),
    Mission(
      id: 'daily_poi_arco',
      name: 'Por el Arco',
      description: 'Pasa por el Arco Principal',
      typeIndex: 0, goalTypeIndex: 2, goalValue: 1,
      xpReward: 50, icon: 'location_on', targetPoiId: 'arco_principal',
    ),
    Mission(
      id: 'daily_poi_plaza',
      name: 'Plaza 5 de Mayo',
      description: 'Visita la Plaza 5 de Mayo',
      typeIndex: 0, goalTypeIndex: 2, goalValue: 1,
      xpReward: 55, icon: 'location_on', targetPoiId: 'plaza_5_mayo',
    ),
    Mission(
      id: 'daily_poi_fitec',
      name: 'Visita FITEC',
      description: 'Pasa corriendo por FITEC',
      typeIndex: 0, goalTypeIndex: 2, goalValue: 1,
      xpReward: 55, icon: 'location_on', targetPoiId: 'fitec',
    ),
    Mission(
      id: 'daily_poi_soymart',
      name: 'Pasa por Soymart',
      description: 'Pasa corriendo por Soymart',
      typeIndex: 0, goalTypeIndex: 2, goalValue: 1,
      xpReward: 45, icon: 'location_on', targetPoiId: 'soymart',
    ),
    Mission(
      id: 'daily_poi_cancha',
      name: 'Cancha Principal',
      description: 'Pasa por la Cancha Principal',
      typeIndex: 0, goalTypeIndex: 2, goalValue: 1,
      xpReward: 55, icon: 'location_on', targetPoiId: 'cancha_principal',
    ),
    Mission(
      id: 'daily_poi_vicerrectoria',
      name: 'Visita Vicerrectoría',
      description: 'Pasa corriendo por Vicerrectoría',
      typeIndex: 0, goalTypeIndex: 2, goalValue: 1,
      xpReward: 55, icon: 'location_on', targetPoiId: 'vicerrectoria',
    ),
  ];

  // Weekly missions pool (4 random assigned each week)
  static const List<Mission> weeklyMissions = [
    // Distancia
    Mission(
      id: 'weekly_5km',
      name: 'Arranque Semanal',
      description: 'Corre 5 km esta semana',
      typeIndex: 1, goalTypeIndex: 0, goalValue: 5000,
      xpReward: 120, icon: 'directions_run',
    ),
    Mission(
      id: 'weekly_10km',
      name: 'Meta Semanal',
      description: 'Corre 10 km esta semana',
      typeIndex: 1, goalTypeIndex: 0, goalValue: 10000,
      xpReward: 200, icon: 'calendar_today',
    ),
    Mission(
      id: 'weekly_15km',
      name: 'Quince Kilómetros',
      description: 'Corre 15 km esta semana',
      typeIndex: 1, goalTypeIndex: 0, goalValue: 15000,
      xpReward: 280, icon: 'terrain',
    ),
    Mission(
      id: 'weekly_20km',
      name: 'Gran Meta',
      description: 'Corre 20 km esta semana',
      typeIndex: 1, goalTypeIndex: 0, goalValue: 20000,
      xpReward: 350, icon: 'star',
    ),
    // Carreras
    Mission(
      id: 'weekly_2runs',
      name: 'Dos Salidas',
      description: 'Completa 2 carreras esta semana',
      typeIndex: 1, goalTypeIndex: 3, goalValue: 2,
      xpReward: 100, icon: 'wb_sunny',
    ),
    Mission(
      id: 'weekly_3runs',
      name: 'Tres en Raya',
      description: 'Completa 3 carreras esta semana',
      typeIndex: 1, goalTypeIndex: 3, goalValue: 3,
      xpReward: 150, icon: 'directions_run',
    ),
    Mission(
      id: 'weekly_5runs',
      name: 'Consistencia',
      description: 'Completa 5 carreras esta semana',
      typeIndex: 1, goalTypeIndex: 3, goalValue: 5,
      xpReward: 250, icon: 'fitness_center',
    ),
    Mission(
      id: 'weekly_7runs',
      name: 'Semana Perfecta',
      description: 'Corre los 7 días de la semana',
      typeIndex: 1, goalTypeIndex: 3, goalValue: 7,
      xpReward: 400, icon: 'local_fire_department',
    ),
    // Tiempo
    Mission(
      id: 'weekly_60min',
      name: 'Una Hora',
      description: 'Acumula 60 minutos corriendo',
      typeIndex: 1, goalTypeIndex: 1, goalValue: 3600,
      xpReward: 180, icon: 'timer',
    ),
    Mission(
      id: 'weekly_120min',
      name: 'Dos Horas',
      description: 'Acumula 2 horas corriendo',
      typeIndex: 1, goalTypeIndex: 1, goalValue: 7200,
      xpReward: 300, icon: 'timer',
    ),
    // POIs específicos semanales
    Mission(
      id: 'weekly_poi_biblioteca',
      name: 'Estudio y Deporte',
      description: 'Visita la Biblioteca esta semana',
      typeIndex: 1, goalTypeIndex: 2, goalValue: 1,
      xpReward: 130, icon: 'location_on', targetPoiId: 'biblioteca',
    ),
    Mission(
      id: 'weekly_poi_gym',
      name: 'Día de Gym',
      description: 'Visita el Gym esta semana',
      typeIndex: 1, goalTypeIndex: 2, goalValue: 1,
      xpReward: 130, icon: 'location_on', targetPoiId: 'gym',
    ),
    Mission(
      id: 'weekly_poi_rectoria',
      name: 'Visita Rectoría',
      description: 'Pasa por Rectoría esta semana',
      typeIndex: 1, goalTypeIndex: 2, goalValue: 1,
      xpReward: 120, icon: 'location_on', targetPoiId: 'rectoria',
    ),
    Mission(
      id: 'weekly_poi_cancha',
      name: 'La Cancha',
      description: 'Pasa por la Cancha Principal',
      typeIndex: 1, goalTypeIndex: 2, goalValue: 1,
      xpReward: 120, icon: 'location_on', targetPoiId: 'cancha_principal',
    ),
    Mission(
      id: 'weekly_poi_arco',
      name: 'Entrada al Campus',
      description: 'Pasa por el Arco Principal',
      typeIndex: 1, goalTypeIndex: 2, goalValue: 1,
      xpReward: 110, icon: 'location_on', targetPoiId: 'arco_principal',
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
