import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/location_service.dart';
import '../services/gamification_service.dart';
import '../services/database_service.dart';
import '../services/audio_coach_service.dart';
import '../services/sync_service.dart';
import '../widgets/run_stats_panel.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../models/run_model.dart';
import 'run_summary_screen.dart';
import 'history_screen.dart'; // RunDetailScreen

class RunHubScreen extends StatefulWidget {
  const RunHubScreen({super.key});

  @override
  State<RunHubScreen> createState() => _RunHubScreenState();
}

class _RunHubScreenState extends State<RunHubScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _panelAnim;

  bool _isStarting = false;
  bool _followUser = true;

  static const double _sheetMax = 0.92;
  static const double _stripH = 76.0;

  static final _campusBounds = LatLngBounds(
    const LatLng(AppConstants.campusSWLat, AppConstants.campusSWLon),
    const LatLng(AppConstants.campusNELat, AppConstants.campusNELon),
  );
  static final _cameraConstraint =
      CameraConstraint.contain(bounds: _campusBounds);

  @override
  void initState() {
    super.initState();
    _panelAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _initLocation();
  }

  @override
  void dispose() {
    _panelAnim.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _togglePanel() {
    if (_panelAnim.value < 0.5) {
      _panelAnim.animateTo(1.0, curve: Curves.easeOutCubic);
    } else {
      _panelAnim.animateTo(0.0, curve: Curves.easeOutCubic);
    }
  }

  Future<void> _initLocation() async {
    final loc = context.read<LocationService>();
    final pos = await loc.getCurrentPosition();
    if (pos != null && mounted) {
      _mapController.move(
        LatLng(pos.latitude, pos.longitude),
        AppConstants.defaultZoom,
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocationService, GamificationService>(
      builder: (context, location, gamification, _) {
        final isTracking = location.isTracking;
        final sheetOffset = _stripH + MediaQuery.of(context).padding.bottom;

        return Scaffold(
          body: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // 1 · Full-screen map
              _buildMap(location, gamification),

              // 2 · Live stats panel (tracking only)
              if (isTracking) _buildStatsOverlay(location),

              // 3 · My-location button (idle only)
              if (!isTracking)
                _buildMyLocationFab(sheetOffset + 96),

              // 4 · Run controls
              if (isTracking)
                _buildTrackingControls(location, gamification)
              else
                _buildStartButton(location, sheetOffset + 24),

              // 5 · History panel (idle only)
              if (!isTracking)
                _buildHistoryPanel(gamification),
            ],
          ),
        );
      },
    );
  }

  // ─── Map ───────────────────────────────────────────────────────────────────

  Widget _buildMap(LocationService location, GamificationService gamification) {
    final currentPos = location.currentPosition;
    final center = currentPos != null
        ? LatLng(currentPos.latitude, currentPos.longitude)
        : const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude);

    if (location.isTracking && _followUser && currentPos != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(
          LatLng(currentPos.latitude, currentPos.longitude),
          _mapController.camera.zoom,
        );
      });
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: AppConstants.defaultZoom,
        minZoom: 15.5,
        maxZoom: 19,
        cameraConstraint: _cameraConstraint,
        onTap: (tapPos, latLng) {},
        onPositionChanged: (_, hasGesture) {
          if (hasGesture) _followUser = false;
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.aerdr.rush',
          maxZoom: 19,
          retinaMode: true,
        ),
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
      ],
    );
  }

  Widget _buildLocationMarker(LocationService location) {
    final points = location.routePoints;
    double? heading;
    if (points.length >= 2) {
      final p1 = points[points.length - 2];
      final p2 = points.last;
      final dLon = (p2.longitude - p1.longitude) * math.pi / 180;
      final lat1 = p1.latitude * math.pi / 180;
      final lat2 = p2.latitude * math.pi / 180;
      final y = math.sin(dLon) * math.cos(lat2);
      final x = math.cos(lat1) * math.sin(lat2) -
          math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
      heading = math.atan2(y, x);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withAlpha(40),
          ),
        ),
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

  Widget _buildStatsOverlay(LocationService location) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
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

  Widget _buildMyLocationFab(double bottomOffset) {
    return Positioned(
      bottom: bottomOffset,
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
    final loc = context.read<LocationService>();
    final pos = loc.currentPosition ?? await loc.getCurrentPosition();
    if (!mounted) return;
    if (pos != null) {
      _followUser = true;
      _mapController.move(
        LatLng(pos.latitude, pos.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  // ─── Run controls ──────────────────────────────────────────────────────────

  Widget _buildStartButton(LocationService location, double bottomOffset) {
    return Positioned(
      bottom: bottomOffset,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
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
                      width: 28,
                      height: 28,
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
      ),
    );
  }

  Future<void> _startRun(LocationService location) async {
    if (!mounted) return;
    _panelAnim.value = 0.0;
    setState(() => _isStarting = true);

    final started = await location.startTracking();
    if (started) AudioCoachService.countdown();

    if (!mounted) return;
    setState(() => _isStarting = false);

    if (!started) {
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
            _runControlButton(
              icon: location.isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              label: location.isPaused ? 'Reanudar' : 'Pausar',
              color: AppColors.warning,
              onPressed: () => location.isPaused
                  ? location.resumeTracking()
                  : location.pauseTracking(),
            ),
            _runControlButton(
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

  Widget _runControlButton({
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
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Future<void> _stopRun(
    LocationService location,
    GamificationService gamification,
  ) async {
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
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final user = gamification.user;
    if (user == null) return;

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

    AudioCoachService.runComplete(run.distanceKm);
    final result = await gamification.processRun(run);

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
        final synced =
            await SyncService().uploadRun(runModel, localRunId: run.id);
        if (synced) {
          debugPrint('✅ Carrera sincronizada');
        }
      }
    } catch (e) {
      debugPrint('❌ Error sync: $e');
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

  // ─── History sheet ─────────────────────────────────────────────────────────

  Widget _buildHistoryPanel(GamificationService gamification) {
    final user = gamification.user;
    if (user == null) return const SizedBox.shrink();
    final runs = DatabaseService.getAllRuns(user.id);

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekRuns = runs.where((r) => r.createdAt.isAfter(
          DateTime(weekStart.year, weekStart.month, weekStart.day),
        )).toList();
    int weekDist = 0;
    for (final r in weekRuns) {
      weekDist += r.distance;
    }

    final mq = MediaQuery.of(context);
    final bottomPad = mq.padding.bottom;
    final maxH = mq.size.height * _sheetMax;
    final collapsedH = _stripH + bottomPad;

    // Positioned is FIXED at bottom:0, height:maxH — layout never changes.
    // AnimatedBuilder drives Transform.translate (paint-only, zero layout cost).
    // Stack.clipBehavior clips the off-screen portion when the panel is closed.
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: maxH,
      child: AnimatedBuilder(
        animation: _panelAnim,
        builder: (_, listChild) {
          // dy=0 when open, dy=(maxH-collapsedH) when closed → slides off-screen
          final dy = (1.0 - _panelAnim.value) * (maxH - collapsedH);
          return Transform.translate(
            offset: Offset(0, dy),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Strip — tap or swipe to toggle
                  GestureDetector(
                    onTap: _togglePanel,
                    onVerticalDragEnd: (details) {
                      final vy = details.velocity.pixelsPerSecond.dy;
                      if (vy < -300) {
                        _panelAnim.animateTo(1.0, curve: Curves.easeOutCubic);
                      } else if (vy > 300) {
                        _panelAnim.animateTo(0.0, curve: Curves.easeOutCubic);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 6),
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withAlpha(80),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        _buildSummaryStrip(weekRuns.length, weekDist),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Content — Expanded always has stable maxH constraint
                  Expanded(child: listChild!),
                ],
              ),
            ),
          );
        },
        // child is cached — only rebuilt when Consumer2 rebuilds, not on anim ticks
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomPad + 80),
          children: [
            _buildWeeklyCard(weekRuns, weekDist),
            const SizedBox(height: 8),
            if (runs.isEmpty)
              _buildEmptyState()
            else
              ..._buildRunItems(runs),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStrip(int count, int distanceM) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_run_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Esta semana',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    '$count ${count == 1 ? 'carrera' : 'carreras'}  ·  ${(distanceM / 1000).toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
    );
  }

  Widget _buildWeeklyCard(List weekRuns, int weekDist) {
    int weekDuration = 0;
    for (final r in weekRuns) {
      weekDuration += r.duration as int;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2A3A), Color(0xFF2A3A4E)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 8),
                const Text(
                  'Esta semana',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${weekRuns.length} ${weekRuns.length == 1 ? 'carrera' : 'carreras'}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _summaryMetric(
                    value: (weekDist / 1000).toStringAsFixed(1),
                    unit: 'km',
                    label: 'Distancia',
                  ),
                ),
                Container(
                    width: 1, height: 40, color: Colors.white12),
                Expanded(
                  child: _summaryMetric(
                    value: Formatters.duration(weekDuration),
                    unit: '',
                    label: 'Tiempo',
                  ),
                ),
                Container(
                    width: 1, height: 40, color: Colors.white12),
                Expanded(
                  child: _summaryMetric(
                    value: weekRuns.isNotEmpty &&
                            weekDuration > 0 &&
                            weekDist > 0
                        ? Formatters.pace(
                            (weekDuration / 60) / (weekDist / 1000))
                        : '--:--',
                    unit: '/km',
                    label: 'Ritmo prom.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryMetric({
    required String value,
    required String unit,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 2),
                child: Text(unit,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white54)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.white54,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_run_rounded,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('Sin actividades',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Presiona ▶ para iniciar\ntu primera carrera',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRunItems(List runs) {
    final grouped = <String, List>{};
    for (final run in runs) {
      final key = _relativeDateHeader(run.createdAt);
      grouped.putIfAbsent(key, () => []).add(run);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      widgets.add(Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: widgets.isEmpty ? 0 : 16,
          bottom: 10,
        ),
        child: Text(
          entry.key,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
      ));
      for (final run in entry.value) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
          child: _buildRunCard(run),
        ));
      }
    }
    return widgets;
  }

  Widget _buildRunCard(dynamic run) {
    final double km = (run.distance as int) / 1000;

    return Dismissible(
      key: Key(run.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) => _confirmDelete(run),
      onDismissed: (_) => _deleteRun(run),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RunDetailScreen(run: run)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Accent bar
                Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                      Icons.directions_run_rounded,
                                      color: AppColors.primary,
                                      size: 16),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('Carrera',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary)),
                                    Text(Formatters.time(run.createdAt),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 12,
                                      color: AppColors.secondary),
                                  const SizedBox(width: 3),
                                  Text('+${run.xpEarned} XP',
                                      style: const TextStyle(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(km.toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    height: 1)),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 3, left: 3),
                              child: Text('km',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              _cardStat(Icons.timer_outlined,
                                  Formatters.duration(run.duration), 'Tiempo'),
                              _divider(),
                              _cardStat(Icons.speed_rounded,
                                  Formatters.pace(run.avgPace), 'Ritmo'),
                              if ((run.poisVisited as List).isNotEmpty) ...[
                                _divider(),
                                _cardStat(
                                    Icons.place_rounded,
                                    '${(run.poisVisited as List).length}',
                                    'POIs'),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardStat(IconData icon, String value, String label) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AppColors.textMuted.withAlpha(40),
    );
  }

  String _relativeDateHeader(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Esta semana';
    if (diff < 30) return 'Este mes';
    return Formatters.date(date);
  }

  Future<bool?> _confirmDelete(dynamic run) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar carrera',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Esta acción no se puede deshacer.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _deleteRun(dynamic run) {
    DatabaseService.deleteRun(run.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Carrera eliminada'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.error,
      ),
    );
    setState(() {});
  }
}

