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
    await Future.delayed(const Duration(seconds: 2));
    User? user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user != null) {
      try {
        // 1. Fetch the user profile/doc
        final profile = await ProfileService().fetchUserProfile();

        // 2. Determine if they finished the AI Onboarding
        // Note: You can check individual fields or just your 'onboarding_complete' boolean
        final bool isComplete =
            profile != null && (profile.fullName?.trim().isNotEmpty ?? false);

        if (isComplete) {
          // ✅ Profile done -> Go to Main Dashboard
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // ❌ Profile NOT done -> Go to AI Agent (SetupScreen)
          Navigator.pushReplacementNamed(context, '/setup');
        }
      } catch (e) {
        debugPrint("Error fetching profile: $e");
        // Fallback: If error occurs, send to Setup just in case
        Navigator.pushReplacementNamed(context, '/setup');
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
