import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/screens/chats/chat_screen.dart';


import '../favourite_screen.dart';


class NavigatorItem {
  final String label;
  final IconData icon;
  final int index;
  final Widget screen;

  NavigatorItem(this.label, this.icon, this.index, this.screen);
}


List<NavigatorItem> navigatorItems = [
  NavigatorItem("Home",Icons.home_outlined, 0, HomeScreen()),
  NavigatorItem("Favorites", Icons.favorite_border, 1, FavouriteScreen()),
  NavigatorItem("Cart", Icons.shopping_cart_outlined, 2, CartScreen()),
  NavigatorItem("Categories", Icons.grid_view, 3, ExploreScreen()),
  // NavigatorItem("Chat", Icons.chat, 4, ChatScreen()),
  NavigatorItem("Profile", Icons.person_outline, 5, AccountScreenFinal()),
];
