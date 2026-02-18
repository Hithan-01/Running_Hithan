import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/location_service.dart';
import '../services/gamification_service.dart';
import '../widgets/run_stats_panel.dart';
import '../utils/constants.dart';
import 'run_summary_screen.dart';
import '../models/run_model.dart';
import '../services/sync_service.dart';
import '../services/audio_coach_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _isStarting = false;
  bool _followUser = true; // auto-follow during tracking

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final locationService = context.read<LocationService>();
    final pos = await locationService.getCurrentPosition();
    if (pos != null) {
      _mapController.move(
        LatLng(pos.latitude, pos.longitude),
        AppConstants.defaultZoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocationService, GamificationService>(
      builder: (context, location, gamification, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Map — full screen
              _buildMap(location, gamification),

              // Top bar (back button only)
              _buildTopBar(location),

              // Stats panel (when tracking)
              if (location.isTracking) _buildStatsOverlay(location),

              // My location FAB — bottom right
              _buildMyLocationButton(),

              // Bottom controls
              _buildBottomControls(location, gamification),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(LocationService location, GamificationService gamification) {
    final currentPos = location.currentPosition;
    final center = currentPos != null
        ? LatLng(currentPos.latitude, currentPos.longitude)
        : const LatLng(
            AppConstants.defaultLatitude,
            AppConstants.defaultLongitude,
          );

    // Auto-follow user during tracking
    if (location.isTracking && _followUser && currentPos != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          LatLng(currentPos.latitude, currentPos.longitude),
          _mapController.camera.zoom,
        );
      });
    }

    // Campus bounds — lock camera to university area
    final campusBounds = LatLngBounds(
      const LatLng(AppConstants.campusSWLat, AppConstants.campusSWLon),
      const LatLng(AppConstants.campusNELat, AppConstants.campusNELon),
    );

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: AppConstants.defaultZoom,
        minZoom: 15.5,
        maxZoom: 19,
        cameraConstraint: CameraConstraint.contain(bounds: campusBounds),
        onTap: (_, __) {},
        onPositionChanged: (pos, hasGesture) {
          // If user manually drags the map, stop auto-follow
          if (hasGesture) {
            _followUser = false;
          }
        },
      ),
      children: [
        // CartoDB Voyager — buildings, parks, colored landmarks
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.aerdr.rush',
          maxZoom: 19,
          retinaMode: true,
        ),

        // Route polyline
        if (location.isTracking && location.routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: location.routePoints
                    .map((p) => LatLng(p.latitude, p.longitude))
                    .toList(),
                color: AppColors.primary,
                strokeWidth: 6,
                borderColor: AppColors.primary.withAlpha(60),
                borderStrokeWidth: 3,
              ),
            ],
          ),

        // Current location marker with direction arrow
        if (currentPos != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(currentPos.latitude, currentPos.longitude),
                width: 44,
                height: 44,
                child: _buildLocationMarker(location),
              ),
            ],
          ),

        // POI markers hidden — detection still works via LocationService
      ],
    );
  }

  /// Computes heading in radians from the last two route points.
  double? _computeHeading(LocationService location) {
    final points = location.routePoints;
    if (points.length < 2) return null;
    final p1 = points[points.length - 2];
    final p2 = points.last;
    final dLon = (p2.longitude - p1.longitude) * math.pi / 180;
    final lat1 = p1.latitude * math.pi / 180;
    final lat2 = p2.latitude * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return math.atan2(y, x); // radians, 0 = north
  }

  Widget _buildLocationMarker(LocationService location) {
    final heading = _computeHeading(location);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing glow ring
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withAlpha(40),
          ),
        ),
        // Arrow — rotates with heading, points up by default
        Transform.rotate(
          angle: heading ?? 0,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(120),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(LocationService location) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Back button (only when not tracking AND screen was pushed as route)
          if (!location.isTracking && Navigator.of(context).canPop())
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return Positioned(
      bottom: 200,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: _centerOnLocation,
          icon: const Icon(Icons.my_location, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  void _centerOnLocation() async {
    final location = context.read<LocationService>();
    final pos = location.currentPosition ?? await location.getCurrentPosition();
    if (pos != null) {
      _followUser = true; // re-enable auto-follow
      _mapController.move(
        LatLng(pos.latitude, pos.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  Widget _buildStatsOverlay(LocationService location) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 16,
      right: 16,
      child: RunStatsPanel(
        distance: location.distance,
        duration: location.duration,
        pace: location.avgPace,
        isLive: true,
        compact: true,
        darkMode: true,
      ),
    );
  }


  Widget _buildBottomControls(
    LocationService location,
    GamificationService gamification,
  ) {
    if (location.isTracking) {
      return _buildTrackingControls(location, gamification);
    }
    return _buildStartControls(location, gamification);
  }

  Widget _buildStartControls(LocationService location, GamificationService gamification) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large circular START button
          GestureDetector(
            onTap: _isStarting ? null : () => _startRun(location),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryLight,
                    AppColors.accent,
                    AppColors.primaryDark,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withAlpha(120),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isStarting
                  ? const Center(
                      child: SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startRun(LocationService location) async {
    setState(() => _isStarting = true);

    final started = await location.startTracking();

    if (started) {
      AudioCoachService.countdown();
    }

    setState(() => _isStarting = false);

    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo acceder a la ubicación'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildTrackingControls(
    LocationService location,
    GamificationService gamification,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.navBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Pause/Resume button
            _buildControlButton(
              icon: location.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              label: location.isPaused ? 'Reanudar' : 'Pausar',
              color: AppColors.warning,
              onPressed: () {
                if (location.isPaused) {
                  location.resumeTracking();
                } else {
                  location.pauseTracking();
                }
              },
            ),

            // Stop button
            _buildControlButton(
              icon: Icons.stop_rounded,
              label: 'Terminar',
              color: AppColors.error,
              onPressed: () => _stopRun(location, gamification),
              isLarge: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    final size = isLarge ? 64.0 : 52.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: isLarge ? 32 : 26),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Future<void> _stopRun(
    LocationService location,
    GamificationService gamification,
  ) async {
    // Confirm stop
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('¿Terminar carrera?'),
        content: const Text('¿Quieres guardar esta carrera?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = gamification.user;
    if (user == null) return;

    // Stop tracking and get run data
    final runId = const Uuid().v4();
    final run = location.stopTracking(user.id, runId);

    if (run == null || run.distance < 50) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Carrera muy corta para guardar'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    // Announce run complete via TTS
    AudioCoachService.runComplete(run.distanceKm);

    // Process run with gamification
    final result = await gamification.processRun(run);

    // Sync to Firebase
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final endTime = run.createdAt.add(Duration(seconds: run.duration));

        final runModel = RunModel.create(
          userId: firebaseUser.uid,
          startTime: run.createdAt,
          endTime: endTime,
          distanceKm: run.distance / 1000.0,
          routePoints: run.route
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList(),
        );

        // Upload via SyncService with local run ID for marking as synced
        final synced = await SyncService().uploadRun(runModel, localRunId: run.id);
        if (synced) {
          debugPrint('✅ Carrera sincronizada inmediatamente');
        } else {
          debugPrint('⏳ Carrera se sincronizará cuando haya internet');
        }
      }
    } catch (e) {
      debugPrint("❌ Error syncing run: $e");
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RunSummaryScreen(run: run, result: result),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
