import 'package:geolocator/geolocator.dart';

/// Thin wrapper around `geolocator` for the running tracker screen —
/// permission handling + a live position stream. Works on Android, iOS, and
/// web (browser Geolocation API), so the setup/permission flow can be
/// exercised from Chrome even though real outdoor GPS trails need a phone.
class GpsTrackService {
  static const _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // meters between updates
  );

  static Future<bool> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return false;
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  static Stream<Position> positionStream() => Geolocator.getPositionStream(locationSettings: _locationSettings);

  /// Cumulative distance (meters) between consecutive points via the
  /// haversine-based helper geolocator already ships with.
  static double distanceBetween(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
