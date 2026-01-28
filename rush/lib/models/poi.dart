import 'package:hive/hive.dart';

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
// NOTA: Estas coordenadas son aproximadas - ajustar con coordenadas reales
class CampusPois {
  static const List<Poi> all = [
    // Academic
    Poi(
      id: 'biblioteca',
      name: 'Biblioteca',
      description: 'Centro de conocimiento del campus',
      latitude: 25.1933,
      longitude: -99.8267,
      categoryIndex: 0,
      xpReward: 30,
      icon: '📚',
    ),
    Poi(
      id: 'facultad_ingenieria',
      name: 'Facultad de Ingeniería',
      description: 'Donde nacen los innovadores',
      latitude: 25.1940,
      longitude: -99.8275,
      categoryIndex: 0,
      xpReward: 30,
      icon: '💻',
    ),
    Poi(
      id: 'facultad_salud',
      name: 'Facultad de Ciencias de la Salud',
      description: 'Formando profesionales de la salud',
      latitude: 25.1928,
      longitude: -99.8260,
      categoryIndex: 0,
      xpReward: 30,
      icon: '🏥',
    ),

    // Sports
    Poi(
      id: 'gimnasio',
      name: 'Gimnasio',
      description: 'Centro deportivo principal',
      latitude: 25.1945,
      longitude: -99.8280,
      categoryIndex: 1,
      xpReward: 25,
      icon: '🏋️',
    ),
    Poi(
      id: 'pista',
      name: 'Pista de Atletismo',
      description: 'Donde los campeones entrenan',
      latitude: 25.1950,
      longitude: -99.8285,
      categoryIndex: 1,
      xpReward: 25,
      icon: '🏟️',
    ),
    Poi(
      id: 'canchas',
      name: 'Canchas Deportivas',
      description: 'Múltiples canchas para diferentes deportes',
      latitude: 25.1948,
      longitude: -99.8290,
      categoryIndex: 1,
      xpReward: 25,
      icon: '🏀',
    ),

    // Landmarks
    Poi(
      id: 'capilla',
      name: 'Capilla',
      description: 'Centro espiritual del campus',
      latitude: 25.1935,
      longitude: -99.8270,
      categoryIndex: 2,
      xpReward: 35,
      icon: '⛪',
    ),
    Poi(
      id: 'cafeteria',
      name: 'Cafetería Central',
      description: 'El punto de encuentro favorito',
      latitude: 25.1938,
      longitude: -99.8265,
      categoryIndex: 2,
      xpReward: 20,
      icon: '🍽️',
    ),
    Poi(
      id: 'lago',
      name: 'Lago',
      description: 'Oasis de tranquilidad',
      latitude: 25.1925,
      longitude: -99.8272,
      categoryIndex: 2,
      xpReward: 40,
      icon: '🌊',
    ),
    Poi(
      id: 'entrada_principal',
      name: 'Entrada Principal',
      description: 'La puerta al conocimiento',
      latitude: 25.1920,
      longitude: -99.8255,
      categoryIndex: 2,
      xpReward: 20,
      icon: '🚪',
    ),
  ];

  static Poi? getById(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
