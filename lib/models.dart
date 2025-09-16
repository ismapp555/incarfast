import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String? name;
  final String? email;
  final String? phone;
  final String role; // 'passenger' or 'driver'

  AppUser({
    required this.uid,
    this.name,
    this.email,
    this.phone,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
    };
  }

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: data['name'],
      email: data['email'],
      phone: data['phone'],
      role: data['role'],
    );
  }
}

class VehicleType {
  final String id;
  final String name;
  final double pricePerKm;
  final String icon;

  VehicleType({
    required this.id,
    required this.name,
    required this.pricePerKm,
    required this.icon,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'priceper_km': pricePerKm, 'icon': icon};
  }

  factory VehicleType.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return VehicleType(
      id: doc.id,
      name: data['name'],
      pricePerKm: (data['priceper_km'] as num).toDouble(),
      icon: data['icon'],
    );
  }
}

class Ride {
  final String rideId;
  final String passengerId;
  final String? passengerPhone;
  final String? driverId;
  final GeoPoint startCoords;
  final GeoPoint endCoords;
  final String vehicleType;
  final double estimatedPrice;
  final String status; // e.g., 'pending', 'accepted', 'ongoing', 'completed'
  final Timestamp createdAt;

  Ride({
    required this.rideId,
    required this.passengerId,
    this.passengerPhone,
    this.driverId,
    required this.startCoords,
    required this.endCoords,
    required this.vehicleType,
    required this.estimatedPrice,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'passengerId': passengerId,
      'passengerPhone': passengerPhone,
      'driverId': driverId,
      'startCoords': startCoords,
      'endCoords': endCoords,
      'vehicleType': vehicleType,
      'estimatedPrice': estimatedPrice,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory Ride.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Ride(
      rideId: doc.id,
      passengerId: data['passengerId'],
      passengerPhone: data['passengerPhone'],
      driverId: data['driverId'],
      startCoords: data['startCoords'],
      endCoords: data['endCoords'],
      vehicleType: data['vehicleType'],
      estimatedPrice: (data['estimatedPrice'] as num).toDouble(),
      status: data['status'],
      createdAt:
          data['createdAt'] ?? Timestamp.now(), // Fallback for older documents
    );
  }
}

class DriverLocation {
  final String driverId;
  final double lat;
  final double lng;
  final Timestamp lastUpdate;

  DriverLocation({
    required this.driverId,
    required this.lat,
    required this.lng,
    required this.lastUpdate,
  });

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lng': lng, 'lastUpdate': lastUpdate};
  }

  factory DriverLocation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DriverLocation(
      driverId: doc.id,
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      lastUpdate: data['lastUpdate'],
    );
  }
}
