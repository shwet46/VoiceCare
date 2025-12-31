import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> reminders = [];
  bool isLoading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Color primaryOrange = Color(0xFFE85D32);
  static const Color bgColor = Color(0xFFF8F9FB);

  @override
  void initState() {
    super.initState();
    _fetchDbReminders();
  }

  /// Helper to format "1900-01-01T14:00:00" or "14:00:00" to readable time
  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return "No time set";
    try {
      // Handles ISO format from your screenshot: 1900-01-01T14:00:00
      String timePart = timeStr.contains('T') ? timeStr.split('T')[1] : timeStr;
      List<String> parts = timePart.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      final minuteStr = minute.toString().padLeft(2, '0');

      return "$hour12:$minuteStr $period";
    } catch (e) {
      return timeStr; // Fallback to raw string if parsing fails
    }
  }

  Future<void> _fetchDbReminders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      // Query updated to match your screenshot (status: "pending")
      final querySnapshot = await _firestore
          .collection('reminders')
          .where('user_id', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      final reminderList = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      if (mounted) {
        setState(() {
          reminders = reminderList;
          isLoading = false;
        });
      }
    } catch (e) {
      log("Reminder Fetch Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryOrange)),
      );
    }

    final String userName = _auth.currentUser?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $userName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Scheduled Reminders',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: reminders.isEmpty
                    ? const Center(child: Text("No pending reminders set"))
                    : RefreshIndicator(
                        onRefresh: _fetchDbReminders,
                        color: primaryOrange,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: reminders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _buildReminderCard(reminders[index]);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> data) {
    IconData icon;
    // Map icons based on the 'type' field in your screenshot
    switch (data['type']) {
      case 'reminder':
        icon = Icons.notifications_active;
        break;
      case 'medication':
        icon = Icons.medication;
        break;
      default:
        icon = Icons.alarm;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: primaryOrange),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Mapping to "medication_name" from your screenshot
                  data['medication_name'] ?? 'Reminder',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if ((data['about'] ?? '').isNotEmpty)
                  Text(
                    data['about'],
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.black45,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(data['scheduled_time']),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: primaryOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
