import 'dart:ui';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:http/http.dart' as http;

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
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FE),
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
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      leading: GestureDetector(
        onTap: () {
          _triggerHaptic();
          context.pop();
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image with parallax
            Transform.translate(
              offset: Offset(0, _scrollOffset * 0.3),
              child: Image.network(
                'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=1974&auto=format&fit=crop',
                fit: BoxFit.cover,
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                    Colors.black.withOpacity(0.9),
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
                      child: _buildParticle(8, const Color(0xFF4CAF50)),
                    ),
                    Positioned(
                      top: 150 + (_floatController.value * -8),
                      left: 40,
                      child: _buildParticle(6, Colors.white),
                    ),
                    Positioned(
                      bottom: 80 + (_floatController.value * 12),
                      right: 60,
                      child: _buildParticle(5, const Color(0xFF4CAF50)),
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
                        colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '100% Natural',
                          style: TextStyle(
                            color: Colors.white,
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Certified toxin-free ICBN agriculture with complete traceability',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
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
        color: color.withOpacity(0.6),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)],
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : const Color(0xFF4CAF50))
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
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
                        color: const Color(0xFF4CAF50).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.spa_rounded,
                        color: Color(0xFF4CAF50),
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
                                  isDark ? Colors.grey[400] : Colors.grey[600],
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
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
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
        'color': const Color(0xFF4CAF50),
        'image':
            'https://images.unsplash.com/photo-1563203432-345337a36416?q=80&w=1964&auto=format&fit=crop',
      },
      {
        'icon': Icons.person_pin_rounded,
        'title': 'Your Farm Manager',
        'desc':
            'Expert agronomists overseeing the entire crop lifecycle for you',
        'color': const Color(0xFF2196F3),
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
                                color: (feature['color'] as Color).withOpacity(
                                  0.3,
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
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.8),
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
                                        .withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    feature['icon'] as IconData,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  feature['title'] as String,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  feature['desc'] as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
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
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                            color: const Color(0xFF4CAF50).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            benefit['icon'] as IconData,
                            color: const Color(0xFF4CAF50),
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
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                    ? [const Color(0xFF1E3A2F), const Color(0xFF0F1F1A)]
                    : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
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
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.handshake_outlined,
                    color: Colors.white,
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
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
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
              'Seed-to-Scale Visibility',
              'Eliminate the "black box" of sourcing. Gain total visibility over your dedicated yield, from the sowing of Heirloom seeds to final logistics, ensuring your production lines never stop.',
            ),
            _buildAdvantageItem(
              theme,
              'Standardized Purity',
              'Guarantee consistent nutritional density for your customers. We adhere to strict Toxin-Free ICBN Farming protocols certified by the Government of INDIA, protecting your brand from the liabilities of modern chemical farming.',
            ),
            _buildAdvantageItem(
              theme,
              'Ethical Compliance',
              ' Turn your supply chain into a corporate asset. Partnering with ANAAD directly validates your commitment to Environmental Health and Farmer Economic Welfare, providing a verifiable impact story for your stakeholders',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvantageItem(ThemeData theme, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF4CAF50), size: 14),
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
                    color: Colors.grey[600],
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
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            step['icon'] as IconData,
                            color: Colors.white,
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
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Register Your Interest',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
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
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final messageController = TextEditingController();
  final theme = Theme.of(outerContext);
  final isDark = theme.brightness == Brightness.dark;
  String selectedRequirementType = 'INDIVIDUAL';

  await showGeneralDialog(
    context: outerContext,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.6),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: FadeTransition(
          opacity: animation,
          child: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors:
                                  isDark
                                      ? [
                                        const Color(0xFF1E3A2F),
                                        const Color(0xFF0F1F1A),
                                      ]
                                      : [
                                        Colors.white,
                                        const Color(
                                          0xFF4CAF50,
                                        ).withOpacity(0.1),
                                      ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.colorScheme.primary,
                                            theme.colorScheme.primary
                                                .withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.agriculture_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Register Your Interest',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Join our natural farming program',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 24),
                                    _buildFormField(
                                      nameController,
                                      'Full Name *',
                                      Icons.person_outline,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFormField(
                                      phoneController,
                                      'Phone Number *',
                                      Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFormField(
                                      emailController,
                                      'Email (Optional)',
                                      Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFormField(
                                      messageController,
                                      'Message *',
                                      Icons.message_outlined,
                                      maxLines: 3,
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF4CAF50,
                                        ).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF4CAF50,
                                          ).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: DropdownButtonFormField<String>(
                                        value: selectedRequirementType,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          labelText: 'Requirement Type',
                                        ),
                                        items:
                                            ['INDIVIDUAL', "B2B", 'FAMILY'].map(
                                              (value) {
                                                return DropdownMenuItem(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              },
                                            ).toList(),
                                        onChanged:
                                            (value) => setDialogState(
                                              () =>
                                                  selectedRequirementType =
                                                      value!,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    GestureDetector(
                                      onTap: () async {
                                        if (formKey.currentState!.validate()) {
                                          try {
                                            final response = await http.post(
                                              Uri.parse(
                                                '${ApiConfig.baseUrl}/api/user-queries/',
                                              ),
                                              headers: {
                                                'Content-Type':
                                                    'application/json',
                                              },
                                              body: jsonEncode({
                                                'name': nameController.text,
                                                'phone_number':
                                                    phoneController.text,
                                                'email': emailController.text,
                                                'message':
                                                    messageController.text,
                                                'requirement_type':
                                                    selectedRequirementType,
                                                'is_from_rfp': true,
                                                'redirection_from': 'RFP',
                                              }),
                                            );
                                            if (!dialogContext.mounted) return;
                                            Navigator.of(dialogContext).pop();
                                            if (!outerContext.mounted) return;
                                            if (response.statusCode == 200 ||
                                                response.statusCode == 201) {
                                              SnackBarHelper.showSuccess(
                                                outerContext,
                                                'Thank you! We\'ll get back to you soon.',
                                              );
                                            } else {
                                              SnackBarHelper.showError(
                                                outerContext,
                                                'Failed. Please try again.',
                                              );
                                            }
                                          } catch (e) {
                                            if (!dialogContext.mounted) return;
                                            Navigator.of(dialogContext).pop();
                                            if (!outerContext.mounted) return;
                                            SnackBarHelper.showError(
                                              outerContext,
                                              'Error. Please try again.',
                                            );
                                          }
                                        }
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              theme.colorScheme.primary,
                                              theme.colorScheme.primary
                                                  .withOpacity(0.8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Submit',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
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
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

Widget _buildFormField(
  TextEditingController controller,
  String hint,
  IconData icon, {
  TextInputType? keyboardType,
  int maxLines = 1,
}) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF4CAF50).withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFF4CAF50).withOpacity(0.3),
        width: 1,
      ),
    ),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50).withOpacity(0.7)),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator:
          hint.contains('*')
              ? (v) => v?.isEmpty == true ? 'Required' : null
              : null,
    ),
  );
}
