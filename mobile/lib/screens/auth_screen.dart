import 'package:flutter/material.dart';
import 'package:voicecare/widgets/country_code_dropdown.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _obscurePassword = true;
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();

  // State Variables
  bool _isEmailMode = true;
  bool _isRegistering = false;
  bool _otpSent = false;
  bool _isLoading = false;
  String? _verId;
  String _completePhoneNumber = '';
  String _message = '';

  // Theme Config
  static const Color primaryOrange = Color(0xFFDE9243);
  static const Color darkOrange = Color(0xFFC4561D);
  static const String customFont = 'GoogleSans';

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePhoneSubmit() async {
    if (!_otpSent) {
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
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputStyle(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 14,
        fontFamily: customFont,
      ),
      floatingLabelStyle: const TextStyle(
        color: darkOrange,
        fontWeight: FontWeight.bold,
        fontFamily: customFont,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryOrange),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryOrange),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryOrange, width: 2),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text(
              'Voice',
              style: TextStyle(
                fontSize: 32,
                color: primaryOrange,
                fontWeight: FontWeight.w400,
                fontFamily: customFont,
              ),
            ),
            Text(
              'Care',
              style: TextStyle(
                fontSize: 32,
                color: darkOrange,
                fontWeight: FontWeight.w400,
                fontFamily: customFont,
              ),
            ),
          ],
        ),
        const Text(
          'Your digital friend, day and night.',
          style: TextStyle(
            fontSize: 15,
            color: Color.fromARGB(255, 0, 0, 0),
            fontFamily: customFont,
            height: 1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: customFont),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 50),
                  Text(
                    _isRegistering ? 'Welcome' : 'Welcome Back',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      fontFamily: customFont,
                      color: Colors.black,
                    ),
                  ),
                  RichText(
                    text: const TextSpan(
                      text: 'To ',
                      style: TextStyle(
                        fontSize: 36,
                        color: Colors.black,
                        fontWeight: FontWeight.w300,
                        fontFamily: customFont,
                      ),
                      children: [
                        TextSpan(
                          text: 'Voice',
                          style: TextStyle(
                            fontSize: 36,
                            color: primaryOrange,
                            fontWeight: FontWeight.w600,
                            fontFamily: customFont,
                          ),
                        ),
                        TextSpan(
                          text: 'Care',
                          style: TextStyle(
                            fontSize: 36,
                            color: darkOrange,
                            fontWeight: FontWeight.w600,
                            fontFamily: customFont,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey("$_isEmailMode$_isRegistering$_otpSent"),
                      children: [
                        if (_isRegistering && !_otpSent) ...[
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(fontFamily: customFont),
                            decoration: _inputStyle(
                              'Full Name',
                              hint: 'eg. John Doe',
                            ),
                            validator: (v) =>
                                v!.isEmpty ? "Name is required" : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _isEmailMode
                            ? _buildEmailFields()
                            : _buildPhoneFields(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: primaryOrange,
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isEmailMode
                                ? _handleEmailSubmit
                                : _handlePhoneSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _otpSent ? 'VERIFY OTP' : 'CONTINUE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: customFont,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() {
                        _isRegistering = !_isRegistering;
                        _otpSent = false;
                        _message = '';
                      }),
                      child: Text(
                        _isRegistering
                            ? "Already have an account? Sign In"
                            : "New here? Create an account",
                        style: const TextStyle(
                          color: primaryOrange,
                          fontWeight: FontWeight.w400,
                          fontFamily: customFont,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'or',
                          style: TextStyle(fontFamily: customFont),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _methodButton(Icons.email_outlined, true),
                      const SizedBox(width: 25),
                      _methodButton(Icons.phone_android_outlined, false),
                    ],
                  ),
                  if (_message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(
                        child: Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _message.contains('failed')
                                ? Colors.red
                                : primaryOrange,
                            fontSize: 13,
                            fontFamily: customFont,
                          ),
                        ),
                      ),
                    ),
                  // const SizedBox(height: 50),
                  // const Center(
                  //   child: Text(
                  //     'Your digital friend, day and night.',
                  //     style: TextStyle(
                  //       color: primaryOrange,
                  //       fontSize: 12,
                  //       fontFamily: customFont,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailFields() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          style: const TextStyle(fontFamily: customFont),
          decoration: _inputStyle('Email Address', hint: 'eg. name@email.com'),
          validator: (v) => !v!.contains('@') ? "Invalid email" : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(fontFamily: customFont),
          decoration: _inputStyle('Password', hint: 'Min. 6 characters')
              .copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
          validator: (v) => v!.length < 6 ? "Min 6 characters" : null,
        ),
      ],
    );
  }

  Widget _buildPhoneFields() {
    if (_otpSent) {
      return TextFormField(
        controller: _otpController,
        style: const TextStyle(fontFamily: customFont),
        decoration: _inputStyle('Verification Code', hint: '6-digit OTP'),
        keyboardType: TextInputType.number,
        maxLength: 6,
      );
    }
    return CountryCodeDropdown(
      controller: _phoneController,
      decoration: _inputStyle('Phone Number', hint: '84XXX XXXXX'),
      initialCountryCode: 'US',
      onChanged: (number) => _completePhoneNumber = number,
      style: const TextStyle(fontFamily: customFont),
    );
  }

  Widget _methodButton(IconData icon, bool mode) {
    bool isSelected = _isEmailMode == mode;
    return InkWell(
      onTap: () => setState(() {
        _isEmailMode = mode;
        _otpSent = false;
        _message = '';
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange.withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? darkOrange : primaryOrange,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          color: isSelected ? darkOrange : primaryOrange,
          size: 26,
        ),
      ),
    );
  }
}
