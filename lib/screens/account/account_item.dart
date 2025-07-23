import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail.dart';
import 'package:grocery_app/screens/help/help_screen.dart';
import 'package:grocery_app/screens/referral/referral_screen.dart';

import 'package:flutter/material.dart';
import 'package:grocery_app/screens/about/about_screen.dart';
import 'package:grocery_app/screens/order/order_screen.dart';
import 'package:grocery_app/screens/profile/profile_screen.dart';
import 'package:grocery_app/screens/account/fcm_token_screen.dart';

class AccountItem {
  final String label;
  final Icon iconPath;
  final Widget screen;

  AccountItem(this.label, this.iconPath, this.screen);
}

List<AccountItem> accountItems = [
  AccountItem("Orders", Icon(Icons.my_library_add), OrderScreen()),
  AccountItem(
    "My Subscriptions",
    Icon(Icons.my_library_add),
    SubscriptionScreen(),
  ),

  // AccountItem("My Details", Icon(Icons.abc_sharp), ProfileScreen()),
  AccountItem("Referral", Icon(Icons.abc_sharp), ReferAndEarnScreen()),

  AccountItem("Help", Icon(Icons.abc_sharp), HelpScreen()),
  AccountItem("About", Icon(Icons.abc_sharp), AboutScreen()),
  AccountItem("FCM Token", Icon(Icons.notifications), FCMTokenScreen()),
];
