import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Extended controller duration to 2500ms
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Phase 1 (0.0 to 1.5s / 0.0 to 0.6 of controller): Logo fades in
    _logoFadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    // Phase 1 (0.0 to 1.5s / 0.0 to 0.6 of controller): Logo scales
    _logoScaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Phase 2 (1.5 to 2.5s / 0.6 to 1.0 of controller): Tagline and title fade in
    _textFadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );

    // Introduce a short delay before animating to let native screen transition settle
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
      }
    });

    // Navigate to home after total splash delay of 3500ms
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        context.go(AppRoute.home.path);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine background color based on theme mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkCanvas : AppColors.parchment;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _logoFadeAnimation,
              child: ScaleTransition(
                scale: _logoScaleAnimation,
                child: Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/images/OnBoarding/logo.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _textFadeAnimation,
              child: Column(
                children: [
                  Text(
                    'ANAAD FOODS',
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.parchment
                              : AppColors.deepSoilGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SACRED TRACEABLE COMMITMENT',
                    style: TextStyle(
                      color: (isDark ? AppColors.parchment : AppColors.charcoal)
                          .withValues(alpha: 0.6),
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
