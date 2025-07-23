import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // OTP bottom sheet state
  final TextEditingController _otpController = TextEditingController();
  bool _isOtpLoading = false;
  String? _otpError;
  String? _sendOtpError;
  String? _identifierType;

  // Password reset state
  bool _showPasswordFields = false;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordError;
  bool _isResetLoading = false;
  String? _resetSuccess;

  bool _isEmail(String input) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(input);
  }

  bool _isPhone(String input) {
    final phoneRegex = RegExp(r'^[0-9]{10,15}\$');
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

  // Password standards: at least 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char
  bool _isPasswordValid(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}',
    );
    return regex.hasMatch(password);
  }

  Future<void> _sendOtp() async {
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
      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
        });
        _showOtpBottomSheet();
      } else {
        setState(() {
          _isLoading = false;
          _sendOtpError = 'Failed to send OTP';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _sendOtpError = 'Network error';
      });
    }
  }

  Future<void> _resendOtp() async {
    await _sendOtp();
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
            'Password must be at least 8 characters, include upper, lower, number, and special character.';
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
      if (response.statusCode == 200) {
        setState(() {
          _isResetLoading = false;
          _resetSuccess = 'Password changed successfully!';
        });
      } else {
        setState(() {
          _isResetLoading = false;
          _passwordError = 'Failed to reset password';
        });
      }
    } catch (e) {
      setState(() {
        _isResetLoading = false;
        _passwordError = 'Network error';
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isOtpLoading = true;
      _otpError = null;
    });
    final identifier = _identifierController.text.trim();
    final otp = _otpController.text.trim();
    final type = _identifierType ?? (_isEmail(identifier) ? 'EMAIL' : 'PHONE');
    try {
      final response = await http.post(
        Uri.parse(
          'https://app.anaadfoods.com/api/auth/forgot-password/verify-otp/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'otp': otp, 'type': type}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _isOtpLoading = false;
          _showPasswordFields = true;
        });
        Navigator.of(context).pop(); // Close bottom sheet
      } else {
        setState(() {
          _isOtpLoading = false;
          _otpError = 'Invalid OTP';
        });
      }
    } catch (e) {
      setState(() {
        _isOtpLoading = false;
        _otpError = 'Network error';
      });
    }
  }

  void _showOtpBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 32,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter OTP',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: '6-digit OTP',
                  errorText: _otpError,
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isOtpLoading ? null : _verifyOtp,
                      child:
                          _isOtpLoading
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Verify'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isOtpLoading ? null : _resendOtp,
                      child: const Text('Send Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _identifierController,
                  decoration: const InputDecoration(
                    labelText: 'Email or Phone',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateInput,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_showPasswordFields,
                ),
                if (_sendOtpError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _sendOtpError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                if (!_showPasswordFields) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                if (_formKey.currentState!.validate()) {
                                  _sendOtp();
                                }
                              },
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Send OTP'),
                    ),
                  ),
                ],
                if (_showPasswordFields) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Password must be at least 8 characters, include upper, lower, number, and special character.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_passwordError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _passwordError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  if (_resetSuccess != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _resetSuccess!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isResetLoading ? null : _resetPassword,
                      child:
                          _isResetLoading
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Change Password'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
