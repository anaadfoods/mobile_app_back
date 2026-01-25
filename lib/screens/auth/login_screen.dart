import 'dart:ui';
import 'dart:math' as math;
import 'package:grocery_app/common_widgets/global_import.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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

  // Focus nodes for input animation
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _emailFocused = false;
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupFocusListeners();
  }

  void _initAnimations() {
    // Card entrance animation
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardSlide = Tween<double>(begin: 80.0, end: 0.0).animate(
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Floating animation for decorative elements
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
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

  void _setupFocusListeners() {
    _emailFocus.addListener(() {
      setState(() => _emailFocused = _emailFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _passwordFocused = _passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _cardController.dispose();
    _inputController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    _breathingController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        const DashboardScreen(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
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
                                  Colors.transparent,
                                  colorScheme.primary.withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Floating decorative circles
                        Positioned(
                          top:
                              size.height * 0.1 +
                              math.sin(_floatController.value * math.pi) * 20,
                          right: -50,
                          child: _buildFloatingCircle(
                            100,
                            colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        Positioned(
                          bottom:
                              size.height * 0.3 +
                              math.cos(_floatController.value * math.pi) * 15,
                          left: -30,
                          child: _buildFloatingCircle(
                            80,
                            AppColors.buttonBackgroundColor.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Main Content
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.all(AppColors.spacingXL),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Animated Logo with subtle breathing (No background circle)
                                AnimatedBuilder(
                                  animation: Listenable.merge([
                                    _cardController,
                                    _breathingController,
                                  ]),
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale:
                                          _logoScale.value *
                                          _logoBreathing.value,
                                      child: Opacity(
                                        opacity: _cardFade.value,
                                        child: Align(
                                          alignment:
                                              Alignment
                                                  .center, // Center alignment
                                          child: Image.asset(
                                            "assets/images/OnBoarding/logo.png",
                                            height:
                                                80, // Slightly larger as requested (user asked to increase size in previous turn, keep it reasonable)
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: AppColors.spacingXXL),

                                // Animated Login Card
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
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(
                                          AppColors.spacingXL,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              colorScheme.primary,
                                              colorScheme.primary.withValues(
                                                alpha: 0.85,
                                              ),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppColors.radiusXL,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 30,
                                              offset: const Offset(0, 15),
                                            ),
                                          ],
                                        ),
                                        child: Form(
                                          key: _formKey,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              // Welcome Text with stagger animation
                                              _buildStaggeredWidget(
                                                delay: 0.0,
                                                child: Text(
                                                  "Welcome Home!",
                                                  textAlign:
                                                      TextAlign
                                                          .center, // Center align
                                                  style: textTheme.headlineSmall
                                                      ?.copyWith(
                                                        color:
                                                            colorScheme
                                                                .onPrimary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        letterSpacing: 0.5,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: AppColors.spacingXS,
                                              ),
                                              _buildStaggeredWidget(
                                                delay: 0.1,
                                                child: Text(
                                                  "Your harvest is ready and waiting.",
                                                  textAlign:
                                                      TextAlign
                                                          .center, // Center align
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .onPrimary
                                                            .withValues(
                                                              alpha: 0.85,
                                                            ),
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: AppColors.spacingXL,
                                              ),

                                              // Email Input with focus animation
                                              _buildStaggeredWidget(
                                                delay: 0.2,
                                                child: _buildAnimatedInput(
                                                  child: CustomInput(
                                                    hintText: "Email",
                                                    controller:
                                                        _emailController,
                                                    focusNode: _emailFocus,
                                                    keyboardType:
                                                        TextInputType
                                                            .emailAddress,
                                                    onPrimary: true,
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty)
                                                        return 'Please enter your email';
                                                      if (!RegExp(
                                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                                      ).hasMatch(value)) {
                                                        return 'Please enter a valid email';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                  isFocused: _emailFocused,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: AppColors.spacingL,
                                              ),

                                              // Password Input with focus animation
                                              _buildStaggeredWidget(
                                                delay: 0.3,
                                                child: _buildAnimatedInput(
                                                  child: CustomInput(
                                                    hintText: "Password",
                                                    obscureText: true,
                                                    controller:
                                                        _passwordController,
                                                    focusNode: _passwordFocus,
                                                    onPrimary: true,
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty)
                                                        return 'Please enter your password';
                                                      return null;
                                                    },
                                                  ),
                                                  isFocused: _passwordFocused,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: AppColors.spacingXS,
                                              ),

                                              // Forgot Password with hover effect
                                              _buildStaggeredWidget(
                                                delay: 0.4,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: TextButton(
                                                    onPressed:
                                                        isLoading
                                                            ? null
                                                            : () => Navigator.push(
                                                              context,
                                                              _buildPageRoute(
                                                                const ForgetPasswordScreen(),
                                                              ),
                                                            ),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          colorScheme.onPrimary,
                                                    ),
                                                    child: Text(
                                                      "Forgot Password?",
                                                      style: textTheme.bodySmall
                                                          ?.copyWith(
                                                            color: colorScheme
                                                                .onPrimary
                                                                .withValues(
                                                                  alpha: 0.85,
                                                                ),
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: AppColors.spacingM,
                                              ),

                                              // Enhanced Login Button
                                              _buildStaggeredWidget(
                                                delay: 0.5,
                                                child: _buildShimmerButton(
                                                  isLoading: isLoading,
                                                  onPressed: _handleLogin,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: AppColors.spacingL,
                                              ),

                                              // Register Link
                                              _buildStaggeredWidget(
                                                delay: 0.6,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "Don't have an account?",
                                                      style: textTheme.bodySmall
                                                          ?.copyWith(
                                                            color: colorScheme
                                                                .onPrimary
                                                                .withValues(
                                                                  alpha: 0.85,
                                                                ),
                                                          ),
                                                    ),
                                                    TextButton(
                                                      onPressed:
                                                          isLoading
                                                              ? null
                                                              : () => Navigator.push(
                                                                context,
                                                                _buildPageRoute(
                                                                  const SignupScreen(),
                                                                ),
                                                              ),
                                                      child: Text(
                                                        "Register",
                                                        style: textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              color:
                                                                  AppColors
                                                                      .buttonBackgroundColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
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

                                const Spacer(),

                                // Animated Divider
                                AnimatedBuilder(
                                  animation: _inputController,
                                  builder: (context, child) {
                                    final opacity =
                                        Tween<double>(begin: 0.0, end: 1.0)
                                            .animate(
                                              CurvedAnimation(
                                                parent: _inputController,
                                                curve: const Interval(0.7, 1.0),
                                              ),
                                            )
                                            .value;
                                    return Opacity(
                                      opacity: opacity,
                                      child: child,
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: theme.dividerColor,
                                        ),
                                      ),
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
                                      Expanded(
                                        child: Divider(
                                          color: theme.dividerColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppColors.spacingXL),

                                // Animated Google Sign-in Button
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
                                      child: Opacity(
                                        opacity: opacity,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Center(
                                    child: _GoogleSignInButton(
                                      isLoading: isLoading,
                                      onPressed:
                                          () =>
                                              context
                                                  .read<AuthCubit>()
                                                  .googleLogin(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppColors.spacingXL),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
            blurRadius: 30,
            spreadRadius: 10,
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
              (delay + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
    );
  }

  Widget _buildAnimatedInput({required Widget child, required bool isFocused}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      transform: Matrix4.identity()..scale(isFocused ? 1.02 : 1.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        boxShadow:
            isFocused
                ? [
                  BoxShadow(
                    color: AppColors.buttonBackgroundColor.withValues(
                      alpha: 0.3,
                    ),
                    blurRadius: 15,
                    spreadRadius: 0,
                  ),
                ]
                : null,
      ),
      child: child,
    );
  }

  Widget _buildShimmerButton({
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
                color: AppColors.buttonBackgroundColor.withValues(alpha: 0.4),
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
              splashColor: Colors.white.withValues(alpha: 0.2),
              highlightColor: Colors.white.withValues(alpha: 0.1),
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
                            "Login",
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

  PageRouteBuilder _buildPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

// Enhanced Google Sign-in Button with colorful design
class _GoogleSignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton>
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
              border: Border.all(
                color: _isHovered ? Colors.grey.shade300 : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.08),
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
                  "Sign in with Google",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
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
    paint.color = Colors.white;
    canvas.drawCircle(Offset(center, center), innerRadius, paint);

    // Cut out the top-right opening of the G
    paint.color = Colors.white;
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

