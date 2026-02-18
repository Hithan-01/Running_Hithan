import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/location_service.dart';
import '../services/gamification_service.dart';
import '../models/poi.dart';
import '../widgets/run_stats_panel.dart';
import '../widgets/poi_marker.dart';
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
  Poi? _selectedPoi;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final locationService = context.read<LocationService>();
    await locationService.getCurrentPosition();
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

              // POI info card
              if (_selectedPoi != null) _buildPoiInfoOverlay(gamification),

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

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: AppConstants.defaultZoom,
        onTap: (_, __) {
          setState(() {
            _selectedPoi = null;
          });
        },
      ),
      children: [
        // OpenStreetMap tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.aerdr.rush',
          maxZoom: 19,
        ),

        // Route polyline
        if (location.isTracking && location.routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: location.routePoints
                    .map((p) => LatLng(p.latitude, p.longitude))
                    .toList(),
                color: AppColors.accent,
                strokeWidth: 5,
              ),
            ],
          ),

        // Current location marker
        if (currentPos != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(currentPos.latitude, currentPos.longitude),
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(100),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

        // POI markers
        MarkerLayer(markers: _buildPoiMarkers(gamification)),
      ],
    );
  }

  List<Marker> _buildPoiMarkers(GamificationService gamification) {
    return CampusPois.all.map((poi) {
      final isVisited = gamification.isPoiVisited(poi.id);

      return Marker(
        point: LatLng(poi.latitude, poi.longitude),
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedPoi = poi;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isVisited ? AppColors.success : AppColors.secondary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(poi.icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
        ),
      );
    }).toList();
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

  Widget _buildPoiInfoOverlay(GamificationService gamification) {
    return Positioned(
      bottom: 140,
      left: 16,
      right: 16,
      child: PoiInfoCard(
        poi: _selectedPoi!,
        isVisited: gamification.isPoiVisited(_selectedPoi!.id),
        onClose: () {
          setState(() {
            _selectedPoi = null;
          });
        },
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
