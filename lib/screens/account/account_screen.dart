import "dart:math" as math;
import "package:grocery_app/common_widgets/global_import.dart";
import "package:grocery_app/models/user_summary_model.dart";
import "package:grocery_app/routes/app_routes.dart";
import "package:grocery_app/services/user_summary_service.dart";
import "package:grocery_app/screens/account/account_profile_card.dart";
import "package:grocery_app/screens/account/account_stats_row.dart";
import "package:grocery_app/screens/account/account_menu_section.dart";
import "package:grocery_app/screens/account/account_preferences_section.dart";

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  // Single animation controller for footer badge shimmer
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
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _fetchUserSummary();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchUserSummary();
  }

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

  @override
  void dispose() {
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
          "Couldn't open WhatsApp. Is it installed?",
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

    String userName = '${user.firstName} ${user.lastName}'.trim();
    if (userName.isEmpty) userName = "User";

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: theme.colorScheme.primary,
      onRefresh: () async {
        await Future.wait([
          context.read<AuthCubit>().checkAuthStatus(),
          _fetchUserSummary(),
        ]);
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Hero SliverAppBar with gradient + centered avatar
          SliverAppBar(
            expandedHeight: 210,
            floating: false,
            pinned: false,
            stretch: true,
            automaticallyImplyLeading: false,
            backgroundColor: theme.colorScheme.primary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _buildHeroBackground(context, user, userName, theme),
            ),
          ),

          // Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                children: [
                  // Gradient Stat Chips
                  AccountStatsRow(
                    totalOrders: _userSummary?.orders.total ?? 0,
                    activeSubscriptions:
                        _userSummary?.subscriptions.activeTotal ?? 0,
                    favoriteCount: _userSummary?.favorites.count ?? 0,
                  ),
                  const SizedBox(height: 20),

                  // Refer & Earn Banner
                  _buildReferEarnBanner(context, theme),
                  const SizedBox(height: 24),

                  // Quick Settings (Preferences as inline toggles)
                  AccountPreferencesSection(
                    vibrationEnabled: _vibrationEnabled,
                    onVibrationChanged: (value) {
                      setState(() => _vibrationEnabled = value);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Account Section
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
                          context.pushNamed(
                            AppRoute.editProfile.name,
                            extra: user,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Orders & Subscriptions with trailing values
                  AccountMenuSection(
                    title: 'Orders & Subscriptions',
                    items: [
                      AccountMenuItem(
                        icon: Icons.shopping_bag_outlined,
                        title: 'My Orders',
                        subtitle: 'Track your harvest journey',
                        iconColor: Colors.green,
                        trailing: _userSummary != null
                            ? '${_userSummary!.orders.total}'
                            : null,
                        onTap: () {
                          _triggerHaptic();
                          context.pushNamed(AppRoute.orderList.name);
                        },
                      ),
                      AccountMenuItem(
                        icon: Icons.autorenew_rounded,
                        title: 'My Subscriptions',
                        subtitle: 'View active plans',
                        iconColor: Colors.blue,
                        trailing: _userSummary != null &&
                                _userSummary!.subscriptions.activeTotal > 0
                            ? '${_userSummary!.subscriptions.activeTotal} active'
                            : null,
                        onTap: () {
                          _triggerHaptic();
                          context.pushNamed(AppRoute.subscriptionList.name);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Explore Section
                  AccountMenuSection(
                    title: 'Explore',
                    items: [
                      AccountMenuItem(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Panchang',
                        subtitle: 'Daily cosmic insights',
                        iconColor: Colors.deepOrange,
                        onTap: () {
                          _triggerHaptic();
                          context.pushNamed(AppRoute.panchang.name);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Support Section
                  AccountMenuSection(
                    title: 'Support',
                    items: [
                      AccountMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help Center',
                        subtitle: 'FAQs and support',
                        iconColor: Colors.teal,
                        onTap: () {
                          _triggerHaptic();
                          context.pushNamed(AppRoute.help.name);
                        },
                      ),
                      AccountMenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Chat on WhatsApp',
                        subtitle: "We're here to help",
                        iconColor: const Color(0xFF25D366),
                        onTap: () => openWhatsApp(context),
                      ),
                      AccountMenuItem(
                        icon: Icons.info_outline_rounded,
                        title: 'About Us',
                        subtitle: 'Learn more about us',
                        iconColor: Colors.indigo,
                        onTap: () {
                          _triggerHaptic();
                          context.pushNamed(AppRoute.aboutUs.name);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Brand Footer
                  _buildBrandFooter(theme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hero Background with gradient + subtle pattern + centered avatar
  Widget _buildHeroBackground(
    BuildContext context,
    UserModel user,
    String userName,
    ThemeData theme,
  ) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withAlpha(220),
              const Color(0xFF2E4A34),
            ],
          ),
        ),
      child: Stack(
        children: [
          // Profile content centered
          SafeArea(
            bottom: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 22),
                child: AccountProfileCard(
                  user: user,
                  userName: userName,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  // Refer & Earn green banner
  Widget _buildReferEarnBanner(BuildContext context, ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          _triggerMediumHaptic();
          context.pushNamed(AppRoute.referEarn.name);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withAlpha(200),
                const Color(0xFF2E4A34),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withAlpha(60),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Refer & Earn',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Share health with friends & get rewards',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF1E88E5),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Brand Footer with version + innovation badge
  Widget _buildBrandFooter(ThemeData theme) {
    const saffronColor = Color(0xFFFF9933);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          'Version 1.0.0',
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodyMedium?.color?.withAlpha(90),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final glowIntensity = 0.15 +
                (math.sin(_shimmerController.value * math.pi * 2) * 0.1);

            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isDark
                    ? saffronColor.withAlpha(20)
                    : saffronColor.withAlpha(15),
                border: Border.all(
                  color: saffronColor.withAlpha(((glowIntensity + 0.2) * 255).round()),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        saffronColor,
                        const Color(0xFFFFD700),
                        saffronColor,
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      '\u26A1',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            saffronColor,
                            const Color(0xFFFFD700),
                            saffronColor,
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'Powered by Innovators from the Soil of India',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        saffronColor,
                        const Color(0xFFFFD700),
                        saffronColor,
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      '\u26A1',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Deactivation Dialog (preserved from original)
  void _showDeactivationDialog() {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isObscured = true;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
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
                    color: Colors.red.withAlpha(25),
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
                        onPressed: isLoading
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
                    color:
                        isLoading ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => isLoading = true);

                          final authCubit =
                              innerContext.read<AuthCubit>();
                          final result = await authCubit
                              .deactivateAccount(passwordController.text);

                          if (result['success'] == true) {
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
                child: isLoading
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