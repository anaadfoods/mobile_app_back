import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:share_plus/share_plus.dart';
import 'package:grocery_app/services/referral_reward_service.dart';
import 'package:grocery_app/models/referral_model.dart';

import 'package:grocery_app/service_locator.dart';

class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  final ReferralRewardService _referralService = getIt<ReferralRewardService>();

  // Dynamic data from API
  ReferralData? _referralData;
  bool _isLoading = true;

  String get _referralCode => _referralData?.referralCode ?? 'LOADING...';
  int get _totalReferrals => _referralData?.referralsCount ?? 0;
  int get _pendingReferrals =>
      _referralData?.referredUsers
          .where(
            (u) =>
                u.status == 'PENDING' ||
                u.status == 'REGISTERED' ||
                u.status == 'QUALIFICATION_PENDING',
          )
          .length ??
      0;
  int get _acceptedReferrals =>
      _referralData?.referredUsers
          .where(
            (u) =>
                u.status == 'QUALIFIED' ||
                u.status == 'REWARD_AVAILABLE' ||
                u.status == 'REWARD_REDEEMED',
          )
          .length ??
      0;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _fetchReferralData();
  }

  Future<void> _fetchReferralData() async {
    final data = await _referralService.fetchReferrals();
    if (mounted) {
      setState(() {
        _referralData = data;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    HapticFeedback.mediumImpact();
    SnackBarHelper.showCopied(context, what: 'Referral code');
  }

  void _share(BuildContext context) {
    HapticFeedback.mediumImpact();
    final box = context.findRenderObject() as RenderBox?;
    Share.share(
      'Join Anaad — where food meets farming! Use my referral code: $_referralCode to sign up & place your first order.\n\nDownload now: https://anaad.app/download',
      subject: 'Join Anaad — Fresh from the Farm!',
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.parchment : AppColors.charcoal,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Refer & Earn',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.parchment : AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : RefreshIndicator(
                color: theme.colorScheme.primary,
                backgroundColor: theme.cardColor,
                onRefresh: _fetchReferralData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    20 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Hero Section
                      _buildHeroSection(theme, isDark),
                      const SizedBox(height: 28),

                      // Referral Code Card
                      _buildReferralCodeCard(theme, isDark),
                      const SizedBox(height: 24),

                      // Share Buttons
                      _buildShareButtons(context, theme, isDark),
                      const SizedBox(height: 28),

                      // Stats Section
                      _buildStatsSection(theme, isDark),
                      const SizedBox(height: 28),

                      // Referred Users List
                      if (_referralData != null)
                        _buildReferredUsersList(theme, isDark),
                      if (_referralData != null) const SizedBox(height: 28),

                      // How It Works
                      _buildHowItWorks(theme, isDark),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildHeroSection(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.harvestAmber,
                AppColors.harvestAmber.withAlpha(200),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.harvestAmber.withAlpha(100),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.card_giftcard_rounded,
            color: AppColors.pureWhite,
            size: 50,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Sow the Seeds of Health.',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.parchment : AppColors.charcoal87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Invite your loved ones to Anaad. When your friend signs up and places their first order, you receive a surprise gift from the Anaad team! 🎁',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.parchment70 : AppColors.rawEarth70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReferralCodeCard(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withAlpha(200),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withAlpha(100),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.transparent,
                        AppColors.parchment.withValues(alpha: 0.15),
                        AppColors.transparent,
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
              Column(
                children: [
                  Text(
                    'Your Referral Code',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.parchment.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.parchment.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.parchment.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _referralCode,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: AppColors.parchment,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: _copyCode,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.parchment.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.copy_rounded,
                              color: AppColors.parchment,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _share(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.parchment,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.charcoal.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.share_rounded,
                            color: AppColors.deepSoilGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Share Now',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.deepSoilGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareButtons(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final platforms = [
      {
        'icon': Icons.message_rounded,
        'name': 'WhatsApp',
        'color': AppColors.deepSoilGreen,
      },
      {
        'icon': Icons.telegram,
        'name': 'Telegram',
        'color': AppColors.deepSoilGreen,
      },
      {
        'icon': Icons.email_rounded,
        'name': 'Email',
        'color': AppColors.deepSoilGreen,
      },
      {
        'icon': Icons.more_horiz_rounded,
        'name': 'More',
        'color': AppColors.rawEarth,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share via',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              platforms.map((p) {
                return Builder(
                  builder:
                      (ctx) => GestureDetector(
                        onTap: () => _share(ctx),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: (p['color'] as Color).withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                p['icon'] as IconData,
                                color: p['color'] as Color,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p['name'] as String,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color:
                                    isDark
                                        ? AppColors.parchment70
                                        : AppColors.rawEarth70,
                              ),
                            ),
                          ],
                        ),
                      ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatsSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withAlpha(12),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Referral Stats',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                theme,
                isDark,
                Icons.people_rounded,
                '$_totalReferrals',
                'Referrals',
                AppColors.harvestAmber,
              ),
              _buildStatItem(
                theme,
                isDark,
                Icons.hourglass_top_rounded,
                '$_pendingReferrals',
                'Pending',
                AppColors.rawEarth,
              ),
              _buildStatItem(
                theme,
                isDark,
                Icons.shopping_cart_checkout_rounded,
                '$_acceptedReferrals',
                'Ordered',
                AppColors.deepSoilGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    bool isDark,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.parchment : AppColors.charcoal87,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark ? AppColors.parchment70 : AppColors.rawEarth70,
          ),
        ),
      ],
    );
  }

  Widget _buildReferredUsersList(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withAlpha(12),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  color: AppColors.deepSoilGreen.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: AppColors.deepSoilGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Your Referrals',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.harvestAmber.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_referralData!.referredUsers.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.harvestAmber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_referralData!.referredUsers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 40,
                      color:
                          isDark
                              ? AppColors.parchment.withValues(alpha: 0.4)
                              : AppColors.rawEarth.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No referrals registered yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            isDark
                                ? AppColors.parchment.withValues(alpha: 0.7)
                                : AppColors.rawEarth.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_referralData!.referredUsers.map(
              (user) => _buildUserCard(theme, isDark, user),
            )),
        ],
      ),
    );
  }

  Widget _buildUserCard(ThemeData theme, bool isDark, ReferredUser user) {
    Color statusColor;
    switch (user.status?.toUpperCase()) {
      case 'REGISTERED':
      case 'QUALIFICATION_PENDING':
      case 'PENDING':
        statusColor = AppColors.harvestAmber;
        break;
      case 'QUALIFIED':
      case 'REWARD_AVAILABLE':
      case 'REWARD_REDEEMED':
        statusColor = AppColors.deepSoilGreen;
        break;
      case 'DISQUALIFIED':
        statusColor = AppColors.rawEarth;
        break;
      default:
        statusColor = AppColors.harvestAmber;
    }
    final statusText = user.statusDisplay ?? user.status ?? 'Joined';
    final dateStr =
        '${user.dateJoined.day}/${user.dateJoined.month}/${user.dateJoined.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.charcoal60 : AppColors.rawEarth12,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withAlpha(200),
                  theme.colorScheme.primary,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : user.username[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.parchment,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : user.username,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Joined $dateStr',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        isDark ? AppColors.parchment70 : AppColors.rawEarth70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  statusText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(ThemeData theme, bool isDark) {
    final steps = [
      {
        'icon': Icons.share_rounded,
        'title': 'Share',
        'desc': 'Share your code with friends & family',
      },
      {
        'icon': Icons.person_add_rounded,
        'title': 'Join',
        'desc': 'They sign up and join the Anaad family',
      },
      {
        'icon': Icons.shopping_cart_rounded,
        'title': 'Order',
        'desc': 'They taste their first harvest',
      },
      {
        'icon': Icons.celebration_rounded,
        'title': 'Get Your Gift',
        'desc': 'Receive a surprise gift from Anaad team!',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withAlpha(12),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  color: AppColors.deepSoilGreen.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.deepSoilGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'How It Works',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withAlpha(200),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.parchment,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'] as String,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          step['desc'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                isDark
                                    ? AppColors.parchment70
                                    : AppColors.rawEarth70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    step['icon'] as IconData,
                    color: AppColors.harvestAmber,
                    size: 22,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
