import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  final Color _splashColor = const Color(0xFFBEF574);

  @override
  void initState() {
    super.initState();

    // Use WidgetsBinding to start animation after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });

    // NO MORE NAVIGATION LOGIC HERE.
    // The AuthWrapper in main.dart now handles showing this screen and then navigating away.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(seconds: 1), // Fade-in duration
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_taxi, color: _splashColor, size: 120.0),
              const SizedBox(height: 24),
              Text(
                'Bienvenue chez inCar',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: _splashColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
