import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/helpers/animated_transitions.dart';
import 'navigator_item.dart';

// import 'package:grocery_app/screens/auth/login_screen.dart';
// import 'package:grocery_app/services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      currentIndex = index;
    });
    // Restart animation for smooth transition
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0.1, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<int>(currentIndex),
          child: navigatorItems[currentIndex].screen,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(15),
            topLeft: Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black38.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 37,
              offset: Offset(0, -12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: currentIndex,
            onTap: _onTabChanged,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primaryColor,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
            unselectedItemColor: Colors.black,
            items:
                navigatorItems.map((e) {
                  return getNavigationBarItem(
                    label: e.label,
                    index: e.index,
                    iconPath: e.iconPath,
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem getNavigationBarItem({
    required String label,
    required String iconPath,
    required int index,
  }) {
    Color iconColor =
        index == currentIndex ? AppColors.primaryColor : Colors.black;
    return BottomNavigationBarItem(
      label: label,
      icon: SvgPicture.asset(iconPath, color: iconColor),
    );
  }
}
