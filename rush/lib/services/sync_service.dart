import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/run_model.dart';
import 'database_service.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  /// Sube una carrera a Firestore y retorna true si fue exitosa
  Future<bool> uploadRun(RunModel run, {String? localRunId}) async {
    // 1. Checar conectividad
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      debugPrint('⚠️ Sin internet. Carrera guardada localmente (${run.id}).');
      return false; // Se queda solo en local (Hive)
    }

    try {
      debugPrint('📤 Subiendo carrera ${run.id} a Firestore...');

      // 2. Referencia al documento: runs/{runId}
      await _firestore.collection('runs').doc(run.id).set(run.toMap());

      // 3. Actualizar stats del usuario (Total KM, XP)
      // Usamos una transacción para que sea atómico
      final userRef = _firestore.collection('users').doc(run.userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          // Si no existe, lo creamos
          transaction.set(userRef, {
            'totalDistance': run.distanceKm,
            'totalRuns': 1,
            'lastRun': Timestamp.fromDate(run.endTime),
            'xp': (run.distanceKm * 100).round(), // 1km = 100XP
          });
        } else {
          // Si existe, actualizamos
          final currentDist =
              (userDoc.data()?['totalDistance'] as num?)?.toDouble() ?? 0;
          final currentRuns = (userDoc.data()?['totalRuns'] as int?) ?? 0;
          final currentXP = (userDoc.data()?['xp'] as int?) ?? 0;

          transaction.update(userRef, {
            'totalDistance': currentDist + run.distanceKm,
            'totalRuns': currentRuns + 1,
            'lastRun': Timestamp.fromDate(run.endTime),
            'xp': currentXP + (run.distanceKm * 100).round(),
          });
        }
      });

      // 4. Marcar como sincronizada en Hive si tenemos el ID local
      if (localRunId != null) {
        await DatabaseService.markRunAsSynced(localRunId);
      }

      debugPrint('✅ Carrera sincronizada exitosamente: ${run.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Error sincronizando carrera: $e');
      return false; // Marca como no sincronizada para reintentar después
    }
  }

  /// Sincroniza todas las carreras pendientes de un usuario
  Future<int> syncPendingRuns(String userId, String oderId) async {
    // Obtener carreras no sincronizadas
    final unsyncedRuns = DatabaseService.getUnsyncedRuns(oderId);

    if (unsyncedRuns.isEmpty) {
      debugPrint('✅ No hay carreras pendientes por sincronizar');
      return 0;
    }

    debugPrint('🔄 Sincronizando ${unsyncedRuns.length} carreras pendientes...');

    int syncedCount = 0;
    for (final run in unsyncedRuns) {
      // Convertir Run de Hive a RunModel de Firebase
      final runModel = RunModel(
        id: run.id,
        userId: userId,
        startTime: run.createdAt,
        endTime: run.createdAt.add(Duration(seconds: run.duration)),
        distanceKm: run.distanceKm,
        durationSeconds: run.duration,
        routePoints: run.route
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(),
        isSynced: false,
      );

      // Intentar subir
      final success = await uploadRun(runModel, localRunId: run.id);
      if (success) {
        syncedCount++;
      }
    }

    debugPrint('✅ Se sincronizaron $syncedCount de ${unsyncedRuns.length} carreras');
    return syncedCount;
  }

  /// Descarga stats del usuario (para cuando inicias sesión en otro cel)
  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error obteniendo stats: $e');
      return null;
    }
  }
}
