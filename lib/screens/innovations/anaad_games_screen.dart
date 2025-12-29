import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

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
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          _buildBackground(isDark),
          _buildFloatingParticles(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, theme, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeroIcon(),
                      const SizedBox(height: 24),
                      _buildComingSoonBadge(theme),
                      const SizedBox(height: 20),
                      Text(
                        'Anaad Games',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Play. Learn. Grow Sustainably.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      _buildArticleCard(theme, isDark),
                      const SizedBox(height: 24),
                      _buildGameConcepts(theme, isDark),
                      const SizedBox(height: 32),
                      _buildNotifyForm(theme, isDark),
                      const SizedBox(height: 40),
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
            'Coming Soon',
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF3B82F6),
              fontWeight: FontWeight.w700,
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

  Widget _buildGameConcepts(ThemeData theme, bool isDark) {
    final games = [
      {'icon': Icons.grass_rounded, 'name': 'Farm Tycoon', 'desc': 'Build your organic empire'},
      {'icon': Icons.water_drop_rounded, 'name': 'Aqua Quest', 'desc': 'Save water, save crops'},
      {'icon': Icons.bug_report_rounded, 'name': 'Bug Busters', 'desc': 'Natural pest control'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Games',
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
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(game['icon'] as IconData, color: const Color(0xFF3B82F6), size: 24),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Soon', style: TextStyle(fontSize: 11, color: const Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                          ),
                        ],
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
