import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:voicecare/widgets/voicecare_app_bar.dart';
import 'package:voicecare/screens/sos_page.dart';
import 'package:voicecare/screens/profile_page.dart';
import 'package:voicecare/screens/home_screen.dart';
import 'package:voicecare/screens/call_log_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    SosPage(),
    Center(child: Text("AI Call Content", style: TextStyle(fontSize: 24))),
    CallLogScreen(),
    ProfilePage(),
  ];

  Future<void> getDeviceToken() async {
    // 1. Request permission (Essential for iOS)
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Retrieve the token
      String? token = await FirebaseMessaging.instance.getToken();

      // 3. Print it to your console so you can copy it for Postman
      log("Registration Token: $token");
    }
  }

  @override
  void initState() {
    super.initState();
    getDeviceToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const VoiceCareAppBar(),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ---------------- BOTTOM NAV BAR ----------------

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
        height: 110, // same visual height as original
        decoration: BoxDecoration(color: Colors.white),
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Capsule container
            Container(
              height: 65,
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFFD98E39), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem('assets/icons/home.svg', 'Home', 0),
                  _buildNavItem('assets/icons/multi-users.svg', 'SOS', 1),
                  const SizedBox(width: 80), // space for circle
                  _buildNavItem('assets/icons/phone1.svg', 'Logs', 3),
                  _buildNavItem('assets/icons/user.svg', 'Profile', 4),
                ],
              ),
            ),

            // AI Call Circle — SAME placement as original
            Positioned(
              top: 10,
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = 2),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD98E39),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/phone2.svg',
                        height: 32,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFE85D32),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'AI Call',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'GoogleSans',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- NAV ITEM ----------------

  Widget _buildNavItem(String iconPath, String label, int index) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            height: 22,
            color: isSelected ? const Color(0xFFE85D32) : Colors.grey,
            placeholderBuilder: (_) => const Icon(Icons.error, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'GoogleSans',
              color: isSelected ? const Color(0xFFE85D32) : Colors.black54,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
