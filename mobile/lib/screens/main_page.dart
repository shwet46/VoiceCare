import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:voicecare/widgets/voicecare_app_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // These are the "Content" widgets that will swap
  final List<Widget> _pages = [
    const Center(child: Text("Home Content", style: TextStyle(fontSize: 24))),
    const Center(child: Text("SOS Content", style: TextStyle(fontSize: 24))),
    const Center(
      child: Text("AI Call Content", style: TextStyle(fontSize: 24)),
    ),
    const Center(child: Text("Logs Content", style: TextStyle(fontSize: 24))),
    const Center(
      child: Text("Profile Content", style: TextStyle(fontSize: 24)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VoiceCareAppBar(),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
        height: 110,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // 1. The main horizontal capsule container
            Container(
              height: 65,
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFFD98E39), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem('assets/icons/home.svg', 'Home', 0),
                  _buildNavItem('assets/icons/phone1.svg', 'SOS', 1),
                  const SizedBox(width: 80),
                  _buildNavItem('assets/icons/phone1.svg', 'Logs', 3),
                  _buildNavItem('assets/icons/user.svg', 'Profile', 4),
                ],
              ),
            ),

            // 2. The AI Call button
            Positioned(
              top: 10, // Adjust this so the circle sits perfectly
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = 2),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD98E39),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/phone2.svg',
                              height: 35,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFE85D32),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'AI Call',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                fontFamily: 'GoogleSans',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            height: 24,
            color: isSelected ? const Color(0xFFE85D32) : Colors.grey,
            placeholderBuilder: (context) => const Icon(Icons.error, size: 24),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFFE85D32) : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'GoogleSans',
            ),
          ),
        ],
      ),
    );
  }
}
