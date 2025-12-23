import 'package:grocery_app/common_widgets/global_import.dart';

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

  bool _isFormValid = false;
  final bool _showPassword = false;
  final bool _showConfirmPassword = false;
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  String? _selectedGender;

  final Map<String, bool> _fieldValidity = {
    'firstName': false,
    'lastName': false,
    'username': false,
    'phone': false,
    'email': false,
    'password': false,
    'confirmPassword': false,
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

  void _updateFieldValidity(String field, bool isValid) {
    setState(() {
      _fieldValidity[field] = isValid;
      _isFormValid = _fieldValidity.values.every((isValid) => isValid);
    });
  }

  void _handleSignup() {
    if (!_isEmailVerified) {
      SnackBarHelper.showError(
        context,
        "Please verify your email before signing up.",
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
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
                : "",
        gender: _selectedGender,
      );
      context.read<AuthCubit>().register(user);
    }
  }

  Future<void> _showOtpDialog({
    required String type,
    required String value,
    required VoidCallback onVerified,
  }) async {
    final otpController = TextEditingController();
    bool isVerifying = false;
    String? dialogError;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: colorScheme.primary,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "OTP Verification",
                      style: textTheme.displaySmall?.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "We've sent a 6-digit OTP to your $type",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Pinput(
                      length: 6,
                      controller: otpController,
                      forceErrorState: dialogError != null,
                      onChanged:
                          (_) => setDialogState(() => dialogError = null),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        dialogError!,
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: colorScheme.onSecondary,
                        ),
                        onPressed:
                            isVerifying
                                ? null
                                : () async {
                                  if (otpController.text.length != 6) {
                                    setDialogState(
                                      () =>
                                          dialogError =
                                              'Enter a valid 6-digit OTP',
                                    );
                                    return;
                                  }
                                  setDialogState(() {
                                    isVerifying = true;
                                    dialogError = null;
                                  });
                                  try {
                                    await context
                                        .read<AuthRepository>()
                                        .verifyOtp(
                                          value,
                                          otpController.text,
                                          type.toUpperCase(),
                                        );
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                    onVerified();
                                    SnackBarHelper.showSuccess(
                                      context,
                                      '$type verified successfully!',
                                    );
                                  } on AuthException catch (e) {
                                    setDialogState(
                                      () => dialogError = e.message,
                                    );
                                  } finally {
                                    if (mounted) {
                                      setDialogState(() => isVerifying = false);
                                    }
                                  }
                                },
                        child:
                            isVerifying
                                ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  "Verify",
                                  style: textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onSecondary,
                                  ),
                                ),
                      ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (route) => false,
            );
          } else if (state is AuthRegistrationSuccess) {
            SnackBarHelper.showSuccess(
              context,
              "Registration successful! Please log in.",
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          } else if (state is AuthError) {
            SnackBarHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  "assets/images/OnBoarding/background_login_sign.png",
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppColors.spacingXL,
                    vertical: AppColors.spacingM,
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/images/OnBoarding/logo.png",
                        height: 70,
                      ),
                      const SizedBox(height: AppColors.spacingXL),
                      Container(
                        padding: const EdgeInsets.all(AppColors.spacingXL),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withOpacity(0.9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppColors.radiusXL,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Text(
                                "Welcome",
                                style: textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppColors.spacingXS),
                              Text(
                                "Create an account",
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimary.withOpacity(
                                    0.85,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppColors.spacingXL),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomInput(
                                      hintText: "First Name",
                                      controller: _firstNameController,
                                      onPrimary: true,
                                      validator:
                                          (v) =>
                                              v!.isEmpty
                                                  ? 'Enter first name'
                                                  : null,
                                      onValidationChanged:
                                          (isValid) => _updateFieldValidity(
                                            'firstName',
                                            isValid,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomInput(
                                      hintText: "Last Name",
                                      controller: _lastNameController,
                                      onPrimary: true,
                                      validator:
                                          (v) =>
                                              v!.isEmpty
                                                  ? 'Enter last name'
                                                  : null,
                                      onValidationChanged:
                                          (isValid) => _updateFieldValidity(
                                            'lastName',
                                            isValid,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppColors.spacingL),
                              CustomInput(
                                hintText: "Username",
                                controller: _usernameController,
                                onPrimary: true,
                                validator:
                                    (v) => v!.isEmpty ? 'Enter username' : null,
                                onValidationChanged:
                                    (isValid) => _updateFieldValidity(
                                      'username',
                                      isValid,
                                    ),
                              ),
                              const SizedBox(height: 15),
                              CustomInput(
                                hintText: "Email",
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                onPrimary: true,
                                validator: (v) {
                                  if (v!.isEmpty) return 'Enter email';
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(v))
                                    return 'Invalid email';
                                  return null;
                                },
                                onValidationChanged:
                                    (isValid) =>
                                        _updateFieldValidity('email', isValid),
                                suffixIcon: _buildVerifyButton(
                                  label:
                                      _isEmailVerified ? "Verified" : "Verify",
                                  isVerified: _isEmailVerified,
                                  onPressed: () async {
                                    try {
                                      await context
                                          .read<AuthRepository>()
                                          .sendOtp(
                                            _emailController.text,
                                            'EMAIL',
                                          );
                                      if (!mounted) return;
                                      SnackBarHelper.showSuccess(
                                        context,
                                        'OTP sent to your email.',
                                      );
                                      await _showOtpDialog(
                                        type: 'email',
                                        value: _emailController.text,
                                        onVerified:
                                            () => setState(
                                              () => _isEmailVerified = true,
                                            ),
                                      );
                                    } on AuthException catch (e) {
                                      if (!mounted) return;
                                      SnackBarHelper.showError(
                                        context,
                                        e.message,
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: AppColors.spacingL),
                              CustomInput(
                                hintText: "Phone number",
                                controller: _phoneController,
                                keyboardType: TextInputType.number,
                                onPrimary: true,
                                validator: (v) {
                                  if (v!.isEmpty) return 'Enter phone number';
                                  if (!RegExp(r'^[0-9]{10}$').hasMatch(v))
                                    return 'Invalid phone number';
                                  return null;
                                },
                                onValidationChanged:
                                    (isValid) =>
                                        _updateFieldValidity('phone', isValid),
                                suffixIcon: _buildVerifyButton(
                                  label:
                                      _isPhoneVerified ? "Verified" : "Verify",
                                  isVerified: _isPhoneVerified,
                                  onPressed: () async {
                                    try {
                                      await context
                                          .read<AuthRepository>()
                                          .sendOtp(
                                            _phoneController.text,
                                            'MOBILE',
                                          );
                                      if (!mounted) return;
                                      SnackBarHelper.showSuccess(
                                        context,
                                        'OTP sent to your phone.',
                                      );
                                      await _showOtpDialog(
                                        type: 'phone',
                                        value: _phoneController.text,
                                        onVerified:
                                            () => setState(
                                              () => _isPhoneVerified = true,
                                            ),
                                      );
                                    } on AuthException catch (e) {
                                      if (!mounted) return;
                                      SnackBarHelper.showError(
                                        context,
                                        e.message,
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 15),
                              CustomInput(
                                hintText: "Password",
                                controller: _passwordController,
                                obscureText: true,
                                onPrimary: true,
                                validator: (v) {
                                  if (v!.isEmpty) return 'Enter password';
                                  if (v.length < 6) return 'Min 6 characters';
                                  return null;
                                },
                                onValidationChanged:
                                    (isValid) => _updateFieldValidity(
                                      'password',
                                      isValid,
                                    ),
                              ),
                              const SizedBox(height: 15),
                              CustomInput(
                                hintText: "Confirm Password",
                                controller: _confirmPasswordController,
                                obscureText: true,
                                onPrimary: true,
                                validator: (v) {
                                  if (v!.isEmpty) return 'Confirm password';
                                  if (v != _passwordController.text)
                                    return 'Passwords do not match';
                                  return null;
                                },
                                onValidationChanged:
                                    (isValid) => _updateFieldValidity(
                                      'confirmPassword',
                                      isValid,
                                    ),
                              ),
                              const SizedBox(height: 15),
                              CustomInput(
                                hintText: "Referral Code (Optional)",
                                controller: _referralCodeController,
                                onPrimary: true,
                              ),
                              const SizedBox(height: 10),
                              AppButton(
                                label: isLoading ? "Signing up..." : "Sign Up",
                                fontWeight: FontWeight.bold,
                                onPressed:
                                    isLoading || !_isFormValid
                                        ? null
                                        : _handleSignup,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account?",
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onPrimary.withOpacity(
                                        0.8,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        isLoading
                                            ? null
                                            : () => Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => const LoginScreen(),
                                              ),
                                            ),
                                    child: Text(
                                      "Login",
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppColors.spacingXL),
                      Row(
                        children: [
                          Expanded(child: Divider(color: theme.dividerColor)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppColors.spacingM,
                            ),
                            child: Text(
                              "or continue with",
                              style: textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: theme.dividerColor)),
                        ],
                      ),
                      const SizedBox(height: AppColors.spacingXL),
                      Center(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onPrimary,
                            side: BorderSide(
                              color: colorScheme.onPrimary.withOpacity(0.7),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppColors.spacingXXL,
                              vertical: AppColors.spacingM,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppColors.radiusRound,
                              ),
                            ),
                          ),
                          onPressed:
                              isLoading
                                  ? null
                                  : () =>
                                      context.read<AuthCubit>().googleLogin(),
                          icon: const Icon(FontAwesomeIcons.google, size: 18),
                          label: const Text("Sign up with Google"),
                        ),
                      ),
                      const SizedBox(height: AppColors.spacingXL),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVerifyButton({
    required String label,
    required bool isVerified,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: isVerified ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor:
            isVerified ? AppColors.success : theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.onSecondary,
      ),
      child: Text(label),
    );
  }
}
