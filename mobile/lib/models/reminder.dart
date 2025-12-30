class ReminderDetails {
  final String reminderId;
  final String category;
  final String title;
  final String? medicationName;
  final String? dosage;
  final String? activityType;
  final String scheduledTime;
  final bool isRecurring;

  ReminderDetails({
    required this.reminderId,
    required this.category,
    required this.title,
    this.medicationName,
    this.dosage,
    this.activityType,
    required this.scheduledTime,
    required this.isRecurring,
  });

  factory ReminderDetails.fromJson(Map<String, dynamic> json) {
    return ReminderDetails(
      reminderId: json['reminder_id'],
      category: json['category'],
      title: json['title'],
      medicationName: json['medication_name'],
      dosage: json['dosage'],
      activityType: json['activity_type'],
      scheduledTime: json['scheduled_time'],
      isRecurring: json['is_recurring'] ?? false,
    );
  }
}

class Outcome {
  final String callStatus;
  final String actionStatus;
  final bool isRescheduled;
  final String? rescheduledFromTime;
  final String? userReasoning;
  final int? attemptsMade;

  Outcome({
    required this.callStatus,
    required this.actionStatus,
    required this.isRescheduled,
    this.rescheduledFromTime,
    this.userReasoning,
    this.attemptsMade,
  });

  factory Outcome.fromJson(Map<String, dynamic> json) {
    return Outcome(
      callStatus: json['call_status'],
      actionStatus: json['action_status'],
      isRescheduled: json['is_rescheduled'] ?? false,
      rescheduledFromTime:
          json['rescheduled_from_time'] ??
          json['rescheduled_from_time'] ??
          json['rescheduled_from_time'],
      userReasoning: json['user_reasoning'],
      attemptsMade: json['attempts_made'],
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

  static List<TranscriptEntry> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((e) => TranscriptEntry.fromJson(e)).toList();
  }
}

class Meta {
  final String startedAt;
  final String endedAt;
  final int? callDurationSeconds;
  final String? voiceId;

  Meta({
    required this.startedAt,
    required this.endedAt,
    this.callDurationSeconds,
    this.voiceId,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      startedAt: json['started_at'],
      endedAt: json['ended_at'],
      callDurationSeconds: json['call_duration_seconds'],
      voiceId: json['voice_id'],
    );
  }
}

class Reminder {
  final String userId;
  final String callId;
  final ReminderDetails reminderDetails;
  final Outcome outcome;
  final List<TranscriptEntry> transcript;
  final Meta meta;

  Reminder({
    required this.userId,
    required this.callId,
    required this.reminderDetails,
    required this.outcome,
    required this.transcript,
    required this.meta,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      userId: json['user_id'],
      callId: json['call_id'],
      reminderDetails: ReminderDetails.fromJson(json['reminder_details']),
      outcome: Outcome.fromJson(json['outcome']),
      transcript: TranscriptEntry.listFromJson(json['transcript'] ?? []),
      meta: Meta.fromJson(json['meta']),
    );
  }

  static List<Reminder> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((e) => Reminder.fromJson(e)).toList();
  }
}
