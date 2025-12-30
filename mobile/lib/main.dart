import 'dart:developer';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
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

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If the message contains call data, show the CallKit UI
  if (message.data['type'] == 'incoming_call') {
    showCallkitIncoming(message.data);
  }
}

Future<void> showCallkitIncoming(Map<String, dynamic> data) async {
  final params = CallKitParams(
    id: data['id'] ?? 'default_id',
    nameCaller: data['nameCaller'] ?? 'Max Verstappan',
    appName: 'VoiceCare',
    avatar:
        'https://cdn-9.motorsport.com/images/mgl/6D1XbeV0/s800/max-verstappen-red-bull-racing.jpg', // Optional: Replace with your AI icon
    handle: data['handle'] ?? 'Voice Session',
    type: 0, // 0 for Audio, 1 for Video
    duration: 30000, // 30 seconds
    textAccept: 'Accept',
    textDecline: 'Decline',
    // missedCallBadgeCount: 1,
    extra: <String, dynamic>{'userId': '1234'},
    headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
    android: const AndroidParams(
      isCustomNotification: true,
      isShowFullLockedScreen: true,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#BF4E1E',
      backgroundUrl:
          'https://cdn-9.motorsport.com/images/mgl/6D1XbeV0/s800/max-verstappen-red-bull-racing.jpg',
      actionColor: '#BF4E1E',
      incomingCallNotificationChannelName: 'Incoming Call',
      missedCallNotificationChannelName: 'Missed Call',
    ),
  );

  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

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

  FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
    switch (event!.event) {
      case Event.actionCallAccept:
        log("Call Accepted! Extra data: ${event.body}");
        break;
      case Event.actionCallDecline:
        print("Call Declined");
        break;
      case Event.actionCallTimeout:
        print("Call Timed Out");
        break;
      default:
        break;
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseAppCheck.instance.activate(
    providerAndroid: AndroidDebugProvider(),
    providerApple: AppleDebugProvider(),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Listen for messages while the app is in the FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'incoming_call') {
        showCallkitIncoming(message.data);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VoiceCare',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'GoogleSans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBurntOrange,
          primary: kBurntOrange,
          secondary: kMustardGold,
          surface: Color(0xFFF2E9E9),
        ),
        scaffoldBackgroundColor: const Color(0xFFF2E9E9),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: kPrimaryBrown,
            fontWeight: FontWeight.bold,
            fontFamily: 'GoogleSans',
          ),
          bodyMedium: TextStyle(color: kPrimaryBrown, fontFamily: 'GoogleSans'),
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

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

// }
