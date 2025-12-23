import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:http/http.dart' as http;

class CombinedScreen extends StatelessWidget {
  const CombinedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toxin-Free & Contract Farming')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ToxinFreeScreen(),
            const SizedBox(height: 20),
            ContractFarmingScreen(),
          ],
        ),
      ),
    );
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
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: theme.colorScheme.primary,
            title: Center(
              child: Text(
                "Register Your Interest",
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
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
                      const SizedBox(height: 15),
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
                      const SizedBox(height: 15),
                      CustomInput(
                        hintText: "Email (Optional)",
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        onPrimary: true,
                      ),
                      const SizedBox(height: 15),
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
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRequirementType,
                        decoration: const InputDecoration(
                          labelText: 'Requirement Type',
                          fillColor: AppColors.primaryColor,
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        final bool isFromRfp = selectedRequirementType == 'B2B';
                        try {
                          final response = await http.post(
                            Uri.parse('${ApiConfig.baseUrl}/api/user-queries/'),
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

class ToxinFreeScreen extends StatelessWidget {
  const ToxinFreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [_buildHeader(context), _buildContentBody(context)],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Container(
          height: 350,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            image: DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=1974&auto=format&fit=crop',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: 350,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
        ),
        // Positioned(
        //   top: 50,
        //   left: 16,
        //   right: 16,
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       IconButton(
        //         icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        //         onPressed: () {
        //           Navigator.pop(context);
        //         },
        //       ),
        //     ],
        //   ),
        // ),
        Positioned(
          bottom: 25,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The Promise of a Toxin-Free Plate',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We believe your family deserves better. Our RFP service beyond organic, it\'s a promise of purity.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _showNotificationForm(context);
                },
                child: const Text('Click to Register'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentBody(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: _InfoCard(
                  imageUrl:
                      'https://images.unsplash.com/photo-1563203432-345337a36416?q=80&w=1964&auto=format&fit=crop',
                  title: 'Your Family, Mini Farm',
                  description:
                      'Based on your family size and consumption patterns, a specific section of our farm is dedicated exclusively to you.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoCard(
                  imageUrl:
                      'https://images.unsplash.com/photo-1599599810694-b5b37304c847?q=80&w=2070&auto=format&fit=crop',
                  title: 'Your Farmer,\nYour Food',
                  description:
                      'This is not generic farming. This is your personal mini-farming and cared for by a farmer dedicated solely to you.',
                  cardColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Wrap(
              spacing: 16,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _FeatureItem(
                  icon: Icons.home_work_outlined,
                  title: 'Dedicated Family Farmer',
                  subtitle: 'Meet the farmer who grows only for you.',
                ),
                _FeatureItem(
                  icon: Icons.agriculture_outlined,
                  title: 'Free Farm Visits',
                  subtitle: 'Connect with the land and your food.',
                ),
                _FeatureItem(
                  icon: Icons.camera_alt_outlined,
                  title: 'Real-Time Updates',
                  subtitle: 'Get photo & video updates of your crops.',
                ),
                _FeatureItem(
                  icon: Icons.access_time,
                  title: 'Early Product Access',
                  subtitle: 'Be the first to try our new launches.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final Color? cardColor;

  const _InfoCard({
    required this.imageUrl,
    required this.title,
    required this.description,
    this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        image:
            cardColor == null
                ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                )
                : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.1),
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 170),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.onPrimary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContractFarmingScreen extends StatelessWidget {
  const ContractFarmingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: Image.network(
            'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?q=80&w=2070&auto=format&fit=crop',
            fit: BoxFit.cover,
            loadingBuilder: (
              BuildContext context,
              Widget child,
              ImageChunkEvent? loadingProgress,
            ) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                ),
              );
            },
            errorBuilder:
                (context, error, stackTrace) =>
                    Icon(Icons.error, color: theme.colorScheme.error, size: 50),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 15,
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return _buildWideLayout();
              } else {
                return _buildNarrowLayout();
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 32.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showNotificationForm(context);
              },
              child: const Text('Click to Register'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _InfoSection()),
        SizedBox(width: 24),
        Expanded(flex: 1, child: _TimelineSection()),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return const Column(
      children: [_InfoSection(), SizedBox(height: 32), _TimelineSection()],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contract Farming with Absolute Transparency.',
          style: theme.textTheme.headlineSmall?.copyWith(height: 1.2),
        ),
        const SizedBox(height: 10),
        Text(
          'For businesses that demand the best, Anaad offers a groundbreaking contract farming solution. We work closely with you to understand your exact requirements and dedicate land and resources to fulfill your needs. You get unparalleled transparency, from seed to supply chain.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 24),
        Text('Key Advantages', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        const _AdvantageItem(
          title: 'Utmost Transparency',
          subtitle: 'Know exactly where, when, and how your produce is grown.',
        ),
        const _AdvantageItem(
          title: 'Consistent Quality & Supply',
          subtitle: 'Eliminate unpredictability with a dedicated supply line.',
        ),
        const _AdvantageItem(
          title: 'Sourced with Trust',
          subtitle:
              'Partner with us for reliable and ethical sourcing solutions.',
        ),
      ],
    );
  }
}

class _AdvantageItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AdvantageItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, color: theme.colorScheme.primary, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _TimelineStep(icon: Icons.chat_bubble_outline, label: 'Consultation'),
        _TimelineConnector(),
        _TimelineStep(
          icon: Icons.agriculture_outlined,
          label: 'Contract Farming',
        ),
        _TimelineConnector(),
        _TimelineStep(
          icon: Icons.location_searching,
          label: 'Transparent Tracking',
        ),
        _TimelineConnector(),
        _TimelineStep(
          icon: Icons.inventory_2_outlined,
          label: 'Consistent Supply',
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TimelineStep({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      width: 2,
      child: Column(
        children: [
          Expanded(child: Container(color: theme.dividerColor)),
          Icon(Icons.arrow_downward, color: theme.dividerColor, size: 16),
          Expanded(child: Container(color: theme.dividerColor)),
        ],
      ),
    );
  }
}
