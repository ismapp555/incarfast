
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:incar_passenger/app/home/presentation/home_page.dart';
import 'package:incar_passenger/login_screen.dart';
import 'package:incar_passenger/theme/app_theme.dart';
import 'firebase_options.dart';

// A flag to easily toggle emulator usage
const bool USE_EMULATOR = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (USE_EMULATOR) {
    try {
      // Use a local host emulator for Firebase Auth
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    } catch (e) {
      // This is likely because the emulator is not running, we can ignore this error.
      debugPrint('Error using auth emulator: $e');
    }
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'inCar Passenger',
      debugShowCheckedModeBanner: false, // Hiding the debug banner
      theme: AppTheme.lightTheme, // Using the light theme
      darkTheme: AppTheme.darkTheme, // Providing a dark theme option
      themeMode: ThemeMode.system, // Will follow system settings
      home: const AuthStreamWrapper(),
    );
  }
}

class AuthStreamWrapper extends StatelessWidget {
  const AuthStreamWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in, show HomePage
        if (snapshot.hasData && snapshot.data != null) {
          return const HomePage();
        }
        
        // Otherwise, show LoginScreen
        return const LoginScreen();
      },
    );
  }
}
