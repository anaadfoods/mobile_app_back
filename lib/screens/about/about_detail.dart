import "package:grocery_app/common_widgets/global_import.dart";

class SustainabilitySection extends StatelessWidget {
  const SustainabilitySection({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // You can show a snackbar or toast here if the launch fails
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      child: Container(
        color: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sustainability',
              style: textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Discover the benefits of choosing naturally\n'
              'grown ingredients for your health',
              style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.8)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _launchURL('https://www.facebook.com/anaadfoods1'),
                  icon: Icon(FontAwesomeIcons.facebookF, color: theme.colorScheme.onPrimary, size: 20),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _launchURL('https://www.instagram.com/anaadfoods'),
                  icon: Icon(FontAwesomeIcons.instagram, color: theme.colorScheme.onPrimary, size: 20),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _launchURL('https://www.linkedin.com/company/anaad-anhad-naad-foods/'),
                  icon: Icon(FontAwesomeIcons.linkedinIn, color: theme.colorScheme.onPrimary, size: 20),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _launchURL('https://x.com/AnaadFoods'),
                  icon: Icon(FontAwesomeIcons.xTwitter, color: theme.colorScheme.onPrimary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Contact',
              style: textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'connect@anaadfoods.com\n'
              '+91 9996166186\n'
              'Anaad, Farmlands of, Bhuri, Sonipat, Haryana\n131001',
              style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.8)),
            ),
            const SizedBox(height: 24),
            Text(
              '© 2025. All rights reserved.',
              style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
