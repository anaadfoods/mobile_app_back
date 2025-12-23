import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/common_widgets/global_import.dart' as http;

class CommunityDetailScreen extends StatelessWidget {
  final Community community;
  const CommunityDetailScreen({super.key, required this.community});

  // --- All original validation logic is preserved ---
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );
  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!_emailRegex.hasMatch(value))
      return 'Please enter a valid email address';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your phone number';
    String cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    if (!_phoneRegex.hasMatch(cleanPhone))
      return 'Please enter a valid 10-digit phone number';
    return null;
  }

  Future<void> _showNotificationForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final messageController = TextEditingController();

    // Get theme properties to use inside the dialog
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusXL),
          ),
          title: Center(
            child: Text(
              'Stay Updated',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          backgroundColor: colorScheme.primary,
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomInput(
                      height: 60,
                      borderRadius: BorderRadius.circular(AppColors.radiusM),
                      hintText: "Name*",
                      controller: nameController,
                      keyboardType: TextInputType.name,
                      onPrimary: true,
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Please enter your name'
                                  : null,
                    ),
                    const SizedBox(height: AppColors.spacingL),
                    CustomInput(
                      height: 60,
                      borderRadius: BorderRadius.circular(AppColors.radiusM),
                      hintText: "Email*",
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      onPrimary: true,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: AppColors.spacingL),
                    CustomInput(
                      hintText: "Phone number*",
                      controller: phoneController,
                      keyboardType: TextInputType.number,
                      onPrimary: true,
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: AppColors.spacingL),
                    CustomInput(
                      hintText: "Message*",
                      controller: messageController,
                      keyboardType: TextInputType.text,
                      onPrimary: true,
                      validator: (v) => v!.isEmpty ? 'Enter a message' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppColors.spacingL,
                0,
                AppColors.spacingL,
                AppColors.spacingL,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      try {
                        final response = await http.post(
                          Uri.parse(
                            '${ApiConfig.baseUrl}/api/core/communities/${community.name}/subscribe/',
                          ),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'name': nameController.text,
                            'email': emailController.text,
                            'phone': phoneController.text,
                            'message': messageController.text,
                          }),
                        );
                        if (!context.mounted) return;
                        if (response.statusCode == 200 ||
                            response.statusCode == 201) {
                          Navigator.pop(context);
                          SnackBarHelper.showSuccess(
                            context,
                            'Thank you! We\'ll keep you updated.',
                          );
                        } else {
                          throw Exception('Failed to submit form');
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        SnackBarHelper.showError(
                          context,
                          'Failed to submit. Please try again later.',
                        );
                      }
                    }
                  },
                  child: const Text('Submit'),
                ),
              ),
            ),
          ],
          actionsPadding: EdgeInsets.zero,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppColors.spacingM,
                  vertical: AppColors.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(AppColors.radiusS),
                ),
                child: Text(
                  community.name,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    community.image,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          color: colorScheme.primary,
                          child: const Icon(
                            Icons.eco,
                            size: 80,
                            color: Colors.white24,
                          ),
                        ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(AppColors.spacingS),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppColors.spacingXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coming Soon Badge
                  if (community.comingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppColors.spacingM,
                        vertical: AppColors.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusRound,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Coming Soon",
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppColors.spacingXS),
                          const Icon(Icons.eco, size: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppColors.spacingXL),

                  // Description Card
                  Container(
                    padding: const EdgeInsets.all(AppColors.spacingXL),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(AppColors.radiusL),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: AppColors.spacingS),
                            Text(
                              'About',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppColors.spacingM),
                        Text(
                          community.description,
                          style: textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color:
                                isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppColors.spacingXL),

                  // Benefits Card
                  Container(
                    padding: const EdgeInsets.all(AppColors.spacingXL),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(AppColors.radiusL),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star_outline,
                              color: AppColors.orderPlaced,
                              size: 20,
                            ),
                            const SizedBox(width: AppColors.spacingS),
                            Text(
                              'Benefits',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppColors.spacingM),
                        ..._buildBenefitsList(context, community.benefits),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppColors.spacingXXL),

                  // Notify Me Button
                  if (community.comingSoon)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showNotificationForm(context),
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('Notify Me When Available'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppColors.spacingL,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppColors.spacingXL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBenefitsList(BuildContext context, String benefits) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final items =
        benefits
            .split(RegExp(r'\n|•'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    if (items.length <= 1) {
      return [
        Text(benefits, style: textTheme.bodyMedium?.copyWith(height: 1.6)),
      ];
    }

    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppColors.spacingS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppColors.spacingM),
                Expanded(
                  child: Text(
                    item,
                    style: textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}
