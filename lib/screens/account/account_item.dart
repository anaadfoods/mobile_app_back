
import 'package:flutter/material.dart';
import 'package:grocery_app/screens/order/order_screen.dart';

class AccountItem {
  final String label;
  final String iconPath;
  final Widget screen;
  
  AccountItem(this.label, this.iconPath, this.screen );
}

List<AccountItem> accountItems = [
  AccountItem("Orders", "assets/icons/account_icons/orders_icon.svg" , OrderScreen()),
  AccountItem("My Details", "assets/icons/account_icons/details_icon.svg", OrderScreen()),
  AccountItem("Help", "assets/icons/account_icons/help_icon.svg", OrderScreen()),
  AccountItem("About", "assets/icons/account_icons/about_icon.svg", OrderScreen()),
];