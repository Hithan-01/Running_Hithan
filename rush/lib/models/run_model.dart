import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

class RunModel {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final int durationSeconds;
  final List<LatLng> routePoints;
  final bool isSynced;

  RunModel({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.durationSeconds,
    required this.routePoints,
    this.isSynced = false,
  });

  // Crear una nueva carrera
  factory RunModel.create({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    required double distanceKm,
    required List<LatLng> routePoints,
  }) {
    return RunModel(
      id: const Uuid().v4(),
      userId: userId,
      startTime: startTime,
      endTime: endTime,
      distanceKm: distanceKm,
      durationSeconds: endTime.difference(startTime).inSeconds,
      routePoints: routePoints,
      isSynced: false,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'distanceKm': distanceKm,
      'durationSeconds': durationSeconds,
      // Firestore no soporta listas de objetos complejos fácilmente,
      // guardamos los puntos como lista de GeoPoints
      'route': routePoints
          .map((p) => GeoPoint(p.latitude, p.longitude))
          .toList(),
    };
  }

  // Crear desde Firestore
  factory RunModel.fromMap(Map<String, dynamic> map) {
    return RunModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      distanceKm: (map['distanceKm'] as num).toDouble(),
      durationSeconds: map['durationSeconds'] as int,
      routePoints:
          (map['route'] as List?)
              ?.map((p) => LatLng((p as GeoPoint).latitude, p.longitude))
              .toList() ??
          [],
      isSynced: true, // Si viene de Firestore, ya está sincronizada
    );
  }
}
