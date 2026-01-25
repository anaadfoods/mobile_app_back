import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/services.dart';
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
      backgroundColor: isDark ? const Color(0xFF0A0F0A) : const Color(0xFFF5FAF5),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.05)]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🎮', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                            Text('5 GAMES READY TO PLAY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.green, letterSpacing: 1)),
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
                          Text('FEATURED GAMES', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1)),
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
            colors: isDark
                ? [const Color(0xFF0A1A0A), const Color(0xFF0A0F0A)]
                : [const Color(0xFFE8F5E9), const Color(0xFFF5FAF5)],
          ),
        ),
        child: CustomPaint(
          painter: _LeafPatternPainter(isDark: isDark, animation: _floatAnimation.value),
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
          builder: (_, __) => Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF22C55E), Color(0xFF16A34A), Color(0xFF15803D)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.5), blurRadius: 25, spreadRadius: 5),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌾', style: TextStyle(fontSize: 30)),
                      Text('A', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white, height: 0.8)),
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
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
          ).createShader(bounds),
          child: const Text('ANAAD GAMES', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
        ),
        const SizedBox(height: 4),
        Text(
          'Learn Sustainable Farming Through Play',
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
  
  Widget _buildQuickPlayGrid(ThemeData theme, bool isDark) {
    final quickGames = [
      {'emoji': '🐄', 'name': 'Cow Cycle', 'color': const Color(0xFF10B981), 'screen': const CowToSoilCycleGameScreen()},
      {'emoji': '🦠', 'name': 'Microbe', 'color': const Color(0xFF8B5CF6), 'screen': const MicrobeManiaGameScreen()},
      {'emoji': '🌾', 'name': 'Seeds', 'color': const Color(0xFF4CAF50), 'screen': const SeedSaviorGameScreen()},
      {'emoji': '🌱', 'name': 'Compost', 'color': const Color(0xFF795548), 'screen': const CompostCommanderGameScreen()},
      {'emoji': '☀️', 'name': 'Seasons', 'color': const Color(0xFFFF6B00), 'screen': const RituChakraGameScreen()},
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [(isDark ? Colors.white : Colors.black).withOpacity(0.08), (isDark ? Colors.white : Colors.black).withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('QUICK PLAY', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: quickGames.map((g) => GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.push(context, MaterialPageRoute(builder: (_) => g['screen'] as Widget));
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
                        colors: [(g['color'] as Color), (g['color'] as Color).withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: (g['color'] as Color).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Center(child: Text(g['emoji'] as String, style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(height: 6),
                  Text(g['name'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: g['color'] as Color)),
                ],
              ),
            )).toList(),
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
            colors: isDark
                ? [const Color(0xFF0D1A2E), const Color(0xFF0F0F1A)]
                : [const Color(0xFFEBF5FF), const Color(0xFFF8F9FE)],
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
              child: _particle(9, const Color(0xFF3B82F6)),
            ),
            Positioned(
              top: 220 + (_floatAnimation.value * -10),
              left: 25,
              child: _particle(6, const Color(0xFF60A5FA)),
            ),
            Positioned(
              bottom: 280 + (_floatAnimation.value * 8),
              right: 50,
              child: _particle(5, const Color(0xFF93C5FD)),
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
        color: color.withOpacity(0.6),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme, bool isDark) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
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
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
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
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 60),
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
        builder: (_, __) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1A2830), const Color(0xFF0F1A20)]
                  : [const Color(0xFFF0FDF4), const Color(0xFFECFDF5)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF22C55E).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withOpacity(0.15 * _pulseAnimation.value),
                blurRadius: 25,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.1 * _pulseAnimation.value),
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
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF22C55E), Color(0xFF10B981), Color(0xFF059669)],
                          ).createShader(bounds),
                          child: Text(
                            'ANAAD',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
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
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                    colors: [const Color(0xFF22C55E).withOpacity(0.2), const Color(0xFF22C55E).withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF22C55E)),
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
        color: const Color(0xFF22C55E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF22C55E))),
        ],
      ),
    );
  }

  Widget _buildPremiumAnaadLogo(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, __) => Transform.scale(
        scale: 0.95 + (_pulseAnimation.value * 0.1),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF22C55E), Color(0xFF16A34A), Color(0xFF15803D)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating ring effect
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (_, __) => Transform.rotate(
                  angle: _floatAnimation.value * 3.14159 * 2,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
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
                      color: Colors.white,
                      height: 0.9,
                      shadows: [const Shadow(color: Colors.black38, blurRadius: 8)],
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
                    gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.5), blurRadius: 6)],
                  ),
                  child: const Center(child: Text('i', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white))),
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
          colors: [Color(0xFFFF6B00), Color(0xFFFF9500)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF6B00).withOpacity(0.4), blurRadius: 8),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⚡', style: TextStyle(fontSize: 9)),
          SizedBox(width: 3),
          Text(
            'BETA',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
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
      barrierColor: Colors.black.withOpacity(0.85),
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
                  BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.3), blurRadius: 40, spreadRadius: 5),
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 15)),
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
                        colors: isDark
                            ? [const Color(0xFF0A1A0F).withOpacity(0.95), const Color(0xFF0F1A12).withOpacity(0.95)]
                            : [Colors.white.withOpacity(0.95), const Color(0xFFF0FDF4).withOpacity(0.95)],
                      ),
                      border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3), width: 2),
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
                                    colors: [const Color(0xFF22C55E).withOpacity(0.3), Colors.transparent],
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
                                    colors: [Color(0xFF22C55E), Color(0xFF16A34A), Color(0xFF15803D)],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                                  boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.5), blurRadius: 20)],
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('🌾', style: TextStyle(fontSize: 24)),
                                    Text('A', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, height: 0.8)),
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
                                      color: Colors.red.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                                    ),
                                    child: const Icon(Icons.close_rounded, size: 20, color: Colors.red),
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
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFF22C55E), Color(0xFF10B981)],
                                ).createShader(bounds),
                                child: Text('ANAAD GAMES', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3)),
                              ),
                              const SizedBox(width: 10),
                              _buildPremiumBetaBadge(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Learn Sustainable Farming Through Play', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.w500)),
                          const SizedBox(height: 20),
                          
                          // Why Important
                          _buildPremiumSection(
                            emoji: '🌍',
                            title: 'WHY IT MATTERS',
                            gradient: [const Color(0xFF22C55E), const Color(0xFF16A34A)],
                            content: 'Anaad Games transform complex farming knowledge into memorable, hands-on experiences. Instead of forgetting what you read, you learn by doing - making decisions, seeing consequences, and building real skills.',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 14),
                          
                          // What You Learn
                          _buildPremiumSection(
                            emoji: '🎓',
                            title: 'WHAT YOU LEARN',
                            gradient: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
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
                            gradient: [const Color(0xFF795548), const Color(0xFF5D4037)],
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
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const CompostCommanderGameScreen()));
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF795548), Color(0xFF5D4037), Color(0xFF4E342E)]),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [BoxShadow(color: const Color(0xFF795548).withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))],
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('🌱', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Text('Play Compost Commander', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Close button
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Got it!', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.w600)),
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
          colors: [gradient[0].withOpacity(0.15), gradient[1].withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gradient[0].withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [gradient[0].withOpacity(0.3), gradient[1].withOpacity(0.15)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1, color: gradient[0])),
            ],
          ),
          const SizedBox(height: 10),
          if (content != null)
            Text(content, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54, height: 1.5)),
          if (bullets != null)
            ...bullets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•', style: TextStyle(fontSize: 14, color: gradient[0], fontWeight: FontWeight.w900)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(b, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54, height: 1.4))),
                ],
              ),
            )),
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
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
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
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
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
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
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
                  color: isDark ? Colors.white : Colors.black87,
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
                        colors: [const Color(0xFF10B981).withOpacity(0.35), const Color(0xFF3B82F6).withOpacity(0.20)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: const Center(
                      child: Icon(Icons.check_rounded, size: 12, color: Color(0xFF10B981)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.45,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
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
        color: const Color(0xFF3B82F6).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.games_rounded, color: Color(0xFF3B82F6), size: 18),
          const SizedBox(width: 8),
          Text(
            'Coming Soon (More Games)',
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF3B82F6),
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
        color: const Color(0xFF10B981).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 8),
          Text(
            'Now Playable',
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF10B981),
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
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
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
                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.article_rounded, color: Color(0xFF3B82F6), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'About Anaad Games',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Gaming for Good: Sustainable Farming Adventures',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3B82F6),
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
              color: isDark ? Colors.grey[300] : Colors.grey[700],
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
          colors: isDark
              ? [const Color(0xFF0B1228), const Color(0xFF0F0F1A)]
              : [Colors.white, const Color(0xFFEBF5FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.12),
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
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
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
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      'Cow → Soil Cycle',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
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
              color: isDark ? Colors.grey[300] : Colors.grey[700],
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
                      MaterialPageRoute(builder: (_) => const CowToSoilCycleGameScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Play Now',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
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
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.help_outline_rounded, color: Color(0xFF10B981)),
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121225) : Colors.white,
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
                      color: Colors.grey.withOpacity(0.3),
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
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black54),
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
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
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
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [Colors.white, const Color(0xFFF0E6FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.12),
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
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
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
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    Text(
                      'Microbe Mania',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.25)),
                ),
                child: const Text(
                  '🔥 HOT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8B5CF6),
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
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _featureChip('🏃 Endless Runner', const Color(0xFF8B5CF6)),
              _featureChip('🛡️ Power-Ups', const Color(0xFF8B5CF6)),
              _featureChip('🏆 Achievements', const Color(0xFF8B5CF6)),
              _featureChip('🔓 Unlock Microbes', const Color(0xFF8B5CF6)),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MicrobeManiaGameScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Play Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
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
          colors: isDark
              ? [const Color(0xFF1A2810), const Color(0xFF0F1A08)]
              : [Colors.white, const Color(0xFFF5F8E8)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.12),
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
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
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
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    Text(
                      'Seed Savior',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.25)),
                ),
                child: const Text(
                  '🎮 NEW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF9800),
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
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _featureChip('🧩 Match-3', const Color(0xFF4CAF50)),
              _featureChip('🌾 6 Seed Types', const Color(0xFF4CAF50)),
              _featureChip('🏆 10 Levels', const Color(0xFF4CAF50)),
              _featureChip('⚡ Combos', const Color(0xFF4CAF50)),
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
                gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Play Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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
          colors: isDark
              ? [const Color(0xFF1A1510), const Color(0xFF0F0D08)]
              : [Colors.white, const Color(0xFFF5EDE0)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF795548).withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF795548).withOpacity(0.15),
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
                    colors: [Color(0xFF795548), Color(0xFF5D4037)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF795548).withOpacity(0.4),
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
                        color: const Color(0xFF795548),
                      ),
                    ),
                    Text(
                      'Compost Commander',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFFFD700).withOpacity(0.3), const Color(0xFFFFD700).withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
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
                        color: Color(0xFFFFD700),
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
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _featureChip('🧪 Simulation', const Color(0xFF795548)),
              _featureChip('📈 20 Levels', const Color(0xFF795548)),
              _featureChip('🛒 Upgrades', const Color(0xFF795548)),
              _featureChip('🎓 Learn Science', const Color(0xFF795548)),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CompostCommanderGameScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF795548), Color(0xFF5D4037)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF795548).withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Play Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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
          colors: isDark
              ? [const Color(0xFF1A1008), const Color(0xFF0F0805)]
              : [Colors.white, const Color(0xFFFFF8E8)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withOpacity(0.2),
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
                      Color(0xFFFF69B4), // Vasant
                      Color(0xFFFF8C00), // Grishma
                      Color(0xFF4169E1), // Varsha
                      Color(0xFFDAA520), // Sharad
                      Color(0xFF708090), // Hemant
                      Color(0xFF4682B4), // Shishir
                      Color(0xFFFF69B4), // Back to Vasant
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withOpacity(0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.amber[100]!, Colors.orange[300]!],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: const Center(child: Text('☀️', style: TextStyle(fontSize: 18))),
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
                        color: const Color(0xFFFF6B00),
                      ),
                    ),
                    Text(
                      'Ritu Chakra',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.withOpacity(0.3), Colors.orange.withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.red.withOpacity(0.4)),
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
                        color: Colors.red,
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
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          // Season chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _seasonChip('🌸', 'Vasant', const Color(0xFFFF69B4)),
                _seasonChip('☀️', 'Grishma', const Color(0xFFFF8C00)),
                _seasonChip('🌧️', 'Varsha', const Color(0xFF4169E1)),
                _seasonChip('🍂', 'Sharad', const Color(0xFFDAA520)),
                _seasonChip('🌫️', 'Hemant', const Color(0xFF708090)),
                _seasonChip('❄️', 'Shishir', const Color(0xFF4682B4)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _featureChip('🌾 8 Crops', const Color(0xFFFF6B00)),
              _featureChip('📅 3 Years', const Color(0xFFFF6B00)),
              _featureChip('🎯 Strategy', const Color(0xFFFF6B00)),
              _featureChip('🌦️ Weather', const Color(0xFFFF6B00)),
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
                gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFF8C00), Color(0xFFFFD700)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B00).withOpacity(0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Play Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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
        gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }


  Widget _buildGameConcepts(ThemeData theme, bool isDark) {
    final games = [
      {'icon': Icons.spa_rounded, 'name': 'Cow → Soil Cycle', 'desc': 'Build the natural cycle', 'soon': false, 'color': const Color(0xFF10B981)},
      {'icon': Icons.bug_report_rounded, 'name': 'Microbe Mania', 'desc': 'Endless runner as soil microbe', 'soon': false, 'color': const Color(0xFF8B5CF6)},
      {'icon': Icons.grass_rounded, 'name': 'Seed Savior', 'desc': 'Match-3 to save native seeds', 'soon': false, 'color': const Color(0xFF4CAF50)},
      {'icon': Icons.eco_rounded, 'name': 'Compost Commander', 'desc': 'Master decomposition science', 'soon': false, 'color': const Color(0xFF795548)},
      {'icon': Icons.wb_sunny_rounded, 'name': 'Ritu Chakra', 'desc': 'Master 6 Hindu seasons', 'soon': false, 'color': const Color(0xFFFF6B00)},
      {'icon': Icons.water_drop_rounded, 'name': 'Water Wisdom', 'desc': 'Traditional water harvesting', 'soon': true, 'color': const Color(0xFF06B6D4)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Games',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CowToSoilCycleGameScreen()));
                          } else if (name.contains('Microbe')) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const MicrobeManiaGameScreen()));
                          } else if (name.contains('Seed')) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SeedSaviorGameScreen()));
                          } else if (name.contains('Compost')) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CompostCommanderGameScreen()));
                          } else if (name.contains('Ritu')) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const RituChakraGameScreen()));
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (game['color'] as Color).withOpacity(isDark ? 0.15 : 0.08),
                              (game['color'] as Color).withOpacity(isDark ? 0.05 : 0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: (game['color'] as Color).withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [(game['color'] as Color), (game['color'] as Color).withOpacity(0.7)]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(game['icon'] as IconData, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    game['name'] as String,
                                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    game['desc'] as String,
                                    style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: ((game['soon'] as bool) ? Colors.grey : const Color(0xFF10B981)).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ((game['soon'] as bool) ? Colors.grey : const Color(0xFF10B981)).withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!(game['soon'] as bool)) const Icon(Icons.play_arrow_rounded, size: 14, color: Color(0xFF10B981)),
                                  if (!(game['soon'] as bool)) const SizedBox(width: 4),
                                  Text(
                                    (game['soon'] as bool) ? 'Coming Soon' : 'Play',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: (game['soon'] as bool) ? Colors.grey : const Color(0xFF10B981),
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
          color: const Color(0xFF10B981).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
            const SizedBox(width: 12),
            Text(
              'You\'re in! We\'ll notify you at launch.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF10B981),
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
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Be the First to Play',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Get early access and exclusive rewards',
            style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _emailController,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: Icon(Icons.email_outlined, color: isDark ? Colors.grey[400] : Colors.grey[600]),
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
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Join Waitlist',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
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
      
      paint.color = Colors.green.withOpacity(isDark ? 0.04 : 0.06);
      
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
      
      paint.color = (i % 2 == 0 ? Colors.green : Colors.amber).withOpacity(isDark ? 0.02 : 0.03);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant _LeafPatternPainter old) => old.animation != animation;
}
