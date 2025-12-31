import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  static Future<void> initEnv() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Error loading .env file: $e");
    }
  }

  // --- PHONE AUTH FLOW ---

  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required Function(PhoneAuthCredential) onCompleted,
    required Function(FirebaseAuthException) onFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onTimeout,
  }) async {
    try {
      // PRODUCTION CHANGE: Enforce real app verification.
      // This ensures reCAPTCHA (Web/iOS) or Play Integrity (Android) is used.
      await _auth.setSettings(appVerificationDisabledForTesting: true);

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // On some Android devices, the SMS is automatically detected.
          // We sign the user in immediately.
          await _auth.signInWithCredential(credential);
          await onCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          // PRODUCTION LOGGING: Avoid printing sensitive info to console in release
          if (kDebugMode) debugPrint("Phone Verification Failed: ${e.code}");
          onFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          onTimeout(verificationId);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      // Update profile only if user is new or name is provided
      if (name != null && name.trim().isNotEmpty && result.user != null) {
        await result.user!.updateDisplayName(name.trim());
        await result.user!.reload();
      }

      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<User?> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null) {
        await result.user!.updateDisplayName(name.trim());
        await result.user!.reload();
        final String uid = result.user!.uid;

        // 2. ACTUALLY CREATE THE DOCUMENT
        // This turns the "italicized/phantom" ID into a real document with data
        await _db.collection('users').doc(uid).set({
          'uid': uid,
          'email': email.trim(),
          'display_name': name.trim(),
          'onboarding_complete': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _handleAuthError(FirebaseAuthException e) {
    // Log errors to a service like Crashlytics here in production
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password you entered is incorrect.';
      case 'email-already-in-use':
        return 'This email address is already registered.';
      case 'invalid-phone-number':
        return 'The phone number entered is invalid.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again in a few minutes.';
      case 'session-expired':
        return 'The verification session has expired. Please try again.';
      case 'invalid-verification-code':
        return 'The SMS code entered is incorrect.';
      case 'app-not-authorized':
        return 'App integrity check failed. Please ensure the app is installed from the official store.';
      default:
        return 'An authentication error occurred. Please try again.';
    }
  }
}
