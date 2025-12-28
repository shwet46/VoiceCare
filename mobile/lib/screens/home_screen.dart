import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicecare/screens/WelcomeScreen.dart';
import 'package:voicecare/widgets/voicecare_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VoiceCareAppBar(),
      body: const Center(
        child: Text(
          'Welcome to VoiceCare !',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
