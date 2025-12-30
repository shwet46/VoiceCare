// import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:voicecare/screens/main_page.dart';
import 'package:voicecare/services/profile_service.dart';
import 'package:voicecare/screens/welcome_screen.dart';
import 'package:voicecare/main.dart';

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
      // Check if user profile is complete
      final profile = await ProfileService().fetchUserProfile();
      final isComplete =
          profile != null &&
          [
            profile.fullName,
            profile.allergies,
            profile.medications,
            profile.carePreferences,
            profile.healthConcerns,
          ].every((e) => e != null && e.trim().isNotEmpty);
      if (!isComplete) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
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
      backgroundColor: const Color(0xFFF2E9E9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            CircularProgressIndicator(
              color: kMustardGold.withOpacity(0.8),
              backgroundColor: Color(0xFFF2E9E9),
            ),
          ],
        ),
      ),
    );
  }
}
