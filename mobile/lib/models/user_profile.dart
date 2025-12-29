class UserProfile {
  final String? fullName;
  final String? allergies;
  final String? medications;
  final String? carePreferences;
  final String? healthConcerns;

  UserProfile({
    this.fullName,
    this.allergies,
    this.medications,
    this.carePreferences,
    this.healthConcerns,
    this.emergencyContactsSummary,
  });

  final List<Map<String, dynamic>>? emergencyContactsSummary;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      fullName: map['full_name'] as String?,
      allergies: map['allergies'] as String?,
      medications: map['medications'] as String?,
      carePreferences: map['care_preferences'] as String?,
      healthConcerns: map['health_concerns'] as String?,
      emergencyContactsSummary: (map['emergency_contacts_summary'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'allergies': allergies,
      'medications': medications,
      'care_preferences': carePreferences,
      'health_concerns': healthConcerns,
      if (emergencyContactsSummary != null)
        'emergency_contacts_summary': emergencyContactsSummary,
    };
  }
}
