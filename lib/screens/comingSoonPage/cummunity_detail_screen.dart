import 'dart:ui';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/common_widgets/global_import.dart' as http;

class CommunityDetailScreen extends StatefulWidget {
  final Community community;
  const CommunityDetailScreen({super.key, required this.community});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with TickerProviderStateMixin {
  // Animations
  late AnimationController _entranceController;
  late AnimationController _floatController;
  late AnimationController _shimmerController;
  late Animation<double> _heroFade;
  late Animation<double> _cardSlide;
  late Animation<double> _floatAnimation;
  late Animation<double> _shimmerAnimation;
  
  late ScrollController _scrollController;
  double _scrollOffset = 0;

  // Form validation
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );
  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() => _scrollOffset = _scrollController.offset);
      });

    // Entrance animation
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _heroFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _cardSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Floating particles
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // Shimmer for button
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Get accent color based on community name
  Color get _accentColor {
    final name = widget.community.name.toLowerCase();
    if (name.contains('grinity') || name.contains('green')) {
      return const Color(0xFF69F0AE);
    }
    return const Color(0xFFFFAB91);
  }

  List<Color> get _gradientColors {
    final name = widget.community.name.toLowerCase();
    if (name.contains('grinity') || name.contains('green')) {
      return [const Color(0xFF1B5E20), const Color(0xFF2E7D32), const Color(0xFF43A047)];
    }
    return [const Color(0xFF3E2723), const Color(0xFF5D4037), const Color(0xFF795548)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      body: AnimatedBuilder(
        animation: _entranceController,
        builder: (context, child) {
          return Stack(
            children: [

              // Main content
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeroSection(context, textTheme),
                  _buildContentSection(context, theme, textTheme, isDark),
                ],
              ),

              // Floating particles overlay
              _buildFloatingParticles(),

              // Glassmorphism back button
              _buildBackButton(context),
            ],
          );
        },
      ),
    );
  }

  // Background removed - was causing awkward color at top

  Widget _buildHeroSection(BuildContext context, TextTheme textTheme) {
    final heroHeight = 300.0;
    final parallaxOffset = _scrollOffset * 0.5;

    return SliverToBoxAdapter(
      child: ClipRect(
        child: Opacity(
          opacity: _heroFade.value,
          child: SizedBox(
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
              // Parallax Image
              Transform.translate(
                offset: Offset(0, parallaxOffset),
                child: Image.network(
                  widget.community.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      size: 100,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ),

              // Gradient overlays
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _gradientColors[0].withOpacity(0.7),
                      _gradientColors[1].withOpacity(0.5),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Hero content
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glassmorphism badge
                    if (widget.community.comingSoon)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _accentColor.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Coming Soon",
                                  style: textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Community name
                    Text(
                      widget.community.name,
                      style: textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            blurRadius: 20,
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 4),
                          ),
                        ],
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
  }

  Widget _buildContentSection(
    BuildContext context,
    ThemeData theme,
    TextTheme textTheme,
    bool isDark,
  ) {
    return SliverToBoxAdapter(
      child: Transform.translate(
        offset: Offset(0, _cardSlide.value),
        child: Opacity(
          opacity: _heroFade.value,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // About Card - Glassmorphism
                _buildGlassCard(
                  context: context,
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  child: Text(
                    widget.community.description,
                    style: textTheme.bodyLarge?.copyWith(
                      height: 1.7,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Benefits Card
                _buildGlassCard(
                  context: context,
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.star_outline_rounded,
                  iconColor: const Color(0xFFFFD700),
                  title: 'Benefits',
                  child: Column(
                    children: _buildBenefitsList(context, widget.community.benefits),
                  ),
                ),
                const SizedBox(height: 32),

                // Premium CTA Button
                if (widget.community.comingSoon) _buildNotifyButton(context, textTheme),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required String title,
    required Widget child,
    Color? iconColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withOpacity(0.1),
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
                      color: (iconColor ?? _accentColor).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor ?? _accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifyButton(BuildContext context, TextTheme textTheme) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showNotificationForm(context);
      },
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _gradientColors[1].withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Shimmer overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.15),
                            Colors.transparent,
                          ],
                          stops: [
                            (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                            _shimmerAnimation.value.clamp(0.0, 1.0),
                            (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Button content
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Notify Me When Available',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
              top: 80 + (_floatAnimation.value * 10),
              right: 30,
              child: _buildParticle(6),
            ),
            Positioned(
              top: 150 + (_floatAnimation.value * -8),
              right: 60,
              child: _buildParticle(4),
            ),
            Positioned(
              top: 220 + (_floatAnimation.value * 6),
              right: 25,
              child: _buildParticle(5),
            ),
          ],
        );
      },
    );
  }

  Widget _buildParticle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _accentColor.withOpacity(0.5),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.3),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      child: Opacity(
        opacity: _heroFade.value,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBenefitsList(BuildContext context, String benefits) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final items = benefits
        .split(RegExp(r'\n|•'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (items.length <= 1) {
      return [
        Text(
          benefits,
          style: textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
      ];
    }

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item,
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Form validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!_emailRegex.hasMatch(value)) return 'Please enter a valid email address';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your phone number';
    String cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    if (!_phoneRegex.hasMatch(cleanPhone)) return 'Please enter a valid 10-digit phone number';
    return null;
  }

  Future<void> _showNotificationForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final messageController = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isDark = theme.brightness == Brightness.dark;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: curvedAnimation,
          child: FadeTransition(
            opacity: animation,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _gradientColors[0].withOpacity(0.95),
                            _gradientColors[1].withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _gradientColors[0].withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header with icon
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _accentColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _accentColor.withOpacity(0.3),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Stay Updated',
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Be the first to know when we launch!',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                // Glass inputs
                                _buildGlassInput(
                                  controller: nameController,
                                  hint: 'Your Name',
                                  icon: Icons.person_outline_rounded,
                                  validator: (value) =>
                                      value == null || value.isEmpty ? 'Please enter your name' : null,
                                ),
                                const SizedBox(height: 12),
                                _buildGlassInput(
                                  controller: emailController,
                                  hint: 'Email Address',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 12),
                                _buildGlassInput(
                                  controller: phoneController,
                                  hint: 'Phone Number',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: _validatePhone,
                                ),
                                const SizedBox(height: 12),
                                _buildGlassInput(
                                  controller: messageController,
                                  hint: 'Message (optional)',
                                  icon: Icons.message_outlined,
                                  validator: (v) => v!.isEmpty ? 'Enter a message' : null,
                                ),
                                const SizedBox(height: 20),
                                // Submit button
                                GestureDetector(
                                  onTap: () async {
                                    if (formKey.currentState!.validate()) {
                                      HapticFeedback.mediumImpact();
                                      formKey.currentState!.save();
                                      try {
                                        final response = await http.post(
                                          Uri.parse(
                                            '${ApiConfig.baseUrl}/api/core/communities/${widget.community.name}/subscribe/',
                                          ),
                                          headers: {'Content-Type': 'application/json'},
                                          body: jsonEncode({
                                            'name': nameController.text,
                                            'email': emailController.text,
                                            'phone': phoneController.text,
                                            'message': messageController.text,
                                          }),
                                        );
                                        if (!context.mounted) return;
                                        if (response.statusCode == 200 || response.statusCode == 201) {
                                          Navigator.pop(context);
                                          SnackBarHelper.showSuccess(context, 'Thank you! We\'ll keep you updated.');
                                        } else {
                                          throw Exception('Failed to submit form');
                                        }
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                        SnackBarHelper.showError(context, 'Failed to submit. Please try again later.');
                                      }
                                    }
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Notify Me',
                                        style: textTheme.titleMedium?.copyWith(
                                          color: _gradientColors[0],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Cancel button
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Maybe Later',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.7),
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
          ),
        );
      },
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              errorStyle: TextStyle(color: _accentColor),
            ),
          ),
        ),
      ),
    );
  }
}

