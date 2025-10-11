import 'package:flutter/material.dart';
import 'package:grocery_app/screens/about/about_detail.dart';

class AboutScreen extends StatelessWidget {
  AboutScreen({super.key});

  final List<String> imageUrls = [
    'https://assets.zyrosite.com/cdn-cgi/image/format=auto,w=1920,fit=crop/A0xleG2zZeFjLgjV/slidescroll1-mk3vyrjar2sPvOrq.jpeg',
    'https://assets.zyrosite.com/cdn-cgi/image/format=auto,w=1920,fit=crop/A0xleG2zZeFjLgjV/slidescroll4-AQEx4R1bgGux12OX.jpeg',
    'https://assets.zyrosite.com/cdn-cgi/image/format=auto,w=1920,fit=crop/A0xleG2zZeFjLgjV/slidescroll2-YKb3aQpzGGU2ovZg.jpeg',
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("About"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Highlights Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  "Anaad Highlights",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              // About Us Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  "About Us",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Anaad is committed to delivering fresh, organic, and sustainable produce directly from farm to table. "
                  "We believe in transparency, eco-conscious farming, and empowering local communities through ethical practices.",
                  style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                ),
              ),

              const SizedBox(height: 32),

              // Sustainability Section
              const SustainabilitySection(),
            ],
          ),
        ),
      ),
    );
  }
}
