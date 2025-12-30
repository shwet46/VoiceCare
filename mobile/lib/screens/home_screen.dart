import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import 'reminder_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Reminder? reminder;
  bool isLoading = true;

  static const Color primaryOrange = Color(0xFFE85D32);
  static const Color bgColor = Color(0xFFF8F9FB);

  @override
  void initState() {
    super.initState();
    loadReminder();
  }

  Future<void> loadReminder() async {
    final jsonString =
        await rootBundle.loadString('assets/test/rem.json');
    setState(() {
      reminder = Reminder.fromJson(json.decode(jsonString));
      isLoading = false;
    });
  }

  String formatTime(String iso) {
    return DateFormat('hh:mm a').format(
      DateTime.parse(iso).toLocal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: primaryOrange),
        ),
      );
    }

    final d = reminder!.reminderDetails;
    final o = reminder!.outcome;

    /// Extract user name from transcript
    String userName = 'User';
    final agentLine = reminder!.transcript.first.text;
    final match = RegExp(r'Hello ([^,]+)').firstMatch(agentLine);
    if (match != null) userName = match.group(1)!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Text(
                'Good Evening, $userName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your next reminder',
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 24),

              /// REMINDER CARD (ONLY CONTENT)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReminderDetailScreen(
                        reminder: reminder!,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(),
                  child: Row(
                    children: [
                      _iconBox(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${d.medicationName} • ${d.dosage}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: Colors.black45,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formatTime(d.scheduledTime),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _statusBadge(o.actionStatus),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// UI HELPERS

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      );

  Widget _iconBox() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.medication_outlined,
          size: 30,
          color: primaryOrange,
        ),
      );

  Widget _statusBadge(String status) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: status == 'completed'
              ? Colors.green.shade50
              : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: status == 'completed'
                ? Colors.green
                : primaryOrange,
          ),
        ),
      );
}