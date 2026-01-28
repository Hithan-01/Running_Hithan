import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/run.dart';
import '../models/poi.dart';

class LocationService extends ChangeNotifier {
  StreamSubscription<Position>? _positionSubscription;

  // Current state
  bool _isTracking = false;
  bool _isPaused = false;
  Position? _currentPosition;
  List<RunPoint> _routePoints = [];

  // Run metrics
  int _distance = 0; // meters
  int _duration = 0; // seconds
  DateTime? _startTime;
  Timer? _durationTimer;

  // POI detection
  final Set<String> _visitedPoisThisRun = {};
  Function(Poi)? onPoiVisited;

  // Getters
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  Position? get currentPosition => _currentPosition;
  List<RunPoint> get routePoints => List.unmodifiable(_routePoints);
  int get distance => _distance;
  int get duration => _duration;
  Set<String> get visitedPoisThisRun => Set.unmodifiable(_visitedPoisThisRun);

  double get distanceKm => _distance / 1000;

  double get avgPace {
    if (_distance == 0) return 0;
    // pace = minutes per km
    double minutes = _duration / 60;
    double km = _distance / 1000;
    return minutes / km;
  }

  String get formattedPace {
    if (avgPace <= 0 || avgPace.isInfinite || avgPace.isNaN) return '--:--';
    int minutes = avgPace.floor();
    int seconds = ((avgPace - minutes) * 60).round();
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  String get formattedDuration {
    int hours = _duration ~/ 3600;
    int minutes = (_duration % 3600) ~/ 60;
    int seconds = _duration % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Check and request permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions permanently denied');
      return false;
    }

    return true;
  }

  // Get current position once
  Future<Position?> getCurrentPosition() async {
    if (!await checkPermissions()) return null;

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();
      return _currentPosition;
    } catch (e) {
      debugPrint('Error getting position: $e');
      return null;
    }
  }

  // Start tracking run
  Future<bool> startTracking() async {
    if (_isTracking) return true;
    if (!await checkPermissions()) return false;

    _isTracking = true;
    _isPaused = false;
    _distance = 0;
    _duration = 0;
    _routePoints = [];
    _visitedPoisThisRun.clear();
    _startTime = DateTime.now();

    // Start duration timer
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        _duration++;
        notifyListeners();
      }
    });

    // Start position stream
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onPositionUpdate);

    notifyListeners();
    return true;
  }

  void _onPositionUpdate(Position position) {
    if (_isPaused) return;

    // Calculate distance from last point
    if (_routePoints.isNotEmpty) {
      final lastPoint = _routePoints.last;
      final distanceFromLast = Geolocator.distanceBetween(
        lastPoint.latitude,
        lastPoint.longitude,
        position.latitude,
        position.longitude,
      );

      // Only add if moved significantly (filter GPS noise)
      if (distanceFromLast >= 3) {
        _distance += distanceFromLast.round();
      }
    }

    // Add point to route
    _routePoints.add(RunPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    ));

    _currentPosition = position;

    // Check for POI visits
    _checkPoiProximity(position);

    notifyListeners();
  }

  void _checkPoiProximity(Position position) {
    for (final poi in CampusPois.all) {
      if (_visitedPoisThisRun.contains(poi.id)) continue;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        poi.latitude,
        poi.longitude,
      );

      if (distance <= Poi.visitRadius) {
        _visitedPoisThisRun.add(poi.id);
        onPoiVisited?.call(poi);
        debugPrint('POI visited: ${poi.name}');
      }
    }
  }

  // Pause tracking
  void pauseTracking() {
    _isPaused = true;
    notifyListeners();
  }

  // Resume tracking
  void resumeTracking() {
    _isPaused = false;
    notifyListeners();
  }

  // Stop tracking and return run data
  Run? stopTracking(String oderId, String runId) {
    if (!_isTracking) return null;

    _isTracking = false;
    _isPaused = false;
    _positionSubscription?.cancel();
    _durationTimer?.cancel();

    final run = Run(
      id: runId,
      oderId: oderId,
      distance: _distance,
      duration: _duration,
      avgPace: avgPace,
      route: List.from(_routePoints),
      poisVisited: _visitedPoisThisRun.toList(),
      createdAt: _startTime ?? DateTime.now(),
    );

    // Reset state
    _routePoints = [];
    _visitedPoisThisRun.clear();
    _distance = 0;
    _duration = 0;
    _startTime = null;

    notifyListeners();
    return run;
  }

  // Calculate distance between two points (Haversine)
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }
}
