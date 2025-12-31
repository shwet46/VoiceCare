import 'package:flutter/material.dart';
import 'package:voicecare/services/auth_service.dart';
import 'package:voicecare/models/user_profile.dart';
import 'package:voicecare/services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;

  static const Color primaryOrange = Color(0xFFE85D32);

  final _fullNameCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _carePreferencesCtrl = TextEditingController();
  final _healthConcernsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicationsCtrl.dispose();
    _carePreferencesCtrl.dispose();
    _healthConcernsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileService().fetchUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : RefreshIndicator(
              color: primaryOrange,
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFF2F2F2),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      _profile?.fullName ?? user?.displayName ?? 'Your Name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'GoogleSans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontFamily: 'GoogleSans',
                      ),
                    ),

                    const SizedBox(height: 28),

                    _infoCard(),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _showEditProfileDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'GoogleSans',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------------- INFO CARD ----------------

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Emergency contacts removed
          _row('Allergies', _profile?.allergies),
          _divider(),
          _row('Medications', _profile?.medications),
          _divider(),
          _row('Care Preferences', _profile?.carePreferences),
          _divider(),
          _row('Health Concerns', _profile?.healthConcerns),
        ],
      ),
    );
  }

  // Change the parameter type from String? to dynamic or List<String>?
  Widget _row(String label, List<String>? values) {
    // Join the list items with a comma for display
    final String displayValue = values?.join(", ") ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              fontFamily: 'GoogleSans',
            ),
          ),
        ),
        Expanded(
          child: Text(
            displayValue.isNotEmpty ? displayValue : 'Not set',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'GoogleSans',
              color: displayValue.isEmpty ? Colors.grey : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 10),
    child: Divider(height: 1),
  );

  // ---------------- EDIT FORM ----------------

  void _showEditProfileDialog() {
    final p = _profile ?? UserProfile();

    _fullNameCtrl.text = p.fullName ?? '';
    // Convert Lists to Strings for the TextFields
    _allergiesCtrl.text = p.allergies?.join(", ") ?? '';
    _medicationsCtrl.text = p.medications?.join(", ") ?? '';
    _carePreferencesCtrl.text = p.carePreferences?.join(", ") ?? '';
    _healthConcernsCtrl.text = p.healthConcerns?.join(", ") ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Medical Profile'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _field('Full Name', _fullNameCtrl),
              // Emergency contacts removed
              _section('Medical'),
              _field('Allergies', _allergiesCtrl),
              _field('Medications', _medicationsCtrl),
              _field('Care Preferences', _carePreferencesCtrl),
              _field('Health Concerns', _healthConcernsCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    ),
  );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    // Helper to turn "Peanuts, Dust" into ["Peanuts", "Dust"]
    List<String> _parseInput(String input) {
      if (input.trim().isEmpty) return [];
      return input
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final updated = UserProfile(
      fullName: _fullNameCtrl.text.trim(),
      allergies: _parseInput(_allergiesCtrl.text),
      medications: _parseInput(_medicationsCtrl.text),
      carePreferences: _parseInput(_carePreferencesCtrl.text),
      healthConcerns: _parseInput(_healthConcernsCtrl.text),
      // Preserve existing contacts if any
      emergencyContactsSummary: _profile?.emergencyContactsSummary,
    );

    await ProfileService().updateUserProfile(updated);

    if (mounted) {
      setState(() {
        _profile = updated;
        _isSaving = false;
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }
}
