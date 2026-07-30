import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'dashboard_dock_nav_item.dart';
import 'wave_clipper.dart';

class NavigatorItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const NavigatorItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

final List<NavigatorItem> navigatorItems = [
  const NavigatorItem(
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  const NavigatorItem(
    label: 'Explore',
    icon: Icons.grid_view_outlined,
    activeIcon: Icons.grid_view_rounded,
  ),
  const NavigatorItem(
    label: 'Cart',
    icon: Icons.shopping_cart_outlined,
    activeIcon: Icons.shopping_cart_rounded,
  ),
  const NavigatorItem(
    label: 'Favorites',
    icon: Icons.favorite_outline_rounded,
    activeIcon: Icons.favorite_rounded,
  ),
  const NavigatorItem(
    label: 'Account',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
  ),
];

class PremiumBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final List<NavigatorItem> items;
  final bool isDark;
  final ColorScheme colorScheme;
  final AnimationController bounceController;
  final AnimationController fabFloatController;
  final double pageOffset;
  final int cartBadgeCount;

  const PremiumBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.items,
    required this.isDark,
    required this.colorScheme,
    required this.bounceController,
    required this.fabFloatController,
    required this.pageOffset,
    required this.cartBadgeCount,
  });

  @override
  Widget build(BuildContext context) {
    const navBarHeight = 65.0;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
          child: ClipPath(
            clipper: WaveClipper(notchRadius: 26, notchMargin: 5),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: navBarHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            AppColors.deepSoilGreen.withValues(alpha: 0.95),
                            AppColors.deepSoilGreen.withValues(alpha: 0.98),
                          ]
                        : [
                            AppColors.softCream.withValues(alpha: 0.96),
                            AppColors.parchment.withValues(alpha: 0.98),
                          ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? AppColors.parchment.withValues(alpha: 0.1)
                        : AppColors.rawEarth.withValues(alpha: 0.12),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? AppColors.pureBlack.withValues(alpha: 0.4)
                          : AppColors.rawEarth.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isActive = index == currentIndex;

                    if (index == 2) {
                      return DockCartNavItem(
                        item: item,
                        isActive: isActive,
                        onTap: () => onTabChanged(index),
                        colorScheme: colorScheme,
                        isDark: isDark,
                        itemIndex: index,
                        pageOffset: pageOffset,
                        cartCount: cartBadgeCount,
                      );
                    }

                    return Expanded(
                      child: DockNavItem(
                        item: item,
                        isActive: isActive,
                        onTap: () => onTabChanged(index),
                        colorScheme: colorScheme,
                        isDark: isDark,
                        currentIndex: currentIndex,
                        itemIndex: index,
                        pageOffset: pageOffset,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: navBarHeight - 30,
          child: AnimatedBuilder(
            animation: fabFloatController,
            builder: (context, child) {
              final floatTranslation = fabFloatController.value * -3.0;
              return Transform.translate(
                offset: Offset(0, floatTranslation),
                child: child,
              );
            },
            child: BuildCenterFab(
              bounceController: bounceController,
              isCartActive: currentIndex == 2,
              onTap: () => onTabChanged(2),
              isDark: isDark,
              cartCount: cartBadgeCount,
            ),
          ),
        ),
      ],
    );
  }
}
