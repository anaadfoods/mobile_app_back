import "dart:math" as math;
import "package:flutter/services.dart";
import "package:grocery_app/common_widgets/global_import.dart";
import "package:grocery_app/screens/innovations/anaad_innovations_screen.dart";

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // Settings state
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Main entrance animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Pulse animation for profile card
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Shimmer animation for header
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _shimmerController.repeat();

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // Haptic feedback methods
  void _triggerHaptic() {
    if (_vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _triggerMediumHaptic() {
    if (_vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void openWhatsApp(BuildContext context) async {
    _triggerHaptic();
    final phoneNumber = '+919996166186';
    final message = Uri.encodeComponent(
      "Hello, I want to inquire about your products.",
    );
    final url = Uri.parse("https://wa.me/$phoneNumber?text=$message");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  void _handleLogout(BuildContext context) {
    _triggerMediumHaptic();
    context.read<AuthCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              return _buildAccountView(context, state.user);
            }
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountView(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    String userName = '${user.firstName} ${user.lastName}'.trim();
    if (userName.isEmpty) userName = "User";

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: () async {
        await context.read<AuthCubit>().checkAuthStatus();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildAnimatedHeader(theme, size, user, userName),
            const SizedBox(height: 70),
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildAnimatedStatsRow(theme),
                      const SizedBox(height: 24),

                      // Anaad Innovations Section
                      _buildInnovationsCard(theme),
                      const SizedBox(height: 20),

                      _buildMenuSection(
                        theme,
                        title: 'Account',
                        items: [
                          _MenuItem(
                            icon: Icons.person_outline_rounded,
                            title: 'Edit Profile',
                            subtitle: 'Update your personal details',
                            iconColor: Colors.blue,
                            onTap: () {
                              _triggerHaptic();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          EditProfileScreen(userProfile: user),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildMenuSection(
                        theme,
                        title: 'Orders & Subscriptions',
                        items: [
                          _MenuItem(
                            icon: Icons.shopping_bag_outlined,
                            title: 'My Orders',
                            subtitle: ' Track your harvest journey',
                            iconColor: Colors.green,
                            onTap: () {
                              _triggerHaptic();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderScreen(),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.autorenew_rounded,
                            title: 'My Subscriptions',
                            subtitle: 'View active subscriptions',
                            iconColor: Colors.green,
                            onTap: () {
                              _triggerHaptic();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const SubscriptionScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildPreferencesSection(theme),
                      const SizedBox(height: 20),
                      _buildMenuSection(
                        theme,
                        title: 'Support',
                        items: [
                          _MenuItem(
                            icon: Icons.help_outline_rounded,
                            title: 'Help Center',
                            subtitle: 'FAQs and support',
                            iconColor: Colors.green,
                            onTap: () {
                              _triggerHaptic();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HelpScreen(),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'Chat on WhatsApp',
                            subtitle: 'We\'re here to help',
                            iconColor: Colors.green,
                            onTap: () => openWhatsApp(context),
                          ),
                          _MenuItem(
                            icon: Icons.info_outline_rounded,
                            title: 'About Us',
                            subtitle: 'Learn more about us',
                            iconColor: Colors.green,
                            onTap: () {
                              _triggerHaptic();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AboutScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildLogoutButton(theme, context),
                      const SizedBox(height: 32),
                      _buildAppVersion(theme),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ANIMATED HEADER ====================
  Widget _buildAnimatedHeader(
    ThemeData theme,
    Size size,
    UserModel user,
    String userName,
  ) {
    final colorScheme = theme.colorScheme;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Animated Gradient Background with shimmer
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Container(
              height: size.height * 0.26 + statusBarHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withAlpha(255),
                    colorScheme.primary,
                    colorScheme.primary.withAlpha(204),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Shimmer effect overlay
                  Positioned.fill(child: _buildShimmerOverlay()),
                  // Floating animated circles
                  ..._buildFloatingCircles(),
                  // Title
                  Positioned(
                    top: statusBarHeight + 12,
                    left: 0,
                    right: 0,
                    child: const Center(
                      child: Text(
                        'My Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Curved bottom edge
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
        // Profile Card with pulse animation
        Positioned(
          bottom: -50,
          left: 20,
          right: 20,
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: _buildProfileCard(theme, user, userName),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerOverlay() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(0),
                Colors.white.withAlpha(25),
                Colors.white.withAlpha(0),
              ],
              stops: [
                (shimmerValue - 0.3).clamp(0.0, 1.0),
                shimmerValue.clamp(0.0, 1.0),
                (shimmerValue + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingCircles() {
    final positions = [
      {'top': -60.0, 'right': -40.0, 'size': 180.0, 'alpha': 25},
      {'top': 60.0, 'left': -40.0, 'size': 100.0, 'alpha': 20},
      {'bottom': 50.0, 'right': 30.0, 'size': 60.0, 'alpha': 15},
      {'top': 80.0, 'right': 80.0, 'size': 40.0, 'alpha': 20},
      {'bottom': 70.0, 'left': 50.0, 'size': 30.0, 'alpha': 18},
    ];

    return positions.asMap().entries.map((entry) {
      final index = entry.key;
      final pos = entry.value;

      return AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          final offset =
              math.sin(_shimmerController.value * math.pi * 2 + index) * 5;
          return Positioned(
            top: pos['top'] != null ? (pos['top'] as double) + offset : null,
            bottom:
                pos['bottom'] != null
                    ? (pos['bottom'] as double) + offset
                    : null,
            left: pos['left'] != null ? (pos['left'] as double) + offset : null,
            right:
                pos['right'] != null ? (pos['right'] as double) + offset : null,
            child: Container(
              height: pos['size'] as double,
              width: pos['size'] as double,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(pos['alpha'] as int),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  // ==================== PROFILE CARD ====================
  Widget _buildProfileCard(ThemeData theme, UserModel user, String userName) {
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        _triggerMediumHaptic();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(userProfile: user),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withAlpha(40),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with animated gradient border
            _buildAnimatedAvatar(theme, user),
            const SizedBox(width: 14),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withAlpha(153),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _buildVerifiedBadge(theme, user),
                ],
              ),
            ),
            // Edit Button with ripple
            Material(
              color: colorScheme.primary.withAlpha(25),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () {
                  _triggerHaptic();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => EditProfileScreen(userProfile: user),
                    ),
                  );
                },
                customBorder: const CircleBorder(),
                splashColor: colorScheme.primary.withAlpha(51),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedAvatar(ThemeData theme, UserModel user) {
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              startAngle: _shimmerController.value * math.pi * 2,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withAlpha(128),
                colorScheme.primary,
              ],
            ),
          ),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: theme.cardColor,
            child: CircleAvatar(
              radius: 29,
              backgroundColor: colorScheme.primary.withAlpha(25),
              backgroundImage:
                  user.profilePicture != null && user.profilePicture!.isNotEmpty
                      ? NetworkImage(user.profilePicture!)
                      : null,
              child:
                  user.profilePicture == null || user.profilePicture!.isEmpty
                      ? Icon(
                        Icons.person_rounded,
                        size: 32,
                        color: colorScheme.primary,
                      )
                      : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerifiedBadge(ThemeData theme, UserModel user) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withAlpha(51),
                  Colors.orange.withAlpha(38),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withAlpha(76), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 4),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== STATS ROW ====================
  Widget _buildAnimatedStatsRow(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnimatedStatItem(
                  theme,
                  12,
                  'Orders',
                  Icons.shopping_bag_outlined,
                  Colors.green,
                  0,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OrderScreen()),
                    );
                  },
                ),
                _buildGradientDivider(theme),
                _buildAnimatedStatItem(
                  theme,
                  3,
                  'Subscriptions',
                  Icons.autorenew_rounded,
                  Colors.green,
                  1,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubscriptionScreen(),
                      ),
                    );
                  },
                ),
                _buildGradientDivider(theme),
                _buildAnimatedStatItem(
                  theme,
                  5,
                  'Saved',
                  Icons.favorite_outline_rounded,
                  const Color(0xFFD32F2F),
                  2,
                  () {
                    context
                        .findAncestorStateOfType<DashboardScreenState>()!
                        .switchToTab(1);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStatItem(
    ThemeData theme,
    int count,
    String label,
    IconData icon,
    Color color,
    int index,
    Function press,
  ) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: count),
      duration: Duration(milliseconds: 800 + (index * 200)),
      curve: Curves.easeOutCubic,
      builder: (context, animatedCount, child) {
        return GestureDetector(
          onTap: () {
            _triggerHaptic();
            press();
          },
          child: Column(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 100)),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withAlpha(38),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                animatedCount.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(153),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradientDivider(ThemeData theme) {
    return Container(
      height: 45,
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.dividerColor.withAlpha(0),
            theme.dividerColor.withAlpha(76),
            theme.dividerColor.withAlpha(0),
          ],
        ),
      ),
    );
  }

  // ==================== ANAAD INNOVATIONS CARD ====================
  Widget _buildInnovationsCard(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: () {
                _triggerMediumHaptic();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AnaadInnovationsScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6B21A8), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B21A8).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anaad Innovations',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Beyond food. Explore the future of farming.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Enter Lab',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 16,
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
    );
  }

  // ==================== MENU SECTIONS ====================
  Widget _buildMenuSection(
    ThemeData theme, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color?.withAlpha(204),
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children:
                items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == items.length - 1;

                  return Column(
                    children: [
                      _buildAnimatedMenuItem(theme, item, index),
                      if (!isLast)
                        Padding(
                          padding: const EdgeInsets.only(left: 60),
                          child: Divider(
                            height: 1,
                            color: theme.dividerColor.withAlpha(38),
                          ),
                        ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedMenuItem(ThemeData theme, _MenuItem item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(16),
                splashColor: item.iconColor.withAlpha(25),
                highlightColor: item.iconColor.withAlpha(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.iconColor.withAlpha(38),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.icon,
                                color: item.iconColor,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withAlpha(127),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.textTheme.bodyMedium?.color?.withAlpha(76),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== PREFERENCES SECTION ====================
  Widget _buildPreferencesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Your Experience',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color?.withAlpha(204),
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Haptic Feedback Toggle
              _buildAnimatedSwitchItem(
                theme,
                icon: Icons.vibration_rounded,
                title: 'Haptic Feedback',
                subtitle:
                    _vibrationEnabled
                        ? 'Feel subtle vibrations'
                        : 'Vibrations disabled',
                value: _vibrationEnabled,
                iconColor: Colors.deepPurple,
                onChanged: (value) {
                  if (value) {
                    HapticFeedback.mediumImpact();
                  }
                  setState(() => _vibrationEnabled = value);
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 60),
                child: Divider(
                  height: 1,
                  color: theme.dividerColor.withAlpha(38),
                ),
              ),
              // Dark Mode Toggle
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  final isDarkMode =
                      themeMode == ThemeMode.dark ||
                      (themeMode == ThemeMode.system &&
                          MediaQuery.of(context).platformBrightness ==
                              Brightness.dark);

                  return _buildAnimatedSwitchItem(
                    theme,
                    icon:
                        isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                    title: 'Dark Mode',
                    subtitle:
                        isDarkMode
                            ? 'Dark theme enabled'
                            : 'Light theme enabled',
                    value: isDarkMode,
                    iconColor: Colors.blueGrey,
                    onChanged: (value) {
                      _triggerHaptic();
                      context.read<ThemeCubit>().toggleTheme(value);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedSwitchItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color iconColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: value ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, animValue, child) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    iconColor.withAlpha(25),
                    iconColor.withAlpha(64),
                    animValue,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    subtitle,
                    key: ValueKey(subtitle),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withAlpha(127),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildCustomSwitch(theme, value, onChanged),
        ],
      ),
    );
  }

  Widget _buildCustomSwitch(
    ThemeData theme,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient:
              value
                  ? LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withAlpha(204),
                    ],
                  )
                  : null,
          color: value ? null : theme.dividerColor.withAlpha(76),
          boxShadow:
              value
                  ? [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(76),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child:
                  value
                      ? Icon(
                        Icons.check_rounded,
                        key: const ValueKey('check'),
                        size: 14,
                        color: colorScheme.primary,
                      )
                      : const SizedBox(key: ValueKey('empty')),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== LOGOUT BUTTON ====================
  Widget _buildLogoutButton(ThemeData theme, BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.red.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => _showLogoutDialog(theme, context),
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.red.withAlpha(51),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(ThemeData theme, BuildContext context) {
    _triggerMediumHaptic();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Logout Dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (dialogContext, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Log Out'),
                ],
              ),
              content: const Text(
                'Are you sure you want to log out? You\'ll need to sign in again to access your account.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _triggerHaptic();
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withAlpha(178),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _handleLogout(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Log Out'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== APP VERSION ====================
  Widget _buildAppVersion(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Column(
            children: [
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(102),
                ),
              ),
              const SizedBox(height: 10),
              _buildInnovationBadge(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInnovationBadge(ThemeData theme) {
    const saffronColor = Color(0xFFFF9933);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowIntensity =
            0.15 + (math.sin(_pulseController.value * math.pi * 2) * 0.1);
        final pulseScale =
            1.0 + (math.sin(_pulseController.value * math.pi * 2) * 0.08);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color:
                isDark
                    ? saffronColor.withOpacity(0.08)
                    : saffronColor.withOpacity(0.06),
            border: Border.all(
              color: saffronColor.withOpacity(glowIntensity + 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: saffronColor.withOpacity(glowIntensity * 0.4),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: pulseScale,
                child: ShaderMask(
                  shaderCallback:
                      (bounds) => LinearGradient(
                        colors: [
                          saffronColor,
                          const Color(0xFFFFD700),
                          saffronColor,
                        ],
                      ).createShader(bounds),
                  child: const Text(
                    '⚡',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ShaderMask(
                    shaderCallback:
                        (bounds) => LinearGradient(
                          colors: [
                            saffronColor,
                            const Color(0xFFFFD700),
                            saffronColor,
                          ],
                        ).createShader(bounds),
                    child: const Text(
                      'Powered by Innovators from the Soil of India',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: pulseScale,
                child: ShaderMask(
                  shaderCallback:
                      (bounds) => LinearGradient(
                        colors: [
                          saffronColor,
                          const Color(0xFFFFD700),
                          saffronColor,
                        ],
                      ).createShader(bounds),
                  child: const Text(
                    '⚡',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================== MENU ITEM MODEL ====================
class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });
}
