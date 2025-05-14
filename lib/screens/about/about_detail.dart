import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SustainabilitySection extends StatelessWidget {
  const SustainabilitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFF2F4F4F), // Dark green background
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Sustainability',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
      
            // Subtitle
            const Text(
              'Discover the benefits of choosing naturally\n'
              'grown ingredients for your health',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
      
            // Social Icons
            Row(
              children: const [
                Icon(FontAwesomeIcons.facebookF, color: Colors.white, size: 20),
                SizedBox(width: 16),
                Icon(FontAwesomeIcons.instagram, color: Colors.white, size: 20),
                SizedBox(width: 16),
                Icon(FontAwesomeIcons.linkedinIn, color: Colors.white, size: 20),
                SizedBox(width: 16),
                Icon(FontAwesomeIcons.xTwitter, color: Colors.white, size: 20),
              ],
            ),
            const SizedBox(height: 24),
      
            // Contact Header
            const Text(
              'Contact',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
      
            // Contact Details
            const Text(
              'connect@anaadfoods.com\n'
              '+91 9996166186\n'
              'Anaad, Farmlands of, Bhuri, Sonipat, Haryana\n131001',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
      
            // Inquiry Header
            const Text(
              'Inquiry',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your email address here',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
      
            // Email Input
            TextField(
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'example@example.com',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            const SizedBox(height: 16),
      
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BC34A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  // Handle inquiry submission
                },
                child: const Text(
                  'Submit your inquiry now',
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
      
            const SizedBox(height: 24),
      
            // Footer
            const Text(
              '© 2025. All rights reserved.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
