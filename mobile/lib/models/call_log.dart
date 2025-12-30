import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class CallLog {
  final String logId;
  final String date;
  final String time;
  final String duration;
  final String status;
  final String title;
  final String summary;
  final List<TranscriptEntry> transcript;

  CallLog({
    required this.logId,
    required this.date,
    required this.time,
    required this.duration,
    required this.status,
    required this.title,
    required this.summary,
    required this.transcript,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      logId: json['log_id'],
      date: json['date'],
      time: json['time'],
      duration: json['duration'],
      status: json['status'],
      title: json['title'],
      summary: json['summary'],
      transcript: (json['transcript'] as List<dynamic>)
          .map((e) => TranscriptEntry.fromJson(e))
          .toList(),
    );
  }
}

class TranscriptEntry {
  final String role;
  final String text;

  TranscriptEntry({required this.role, required this.text});

  factory TranscriptEntry.fromJson(Map<String, dynamic> json) {
    return TranscriptEntry(role: json['role'], text: json['text']);
  }
}

class CallLogData {
  final String userName;
  final List<CallLog> callHistory;

  CallLogData({required this.userName, required this.callHistory});

  factory CallLogData.fromJson(Map<String, dynamic> json) {
    return CallLogData(
      userName: json['user_name'],
      callHistory: (json['call_history'] as List<dynamic>)
          .map((e) => CallLog.fromJson(e))
          .toList(),
    );
  }
}
