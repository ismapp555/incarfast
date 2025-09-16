import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_car/config/firebase_config.dart';
import 'package:in_car/screens/auth_screen.dart';
import 'package:in_car/screens/home_screen.dart';
import 'package:in_car/screens/splash_screen.dart';
import 'package:in_car/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: passengerFirebaseOptions);
  await Firebase.initializeApp(name: 'driver', options: driverFirebaseOptions);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define your colors
    const Color primaryColor = Color(0xFFBEF574);
    const Color backgroundColor = Colors.black;
    final TextTheme textTheme = GoogleFonts.poppinsTextTheme(
      Theme.of(context).textTheme,
    ).apply(bodyColor: Colors.white, displayColor: Colors.white);

    return MaterialApp(
      title: 'inCar',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        textTheme: textTheme,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.black, // Text color for ElevatedButton
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor, // Text color for TextButton
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white.withAlpha(178)),
          filled: true,
          fillColor: Colors.white.withAlpha(26),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          titleTextStyle: textTheme.titleLarge,
          iconTheme: const IconThemeData(color: primaryColor),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(FirebaseAuth.instance);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show splash screen while checking auth state
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          // User is signed in, show HomeScreen
          return const HomeScreen();
        } else {
          // User is not signed in, show AuthScreen
          return const AuthScreen();
        }
      },
    );
  }
}
