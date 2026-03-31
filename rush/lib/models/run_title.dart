// RunTitle — coleccionable que el usuario equipa y se muestra en el leaderboard/perfil.
// El catálogo es estático; solo equippedTitleId se persiste en User.

enum TitleUnlockType { always, level, achievement }

class RunTitle {
  final String id;
  final String name;         // Texto mostrado en UI
  final String description;  // Cómo se desbloquea
  final String emoji;        // Ícono decorativo
  final TitleUnlockType unlockType;
  final int? requiredLevel;           // para unlockType.level
  final String? requiredAchievementId; // para unlockType.achievement

  const RunTitle({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.unlockType,
    this.requiredLevel,
    this.requiredAchievementId,
  });
}

class RunTitles {
  static const List<RunTitle> all = [
    // ── Siempre disponible ────────────────────────────────────────────────────
    RunTitle(
      id: 'runner',
      name: 'Corredor',
      description: 'Título inicial de todo corredor',
      emoji: '🏃',
      unlockType: TitleUnlockType.always,
    ),

    // ── Por nivel ─────────────────────────────────────────────────────────────
    RunTitle(
      id: 'campus_jogger',
      name: 'Trotador del Campus',
      description: 'Alcanza el nivel 2',
      emoji: '👟',
      unlockType: TitleUnlockType.level,
      requiredLevel: 2,
    ),
    RunTitle(
      id: 'fitness_explorer',
      name: 'Explorador Fitness',
      description: 'Alcanza el nivel 3',
      emoji: '🗺️',
      unlockType: TitleUnlockType.level,
      requiredLevel: 3,
    ),
    RunTitle(
      id: 'trail_master',
      name: 'Trail Master',
      description: 'Alcanza el nivel 4',
      emoji: '⛰️',
      unlockType: TitleUnlockType.level,
      requiredLevel: 4,
    ),
    RunTitle(
      id: 'um_athlete',
      name: 'Atleta UM',
      description: 'Alcanza el nivel 5',
      emoji: '🎽',
      unlockType: TitleUnlockType.level,
      requiredLevel: 5,
    ),
    RunTitle(
      id: 'campus_legend',
      name: 'Leyenda del Campus',
      description: 'Alcanza el nivel máximo',
      emoji: '👑',
      unlockType: TitleUnlockType.level,
      requiredLevel: 6,
    ),

    // ── Por logro ─────────────────────────────────────────────────────────────
    RunTitle(
      id: 'explorer',
      name: 'Explorador',
      description: 'Visita 5 POIs diferentes',
      emoji: '🔍',
      unlockType: TitleUnlockType.achievement,
      requiredAchievementId: 'five_pois',
    ),
    RunTitle(
      id: 'cartographer',
      name: 'Cartógrafo',
      description: 'Visita todos los POIs del campus',
      emoji: '🗾',
      unlockType: TitleUnlockType.achievement,
      requiredAchievementId: 'all_pois',
    ),
    RunTitle(
      id: 'fondist',
      name: 'Fondista',
      description: 'Corre 10 km en una carrera',
      emoji: '📏',
      unlockType: TitleUnlockType.achievement,
      requiredAchievementId: 'ten_km',
    ),
    RunTitle(
      id: 'unstoppable',
      name: 'Incansable',
      description: 'Mantén una racha de 7 días',
      emoji: '🔥',
      unlockType: TitleUnlockType.achievement,
      requiredAchievementId: 'streak_7',
    ),
    RunTitle(
      id: 'lightning',
      name: 'El Rayo',
      description: 'Manten un pace menor a 5:00/km',
      emoji: '⚡',
      unlockType: TitleUnlockType.achievement,
      requiredAchievementId: 'pace_5',
    ),
    RunTitle(
      id: 'speed_demon',
      name: 'Demonio de Velocidad',
      description: 'Manten un pace menor a 4:00/km',
      emoji: '💨',
      unlockType: TitleUnlockType.achievement,
      requiredAchievementId: 'speed_demon',
    ),
    RunTitle(
      id: 'pi_runner',
      name: 'π Runner',
      description: 'Corre exactamente 3.14 km',
      emoji: '🔢',
      unlockType: TitleUnlockType.achievement,
      requiredAchievementId: 'pi_run',
    ),
    RunTitle(
      id: 'ghost',
      name: 'El Fantasma',
      description: 'Corre a las 3 AM',
      emoji: '👻',
      unlockType: TitleUnlockType.achievement,
      requiredAchievementId: 'three_am',
    ),
    RunTitle(
      id: 'mission_master',
      name: 'Maestro de Misiones',
      description: 'Completa 50 misiones',
      emoji: '🎯',
      unlockType: TitleUnlockType.achievement,
      requiredAchievementId: 'fifty_missions',
    ),
  ];

  static RunTitle? getById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
