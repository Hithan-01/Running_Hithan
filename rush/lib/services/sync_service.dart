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

  /// Inicializa el documento de un usuario nuevo en Firestore (registro).
  /// Sobreescribe cualquier dato previo para ese UID.
  Future<void> initNewUser(String uid, String name) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'xp': 0,
        'totalDistance': 0.0,
        'totalRuns': 0,
      });
    } catch (e) {
      debugPrint('❌ Error inicializando usuario en Firestore: $e');
    }
  }

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
          transaction.set(userRef, {
            'name': run.userName,
            'totalDistance': run.distanceKm,
            'totalRuns': 1,
            'lastRun': Timestamp.fromDate(run.endTime),
            'xp': (run.distanceKm * 100).round(),
          });
        } else {
          final currentDist =
              (userDoc.data()?['totalDistance'] as num?)?.toDouble() ?? 0;
          final currentRuns = (userDoc.data()?['totalRuns'] as int?) ?? 0;
          final currentXP = (userDoc.data()?['xp'] as int?) ?? 0;

          transaction.update(userRef, {
            'name': run.userName,
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
  Future<int> syncPendingRuns(String userId, String oderId, {String userName = ''}) async {
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
        userName: run.oderId, // fallback; overridden when name is available
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

  /// Fetch leaderboard entries.
  /// [since] = null → all time; otherwise filters by startTime >= since
  Future<List<Map<String, dynamic>>> fetchLeaderboard({DateTime? since}) async {
    try {
      if (since == null) {
        // All time: query users collection
        final snap = await _firestore
            .collection('users')
            .orderBy('xp', descending: true)
            .limit(20)
            .get();
        return snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .where((d) {
              final name = d['name'] as String? ?? '';
              return name.isNotEmpty && name != 'Sin nombre';
            })
            .toList();
      } else {
        // Period: aggregate runs since the given date
        final snap = await _firestore
            .collection('runs')
            .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
            .get();

        final Map<String, Map<String, dynamic>> agg = {};
        for (final doc in snap.docs) {
          final data = doc.data();
          final uid = data['userId'] as String? ?? '';
          final name = data['userName'] as String? ?? '';
          final dist = (data['distanceKm'] as num?)?.toDouble() ?? 0;
          if (uid.isEmpty) continue;
          if (!agg.containsKey(uid)) {
            agg[uid] = {'id': uid, 'name': name, 'totalDistance': 0.0, 'totalRuns': 0, 'xp': 0};
          }
          agg[uid]!['totalDistance'] = (agg[uid]!['totalDistance'] as double) + dist;
          agg[uid]!['totalRuns'] = (agg[uid]!['totalRuns'] as int) + 1;
          agg[uid]!['xp'] = (agg[uid]!['xp'] as int) + (dist * 100).round();
        }
        // Fetch cosmetics from users collection for each unique user
        if (agg.isNotEmpty) {
          try {
            final uids = agg.keys.toList();
            final userDocs = await _firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: uids.take(10).toList())
                .get();
            for (final doc in userDocs.docs) {
              if (agg.containsKey(doc.id)) {
                final d = doc.data();
                if (d['equippedAvatarColorId'] != null) {
                  agg[doc.id]!['equippedAvatarColorId'] = d['equippedAvatarColorId'];
                }
                if (d['equippedAvatarFrameId'] != null) {
                  agg[doc.id]!['equippedAvatarFrameId'] = d['equippedAvatarFrameId'];
                }
              }
            }
          } catch (_) {}
        }
        final result = agg.values.toList()
          ..sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));
        return result;
      }
    } catch (e) {
      debugPrint('❌ Error fetching leaderboard: $e');
      return [];
    }
  }

  /// Guarda los cosméticos equipados del usuario en Firestore.
  Future<void> updateUserCosmetics(
    String userId, {
    String? avatarColorId,
    String? avatarFrameId,
    String? routeColorId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (avatarColorId != null) data['equippedAvatarColorId'] = avatarColorId;
      if (avatarFrameId != null) data['equippedAvatarFrameId'] = avatarFrameId;
      if (routeColorId != null) data['equippedRouteColorId'] = routeColorId;
      if (data.isEmpty) return;
      await _firestore
          .collection('users')
          .doc(userId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Error guardando cosméticos: $e');
    }
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
