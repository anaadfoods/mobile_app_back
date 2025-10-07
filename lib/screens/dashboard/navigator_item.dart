import 'package:flutter/material.dart';

import 'package:grocery_app/screens/account/account_screen_final.dart';
import 'package:grocery_app/screens/cart/cart_screen.dart';
import 'package:grocery_app/screens/explore_screen.dart';
import 'package:grocery_app/screens/home/home_screen.dart';
import '../favourite_screen.dart';

class NavigatorItem {
  final String label;
  final Widget icon;
  final int index;
  final Widget screen;

  NavigatorItem(this.label, this.icon, this.index, this.screen);
}

List<NavigatorItem> navigatorItems = [
  NavigatorItem("Home",Icon(Icons.home_outlined , ), 0, HomeScreen()),
  NavigatorItem("Favorites", Icon(Icons.favorite_border), 1, FavouriteScreen()),
  NavigatorItem("Cart", Icon(Icons.shopping_cart_outlined), 2, CartScreen()),
  NavigatorItem("Categories", Icon(Icons.grid_view), 3, ExploreScreen()),
  NavigatorItem("Profile", Icon(Icons.person_outline), 4, AccountScreenFinal()),
];
