import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import 'package:grocery_app/styles/colors.dart'; // Assuming you have this file for your AppColors

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  // --- STATE AND CONTROLLERS (LOGIC UNCHANGED) ---
  final TextEditingController _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _sendOtpError;
  String? _identifierType;

  // OTP Dialog State
  final TextEditingController _otpController = TextEditingController();

  // Password Reset State
  bool _showPasswordFields = false;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordError;
  bool _isResetLoading = false;
  String? _resetSuccess;

  // --- VALIDATION LOGIC (UNCHANGED) ---
  bool _isEmail(String input) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(input);
  }

  bool _isPhone(String input) {
    // Corrected Regex
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    return phoneRegex.hasMatch(input);
  }

  String? _validateInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email or phone number';
    }
    if (!_isEmail(value) && !_isPhone(value)) {
      return 'Enter a valid email or phone number';
    }
    return null;
  }

  bool _isPasswordValid(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}',
    );
    return regex.hasMatch(password);
  }

  // --- API LOGIC (UNCHANGED, EXCEPT FOR UI FEEDBACK) ---
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _sendOtpError = null;
    });

    final identifier = _identifierController.text.trim();
    final type = _isEmail(identifier) ? 'EMAIL' : 'PHONE';
    _identifierType = type;

    try {
      final response = await http.post(
        Uri.parse(
          'https://app.anaadfoods.com/api/auth/forgot-password/send-otp/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'type': type}),
      );
      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showOtpDialog();
      } else {
        setState(() {
          _sendOtpError = responseBody['message'] ?? 'Failed to send OTP';
        });
      }
    } catch (e) {
      setState(() {
        _sendOtpError = 'A network error occurred. Please try again.';
      });
    } finally {
       if (mounted) {
        setState(() => _isLoading = false);
       }
    }
  }

  Future<void> _resetPassword() async {
    setState(() {
      _isResetLoading = true;
      _passwordError = null;
      _resetSuccess = null;
    });

    final identifier = _identifierController.text.trim();
    final type = _identifierType ?? (_isEmail(identifier) ? 'EMAIL' : 'PHONE');
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      setState(() {
        _isResetLoading = false;
        _passwordError = 'Passwords do not match';
      });
      return;
    }
    if (!_isPasswordValid(newPassword)) {
      setState(() {
        _isResetLoading = false;
        _passwordError =
            'Password does not meet the security requirements.';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://app.anaadfoods.com/api/auth/forgot-password/reset/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'type': type,
          'new_password': newPassword,
        }),
      );

      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _resetSuccess = responseBody['message'] ?? 'Password changed successfully!';
          // Optionally navigate away after a delay
          Future.delayed(const Duration(seconds: 2), () {
            if(mounted) Navigator.of(context).pop();
          });
        });
      } else {
        setState(() {
          _passwordError = responseBody['error'] ?? 'Failed to reset password';
        });
      }
    } catch (e) {
      setState(() {
        _passwordError = 'A network error occurred. Please try again.';
      });
    } finally {
       if (mounted) {
        setState(() => _isResetLoading = false);
       }
    }
  }
  
  // --- NEW OTP DIALOG ---
  Future<void> _showOtpDialog() async {
    _otpController.clear();
    String? dialogError;
    bool isVerifying = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            Future<void> verifyOtpAction() async {
              if (_otpController.text.length != 6) {
                setDialogState(() => dialogError = 'Enter a valid 6-digit OTP');
                return;
              }
              setDialogState(() { isVerifying = true; dialogError = null; });

              try {
                final response = await http.post(
                  Uri.parse('https://app.anaadfoods.com/api/auth/forgot-password/verify-otp/'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'identifier': _identifierController.text.trim(),
                    'otp': _otpController.text.trim(),
                    'type': _identifierType,
                  }),
                );
                final responseBody = jsonDecode(response.body);
                if (response.statusCode == 200) {
                   Navigator.of(context).pop(); // Close dialog on success
                   setState(() => _showPasswordFields = true);
                } else {
                   setDialogState(() => dialogError = responseBody['error'] ?? 'Invalid OTP');
                }
              } catch(e) {
                 setDialogState(() => dialogError = 'Network error');
              } finally {
                 if (mounted) {
                  setDialogState(() => isVerifying = false);
                 }
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppColors.primaryColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Verify Your Account",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Enter the 6-digit code sent to\n${_identifierController.text}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Pinput(
                      length: 6,
                      controller: _otpController,
                      onCompleted: (_) => verifyOtpAction(),
                      onChanged: (_) => setDialogState(() => dialogError = null),
                      forceErrorState: dialogError != null,
                      errorTextStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      errorText: dialogError,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bottonBackgroundColor,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: isVerifying ? null : verifyOtpAction,
                        child: isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text("Verify", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                     const SizedBox(height: 16),
                      TextButton(
                        onPressed: isVerifying ? null : () {
                           Navigator.of(context).pop();
                           _sendOtp(); // This is your resend logic
                        },
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- THEMED BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    // Get screen height to ensure the layout can fill the screen
    final screenHeight = MediaQuery.of(context).size.height;
    final safePadding = MediaQuery.of(context).padding;
    final minLayoutHeight = screenHeight - safePadding.top - safePadding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/OnBoarding/background_login_sign.png", fit: BoxFit.cover),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(minHeight: minLayoutHeight),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
                  children: [
                    Image.asset("assets/images/OnBoarding/logo.png", height: 60),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const Text("Forgot Password", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 6),
                             Text(
                              _showPasswordFields 
                                ? "Create a new password"
                                : "Enter your email or phone to proceed", 
                              style: TextStyle(fontSize: 13, color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),

                            if (!_showPasswordFields) _buildIdentifierSection(),
                            if (_showPasswordFields) _buildResetPasswordSection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER BUILD WIDGETS FOR CLEANLINESS ---
  
  Widget _buildIdentifierSection() {
    return Column(
      children: [
        TextFormField(
          controller: _identifierController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Email or Phone'),
          validator: _validateInput,
          keyboardType: TextInputType.emailAddress,
        ),
        if (_sendOtpError != null) ...[
          const SizedBox(height: 12),
          Text(_sendOtpError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            style: _buttonStyle(),
            child: _isLoading ? _loader() : const Text('Send OTP'),
          ),
        ),
      ],
    );
  }

  Widget _buildResetPasswordSection() {
    return Column(
      children: [
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('New Password').copyWith(
            suffixIcon: _visibilityIcon(_obscureNewPassword, () {
              setState(() => _obscureNewPassword = !_obscureNewPassword);
            }),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Confirm Password').copyWith(
            suffixIcon: _visibilityIcon(_obscureConfirmPassword, () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            }),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.white54),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Use 8+ characters with a mix of letters, numbers & symbols.',
                style: TextStyle(fontSize: 12, color: Colors.white54, height: 1.4),
              ),
            ),
          ],
        ),
        if (_passwordError != null) ...[
          const SizedBox(height: 12),
          Text(_passwordError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        ],
        if (_resetSuccess != null) ...[
          const SizedBox(height: 12),
          Text(_resetSuccess!, style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isResetLoading ? null : _resetPassword,
            style: _buttonStyle(),
            child: _isResetLoading ? _loader() : const Text('Change Password'),
          ),
        ),
      ],
    );
  }
  
  // --- STYLING HELPERS ---

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF244A2F), // Darker green fill
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Colors.white54, width: 1),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.bottonBackgroundColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    );
  }

  Widget _loader() {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
  
  Widget _visibilityIcon(bool obscure, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.white54,
      ),
      onPressed: onPressed,
    );
  }
}
