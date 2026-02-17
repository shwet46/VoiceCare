import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicecare/models/user_profile.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserProfile?> fetchUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data()?['profile'] != null) {
        final profile = UserProfile.fromMap(
          Map<String, dynamic>.from(doc.data()!['profile']),
        );
        // If Firestore has no name, use registration name from Auth
        if (profile.fullName == null || profile.fullName!.isEmpty) {
          return UserProfile(
            fullName: user.displayName,
            allergies: profile.allergies,
            medications: profile.medications,
            carePreferences: profile.carePreferences,
            healthConcerns: profile.healthConcerns,
          );
        }
        return profile;
      }

      // New user: return a profile initialized with the name they registered with
      return UserProfile(fullName: user.displayName);
    } catch (e) {
      print("Fetch Error: $e");
      return null;
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update Firebase Auth Display Name if it changed
      if (profile.fullName != null && profile.fullName != user.displayName) {
        await user.updateDisplayName(profile.fullName);
        await user.reload();
      }

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'profile': profile.toMap(),
        'last_updated': FieldValue.serverTimestamp(),
        'email': user.email,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Update Error: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserReminders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('reminders')
          .where('user_id', isEqualTo: user.uid)
          // Updated to 'pending' to match your screenshot
          .where('status', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      log("Reminder Fetch Error: $e");
      return [];
    }
  }
}
