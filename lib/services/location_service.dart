import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();

  Future<bool> _checkPermission() async {
    var permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  Future<LocationData?> getCurrentLocation() async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      return null;
    }

    // Ensure the service is enabled
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return null; // User did not enable the location service
      }
    }

    return await _location.getLocation();
  }
}
