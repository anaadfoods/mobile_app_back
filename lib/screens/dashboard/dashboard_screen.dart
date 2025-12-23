import 'package:grocery_app/common_widgets/global_import.dart';
import 'navigator_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentIndex = 0;

  // NEW: Variable to store the time of the last back press
  DateTime? lastTimeBackPressed;

  void _onTabChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // NEW: WillPopScope intercepts the back button to add custom logic
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        // Check if the back button was pressed within the last 2 seconds
        final isWarning =
            lastTimeBackPressed == null ||
            now.difference(lastTimeBackPressed!) > const Duration(seconds: 2);

        if (isWarning) {
          // If it's the first tap, store the time and show a message
          lastTimeBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          // Prevent the app from closing
          return false;
        } else {
          // If the second tap is within 2 seconds, allow the app to close
          return true;
        }
      },
      child: Scaffold(
        // The body dynamically changes based on the selected tab
        body: navigatorItems[currentIndex].screen,
        bottomNavigationBar: AnimatedContainer(
          duration: const Duration(milliseconds: AppColors.animMedium),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppColors.radiusXL),
              topRight: Radius.circular(AppColors.radiusXL),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(
                          AppColors.shadowOpacityLight,
                        ),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppColors.radiusXL),
              topRight: Radius.circular(AppColors.radiusXL),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              currentIndex: currentIndex,
              onTap: _onTabChanged,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedItemColor: colorScheme.primary,
              unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
              items:
                  navigatorItems.map((e) {
                    bool isActive = e.index == currentIndex;
                    return BottomNavigationBarItem(
                      label: e.label,
                      icon: AnimatedScale(
                        scale: isActive ? 1.0 : 0.9,
                        duration: const Duration(
                          milliseconds: AppColors.animFast,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(
                            milliseconds: AppColors.animMedium,
                          ),
                          padding: EdgeInsets.all(isActive ? 10 : 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isActive
                                    ? colorScheme.primary
                                    : Colors.transparent,
                            boxShadow:
                                isActive
                                    ? [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Icon(
                            e.icon,
                            color:
                                isActive
                                    ? colorScheme.onPrimary
                                    : (isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600]),
                            size: isActive ? 22 : 20,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
