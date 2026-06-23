import 'dart:ui';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/common_widgets/otp_resend_section.dart';
import 'package:pinput/pinput.dart';

class CombinedScreen extends StatefulWidget {
  const CombinedScreen({super.key});

  @override
  State<CombinedScreen> createState() => _CombinedScreenState();
}

class _CombinedScreenState extends State<CombinedScreen>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _floatController;
  late ScrollController _scrollController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    _scrollController =
        ScrollController()..addListener(() {
          setState(() => _scrollOffset = _scrollController.offset);
        });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _floatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerHaptic() => HapticFeedback.lightImpact();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAnimatedAppBar(theme, isDark),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeroSection(theme, isDark),
                const SizedBox(height: 24),
                _buildFeatureCards(theme, isDark),
                const SizedBox(height: 32),
                _buildBenefitsSection(theme, isDark),
                const SizedBox(height: 32),
                _buildContractFarmingSection(theme, isDark),
                const SizedBox(height: 32),
                _buildTimelineSection(theme, isDark),
                const SizedBox(height: 32),
                _buildCTAButton(context, theme),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedAppBar(ThemeData theme, bool isDark) {
    final collapse = (_scrollOffset / 200).clamp(0.0, 1.0);

    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.maybePop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image with parallax
            Transform.translate(
              offset: Offset(0, _scrollOffset * 0.3),
              child: CachedNetworkImage(
                imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=1974&auto=format&fit=crop',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDark ? AppColors.charcoal : AppColors.parchment,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDark ? AppColors.charcoal : AppColors.parchment,
                  child: Icon(
                    Icons.image_not_supported,
                    color: theme.disabledColor,
                    size: 40,
                  ),
                ),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.charcoal.withValues(alpha: 0.1),
                    AppColors.transparent,
                    AppColors.charcoal.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            // Floating particles
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, _) {
                return Stack(
                  children: [
                    Positioned(
                      top: 60 + (_floatController.value * 10),
                      right: 30,
                      child: _buildParticle(8, AppColors.parchment),
                    ),
                    Positioned(
                      top: 150 + (_floatController.value * -8),
                      left: 40,
                      child: _buildParticle(6, AppColors.parchment),
                    ),
                    Positioned(
                      bottom: 80 + (_floatController.value * 12),
                      right: 60,
                      child: _buildParticle(5, AppColors.parchment),
                    ),
                  ],
                );
              },
            ),
            // Title content
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.deepSoilGreen,
                          AppColors.deepSoilGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.eco_rounded,
                          color: AppColors.parchment,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '100% Natural',
                          style: TextStyle(
                            color: AppColors.parchment,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ' Remote Farming Program',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.parchment,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Certified toxin-free ICBN agriculture with complete traceability',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.parchment.withValues(alpha: 0.9),
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

  Widget _buildParticle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.6),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
        ],
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme, bool isDark) {
    final accentColor = isDark ? AppColors.parchment : AppColors.deepSoilGreen;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.spa_rounded,
                        color: accentColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The Purity Standard',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Beyond organic - a toxin-free guarantee',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  isDark
                                      ? AppColors.parchment70
                                      : AppColors.rawEarth70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "We strictly adhere to natural(ICBN) farming protocols. This means no synthetic chemicals, toxins or pesticides and zero shortcuts. We grow crops that not only meet the highest Safety Standards but also redefine the Nutritional Standards. Here, you don't just buy produce; rather commit to the harvest",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.parchment70 : AppColors.charcoal60,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCards(ThemeData theme, bool isDark) {
    final features = [
      {
        'icon': Icons.home_work_outlined,
        'title': 'Your Mini Farm',
        'desc':
            'Land allocated exclusively to grow your/your family’s seasonal vegetable requirements',
        'color': AppColors.deepSoilGreen,
        'image':
            'https://images.unsplash.com/photo-1563203432-345337a36416?q=80&w=1964&auto=format&fit=crop',
      },
      {
        'icon': Icons.person_pin_rounded,
        'title': 'Your Farm Manager',
        'desc':
            'Expert agronomists overseeing the entire crop lifecycle for you',
        'color': AppColors.harvestAmber,
        'image':
            'https://images.unsplash.com/photo-1599599810694-b5b37304c847?q=80&w=2070&auto=format&fit=crop',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children:
            features.asMap().entries.map((entry) {
              final index = entry.key;
              final feature = entry.value;
              return Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 600 + (index * 150)),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    final clampedValue = value.clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: clampedValue,
                        child: Container(
                          height: 200,
                          margin: EdgeInsets.only(
                            right: index == 0 ? 8 : 0,
                            left: index == 1 ? 8 : 0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: NetworkImage(feature['image'] as String),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (feature['color'] as Color).withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.transparent,
                                  AppColors.charcoal.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (feature['color'] as Color)
                                        .withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    feature['icon'] as IconData,
                                    color: AppColors.parchment,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  feature['title'] as String,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.parchment,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  feature['desc'] as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.parchment.withValues(
                                      alpha: 0.8,
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
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildBenefitsSection(ThemeData theme, bool isDark) {
    final benefits = [
      {
        'icon': Icons.agriculture_outlined,
        'title': 'Free Farm Visits',
        'desc': 'Connect with the land',
      },
      {
        'icon': Icons.camera_alt_outlined,
        'title': 'Real-Time Updates',
        'desc': 'Photo & video of crops',
      },
      {
        'icon': Icons.access_time,
        'title': 'Early Access',
        'desc': 'First to try new products',
      },
      {
        'icon': Icons.verified_outlined,
        'title': 'Quality Promise',
        'desc': '100% toxin-free guarantee',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Benefits',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: benefits.length,
            itemBuilder: (context, index) {
              final benefit = benefits[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.parchment,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.parchment.withValues(alpha: 0.08)
                        : AppColors.parchment.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.charcoal.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 112,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.parchment : AppColors.deepSoilGreen).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            benefit['icon'] as IconData,
                            color: isDark ? AppColors.parchment : AppColors.deepSoilGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          benefit['title'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          benefit['desc'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                isDark
                                    ? AppColors.parchment70
                                    : AppColors.rawEarth70,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContractFarmingSection(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [
                      AppColors.darkSurfaceElevated,
                      AppColors.darkSurface,
                    ]
                    : [AppColors.pureWhite, AppColors.pureWhite],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.charcoal.withValues(alpha: isDark ? 0.3 : 0.1),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.deepSoilGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.handshake_outlined,
                    color: AppColors.parchment,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enterprise Farming Partnership',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'A transparent, predictable supply chain for your business',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              isDark
                                  ? AppColors.parchment70
                                  : AppColors.rawEarth70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Absolute transparency from seed to supply chain. We dedicate land and resources to fulfill your exact requirements.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 24),
            _buildAdvantageItem(
              theme,
              isDark,
              'Seed-to-Scale Visibility',
              'Eliminate the "black box" of sourcing. Gain total visibility over your dedicated yield, from the sowing of Heirloom seeds to final logistics, ensuring your production lines never stop.',
            ),
            _buildAdvantageItem(
              theme,
              isDark,
              'Standardized Purity',
              'Guarantee consistent nutritional density for your customers. We adhere to strict Toxin-Free ICBN Farming protocols certified by the Government of INDIA, protecting your brand from the liabilities of modern chemical farming.',
            ),
            _buildAdvantageItem(
              theme,
              isDark,
              'Ethical Compliance',
              ' Turn your supply chain into a corporate asset. Partnering with ANAAD directly validates your commitment to Environmental Health and Farmer Economic Welfare, providing a verifiable impact story for your stakeholders',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvantageItem(ThemeData theme, bool isDark, String title, String desc) {
    final iconColor = isDark ? AppColors.parchment : AppColors.deepSoilGreen;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: iconColor,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  desc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.parchment70 : AppColors.rawEarth70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(ThemeData theme, bool isDark) {
    final steps = [
      {'icon': Icons.chat_bubble_outline, 'label': 'Consultation'},
      {'icon': Icons.agriculture_outlined, 'label': 'Cultivation'},
      {'icon': Icons.location_searching, 'label': 'Monitoring'},
      {'icon': Icons.inventory_2_outlined, 'label': 'Fulfillment'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Our Process',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      AppColors.darkSurfaceElevated,
                                      AppColors.darkSurfaceElevated,
                                    ]
                                  : [
                                      AppColors.deepSoilGreen,
                                      AppColors.deepSoilGreen,
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark
                                        ? AppColors.pureBlack
                                        : AppColors.deepSoilGreen)
                                    .withValues(
                                  alpha: isDark ? 0.2 : 0.3,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            step['icon'] as IconData,
                            color: AppColors.parchment,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          step['label'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCTAButton(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          _triggerHaptic();
          _showNotificationForm(context);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.parchment, AppColors.parchment]
                  : [AppColors.deepSoilGreen, AppColors.deepSoilGreen],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.parchment : AppColors.deepSoilGreen)
                    .withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.eco_rounded,
                color: isDark ? AppColors.deepSoilGreen : AppColors.parchment,
              ),
              const SizedBox(width: 12),
              Text(
                'Register Your Interest',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark ? AppColors.deepSoilGreen : AppColors.parchment,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showNotificationForm(BuildContext outerContext) async {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: outerContext,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (context) => const _RfpFormSheet(),
  );
}

class _RfpFormSheet extends StatefulWidget {
  const _RfpFormSheet();

  @override
  State<_RfpFormSheet> createState() => _RfpFormSheetState();
}

class _RfpFormSheetState extends State<_RfpFormSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'INDIVIDUAL';
  bool _isLoading = false;

  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  bool _isSendingEmailOtp = false;
  bool _isSendingPhoneOtp = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEmailVerified && !_isPhoneVerified) {
      SnackBarHelper.showError(
        context,
        "Please verify either your email or phone number.",
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.instance.post(
        '/api/user-queries/',
        data: {
          'name': _nameController.text,
          'phone_number': _phoneController.text,
          'email': _emailController.text,
          'message': _messageController.text,
          'requirement_type': _selectedType,
          'is_from_rfp': true,
          'redirection_from': 'RFP',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        SnackBarHelper.showSuccess(
          context,
          'Thank you! We\'ll get back to you soon.',
        );
      } else {
        throw Exception('Failed to submit');
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to submit. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp(String type, String value) async {
    if (value.trim().isEmpty) {
      SnackBarHelper.showError(context, 'Please enter $type first.');
      return;
    }
    
    if (type == 'phone' && !RegExp(r'^\d{10}$').hasMatch(value.trim())) {
      SnackBarHelper.showError(context, 'Enter a valid 10-digit phone number.');
      return;
    }
    if (type == 'email' && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      SnackBarHelper.showError(context, 'Enter a valid email.');
      return;
    }

    setState(() {
      if (type == 'email') _isSendingEmailOtp = true;
      else _isSendingPhoneOtp = true;
    });

    try {
      await context.read<AuthRepository>().sendOtp(value.trim(), type.toUpperCase());
      if (!mounted) return;
      _showOtpDialog(
        type: type,
        value: value.trim(),
        onVerified: () {
          setState(() {
            if (type == 'email') _isEmailVerified = true;
            else _isPhoneVerified = true;
          });
        },
      );
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) {
        setState(() {
          if (type == 'email') _isSendingEmailOtp = false;
          else _isSendingPhoneOtp = false;
        });
      }
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
                                            } catch (e) {
                                              setDialogState(
                                                () => dialogError = e.toString().replaceAll('Exception:', '').trim(),
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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.agriculture_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Register Your Interest',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Join our natural farming program',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.16),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Only one verification is required: mobile number or email address.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Form fields
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name*',
                  icon: Icons.person_outline_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your name';
                    if (v.trim().length < 3) return 'Name must be at least 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number*',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) {
                    if (_isPhoneVerified) {
                      setState(() => _isPhoneVerified = false);
                    }
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your phone number';
                    if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) return 'Phone number must be exactly 10 digits';
                    return null;
                  },
                  suffix: _isPhoneVerified
                      ? const Icon(Icons.check_circle, color: AppColors.deepSoilGreen)
                      : TextButton(
                          onPressed: _isSendingPhoneOtp
                              ? null
                              : () => _sendOtp('phone', _phoneController.text),
                          child: _isSendingPhoneOtp
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Verify'),
                        ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email*',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_isEmailVerified) {
                      setState(() => _isEmailVerified = false);
                    }
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) return 'Please enter a valid email';
                    return null;
                  },
                  suffix: _isEmailVerified
                      ? const Icon(Icons.check_circle, color: AppColors.deepSoilGreen)
                      : TextButton(
                          onPressed: _isSendingEmailOtp
                              ? null
                              : () => _sendOtp('email', _emailController.text),
                          child: _isSendingEmailOtp
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Verify'),
                        ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _messageController,
                  label: 'Your Message*',
                  icon: Icons.message_outlined,
                  maxLines: 3,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your message';
                    if (v.trim().length < 10) return 'Message must be at least 10 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Requirement type selector
                _buildTypeSelector(theme, colorScheme),
                const SizedBox(height: 28),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: AppColors.parchment,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.parchment,
                                strokeWidth: 2.5,
                              ),
                            )
                            : const Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? suffix,
    Function(String)? onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary, size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: colorScheme.primary.withAlpha(8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary.withAlpha(40)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary.withAlpha(30)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.rawEarth),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requirement Type',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTypeChip(
                theme,
                colorScheme,
                'INDIVIDUAL',
                'Individual',
                Icons.person_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeChip(
                theme,
                colorScheme,
                'B2B',
                'Business',
                Icons.business_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeChip(
                theme,
                colorScheme,
                'FAMILY',
                'Family',
                Icons.family_restroom_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(
    ThemeData theme,
    ColorScheme colorScheme,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedType == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedType = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? colorScheme.primary
                  : colorScheme.primary.withAlpha(10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected
                    ? colorScheme.primary
                    : colorScheme.primary.withAlpha(40),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.parchment : colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.parchment : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
