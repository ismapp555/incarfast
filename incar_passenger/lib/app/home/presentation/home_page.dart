import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:incar_passenger/login_screen.dart';

// Modèle de données pour les types de véhicules
class VehicleType {
  final String name;
  final IconData icon;
  final double estimatedPrice;

  const VehicleType({
    required this.name,
    required this.icon,
    required this.estimatedPrice,
  });
}

// Le Widget principal de l'écran de réservation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Contrôleurs et État de la Carte
  GoogleMapController? _mapController;
  bool _locationPermissionGranted = false;
  LatLng? _pickupLocation;
  String _pickupAddress = "Déplacer la carte...";

  // Position initiale de la caméra (par exemple, Paris)
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(48.8566, 2.3522),
    zoom: 14.0,
  );

  // État de la Sélection du Véhicule
  int? _selectedVehicleIndex;
  final List<VehicleType> _vehicleTypes = const [
    VehicleType(name: 'Standard', icon: Icons.directions_car, estimatedPrice: 12.50),
    VehicleType(name: 'Confort', icon: Icons.local_taxi, estimatedPrice: 18.75),
    VehicleType(name: 'Van', icon: Icons.airport_shuttle, estimatedPrice: 25.00),
    VehicleType(name: 'Moto', icon: Icons.two_wheeler, estimatedPrice: 8.20),
  ];

  // État du Flux de Réservation
  bool _isPickupConfirmed = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // 1. Gestion des Permissions
  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    setState(() {
      _locationPermissionGranted = status.isGranted;
    });

    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  // 2. Callbacks de la Carte
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraIdle() async {
    if (_mapController == null) return;

    if (!_isPickupConfirmed) {
      final bounds = await _mapController!.getVisibleRegion();
      final center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );
      setState(() {
        _pickupLocation = center;
      });
      _getAddressFromLatLng(center);
      log('Point de départ sélectionné : $_pickupLocation');
    }
  }

  // Fonction pour obtenir l'adresse à partir des coordonnées
  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final addressParts = [
          placemark.street,
          placemark.locality,
          placemark.postalCode,
        ];
        addressParts.removeWhere((part) => part == null || part.isEmpty);
        setState(() {
          _pickupAddress = addressParts.join(', ');
        });
      } else {
        setState(() {
          _pickupAddress = "Adresse non trouvée";
        });
      }
    } catch (e) {
      log("Erreur de géocodage inversé: $e");
      setState(() {
        _pickupAddress = "Impossible de récupérer l'adresse";
      });
    }
  }

  // 3. Logique de Réservation
  void _onVehicleSelected(int index) {
    setState(() {
      _selectedVehicleIndex = index;
    });
  }

  void _confirmPickup() {
    if (_selectedVehicleIndex != null && _pickupLocation != null) {
      setState(() {
        _isPickupConfirmed = true;
      });
      final selectedVehicle = _vehicleTypes[_selectedVehicleIndex!];
      log('Confirmation : Départ de $_pickupAddress avec ${selectedVehicle.name}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Point de départ confirmé pour ${selectedVehicle.name}.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _continueToNextStep() {
    log('Passage à l\'étape suivante : choix de la destination.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Implémentez ici la navigation vers le choix de la destination.'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // 4. Construction de l'UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isPickupConfirmed ? 'Confirmez votre course' : 'Où allez-vous ?'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildGoogleMap(),
          if (!_isPickupConfirmed) _buildCenterPin(),
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      initialCameraPosition: _initialCameraPosition,
      onMapCreated: _onMapCreated,
      onCameraIdle: _onCameraIdle,
      myLocationEnabled: _locationPermissionGranted,
      myLocationButtonEnabled: _locationPermissionGranted,
      zoomControlsEnabled: false,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.35),
    );
  }

  Widget _buildCenterPin() {
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.location_pin, color: Colors.red, size: 50),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isPickupConfirmed) _buildVehicleSelectionList() else _buildConfirmationSummary(),
            const SizedBox(height: 16),
            if (!_isPickupConfirmed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _pickupAddress,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 8),
            _isPickupConfirmed
                ? _buildActionButton('Choisir la destination', _continueToNextStep)
                : _buildActionButton('Confirmer le Départ', _confirmPickup, isEnabled: _selectedVehicleIndex != null),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSelectionList() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _vehicleTypes.length,
        itemBuilder: (context, index) {
          final vehicle = _vehicleTypes[index];
          final isSelected = _selectedVehicleIndex == index;
          return GestureDetector(
            onTap: () => _onVehicleSelected(index),
            child: Container(
              width: 100,
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Theme.of(context).splashColor,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: Theme.of(context).primaryColor, width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(vehicle.icon, color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color, size: 30),
                  const SizedBox(height: 8),
                  Text(vehicle.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('€${vehicle.estimatedPrice.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfirmationSummary() {
    if (_selectedVehicleIndex == null) return const SizedBox.shrink();
    final vehicle = _vehicleTypes[_selectedVehicleIndex!];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(vehicle.icon, color: Theme.of(context).primaryColor, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Départ: $_pickupAddress', style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          Text('€${vehicle.estimatedPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed, {bool isEnabled = true}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        child: Text(text),
      ),
    );
  }
}
