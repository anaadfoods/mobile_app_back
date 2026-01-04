import 'dart:ui';
import 'dart:math' as math;
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:http/http.dart' as http;

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen>
    with TickerProviderStateMixin {
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

  // Animation Controllers
  late AnimationController _cardController;
  late AnimationController _inputController;
  late AnimationController _floatController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoBreathing;
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Card entrance animation
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardSlide = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // Subtle breathing animation - 2% scale
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );
    _logoBreathing = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // Input stagger animation
    _inputController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Floating animation
    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    // Shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Start animations with haptic
    _cardController.forward().then((_) {
      HapticFeedback.lightImpact();
      _inputController.forward();
      _breathingController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _cardController.dispose();
    _inputController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

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
        Uri.parse('${ApiConfig.baseUrl}/api/auth/forgot-password/send-otp/'),
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
        _passwordError = 'Password does not meet the security requirements.';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/forgot-password/reset/'),
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
          _resetSuccess =
              responseBody['message'] ?? 'Password changed successfully!';
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
                  Uri.parse(
                    '${ApiConfig.baseUrl}/api/auth/forgot-password/verify-otp/',
                  ),
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
                  setDialogState(
                    () => dialogError = responseBody['error'] ?? 'Invalid OTP',
                  );
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated lock icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.buttonBackgroundColor.withOpacity(
                              0.2,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.buttonBackgroundColor
                                  .withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: AppColors.buttonBackgroundColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Verify Your Account",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Enter the 6-digit code sent to\n${_identifierController.text}",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Pinput(
                          length: 6,
                          controller: _otpController,
                          onCompleted: (_) => verifyOtpAction(),
                          onChanged:
                              (_) => setDialogState(() => dialogError = null),
                          forceErrorState: dialogError != null,
                          errorTextStyle: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 13,
                          ),
                          errorText: dialogError,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed:
                                    isVerifying
                                        ? null
                                        : () {
                                          Navigator.of(context).pop();
                                          _sendOtp();
                                        },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  foregroundColor: theme.colorScheme.onPrimary,
                                ),
                                child: Text(
                                  'Resend',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.buttonBackgroundColor,
                                      AppColors.buttonBackgroundColor.withRed(
                                        200,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.buttonBackgroundColor
                                          .withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed:
                                      isVerifying ? null : verifyOtpAction,
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
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                ),
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final safePadding = MediaQuery.of(context).padding;
    final minLayoutHeight = screenHeight - safePadding.top - safePadding.bottom;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Base background image
                    Positioned.fill(
                      child: Image.asset(
                        "assets/images/OnBoarding/background_login_sign.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colorScheme.primary.withOpacity(0.1),
                              Colors.transparent,
                              colorScheme.primary.withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Floating decorative circles
                    Positioned(
                      top:
                          screenHeight * 0.12 +
                          math.sin(_floatController.value * math.pi) * 15,
                      right: -35,
                      child: _buildFloatingCircle(
                        80,
                        colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    Positioned(
                      bottom:
                          screenHeight * 0.25 +
                          math.cos(_floatController.value * math.pi) * 12,
                      left: -25,
                      child: _buildFloatingCircle(
                        65,
                        AppColors.buttonBackgroundColor.withOpacity(0.08),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(minHeight: minLayoutHeight),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo with subtle breathing
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _cardController,
                        _breathingController,
                      ]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScale.value * _logoBreathing.value,
                          child: Opacity(
                            opacity: _cardFade.value,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(
                                      0.15 + (_logoBreathing.value - 1.0) * 2,
                                    ),
                                    blurRadius:
                                        22 + (_logoBreathing.value - 1.0) * 80,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                "assets/images/OnBoarding/logo.png",
                                height: 50,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),

                    // Animated Card
                    AnimatedBuilder(
                      animation: _cardController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _cardSlide.value),
                          child: Opacity(
                            opacity: _cardFade.value,
                            child: child,
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppColors.radiusXL),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primary.withOpacity(0.85),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                AppColors.radiusXL,
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.4),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Header Icon
                                  _buildStaggeredWidget(
                                    delay: 0.0,
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.buttonBackgroundColor
                                            .withOpacity(0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.buttonBackgroundColor
                                              .withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        _showPasswordFields
                                            ? Icons.lock_reset_rounded
                                            : Icons.mail_lock_rounded,
                                        color: AppColors.buttonBackgroundColor,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Title
                                  _buildStaggeredWidget(
                                    delay: 0.1,
                                    child: Text(
                                      _showPasswordFields
                                          ? "Reset Password"
                                          : "Forgot Password",
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            color: colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Subtitle
                                  _buildStaggeredWidget(
                                    delay: 0.15,
                                    child: Text(
                                      _showPasswordFields
                                          ? "Create a new secure password"
                                          : "Enter your email or phone to proceed",
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onPrimary
                                                .withOpacity(0.8),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // Form Fields
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeIn,
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.1, 0),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child:
                                        !_showPasswordFields
                                            ? _buildIdentifierSection(theme)
                                            : _buildResetPasswordSection(theme),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Back to login link
                    AnimatedBuilder(
                      animation: _inputController,
                      builder: (context, child) {
                        final opacity =
                            Tween<double>(begin: 0.0, end: 1.0)
                                .animate(
                                  CurvedAnimation(
                                    parent: _inputController,
                                    curve: const Interval(0.6, 1.0),
                                  ),
                                )
                                .value;
                        return Opacity(opacity: opacity, child: child);
                      },
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                          color: colorScheme.onPrimary.withOpacity(0.8),
                        ),
                        label: Text(
                          "Back to Login",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary.withOpacity(0.8),
                          ),
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

  Widget _buildFloatingCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 25,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildStaggeredWidget({required double delay, required Widget child}) {
    return AnimatedBuilder(
      animation: _inputController,
      builder: (context, _) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _inputController,
            curve: Interval(
              delay,
              (delay + 0.3).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );
        return Transform.translate(
          offset: Offset(0, 15 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
    );
  }

  Widget _buildIdentifierSection(ThemeData theme) {
    return Column(
      key: const ValueKey('identifier'),
      children: [
        _buildStaggeredWidget(
          delay: 0.2,
          child: CustomInput(
            hintText: 'Email or Phone',
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            onPrimary: true,
            validator: _validateInput,
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: theme.colorScheme.onPrimary.withOpacity(0.7),
            ),
          ),
        ),
        if (_sendOtpError != null) ...[
          const SizedBox(height: 12),
          _buildStaggeredWidget(
            delay: 0.25,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _sendOtpError!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildStaggeredWidget(
          delay: 0.3,
          child: _buildShimmerButton(
            label: 'Send OTP',
            isLoading: _isLoading,
            onPressed: _sendOtp,
          ),
        ),
      ],
    );
  }

  Widget _buildResetPasswordSection(ThemeData theme) {
    return Column(
      key: const ValueKey('reset'),
      children: [
        CustomInput(
          hintText: 'New Password',
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          onPrimary: true,
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: theme.colorScheme.onPrimary.withOpacity(0.7),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNewPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: theme.colorScheme.onPrimary.withOpacity(0.7),
            ),
            onPressed: () {
              setState(() => _obscureNewPassword = !_obscureNewPassword);
            },
          ),
        ),
        const SizedBox(height: 16),
        CustomInput(
          hintText: 'Confirm Password',
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          onPrimary: true,
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: theme.colorScheme.onPrimary.withOpacity(0.7),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: theme.colorScheme.onPrimary.withOpacity(0.7),
            ),
            onPressed: () {
              setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: theme.colorScheme.onPrimary.withOpacity(0.7),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Use 8+ characters with a mix of letters, numbers & symbols.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_passwordError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _passwordError!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_resetSuccess != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _resetSuccess!,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildShimmerButton(
          label: 'Change Password',
          isLoading: _isResetLoading,
          onPressed: _resetPassword,
        ),
      ],
    );
  }

  Widget _buildShimmerButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusRound),
            gradient: LinearGradient(
              colors: [
                AppColors.buttonBackgroundColor,
                AppColors.buttonBackgroundColor.withRed(200),
                AppColors.buttonBackgroundColor,
              ],
              stops: [0.0, _shimmerController.value, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.buttonBackgroundColor.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
              onTap: isLoading ? null : onPressed,
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppColors.spacingL,
                ),
                child: Center(
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            label,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                ),
              ),
            ),
          ),
        );
      },
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
