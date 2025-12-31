class UserProfile {
  final String? fullName;
  final List<String>? allergies;
  final List<String>? medications;
  final List<String>? carePreferences;
  final List<String>? healthConcerns;
  final List<Map<String, dynamic>>? emergencyContactsSummary;

  UserProfile({
    this.fullName,
    this.allergies,
    this.medications,
    this.carePreferences,
    this.healthConcerns,
    this.emergencyContactsSummary,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      fullName: map['full_name'] as String?,
      // Use a helper or cast to List<String>
      allergies: _toList(map['allergies']),
      medications: _toList(map['medications']),
      carePreferences: _toList(map['care_preferences']),
      healthConcerns: _toList(map['health_concerns']),
      emergencyContactsSummary: (map['emergency_contacts_summary'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }

  // Helper function to safely cast dynamic lists from Firestore
  static List<String>? _toList(dynamic value) {
    if (value == null) return null;
    return List<String>.from(value as List);
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
