import 'package:grocery_app/common_widgets/global_import.dart';

class AnaadRobotsScreen extends StatefulWidget {
  const AnaadRobotsScreen({super.key});

  @override
  State<AnaadRobotsScreen> createState() => _AnaadRobotsScreenState();
}

class _AnaadRobotsScreenState extends State<AnaadRobotsScreen>
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
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
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
          // Background gradient
          _buildBackground(isDark),

          // Floating particles
          _buildFloatingParticles(),

          // Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverSafeArea(
                top: true,
                bottom: false,
                sliver: _buildAppBar(context, theme, isDark),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.paddingOf(context).bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Hero Icon with pulse
                      _buildHeroIcon(),
                      const SizedBox(height: 24),

                      // Coming Soon Badge
                      _buildComingSoonBadge(theme),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Anaad Robots',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isDark
                                  ? AppColors.parchment
                                  : AppColors.charcoal87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        'The Future of Farming is Here',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.parchment,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Article Card
                      _buildArticleCard(theme, isDark),
                      const SizedBox(height: 24),

                      // Features List
                      _buildFeaturesSection(theme, isDark),
                      const SizedBox(height: 32),

                      // Notify Form
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
              top: 120 + (_floatAnimation.value * 15),
              right: 40,
              child: _particle(10, AppColors.parchment),
            ),
            Positioned(
              top: 250 + (_floatAnimation.value * -12),
              left: 30,
              child: _particle(7, AppColors.parchment),
            ),
            Positioned(
              bottom: 300 + (_floatAnimation.value * 10),
              right: 60,
              child: _particle(6, AppColors.parchment),
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
              Icons.smart_toy_rounded,
              color: AppColors.parchment,
              size: 60,
            ),
          ),
        );
      },
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
          const Icon(
            Icons.rocket_launch_rounded,
            color: AppColors.parchment,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Coming Soon',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.parchment,
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
                'About Anaad Robots',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Revolutionizing Farming with AI-Powered Robots',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.parchment,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Anaad is developing intelligent farming robots that work alongside farmers to increase productivity while maintaining sustainable practices.\n\n'
            'These robots will help with:\n'
            '• Soil analysis and health monitoring\n'
            '• Precise irrigation based on crop needs\n'
            '• Eco-friendly pest management\n'
            '• Harvest optimization\n\n'
            'Our vision is to bring the future of farming to your fields - making agriculture smarter, more efficient, and environmentally conscious.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.7,
              color: isDark ? AppColors.rawEarth12 : AppColors.charcoal60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(ThemeData theme, bool isDark) {
    final features = [
      {
        'icon': Icons.memory_rounded,
        'title': 'AI-Powered',
        'desc': 'Smart decision making',
      },
      {
        'icon': Icons.eco_rounded,
        'title': 'Eco-Friendly',
        'desc': 'Sustainable practices',
      },
      {
        'icon': Icons.speed_rounded,
        'title': 'Efficient',
        'desc': '24/7 operation',
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          features.map((f) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.parchment.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    f['icon'] as IconData,
                    color: AppColors.parchment,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  f['title'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  f['desc'] as String,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? AppColors.rawEarth26 : AppColors.rawEarth70,
                  ),
                ),
              ],
            );
          }).toList(),
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
              'You\'re on the list! We\'ll notify you.',
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
            'Get Notified at Launch',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
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
                  'Notify Me',
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
