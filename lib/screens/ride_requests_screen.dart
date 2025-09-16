import 'package:flutter/material.dart';
import 'package:in_car/models.dart';
import 'package:in_car/screens/driver_trip_screen.dart';
import 'package:in_car/services/firestore_service.dart';
import 'package:in_car/services/location_service.dart';
import 'package:in_car/services/location_sharing_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart' as geo;

class RideRequestsScreen extends StatefulWidget {
  const RideRequestsScreen({super.key});

  @override
  State<RideRequestsScreen> createState() => _RideRequestsScreenState();
}

class _RideRequestsScreenState extends State<RideRequestsScreen> {
  late final FirestoreService _firestoreService;
  late final String? _currentDriverId;
  LocationSharingService? _locationSharingService;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService(FirebaseFirestore.instance);
    _currentDriverId = FirebaseAuth.instance.currentUser?.uid;

    if (_currentDriverId != null) {
      _locationSharingService = LocationSharingService(
        driverId: _currentDriverId!,
        locationService: LocationService(),
        firestoreService: _firestoreService,
      );
      _locationSharingService?.start();
    }
  }

  @override
  void dispose() {
    _locationSharingService?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes de course'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<List<Ride>>(
        stream: _firestoreService.getPendingRidesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Aucune demande de course pour le moment.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final rides = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              return _RideCard(
                ride: ride,
                onAccept: () async {
                  if (_currentDriverId != null) {
                    await _firestoreService.acceptRide(
                      ride.rideId,
                      _currentDriverId!,
                    );
                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DriverTripScreen(ride: ride),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _RideCard extends StatefulWidget {
  final Ride ride;
  final VoidCallback onAccept;

  const _RideCard({required this.ride, required this.onAccept});

  @override
  State<_RideCard> createState() => _RideCardState();
}

class _RideCardState extends State<_RideCard> {
  String _startAddress = "Chargement...";
  String _endAddress = "Chargement...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _convertCoordinatesToAddress();
  }

  Future<void> _convertCoordinatesToAddress() async {
    try {
      final start = await _getAddress(widget.ride.startCoords);
      final end = await _getAddress(widget.ride.endCoords);
      if (mounted) {
        setState(() {
          _startAddress = start;
          _endAddress = end;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _startAddress = "Adresse introuvable";
          _endAddress = "Adresse introuvable";
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _getAddress(GeoPoint point) async {
    List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
      point.latitude,
      point.longitude,
    );
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      return "${place.street}, ${place.locality}";
    }
    return "Adresse inconnue";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddressRow(Icons.trip_origin, "Départ", _startAddress),
            const Divider(height: 20),
            _buildAddressRow(Icons.location_on, "Destination", _endAddress),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(widget.ride.vehicleType),
                  backgroundColor: const Color(0xFFBEF574).withAlpha(77),
                ),
                Text(
                  '${widget.ride.estimatedPrice.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onAccept,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Accepter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              if (_isLoading)
                const LinearProgressIndicator()
              else
                Text(address, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}
