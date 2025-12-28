import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth_screen.dart';

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
        // Using the Sage Green and Burnt Orange for the color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBurntOrange,
          primary: kBurntOrange,
          secondary: kMustardGold,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFFDFCFB), // Off-white for warmth
        
        // Consistent Text Styling
        textTheme: const TextTheme(
          headlineSmall: TextStyle(color: kPrimaryBrown, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: kPrimaryBrown),
        ),

        // Modern Input Styling for AuthScreen and elsewhere
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

        // Customizing Button Styles
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kBurntOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}



class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.data == null) {
            return const AuthScreen();
          }
          return const MyHomePage(title: 'VoiceCare');
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: kBurntOrange)),
        );
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String userIdentifier = user?.email ?? user?.phoneNumber ?? "Guest";
    final String userName = user?.displayName ?? "User";

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBrown)),
        centerTitle: true,
        backgroundColor: kSageGreen.withOpacity(0.2),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: kPrimaryBrown),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // User Profile Section
            CircleAvatar(
              radius: 50,
              backgroundColor: kSageGreen,
              child: Text(
                userName[0].toUpperCase(),
                style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            Text('Welcome back,', style: TextStyle(color: kOliveGreen, fontSize: 16)),
            Text(
              userName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: kMustardGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                userIdentifier,
                style: const TextStyle(color: kPrimaryBrown, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 48),
            
            // Feature Card
            Card(
              elevation: 0,
              color: kSageGreen.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.mic_none_rounded, size: 48, color: kBurntOrange),
                    const SizedBox(height: 16),
                    const Text(
                      'Ready to begin?',
                      style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBrown),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the button below to start your voice session.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kPrimaryBrown, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start Voice Session'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
}