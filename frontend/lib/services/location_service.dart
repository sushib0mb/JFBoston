import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class _StageCoord {
  final String stageName;
  final double lat;
  final double lng;
  const _StageCoord(this.stageName, this.lat, this.lng);
}

class LocationService extends ChangeNotifier {
  // ── Update these to the exact stage GPS coordinates each year ──
  static const List<_StageCoord> _stages = [
    _StageCoord('Main Stage 1',     42.3553, -71.0686), // Boston Common
    _StageCoord('Downtown Stage 1', 42.3553, -71.0602), // Downtown
    _StageCoord('Stage 3',          42.3553, -71.0602), // Downtown (same location)
  ];

  /// Distance in meters to each stage. Null = not yet available.
  final Map<String, double?> distances = {};

  bool permissionDenied = false;
  StreamSubscription<Position>? _sub;

  Future<void> start() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      permissionDenied = true;
      notifyListeners();
      return;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 10, // only recalculate after moving 10 m
    );

    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) {
        for (final stage in _stages) {
          distances[stage.stageName] = Geolocator.distanceBetween(
            pos.latitude, pos.longitude,
            stage.lat, stage.lng,
          );
        }
        notifyListeners();
      },
      onError: (_) {}, // silently ignore stream errors
    );
  }

  /// Human-readable distance string for a stage, e.g. "0.3 mi" or "280 ft".
  String formatDistance(String stageName) {
    final meters = distances[stageName];
    if (meters == null) return '';
    final feet = meters * 3.28084;
    if (feet < 500) return '${feet.round()} ft away';
    final miles = meters / 1609.344;
    return '${miles.toStringAsFixed(1)} mi away';
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
