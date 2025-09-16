import 'package:flutter/material.dart';
import 'package:in_car/models.dart';
import 'package:in_car/services/firestore_service.dart';
import 'package:in_car/services/directions_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehicleSelector extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String rideId;

  const VehicleSelector({
    super.key,
    required this.origin,
    required this.destination,
    required this.rideId,
  });

  @override
  State<VehicleSelector> createState() => _VehicleSelectorState();
}

class _VehicleSelectorState extends State<VehicleSelector> {
  final FirestoreService _firestoreService = FirestoreService(
    FirebaseFirestore.instance,
  ); // Use default instance
  final DirectionsService _directionsService = DirectionsService();

  Future<List<Map<String, dynamic>>>? _vehicleDataFuture;

  @override
  void initState() {
    super.initState();
    _vehicleDataFuture = _fetchAndCalculateEstimates();
  }

  Future<List<Map<String, dynamic>>> _fetchAndCalculateEstimates() async {
    // 1. Get distance from Directions API
    final double? distanceInKm = await _directionsService.getDistance(
      widget.origin,
      widget.destination,
    );

    if (distanceInKm == null) {
      // Handle error, maybe show a message to the user
      throw Exception("Could not calculate distance.");
    }

    // 2. Fetch vehicle types from Firestore
    final List<VehicleType> vehicleTypes = await _firestoreService
        .getVehicleTypes();

    // 3. Calculate price for each and return a list of combined data
    List<Map<String, dynamic>> data = [];
    for (var vehicle in vehicleTypes) {
      final double estimatedPrice = distanceInKm * vehicle.pricePerKm;
      data.add({
        'vehicle': vehicle,
        'price': estimatedPrice,
        'distance': distanceInKm,
      });
    }
    return data;
  }

  Future<void> _createRideRequest(
    VehicleType vehicle,
    double estimatedPrice,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Should not happen if user is authenticated

    final Ride newRide = Ride(
      rideId: widget.rideId, // Use the passed rideId
      passengerId: user.uid,
      startCoords: GeoPoint(widget.origin.latitude, widget.origin.longitude),
      endCoords: GeoPoint(
        widget.destination.latitude,
        widget.destination.longitude,
      ),
      vehicleType: vehicle.name,
      estimatedPrice: estimatedPrice,
      status: 'pending',
      createdAt: Timestamp.now(),
    );

    await _firestoreService.requestRide(newRide);

    if (!mounted) return; // Check if the widget is still in the tree

    // Close the bottom sheet and return true to indicate success
    Navigator.pop(context, true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Votre demande de course a été envoyée !')),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'directions_car':
        return Icons.directions_car;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'airport_shuttle':
        return Icons.airport_shuttle;
      default:
        return Icons.drive_eta; // A default icon
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _vehicleDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur: Impossible de calculer les tarifs. Avez-vous ajouté votre clé API Directions?",
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucun type de véhicule trouvé."));
          }

          final vehicleData = snapshot.data!;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choisissez un véhicule',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 15),
              ListView.builder(
                shrinkWrap: true,
                itemCount: vehicleData.length,
                itemBuilder: (context, index) {
                  final data = vehicleData[index];
                  final VehicleType vehicle = data['vehicle'];
                  final double price = data['price'];
                  final double distance = data['distance'];

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        _getIconData(vehicle.icon),
                        color: Colors.black,
                        size: 40,
                      ),
                      title: Text(
                        vehicle.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${distance.toStringAsFixed(1)} km'),
                      trailing: Text(
                        '${price.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () => _createRideRequest(vehicle, price),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
