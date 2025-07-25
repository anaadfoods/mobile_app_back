import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/common_widgets/imput_widget.dart';
import 'package:grocery_app/models/user_model.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:flutter/services.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isFormValid = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;

  // Add verification state
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;

  String? _selectedGender; // 'M', 'F', or 'O'

  final Map<String, bool> _fieldValidity = {
    'firstName': false,
    'lastName': false,
    'username': false,
    'phone': false,
    'email': false,
    'password': false,
    'confirmPassword': false,
  };

  void _updateFieldValidity(String field, bool isValid) {
    setState(() {
      _fieldValidity[field] = isValid;
      _isFormValid = _fieldValidity.values.every((isValid) => isValid);
    });
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9].*[0-9]'))) {
      return 'Password must contain at least two numbers';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  void _showErrorSnackBar(String message) {
    SnackBarHelper.showError(context, message);
  }

  void _showSuccessSnackBar(String message) {
    SnackBarHelper.showSuccess(context, message);
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Create user model
        final user = UserModel(
          email: _emailController.text,
          username: _usernameController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phoneNumber: _phoneController.text,
          referralCode:
              _referralCodeController.text.isNotEmpty
                  ? _referralCodeController.text
                  : null,
          gender: _selectedGender,
        );

        // Call API to register user
        final result = await _authService.registerUser(user);

        if (!mounted) return;

        if (result['success']) {
          _showSuccessSnackBar(result['message']);
          // Navigate to login screen after successful registration
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
          _showErrorSnackBar(result['message']);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'An error occurred during registration';
        });
        _showErrorSnackBar('An error occurred during registration');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _showOtpDialog({
    required String type,
    required String value,
  }) async {
    final TextEditingController _otpController = TextEditingController();
    bool _isVerifying = false;
    bool _isResending = false;
    String? _dialogError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Verify ${type == 'email' ? 'Email' : 'Phone'}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Enter the 6-digit OTP sent to your $type.'),
                  SizedBox(height: 12),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'OTP',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_dialogError != null) ...[
                    SizedBox(height: 8),
                    Text(_dialogError!, style: TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      _isResending
                          ? null
                          : () async {
                            setState(() => _isResending = true);
                            final result = await _authService.sendOtp(
                              identifier: value,
                              type:
                                  type.toUpperCase() == 'EMAIL'
                                      ? 'EMAIL'
                                      : 'MOBILE',
                            );
                            setState(() => _isResending = false);
                            if (result['success']) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['message'] ?? 'OTP resent to $value',
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['message'] ?? 'Failed to resend OTP',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                  child:
                      _isResending
                          ? CircularProgressIndicator()
                          : Text('Resend'),
                ),
                TextButton(
                  onPressed:
                      _isVerifying
                          ? null
                          : () async {
                            if (_otpController.text.length != 6) {
                              setState(
                                () =>
                                    _dialogError = 'Enter a valid 6-digit OTP',
                              );
                              return;
                            }
                            setState(() {
                              _isVerifying = true;
                              _dialogError = null;
                            });
                            final result = await _authService.verifyOtp(
                              identifier: value,
                              otp: _otpController.text,
                              type:
                                  type.toUpperCase() == 'EMAIL'
                                      ? 'EMAIL'
                                      : 'MOBILE',
                            );
                            setState(() => _isVerifying = false);
                            if (result['success']) {
                              Navigator.of(context).pop();
                              setState(() {
                                if (type == 'email') {
                                  _isEmailVerified = true;
                                } else {
                                  _isPhoneVerified = true;
                                }
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['message'] ??
                                        '$type verified successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              setState(
                                () =>
                                    _dialogError =
                                        result['message'] ?? 'Invalid OTP',
                              );
                            }
                          },
                  child:
                      _isVerifying
                          ? CircularProgressIndicator()
                          : Text('Verify'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Signup"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Let's get started",
                  style: TextStyle(fontWeight: FontWeight.normal, fontSize: 20),
                ),
                SizedBox(height: 5),
                Text(
                  "Signup",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ),
                if (_errorMessage != null) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 20),
                // First Name and Last Name in one row
                Row(
                  children: [
                    Expanded(
                      child: CustomInput(
                        hintText: "First Name",
                        obscureText: false,
                        controller: _firstNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                        onValidationChanged:
                            (isValid) =>
                                _updateFieldValidity('firstName', isValid),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CustomInput(
                        hintText: "Last Name",
                        obscureText: false,
                        controller: _lastNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                        onValidationChanged:
                            (isValid) =>
                                _updateFieldValidity('lastName', isValid),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                // Username field
                CustomInput(
                  hintText: "Username",
                  obscureText: false,
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                  onValidationChanged:
                      (isValid) => _updateFieldValidity('username', isValid),
                ),
                SizedBox(height: 15),
                // Phone Number field
                CustomInput(
                  hintText: "Phone Number",
                  obscureText: false,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                  onValidationChanged:
                      (isValid) => _updateFieldValidity('phone', isValid),
                  suffixIcon: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      backgroundColor:
                          _isPhoneVerified
                              ? Colors.green[700]
                              : Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      minimumSize: Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed:
                        _isPhoneVerified
                            ? null
                            : () async {
                              if (_phoneController.text.isNotEmpty) {
                                setState(() => _isLoading = true);
                                final result = await _authService.sendOtp(
                                  identifier: _phoneController.text,
                                  type: 'MOBILE',
                                );
                                setState(() => _isLoading = false);
                                if (result['success']) {
                                  _showSuccessSnackBar(
                                    result['message'] ?? 'OTP sent!',
                                  );
                                  _showOtpDialog(
                                    type: 'phone',
                                    value: _phoneController.text,
                                  );
                                } else {
                                  _showErrorSnackBar(
                                    result['message'] ?? 'Failed to send OTP',
                                  );
                                }
                              } else {
                                _showErrorSnackBar('Enter phone number first');
                              }
                            },
                    child: Text(
                      _isPhoneVerified ? 'Verified' : 'Verify',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                CustomInput(
                  hintText: "Referral Code (optional)",
                  obscureText: false,
                  controller: _referralCodeController,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    return null;
                  },
                ),
                SizedBox(height: 15),
                // Email field
                CustomInput(
                  hintText: "Email",
                  obscureText: false,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  onValidationChanged:
                      (isValid) => _updateFieldValidity('email', isValid),
                  suffixIcon: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      backgroundColor:
                          _isEmailVerified
                              ? Colors.green[700]
                              : Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      minimumSize: Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed:
                        _isEmailVerified
                            ? null
                            : () async {
                              if (_emailController.text.isNotEmpty) {
                                setState(() => _isLoading = true);
                                final result = await _authService.sendOtp(
                                  identifier: _emailController.text,
                                  type: 'EMAIL',
                                );
                                setState(() => _isLoading = false);
                                if (result['success']) {
                                  _showSuccessSnackBar(
                                    result['message'] ?? 'OTP sent!',
                                  );
                                  _showOtpDialog(
                                    type: 'email',
                                    value: _emailController.text,
                                  );
                                } else {
                                  _showErrorSnackBar(
                                    result['message'] ?? 'Failed to send OTP',
                                  );
                                }
                              } else {
                                _showErrorSnackBar('Enter email first');
                              }
                            },
                    child: Text(
                      _isEmailVerified ? 'Verified' : 'Verify',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                // Gender radio field
                Text("Gender", style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Radio<String>(
                      value: "M",
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                    Text("Male"),
                    Radio<String>(
                      value: "F",
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                    Text("Female"),
                    Radio<String>(
                      value: "O",
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                    Text("Other"),
                  ],
                ),
                SizedBox(height: 15),
                // Password and Confirm Password in one row
                Row(
                  children: [
                    Expanded(
                      child: CustomInput(
                        hintText: "Password",
                        obscureText: !_showPassword,
                        controller: _passwordController,
                        validator: _validatePassword,
                        onValidationChanged:
                            (isValid) =>
                                _updateFieldValidity('password', isValid),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CustomInput(
                        hintText: "Confirm Password",
                        obscureText: !_showConfirmPassword,
                        controller: _confirmPasswordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        onValidationChanged:
                            (isValid) => _updateFieldValidity(
                              'confirmPassword',
                              isValid,
                            ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                AppButton(
                  label: _isLoading ? "Signing up..." : "Sign Up",
                  fontWeight: FontWeight.bold,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  onPressed:
                      _isLoading || !_isFormValid
                          ? null
                          : () {
                            if (!_isEmailVerified) {
                              _showErrorSnackBar(
                                'Please verify your email before signing up.',
                              );
                              return;
                            }
                            _handleSignup();
                          },
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                      child: Text('Login'),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(1.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.g_mobiledata, size: 25),
                        onPressed: () {
                          // Handle Google login
                        },
                      ),
                    ),
                    SizedBox(width: 20),
                    Container(
                      padding: EdgeInsets.all(1.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.apple, size: 25),
                        onPressed: () {
                          // Handle Apple login
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
