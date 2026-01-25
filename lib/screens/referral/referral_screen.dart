import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:share_plus/share_plus.dart';
import 'package:grocery_app/services/referral_reward_service.dart';
import 'package:grocery_app/models/referral_model.dart';
import 'package:intl/intl.dart';

class ReferAndEarnScreen extends StatefulWidget {
  const ReferAndEarnScreen({super.key});

  @override
  State<ReferAndEarnScreen> createState() => _ReferAndEarnScreenState();
}

class _ReferAndEarnScreenState extends State<ReferAndEarnScreen> {
  final ReferralRewardService _referralService = ReferralRewardService();
  ReferralData? _referralData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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

  String get referralCode => _referralData?.referralCode ?? "LOADING...";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Refer & Earn",
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchReferralData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppColors.spacingXL),
                  child: Column(
                    children: [
                      const SizedBox(height: AppColors.spacingL),

                      // Gift Icon with glow
                      Container(
                        padding: const EdgeInsets.all(AppColors.spacingXL),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.2),
                              blurRadius: 24,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.card_giftcard,
                          size: 60,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppColors.spacingXL),

                      // Title
                      Text(
                        "Share Health, Earn Trust",
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppColors.spacingM),

                      // Description
                      Text(
                        "Invite your friends and family to join the ANAAD community and earn rewards while spreading health.",
                        style: textTheme.bodyLarge?.copyWith(
                          color: theme.hintColor,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppColors.spacingXL),

                      // Stats Row
                      _buildStatsRow(theme, colorScheme, isDark),
                      const SizedBox(height: AppColors.spacingXL),

                      // Referral Code Card
                      _buildReferralCodeCard(
                        theme,
                        textTheme,
                        colorScheme,
                        isDark,
                      ),
                      const SizedBox(height: AppColors.spacingXL),

                      // Invite Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Share.share(
                              'Join me on ANAAD! Use my referral code: $referralCode to get exclusive benefits. Download now!',
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text("Invite Friends"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppColors.spacingL,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppColors.spacingXL),

                      // Share Options
                      Text(
                        'Share via',
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: AppColors.spacingL),
                      _buildShareOptions(context),
                      const SizedBox(height: AppColors.spacingXXL),

                      // Referred Users Section
                      if (_referralData != null &&
                          _referralData!.referredUsers.isNotEmpty)
                        _buildReferredUsersSection(
                          theme,
                          textTheme,
                          colorScheme,
                          isDark,
                        ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme: theme,
            colorScheme: colorScheme,
            isDark: isDark,
            icon: Icons.people_rounded,
            value: '${_referralData?.referralsCount ?? 0}',
            label: 'Total Referrals',
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme: theme,
            colorScheme: colorScheme,
            isDark: isDark,
            icon: Icons.card_giftcard_rounded,
            value:
                '${_referralData?.referredUsers.where((u) => u.status == 'ACCEPTED' || u.status == null).length ?? 0}',
            label: 'Rewards Earned',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isDark,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeCard(
    ThemeData theme,
    TextTheme textTheme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppColors.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusL),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Referral Code',
                  style: textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: AppColors.spacingXS),
                Text(
                  referralCode,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppColors.radiusM),
            ),
            child: IconButton(
              icon: Icon(Icons.copy, color: colorScheme.primary),
              onPressed: () {
                HapticFeedback.lightImpact();
                Clipboard.setData(ClipboardData(text: referralCode));
                SnackBarHelper.showSuccess(
                  context,
                  "Referral code copied to clipboard!",
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOptions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildShareButton(
          context,
          icon: Icons.chat,
          color: const Color(0xFF25D366),
          onPressed: () async {
            final message = Uri.encodeComponent(
              'Join me on ANAAD! Use my referral code: $referralCode',
            );
            final url = 'https://wa.me/?text=$message';
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url));
            } else {
              SnackBarHelper.showError(
                context,
                'No app found to open WhatsApp.',
              );
            }
          },
        ),
        const SizedBox(width: AppColors.spacingL),
        _buildShareButton(
          context,
          icon: Icons.facebook,
          color: const Color(0xFF4267B2),
          onPressed: () async {
            final fbUrl =
                'https://www.facebook.com/sharer/sharer.php?u=https://anaadfoods.com&quote=Join me on ANAAD! Use my referral code: $referralCode';
            if (await canLaunchUrl(Uri.parse(fbUrl))) {
              await launchUrl(Uri.parse(fbUrl));
            } else {
              SnackBarHelper.showError(
                context,
                'No app found to open Facebook.',
              );
            }
          },
        ),
        const SizedBox(width: AppColors.spacingL),
        _buildShareButton(
          context,
          icon: Icons.email,
          color: const Color(0xFFDD4B39),
          onPressed: () async {
            final subject = Uri.encodeComponent('Join me on ANAAD!');
            final body = Uri.encodeComponent(
              'Use my referral code: $referralCode',
            );
            final emailUrl = 'mailto:?subject=$subject&body=$body';
            if (await canLaunchUrl(Uri.parse(emailUrl))) {
              await launchUrl(Uri.parse(emailUrl));
            } else {
              SnackBarHelper.showError(context, 'No app found to open email.');
            }
          },
        ),
      ],
    );
  }

  Widget _buildShareButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 28),
        onPressed: onPressed,
        padding: const EdgeInsets.all(AppColors.spacingM),
      ),
    );
  }

  Widget _buildReferredUsersSection(
    ThemeData theme,
    TextTheme textTheme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.people_alt_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Your Referrals',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_referralData!.referredUsers.length}',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...(_referralData!.referredUsers.asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;
          return _buildReferredUserCard(
            theme,
            textTheme,
            colorScheme,
            isDark,
            user,
            index,
          );
        })),
      ],
    );
  }

  Widget _buildReferredUserCard(
    ThemeData theme,
    TextTheme textTheme,
    ColorScheme colorScheme,
    bool isDark,
    ReferredUser user,
    int index,
  ) {
    final statusColor = _getStatusColor(user.status);
    final statusText = user.status ?? 'Active';
    final formattedDate = DateFormat('MMM d, yyyy').format(user.dateJoined);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.8),
                  colorScheme.primary.withOpacity(0.6),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : user.username[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : user.username,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: theme.hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Joined $formattedDate',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.green;
      default:
        return Colors.green; // Default to green for active users
    }
  }
}

