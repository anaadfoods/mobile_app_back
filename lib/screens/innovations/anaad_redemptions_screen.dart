import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

class AnaadRedemptionsScreen extends StatefulWidget {
  const AnaadRedemptionsScreen({super.key});

  @override
  State<AnaadRedemptionsScreen> createState() => _AnaadRedemptionsScreenState();
}

class _AnaadRedemptionsScreenState extends State<AnaadRedemptionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  final int _pointsBalance = 250;

  // Demo rewards data
  final List<Map<String, dynamic>> _rewards = [
    {
      'name': 'Free Organic Honey (250g)',
      'points': 100,
      'image': Icons.fastfood_rounded,
    },
    {
      'name': 'Ghee Pack (500ml)',
      'points': 200,
      'image': Icons.local_cafe_rounded,
    },
    {'name': 'Premium Spice Bundle', 'points': 150, 'image': Icons.spa_rounded},
    {'name': 'Fresh Vegetables Box', 'points': 80, 'image': Icons.eco_rounded},
    {
      'name': 'Natural Cold-Pressed Oil',
      'points': 250,
      'image': Icons.water_drop_rounded,
    },
  ];

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
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.parchment : AppColors.parchment,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.parchment : AppColors.charcoal87,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Anaad Redemptions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.parchment : AppColors.charcoal87,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Points Balance Card
            _buildPointsCard(theme, isDark),
            const SizedBox(height: 24),

            // How to Earn Section
            _buildHowToEarnSection(theme, isDark),
            const SizedBox(height: 24),

            // Available Rewards
            Text(
              'Redeem Your Points',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Rewards List
            ...List.generate(_rewards.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRewardCard(theme, isDark, _rewards[index], index),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.parchment, AppColors.parchment],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.parchment.withValues(alpha: 0.4),
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
                        AppColors.parchment.withValues(alpha: 0.1),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.parchment.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.wallet_giftcard_rounded,
                          color: AppColors.parchment,
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.parchment.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Available Balance',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.parchment,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$_pointsBalance Points',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: AppColors.parchment,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '= ₹${(_pointsBalance * 0.5).toStringAsFixed(0)} value',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.parchment.withValues(alpha: 0.8),
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

  Widget _buildHowToEarnSection(ThemeData theme, bool isDark) {
    final earnWays = [
      {
        'icon': Icons.shopping_bag_rounded,
        'title': 'Order',
        'desc': '1 point per ₹10',
      },
      {'icon': Icons.share_rounded, 'title': 'Refer', 'desc': '50 points each'},
      {
        'icon': Icons.rate_review_rounded,
        'title': 'Review',
        'desc': '10 points each',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.parchment : AppColors.parchment,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to Earn Points',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                earnWays.map((way) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.parchment.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          way['icon'] as IconData,
                          color: AppColors.parchment,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        way['title'] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        way['desc'] as String,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              isDark
                                  ? AppColors.rawEarth26
                                  : AppColors.rawEarth70,
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(
    ThemeData theme,
    bool isDark,
    Map<String, dynamic> reward,
    int index,
  ) {
    final canRedeem = _pointsBalance >= (reward['points'] as int);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.parchment : AppColors.parchment,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      canRedeem
                          ? AppColors.parchment.withValues(alpha: 0.3)
                          : AppColors.rawEarth54.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        canRedeem
                            ? AppColors.parchment.withValues(alpha: 0.1)
                            : AppColors.charcoal.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (canRedeem
                              ? AppColors.parchment
                              : AppColors.rawEarth54)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      reward['image'] as IconData,
                      color:
                          canRedeem
                              ? AppColors.parchment
                              : AppColors.rawEarth54,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward['name'] as String,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reward['points']} points',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                canRedeem
                                    ? AppColors.parchment
                                    : AppColors.rawEarth54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap:
                        canRedeem
                            ? () {
                              HapticFeedback.mediumImpact();
                              SnackBarHelper.showSuccess(
                                context,
                                "Woohoo! ${reward['name']} redeemed! 🎁",
                              );
                            }
                            : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            canRedeem
                                ? AppColors.parchment
                                : AppColors.rawEarth54.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        canRedeem ? 'Redeem' : 'Locked',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.parchment,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
