import 'package:grocery_app/features/auth/domain/repositories/auth_repository.dart' as domain;
import 'dart:ui';
import 'dart:math' as math;
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/common_widgets/otp_resend_section.dart';
import 'package:pinput/pinput.dart';

class HelpScreen extends StatefulWidget {
  final String? orderNumber;

  const HelpScreen({super.key, this.orderNumber});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with TickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 4000),
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

  Future<void> _launchPhoneCall(String phoneNumber) async {
    _triggerHaptic();
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch $phoneUri';
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Could not open phone dialer.');
      }
    }
  }

  Future<void> _launchEmail(String emailAddress) async {
    _triggerHaptic();
    String subject =
        widget.orderNumber != null
            ? 'Support Request for Order #${widget.orderNumber}'
            : 'Support Request';

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
    final String message =
        widget.orderNumber != null
            ? 'Hello, I need help with my order #${widget.orderNumber}.'
            : 'Hello, I need help.';

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

  void _showQueryForm() {
    _triggerHaptic();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => _QueryFormSheet(orderNumber: widget.orderNumber),
    );
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
                        _buildSectionTitle(theme, 'Quick Connect'),
                        const SizedBox(height: 16),
                        _buildContactCards(theme, colorScheme),
                        const SizedBox(height: 32),
                        _buildSectionTitle(theme, 'Frequently Asked'),
                        const SizedBox(height: 16),
                        _buildFaqSection(theme, colorScheme),
                        const SizedBox(height: 32),
                        _buildQueryCard(theme, colorScheme),
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
    final double appBarHeight = (statusBarHeight + 180).clamp(
      220.0,
      math.max(220.0, size.height * 0.32).toDouble(),
    );

    return FadeTransition(
      opacity: _headerFade,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Gradient background
          Container(
            height: appBarHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withAlpha(220),
                  colorScheme.primary.withAlpha(180),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Floating particles
                ..._buildFloatingParticles(),
                // Back button
                Positioned(
                  top: statusBarHeight + 8,
                  left: 12,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.parchment,
                    ),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
                // Header Content (Title + Icon)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 40, // Keeps it nicely above the curved bottom (height 30)
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                'The Community Desk',
                                style: TextStyle(
                                  color: AppColors.parchment,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Questions about your food? Speak to us',
                                style: TextStyle(
                                  color: AppColors.parchment.withAlpha(200),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      AnimatedBuilder(
                        animation: _particleController,
                        builder: (context, child) {
                          final scale =
                              1.0 +
                              math.sin(_particleController.value * math.pi * 2) *
                                  0.08;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.parchment.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.support_agent_rounded,
                                color: AppColors.parchment,
                                size: 32,
                              ),
                            ),
                          );
                        },
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
      {'top': 20.0, 'left': 50.0, 'icon': Icons.eco_rounded, 'size': 24.0},
      {'top': 80.0, 'right': 80.0, 'icon': Icons.grass_rounded, 'size': 20.0},
      {
        'bottom': 60.0,
        'left': 30.0,
        'icon': Icons.local_florist_rounded,
        'size': 22.0,
      },
    ];

    return particles.asMap().entries.map((entry) {
      final i = entry.key;
      final p = entry.value;

      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          final t = _particleController.value;
          final dx = math.cos(t * math.pi * 2 + i) * 6;
          final dy = math.sin(t * math.pi * 2 + i) * 8;
          final rotation = (t * math.pi * 2 + i) * 0.15;

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
                color: AppColors.parchment.withAlpha(40),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildContactCards(ThemeData theme, ColorScheme colorScheme) {
    final contacts = [
      {
        'icon': Icons.email_rounded,
        'title': 'Write to Us',
        'subtitle': 'wait for 48 hours',
        'color': AppColors.deepSoilGreen,
        'gradient': [AppColors.deepSoilGreen, AppColors.deepSoilGreen],
        'onTap': () => _launchEmail('complaints@anaadfoods.com'),
      },
      {
        'icon': Icons.chat_rounded,
        'title': 'Chat Live',
        'subtitle': 'within 24 hours',
        'color': AppColors.deepSoilGreen,
        'gradient': [AppColors.deepSoilGreen, AppColors.deepSoilGreen],
        'onTap': () => _launchWhatsApp('919996166186'),
      },
      {
        'icon': Icons.phone_rounded,
        'title': 'Speak to Us',
        'subtitle': 'Real voices',
        'color': AppColors.harvestAmber,
        'gradient': [AppColors.harvestAmber, AppColors.harvestAmber],
        'onTap': () => _launchPhoneCall('9996166186'),
      },
    ];

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: contacts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return _buildContactCard(
            theme: theme,
            icon: contact['icon'] as IconData,
            title: contact['title'] as String,
            subtitle: contact['subtitle'] as String,
            gradient: contact['gradient'] as List<Color>,
            onTap: contact['onTap'] as VoidCallback,
            delay: index,
          );
        },
      ),
    );
  }

  Widget _buildContactCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (delay * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withAlpha(80),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.parchment.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.parchment, size: 22),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.parchment,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.parchment.withAlpha(200),
                  fontSize: 11,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqSection(ThemeData theme, ColorScheme colorScheme) {
    final faqs = [
      {
        'icon': Icons.eco_rounded,
        'title': 'What is ICBN?',
        'content':
            'ICBN stands for Indigenous Cow Based Natural farming. It is a farming approach rooted in natural inputs, living soil, and traditional agricultural knowledge, designed to grow food in a way that supports both human health and ecological balance.',
      },
      {
        'icon': Icons.agriculture_rounded,
        'title': 'Why does ANAAD follow ICBN farming?',
        'content':
            'We follow ICBN farming because we believe food should begin with living soil, not chemical dependence. This approach allows us to grow staples with greater care for the land, the farmer, and the families who eat our food.',
      },
      {
        'icon': Icons.subscriptions_rounded,
        'title': 'Why are ANAAD products offered through subscriptions?',
        'content':
            'Subscriptions allow us to grow with clarity and responsibility. They help us plan before sowing, share risk with committed households, and deliver food in a way that stays closer to the field and farther from speculation.',
      },
      {
        'icon': Icons.handshake_rounded,
        'title': 'What does risk sharing mean in your model?',
        'content':
            'Risk sharing means that instead of placing the full uncertainty on the farmer, the household commits in advance and helps anchor the season. This gives us the confidence to plan better, grow more responsibly, and reduce waste across the food system.',
      },
      {
        'icon': Icons.verified_rounded,
        'title': 'How do ANAAD Commitment Plans work?',
        'content':
            'When you choose a Commitment Plan, a portion of our harvest is reserved for your household. Your food is then handled in a planned cycle of harvesting, processing, packaging, and dispatch, so every batch remains connected to a clear origin and a defined purpose.',
      },
      {
        'icon': Icons.track_changes_rounded,
        'title': 'Why is traceability important?',
        'content':
            'Traceability is what makes trust visible. It allows you to see where your food came from, how it was grown, and how it moved through each stage before reaching your kitchen.',
      },
      {
        'icon': Icons.visibility_rounded,
        'title': 'How does ANAAD ensure transparency?',
        'content':
            'We share batch-level information, farm records, and process details so the journey of the food is not hidden from the household. Transparency, for us, is not a marketing claim — it is part of the product.',
      },
      {
        'icon': Icons.health_and_safety_rounded,
        'title': 'Why does ANAAD avoid chemicals in farming?',
        'content':
            'We avoid chemicals because they may increase yield, but they often come at the cost of soil health, ecological stability, and long-term food quality. Our work is built on the belief that clean food must also come from clean growing practices.',
      },
      {
        'icon': Icons.grass_rounded,
        'title': 'Why are desi seeds important?',
        'content':
            'Desi seeds are important because they are part of a living food heritage that is better adapted to local conditions. They help preserve biodiversity, support resilience in the field, and keep the character of the crop more intact.',
      },
      {
        'icon': Icons.pets_rounded,
        'title': 'Why does ANAAD use desi cows?',
        'content':
            'Desi cows are central to our natural farming system because they support the preparation of farm-made inputs and reflect a more balanced agricultural ecology. They are part of a farming practice that values nourishment over extraction.',
      },
      {
        'icon': Icons.food_bank_rounded,
        'title': 'Why do you use traditional processing methods?',
        'content':
            'We use traditional processing methods because we want to preserve the grain’s natural character. Slower, careful processing helps us protect taste, texture, and nutritional integrity without forcing the food through excessive heat or speed.',
      },
      {
        'icon': Icons.people_rounded,
        'title': 'How does ANAAD support farmer upliftment?',
        'content':
            'We work through a model that gives farmers more stability, clearer planning, and a stronger link to the people they grow for. When households commit early, farmers gain more certainty and can focus on growing with care rather than chasing unpredictable markets.',
      },
      {
        'icon': Icons.nature_rounded,
        'title': 'How does this model help the environment?',
        'content':
            'Our model reduces unnecessary movement, unnecessary storage, and unnecessary waste in the food chain. By growing more deliberately and closer to the people who consume the food, we aim to support healthier soil, lower waste, and a more respectful ecological footprint.',
      },
      {
        'icon': Icons.currency_rupee_rounded,
        'title': 'Why is ANAAD priced differently from regular store-bought food?',
        'content':
            'ANAAD is priced based on real farming practices, fresher handling, traceability, and the responsibility of growing food with care. It reflects the cost of doing things properly, not the cost of doing them cheaply.',
      },
      {
        'icon': Icons.star_rounded,
        'title': 'Why is ANAAD worth choosing?',
        'content':
            'Because it is not only food. It is a system of trust. When you choose ANAAD, you support cleaner farming, healthier soil, fairer farm economics, and food that stays visibly connected to the people and land behind it.',
      },
      {
        'icon': Icons.verified_user_rounded,
        'title': 'How can I trust that no chemicals are used?',
        'content':
            'Trust comes from process, not just promises. That is why we document batches, share farm records, and keep the food journey visible so you can understand how each product was grown and handled.',
      },
      {
        'icon': Icons.lightbulb_rounded,
        'title': 'What makes ANAAD different from other natural food brands?',
        'content':
            'ANAAD is built around a complete chain of responsibility — from natural farming and traceable batches to commitment-based planning and direct household connection. We are not just selling staples; we are rebuilding the relationship between food, farmer, and family.',
      },
      {
        'icon': Icons.shopping_basket_rounded,
        'title': 'Can I start with one product before committing fully?',
        'content':
            'Yes. Many households begin with one product and then move into a Commitment Plan once they experience the difference. It is a simple way to understand the food, the process, and the value of consistency.',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children:
              faqs.asMap().entries.map((entry) {
                final index = entry.key;

                final faq = entry.value;
                return _FaqItem(
                  icon: faq['icon'] as IconData,
                  title: faq['title'] as String,
                  content: faq['content'] as String,
                  isLast: index == faqs.length - 1,
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildQueryCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withAlpha(15),
            colorScheme.primary.withAlpha(8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withAlpha(40),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.contact_support_rounded,
              color: colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tell Us More',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fill out our form and we\'ll get back to you as soon as possible.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _showQueryForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: AppColors.parchment,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Send Message',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// FAQ Item Widget
class _FaqItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String content;
  final bool isLast;

  const _FaqItem({
    required this.icon,
    required this.title,
    required this.content,
    this.isLast = false,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        InkWell(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                RotationTransition(
                  turns: _rotationAnimation,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(64, 0, 20, 16),
            child: Text(
              widget.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
            ),
          ),
        ),
        if (!widget.isLast)
          Divider(
            height: 1,
            indent: 64,
            endIndent: 20,
            color: theme.dividerColor.withAlpha(100),
          ),
      ],
    );
  }
}

// Query Form Bottom Sheet
class _QueryFormSheet extends StatefulWidget {
  final String? orderNumber;

  const _QueryFormSheet({this.orderNumber});

  @override
  State<_QueryFormSheet> createState() => _QueryFormSheetState();
}

class _QueryFormSheetState extends State<_QueryFormSheet>
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
          'is_from_rfp': false,
          'redirection_from': 'USER_QUERY',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        SnackBarHelper.showSuccess(
          context,
          'Thank you! We\'ll get back to you shortly.',
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
      await context.read<domain.AuthRepository>().sendOtp(value.trim(), type.toUpperCase());
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
                                  .read<domain.AuthRepository>()
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
                                                  .read<domain.AuthRepository>()
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
                        Icons.edit_note_rounded,
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
                            'Share Your Query',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'We\'ll respond within 24 hours',
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
                    if (v == null || v.trim().isEmpty)
                      return 'Please enter your name';
                    if (v.trim().length < 3)
                      return 'Name must be at least 3 characters';
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
                    if (v == null || v.trim().isEmpty)
                      return 'Please enter your phone number';
                    if (!RegExp(r'^\d{10}$').hasMatch(v.trim()))
                      return 'Phone number must be exactly 10 digits';
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
                    if (v == null || v.trim().isEmpty)
                      return 'Please enter your email';
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(v.trim()))
                      return 'Please enter a valid email';
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
                    if (v == null || v.trim().isEmpty)
                      return 'Please enter your message';
                    if (v.trim().length < 10)
                      return 'Message must be at least 10 characters';
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                    _submitForm();
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
                              'Submit Query',
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
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
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
