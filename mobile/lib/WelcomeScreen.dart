import 'package:blobs/blobs.dart';
import 'package:flutter/material.dart';
import 'package:voicecare/screens/auth_page.dart';
import 'package:voicecare/screens/auth_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool isLoading = false;

  static const Color primaryOrange = Color(0xFFDE9243);
  static const Color darkOrange = Color(0xFFC4561D);
  static const String customFont = 'GoogleSans'; // Centralized font name

  void handleGetStarted() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildBackgroundShapes(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const Spacer(flex: 2),
                  const Text(
                    'Your Voice\nAlways\nConnected',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                      color: Colors.black,
                      fontFamily: customFont,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'A warm, human-like companion to chat with anytime—always here to listen, help, and remind you when needed.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withOpacity(0.7),
                      height: 1.4,
                      fontFamily: customFont,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildGetStartedButton(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        Positioned(
          top: 130,
          left: -150,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0),
            child: Blob.random(
              size: 300,
              edgesCount: 7,
              minGrowth: 6,
              styles: BlobStyles(
                color: primaryOrange, // Your burnt orange color
                fillType: BlobFillType.fill,
              ),
            ),
          ),
        ),

        Positioned(
          top: 220,
          right: -180,
          child: Blob.random(
            size: 300,
            edgesCount: 6, // Lower number = smoother, more like your image
            minGrowth: 6,
            styles: BlobStyles(
              color: const Color(0xFFC45525), // Your burnt orange color
              fillType: BlobFillType.fill,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text(
              'Voice',
              style: TextStyle(
                fontSize: 32,
                color: primaryOrange,
                fontWeight: FontWeight.w400,
                fontFamily: customFont,
              ),
            ),
            Text(
              'Care',
              style: TextStyle(
                fontSize: 32,
                color: darkOrange,
                fontWeight: FontWeight.w400,
                fontFamily: customFont,
              ),
            ),
          ],
        ),
        const Text(
          'Your digital friend, day and night.',
          style: TextStyle(
            fontSize: 15,
            color: Color.fromARGB(255, 0, 0, 0),
            fontFamily: customFont,
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGetStartedButton() {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: handleGetStarted,
        child: const Text(
          'Get Started',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            fontFamily: customFont,
          ),
        ),
      ),
    );
  }
}
