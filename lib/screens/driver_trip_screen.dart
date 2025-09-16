import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:in_car/models.dart';
import 'package:in_car/services/directions_service.dart';
import 'package:in_car/services/location_service.dart';
import 'package:location/location.dart';
import 'dart:ui' as ui;
import 'dart:developer' as developer;

class DriverTripScreen extends StatefulWidget {
  final Ride ride;

  const DriverTripScreen({super.key, required this.ride});

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final DirectionsService _directionsService = DirectionsService();
  final LocationService _locationService = LocationService();

  final Map<PolylineId, Polyline> _polylines = {};
  final Map<MarkerId, Marker> _markers = {};
  Timer? _locationUpdateTimer;

  String? _distance;
  BitmapDescriptor? _carIcon;

  @override
  void initState() {
    super.initState();
    _loadCarIcon();
    _initializeTrip();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCarIcon() async {
    try {
      final Uint8List markerIcon = await _getBytesFromAsset(
        'assets/images/car_icon.png',
        100,
      );
      _carIcon = BitmapDescriptor.bytes(markerIcon);
    } catch (e) {
      developer.log("Couldn't load car icon: $e");
    }
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!
        .buffer
        .asUint8List();
  }

  Future<void> _initializeTrip() async {
    try {
      final driverLocation = await _locationService.getCurrentLocation();
      if (driverLocation?.latitude == null ||
          driverLocation?.longitude == null) {
        throw Exception("Impossible d'obtenir la position du chauffeur.");
      }

      final driverLatLng = LatLng(
        driverLocation!.latitude!,
        driverLocation.longitude!,
      );
      final passengerLatLng = LatLng(
        widget.ride.startCoords.latitude,
        widget.ride.startCoords.longitude,
      );

      _addMarker(driverLatLng, "driver_marker", "Votre position");
      _addMarker(
        passengerLatLng,
        "passenger_marker",
        "Point de départ du passager",
      );

      await _calculateDistance(driverLatLng, passengerLatLng);
      _subscribeToLocationUpdates();

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          _createBounds(driverLatLng, passengerLatLng),
          100.0, // padding
        ),
      );
    } catch (e) {
      developer.log("Erreur durant l'initialisation du trajet: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erreur: Impossible de charger les détails du trajet. $e",
            ),
          ),
        );
      }
    }
  }

  Future<void> _calculateDistance(LatLng origin, LatLng destination) async {
    try {
      final distance = await _directionsService.getDistance(
        origin,
        destination,
      );

      if (distance != null) {
        if (mounted) {
          setState(() {
            _distance = '${distance.toStringAsFixed(2)} km';
          });
        }
      } else {
        throw Exception("Impossible d'obtenir la distance.");
      }
    } catch (e) {
      developer.log("Erreur durant le calcul de la distance: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: Impossible de calculer la distance. $e"),
          ),
        );
      }
    }
  }

  void _subscribeToLocationUpdates() {
    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final newLocation = await _locationService.getCurrentLocation();
        if (newLocation?.latitude != null && newLocation?.longitude != null) {
          final newLatLng = LatLng(
            newLocation!.latitude!,
            newLocation.longitude!,
          );
          _updateMarkerPosition("driver_marker", newLatLng);
        }
      } catch (e) {
        developer.log("Erreur de mise à jour de la position: $e");
      }
    });
  }

  void _addMarker(LatLng position, String markerId, String title) {
    final id = MarkerId(markerId);
    final marker = Marker(
      markerId: id,
      position: position,
      infoWindow: InfoWindow(title: title),
      icon: markerId == 'driver_marker'
          ? (_carIcon ?? BitmapDescriptor.defaultMarker)
          : BitmapDescriptor.defaultMarker,
    );
    if (mounted) {
      setState(() {
        _markers[id] = marker;
      });
    }
  }

  void _updateMarkerPosition(String markerId, LatLng newPosition) {
    final id = MarkerId(markerId);
    final marker = _markers[id];
    if (marker != null) {
      final updatedMarker = Marker(
        markerId: marker.markerId,
        position: newPosition,
        infoWindow: marker.infoWindow,
        icon: marker.icon,
      );
      if (mounted) {
        setState(() {
          _markers[id] = updatedMarker;
        });
      }
    }
  }

  LatLngBounds _createBounds(LatLng pos1, LatLng pos2) {
    final southwestLat =
        (pos1.latitude < pos2.latitude) ? pos1.latitude : pos2.latitude;
    final southwestLng =
        (pos1.longitude < pos2.longitude) ? pos1.longitude : pos2.longitude;
    final northeastLat =
        (pos1.latitude > pos2.latitude) ? pos1.latitude : pos2.latitude;
    final northeastLng =
        (pos1.longitude > pos2.longitude) ? pos1.longitude : pos2.longitude;
    return LatLngBounds(
      southwest: LatLng(southwestLat, southwestLng),
      northeast: LatLng(northeastLat, northeastLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("En route vers le passager")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(48.8566, 2.3522), // Default to Paris
              zoom: 12,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            polylines: Set<Polyline>.of(_polylines.values),
            markers: Set<Marker>.of(_markers.values),
          ),
          if (_distance != null)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            "Distance",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(_distance!),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
