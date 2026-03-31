import 'package:hive_ce/hive.dart';

part 'poi.g.dart';

enum PoiCategory {
  academic,
  sports,
  landmark,
}

@HiveType(typeId: 5)
class Poi {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final double latitude;

  @HiveField(4)
  final double longitude;

  @HiveField(5)
  final int categoryIndex;

  @HiveField(6)
  final int xpReward;

  @HiveField(7)
  final String icon;

  PoiCategory get category => PoiCategory.values[categoryIndex];

  // Radius in meters to consider POI as visited
  static const double visitRadius = 30.0;

  const Poi({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.categoryIndex,
    required this.xpReward,
    required this.icon,
  });
}

@HiveType(typeId: 6)
class VisitedPoi extends HiveObject {
  @HiveField(0)
  String oderId;

  @HiveField(1)
  String poiId;

  @HiveField(2)
  DateTime visitedAt;

  VisitedPoi({
    required this.oderId,
    required this.poiId,
    required this.visitedAt,
  });
}

// POIs del campus de la Universidad de Montemorelos
class CampusPois {
  static const List<Poi> all = [
    // ── Académico ────────────────────────────────────────────────────────────
    Poi(id: 'biblioteca', name: 'Biblioteca',
      description: 'Centro de conocimiento del campus',
      latitude: 25.193333, longitude: -99.844389,
      categoryIndex: 0, xpReward: 30, icon: '📚'),
    Poi(id: 'fitec_lab', name: 'Laboratorio FITEC',
      description: 'Centro de investigación tecnológica',
      latitude: 25.193624, longitude: -99.847332,
      categoryIndex: 0, xpReward: 30, icon: '🔬'),
    Poi(id: 'fitec', name: 'FITEC',
      description: 'Facultad de Ingeniería y Tecnología',
      latitude: 25.190638, longitude: -99.846515,
      categoryIndex: 0, xpReward: 30, icon: '⚙️'),
    Poi(id: 'sistemas', name: 'Sistemas',
      description: 'Facultad de Sistemas',
      latitude: 25.191779, longitude: -99.844708,
      categoryIndex: 0, xpReward: 30, icon: '💻'),
    Poi(id: 'fateo', name: 'FATEO',
      description: 'Facultad de Teología',
      latitude: 25.192068, longitude: -99.844211,
      categoryIndex: 0, xpReward: 30, icon: '✝️'),
    Poi(id: 'facsa', name: 'FACSA',
      description: 'Facultad de Ciencias de la Salud',
      latitude: 25.193093, longitude: -99.843808,
      categoryIndex: 0, xpReward: 30, icon: '🏥'),
    Poi(id: 'artcom', name: 'ARTCOM',
      description: 'Arte y Comunicación',
      latitude: 25.194248, longitude: -99.844920,
      categoryIndex: 0, xpReward: 30, icon: '🎨'),
    Poi(id: 'escest_qcb', name: 'ESCEST y QCB',
      description: 'Estadística y Química Clínica',
      latitude: 25.193855, longitude: -99.842915,
      categoryIndex: 0, xpReward: 30, icon: '🧪'),
    Poi(id: 'idiomas', name: 'Idiomas',
      description: 'Centro de idiomas',
      latitude: 25.190294, longitude: -99.846212,
      categoryIndex: 0, xpReward: 25, icon: '🌐'),
    Poi(id: 'psicologia', name: 'Psicología',
      description: 'Facultad de Psicología',
      latitude: 25.190371, longitude: -99.847089,
      categoryIndex: 0, xpReward: 30, icon: '🧠'),
    Poi(id: 'um_virtual', name: 'UM Virtual',
      description: 'Campus virtual de la UM',
      latitude: 25.190643, longitude: -99.846859,
      categoryIndex: 0, xpReward: 25, icon: '🖥️'),
    Poi(id: 'faced', name: 'FACED',
      description: 'Facultad de Educación',
      latitude: 25.190444, longitude: -99.846833,
      categoryIndex: 0, xpReward: 30, icon: '📖'),
    Poi(id: 'prepa', name: 'Preparatoria',
      description: 'Escuela preparatoria UM',
      latitude: 25.192146, longitude: -99.846929,
      categoryIndex: 0, xpReward: 25, icon: '🎒'),

    // ── Deportes ─────────────────────────────────────────────────────────────
    Poi(id: 'gym', name: 'Gym',
      description: 'Gimnasio del campus',
      latitude: 25.193222, longitude: -99.846334,
      categoryIndex: 1, xpReward: 25, icon: '🏋️'),
    Poi(id: 'cancha_principal', name: 'Cancha Principal',
      description: 'Cancha principal del campus',
      latitude: 25.195022, longitude: -99.844113,
      categoryIndex: 1, xpReward: 25, icon: '🏀'),
    Poi(id: 'canchas_tenis', name: 'Canchas de Tenis',
      description: 'Canchas de tenis',
      latitude: 25.194750, longitude: -99.843529,
      categoryIndex: 1, xpReward: 25, icon: '🎾'),
    Poi(id: 'campo_softball', name: 'Campo de Softball',
      description: 'Campo de softball',
      latitude: 25.193708, longitude: -99.843529,
      categoryIndex: 1, xpReward: 25, icon: '⚾'),
    Poi(id: 'cancha_carlota', name: 'Cancha la Carlota',
      description: 'Cancha deportiva',
      latitude: 25.194228, longitude: -99.840565,
      categoryIndex: 1, xpReward: 30, icon: '🏐'),

    // ── Servicios / Landmarks ────────────────────────────────────────────────
    Poi(id: 'cajeros', name: 'Cajeros',
      description: 'Cajeros automáticos',
      latitude: 25.193580, longitude: -99.844871,
      categoryIndex: 2, xpReward: 15, icon: '🏧'),
    Poi(id: 'planta_fisica', name: 'Planta Física',
      description: 'Departamento de Planta Física',
      latitude: 25.194020, longitude: -99.846055,
      categoryIndex: 2, xpReward: 20, icon: '🏗️'),
    Poi(id: 'garden', name: 'Garden',
      description: 'Área verde del campus',
      latitude: 25.193930, longitude: -99.846439,
      categoryIndex: 2, xpReward: 20, icon: '🌿'),
    Poi(id: 'carpinteria', name: 'Carpintería',
      description: 'Taller de carpintería',
      latitude: 25.193471, longitude: -99.847490,
      categoryIndex: 2, xpReward: 20, icon: '🪵'),
    Poi(id: 'correos', name: 'Correos',
      description: 'Servicio de correos del campus',
      latitude: 25.193267, longitude: -99.848095,
      categoryIndex: 2, xpReward: 20, icon: '📮'),
    Poi(id: 'soymart', name: 'Soymart',
      description: 'Tienda del campus',
      latitude: 25.193243, longitude: -99.848302,
      categoryIndex: 2, xpReward: 15, icon: '🛒'),
    Poi(id: 'casa_rector', name: 'Casa del Rector',
      description: 'Residencia del rector',
      latitude: 25.191925, longitude: -99.848535,
      categoryIndex: 2, xpReward: 35, icon: '🏠'),
    Poi(id: 'dormitorio_1', name: 'Dormitorio 1',
      description: 'Residencia estudiantil 1',
      latitude: 25.192189, longitude: -99.847688,
      categoryIndex: 2, xpReward: 15, icon: '🛏️'),
    Poi(id: 'dormitorio_2', name: 'Dormitorio 2',
      description: 'Residencia estudiantil 2',
      latitude: 25.191709, longitude: -99.846223,
      categoryIndex: 2, xpReward: 15, icon: '🛏️'),
    Poi(id: 'dormitorio_3', name: 'Dormitorio 3',
      description: 'Residencia estudiantil 3',
      latitude: 25.193639, longitude: -99.845556,
      categoryIndex: 2, xpReward: 15, icon: '🛏️'),
    Poi(id: 'dormitorio_4', name: 'Dormitorio 4',
      description: 'Residencia estudiantil 4',
      latitude: 25.192742, longitude: -99.845719,
      categoryIndex: 2, xpReward: 15, icon: '🛏️'),
    Poi(id: 'coae', name: 'COAE',
      description: 'Centro de Orientación y Apoyo Estudiantil',
      latitude: 25.190677, longitude: -99.847588,
      categoryIndex: 2, xpReward: 20, icon: '🤝'),
    Poi(id: 'museo_um', name: 'Museo UM',
      description: 'Museo de la Universidad de Montemorelos',
      latitude: 25.191141, longitude: -99.846223,
      categoryIndex: 2, xpReward: 35, icon: '🏛️'),
    Poi(id: 'vicerrectoria', name: 'Vicerrectoría',
      description: 'Oficinas de la Vicerrectoría',
      latitude: 25.191862, longitude: -99.845571,
      categoryIndex: 2, xpReward: 25, icon: '🏢'),
    Poi(id: 'arco_principal', name: 'Arco Principal',
      description: 'Entrada principal al campus',
      latitude: 25.191983, longitude: -99.843508,
      categoryIndex: 2, xpReward: 20, icon: '🚪'),
    Poi(id: 'rectoria', name: 'Rectoría',
      description: 'Sede de la Rectoría de la UM',
      latitude: 25.192624, longitude: -99.843905,
      categoryIndex: 2, xpReward: 30, icon: '🏛️'),
    Poi(id: 'plaza_5_mayo', name: 'Plaza 5 de Mayo',
      description: 'Plaza central del campus',
      latitude: 25.193067, longitude: -99.845024,
      categoryIndex: 2, xpReward: 20, icon: '⛲'),
    Poi(id: 'comedor', name: 'Comedor',
      description: 'Comedor universitario',
      latitude: 25.193091, longitude: -99.845475,
      categoryIndex: 2, xpReward: 20, icon: '🍽️'),
    Poi(id: 'jardines_rectoria', name: 'Jardines Rectoría',
      description: 'Jardines de la Rectoría',
      latitude: 25.192834, longitude: -99.844593,
      categoryIndex: 2, xpReward: 20, icon: '🌺'),
    Poi(id: 'casa_andrei', name: 'Casa de Andrei',
      description: 'Residencia de Andrei',
      latitude: 25.193467, longitude: -99.842942,
      categoryIndex: 2, xpReward: 25, icon: '🏡'),
  ];

  static Poi? getById(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
