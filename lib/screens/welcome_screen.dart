import 'dart:math' as math;
import 'dart:ui';
import 'package:grocery_app/common_widgets/global_import.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final List<OnboardingData> onboardingData = [
    OnboardingData(
      image: "assets/images/OnBoarding/onboarding1.jpg",
      title: "Taste the Earth’s honest work.",
      subtitle:
          " Pure ICBN harvests, brought straight from our fields to your home",
      icon: Icons.eco_rounded,
    ),
    OnboardingData(
      image: "assets/images/OnBoarding/onboarding1.jpg",
      title: " Grown by hands we trust.",
      subtitle:
          " No unethical middlemen. Just local farmers growing real nourishment for your family while nourishing the planet.",
      icon: Icons.local_shipping_rounded,
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _pageOffset = 0.0;

  // Animation Controllers
  late AnimationController _logoController;
  late AnimationController _particleController;
  late AnimationController _buttonController;
  late AnimationController _textController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoPulse;
  late Animation<double> _buttonBounce;
  late Animation<double> _buttonGlow;

  // Floating particles
  final List<FloatingParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateParticles();
    _pageController.addListener(_onPageScroll);
  }

  void _initAnimations() {
    // Logo animation - gentle scale in with subtle breathing
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );
    // Subtle breathing pulse - only 2% scale change for soothing effect
    _logoPulse = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );
    _logoController.forward();
    // Light haptic on logo appear
    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.lightImpact();
        // Slow breathing loop - 4 seconds per cycle
        _logoController.duration = const Duration(milliseconds: 4000);
        _logoController.repeat(reverse: true);
      }
    });

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Button animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _buttonBounce = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    _buttonGlow = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // Text stagger animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  void _generateParticles() {
    final random = math.Random();
    for (int i = 0; i < 25; i++) {
      _particles.add(
        FloatingParticle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 4 + 2,
          speed: random.nextDouble() * 0.3 + 0.1,
          opacity: random.nextDouble() * 0.5 + 0.2,
          delay: random.nextDouble(),
        ),
      );
    }
  }

  void _onPageScroll() {
    setState(() {
      _pageOffset = _pageController.page ?? 0.0;
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _logoController.dispose();
    _particleController.dispose();
    _buttonController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Stack(
        children: [
          // Parallax Background Images
          ...List.generate(onboardingData.length, (index) {
            final parallaxOffset = (_pageOffset - index) * 0.3;
            final opacity = (1 - (_pageOffset - index).abs()).clamp(0.0, 1.0);

            return Positioned.fill(
              child: Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(parallaxOffset * size.width, 0),
                  child: Transform.scale(
                    scale: 1.1 + (parallaxOffset.abs() * 0.1),
                    child: Image.asset(
                      onboardingData[index].image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            );
          }),

          // Animated Gradient Overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryColor.withOpacity(0.3),
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.95),
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // Floating Particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                  color: Colors.white,
                ),
              );
            },
          ),

          // Page View (invisible, just for gestures)
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingData.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _textController.reset();
              _textController.forward();
            },
            itemBuilder: (context, index) => const SizedBox.expand(),
          ),

          // Logo with Animation
          Positioned(
            top: size.height * 0.12, // Slightly adjusted top position
            left: 0,
            right: 0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Popping Circle (Kept the animation)
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value * _logoPulse.value,
                      child: Container(
                        width: 220, // Explicit size since image is removed
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryLight.withOpacity(0.2),
                              blurRadius: 40,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Logo Image (Increased size, No "Pop Up" Scale 0->1)
                // Only applying breathing pulse for liveliness
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoPulse.value, // Only breathing, no pop-up
                        child: Image.asset(
                          'assets/images/OnBoarding/logo.png',
                          width: 160, // Increased size significantly
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Content Area with Staggered Animation
          Positioned(
            bottom: 200,
            left: AppColors.spacingXL,
            right: AppColors.spacingXL,
            child: AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                final data = onboardingData[_currentPage];
                return Column(
                  children: [
                    // Animated Icon
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _textController,
                          curve: const Interval(
                            0.0,
                            0.5,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      ),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _textController,
                          curve: const Interval(0.0, 0.5),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.buttonBackgroundColor.withOpacity(
                              0.2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.buttonBackgroundColor
                                  .withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            data.icon,
                            color: AppColors.buttonBackgroundColor,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppColors.spacingL),

                    // Animated Title
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _textController,
                          curve: const Interval(
                            0.2,
                            0.7,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      ),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _textController,
                          curve: const Interval(0.2, 0.7),
                        ),
                        child: ShaderMask(
                          shaderCallback:
                              (bounds) => LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.9),
                                  AppColors.buttonBackgroundColor.withOpacity(
                                    0.8,
                                  ),
                                ],
                              ).createShader(bounds),
                          child: Text(
                            data.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppColors.spacingM),

                    // Animated Subtitle
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _textController,
                          curve: const Interval(
                            0.4,
                            0.9,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      ),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _textController,
                          curve: const Interval(0.4, 0.9),
                        ),
                        child: Text(
                          data.subtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            height: 1.6,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Enhanced Page Indicator
          Positioned(
            bottom: 140,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(onboardingData.length, (index) {
                final isActive = _currentPage == index;
                final distance = (_pageOffset - index).abs();
                final scale = (1 - distance * 0.3).clamp(0.7, 1.0);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      height: 12,
                      width: isActive ? 36 : 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color:
                            isActive
                                ? AppColors.buttonBackgroundColor
                                : Colors.white.withOpacity(0.4),
                        boxShadow:
                            isActive
                                ? [
                                  BoxShadow(
                                    color: AppColors.buttonBackgroundColor
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                                : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Enhanced Button with Glow Effect
          Positioned(
            bottom: 50,
            left: AppColors.spacingXL,
            right: AppColors.spacingXL,
            child: AnimatedBuilder(
              animation: _buttonController,
              builder: (context, child) {
                final isLastPage = _currentPage == onboardingData.length - 1;

                return Transform.translate(
                  offset: Offset(0, isLastPage ? _buttonBounce.value : 0),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (isLastPage) {
                        onGetStartedClicked(context);
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child:
                          isLastPage
                              ? _buildGetStartedButton(theme, colorScheme)
                              : _buildNextButton(theme, colorScheme),
                    ),
                  ),
                );
              },
            ),
          ),

          // Skip Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _currentPage < onboardingData.length - 1 ? 1.0 : 0.0,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _pageController.animateToPage(
                    onboardingData.length - 1,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        "Skip",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedButton(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      key: const ValueKey('start'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.spacingXXL,
        vertical: AppColors.spacingL + 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.buttonBackgroundColor,
            AppColors.buttonBackgroundColor.withRed(200),
          ],
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
        boxShadow: [
          BoxShadow(
            color: AppColors.buttonBackgroundColor.withOpacity(
              _buttonGlow.value,
            ),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.buttonBackgroundColor.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Get Started",
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: AppColors.spacingS),
          const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      key: const ValueKey('next'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Page number indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${_currentPage + 1}/${onboardingData.length}",
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Next button
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spacingXL,
            vertical: AppColors.spacingM + 2,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppColors.radiusRound),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Next",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: AppColors.spacingS),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void onGetStartedClicked(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }
}

// Data class for onboarding content
class OnboardingData {
  final String image;
  final String title;
  final String subtitle;
  final IconData icon;

  OnboardingData({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

// Floating particle data
class FloatingParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double delay;

  FloatingParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.delay,
  });
}

// Custom painter for floating particles
class ParticlePainter extends CustomPainter {
  final List<FloatingParticle> particles;
  final double progress;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final adjustedProgress = (progress + particle.delay) % 1.0;
      final y = (particle.y - adjustedProgress * particle.speed * 3) % 1.0;
      final x = particle.x + math.sin(adjustedProgress * math.pi * 2) * 0.02;

      final paint =
          Paint()
            ..color = color.withOpacity(
              particle.opacity * (1 - (y - 0.5).abs() * 0.5),
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

