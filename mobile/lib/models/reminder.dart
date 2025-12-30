import 'dart:convert';

class Reminder {
  final String id;
  final String time;
  final String title;
  final String subtitle;
  final String type;
  final String status;
  final String priority;
  final String icon;

  Reminder({
    required this.id,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.status,
    required this.priority,
    required this.icon,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      time: json['time'],
      title: json['title'],
      subtitle: json['subtitle'],
      type: json['type'],
      status: json['status'],
      priority: json['priority'],
      icon: json['icon'],
    );
  }

  static List<Reminder> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((e) => Reminder.fromJson(e)).toList();
  }
}

class ReminderData {
  final String userName;
  final String date;
  final String completionStats;
  final List<Reminder> reminders;

  ReminderData({
    required this.userName,
    required this.date,
    required this.completionStats,
    required this.reminders,
  });

  factory ReminderData.fromJson(Map<String, dynamic> json) {
    return ReminderData(
      userName: json['user_name'],
      date: json['date'],
      completionStats: json['completion_stats'],
      reminders: Reminder.listFromJson(json['reminders']),
    );
  }
}
