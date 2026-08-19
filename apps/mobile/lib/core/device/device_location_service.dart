import 'package:geolocator/geolocator.dart';

import '../../features/issues/domain/issue_models.dart';
import 'fake_location_service.dart';
import 'location_service.dart';

/// Real GPS via geolocator; falls back to [FakeLocationService] on failure.
class DeviceLocationService implements LocationService {
  DeviceLocationService({LocationService? fallback})
      : _fallback = fallback ?? const FakeLocationService();

  final LocationService _fallback;

  @override
  Future<GeoLocation?> currentPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return await _fallback.currentPosition();

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return await _fallback.currentPosition();
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return GeoLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracyMeters: pos.accuracy,
        label: 'Device GPS',
      );
    } catch (_) {
      return await _fallback.currentPosition();
    }
  }

  @override
  Future<bool> isWithinGeofence({
    required GeoLocation site,
    required double radiusMeters,
  }) async {
    try {
      final here = await currentPosition();
      if (here == null) return false;
      final meters = Geolocator.distanceBetween(
        here.latitude,
        here.longitude,
        site.latitude,
        site.longitude,
      );
      return meters <= radiusMeters;
    } catch (_) {
      return await _fallback.isWithinGeofence(
        site: site,
        radiusMeters: radiusMeters,
      );
    }
  }
}
