import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

part 'achievement.g.dart';

// Icon mapping for achievements
class AchievementIcons {
  static const Map<String, IconData> _icons = {
    'map': Icons.map_rounded,
    'account_balance': Icons.account_balance_rounded,
    'workspace_premium': Icons.workspace_premium_rounded,
    'flag': Icons.flag_rounded,
    'directions_run': Icons.directions_run_rounded,
    'emoji_events': Icons.emoji_events_rounded,
    'trending_up': Icons.trending_up_rounded,
    'star': Icons.star_rounded,
    'play_arrow': Icons.play_arrow_rounded,
    'local_fire_department': Icons.local_fire_department_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'military_tech': Icons.military_tech_rounded,
    'bolt': Icons.bolt_rounded,
    'speed': Icons.speed_rounded,
    'calculate': Icons.calculate_rounded,
    'wb_twilight': Icons.wb_twilight_rounded,
    'lock': Icons.lock_rounded,
  };

  static IconData getIcon(String iconName) {
    return _icons[iconName] ?? Icons.help_outline_rounded;
  }
}

enum AchievementCategory {
  exploration,
  distance,
  consistency,
  speed,
  secret,
}

@HiveType(typeId: 3)
class Achievement {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String icon;

  @HiveField(4)
  final int xpReward;

  @HiveField(5)
  final int categoryIndex;

  AchievementCategory get category => AchievementCategory.values[categoryIndex];

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.categoryIndex,
  });
}

@HiveType(typeId: 4)
class UnlockedAchievement extends HiveObject {
  @HiveField(0)
  String oderId;

  @HiveField(1)
  String achievementId;

  @HiveField(2)
  DateTime unlockedAt;

  UnlockedAchievement({
    required this.oderId,
    required this.achievementId,
    required this.unlockedAt,
  });
}

// Predefined achievements
class Achievements {
  static const List<Achievement> all = [
    // Exploration
    Achievement(
      id: 'first_poi',
      name: 'Explorador Novato',
      description: 'Visita tu primer POI',
      icon: 'map',
      xpReward: 50,
      categoryIndex: 0,
    ),
    Achievement(
      id: 'five_pois',
      name: 'Conociendo el Campus',
      description: 'Visita 5 POIs diferentes',
      icon: 'account_balance',
      xpReward: 150,
      categoryIndex: 0,
    ),
    Achievement(
      id: 'all_pois',
      name: 'Master del Campus',
      description: 'Visita todos los POIs',
      icon: 'workspace_premium',
      xpReward: 500,
      categoryIndex: 0,
    ),

    // Distance
    Achievement(
      id: 'first_km',
      name: 'Primer Kilometro',
      description: 'Corre tu primer kilometro',
      icon: 'flag',
      xpReward: 25,
      categoryIndex: 1,
    ),
    Achievement(
      id: 'five_km',
      name: '5K Runner',
      description: 'Corre 5 km en una carrera',
      icon: 'directions_run',
      xpReward: 100,
      categoryIndex: 1,
    ),
    Achievement(
      id: 'ten_km',
      name: '10K Champion',
      description: 'Corre 10 km en una carrera',
      icon: 'emoji_events',
      xpReward: 250,
      categoryIndex: 1,
    ),
    Achievement(
      id: 'total_25km',
      name: 'Maratonista en Progreso',
      description: 'Acumula 25 km en total',
      icon: 'trending_up',
      xpReward: 200,
      categoryIndex: 1,
    ),
    Achievement(
      id: 'total_50km',
      name: 'Medio Centenar',
      description: 'Acumula 50 km en total',
      icon: 'star',
      xpReward: 400,
      categoryIndex: 1,
    ),

    // Consistency
    Achievement(
      id: 'first_run',
      name: 'El Inicio',
      description: 'Completa tu primera carrera',
      icon: 'play_arrow',
      xpReward: 50,
      categoryIndex: 2,
    ),
    Achievement(
      id: 'streak_3',
      name: 'Racha de 3',
      description: 'Corre 3 dias consecutivos',
      icon: 'local_fire_department',
      xpReward: 75,
      categoryIndex: 2,
    ),
    Achievement(
      id: 'streak_7',
      name: 'Semana Perfecta',
      description: 'Corre 7 dias consecutivos',
      icon: 'fitness_center',
      xpReward: 200,
      categoryIndex: 2,
    ),
    Achievement(
      id: 'ten_runs',
      name: 'Dedicacion',
      description: 'Completa 10 carreras',
      icon: 'military_tech',
      xpReward: 150,
      categoryIndex: 2,
    ),

    // Speed
    Achievement(
      id: 'pace_6',
      name: 'Velocista',
      description: 'Manten un pace menor a 6:00/km',
      icon: 'bolt',
      xpReward: 100,
      categoryIndex: 3,
    ),
    Achievement(
      id: 'pace_5',
      name: 'Rayo',
      description: 'Manten un pace menor a 5:00/km',
      icon: 'speed',
      xpReward: 200,
      categoryIndex: 3,
    ),

    // Secrets
    Achievement(
      id: 'pi_run',
      name: 'Matematico',
      description: 'Corre exactamente 3.14 km',
      icon: 'calculate',
      xpReward: 100,
      categoryIndex: 4,
    ),
    Achievement(
      id: 'early_bird',
      name: 'Madrugador',
      description: 'Corre antes de las 6:00 AM',
      icon: 'wb_twilight',
      xpReward: 75,
      categoryIndex: 4,
    ),
  ];

  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
