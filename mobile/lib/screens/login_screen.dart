import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Ensure this matches your file structure
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();

  // State Variables
  String? _verificationId;
  String _authMethod = 'email'; 
  bool _isRegistering = false; 
  String _message = '';
  bool _isLoading = false;

  void _handleEmailAuth() async {
    setState(() { _isLoading = true; _message = ''; });
    try {
      if (_isRegistering) {
        // REGISTER
        await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
        setState(() => _message = 'Account created successfully!');
      } else {
        // LOGIN
        await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        setState(() => _message = 'Logged in successfully!');
      }
    } catch (e) {
      setState(() => _message = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sendPhoneCode() async {
    setState(() => _isLoading = true);
    await _authService.verifyPhoneNumber(
      _phoneController.text.trim(),
      onCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        setState(() => _message = 'Auto-verified and logged in!');
      },
      onFailed: (error) => setState(() => _message = 'Failed: ${error.message}'),
      onCodeSent: (verId, resendToken) {
        setState(() {
          _verificationId = verId;
          _message = 'Code sent to ${_phoneController.text}';
        });
      },
      onTimeout: (verId) => setState(() => _verificationId = verId),
    );
    setState(() => _isLoading = false);
  }

  void _verifyOtp() async {
    setState(() => _isLoading = true);
    try {
      // Pass the name even for phone auth so it updates the profile if provided
      await _authService.signInWithOtp(
        _verificationId!,
        _smsCodeController.text.trim(),
        _isRegistering ? _nameController.text.trim() : null,
      );
      setState(() => _message = 'Phone Auth Successful!');
    } catch (e) {
      setState(() => _message = 'Invalid Code: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegistering ? 'Create Account' : 'Welcome Back')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 1. Toggle between Email and Phone
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'email', label: Text('Email'), icon: Icon(Icons.email)),
                ButtonSegment(value: 'phone', label: Text('Phone'), icon: Icon(Icons.phone)),
              ],
              selected: {_authMethod},
              onSelectionChanged: (val) => setState(() => _authMethod = val.first),
            ),
            const SizedBox(height: 20),

            // 2. Name Field (Only shown if Registering)
            if (_isRegistering)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              ),
            const SizedBox(height: 12),

            // 3. Conditional Fields (Email vs Phone)
            if (_authMethod == 'email') ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleEmailAuth,
                child: Text(_isRegistering ? 'Sign Up' : 'Sign In'),
              ),
            ] else ...[
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone (e.g., +123456789)', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              if (_verificationId == null)
                ElevatedButton(onPressed: _sendPhoneCode, child: const Text('Send Verification Code'))
              else ...[
                TextField(
                  controller: _smsCodeController,
                  decoration: const InputDecoration(labelText: 'Enter OTP Code', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _verifyOtp, child: const Text('Verify & Continue')),
              ],
            ],

            // 4. Toggle Login/Register
            TextButton(
              onPressed: () => setState(() => _isRegistering = !_isRegistering),
              child: Text(_isRegistering ? 'Already have an account? Login' : 'New user? Create account'),
            ),

            if (_isLoading) const CircularProgressIndicator(),
            
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_message, style: TextStyle(color: _message.contains('Error') ? Colors.red : Colors.green)),
            ),
          ],
        ),
      ),
    );
  }
}