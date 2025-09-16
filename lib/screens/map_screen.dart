import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:in_car/models.dart';
import 'package:in_car/services/location_service.dart';
import 'package:in_car/services/firestore_service.dart';
import 'package:in_car/config/map_style.dart';
import 'package:in_car/widgets/vehicle_selector.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService(
    FirebaseFirestore.instance,
  );

  // State variables
  String _currentAddress = "Déplacez la carte...";
  Timer? _debounce;
  bool _isMapReady = false;
  LatLng? _origin;
  CameraPosition? _currentCameraPosition;
  final Set<Marker> _markers = {};
  BitmapDescriptor? _driverIcon;

  // Ride tracking state
  String? _rideId;
  StreamSubscription<Ride?>? _rideSubscription;
  StreamSubscription<DriverLocation?>? _driverLocationSubscription;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _setUserInitialLocation();
    _loadDriverIcon();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _rideSubscription?.cancel();
    _driverLocationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDriverIcon() async {
    _driverIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/car_icon.png',
    );
  }

  Future<void> _setUserInitialLocation() async {
    LocationData? locationData = await _locationService.getCurrentLocation();
    if (locationData != null &&
        locationData.latitude != null &&
        locationData.longitude != null) {
      setState(() {
        _origin = LatLng(locationData.latitude!, locationData.longitude!);
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    setState(() {
      _isMapReady = true;
    });
    _centerMapOnUser();
  }

  Future<void> _centerMapOnUser() async {
    LocationData? locationData = await _locationService.getCurrentLocation();
    if (locationData != null &&
        locationData.latitude != null &&
        locationData.longitude != null) {
      final GoogleMapController controller = await _controller.future;
      final LatLng userLocation = LatLng(
        locationData.latitude!,
        locationData.longitude!,
      );
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: userLocation, zoom: 17.0),
        ),
      );
      setState(() {
        _origin = userLocation; // Update origin when recentering
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    // Do not update address if a ride is active
    if (_rideId != null) return;

    _currentCameraPosition = position;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _getAddressFromLatLng(position.target);
    });
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final geo.Placemark place = placemarks.first;
        setState(() {
          _currentAddress = "${place.street}, ${place.locality}";
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  void _onContinuePressed() async {
    if (_origin == null || _currentCameraPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attente de la localisation...")),
        );
      }
      return;
    }

    final rideDoc = FirebaseFirestore.instance.collection('rides').doc();
    setState(() {
      _rideId = rideDoc.id;
    });

    // Show the vehicle selector
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VehicleSelector(
        origin: _origin!,
        destination: _currentCameraPosition!.target,
        rideId: _rideId!,
      ),
    );

    if (result == true) {
      // The ride was created, start listening
      _listenToRideUpdates(_rideId!);
    }
  }

  void _listenToRideUpdates(String rideId) {
    _rideSubscription?.cancel();
    _rideSubscription = _firestoreService.getRideStream(rideId).listen((ride) {
      if (ride != null && ride.driverId != null) {
        // Once we have a driver, listen to their location
        _listenToDriverLocation(ride.driverId!);
        // We can stop listening to the ride itself if we only care about the driver assignment
        _rideSubscription?.cancel();
      }
    });
  }

  void _listenToDriverLocation(String driverId) {
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = _firestoreService
        .getDriverLocationStream(driverId)
        .listen((driverLocation) {
          if (driverLocation != null) {
            _updateDriverMarker(LatLng(driverLocation.lat, driverLocation.lng));
          }
        });
  }

  void _updateDriverMarker(LatLng position) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: position,
          icon: _driverIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5), // Center the icon
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kGooglePlex,
            style: mapStyle,
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onCameraMove: _onCameraMove,
            markers: _markers,
          ),
          // Show pin only when no active ride
          if (_rideId == null)
            const Center(
              child: Icon(
                Icons.location_pin,
                color: Color(0xFFBEF574),
                size: 50,
              ),
            ),

          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 10),
                ],
              ),
              child: Text(
                _currentAddress,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          if (_isMapReady && _rideId == null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _centerMapOnUser,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Utiliser la position actuelle"),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _onContinuePressed,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Continuer"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
