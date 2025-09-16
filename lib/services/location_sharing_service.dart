import 'dart:async';
import 'dart:developer' as developer;
import 'package:in_car/services/location_service.dart';
import 'package:in_car/services/firestore_service.dart';
import 'package:in_car/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationSharingService {
  final LocationService _locationService;
  final FirestoreService _firestoreService;
  final String driverId;

  Timer? _timer;

  LocationSharingService({
    required this.driverId,
    required LocationService locationService,
    required FirestoreService firestoreService,
  }) : _locationService = locationService,
       _firestoreService = firestoreService;

  void start() {
    // Stop any existing timer
    stop();

    // Start a new timer to run every 15 seconds
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      try {
        final position = await _locationService.getCurrentLocation();
        if (position != null &&
            position.latitude != null &&
            position.longitude != null) {
          final driverLocation = DriverLocation(
            driverId: driverId,
            lat: position.latitude!,
            lng: position.longitude!,
            lastUpdate: Timestamp.now(),
          );
          await _firestoreService.updateDriverLocation(driverLocation);
        }
      } catch (e, s) {
        developer.log(
          'Error updating driver location',
          name: 'inCar.LocationSharingService',
          error: e,
          stackTrace: s,
        );
        stop(); // Stop the timer if there's an error
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
