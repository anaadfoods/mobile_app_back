import "dart:math" as math;
import "package:flutter/services.dart";
import "package:grocery_app/common_widgets/global_import.dart";
import "package:grocery_app/models/user_summary_model.dart";
import "package:grocery_app/screens/innovations/panchang/panchang_home_screen.dart";
import "package:grocery_app/screens/innovations/refer_earn_screen.dart";

import "package:grocery_app/services/user_summary_service.dart";
import "package:grocery_app/common_widgets/animated_screen_header.dart";
import "package:grocery_app/screens/account/account_profile_card.dart";
import "package:grocery_app/screens/account/account_stats_row.dart";
import "package:grocery_app/screens/account/account_innovations_card.dart";
import "package:grocery_app/screens/account/account_menu_section.dart";
import "package:grocery_app/screens/account/account_preferences_section.dart";

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  // Settings state
  bool _vibrationEnabled = true;

  // User summary state
  final UserSummaryService _userSummaryService = UserSummaryService();
  UserSummaryModel? _userSummary;
  bool _isLoadingSummary = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchUserSummary();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh user summary each time screen is visited
    _fetchUserSummary();
  }

  /// Fetches user summary data from the API
  Future<void> _fetchUserSummary() async {
    if (_isLoadingSummary) return;
    if (!mounted) return;

    setState(() => _isLoadingSummary = true);

    try {
      final summary = await _userSummaryService.getUserSummary();
      if (mounted) {
        setState(() {
          _userSummary = summary;
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSummary = false);
      }
    }
  }

  void _initAnimations() {
    // Pulse animation for profile card and other elements
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseController.repeat(reverse: true);

    // Shimmer animation for header and other elements
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _shimmerController.repeat();
  }

  @override
  void dispose() {
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
        SnackBarHelper.showError(
          context,
          "Couldn't open WhatsApp. Is it installed? 💬",
        );
      }
    }
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
        await Future.wait([
          context.read<AuthCubit>().checkAuthStatus(),
          _fetchUserSummary(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Builder(
              builder: (context) {
                final statusBarHeight = MediaQuery.of(context).padding.top;
                final screenHeight = size.height;
                final headerHeight = (statusBarHeight + 180).clamp(
                  200.0,
                  (screenHeight * 0.30).clamp(200.0, 280.0),
                );

                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedScreenHeader(
                      title: "My Profile",
                      icon: Icons.person_rounded,
                      showBack: false,
                      height: headerHeight,
                      centerTitle: true,
                    ),
                    Positioned(
                      bottom: -55,
                      left: 20,
                      right: 20,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: AccountProfileCard(
                          user: user,
                          userName: userName,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 75),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Stats Row with padding
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: AccountStatsRow(
                      totalOrders: _userSummary?.orders.total ?? 0,
                      activeSubscriptions:
                          _userSummary?.subscriptions.activeTotal ?? 0,
                      favoriteCount: _userSummary?.favorites.count ?? 0,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Anaad Innovations Section
                  // const AccountInnovationsCard(),
                  const SizedBox(height: 20),

                  AccountMenuSection(
                    title: 'Account',
                    items: [
                      AccountMenuItem(
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
                      AccountMenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Refer & Earn',
                        subtitle: 'Connect your friend in health',
                        iconColor: Colors.blue,
                        onTap: () {
                          _triggerHaptic();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReferEarnScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  AccountMenuSection(
                    title: 'Panchang',
                    items: [
                      AccountMenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Panchang',
                        subtitle: 'See your Panchang',
                        iconColor: Colors.blue,
                        onTap: () {
                          _triggerHaptic();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PanchangHomeScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AccountMenuSection(
                    title: 'Orders & Subscriptions',
                    items: [
                      AccountMenuItem(
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
                      AccountMenuItem(
                        icon: Icons.autorenew_rounded,
                        title: 'My Subscriptions',
                        subtitle: 'View active subscriptions',
                        iconColor: Colors.green,
                        onTap: () {
                          _triggerHaptic();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SubscriptionScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AccountPreferencesSection(
                    vibrationEnabled: _vibrationEnabled,
                    onVibrationChanged: (value) {
                      setState(() => _vibrationEnabled = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  AccountMenuSection(
                    title: 'Support',
                    items: [
                      AccountMenuItem(
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
                      AccountMenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Chat on WhatsApp',
                        subtitle: 'We\'re here to help',
                        iconColor: Colors.green,
                        onTap: () => openWhatsApp(context),
                      ),
                      AccountMenuItem(
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
                  const SizedBox(height: 32),
                  _buildAppVersion(theme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ANAAD INNOVATIONS CARD ====================

  // ==================== MENU SECTIONS ====================

  // ==================== LOGOUT BUTTON ====================

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

  void _showDeactivationDialog() {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isObscured = true;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (innerContext, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red[700],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Deactivate Account'),
                  ],
                ),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Are you sure you want to deactivate your account? This action cannot be undone immediately.',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: passwordController,
                        obscureText: isObscured,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isObscured
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed:
                                isLoading
                                    ? null
                                    : () {
                                      setDialogState(() {
                                        isObscured = !isObscured;
                                      });
                                    },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                actions: [
                  TextButton(
                    onPressed:
                        isLoading ? null : () => Navigator.pop(dialogContext),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isLoading ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              if (formKey.currentState!.validate()) {
                                setDialogState(() => isLoading = true);

                                final authCubit =
                                    innerContext.read<AuthCubit>();
                                final result = await authCubit
                                    .deactivateAccount(passwordController.text);

                                if (result['success'] == true) {
                                  // Success — close dialog and show success message
                                  if (innerContext.mounted) {
                                    Navigator.pop(innerContext);
                                  }
                                  if (mounted) {
                                    SnackBarHelper.showSuccess(
                                      context,
                                      result['message'] ??
                                          'Your account has been deactivated successfully.',
                                    );
                                  }
                                } else {
                                  // Error — show error snackbar and keep dialog open
                                  setDialogState(() => isLoading = false);
                                  if (mounted) {
                                    SnackBarHelper.showError(
                                      context,
                                      result['message'] ??
                                          'Failed to deactivate account. Please try again.',
                                    );
                                  }
                                }
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Deactivate'),
                  ),
                ],
              );
            },
          ),
    );
  }
}
