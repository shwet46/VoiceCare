import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getter for the current user
  User? get currentUser => _auth.currentUser;

  // Static method to ensure dotenv is loaded before the app starts
  static Future<void> initEnv() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      print("Error loading .env file: $e");
    }
  }

  // --- EMAIL FLOW ---

  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // IMPORTANT: Update display name immediately after registration
      await result.user?.updateDisplayName(name);
      await result.user?.reload(); 

      return result;
    } on FirebaseAuthException catch (e) {
      // Catch specific Firebase errors for better debugging
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // --- PHONE FLOW ---

  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required Function(PhoneAuthCredential) onCompleted,
    required Function(FirebaseAuthException) onFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onCompleted,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onTimeout,
    );
  }

  Future<UserCredential> signInWithOtp(
    String verificationId,
    String smsCode, [
    String? name,
  ]) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      // Update name if this is a new phone user
      if (name != null && name.isNotEmpty && result.user != null) {
        await result.user!.updateDisplayName(name);
        await result.user!.reload();
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Helper method to make sense of Firebase errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'No user found for that email.';
      case 'wrong-password': return 'Wrong password provided.';
      case 'email-already-in-use': return 'Account already exists for this email.';
      case 'invalid-phone-number': return 'The phone number is not valid.';
      default: return e.message ?? 'An unknown error occurred.';
    }
  }
}