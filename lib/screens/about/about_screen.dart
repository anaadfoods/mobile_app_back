import "package:grocery_app/common_widgets/global_import.dart";

class AboutScreen extends StatelessWidget {
  AboutScreen({super.key});

  final List<String> imageUrls = [
    'https://assets.zyrosite.com/cdn-cgi/image/format=auto,w=1920,fit=crop/A0xleG2zZeFjLgjV/slidescroll1-mk3vyrjar2sPvOrq.jpeg',
    'https://assets.zyrosite.com/cdn-cgi/image/format=auto,w=1920,fit=crop/A0xleG2zZeFjLgjV/slidescroll4-AQEx4R1bgGux12OX.jpeg',
    'https://assets.zyrosite.com/cdn-cgi/image/format=auto,w=1920,fit=crop/A0xleG2zZeFjLgjV/slidescroll2-YKb3aQpzGGU2ovZg.jpeg',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("About")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppColors.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Card
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppColors.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(
                        AppColors.shadowOpacityMedium,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=1974',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.black.withOpacity(0.2),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Image.asset(
                      'assets/anaad_logo.png',
                      height: 120,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'ANAAD',
                          style: TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppColors.spacingXL),

              // Highlights Section
              Text(
                "Anaad Highlights",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppColors.spacingL),
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
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Lorem ipsum dolor sit amet consectetur. Vitae adipiscing maecenas ultrices viverra tellus amet tincidunt. Turpis nullam sed neque ut sit lorem duis sed. Orci consequat cras cursus dui rutrum pellentesque sed id. Leo in mauris in habitant leo in aliquet purus tellus nam. Proin felis viverra in sed cursus.\n\nMorbi non feugiat ultricies et facilisis duis nulla. Amet eget sapien vulputate et rhoncus nisi curabitur est lectus. Ipsum ultrices lectus in aliquet purus tellus nam. Proin felis viverra in sed cursus.',
                  style: textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: AppColors.spacingXL),

              // Benefits Section
              Text(
                'Benefits',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppColors.spacingL),
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
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    _BenefitListItem(
                      text:
                          'Vestibulum sapien morbi fames morbi dui quisque enim.',
                    ),
                    _BenefitListItem(
                      text: 'Convallis amet ullamcorper pretium',
                    ),
                    _BenefitListItem(
                      text: 'Nibh scelerisque sed at egestas Sed',
                    ),
                    _BenefitListItem(text: 'Semper donec in arcu eget gravida'),
                    _BenefitListItem(text: 'Quis fermentum elementum auctor'),
                    _BenefitListItem(
                      text: 'Et commodo quis est mauris tempus et leo.',
                    ),
                    _BenefitListItem(
                      text:
                          'Facilisis ullamcorper eget tellus blandit pellentesque',
                    ),
                    _BenefitListItem(
                      text:
                          'Facilisis ullamcorper eget tellus blandit pellentesque',
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppColors.spacingXL),
              SustainabilitySection(),
              const SizedBox(height: AppColors.spacingL),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitListItem extends StatelessWidget {
  final String text;
  final bool isLast;
  const _BenefitListItem({required this.text, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppColors.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: AppColors.success, size: 16),
          ),
          const SizedBox(width: AppColors.spacingM),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
