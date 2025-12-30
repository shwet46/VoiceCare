import 'package:flutter/material.dart';
import '../models/call_log.dart';

class CallLogDetailScreen extends StatelessWidget {
  final CallLog log;
  const CallLogDetailScreen({Key? key, required this.log}) : super(key: key);

  // THEME COLORS
  static const Color primaryOrange = Color(0xFFE85D32);
  static const Color bgColor = Color(0xFFF9FAFB);
  static const Color summaryIcon = Color(0xFF1976D2);
  static const Color summaryIconBg = Color(0xFFBBDEFB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone, color: primaryOrange, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Call Transcript',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: primaryOrange,
                fontFamily: 'GoogleSans',
                fontSize: 20,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: primaryOrange),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // -------- CALL SUMMARY CARD --------
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: primaryOrange.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          log.status == 'Successful'
                              ? Icons.check_circle_rounded
                              : log.status == 'Missed'
                              ? Icons.cancel_rounded
                              : Icons.snooze,
                          color: log.status == 'Successful'
                              ? Colors.green
                              : log.status == 'Missed'
                              ? Colors.red
                              : Colors.orange,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            log.title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: primaryOrange,
                              fontFamily: 'GoogleSans',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 15,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          log.date,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontFamily: 'GoogleSans',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 15,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          log.time,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontFamily: 'GoogleSans',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.timer, size: 15, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          log.duration,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontFamily: 'GoogleSans',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: summaryIconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.summarize_outlined,
                            size: 18,
                            color: summaryIcon,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            log.summary,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Colors.black87,
                              fontFamily: 'GoogleSans',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // -------- TRANSCRIPT HEADER --------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: const [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: primaryOrange,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Conversation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryOrange,
                      fontFamily: 'GoogleSans',
                    ),
                  ),
                ],
              ),
            ),
            // -------- CHAT TRANSCRIPT --------
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                itemCount: log.transcript.length,
                itemBuilder: (context, index) {
                  final entry = log.transcript[index];
                  final isUser = entry.role == 'user';
                  return _chatBubble(entry.text, isUser);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------- CHAT BUBBLE --------
  Widget _chatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? primaryOrange.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: isUser
                ? const Radius.circular(14)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: isUser ? primaryOrange : Colors.black87,
          ),
        ),
      ),
    );
  }
}
