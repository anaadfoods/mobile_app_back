import 'package:grocery_app/common_widgets/global_import.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Stack(
        children: [
          // Page View with onboarding images
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
                subtitle:
                    "Fresh groceries delivered to your doorstep with love and care.",
                isActive: _currentPage == index,
              );
            },
          ),

          // Page Indicator
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SmoothPageIndicator(
                  controller: _pageController,
                  count: imagePath.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: AppColors.buttonBackgroundColor,
                    dotColor: colorScheme.onPrimary.withOpacity(0.5),
                    dotHeight: 10,
                    dotWidth: 10,
                    spacing: 8,
                    expansionFactor: 3,
                  ),
                ),
              ],
            ),
          ),

          // Next/Start Button
          Positioned(
            bottom: 40,
            left: AppColors.spacingXL,
            right: AppColors.spacingXL,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: AppColors.animMedium),
              child: GestureDetector(
                onTap: () {
                  if (_currentPage == imagePath.length - 1) {
                    onGetStartedClicked(context);
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(
                        milliseconds: AppColors.animSlow,
                      ),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: AppColors.animMedium),
                  transitionBuilder:
                      (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                  child:
                      _currentPage == imagePath.length - 1
                          ? Container(
                            key: const ValueKey('start'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppColors.spacingXXL,
                              vertical: AppColors.spacingL,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.buttonBackgroundColor,
                              borderRadius: BorderRadius.circular(
                                AppColors.radiusRound,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.buttonBackgroundColor
                                      .withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Get Started",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: AppColors.spacingS),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          )
                          : Row(
                            key: const ValueKey('next'),
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppColors.spacingXL,
                                  vertical: AppColors.spacingM,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(
                                    AppColors.radiusRound,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Next",
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: colorScheme.onPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(width: AppColors.spacingXS),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: colorScheme.onPrimary,
                                      size: 16,
                                    ),
                                  ],
                                ),
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
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: AppColors.animSlow),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final bool isActive;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Background Image
        Positioned.fill(child: Image.asset(image, fit: BoxFit.cover)),

        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 0.7],
              ),
            ),
          ),
        ),

        // Text Content with Animation
        Positioned(
          bottom: 180,
          left: AppColors.spacingXL,
          right: AppColors.spacingXL,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: AppColors.animSlow),
            opacity: isActive ? 1.0 : 0.0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: AppColors.animSlow),
              offset: isActive ? Offset.zero : const Offset(0, 0.2),
              curve: Curves.easeOut,
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(
                          blurRadius: 12,
                          color: Colors.black54,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppColors.spacingM),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
