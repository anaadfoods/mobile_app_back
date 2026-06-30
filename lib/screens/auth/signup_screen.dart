import 'dart:ui';
import 'dart:math' as math;
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/common_widgets/otp_resend_section.dart';
import 'package:grocery_app/models/legal_document_model.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/screens/legal/legal_content_screen.dart';
import 'package:grocery_app/services/legal_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
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
  // final bool _showPassword = false; // Unused - commented out
  // final bool _showConfirmPassword = false; // Unused - commented out
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  String? _selectedGender;

  // Legal documents
  final LegalService _legalService = getIt<LegalService>();
  List<LegalDocument> _legalDocuments = [];
  bool _isLoadingLegal = true;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;

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
  void initState() {
    super.initState();
    _initAnimations();
    _fetchLegalDocuments();
  }

  Future<void> _fetchLegalDocuments() async {
    try {
      final docs = await _legalService.fetchLegalDocuments();
      if (mounted) {
        setState(() {
          _legalDocuments = docs;
          _isLoadingLegal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLegal = false);
      }
    }
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

    // Subtle breathing animation for logo - 2% scale
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );
    _logoBreathing = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // Input stagger animation
    _inputController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Floating animation for decorative elements
    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    // Shimmer animation for button
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Start animations with haptic feedback
    _cardController.forward().then((_) {
      HapticFeedback.lightImpact();
      _inputController.forward();
      _breathingController.repeat(reverse: true);
    });
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
    _cardController.dispose();
    _inputController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    _breathingController.dispose();
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
    if (!_isPhoneVerified) {
      SnackBarHelper.showError(
        context,
        "Please verify your phone number before signing up.",
      );
      return;
    }
    if (!_termsAccepted || !_privacyAccepted) {
      SnackBarHelper.showError(
        context,
        "Please accept Terms & Conditions and Privacy Policy.",
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
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: AppColors.transparent,
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
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.parchment.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.deepSoilGreen.withValues(
                              alpha: 0.2,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.deepSoilGreen.withValues(
                                alpha: 0.4,
                              ),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            type == 'email'
                                ? Icons.email_rounded
                                : Icons.phone_android_rounded,
                            color: AppColors.deepSoilGreen,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "OTP Verification",
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "We've sent a 6-digit OTP to your $type",
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: 0.8),
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
                          defaultPinTheme: PinTheme(
                            width: 45,
                            height: 50,
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.parchment,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.parchment.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.parchment.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                          ),
                          focusedPinTheme: PinTheme(
                            width: 45,
                            height: 50,
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.parchment,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.parchment.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.deepSoilGreen,
                                width: 2,
                              ),
                            ),
                          ),
                          submittedPinTheme: PinTheme(
                            width: 45,
                            height: 50,
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.parchment,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.parchment.withValues(
                                alpha: 0.25,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.parchment.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ),
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
                        OtpResendSection(
                          onResend: () async {
                            try {
                              await context
                                  .read<AuthRepository>()
                                  .sendOtp(value.trim(), type.toUpperCase());
                              SnackBarHelper.showSuccess(
                                context,
                                'OTP resent successfully!',
                              );
                            } catch (e) {
                              SnackBarHelper.showError(
                                context,
                                e.toString().replaceAll('Exception:', '').trim(),
                              );
                              rethrow;
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  foregroundColor: colorScheme.onPrimary,
                                ),
                                child: Text(
                                  "Cancel",
                                  style: textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onPrimary.withValues(
                                      alpha: 0.8,
                                    ),
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
                                      AppColors.amberWarn,
                                      AppColors.amberWarn.withValues(
                                        alpha: 0.8,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.amberWarn.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.transparent,
                                    shadowColor: AppColors.transparent,
                                    foregroundColor: AppColors.parchment,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed:
                                      isVerifying
                                          ? null
                                          : () async {
                                            if (otpController.text.length !=
                                                6) {
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
                                                setDialogState(
                                                  () => isVerifying = false,
                                                );
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
                                              color: AppColors.parchment,
                                            ),
                                          )
                                          : Text(
                                            "Verify",
                                            style: textTheme.labelLarge
                                                ?.copyWith(
                                                  color: AppColors.parchment,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.go('/');
          } else if (state is AuthRegistrationSuccess) {
            SnackBarHelper.showSuccess(
              context,
              "Registration successful! Please log in.",
            );
            context.go('/login');
          } else if (state is AuthError) {
            final errorMsg = state.message.toLowerCase();
            if (errorMsg.contains('socket') ||
                errorMsg.contains('network') ||
                errorMsg.contains('failed host lookup') ||
                errorMsg.contains('timeout') ||
                errorMsg.contains('connection') ||
                errorMsg.contains('clientexception')) {
              SnackBarHelper.showWarning(
                context,
                "Looks like a network hiccup! Please check your internet and try again and check your details",
              );
            } else {
              SnackBarHelper.showWarning(context, state.message);
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Stack(
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
                            "assets/images/OnBoarding/background_home.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Animated gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  colorScheme.primary.withValues(alpha: 0.1),
                                  AppColors.transparent,
                                  colorScheme.primary.withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Floating decorative circles
                        Positioned(
                          top:
                              size.height * 0.15 +
                              math.sin(_floatController.value * math.pi) * 15,
                          right: -40,
                          child: _buildFloatingCircle(
                            90,
                            colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        Positioned(
                          bottom:
                              size.height * 0.2 +
                              math.cos(_floatController.value * math.pi) * 12,
                          left: -25,
                          child: _buildFloatingCircle(
                            70,
                            AppColors.deepSoilGreen.withValues(alpha: 0.08),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppColors.spacingXL,
                    vertical: AppColors.spacingM,
                  ),
                  child: Column(
                    children: [
                      // Animated Logo with subtle breathing (No background circle)
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
                              child: Align(
                                alignment: Alignment.center,
                                child: Image.asset(
                                  "assets/images/OnBoarding/logo.png",
                                  height: 70, // Slightly larger
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppColors.spacingXL),

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
                          borderRadius: BorderRadius.circular(
                            AppColors.radiusXL,
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(
                                AppColors.spacingXL,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.primary.withValues(alpha: 0.85),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppColors.radiusXL,
                                ),
                                border: Border.all(
                                  color: AppColors.parchment.withValues(
                                    alpha: 0.2,
                                  ),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Header with stagger animation
                                    _buildStaggeredWidget(
                                      delay: 0.0,
                                      child: Text(
                                        " Let’s grow and heal the world together",
                                        textAlign:
                                            TextAlign.center, // Center align
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              color: colorScheme.onPrimary,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: AppColors.spacingS),
                                    _buildStaggeredWidget(
                                      delay: 0.05,
                                      child: Text(
                                        "Join the ICBN Family for nourishment, not just groceries.",
                                        textAlign:
                                            TextAlign.center, // Center align
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onPrimary
                                              .withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppColors.spacingXL),

                                    // Name Row
                                    _buildStaggeredWidget(
                                      delay: 0.1,
                                      child: Row(
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
                                                  (isValid) =>
                                                      _updateFieldValidity(
                                                        'firstName',
                                                        isValid,
                                                      ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
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
                                                  (isValid) =>
                                                      _updateFieldValidity(
                                                        'lastName',
                                                        isValid,
                                                      ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Username
                                    _buildStaggeredWidget(
                                      delay: 0.15,
                                      child: CustomInput(
                                        hintText: "Username",
                                        controller: _usernameController,
                                        onPrimary: true,
                                        validator:
                                            (v) =>
                                                v!.isEmpty
                                                    ? 'Enter username'
                                                    : null,
                                        onValidationChanged:
                                            (isValid) => _updateFieldValidity(
                                              'username',
                                              isValid,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Email with verify
                                    _buildStaggeredWidget(
                                      delay: 0.2,
                                      child: CustomInput(
                                        hintText: "Email",
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        onPrimary: true,
                                        validator: (v) {
                                          if (v!.isEmpty) return 'Enter email';
                                          if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                          ).hasMatch(v)) {
                                            return 'Invalid email';
                                          }
                                          return null;
                                        },
                                        onValidationChanged: (isValid) {
                                          _updateFieldValidity('email', isValid);
                                          if (_isEmailVerified) {
                                            setState(() => _isEmailVerified = false);
                                          }
                                        },
                                        suffixIcon: _buildVerifyButton(
                                          label:
                                              _isEmailVerified
                                                  ? "Verified"
                                                  : "Verify",
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
                                                      () =>
                                                          _isEmailVerified =
                                                              true,
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
                                    ),
                                    const SizedBox(height: AppColors.spacingL),

                                    // Phone with verify
                                    _buildStaggeredWidget(
                                      delay: 0.25,
                                      child: CustomInput(
                                        hintText: "Phone number",
                                        controller: _phoneController,
                                        keyboardType: TextInputType.number,
                                        onPrimary: true,
                                        validator: (v) {
                                          if (v!.isEmpty) {
                                            return 'Enter phone number';
                                          }
                                          if (!RegExp(
                                            r'^[0-9]{10}$',
                                          ).hasMatch(v)) {
                                            return 'Invalid phone number';
                                          }
                                          return null;
                                        },
                                        onValidationChanged: (isValid) {
                                          _updateFieldValidity('phone', isValid);
                                          if (_isPhoneVerified) {
                                            setState(() => _isPhoneVerified = false);
                                          }
                                        },
                                        suffixIcon: _buildVerifyButton(
                                          label:
                                              _isPhoneVerified
                                                  ? "Verified"
                                                  : "Verify",
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
                                                type: 'MOBILE',
                                                value: _phoneController.text,
                                                onVerified:
                                                    () => setState(
                                                      () =>
                                                          _isPhoneVerified =
                                                              true,
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
                                    ),
                                    const SizedBox(height: 20),

                                    // Password
                                    _buildStaggeredWidget(
                                      delay: 0.3,
                                      child: CustomInput(
                                        hintText: "Password",
                                        controller: _passwordController,
                                        obscureText: true,
                                        onPrimary: true,
                                        validator: (v) {
                                          if (v!.isEmpty) {
                                            return 'Enter password';
                                          }
                                          if (v.length < 6) {
                                            return 'Min 6 characters';
                                          }
                                          return null;
                                        },
                                        onValidationChanged:
                                            (isValid) => _updateFieldValidity(
                                              'password',
                                              isValid,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Confirm Password
                                    _buildStaggeredWidget(
                                      delay: 0.35,
                                      child: CustomInput(
                                        hintText: "Confirm Password",
                                        controller: _confirmPasswordController,
                                        obscureText: true,
                                        onPrimary: true,
                                        validator: (v) {
                                          if (v!.isEmpty) {
                                            return 'Confirm password';
                                          }
                                          if (v != _passwordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                        onValidationChanged:
                                            (isValid) => _updateFieldValidity(
                                              'confirmPassword',
                                              isValid,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Referral Code
                                    _buildStaggeredWidget(
                                      delay: 0.4,
                                      child: CustomInput(
                                        hintText: "Referral Code (Optional)",
                                        controller: _referralCodeController,
                                        onPrimary: true,
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) => _handleSignup(),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Legal Checkboxes
                                    _buildStaggeredWidget(
                                      delay: 0.42,
                                      child: _buildLegalCheckboxes(),
                                    ),
                                    const SizedBox(height: 24),

                                    // Sign Up Button
                                    _buildStaggeredWidget(
                                      delay: 0.45,
                                      child: _buildShimmerButton(
                                        label: "Sign Up",
                                        isLoading: isLoading,
                                        isEnabled:
                                            _isFormValid &&
                                            _termsAccepted &&
                                            _privacyAccepted,
                                        onPressed: _handleSignup,
                                      ),
                                    ),
                                    const SizedBox(height: AppColors.spacingS),

                                    // Login Link
                                    _buildStaggeredWidget(
                                      delay: 0.5,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Already have an account?",
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme.onPrimary
                                                      .withValues(alpha: 0.8),
                                                ),
                                          ),
                                          TextButton(
                                            onPressed:
                                                isLoading
                                                    ? null
                                                    : () => context.go('/login'),
                                            child: Text(
                                              "Login",
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.harvestAmber,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppColors.spacingXL),

                      // Divider with animation
                      AnimatedBuilder(
                        animation: _inputController,
                        builder: (context, child) {
                          final opacity =
                              Tween<double>(begin: 0.0, end: 1.0)
                                  .animate(
                                    CurvedAnimation(
                                      parent: _inputController,
                                      curve: const Interval(0.6, 0.8),
                                    ),
                                  )
                                  .value;
                          return Opacity(opacity: opacity, child: child);
                        },
                        child: Row(
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
                      ),
                      const SizedBox(height: AppColors.spacingXL),

                      // Google Button with animation
                      AnimatedBuilder(
                        animation: _inputController,
                        builder: (context, child) {
                          final slideValue =
                              Tween<double>(begin: 30.0, end: 0.0)
                                  .animate(
                                    CurvedAnimation(
                                      parent: _inputController,
                                      curve: const Interval(
                                        0.7,
                                        0.9,
                                        curve: Curves.easeOut,
                                      ),
                                    ),
                                  )
                                  .value;
                          final opacity =
                              Tween<double>(begin: 0.0, end: 1.0)
                                  .animate(
                                    CurvedAnimation(
                                      parent: _inputController,
                                      curve: const Interval(0.7, 0.9),
                                    ),
                                  )
                                  .value;
                          return Transform.translate(
                            offset: Offset(0, slideValue),
                            child: Opacity(opacity: opacity, child: child),
                          );
                        },
                        child: Center(
                          child: _GoogleSignUpButton(
                            isLoading: isLoading,
                            onPressed:
                                () => context.read<AuthCubit>().googleLogin(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppColors.spacingM),

                      // Apple Button with animation
                      AnimatedBuilder(
                        animation: _inputController,
                        builder: (context, child) {
                          final slideValue =
                              Tween<double>(begin: 30.0, end: 0.0)
                                  .animate(
                                    CurvedAnimation(
                                      parent: _inputController,
                                      curve: const Interval(
                                        0.8,
                                        1.0,
                                        curve: Curves.easeOut,
                                      ),
                                    ),
                                  )
                                  .value;
                          final opacity =
                              Tween<double>(begin: 0.0, end: 1.0)
                                  .animate(
                                    CurvedAnimation(
                                      parent: _inputController,
                                      curve: const Interval(0.8, 1.0),
                                    ),
                                  )
                                  .value;
                          return Transform.translate(
                            offset: Offset(0, slideValue),
                            child: Opacity(opacity: opacity, child: child),
                          );
                        },
                        child: Center(
                          child: _AppleSignUpButton(
                            isLoading: isLoading,
                            onPressed:
                                () => context.read<AuthCubit>().appleLogin(),
                          ),
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

  Widget _buildFloatingCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
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

  Widget _buildShimmerButton({
    required String label,
    required bool isLoading,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isEnabled ? 1.0 : 0.6,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
              gradient: LinearGradient(
                colors: [
                  AppColors.harvestAmber,
                  AppColors.harvestAmber.withValues(alpha: 0.8),
                  AppColors.harvestAmber,
                ],
                stops: [0.0, _shimmerController.value, 1.0],
              ),
              boxShadow:
                  isEnabled
                      ? [
                        BoxShadow(
                          color: AppColors.deepSoilGreen.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ]
                      : null,
            ),
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppColors.radiusRound),
                onTap: isLoading || !isEnabled ? null : onPressed,
                splashColor: AppColors.parchment.withValues(alpha: 0.2),
                highlightColor: AppColors.parchment.withValues(alpha: 0.1),
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
                                  AppColors.parchment,
                                ),
                              ),
                            )
                            : Text(
                              label,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: AppColors.pureWhite,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
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

  Widget _buildVerifyButton({
    required String label,
    required bool isVerified,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 5, top: 4, bottom: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: TextButton(
          onPressed: isVerified ? null : onPressed,
          style: TextButton.styleFrom(
            backgroundColor:
                isVerified ? AppColors.deepSoilGreen : AppColors.deepSoilGreen,
            foregroundColor: AppColors.parchment,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isVerified)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppColors.parchment,
                  ),
                ),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalCheckboxes() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoadingLegal) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.parchment70),
          ),
        ),
      );
    }

    // Find terms and privacy documents
    LegalDocument? termsDoc;
    LegalDocument? privacyDoc;
    for (final doc in _legalDocuments) {
      if (doc.isTermsAndConditions) {
        termsDoc = doc;
      } else if (doc.isPrivacyPolicy) {
        privacyDoc = doc;
      }
    }

    return Column(
      children: [
        // Terms of Service checkbox
        _buildLegalCheckboxRow(
          label: 'I agree to the ',
          linkText: 'Terms of Service',
          isChecked: _termsAccepted,
          onChanged: (value) => setState(() => _termsAccepted = value ?? false),
          onLinkTap:
              termsDoc != null
                  ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LegalContentScreen(document: termsDoc!),
                    ),
                  )
                  : null,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        const SizedBox(height: AppColors.spacingS),
        // Privacy Policy checkbox
        _buildLegalCheckboxRow(
          label: 'I agree to the ',
          linkText: 'Privacy Policy',
          isChecked: _privacyAccepted,
          onChanged:
              (value) => setState(() => _privacyAccepted = value ?? false),
          onLinkTap:
              privacyDoc != null
                  ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LegalContentScreen(document: privacyDoc!),
                    ),
                  )
                  : null,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      ],
    );
  }

  Widget _buildLegalCheckboxRow({
    required String label,
    required String linkText,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
    required VoidCallback? onLinkTap,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: isChecked,
            onChanged: onChanged,
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.deepSoilGreen;
              }
              return AppColors.parchment.withValues(alpha: 0.2);
            }),
            checkColor: AppColors.parchment,
            side: BorderSide(color: AppColors.parchment.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!isChecked),
            child: RichText(
              text: TextSpan(
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.9),
                ),
                children: [
                  TextSpan(text: label),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: onLinkTap,
                      child: Text(
                        linkText,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.harvestAmber,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.harvestAmber,
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
    );
  }
}

// Enhanced Google Sign-up Button with colorful design
class _GoogleSignUpButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleSignUpButton({required this.isLoading, required this.onPressed});

  @override
  State<_GoogleSignUpButton> createState() => _GoogleSignUpButtonState();
}

class _GoogleSignUpButtonState extends State<_GoogleSignUpButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap:
            widget.isLoading
                ? null
                : () {
                  HapticFeedback.lightImpact();
                  widget.onPressed();
                },
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.spacingXL,
              vertical: AppColors.spacingM,
            ),
            decoration: BoxDecoration(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
              border: Border.all(
                color: _isHovered ? AppColors.rawEarth12 : AppColors.parchment,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.charcoal.withValues(
                    alpha: _isHovered ? 0.12 : 0.08,
                  ),
                  blurRadius: _isHovered ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Colorful Google Logo
                AnimatedScale(
                  scale: _isHovered ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(painter: _GoogleLogoPainter()),
                  ),
                ),
                const SizedBox(width: AppColors.spacingM),
                Text(
                  "Sign up with Google",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.charcoal60,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for colorful Google logo
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double center = s / 2;
    final double outerRadius = s / 2;
    final double innerRadius = s * 0.28;

    // Google brand colors
    const Color blue = Color(0xFF4285F4);
    const Color red = Color(0xFFEA4335);
    const Color yellow = Color(0xFFFBBC05);
    const Color green = Color(0xFF34A853);

    final paint = Paint()..style = PaintingStyle.fill;

    // Draw the colored arcs (outer ring)
    // Blue section (right side, from -45° to 45°)
    paint.color = blue;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: outerRadius),
      -0.78, // -45 degrees
      1.57, // 90 degrees
      true,
      paint,
    );

    // Green section (bottom right, from 45° to 135°)
    paint.color = green;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: outerRadius),
      0.78, // 45 degrees
      1.57, // 90 degrees
      true,
      paint,
    );

    // Yellow section (bottom left, from 135° to 225°)
    paint.color = yellow;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: outerRadius),
      2.36, // 135 degrees
      1.57, // 90 degrees
      true,
      paint,
    );

    // Red section (top, from 225° to 315°)
    paint.color = red;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: outerRadius),
      3.93, // 225 degrees
      1.57, // 90 degrees
      true,
      paint,
    );

    // Cut out the inner circle (white center)
    paint.color = AppColors.parchment;
    canvas.drawCircle(Offset(center, center), innerRadius, paint);

    // Cut out the top-right opening of the G
    paint.color = AppColors.parchment;
    final path = Path();
    path.moveTo(center, center);
    path.lineTo(s, center);
    path.lineTo(s, 0);
    path.lineTo(center + innerRadius * 0.5, 0);
    path.lineTo(center, center - innerRadius);
    path.close();
    canvas.drawPath(path, paint);

    // Draw the horizontal bar of the G (blue)
    paint.color = blue;
    final barHeight = s * 0.22;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        center - s * 0.02,
        center - barHeight / 2,
        s * 0.54,
        barHeight,
      ),
      const Radius.circular(1),
    );
    canvas.drawRRect(barRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Enhanced Apple Sign-up Button
class _AppleSignUpButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _AppleSignUpButton({required this.isLoading, required this.onPressed});

  @override
  State<_AppleSignUpButton> createState() => _AppleSignUpButtonState();
}

class _AppleSignUpButtonState extends State<_AppleSignUpButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap:
            widget.isLoading
                ? null
                : () {
                  HapticFeedback.lightImpact();
                  widget.onPressed();
                },
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.spacingXL,
              vertical: AppColors.spacingM,
            ),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
              border: Border.all(
                color: _isHovered ? AppColors.charcoal87 : AppColors.charcoal,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.charcoal.withValues(
                    alpha: _isHovered ? 0.3 : 0.2,
                  ),
                  blurRadius: _isHovered ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: _isHovered ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: Icon(
                      Icons.apple,
                      color: AppColors.parchment,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: AppColors.spacingM),
                Text(
                  "Sign up with Apple",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.parchment,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
