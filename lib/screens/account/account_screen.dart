import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grocery_app/models/subscription_model.dart';
import 'package:grocery_app/models/user_model.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail.dart';
import 'package:grocery_app/screens/about/about_screen.dart';
import 'package:grocery_app/screens/order/order_screen.dart';
import 'package:grocery_app/screens/profile/edit_profile_screen.dart';
import 'package:grocery_app/screens/profile/profile_screen.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Note: The original AccountItem class was not provided, so I'm commenting this out.
// The new UI is built with a more direct approach in the build method.
// import 'account_item.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late AuthService authService;
  UserModel? user;

  @override
  void initState() {
    super.initState();
    authService = AuthService();
    user = authService.currentUser;
  }

  // --- LOGIC METHODS (UNCHANGED) ---

  Future<void> _refreshUser() async {
    final updatedUser = await authService.getUserData();
    setState(() {
      user = updatedUser;
    });
  }

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
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final bearerToken = await authService.getAccessToken();
      if (fcmToken != null && bearerToken != null) {
        await NotificationService().removeFcmTokenFromBackend(
          fcmToken,
          bearerToken,
        );
      }
    } catch (e) {
      debugPrint('Error removing FCM token on logout: ${e.toString()}');
    }
    await authService.clearToken();
    setState(() {
      user = null;
    });
    // You might want to navigate to the login screen here
    // Navigator.of(context).pushReplacement(...);
  }

  // --- UI BUILD METHOD (UPDATED) ---

  @override
  Widget build(BuildContext context) {
    // Assuming a username field exists in your UserModel
    String userHandle = user?.username ?? "loading...";
    String userEmail = user?.email ?? "email@example.com";
    String userName = '${user?.firstName} ${user?.lastName}' ?? "Chlo Jonathan";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '@$userHandle',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              // -- Profile Picture --
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: user?.profilePicture != null
                        ? NetworkImage(user!.profilePicture!)
                        : null,
                    child: user?.profilePicture == null
                        ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 15),

              // -- User Name and Email --
              Text(
                userName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 5),
              Text(
                userEmail,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),

              // -- Edit Profile Button --
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfileScreen(userProfile: user!,)),
                    );
                    if (result == true) {
                      await _refreshUser();
                    }
                  },
                  icon: Icon(Icons.edit, size: 16),
                  label: Text("Edit Profile"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFFB58A55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(height: 30),

              // -- Menu Items --
              _buildAccountItem(
                context,
                icon: Icons.subscriptions_outlined,
                label: "My Subscriptions",
                onTap: () {
 Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SubscriptionScreen()),
                    );                },
              ),
              _buildAccountItem(
                context,
                icon: Icons.shopping_bag_outlined,
                label: "My Orders",
                onTap: () {
 Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OrderScreen()),
                    );                },
              ),
              _buildAccountItem(
                context,
                icon: Icons.settings_outlined,
                label: "About",
                onTap: () {
 Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AboutScreen()),
                    );
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                child: Divider(color: Colors.grey[200]),
              ),

              _buildAccountItem(
                context,
                icon: Icons.logout,
                label: "Logout",
                onTap: () => _handleLogout(context),
              ),
             

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS (UPDATED) ---

  Widget _buildAccountItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),

        ),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFFB58A55), size: 24),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
