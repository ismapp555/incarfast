import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService(this._db);

  //--- User Methods ---
  Future<void> createUser(AppUser user) {
    return _db.collection('users').doc(user.uid).set(user.toJson());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? AppUser.fromFirestore(doc) : null;
  }

  //--- VehicleType Methods ---
  Future<void> createVehicleType(VehicleType vehicle) {
    return _db.collection('vehicletypes').doc(vehicle.id).set(vehicle.toJson());
  }

  Future<List<VehicleType>> getVehicleTypes() async {
    final snapshot = await _db.collection('vehicletypes').get();
    return snapshot.docs.map((doc) => VehicleType.fromFirestore(doc)).toList();
  }

  //--- Ride Methods ---
  Future<void> requestRide(Ride ride) {
    return _db.collection('rides').doc(ride.rideId).set(ride.toJson());
  }

  // Get a stream of a single ride document
  Stream<Ride?> getRideStream(String rideId) {
    return _db
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .map((doc) => doc.exists ? Ride.fromFirestore(doc) : null);
  }

  Stream<List<Ride>> getPendingRidesStream() {
    return _db
        .collection('rides')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Ride.fromFirestore(doc)).toList(),
        );
  }

  Future<void> acceptRide(String rideId, String driverId) {
    return _db.collection('rides').doc(rideId).update({
      'status': 'accepted',
      'driverId': driverId,
    });
  }

  Future<List<Ride>> getPassengerRides(String passengerId) async {
    final snapshot = await _db
        .collection('rides')
        .where('passengerId', isEqualTo: passengerId)
        .get();
    return snapshot.docs.map((doc) => Ride.fromFirestore(doc)).toList();
  }

  Future<List<Ride>> getDriverRides(String driverId) async {
    final snapshot = await _db
        .collection('rides')
        .where('driverId', isEqualTo: driverId)
        .get();
    return snapshot.docs.map((doc) => Ride.fromFirestore(doc)).toList();
  }

  //--- DriverLocation Methods ---
  Future<void> updateDriverLocation(DriverLocation location) {
    return _db
        .collection('drivers_locations')
        .doc(location.driverId)
        .set(location.toJson());
  }

  Stream<DriverLocation?> getDriverLocationStream(String driverId) {
    return _db
        .collection('drivers_locations')
        .doc(driverId)
        .snapshots()
        .map((snap) => snap.exists ? DriverLocation.fromFirestore(snap) : null);
  }
}
