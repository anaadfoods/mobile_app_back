import 'package:grocery_app/common_widgets/global_import.dart';
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
  String? _sendOtpError;
  String? _identifierType;

  final TextEditingController _otpController = TextEditingController();

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
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).pop();
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

  Future<void> _showOtpDialog() async {
    _otpController.clear();
    String? dialogError;
    bool isVerifying = false;
    final theme = Theme.of(context);

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
              setDialogState(() {
                isVerifying = true;
                dialogError = null;
              });

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
              } catch (e) {
                setDialogState(() => dialogError = 'Network error');
              } finally {
                if (mounted) {
                  setDialogState(() => isVerifying = false);
                }
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Verify Your Account",
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Enter the 6-digit code sent to\n${_identifierController.text}",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Pinput(
                      length: 6,
                      controller: _otpController,
                      onCompleted: (_) => verifyOtpAction(),
                      onChanged: (_) => setDialogState(() => dialogError = null),
                      forceErrorState: dialogError != null,
                      errorTextStyle: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                      errorText: dialogError,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isVerifying ? null : verifyOtpAction,
                        child: isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Verify"),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isVerifying
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              _sendOtp(); // This is your resend logic
                            },
                      child: const Text('Resend OTP'),
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safePadding = MediaQuery.of(context).padding;
    final minLayoutHeight = screenHeight - safePadding.top - safePadding.bottom;
    final theme = Theme.of(context);

    return Scaffold(
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/images/OnBoarding/logo.png", height: 60),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Text("Forgot Password", style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onPrimary)),
                            const SizedBox(height: 6),
                            Text(
                              _showPasswordFields
                                  ? "Create a new password"
                                  : "Enter your email or phone to proceed",
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.8)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            if (!_showPasswordFields) _buildIdentifierSection(theme),
                            if (_showPasswordFields) _buildResetPasswordSection(theme),
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

  Widget _buildIdentifierSection(ThemeData theme) {
    return Column(
      children: [
        TextFormField(
          controller: _identifierController,
          decoration: const InputDecoration(labelText: 'Email or Phone'),
          validator: _validateInput,
          keyboardType: TextInputType.emailAddress,
        ),
        if (_sendOtpError != null) ...[
          const SizedBox(height: 12),
          Text(_sendOtpError!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            child: _isLoading ? _loader() : const Text('Send OTP'),
          ),
        ),
      ],
    );
  }

  Widget _buildResetPasswordSection(ThemeData theme) {
    return Column(
      children: [
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          decoration: InputDecoration(
            labelText: 'New Password',
            suffixIcon: _visibilityIcon(_obscureNewPassword, () {
              setState(() => _obscureNewPassword = !_obscureNewPassword);
            }),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            suffixIcon: _visibilityIcon(_obscureConfirmPassword, () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            }),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onPrimary.withOpacity(0.7)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Use 8+ characters with a mix of letters, numbers & symbols.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.7)),
              ),
            ),
          ],
        ),
        if (_passwordError != null) ...[
          const SizedBox(height: 12),
          Text(_passwordError!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
        ],
        if (_resetSuccess != null) ...[
          const SizedBox(height: 12),
          Text(_resetSuccess!, style: TextStyle(color: AppColors.success, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isResetLoading ? null : _resetPassword,
            child: _isResetLoading ? _loader() : const Text('Change Password'),
          ),
        ),
      ],
    );
  }

  Widget _loader() {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  Widget _visibilityIcon(bool obscure, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
      onPressed: onPressed,
    );
  }
}
