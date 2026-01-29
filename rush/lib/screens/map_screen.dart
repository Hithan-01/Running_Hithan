import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/location_service.dart';
import '../services/gamification_service.dart';
import '../models/poi.dart';
import '../widgets/run_stats_panel.dart';
import '../widgets/poi_marker.dart';
import '../utils/constants.dart';
import 'run_summary_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
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
              // Map
              _buildMap(location, gamification),

              // Top bar with back button
              _buildTopBar(location),

              // Stats panel (when tracking)
              if (location.isTracking) _buildStatsOverlay(location),

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
    final initialPos = currentPos != null
        ? LatLng(currentPos.latitude, currentPos.longitude)
        : const LatLng(
            AppConstants.defaultLatitude,
            AppConstants.defaultLongitude,
          );

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPos,
        zoom: AppConstants.defaultZoom,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        _setMapStyle(controller);
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      markers: _buildMarkers(gamification),
      polylines: _buildPolylines(location),
      onTap: (_) {
        setState(() {
          _selectedPoi = null;
        });
      },
    );
  }

  Future<void> _setMapStyle(GoogleMapController controller) async {
    // Dark map style
    const String darkMapStyle = '''
    [
      {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
      {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
      {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#255763"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1626"}]}
    ]
    ''';
    await controller.setMapStyle(darkMapStyle);
  }

  Set<Marker> _buildMarkers(GamificationService gamification) {
    final markers = <Marker>{};

    for (final poi in CampusPois.all) {
      final isVisited = gamification.isPoiVisited(poi.id);

      markers.add(
        Marker(
          markerId: MarkerId(poi.id),
          position: LatLng(poi.latitude, poi.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isVisited ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueViolet,
          ),
          onTap: () {
            setState(() {
              _selectedPoi = poi;
            });
          },
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(LocationService location) {
    if (!location.isTracking || location.routePoints.isEmpty) {
      return {};
    }

    final points = location.routePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: AppColors.accent,
        width: 5,
      ),
    };
  }

  Widget _buildTopBar(LocationService location) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Center on location button
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _centerOnLocation,
              icon: const Icon(Icons.my_location, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _centerOnLocation() async {
    final location = context.read<LocationService>();
    final pos = location.currentPosition ?? await location.getCurrentPosition();
    if (pos != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
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
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: location.isTracking
            ? _buildTrackingControls(location, gamification)
            : _buildStartControls(location),
      ),
    );
  }

  Widget _buildStartControls(LocationService location) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Listo para correr?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Visita POIs en el campus para ganar XP extra',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isStarting ? null : () => _startRun(location),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isStarting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'INICIAR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _startRun(LocationService location) async {
    setState(() => _isStarting = true);

    final started = await location.startTracking();

    setState(() => _isStarting = false);

    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo acceder a la ubicacion'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildTrackingControls(
    LocationService location,
    GamificationService gamification,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Pause/Resume button
        _buildControlButton(
          icon: location.isPaused ? Icons.play_arrow : Icons.pause,
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
          icon: Icons.stop,
          label: 'Terminar',
          color: AppColors.error,
          onPressed: () => _stopRun(location, gamification),
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    final size = isLarge ? 72.0 : 56.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: isLarge ? 36 : 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
        title: const Text('Terminar carrera?'),
        content: const Text('Quieres guardar esta carrera?'),
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

    // Process run with gamification
    final result = await gamification.processRun(run);

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
    _mapController?.dispose();
    super.dispose();
  }
}
