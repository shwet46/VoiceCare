import 'package:flutter/material.dart';
import 'package:voicecare/models/user_profile.dart';
import 'package:voicecare/services/profile_service.dart';
import 'package:voicecare/screens/main_page.dart';

class OnboardingFormPage extends StatefulWidget {
  const OnboardingFormPage({Key? key}) : super(key: key);

  @override
  State<OnboardingFormPage> createState() => _OnboardingFormPageState();
}

class _OnboardingFormPageState extends State<OnboardingFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _carePreferencesController = TextEditingController();
  final _healthConcernsController = TextEditingController();

  bool _saving = false;

  static const Color primaryOrange = Color(0xFFE85D32);

  @override
  void dispose() {
    _allergiesController.dispose();
    _medicationsController.dispose();
    _carePreferencesController.dispose();
    _healthConcernsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final profile = UserProfile(
      allergies: _allergiesController.text.trim(),
      medications: _medicationsController.text.trim(),
      carePreferences: _carePreferencesController.text.trim(),
      healthConcerns: _healthConcernsController.text.trim(),
    );

    await ProfileService().updateUserProfile(profile);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  void _skip() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text(
              'Skip',
              style: TextStyle(
                color: primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Medical Information'),
                _field(
                  controller: _allergiesController,
                  label: 'Allergies',
                  icon: Icons.warning_amber_rounded,
                ),
                _field(
                  controller: _medicationsController,
                  label: 'Medications',
                  icon: Icons.medication,
                ),
                _field(
                  controller: _carePreferencesController,
                  label: 'Care Preferences',
                  icon: Icons.favorite_border,
                ),
                _field(
                  controller: _healthConcernsController,
                  label: 'Health Concerns',
                  icon: Icons.health_and_safety_outlined,
                  maxLines: 2,
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save & Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- UI HELPERS ----------------

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryOrange),
          filled: true,
          fillColor: const Color(0xFFF9F9F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
