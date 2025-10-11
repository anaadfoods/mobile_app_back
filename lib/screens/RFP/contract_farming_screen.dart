import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/imput_widget.dart';
import 'package:grocery_app/screens/RFP/delivery_screen.dart';
import 'package:grocery_app/styles/colors.dart';





class CombinedScreen extends StatelessWidget {
  const CombinedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ToxinFreeScreen(),
            SizedBox(height: 20),
            ContractFarmingScreen(),
          ],
        ),
      ),
    );
  }
}


Future<void> _showNotificationForm(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        // Added shape for rounded corners to match the form fields
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        
        // 1. Title is wrapped in a Center widget
        title: Column(
          children: [
            Center(
              child: Text("Register Here",style: TextStyle(
                color: Colors.white,
                fontSize: 16
              ),
              
              ),
            ),
            Center(
              child: Text("Stay here" , style: TextStyle(
                fontSize: 12,
                color: Colors.white
              ),),
            )
          ],
        ),
        backgroundColor: AppColors.primaryColor,

        // 2. Content is wrapped in a SizedBox to control the width
        content: SizedBox(
          width: double.maxFinite, // Makes the dialog use the available width
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  CustomInput(
                    height: 60,
                    borderRadius: BorderRadius.circular(25),
                    hintText: "Full name*",
                    controller: _nameController,
                    keyboardType: TextInputType.name, // Changed to name
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  CustomInput(
                    height: 60,
                    borderRadius: BorderRadius.circular(25),
                    hintText: "Email",
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  CustomInput(
                    hintText: "Phone number",
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                  ),
                  CustomInput(
                    hintText: "Message",
                    controller: _messageController,
                    keyboardType: TextInputType.text,
                    validator: (v) {
                      if (v!.isEmpty) return 'Enter a message';
                      return null;
                    },
                  )
                ],
              ),
            ),
          ),
        ),
        actions: [
          // 3. Button is wrapped to control its width and padding
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
            child: SizedBox(
              width: double.infinity, // Makes the button stretch
              child: ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                  }
                  Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const DeliveryScreen()),
);


                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.bottonBackgroundColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)
                  )
                ),
                child: Text('Submit'),
              ),
            ),
          ),
        ],
        // Reduces default padding around the actions
        actionsPadding: EdgeInsets.zero,
      );
    },
  );
}


// --- First Screen: The Promise of a Toxin-Free Plate ---
class ToxinFreeScreen extends StatelessWidget {
  const ToxinFreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using a SafeArea here to avoid the top notch on some devices
    return SafeArea(
      top: false, // We want the image to go to the very top
      child: Column(
        children: [
          _buildHeader(context),
          _buildContentBody(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                  'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=1974&auto=format&fit=crop'),
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
        Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 25,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The Promise of a Toxin-Free Plate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The Promise of a Toxin-Free Plate. We believe your family deserves better. Our RFP service beyond organic, it\'s a promise of purity.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                                    _showNotificationForm(context);

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:AppColors.bottonBackgroundColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Click to Register',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentBody(BuildContext context) {
    return Container(
      // transform: Matrix4.translationValues(0.0, -30.0, 0.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      margin: EdgeInsets.only(top: 20),
      child: Column(
        children: [
           const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _InfoCard(
                    imageUrl: 'https://images.unsplash.com/photo-1563203432-345337a36416?q=80&w=1964&auto=format&fit=crop',
                    title: 'Your Family, Mini Farm',
                    description: 'Based on your family size and consumption patterns, a specific section of our farm is dedicated exclusively to you.',
                    titleColor: Colors.white,
                  )),
                  SizedBox(width: 16),
                  Expanded(child: _InfoCard(
                    imageUrl: 'https://images.unsplash.com/photo-1599599810694-b5b37304c847?q=80&w=2070&auto=format&fit=crop',
                    title: 'Your Farmer,\nYour Food',
                    description: 'This is not generic farming. This is your personal mini-farming and cared for by a farmer dedicated solely to you.',
                    titleColor: Colors.white,
                    cardColor: Color(0xFF1B5E20), // Dark Green
                  )),
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
                _FeatureItem(icon: Icons.home_work_outlined, title: 'Dedicated Family Farmer', subtitle: 'Meet the farmer who grows only for you.'),
                _FeatureItem(icon: Icons.agriculture_outlined, title: 'Free Farm Visits', subtitle: 'Connect with the land and your food.'),
                _FeatureItem(icon: Icons.camera_alt_outlined, title: 'Real-Time Updates', subtitle: 'Get photo & video updates of your crops.'),
                _FeatureItem(icon: Icons.access_time, title: 'Early Product Access', subtitle: 'Be the first to try our new launches.'),
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
  final Color titleColor;
  final Color? cardColor;

  const _InfoCard({
    required this.imageUrl,
    required this.title,
    required this.description,
    this.titleColor = Colors.white,
    this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        image: cardColor == null ? DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ) : null,
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
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: titleColor.withOpacity(0.8),
                fontSize: 12,
                height: 1.4,
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 170),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bottonBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black , fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// --- Second Screen: Contract Farming ---
class ContractFarmingScreen extends StatelessWidget {
  const ContractFarmingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: Image.network(
            'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?q=80&w=2070&auto=format&fit=crop',
            fit: BoxFit.cover,
            loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.error, color: Colors.red, size: 50),
          ),
        ),
        Container(
          padding: EdgeInsets.all(
             20
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 15,
              ),
            ],
          ),
          child: 
          // LayoutBuilder(
          //   builder: (context, constraints) {
          //     if (constraints.maxWidth > 600) {
          //       return 
                _buildWideLayout()
          //     } else {
          //       return _buildNarrowLayout();
          //     }
          //   },
          // ),
        ),
      Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 32.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                                                    _showNotificationForm(context);

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bottonBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Click to Register',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
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
        Expanded(
          flex: 2,
          child: _InfoSection(),
        ),
        SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _TimelineSection(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return const Column(
      children: [
        _InfoSection(),
        SizedBox(height: 32),
        _TimelineSection(),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contract Farming with Absolute Transparency.',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
        ),
        const SizedBox(height: 10),
        Text(
          'For businesses that demand the best, Anaad offers a groundbreaking contract farming solution. We work closely with you to understand your exact requirements and dedicate land and resources to fulfill your needs. You get unparalleled transparency, from seed to supply chain.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 10),
        Text(
          'Morbi non feugiat ultricies et facilisis duis nulla. Amet eget sapien vulputate et rhoncus nisi curabitur est lectus. Ipsum ultrices lectus in aliquet purus tellus nam. Proin felis viverra in sed cursus.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text(
          'Key Advantages',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
          subtitle: 'Partner with us for reliable and ethical sourcing solutions.',
        ),
      ],
    );
  }
}

class _AdvantageItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AdvantageItem({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, color: AppColors.bottonBackgroundColor, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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
            icon: Icons.agriculture_outlined, label: 'Contract Farming'),
        _TimelineConnector(),
        _TimelineStep(
            icon: Icons.location_searching, label: 'Transparent Tracking'),
        _TimelineConnector(),
        _TimelineStep(
            icon: Icons.inventory_2_outlined, label: 'Consistent Supply'),
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFB9A275), size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 2,
      child: Column(
        children: [
          Expanded(child: Container(color: Colors.grey[300])),
          Icon(Icons.arrow_downward, color: Colors.grey[400], size: 16),
          Expanded(child: Container(color: Colors.grey[300])),
        ],
      ),
    );
  }
}

