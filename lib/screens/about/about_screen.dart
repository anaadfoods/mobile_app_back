import 'dart:math' as math;
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _contentController;
  late AnimationController _particleController;
  late Animation<double> _headerFade;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  Future<void> _launchURL(String url) async {
    _triggerHaptic();
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Could not open link');
      }
    }
  }

  Future<void> _launchEmail(String emailAddress) async {
    _triggerHaptic();
    String subject = '';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch $emailUri';
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Could not open email app.');
      }
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    _triggerHaptic();
    final String message = "";

    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $whatsappUri';
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Could not open WhatsApp.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Animated Header
              _buildAnimatedHeader(theme, colorScheme, size, statusBarHeight),
              const SizedBox(height: 24),
              // Content
              FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMissionCard(theme, colorScheme),
                        const SizedBox(height: 24),
                        _buildSectionTitle(theme, 'Our Values'),
                        const SizedBox(height: 12),
                        _buildValuesGrid(theme, colorScheme),
                        const SizedBox(height: 16),
                        _buildSectionTitle(theme, 'The Anaad Promise'),
                        const SizedBox(height: 16),
                        _buildBenefitsCard(theme, colorScheme),
                        const SizedBox(height: 32),
                        _buildContactSection(theme, colorScheme),
                        const SizedBox(height: 40),
                      ],
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

  Widget _buildAnimatedHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    Size size,
    double statusBarHeight,
  ) {
    return FadeTransition(
      opacity: _headerFade,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background with gradient and image
          SizedBox(
            height: size.height * 0.40 + statusBarHeight, // Increased height
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                CachedNetworkImage(
                  imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=1974',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withAlpha(180),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.parchment,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withAlpha(180),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.primary.withAlpha(200),
                        colorScheme.primary.withAlpha(240),
                      ],
                    ),
                  ),
                ),
                // Floating particles
                ..._buildFloatingParticles(),
                // ANAAD Logo
                Positioned(
                  top: statusBarHeight + 8,
                  left: 12,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.parchment),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
                // Logo and title
                Positioned(
                  top: statusBarHeight + 10, // Reduced top spacing
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // Logo container
                      AnimatedBuilder(
                        animation: _particleController,
                        builder: (context, child) {
                          final scale =
                              1.0 +
                              math.sin(
                                    _particleController.value * math.pi * 2,
                                  ) *
                                  0.03;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.parchment.withAlpha(30),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.parchment.withAlpha(50),
                                  width: 2,
                                ),
                              ),
                              child: Image.asset(
                                'assets/images/OnBoarding/logo.png',
                                height: 60,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Text(
                                    'A',
                                    style: TextStyle(
                                      fontSize: 40,
                                      color: AppColors.parchment,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ANAAD FOODS',
                        style: TextStyle(
                          color: AppColors.parchment,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ' Not a Brand. A Commitment',
                        style: TextStyle(
                          color: AppColors.parchment.withAlpha(200),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Curved bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingParticles() {
    final particles = [
      {'top': 30.0, 'left': 30.0, 'icon': Icons.eco_rounded, 'size': 22.0},
      {'top': 60.0, 'right': 40.0, 'icon': Icons.grass_rounded, 'size': 18.0},
      {
        'bottom': 80.0,
        'left': 50.0,
        'icon': Icons.local_florist_rounded,
        'size': 20.0,
      },
      {'bottom': 100.0, 'right': 60.0, 'icon': Icons.spa_rounded, 'size': 18.0},
    ];

    return particles.asMap().entries.map((entry) {
      final i = entry.key;
      final p = entry.value;

      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          final t = _particleController.value;
          final dx = math.cos(t * math.pi * 2 + i) * 8;
          final dy = math.sin(t * math.pi * 2 + i) * 10;
          final rotation = (t * math.pi * 2 + i) * 0.12;

          return Positioned(
            top: p['top'] != null ? (p['top'] as double) + dy : null,
            bottom: p['bottom'] != null ? (p['bottom'] as double) + dy : null,
            left: p['left'] != null ? (p['left'] as double) + dx : null,
            right: p['right'] != null ? (p['right'] as double) + dx : null,
            child: Transform.rotate(
              angle: rotation,
              child: Icon(
                p['icon'] as IconData,
                size: p['size'] as double,
                color: AppColors.parchment.withAlpha(35),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    final isDark = theme.brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
        color: isDark ? AppColors.parchment : AppColors.charcoal,
      ),
    );
  }

  Widget _buildMissionCard(ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;
    final bodyColor = isDark ? AppColors.parchment70 : AppColors.charcoal70;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? AppColors.deepSoilGreen.withValues(alpha: 0.15)
                : colorScheme.primary.withValues(alpha: 0.08),
            isDark
                ? AppColors.deepSoilGreen.withValues(alpha: 0.05)
                : colorScheme.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.deepSoilGreen.withValues(alpha: 0.3)
              : colorScheme.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.deepSoilGreen.withValues(alpha: 0.25)
                      : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  color: isDark ? AppColors.harvestAmber : colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Our Mission',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.parchment : AppColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'It began with a question we couldn\'t stop asking: why is a generation obsessed with healthy eating still getting sicker?',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: bodyColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We looked at our own dinner tables and noticed the disconnect. The food looked fresh, but the soil it came from had been stripped of life by decades of synthetic inputs. We were eating chemistry, not nutrients.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: bodyColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We couldn\'t find a source we trusted — so we built the farm we needed. We returned to Indigenous Cow-Based Natural (ICBN) farming not to build a business, but to answer a question honestly: could we feed this food to our own families?',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: bodyColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'When the land breathes and the farmer thrives, your health is the inevitable harvest. ANAAD is us sharing that with you.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: bodyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValuesGrid(ThemeData theme, ColorScheme colorScheme) {
    final values = [
      {
        'icon': Icons.eco_rounded,
        'title': 'Radical Purity',
        'subtitle': "If nature didn't make it, we don't sell it",
        'color': AppColors.deepSoilGreen,
      },
      {
        'icon': Icons.agriculture_rounded,
        'title': 'Zero Distance',
        'subtitle': 'No warehouse. No middlemen. Field to your kitchen.',
        'color': AppColors.harvestAmber,
      },
      {
        'icon': Icons.favorite_rounded,
        'title': 'Nutrient-Rich',
        'subtitle': 'Grown in living soil. Milled cold. Nothing removed.',
        'color': AppColors.rawEarth,
      },
      {
        'icon': Icons.verified_rounded,
        'title': 'Uncompromising Quality',
        'subtitle': 'Every batch tested by SGS before it leaves the farm.',
        'color': AppColors.deepSoilGreen,
      },
    ];

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildValueCard(
                  theme: theme,
                  icon: values[0]['icon'] as IconData,
                  title: values[0]['title'] as String,
                  subtitle: values[0]['subtitle'] as String,
                  color: values[0]['color'] as Color,
                  delay: 0,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildValueCard(
                  theme: theme,
                  icon: values[1]['icon'] as IconData,
                  title: values[1]['title'] as String,
                  subtitle: values[1]['subtitle'] as String,
                  color: values[1]['color'] as Color,
                  delay: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildValueCard(
                  theme: theme,
                  icon: values[2]['icon'] as IconData,
                  title: values[2]['title'] as String,
                  subtitle: values[2]['subtitle'] as String,
                  color: values[2]['color'] as Color,
                  delay: 2,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildValueCard(
                  theme: theme,
                  icon: values[3]['icon'] as IconData,
                  title: values[3]['title'] as String,
                  subtitle: values[3]['subtitle'] as String,
                  color: values[3]['color'] as Color,
                  delay: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValueCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int delay,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (delay * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppColors.parchment.withValues(alpha: 0.08)
                : AppColors.charcoal12,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.transparent
                  : color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? color.withValues(alpha: 0.15)
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.parchment : AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.parchment70 : AppColors.charcoal70,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsCard(ThemeData theme, ColorScheme colorScheme) {
    final benefits = [
      'Harvested Fresh, Never Stored',
      'Zero Tolerance for Chemicals',
      'Fair Returns for Farmers',
      'Earth-Friendly Packaging',
      'Every Batch Tested for Purity',
    ];

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.parchment.withValues(alpha: 0.08)
              : AppColors.charcoal12,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.transparent
                : colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children:
            benefits.asMap().entries.map((entry) {
              final index = entry.key;
              final benefit = entry.value;
              return _BenefitItem(
                text: benefit,
                isLast: index == benefits.length - 1,
                delay: index,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildContactSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'Join the Conversation',
            style: TextStyle(
              color: AppColors.parchment,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Speak directly with the people growing your food.",
            style: TextStyle(
              color: AppColors.parchment.withValues(alpha: 0.75),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          // Social icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                icon: FontAwesomeIcons.facebookF,
                onTap: () => _launchURL('https://www.facebook.com/anaadfoods1'),
              ),
              const SizedBox(width: 16),
              _buildSocialButton(
                icon: FontAwesomeIcons.instagram,
                onTap: () => _launchURL('https://www.instagram.com/anaadfoods'),
              ),
              const SizedBox(width: 16),
              _buildSocialButton(
                icon: FontAwesomeIcons.linkedinIn,
                onTap:
                    () => _launchURL(
                      'https://www.linkedin.com/company/anaad-anhad-naad-foods/',
                    ),
              ),
              const SizedBox(width: 16),
              _buildSocialButton(
                icon: FontAwesomeIcons.xTwitter,
                onTap: () => _launchURL('https://x.com/AnaadFoods'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Contact info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.parchment.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _launchEmail('connect@anaadfoods.com'),
                  child: _buildContactRow(
                    Icons.email_outlined,
                    'connect@anaadfoods.com',
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _launchWhatsApp('+91 9996166186'),
                  child: _buildContactRow(
                    Icons.phone_outlined,
                    '+91 9996166186',
                  ),
                ),
                const SizedBox(height: 12),
                _buildContactRow(
                  Icons.location_on_outlined,
                  'Anaad, Farmlands of Bhuri, Sonipat, Haryana 131001',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '© 2025 Anaad Foods. All rights reserved.',
            style: TextStyle(
              color: AppColors.parchment.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.parchment.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.parchment, size: 18),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.parchment.withValues(alpha: 0.8), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.parchment.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// Benefit Item Widget
class _BenefitItem extends StatelessWidget {
  final String text;
  final bool isLast;
  final int delay;

  const _BenefitItem({
    required this.text,
    this.isLast = false,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (delay * 80)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.harvestAmber, AppColors.harvestAmber]
                      : [AppColors.deepSoilGreen, AppColors.deepSoilGreen],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.parchment,
                size: 14,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: isDark ? AppColors.parchment70 : AppColors.charcoal70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
