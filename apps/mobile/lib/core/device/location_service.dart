import '../../features/issues/domain/issue_models.dart';

abstract class LocationService {
  /// Current position, or null if unavailable.
  Future<GeoLocation?> currentPosition();

  /// Soft geofence check around a site center (meters).
  Future<bool> isWithinGeofence({
    required GeoLocation site,
    required double radiusMeters,
  });
}
