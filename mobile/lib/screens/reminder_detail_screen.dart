import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';

class ReminderDetailScreen extends StatelessWidget {
  final Reminder reminder;

  const ReminderDetailScreen({
    Key? key,
    required this.reminder,
  }) : super(key: key);

  static const Color primaryOrange = Color(0xFFE85D32);
  static const Color bgColor = Color(0xFFF7F8FA);

  String formatDateTime(String iso) {
    return DateFormat('dd MMM • hh:mm a')
        .format(DateTime.parse(iso).toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final d = reminder.reminderDetails;
    final o = reminder.outcome;
    final m = reminder.meta;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Reminder Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.6,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ───────────────── HERO CARD ─────────────────
              _card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _iconBox(),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              d.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _statusChip(o.actionStatus),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _keyValue(
                        Icons.schedule,
                        'Scheduled',
                        formatDateTime(d.scheduledTime),
                      ),
                      if (d.medicationName != null)
                        _keyValue(
                          Icons.medication_outlined,
                          'Medication',
                          d.medicationName!,
                        ),
                      if (d.dosage != null)
                        _keyValue(
                          Icons.science_outlined,
                          'Dosage',
                          d.dosage!,
                        ),
                      _keyValue(
                        Icons.repeat,
                        'Recurring',
                        d.isRecurring ? 'Yes' : 'No',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// ───────────────── OUTCOME ─────────────────
              _sectionTitle('Call Outcome'),
              _card(
                child: Column(
                  children: [
                    _keyValue(
                      Icons.call,
                      'Call Status',
                      o.callStatus,
                    ),
                    _keyValue(
                      Icons.check_circle_outline,
                      'Action Status',
                      o.actionStatus,
                    ),
                    _keyValue(
                      Icons.refresh,
                      'Rescheduled',
                      o.isRescheduled ? 'Yes' : 'No',
                    ),
                    if (o.rescheduledFromTime != null)
                      _keyValue(
                        Icons.schedule,
                        'Rescheduled From',
                        formatDateTime(o.rescheduledFromTime!),
                      ),
                    if (o.attemptsMade != null)
                      _keyValue(
                        Icons.repeat,
                        'Attempts',
                        '${o.attemptsMade}',
                      ),
                    if (o.userReasoning != null) ...[
                      const Divider(height: 24),
                      _keyValue(
                        Icons.info_outline,
                        'User Note',
                        o.userReasoning!,
                        multiline: true,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// ───────────────── TIMELINE ─────────────────
              _sectionTitle('Call Timeline'),
              _card(
                child: Column(
                  children: [
                    _keyValue(
                      Icons.play_circle_outline,
                      'Started',
                      formatDateTime(m.startedAt),
                    ),
                    _keyValue(
                      Icons.stop_circle_outlined,
                      'Ended',
                      formatDateTime(m.endedAt),
                    ),
                    if (m.callDurationSeconds != null)
                      _keyValue(
                        Icons.timer_outlined,
                        'Duration',
                        '${m.callDurationSeconds} seconds',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// ───────────────── CONVERSATION ─────────────────
              _sectionTitle('Conversation'),
              ...reminder.transcript.map(
                (t) => _chatBubble(
                  isAgent: t.role == 'agent',
                  text: t.text,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// ───────────────── UI HELPERS ─────────────────

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _card({Widget? child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );

  Widget _iconBox() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryOrange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.medication_outlined,
          size: 28,
          color: primaryOrange,
        ),
      );

  Widget _statusChip(String status) => Container(
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

  Widget _keyValue(
    IconData icon,
    String label,
    String value, {
    bool multiline = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment:
              multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );

  Widget _chatBubble({
    required bool isAgent,
    required String text,
  }) =>
      Align(
        alignment:
            isAgent ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: isAgent
                ? Colors.grey.shade200
                : primaryOrange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(text),
        ),
      );
}