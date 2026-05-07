import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:http/http.dart' as http;

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
    return FadeTransition(
      opacity: _headerFade,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Gradient background
          Container(
            height: size.height * 0.28 + statusBarHeight,
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
                // ANAAD Logo
                Positioned(
                  top: statusBarHeight + 8,
                  left: 12,
                  child: const AnaadLogoMark(),
                ),
                // Title and subtitle
                Positioned(
                  top: statusBarHeight + 60,
                  left: 24,
                  right: 100, // Increased to avoid overlap with icon
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                // Decorative icon
                Positioned(
                  top: statusBarHeight + 50,
                  right: 20,
                  child: AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, child) {
                      final scale =
                          1.0 +
                          math.sin(_particleController.value * math.pi * 2) *
                              0.08;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.parchment.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: AppColors.parchment,
                            size: 40,
                          ),
                        ),
                      );
                    },
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
        'subtitle': ' A detailed response within 3-5 business days',
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
        'subtitle': 'Real voices, no robots',
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
        'icon': Icons.local_shipping_rounded,
        'title': 'Track Your Order',
        'content':
            'You can track your order from the "My Orders" section. Each order shows real-time status updates from processing to delivery.',
      },
      {
        'icon': Icons.schedule_rounded,
        'title': 'Delivery Timeline',
        'content':
            'We deliver fresh products within 24-48 hours of order confirmation. Delivery times may vary based on your location.',
      },
      {
        'icon': Icons.refresh_rounded,
        'title': 'Returns & Cancellations',
        'content':
            'Orders can be cancelled before dispatch. For quality issues, please contact us within 24 hours of delivery with photos.',
      },
      {
        'icon': Icons.subscriptions_rounded,
        'title': 'Subscription Plans',
        'content':
            'Manage your subscriptions from the "My Subscriptions" section. You can pause, modify, or cancel anytime.',
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

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/user-queries/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'phone_number': _phoneController.text,
          'email': _emailController.text,
          'message': _messageController.text,
          'requirement_type': _selectedType,
          'is_from_rfp': false,
          'redirection_from': 'USER_QUERY',
        }),
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
                // Form fields
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  validator:
                      (v) =>
                          v == null || v.isEmpty
                              ? 'Please enter your name'
                              : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator:
                      (v) =>
                          v == null || v.isEmpty
                              ? 'Please enter your phone'
                              : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email (Optional)',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _messageController,
                  label: 'Your Message',
                  icon: Icons.message_outlined,
                  maxLines: 3,
                  validator:
                      (v) =>
                          v == null || v.isEmpty
                              ? 'Please enter your message'
                              : null,
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
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary, size: 22),
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
