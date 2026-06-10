import 'dart:ui';
import 'dart:math' as math;
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/screens/innovations/games/cow_to_soil_cycle_game_screen.dart';
import 'package:grocery_app/screens/innovations/games/microbe_mania_game_screen.dart';
import 'package:grocery_app/screens/innovations/games/seed_savior_game_screen.dart';
import 'package:grocery_app/screens/innovations/games/compost_commander_game_screen.dart';
import 'package:grocery_app/screens/innovations/games/ritu_chakra_game_screen.dart';

class AnaadGamesScreen extends StatefulWidget {
  const AnaadGamesScreen({super.key});

  @override
  State<AnaadGamesScreen> createState() => _AnaadGamesScreenState();
}

class _AnaadGamesScreenState extends State<AnaadGamesScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  final _emailController = TextEditingController();
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.parchment : AppColors.parchment,
      body: Stack(
        children: [
          _buildNewBackground(isDark),
          _buildFloatingParticles(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, theme, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // New header
                      _buildNewHeader(theme, isDark),
                      const SizedBox(height: 20),

                      // Games count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.deepSoilGreen.withValues(alpha: 0.15),
                              AppColors.deepSoilGreen.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.deepSoilGreen.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🎮', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                            Text(
                              '5 GAMES READY TO PLAY',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.deepSoilGreen,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick play grid
                      _buildQuickPlayGrid(theme, isDark),
                      const SizedBox(height: 24),

                      // Featured section title
                      Row(
                        children: [
                          const Text('🌟', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            'FEATURED GAMES',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildFeaturedGame(theme, isDark),
                      const SizedBox(height: 14),
                      _buildMicrobeManiaFeatured(theme, isDark),
                      const SizedBox(height: 14),
                      _buildSeedSaviorFeatured(theme, isDark),
                      const SizedBox(height: 14),
                      _buildCompostCommanderFeatured(theme, isDark),
                      const SizedBox(height: 14),
                      _buildRituChakraFeatured(theme, isDark),
                      const SizedBox(height: 24),

                      // Info card
                      _buildAnaadInfoStrip(theme, isDark),
                      const SizedBox(height: 24),

                      // All games list
                      _buildGameConcepts(theme, isDark),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewBackground(bool isDark) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? [AppColors.parchment, AppColors.parchment]
                    : [AppColors.parchment, AppColors.parchment],
          ),
        ),
        child: CustomPaint(
          painter: _LeafPatternPainter(
            isDark: isDark,
            animation: _floatAnimation.value,
          ),
        ),
      ),
    );
  }

  Widget _buildNewHeader(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Logo
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder:
              (_, __) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.parchment,
                        AppColors.parchment,
                        AppColors.parchment,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.parchment.withValues(alpha: 0.5),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.parchment.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🌾', style: TextStyle(fontSize: 30)),
                          Text(
                            'A',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.parchment,
                              height: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ),
        const SizedBox(height: 16),

        // Title
        ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [AppColors.parchment, AppColors.parchment],
              ).createShader(bounds),
          child: const Text(
            'ANAAD GAMES',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.parchment,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Learn Sustainable Farming Through Play',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.parchment54 : AppColors.charcoal45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPlayGrid(ThemeData theme, bool isDark) {
    final quickGames = [
      {
        'emoji': '🐄',
        'name': 'Cow Cycle',
        'color': AppColors.parchment,
        'screen': const CowToSoilCycleGameScreen(),
      },
      {
        'emoji': '🦠',
        'name': 'Microbe',
        'color': AppColors.parchment,
        'screen': const MicrobeManiaGameScreen(),
      },
      {
        'emoji': '🌾',
        'name': 'Seeds',
        'color': AppColors.parchment,
        'screen': const SeedSaviorGameScreen(),
      },
      {
        'emoji': '🌱',
        'name': 'Compost',
        'color': AppColors.parchment,
        'screen': const CompostCommanderGameScreen(),
      },
      {
        'emoji': '☀️',
        'name': 'Seasons',
        'color': AppColors.parchment,
        'screen': const RituChakraGameScreen(),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
              alpha: 0.08,
            ),
            (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
              alpha: 0.02,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
            alpha: 0.1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'QUICK PLAY',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                quickGames
                    .map(
                      (g) => GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => g['screen'] as Widget,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    (g['color'] as Color),
                                    (g['color'] as Color).withValues(
                                      alpha: 0.7,
                                    ),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: (g['color'] as Color).withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  g['emoji'] as String,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              g['name'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: g['color'] as Color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? [AppColors.parchment, AppColors.parchment]
                    : [AppColors.parchment, AppColors.parchment],
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
              top: 100 + (_floatAnimation.value * 12),
              right: 35,
              child: _particle(9, AppColors.parchment),
            ),
            Positioned(
              top: 220 + (_floatAnimation.value * -10),
              left: 25,
              child: _particle(6, AppColors.parchment),
            ),
            Positioned(
              bottom: 280 + (_floatAnimation.value * 8),
              right: 50,
              child: _particle(5, AppColors.parchment),
            ),
          ],
        );
      },
    );
  }

  Widget _particle(double size, Color color) {
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
      backgroundColor: AppColors.transparent,
      elevation: 0,
      pinned: true,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? AppColors.parchment : AppColors.charcoal)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.parchment : AppColors.charcoal87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.parchment, AppColors.parchment],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.parchment.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: AppColors.parchment,
              size: 60,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnaadInfoStrip(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showPremiumInfoPopup(theme, isDark);
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder:
            (_, __) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [AppColors.parchment, AppColors.parchment]
                          : [AppColors.parchment, AppColors.parchment],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.parchment.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.parchment.withValues(
                      alpha: 0.15 * _pulseAnimation.value,
                    ),
                    blurRadius: 25,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.parchment.withValues(
                      alpha: 0.1 * _pulseAnimation.value,
                    ),
                    blurRadius: 30,
                    spreadRadius: 1,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Premium animated logo
                  _buildPremiumAnaadLogo(theme, isDark),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ShaderMask(
                              shaderCallback:
                                  (bounds) => const LinearGradient(
                                    colors: [
                                      AppColors.parchment,
                                      AppColors.parchment,
                                      AppColors.parchment,
                                    ],
                                  ).createShader(bounds),
                              child: Text(
                                'ANAAD',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.parchment,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildPremiumBetaBadge(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Learn sustainable farming through play',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                isDark
                                    ? AppColors.rawEarth26
                                    : AppColors.rawEarth70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildMiniFeature('🎮', '4 Games'),
                            const SizedBox(width: 8),
                            _buildMiniFeature('📚', 'Learn'),
                            const SizedBox(width: 8),
                            _buildMiniFeature('🌱', 'Grow'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.parchment.withValues(alpha: 0.2),
                          AppColors.parchment.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.parchment.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.parchment,
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildMiniFeature(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.parchment.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.parchment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAnaadLogo(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder:
          (_, __) => Transform.scale(
            scale: 0.95 + (_pulseAnimation.value * 0.1),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.parchment,
                    AppColors.parchment,
                    AppColors.parchment,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.parchment.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: AppColors.parchment.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating ring effect
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder:
                        (_, __) => Transform.rotate(
                          angle: _floatAnimation.value * 3.14159 * 2,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.parchment.withValues(
                                  alpha: 0.15,
                                ),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                  ),
                  // Center content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌾', style: TextStyle(fontSize: 20)),
                      Text(
                        'A',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.parchment,
                          height: 0.9,
                          shadows: [
                            const Shadow(
                              color: AppColors.charcoal38,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Corner badge
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.parchment, AppColors.parchment],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.parchment,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.parchment.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'i',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            color: AppColors.parchment,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildPremiumBetaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.parchment, AppColors.parchment],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.parchment.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⚡', style: TextStyle(fontSize: 9)),
          SizedBox(width: 3),
          Text(
            'BETA',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: AppColors.parchment,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumInfoPopup(ThemeData theme, bool isDark) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Anaad Info',
      barrierColor: AppColors.charcoal.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim, secondAnim, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (dialogContext, __, ___) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxHeight: 600),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.parchment.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: AppColors.charcoal.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors:
                            isDark
                                ? [
                                  AppColors.parchment.withValues(alpha: 0.95),
                                  AppColors.parchment.withValues(alpha: 0.95),
                                ]
                                : [
                                  AppColors.parchment.withValues(alpha: 0.95),
                                  AppColors.parchment.withValues(alpha: 0.95),
                                ],
                      ),
                      border: Border.all(
                        color: AppColors.parchment.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Premium header
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.parchment.withValues(
                                        alpha: 0.3,
                                      ),
                                      AppColors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.parchment,
                                      AppColors.parchment,
                                      AppColors.parchment,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.parchment.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.parchment.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('🌾', style: TextStyle(fontSize: 24)),
                                    Text(
                                      'A',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.parchment,
                                        height: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.rawEarth.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.rawEarth.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                      color: AppColors.rawEarth,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ShaderMask(
                                shaderCallback:
                                    (bounds) => const LinearGradient(
                                      colors: [
                                        AppColors.parchment,
                                        AppColors.parchment,
                                      ],
                                    ).createShader(bounds),
                                child: Text(
                                  'ANAAD GAMES',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.parchment,
                                        letterSpacing: 3,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _buildPremiumBetaBadge(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Learn Sustainable Farming Through Play',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark
                                      ? AppColors.rawEarth26
                                      : AppColors.rawEarth70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Why Important
                          _buildPremiumSection(
                            emoji: '🌍',
                            title: 'WHY IT MATTERS',
                            gradient: [
                              AppColors.parchment,
                              AppColors.parchment,
                            ],
                            content:
                                'Anaad Games transform complex farming knowledge into memorable, hands-on experiences. Instead of forgetting what you read, you learn by doing - making decisions, seeing consequences, and building real skills.',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 14),

                          // What You Learn
                          _buildPremiumSection(
                            emoji: '🎓',
                            title: 'WHAT YOU LEARN',
                            gradient: [
                              AppColors.parchment,
                              AppColors.parchment,
                            ],
                            bullets: [
                              '🦠 Soil health: microbes, organic matter, nutrient cycles',
                              '🔄 Natural farming: Desi cow → Jeevamrut → Healthy soil',
                              '♻️ Waste-to-wealth: Composting science & C:N balance',
                              '💧 Resource wisdom: Water management, pest control',
                              '🌱 Seed biodiversity: Why native seeds matter',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 14),

                          // How to Play Compost Commander
                          _buildPremiumSection(
                            emoji: '🪵',
                            title: 'HOW TO PLAY: COMPOST COMMANDER',
                            gradient: [
                              AppColors.parchment,
                              AppColors.parchment,
                            ],
                            bullets: [
                              '📦 TAP materials to add layers to your compost bin',
                              '⚖️ BALANCE: Mix browns (🍂 carbon) with greens (🌿 nitrogen)',
                              '🔄 TURN pile for oxygen, 💧 ADD WATER for moisture',
                              '⚠️ FIX red alerts: smell, pests, too wet/dry',
                              '🏆 Reach 100% maturity to win coins + XP!',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),

                          // Play button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => const CompostCommanderGameScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.parchment,
                                    AppColors.parchment,
                                    AppColors.parchment,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.parchment.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(
                                  color: AppColors.parchment.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '🌱',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Play Compost Commander',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.parchment,
                                          letterSpacing: 1,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.parchment,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Close button
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Got it!',
                              style: TextStyle(
                                color:
                                    isDark
                                        ? AppColors.rawEarth26
                                        : AppColors.rawEarth70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildPremiumSection({
    required String emoji,
    required String title,
    required List<Color> gradient,
    String? content,
    List<String>? bullets,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradient[0].withValues(alpha: 0.15),
            gradient[1].withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gradient[0].withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradient[0].withValues(alpha: 0.3),
                      gradient[1].withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: gradient[0],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (content != null)
            Text(
              content,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.parchment70 : AppColors.charcoal54,
                height: 1.5,
              ),
            ),
          if (bullets != null)
            ...bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 14,
                        color: gradient[0],
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isDark
                                  ? AppColors.parchment70
                                  : AppColors.charcoal54,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _popupSection({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required String emoji,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
          alpha: 0.05,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
            alpha: 0.08,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.parchment : AppColors.charcoal87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.5,
              color: isDark ? AppColors.rawEarth12 : AppColors.charcoal60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _popupBullets({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required String emoji,
    required List<String> bullets,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
          alpha: 0.05,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
            alpha: 0.08,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.parchment : AppColors.charcoal87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.parchment.withValues(alpha: 0.35),
                          AppColors.parchment.withValues(alpha: 0.20),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.parchment.withValues(alpha: 0.06),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: AppColors.parchment,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.45,
                        color:
                            isDark
                                ? AppColors.rawEarth12
                                : AppColors.charcoal60,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.parchment.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.parchment.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.games_rounded, color: AppColors.parchment, size: 18),
          const SizedBox(width: 8),
          Text(
            'Coming Soon (More Games)',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.parchment,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayableBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.parchment.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.parchment.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.play_circle_fill_rounded,
            color: AppColors.parchment,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Now Playable',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.parchment,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.parchment : AppColors.parchment,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.parchment.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.parchment.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.parchment.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.article_rounded,
                  color: AppColors.parchment,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'About Anaad Games',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Gaming for Good: Sustainable Farming Adventures',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.parchment,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Experience farming like never before! Our upcoming games teach ICBN (Integrated Community Based Natural) farming through engaging gameplay.\n\n'
            'What you\'ll learn:\n'
            '• Organic farming techniques\n'
            '• Sustainable water management\n'
            '• Natural pest control methods\n'
            '• Crop rotation benefits\n\n'
            'Every virtual crop you grow contributes to real-world agricultural awareness. Play, compete with friends, and become a sustainable farming champion!',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.7,
              color: isDark ? AppColors.rawEarth12 : AppColors.charcoal60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedGame(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [AppColors.parchment, AppColors.parchment]
                  : [AppColors.parchment, AppColors.parchment],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.parchment.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.parchment.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.parchment, AppColors.parchment],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('🐄', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.parchment,
                      ),
                    ),
                    Text(
                      'Cow → Soil Cycle',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppColors.parchment : AppColors.charcoal87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.parchment.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.parchment.withValues(alpha: 0.25),
                  ),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.parchment,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Drag and build the natural farming journey: Desi Cow → Inputs → Jeevamrut → Soil → Crop.\\n'
            'Earn streaks, learn concepts, and play quick rounds.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: isDark ? AppColors.rawEarth12 : AppColors.charcoal60,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CowToSoilCycleGameScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.parchment, AppColors.parchment],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.parchment.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Play Now',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.parchment,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showHowToPlay(theme, isDark);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.parchment.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.parchment.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.parchment,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHowToPlay(ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.parchment : AppColors.parchment,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.rawEarth54.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('🐄', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'How to Play',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isDark
                                  ? AppColors.parchment
                                  : AppColors.charcoal87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color:
                            isDark
                                ? AppColors.parchment70
                                : AppColors.charcoal54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '1) Long‑press and drag a card.\\n'
                  '2) Drop it into the correct journey slot.\\n'
                  '3) Complete the cycle before time ends.\\n\\n'
                  'Try “Challenge” mode to spot and avoid chemical decoys ☠️.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: isDark ? AppColors.rawEarth12 : AppColors.charcoal60,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMicrobeManiaFeatured(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [AppColors.parchment, AppColors.parchment]
                  : [AppColors.parchment, AppColors.parchment],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.parchment.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.parchment.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.parchment, AppColors.parchment],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('🦠', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEW GAME',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.parchment,
                      ),
                    ),
                    Text(
                      'Microbe Mania',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppColors.parchment : AppColors.charcoal87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.parchment.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.parchment.withValues(alpha: 0.25),
                  ),
                ),
                child: const Text(
                  '🔥 HOT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.parchment,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Play as a beneficial soil microbe! Endless runner with power-ups, unlockable characters, achievements & educational content.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: isDark ? AppColors.rawEarth12 : AppColors.charcoal60,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _featureChip('🏃 Endless Runner', AppColors.parchment),
              _featureChip('🛡️ Power-Ups', AppColors.parchment),
              _featureChip('🏆 Achievements', AppColors.parchment),
              _featureChip('🔓 Unlock Microbes', AppColors.parchment),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MicrobeManiaGameScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.parchment, AppColors.parchment],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.parchment.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.parchment,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Play Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.parchment,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSeedSaviorFeatured(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [AppColors.parchment, AppColors.parchment]
                  : [AppColors.parchment, AppColors.parchment],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.parchment.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.parchment.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.parchment, AppColors.parchment],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('🌾', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEW GAME',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.parchment,
                      ),
                    ),
                    Text(
                      'Seed Savior',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppColors.parchment : AppColors.charcoal87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.parchment.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.parchment.withValues(alpha: 0.25),
                  ),
                ),
                child: const Text(
                  '🎮 NEW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.parchment,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Match-3 puzzle game! Match native seeds to save them from extinction. Avoid GMO invaders, collect seeds, and learn about biodiversity.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: isDark ? AppColors.rawEarth12 : AppColors.charcoal60,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _featureChip('🧩 Match-3', AppColors.parchment),
              _featureChip('🌾 6 Seed Types', AppColors.parchment),
              _featureChip('🏆 10 Levels', AppColors.parchment),
              _featureChip('⚡ Combos', AppColors.parchment),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SeedSaviorGameScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.parchment, AppColors.parchment],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.parchment.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.parchment,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Play Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.parchment,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompostCommanderFeatured(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [AppColors.parchment, AppColors.parchment]
                  : [AppColors.parchment, AppColors.parchment],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.parchment.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.parchment.withValues(alpha: 0.15),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.parchment, AppColors.parchment],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.parchment.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Text('🌱', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PREMIUM GAME',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.parchment,
                      ),
                    ),
                    Text(
                      'Compost Commander',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppColors.parchment : AppColors.charcoal87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.parchment.withValues(alpha: 0.3),
                      AppColors.parchment.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.parchment.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('⭐', style: TextStyle(fontSize: 10)),
                    SizedBox(width: 4),
                    Text(
                      'AAA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.parchment,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Master the art of decomposition! Balance carbon, nitrogen, moisture & temperature to create black gold. Fight pests, manage critters, and learn real composting science.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: isDark ? AppColors.rawEarth12 : AppColors.charcoal60,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _featureChip('🧪 Simulation', AppColors.parchment),
              _featureChip('📈 20 Levels', AppColors.parchment),
              _featureChip('🛒 Upgrades', AppColors.parchment),
              _featureChip('🎓 Learn Science', AppColors.parchment),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CompostCommanderGameScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.parchment, AppColors.parchment],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.parchment.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.parchment,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Play Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.parchment,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRituChakraFeatured(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [AppColors.parchment, AppColors.parchment]
                  : [AppColors.parchment, AppColors.parchment],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.parchment.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.parchment.withValues(alpha: 0.2),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Animated seasonal wheel icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const SweepGradient(
                    colors: [
                      AppColors.parchment, // Vasant
                      AppColors.parchment, // Grishma
                      AppColors.parchment, // Varsha
                      AppColors.parchment, // Sharad
                      AppColors.parchment, // Hemant
                      AppColors.parchment, // Shishir
                      AppColors.parchment, // Back to Vasant
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.parchment.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.harvestAmber,
                        AppColors.harvestAmber,
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.parchment.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text('☀️', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STRATEGY GAME',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.parchment,
                      ),
                    ),
                    Text(
                      'Ritu Chakra',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppColors.parchment : AppColors.charcoal87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.rawEarth.withValues(alpha: 0.3),
                      AppColors.harvestAmber.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.rawEarth.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 10)),
                    SizedBox(width: 4),
                    Text(
                      'HOT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.rawEarth,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Master the 6 Hindu seasons! Plant crops, manage resources, survive weather events. A year-long cycle of growth, harvest, and ancient farming wisdom.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: isDark ? AppColors.rawEarth12 : AppColors.charcoal60,
            ),
          ),
          const SizedBox(height: 10),
          // Season chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _seasonChip('🌸', 'Vasant', AppColors.parchment),
                _seasonChip('☀️', 'Grishma', AppColors.parchment),
                _seasonChip('🌧️', 'Varsha', AppColors.parchment),
                _seasonChip('🍂', 'Sharad', AppColors.parchment),
                _seasonChip('🌫️', 'Hemant', AppColors.parchment),
                _seasonChip('❄️', 'Shishir', AppColors.parchment),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _featureChip('🌾 8 Crops', AppColors.parchment),
              _featureChip('📅 3 Years', AppColors.parchment),
              _featureChip('🎯 Strategy', AppColors.parchment),
              _featureChip('🌦️ Weather', AppColors.parchment),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RituChakraGameScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.parchment,
                    AppColors.parchment,
                    AppColors.parchment,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.parchment.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.parchment,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Play Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.parchment,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seasonChip(String emoji, String name, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameConcepts(ThemeData theme, bool isDark) {
    final games = [
      {
        'icon': Icons.spa_rounded,
        'name': 'Cow → Soil Cycle',
        'desc': 'Build the natural cycle',
        'soon': false,
        'color': AppColors.parchment,
      },
      {
        'icon': Icons.bug_report_rounded,
        'name': 'Microbe Mania',
        'desc': 'Endless runner as soil microbe',
        'soon': false,
        'color': AppColors.parchment,
      },
      {
        'icon': Icons.grass_rounded,
        'name': 'Seed Savior',
        'desc': 'Match-3 to save native seeds',
        'soon': false,
        'color': AppColors.parchment,
      },
      {
        'icon': Icons.eco_rounded,
        'name': 'Compost Commander',
        'desc': 'Master decomposition science',
        'soon': false,
        'color': AppColors.parchment,
      },
      {
        'icon': Icons.wb_sunny_rounded,
        'name': 'Ritu Chakra',
        'desc': 'Master 6 Hindu seasons',
        'soon': false,
        'color': AppColors.parchment,
      },
      {
        'icon': Icons.water_drop_rounded,
        'name': 'Water Wisdom',
        'desc': 'Traditional water harvesting',
        'soon': true,
        'color': AppColors.parchment,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Games',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...games.asMap().entries.map((entry) {
          final index = entry.key;
          final game = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (index * 100)),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(20 * (1 - value), 0),
                  child: Opacity(
                    opacity: value,
                    child: GestureDetector(
                      onTap: () {
                        if (!(game['soon'] as bool)) {
                          HapticFeedback.mediumImpact();
                          final name = game['name'] as String;
                          if (name.contains('Cow')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const CowToSoilCycleGameScreen(),
                              ),
                            );
                          } else if (name.contains('Microbe')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MicrobeManiaGameScreen(),
                              ),
                            );
                          } else if (name.contains('Seed')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SeedSaviorGameScreen(),
                              ),
                            );
                          } else if (name.contains('Compost')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const CompostCommanderGameScreen(),
                              ),
                            );
                          } else if (name.contains('Ritu')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RituChakraGameScreen(),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (game['color'] as Color).withValues(
                                alpha: isDark ? 0.15 : 0.08,
                              ),
                              (game['color'] as Color).withValues(
                                alpha: isDark ? 0.05 : 0.02,
                              ),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (game['color'] as Color).withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    (game['color'] as Color),
                                    (game['color'] as Color).withValues(
                                      alpha: 0.7,
                                    ),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                game['icon'] as IconData,
                                color: AppColors.parchment,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    game['name'] as String,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    game['desc'] as String,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          isDark
                                              ? AppColors.rawEarth26
                                              : AppColors.rawEarth70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: ((game['soon'] as bool)
                                        ? AppColors.rawEarth54
                                        : AppColors.parchment)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: ((game['soon'] as bool)
                                          ? AppColors.rawEarth54
                                          : AppColors.parchment)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!(game['soon'] as bool))
                                    const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 14,
                                      color: AppColors.parchment,
                                    ),
                                  if (!(game['soon'] as bool))
                                    const SizedBox(width: 4),
                                  Text(
                                    (game['soon'] as bool)
                                        ? 'Coming Soon'
                                        : 'Play',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          (game['soon'] as bool)
                                              ? AppColors.rawEarth54
                                              : AppColors.parchment,
                                      fontWeight: FontWeight.w700,
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
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNotifyForm(ThemeData theme, bool isDark) {
    if (_isSubscribed) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.parchment.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.parchment.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.parchment,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'You\'re in! We\'ll notify you at launch.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.parchment,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.parchment : AppColors.parchment,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.parchment.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Be the First to Play',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get early access and exclusive rewards',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.rawEarth26 : AppColors.rawEarth70,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.parchment.withValues(alpha: 0.05)
                      : AppColors.rawEarth54.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _emailController,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: isDark ? AppColors.rawEarth26 : AppColors.rawEarth70,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (_emailController.text.isNotEmpty) {
                HapticFeedback.mediumImpact();
                setState(() => _isSubscribed = true);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.parchment, AppColors.parchment],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.parchment.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Join Waitlist',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.parchment,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for leaf pattern background
class _LeafPatternPainter extends CustomPainter {
  final bool isDark;
  final double animation;

  _LeafPatternPainter({required this.isDark, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rand = math.Random(42);

    // Draw subtle leaf patterns
    for (int i = 0; i < 20; i++) {
      final x = rand.nextDouble() * size.width;
      final baseY = rand.nextDouble() * size.height;
      final y = (baseY + animation * 30) % size.height;
      final leafSize = rand.nextDouble() * 15 + 8;

      paint.color = AppColors.deepSoilGreen.withValues(
        alpha: isDark ? 0.04 : 0.06,
      );

      // Simple leaf shape
      final path = Path();
      path.moveTo(x, y - leafSize);
      path.quadraticBezierTo(x + leafSize * 0.7, y, x, y + leafSize);
      path.quadraticBezierTo(x - leafSize * 0.7, y, x, y - leafSize);
      canvas.drawPath(path, paint);
    }

    // Draw subtle circles
    for (int i = 0; i < 10; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final radius = rand.nextDouble() * 30 + 20;

      paint.color = (i % 2 == 0
              ? AppColors.deepSoilGreen
              : AppColors.harvestAmber)
          .withValues(alpha: isDark ? 0.02 : 0.03);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LeafPatternPainter old) =>
      old.animation != animation;
}
