import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:voicecare/screens/splash.dart';
import 'package:voicecare/screens/onboarding_form_page.dart';
import 'package:voicecare/screens/home_screen.dart';

// Autumn Palette Constants
const Color kPrimaryBrown = Color(0xFF834820);
const Color kBurntOrange = Color(0xFFBF4E1E);
const Color kMustardGold = Color(0xFFDD9239);
const Color kSageGreen = Color(0xFFB0D0BF);
const Color kOliveGreen = Color(0xFF929D65);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
      appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VoiceCare',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBurntOrange,
          primary: kBurntOrange,
          secondary: kMustardGold,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFFDFCFB),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: kPrimaryBrown,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(color: kPrimaryBrown),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kSageGreen),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kSageGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBurntOrange, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kBurntOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/onboarding': (_) => const OnboardingFormPage(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
