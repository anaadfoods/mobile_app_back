import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:share_plus/share_plus.dart';

class ReferAndEarnScreen extends StatelessWidget {
  final String referralCode = "ANAAD2025";

  const ReferAndEarnScreen({super.key});

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppColors.spacingXL),
        child: Column(
          children: [
            const SizedBox(height: AppColors.spacingXL),

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
            const SizedBox(height: AppColors.spacingXXL),

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
            const SizedBox(height: AppColors.spacingXXL),

            // Referral Code Card
            Container(
              padding: const EdgeInsets.all(AppColors.spacingL),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppColors.radiusL),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(
                      AppColors.shadowOpacityLight,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
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
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppColors.radiusM),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.copy, color: colorScheme.primary),
                      onPressed: () {
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
            ),
            const SizedBox(height: AppColors.spacingXXL),

            // Invite Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Share.share(
                    'Join me on ANAAD! Use my referral code: $referralCode',
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
            const SizedBox(height: AppColors.spacingXXL),

            // Share Options
            Text(
              'Share via',
              style: textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: AppColors.spacingL),
            Row(
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
                      SnackBarHelper.showError(
                        context,
                        'No app found to open email.',
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
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
}
