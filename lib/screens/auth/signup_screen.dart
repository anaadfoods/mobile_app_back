import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/common_widgets/imput_widget.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:grocery_app/models/user_model.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/styles/colors.dart';

import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:pinput/pinput.dart' hide PinTheme;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // --- STATE AND CONTROLLERS (UNCHANGED) ---
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

  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  String? _selectedGender;

  final Map<String, bool> _fieldValidity = {
    'firstName': false, 'lastName': false, 'username': false,
    'phone': false, 'email': false, 'password': false, 'confirmPassword': false,
  };

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
  
  // --- LOGIC METHODS (UNCHANGED) ---
  void _updateFieldValidity(String field, bool isValid) {
    setState(() {
      _fieldValidity[field] = isValid;
      _isFormValid = _fieldValidity.values.every((isValid) => isValid);
    });
  }

  void _showErrorSnackBar(String message) {
    SnackBarHelper.showError(context, message);
  }

  void _showSuccessSnackBar(String message) {
    SnackBarHelper.showSuccess(context, message);
  }


  // Replace your existing _parseErrorMessage function with this one.

String _parseErrorMessage(dynamic errorData) {
  // Default message if parsing fails
  const String genericError = "An unknown registration error occurred.";

  if (errorData is String) {
    // If the error is already a simple string, return it.
    return errorData;
  }

  if (errorData is Map) {
    // A list of potential keys the backend might use for validation errors.
    // This makes the parser flexible and easy to extend.
    final List<String> errorKeys = [
      'email',
      'username',
      'phone',
      'phone_number', // Common alternative for phone
      'referral_code',
      'referralCode' // Common alternative for referral code
    ];

    // Loop through our list of known keys to find a match.
    for (final key in errorKeys) {
      if (errorData.containsKey(key) &&
          errorData[key] is List &&
          errorData[key].isNotEmpty) {
        // Found a matching error key, so we return its message.
        // For example, if the key is 'username', this returns the username error.
        return errorData[key][0];
      }
    }

    // Fallback: If no specific keys match, try to get the first error
    // message from the map, regardless of its key.
    if (errorData.isNotEmpty &&
        errorData.values.first is List &&
        (errorData.values.first as List).isNotEmpty) {
      return errorData.values.first[0];
    }
  }

  // If all parsing attempts fail, return the generic error message.
  return genericError;
}


  Future<void> _handleSignup() async {
    if (!_isEmailVerified) {
       _showErrorSnackBar("Please verify your email before signing up.");
       return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = UserModel(
          email: _emailController.text,
          username: _usernameController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phoneNumber: _phoneController.text,
          referralCode: _referralCodeController.text.isNotEmpty
              ? _referralCodeController.text : "",
          gender: _selectedGender,
        );
        final result = await _authService.registerUser(user);
        if (!mounted) return;
        if (result['success']) {
          _showSuccessSnackBar(result['message']);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
                final String friendlyErrorMessage = _parseErrorMessage(result['message']);
        _showErrorSnackBar(friendlyErrorMessage);
        }
      } catch (e) {
        if (!mounted) return;
        _showErrorSnackBar("An error occurred: ${e.toString()}");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showOtpDialog({
    required String type,
    required String value,
    required VoidCallback onVerified,
  }) async {
    final TextEditingController otpController = TextEditingController();
    bool isVerifying = false;
    String? dialogError;

    // 1. PINPUT THEME CONFIGURATION
    // Define the visual style for the OTP input fields.
    final defaultPinTheme = PinTheme(
      fieldWidth: 50,
      fieldHeight: 55,
    
    );

    // final errorPinTheme = defaultPinTheme.copyWith(
    //   decoration: defaultPinTheme.decoration!.copyWith(
    //     border: Border.all(color: Colors.redAccent),
    //   ),
    // );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppColors.primaryColor, // Dark green background
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "OTP Verification",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "We've sent a 6-digit OTP to your registered\nmobile number or email",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // 2. PINPUT WIDGET INTEGRATION
                    // This is the configured Pinput widget.
                    Pinput(
                      length: 6,
                      controller: otpController, // Connects to your logic
                      // defaultPinTheme: defaultPinTheme,
                      // focusedPinTheme: defaultPinTheme.copyWith(
                      //   decoration: defaultPinTheme.decoration!.copyWith(
                      //     border: Border.all(color: Colors.white.withOpacity(0.5)),
                      //   ),
                      // ),
                      // errorPinTheme: errorPinTheme, // Style for when there's an error
                      forceErrorState: dialogError != null, // Shows error style based on your logic
                      onChanged: (_) => setState(() => dialogError = null), // Clears error on change
                      onCompleted: (pin) {
                        // Optional: You could trigger verification here automatically
                        // For now, it respects your button-press logic
                        debugPrint('OTP Entered: $pin');
                      },
                    ),
                    
                    if (dialogError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        dialogError!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bottonBackgroundColor, // Tan color
                          foregroundColor: Colors.white, // White text is more readable
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: isVerifying ? null : () async {
                          if (otpController.text.length != 6) {
                            setState(() => dialogError = 'Enter a valid 6-digit OTP');
                            return;
                          }
                          setState(() { isVerifying = true; dialogError = null; });
                          final result = await _authService.verifyOtp(
                            identifier: value,
                            otp: otpController.text,
                            type: type.toUpperCase() == 'EMAIL' ? 'EMAIL' : 'MOBILE',
                          );
                          setState(() => isVerifying = false);
                          if (result['success']) {
                            Navigator.of(context).pop();
                            onVerified();
                            _showSuccessSnackBar('$type verified successfully!');
                          } else {
                            setState(() => dialogError = result['message'] ?? 'Invalid OTP');
                          }
                        },
                        child: isVerifying
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text("Verify", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? ", style: TextStyle(fontSize: 13, color: Colors.white70)),
                        GestureDetector(
                          onTap: () {
                              Navigator.of(context).pop(); // Close dialog first
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/OnBoarding/background_login_sign.png", fit: BoxFit.cover),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Image.asset("assets/images/OnBoarding/logo.png", height: 60),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text("Welcome", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 6),
                          const Text("Create an account", style: TextStyle(fontSize: 13, color: Colors.white70)),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: CustomInput(
                                  hintText: "First Name",
                                  controller: _firstNameController,
                                  validator: (v) => v!.isEmpty ? 'Enter first name' : null,
                                  onValidationChanged: (isValid) => _updateFieldValidity('firstName', isValid),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomInput(
                                  hintText: "Last Name",
                                  controller: _lastNameController,
                                  validator: (v) => v!.isEmpty ? 'Enter last name' : null,
                                  onValidationChanged: (isValid) => _updateFieldValidity('lastName', isValid),
                                ),
                              ),
                            ],
                          ),
                          CustomInput(
                            hintText: "Username",
                            controller: _usernameController,
                            validator: (v) => v!.isEmpty ? 'Enter username' : null,
                            onValidationChanged: (isValid) => _updateFieldValidity('username', isValid),
                          ),
                          CustomInput(
                            hintText: "Email",
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v!.isEmpty) return 'Enter email';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Invalid email';
                              return null;
                            },
                            onValidationChanged: (isValid) => _updateFieldValidity('email', isValid),
                            suffixIcon: _buildVerifyButton(
                              label: _isEmailVerified ? "Verified" : "Verify",
                              isVerified: _isEmailVerified,
                              onPressed: () async {
                                final result = await _authService.sendOtp(identifier: _emailController.text, type: 'EMAIL');
                                if (!mounted) return;
                                _showSuccessSnackBar(result['message'] ?? 'Processing...');
                                if (result['success']) {
                                  await _showOtpDialog(
                                    type: 'email',
                                    value: _emailController.text,
                                    onVerified: () => setState(() => _isEmailVerified = true),
                                  );
                                }
                              },
                            ),
                          ),
                          CustomInput(
                            hintText: "Phone number",
                            controller: _phoneController,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v!.isEmpty) return 'Enter phone number';
                              if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) return 'Invalid phone number';
                              return null;
                            },
                            onValidationChanged: (isValid) => _updateFieldValidity('phone', isValid),
                            suffixIcon: _buildVerifyButton(
                              label: _isPhoneVerified ? "Verified" : "Verify",
                              isVerified: _isPhoneVerified,
                              onPressed: () async {
                                final result = await _authService.sendOtp(identifier: _phoneController.text, type: 'MOBILE');
                                if (!mounted) return;
                                 _showSuccessSnackBar(result['message'] ?? 'Processing...');
                                if (result['success']) {
                                  await _showOtpDialog(
                                    type: 'phone',
                                    value: _phoneController.text,
                                    onVerified: () => setState(() => _isPhoneVerified = true),
                                  );
                                }
                              },
                            ),
                          ),
                          CustomInput(
                            hintText: "Password",
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            validator: (v) {
                              if (v!.isEmpty) return 'Enter password';
                              if (v.length < 6) return 'Min 6 characters';
                              return null;
                            },
                            onValidationChanged: (isValid) => _updateFieldValidity('password', isValid),
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                          CustomInput(
                            hintText: "Confirm Password",
                            controller: _confirmPasswordController,
                            obscureText: !_showConfirmPassword,
                            validator: (v) {
                              if (v!.isEmpty) return 'Confirm password';
                              if (v != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                            onValidationChanged: (isValid) => _updateFieldValidity('confirmPassword', isValid),
                            suffixIcon: IconButton(
                              icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                            ),
                          ),
                          CustomInput(
                            hintText: "Referral Code (Optional)",
                            controller: _referralCodeController,
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            label: _isLoading ? "Signing up..." : "Sign Up",
                            fontWeight: FontWeight.bold,
                            color: AppColors.bottonBackgroundColor,
                            textColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            onPressed: _isLoading || !_isFormValid ? null : _handleSignup,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account?", style: TextStyle(fontSize: 12, color: Colors.white70)),
                              TextButton(
                                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                                child: const Text("Login", style: TextStyle(fontSize: 12, color: Colors.orange)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Colors.white54)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("or", style: TextStyle(color: Colors.white70)),
                      ),
                      Expanded(child: Divider(color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialLoginButton(icon: Icons.g_mobiledata, onPressed: () {}),
                      const SizedBox(width: 20),
                      _buildSocialLoginButton(icon: Icons.apple, onPressed: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton({
    required String label,
    required bool isVerified,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: isVerified ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isVerified ? Colors.green : AppColors.bottonBackgroundColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(60, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSocialLoginButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(1.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(50.0),
      ),
      child: IconButton(
        icon: Icon(icon, size: 28, color: Colors.white),
        onPressed: _isLoading ? null : onPressed,
      ),
    );
  }
}