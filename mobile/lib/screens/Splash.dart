// import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:voicecare/screens/WelcomeScreen.dart';
import 'package:voicecare/main.dart';
import 'package:voicecare/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // 1. Artificial delay to show the splash logo (e.g., 2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    // 2. Check current Firebase User
    User? user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user != null) {
      // User is logged in -> Go to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
          // If HomeScreen is not the correct class, replace 'HomeScreen' with the actual home page widget class name.
        ),
      );
    } else {
      // No user -> Go to Welcome Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // const Icon(Icons.graphic_eq_rounded, size: 80, color: Colors.white),
            // const SizedBox(height: 24),
            const Text(
              'VoiceCare',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w400,
                color: Color.fromARGB(255, 0, 0, 0),
                letterSpacing: 1.2,
                fontFamily: 'GoogleSans',
              ),
            ),
            const SizedBox(height: 10),
            CircularProgressIndicator(color: kMustardGold.withOpacity(0.8)),
          ],
        ),
      ),
    );
  }
}
