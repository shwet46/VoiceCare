import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicecare/screens/WelcomeScreen.dart';

class VoiceCareAppBar extends StatelessWidget implements PreferredSizeWidget {
  const VoiceCareAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Voice',
                  style: TextStyle(
                    color: Color(0xFFDE9243), // Orange
                    fontWeight: FontWeight.w400,
                    fontSize: 28,
                    fontFamily: 'GoogleSans',
                  ),
                ),
                TextSpan(
                  text: 'Care',
                  style: TextStyle(
                    color: Color(0xFFC4561D), // Dark Orange
                    fontWeight: FontWeight.w400,
                    fontSize: 28,
                    fontFamily: 'GoogleSans',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Your digital friend, day and night.',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontFamily: 'GoogleSans',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      toolbarHeight: 70,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.black54),
          tooltip: 'Logout',
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
