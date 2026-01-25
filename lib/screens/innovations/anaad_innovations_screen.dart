import 'dart:ui';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/screens/innovations/anaad_redemptions_screen.dart';
import 'package:grocery_app/screens/innovations/anaad_robots_screen.dart';
import 'package:grocery_app/screens/innovations/anaad_games_screen.dart';
import 'package:grocery_app/screens/innovations/refer_earn_screen.dart';
import 'package:grocery_app/screens/innovations/panchang/panchang_home_screen.dart';

class AnaadInnovationsScreen extends StatefulWidget {
  const AnaadInnovationsScreen({super.key});

  @override
  State<AnaadInnovationsScreen> createState() => _AnaadInnovationsScreenState();
}

class _AnaadInnovationsScreenState extends State<AnaadInnovationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _shimmerController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _floatAnimation;

  // Demo points balance
  final int _pointsBalance = 250;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _shimmerController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Background gradient
          _buildBackground(isDark),

          // Floating particles
          _buildFloatingParticles(),

          // Main content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, theme, isDark),
              _buildContent(context, theme, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [const Color(0xFF1A0F2E), const Color(0xFF0F0F1A)]
                    : [const Color(0xFFF0EBFF), const Color(0xFFF8F9FE)],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned(
              top: 100 + (_floatAnimation.value * 15),
              right: 30,
              child: _buildParticle(8, const Color(0xFF8B5CF6)),
            ),
            Positioned(
              top: 200 + (_floatAnimation.value * -10),
              left: 40,
              child: _buildParticle(6, const Color(0xFF3B82F6)),
            ),
            Positioned(
              top: 350 + (_floatAnimation.value * 12),
              right: 60,
              child: _buildParticle(5, const Color(0xFFF59E0B)),
            ),
            Positioned(
              bottom: 200 + (_floatAnimation.value * -8),
              left: 50,
              child: _buildParticle(7, const Color(0xFF10B981)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildParticle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.6),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Anaad Innovations',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Points Balance Card
              _buildPointsCard(theme, isDark),
              const SizedBox(height: 28),

              // Section Title
              Text(
                'Explore Innovations',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Feature Cards Grid
              _buildFeatureCard(
                context: context,
                theme: theme,
                isDark: isDark,
                icon: Icons.card_giftcard_rounded,
                title: 'Anaad Redemptions',
                subtitle: 'Turn your points into pure produce.',
                gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
                isComingSoon: true,
                delay: 0,
                onTap:
                    () => _navigateTo(context, const AnaadRedemptionsScreen()),
              ),
              const SizedBox(height: 16),

              _buildFeatureCard(
                context: context,
                theme: theme,
                isDark: isDark,
                icon: Icons.smart_toy_rounded,
                title: 'Anaad Robots',
                subtitle: 'Technology that serves the soil.',
                gradient: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
                isComingSoon: true,
                delay: 1,
                onTap: () => _navigateTo(context, const AnaadRobotsScreen()),
              ),
              const SizedBox(height: 16),

              _buildFeatureCard(
                context: context,
                theme: theme,
                isDark: isDark,
                icon: Icons.sports_esports_rounded,
                title: 'Anaad Games',
                subtitle: 'Learn the art of natural farming.',
                gradient: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                isComingSoon: false,
                delay: 2,
                onTap: () => _navigateTo(context, const AnaadGamesScreen()),
              ),
              const SizedBox(height: 16),

              _buildFeatureCard(
                context: context,
                theme: theme,
                isDark: isDark,
                icon: Icons.share_rounded,
                title: 'Refer & Earn',
                subtitle: 'Grow our community, reap the rewards',
                gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                isComingSoon: false,
                delay: 3,
                onTap: () => _navigateTo(context, const ReferEarnScreen()),
              ),
              const SizedBox(height: 40),

              _buildFeatureCard(
                context: context,
                theme: theme,
                isDark: isDark,
                icon: Icons.calendar_month_rounded,
                title: 'Panchang Calendar',
                subtitle: 'Today\'s Panchang & calendar view',
                gradient: [const Color(0xFF6B21A8), const Color(0xFF7C3AED)],
                isComingSoon: false,
                delay: 4,
                onTap: () => _navigateTo(context, const PanchangHomeScreen()),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildPointsCard(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix([
                0.5,
                0.2,
                0.2,
                0,
                0,
                0.2,
                0.5,
                0.2,
                0,
                0,
                0.2,
                0.2,
                0.5,
                0,
                0,
                0,
                0,
                0,
                0.7,
                0,
              ]),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6B21A8).withValues(alpha: 0.6),
                      const Color(0xFF7C3AED).withValues(alpha: 0.55),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B21A8).withValues(alpha: 0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.stars_rounded,
                                color: Colors.white70,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Anaad Points',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '$_pointsBalance',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.trending_up,
                                            color: Color(0xFF6EE7B7),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '+50 this week',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF6EE7B7,
                                                  ).withValues(alpha: 0.7),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.hourglass_top_rounded,
                                color: Colors.white54,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Coming Soon - Earn points with orders!',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Coming Soon Badge
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.rocket_launch_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'COMING SOON',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required bool isComingSoon,
    required int delay,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (delay * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final clampedOpacity = value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: clampedOpacity,
            child: _FeatureCardContent(
              theme: theme,
              isDark: isDark,
              icon: icon,
              title: title,
              subtitle: subtitle,
              gradient: gradient,
              isComingSoon: isComingSoon,
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }
}

class _FeatureCardContent extends StatefulWidget {
  final ThemeData theme;
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final bool isComingSoon;
  final VoidCallback onTap;

  const _FeatureCardContent({
    required this.theme,
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.isComingSoon,
    required this.onTap,
  });

  @override
  State<_FeatureCardContent> createState() => _FeatureCardContentState();
}

class _FeatureCardContentState extends State<_FeatureCardContent>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isComingSoon) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.isComingSoon ? null : (_) => setState(() => _isPressed = true),
      onTapUp:
          widget.isComingSoon
              ? null
              : (_) {
                setState(() => _isPressed = false);
                widget.onTap();
              },
      onTapCancel:
          widget.isComingSoon ? null : () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.gradient[0].withValues(
                alpha: widget.isComingSoon ? 0.5 : 0.3,
              ),
              width: widget.isComingSoon ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradient[0].withValues(
                  alpha: _isPressed ? 0.2 : 0.15,
                ),
                blurRadius: _isPressed ? 10 : 20,
                offset: Offset(0, _isPressed ? 4 : 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main content
              Row(
                children: [
                  // Icon with optional grayscale for coming soon
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: widget.gradient),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: widget.gradient[0].withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 26),
                      ),
                      // Lock overlay for coming soon
                      if (widget.isComingSoon)
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.hourglass_top_rounded,
                              size: 14,
                              color: widget.gradient[0],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: widget.theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: widget.theme.textTheme.bodySmall?.copyWith(
                            color:
                                widget.isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: widget.gradient[0],
                  ),
                ],
              ),

              // Coming Soon Banner - Responsive Corner Ribbon
              if (widget.isComingSoon)
                Positioned(
                  top: -10,
                  right: -10,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        // Responsive scaling factor based on screen width
                        final isWideScreen = screenWidth > 600;
                        final horizontalPadding = isWideScreen ? 12.0 : 8.0;
                        final verticalPadding = isWideScreen ? 6.0 : 4.0;
                        final iconSize = isWideScreen ? 14.0 : 10.0;
                        final fontSize = isWideScreen ? 10.0 : 8.0;
                        final borderRadius = isWideScreen ? 16.0 : 12.0;
                        final spacing = isWideScreen ? 5.0 : 3.0;

                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: verticalPadding,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [widget.gradient[0], widget.gradient[1]],
                            ),
                            borderRadius: BorderRadius.circular(borderRadius),
                            boxShadow: [
                              BoxShadow(
                                color: widget.gradient[0].withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.rocket_launch_rounded,
                                size: iconSize,
                                color: Colors.white,
                              ),
                              SizedBox(width: spacing),
                              Text(
                                'COMING SOON',
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

