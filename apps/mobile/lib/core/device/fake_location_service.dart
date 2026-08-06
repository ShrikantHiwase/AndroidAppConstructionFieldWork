import '../../features/issues/domain/issue_models.dart';
import 'location_service.dart';

class FakeLocationService implements LocationService {
  const FakeLocationService();

  static const demoSite = GeoLocation(
    latitude: 18.5912,
    longitude: 73.7389,
    accuracyMeters: 8,
    label: 'Demo GPS · Hinjewadi',
  );

  @override
  Future<GeoLocation?> currentPosition() async => demoSite;

  @override
  Future<bool> isWithinGeofence({
    required GeoLocation site,
    required double radiusMeters,
  }) async =>
      true;
}
