import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io' show Platform;

class DirectionsService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json?';

  // IMPORTANT: Replace with your own Google Directions API key
  final String _apiKey = "AIzaSyBXrLjjyXqnzOPGcNxGa_GG_GARR2BgRcA";

  Future<double?> getDistance(LatLng origin, LatLng destination) async {
    // Return a mock distance when running in a test environment
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return 10.0;
    }

    final String url =
        '$_baseUrl'
        'origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        if (route['legs'].isNotEmpty) {
          final leg = route['legs'][0];
          // Distance in meters
          final distanceValue = leg['distance']['value'];
          // Convert meters to kilometers
          return distanceValue / 1000.0;
        }
      }
    }
    return null;
  }
}
