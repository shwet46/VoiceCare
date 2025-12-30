import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/call_log.dart';
import 'call_log_detail_screen.dart';

class CallLogScreen extends StatefulWidget {
  const CallLogScreen({Key? key}) : super(key: key);

  @override
  State<CallLogScreen> createState() => _CallLogScreenState();
}

class _CallLogScreenState extends State<CallLogScreen> {
  CallLogData? callLogData;
  bool isLoading = true;

  // THEME COLORS (consistent with app)
  static const Color primaryOrange = Color(0xFFE85D32);
  static const Color bgColor = Color.fromARGB(255, 255, 255, 255);
  static const Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    loadCallLogData();
  }

  Future<void> loadCallLogData() async {
    final String jsonString = await rootBundle.loadString(
      'assets/test/calls.json',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonString);

    setState(() {
      callLogData = CallLogData.fromJson(jsonMap);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : callLogData == null
          ? const Center(child: Text('No call logs available'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: callLogData!.callHistory.length,
              itemBuilder: (context, index) {
                final log = callLogData!.callHistory[index];
                return _callLogCard(log);
              },
            ),
    );
  }

  // ---------------- CALL LOG CARD ----------------
  Widget _callLogCard(CallLog log) {
    final iconData = log.status == 'Successful'
        ? Icons.call_rounded
        : log.status == 'Missed'
        ? Icons.call_missed_rounded
        : Icons.call_received_rounded;

    final iconColor = log.status == 'Successful'
        ? Colors.green
        : log.status == 'Missed'
        ? Colors.red
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          log.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${log.date} • ${log.time} • ${log.duration}',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.black38,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CallLogDetailScreen(log: log),
            ),
          );
        },
      ),
    );
  }
}
