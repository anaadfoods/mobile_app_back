import 'package:grocery_app/common_widgets/global_import.dart';

class UserProfileSummaryCard extends StatelessWidget {
  final bool isDark;
  final String? userName;
  final String? profileImageUrl;
  final String? dateOfBirth;
  final String? timeOfBirth;
  final String? birthCity;
  final String? primaryDosha;
  final String? onboardingStatus;
  final VoidCallback? onEditProfile;

  const UserProfileSummaryCard({
    super.key,
    required this.isDark,
    this.userName,
    this.profileImageUrl,
    this.dateOfBirth,
    this.timeOfBirth,
    this.birthCity,
    this.primaryDosha,
    this.onboardingStatus,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasProfile = dateOfBirth != null && dateOfBirth!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (userName != null && userName!.trim().isNotEmpty && userName != 'User Profile' && userName != 'User')
                          ? "${userName!.trim()}'s Wellness Profile"
                          : 'Your Wellness Profile',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Birth Details & Prakriti Overview',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (hasProfile)
            _buildProfileData(context, theme)
          else
            _buildEmptyState(context, theme),
        ],
      ),
    );
  }

  Widget _buildProfileData(BuildContext context, ThemeData theme) {
    final displayName = (userName != null && userName!.trim().isNotEmpty && userName != 'User Profile')
        ? userName!.trim()
        : 'User Profile';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
              child: profileImageUrl == null
                  ? Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.cake_outlined, size: 12, color: theme.hintColor),
                      const SizedBox(width: 4),
                      Text(
                        '$dateOfBirth${timeOfBirth != null ? ', $timeOfBirth' : ''}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (birthCity != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: theme.hintColor),
                        const SizedBox(width: 4),
                        Text(birthCity!, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (primaryDosha != null && primaryDosha!.isNotEmpty)
              _buildDoshaBadge(theme),
            if (primaryDosha != null && primaryDosha!.isNotEmpty)
              const SizedBox(width: 12),
            _buildStatusIndicator(theme),
          ],
        ),
      ],
    );
  }

  Widget _buildDoshaBadge(ThemeData theme) {
    final doshaStr = primaryDosha!.toUpperCase();
    Color badgeColor = AppColors.deepSoilGreen;
    if (doshaStr == 'PITTA') {
      badgeColor = AppColors.harvestAmber;
    } else if (doshaStr == 'VATA') {
      badgeColor = isDark ? AppColors.infoTeal : AppColors.infoTeal;
    } else if (doshaStr == 'KAPHA') {
      badgeColor = AppColors.deepSoilGreen;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.spa, size: 14, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            'Primary: $doshaStr',
            style: theme.textTheme.labelSmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(ThemeData theme) {
    final hasBirthDetails = dateOfBirth != null && dateOfBirth!.isNotEmpty;
    final isDone = onboardingStatus == 'COMPLETE' ||
        onboardingStatus == 'QUIZ_DONE' ||
        (hasBirthDetails && (primaryDosha != null && primaryDosha!.isNotEmpty));
    final statusColor = isDone ? AppColors.successGreen : AppColors.amberWarn;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.pending_outlined,
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 5),
          Text(
            isDone ? 'Profile Complete' : 'Incomplete',
            style: theme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete your birth details to unlock personalized Ayurvedic and Astrological insights.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: onEditProfile ?? () {
            context.push('/kundli-input');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
            foregroundColor: isDark ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: const Icon(Icons.edit_calendar_rounded, size: 18),
          label: const Text('Complete Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
