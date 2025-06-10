import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/screens/dashboard/dashboard_screen.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class WelcomeScreen extends StatelessWidget {
  final List<String> imagePath = [
    "assets/images/1.svg",
    "assets/images/2.svg",
    "assets/images/3.svg",
    "assets/images/4.svg",
  ];
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            children: [
              Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: SvgPicture.asset(
                    imagePath[0],
                    width: MediaQuery.of(context).size.width ,
                    height: MediaQuery.of(context).size.height ,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: SvgPicture.asset(
                    imagePath[1],
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: SvgPicture.asset(
                    imagePath[2],
                    width: MediaQuery.of(context).size.width ,
                    height: MediaQuery.of(context).size.height ,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: SvgPicture.asset(
                    imagePath[3],
                    width: MediaQuery.of(context).size.width ,
                    height: MediaQuery.of(context).size.height ,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          Container(
            alignment: Alignment(0, 0.90),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    _pageController.jumpToPage(3);
                  },
                  child: Text("skip"),
                ),

                SmoothPageIndicator(
                  controller: _pageController,
                  count: 4,
                  effect: ExpandingDotsEffect(activeDotColor: const Color.fromARGB(255, 181, 60, 60)),
                ),
                GestureDetector(
                  onTap: () {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    if (_pageController.page == 3) {
                      onGetStartedClicked(context);
                    }
                  },
                  child: Text("next"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget icon() {
    String iconPath = "assets/icons/app_icon.svg";
    return SvgPicture.asset(iconPath, width: 48, height: 56);
  }

  Widget welcomeTextWidget() {
    return Column(
      children: [
        AppText(
          text: "Welcome",
          fontSize: 48,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        AppText(
          text: "to our store",
          fontSize: 48,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ],
    );
  }

  Widget sloganText() {
    return AppText(
      text: "Get your grecories as fast as in hour",
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xffFCFCFC).withOpacity(0.7),
    );
  }

  Widget getButton(BuildContext context) {
    return AppButton(
      label: "Get Started",
      fontWeight: FontWeight.w600,
      padding: EdgeInsets.symmetric(vertical: 25),
      onPressed: () {
        onGetStartedClicked(context);
      },
    );
  }

  void onGetStartedClicked(BuildContext context) {
    Navigator.of(context).pushReplacement(
      new MaterialPageRoute(
        builder: (BuildContext context) {
          return DashboardScreen();
        },
      ),
    );
  }
}
