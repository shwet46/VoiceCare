import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicecare/screens/welcome_screen.dart';

class VoiceCareAppBar extends StatelessWidget implements PreferredSizeWidget {
  const VoiceCareAppBar({super.key});

  // Defining the brand colors
  final Color primaryOrange = const Color(0xFFDE9243);
  final Color deepBrown = const Color(0xFFC4561D);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 90,
      automaticallyImplyLeading: false,
      // Subtle bottom divider for a clean look
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: Colors.grey.withOpacity(0.08),
          height: 1.0,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Apply Gradient to the Logo text
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: [primaryOrange, deepBrown],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: const Text(
              'VoiceCare',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                fontFamily: 'GoogleSans',
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Your digital friend, day and night.',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 13,
              fontFamily: 'GoogleSans',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Center(
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryOrange.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: primaryOrange.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.logout_rounded, color: deepBrown, size: 20),
                onPressed: () => _handleLogout(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(90);
}