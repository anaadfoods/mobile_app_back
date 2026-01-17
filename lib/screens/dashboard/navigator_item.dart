import 'package:grocery_app/common_widgets/global_import.dart';

import '../favourite_screen.dart';

class NavigatorItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final Widget screen;
  final bool isCenterFab; // For the floating center button

  NavigatorItem(
    this.label,
    this.icon,
    this.activeIcon,
    this.index,
    this.screen, {
    this.isCenterFab = false,
  });
}

// Center index for the floating FAB
const int centerFabIndex = 2;

List<NavigatorItem> navigatorItems = [
  NavigatorItem(
    "Home",
    Icons.home_outlined,
    Icons.home_rounded,
    0,
    HomeScreen(),
  ),
  NavigatorItem(
    "Favorites",
    Icons.favorite_border,
    Icons.favorite_rounded,
    1,
    FavouriteScreen(),
  ),
  NavigatorItem(
    "Cart",
    Icons.shopping_cart_outlined,
    Icons.shopping_cart_rounded,
    2,
    CartScreen(),
    isCenterFab: true,
  ),
  NavigatorItem(
    "Categories",
    Icons.grid_view_outlined,
    Icons.grid_view_rounded,
    3,
    ExploreScreen(),
  ),
  NavigatorItem(
    "Profile",
    Icons.person_outline,
    Icons.person_rounded,
    4,
    AccountScreenFinal(),
  ),
];
