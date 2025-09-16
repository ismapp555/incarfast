import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_car/models.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  // Use the default Firestore instance for user management
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService(this._firebaseAuth);

  /// Stream to listen for authentication changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Sign in with email and password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return "Signed In";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  /// Sign up with email and password, and create a user document
  Future<String?> signUp({
    required String email,
    required String password,
    required String phone,
    required String name, // Added name for a more complete user profile
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Create a new user document in Firestore
        await _createUserDocument(
          uid: userCredential.user!.uid,
          email: email,
          phone: phone,
          name: name,
        );
        return "Signed Up";
      }
      return "Sign up failed: User not created.";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  /// Create a user document in the 'users' collection
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String phone,
    required String name,
  }) async {
    final user = AppUser(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      role: 'passenger', // Default role for new sign-ups
    );
    await _firestore.collection('users').doc(uid).set(user.toJson());
  }

  /// Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
