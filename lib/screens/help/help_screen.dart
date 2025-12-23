import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:http/http.dart' as http;

class HelpScreen extends StatelessWidget {
  final String? orderNumber;

  const HelpScreen({super.key, this.orderNumber});

  Future<void> _launchPhoneCall(
    BuildContext context,
    String phoneNumber,
  ) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch $phoneUri';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer.')),
      );
    }
  }

  Future<void> _launchEmail(BuildContext context, String emailAddress) async {
    String subject =
        orderNumber != null
            ? 'Support Request for Order #$orderNumber'
            : 'Support Request';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch $emailUri';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String phoneNumber) async {
    final String message =
        orderNumber != null
            ? 'Hello, I need help with my order #$orderNumber.'
            : 'Hello, I need help.';

    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $whatsappUri';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
    }
  }

  Future<void> _showNotificationForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final messageController = TextEditingController();
    final theme = Theme.of(context);

    String selectedRequirementType = 'NORMAL';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusXL),
              ),
              backgroundColor: theme.colorScheme.primary,
              title: Center(
                child: Text(
                  "Share Your Query",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomInput(
                          hintText: "Full name*",
                          controller: nameController,
                          keyboardType: TextInputType.name,
                          onPrimary: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppColors.spacingL),
                        CustomInput(
                          hintText: "Phone number*",
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          onPrimary: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppColors.spacingL),
                        CustomInput(
                          hintText: "Email (Optional)",
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          onPrimary: true,
                        ),
                        const SizedBox(height: AppColors.spacingL),
                        CustomInput(
                          hintText: "Message*",
                          controller: messageController,
                          keyboardType: TextInputType.text,
                          onPrimary: true,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Please enter a message';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppColors.spacingL),
                        DropdownButtonFormField<String>(
                          initialValue: selectedRequirementType,
                          decoration: const InputDecoration(
                            labelText: 'Requirement Type',
                          ),
                          items:
                              ['NORMAL', 'B2B'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                          onChanged: (newValue) {
                            setDialogState(() {
                              selectedRequirementType = newValue!;
                            });
                          },
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

                          final bool isFromRfp =
                              selectedRequirementType == 'B2B';

                          try {
                            final response = await http.post(
                              Uri.parse(
                                '${ApiConfig.baseUrl}/api/user-queries/',
                              ),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'name': nameController.text,
                                'phone_number': phoneController.text,
                                'email': emailController.text,
                                'message': messageController.text,
                                'requirement_type': selectedRequirementType,
                                'is_from_rfp': isFromRfp,
                              }),
                            );

                            if (!context.mounted) return;

                            if (response.statusCode == 200 ||
                                response.statusCode == 201) {
                              Navigator.pop(context);
                              SnackBarHelper.showSuccess(
                                context,
                                'Thank you for your query! We will get back to you shortly.',
                              );
                            } else {
                              throw Exception(
                                'Failed to submit form: ${response.body}',
                              );
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Journey Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppColors.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Connect with Our Guides'),
            const SizedBox(height: AppColors.spacingL),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildContactCard(
                    context: context,
                    icon: Icons.mail_outline,
                    title: 'Speak with a Guide',
                    subtitle: 'For immediate assistance.',
                    color: Colors.blue,
                    onTap:
                        () =>
                            _launchEmail(context, 'complaints@anaadfoods.com'),
                  ),
                  const SizedBox(width: AppColors.spacingM),
                  _buildContactCard(
                    context: context,
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat Us Direct',
                    subtitle: 'Chat on WhatsApp.',
                    color: Colors.green,
                    onTap: () => _launchWhatsApp(context, '919996166186'),
                  ),
                  const SizedBox(width: AppColors.spacingM),
                  _buildContactCard(
                    context: context,
                    icon: Icons.phone_outlined,
                    title: 'Call Us',
                    subtitle: 'Talk to our team directly.',
                    color: Colors.orange,
                    onTap: () => _launchPhoneCall(context, '9996166186'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColors.spacingXXL),
            _buildSectionHeader(context, 'Guidance for Your Path'),
            const SizedBox(height: AppColors.spacingL),
            Container(
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
              child: const Column(
                children: [
                  _FaqExpansionTile(
                    title: 'Track Your Conscious Delivery?',
                    content: 'Details about tracking will be shown here.',
                  ),
                  _FaqExpansionTile(
                    title: 'Understanding Your Delivery Timeline',
                    content: 'Details about timelines will be shown here.',
                  ),
                  _FaqExpansionTile(
                    title: 'Adjusting Your Journey (Cancellations)',
                    content: 'Details about cancellations will be shown here.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColors.spacingXXL),
            _buildSectionHeader(context, 'Deepen for Understanding'),
            const SizedBox(height: AppColors.spacingL),
            _buildQueryCard(
              context: context,
              onTap: () {
                _showNotificationForm(context);
              },
            ),
            const SizedBox(height: AppColors.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(AppColors.spacingL),
        height: 130,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppColors.spacingS),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppColors.radiusS),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppColors.spacingXS),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueryCard({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.spacingXL),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppColors.radiusL),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(AppColors.shadowOpacityLight),
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
              Container(
                padding: const EdgeInsets.all(AppColors.spacingM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppColors.radiusS),
                ),
                child: Icon(
                  Icons.help_outline,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppColors.spacingL),
              Expanded(
                child: Text(
                  'Share Your Query',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spacingM),
          Text(
            "Couldn't find what you were looking for? Tell us how we can assist.",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: AppColors.spacingXL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              child: const Text('Fill Out Our Form'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqExpansionTile extends StatelessWidget {
  final String title;
  final String content;
  const _FaqExpansionTile({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      iconColor: theme.colorScheme.primary,
      collapsedIconColor: theme.hintColor,
      tilePadding: const EdgeInsets.symmetric(
        horizontal: AppColors.spacingL,
        vertical: AppColors.spacingXS,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppColors.spacingL,
            0,
            AppColors.spacingL,
            AppColors.spacingL,
          ),
          child: Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.hintColor,
            ),
          ),
        ),
      ],
    );
  }
}
