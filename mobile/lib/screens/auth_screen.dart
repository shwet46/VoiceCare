import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>(); // Added for validation

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isEmailMode = true;
  bool _isRegistering = false;
  bool _otpSent = false;
  bool _isLoading = false;
  String? _verId;
  String _completePhoneNumber = ''; // Stores formatted number (e.g. +91...)
  String _message = '';

  // Palette Colors
  final Color primaryBrown = const Color(0xFF834820);
  final Color burntOrange = const Color(0xFFBF4E1E);
  final Color mustardGold = const Color(0xFFDD9239);
  final Color sageGreen = const Color(0xFFB0D0BF);
  final Color oliveGreen = const Color(0xFF929D65);

  void _setStatus(String msg, {bool loading = false}) {
    setState(() {
      _message = msg;
      _isLoading = loading;
    });
  }

  void _handleEmailSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    _setStatus('', loading: true);

    try {
      if (_isRegistering) {
        await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
      } else {
        await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
    } catch (e) {
      _setStatus(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePhoneSubmit() async {
    if (!_otpSent) {
      // Manual check for phone since IntlPhoneField has its own validation
      if (_completePhoneNumber.isEmpty) {
        _setStatus("Please enter a valid phone number");
        return;
      }
      _setStatus('', loading: true);
      
      await _authService.verifyPhoneNumber(
        _completePhoneNumber,
        onCompleted: (_) {},
        onFailed: (e) => _setStatus(e.message ?? "Verification failed"),
        onCodeSent: (id, _) => setState(() {
          _verId = id;
          _otpSent = true;
          _isLoading = false;
          _message = "OTP sent to $_completePhoneNumber";
        }),
        onTimeout: (id) => _verId = id,
      );
    } else {
      if (_otpController.text.length < 6) {
        _setStatus("Enter 6-digit OTP");
        return;
      }
      _setStatus('', loading: true);
      try {
        await _authService.signInWithOtp(
          _verId!,
          _otpController.text.trim(),
          _isRegistering ? _nameController.text.trim() : null,
        );
      } catch (e) {
        _setStatus("Invalid Code");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: oliveGreen, size: 20),
      labelStyle: TextStyle(color: primaryBrown, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: sageGreen),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: burntOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sageGreen.withOpacity(0.2),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Icon(Icons.eco_rounded, size: 70, color: burntOrange),
                const SizedBox(height: 10),
                Text("VoiceCare",
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: primaryBrown,
                        letterSpacing: 1.5)),
                const SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: primaryBrown.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildToggleButtons(),
                      const SizedBox(height: 24),
                      if (_isRegistering && !_otpSent) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputStyle("Full Name", Icons.person_outline),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _isEmailMode ? _buildEmailFields() : _buildPhoneFields(),
                      const SizedBox(height: 24),
                      _isLoading
                          ? CircularProgressIndicator(color: burntOrange)
                          : _buildSubmitButton(),
                      const SizedBox(height: 16),
                      _buildSwitchAuthMode(),
                      if (_message.isNotEmpty) _buildMessage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return ToggleButtons(
      isSelected: [_isEmailMode, !_isEmailMode],
      onPressed: (index) => setState(() {
        _isEmailMode = index == 0;
        _otpSent = false;
        _message = '';
      }),
      borderRadius: BorderRadius.circular(12),
      selectedColor: Colors.white,
      fillColor: mustardGold,
      color: primaryBrown,
      constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
      children: const [Text("Email"), Text("Phone")],
    );
  }

  Widget _buildEmailFields() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          decoration: _inputStyle("Email Address", Icons.email_outlined),
          keyboardType: TextInputType.emailAddress,
          validator: (v) => !v!.contains('@') ? "Invalid email" : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          decoration: _inputStyle("Password", Icons.lock_outline),
          obscureText: true,
          validator: (v) => v!.length < 6 ? "Min 6 characters" : null,
        ),
      ],
    );
  }

  Widget _buildPhoneFields() {
    return Column(
      children: [
        if (!_otpSent)
          IntlPhoneField(
            controller: _phoneController,
            decoration: _inputStyle("Phone Number", Icons.phone_android),
            initialCountryCode: 'US',
            onChanged: (phone) {
              _completePhoneNumber = phone.completeNumber;
            },
            style: TextStyle(color: primaryBrown),
          )
        else
          TextFormField(
            controller: _otpController,
            decoration: _inputStyle("6-Digit Code", Icons.pin_outlined),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isEmailMode ? _handleEmailSubmit : _handlePhoneSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: burntOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          _otpSent ? "VERIFY OTP" : (_isRegistering ? "CREATE ACCOUNT" : "SIGN IN"),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSwitchAuthMode() {
    return TextButton(
      onPressed: () => setState(() {
        _isRegistering = !_isRegistering;
        _otpSent = false;
        _message = '';
      }),
      child: Text(
        _isRegistering ? "Already have an account? Login" : "New here? Create an Account",
        style: TextStyle(color: burntOrange, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMessage() {
    bool isError = _message.toLowerCase().contains("failed") || _message.toLowerCase().contains("invalid");
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        _message,
        textAlign: TextAlign.center,
        style: TextStyle(color: isError ? Colors.red : oliveGreen, fontSize: 13),
      ),
    );
  }
}