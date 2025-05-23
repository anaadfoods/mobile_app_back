import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grocery_app/services/auth_service.dart';

import 'account_item.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void openWhatsApp() async {
    final phoneNumber = '+919996166186';
    final message = Uri.encodeComponent(
      "Hello, I want to inquire about your products.",
    );
    final url = Uri.parse("https://wa.me/$phoneNumber?text=$message");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.clearToken();
    // No need to navigate as AccountScreenFinal will handle the UI update
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              ListTile(
                leading: CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  child: Text(
                     "U",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                title: AppText(
                  text:
                      user != null
                          ? "${user.firstName} ${user.lastName}"
                          : "User Name",
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                subtitle: AppText(
                  text: user?.email ?? "user@123",
                  color: Color(0xff7C7C7C),
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 20),
              ...accountItems
                  .map((item) => buildAccountItem(context, item))
                  .toList(),
              SizedBox(height: 30),
              logoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAccountItem(
    BuildContext context,
    AccountItem item, {
    Function()? onTap,
  }) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item.screen),
            );
          },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            item.iconPath,
            SizedBox(width: 20),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget logoutButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 25),
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: SvgPicture.asset(
          "assets/icons/account_icons/logout_icon.svg",
          width: 20,
          height: 20,
        ),
        label: Text(
          "Log Out",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Color(0xffF2F3F2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => _handleLogout(context),
      ),
    );
  }
}
