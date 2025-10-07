import 'package:flutter/material.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/screens/dashboard/dashboard_screen.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final List<String> imagePath = [
    "assets/images/OnBoarding/onboarding1.jpg",
    "assets/images/OnBoarding/onboarding2.jpg",
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Stack(
        children: [
          // PageView with images
          PageView.builder(
            controller: _pageController,
            itemCount: imagePath.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return OnboardingPage(
                image: imagePath[index],
                title: "Welcome to AnaadFoods",
                subtitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
              );
            },
          ),

             Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
               // keep alignment

                // Page Indicator
                SmoothPageIndicator(
                  controller: _pageController,
                  count: imagePath.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: Colors.red.shade700,
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                ),

               
              ],
            ),
          ),
          // Bottom Navigation Controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Align(
              alignment:Alignment.centerRight,
              child: 
                // Skip button
                // if (_currentPage != imagePath.length - 1)
                //   GestureDetector(
                //     onTap: () => onGetStartedClicked(context),
                //     child: Text(
                //       "Skip",
                //       style: TextStyle(
                //         fontSize: 16,
                //         color: Colors.white70,
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //   )
                // else
                //   const SizedBox(width: 50), // keep alignment

                // // Page Indicator
                // SmoothPageIndicator(
                //   controller: _pageController,
                //   count: imagePath.length,
                //   effect: ExpandingDotsEffect(
                //     activeDotColor: Colors.red.shade700,
                //     dotHeight: 8,
                //     dotWidth: 8,
                //   ),
                // ),

                // Next or Get Started
                GestureDetector(
                  onTap: () {
                    if (_currentPage == imagePath.length - 1) {
                      onGetStartedClicked(context);
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    _currentPage == imagePath.length - 1 ? "Start" : "Next →",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 6,
                          color: Colors.black45,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              
            ),
          ),
        ],
      ),
    );
  }

  void onGetStartedClicked(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}

/// A reusable onboarding page widget
class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset(
            image,
            fit: BoxFit.cover,
          ),
        ),

        // Gradient overlay for readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Text content
        Positioned(
          bottom: 150,
          left: 20,
          right: 20,
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 8,
                      color: Colors.black45,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
