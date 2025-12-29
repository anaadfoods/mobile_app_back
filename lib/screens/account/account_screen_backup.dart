import "package:grocery_app/common_widgets/global_import.dart";
// --- IMPORT ADDED ---
// Assuming you saved the switch in a common_widgets folder
import 'package:grocery_app/widgets/custom_switch.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  // --- LOGIC METHODS ARE NOW STATIC OR MOVED ---

  void openWhatsApp(BuildContext context) async {
    final phoneNumber = '+919996166186';
    final message = Uri.encodeComponent(
      "Hello, I want to inquire about your products.",
    );
    final url = Uri.parse("https://wa.me/$phoneNumber?text=$message");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // It's good practice to show feedback if it fails
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
    }
  }

  void _handleLogout(BuildContext context) {
    // The UI's only job is to tell the cubit to log out.
    // The cubit handles token removal and state change.
    // The AuthWrapper handles navigation.
    context.read<AuthCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use BlocBuilder to get the current user data from the AuthCubit state
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            // If the user is authenticated, build the main account screen content.
            return _buildAccountView(context, state.user);
          }
          // If the state is not Authenticated (e.g., loading, error, or unauthenticated),
          // show a loading indicator. The parent AuthWrapper will handle navigation away
          // from this screen if the user logs out.
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }

  // --- UI BUILD METHOD ---
  Widget _buildAccountView(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final String userHandle = user.username;
    final String userEmail = user.email;
    String userName = '${user.firstName} ${user.lastName}'.trim();
    if (userName.isEmpty) {
      userName = "User Name";
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Profile Picture
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage:
                              user.profilePicture != null &&
                                      user.profilePicture!.isNotEmpty
                                  ? NetworkImage(user.profilePicture!)
                                  : null,
                          child:
                              user.profilePicture == null ||
                                      user.profilePicture!.isEmpty
                                  ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white70,
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: AppColors.spacingM),
                      Text(
                        userName,
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppColors.spacingXS),
                      Text(
                        '@$userHandle',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppColors.spacingXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Email section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppColors.spacingL),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(AppColors.radiusM),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppColors.spacingM),
                        Expanded(
                          child: Text(userEmail, style: textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppColors.spacingL),

                  // Edit Profile Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    EditProfileScreen(userProfile: user),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Edit Profile"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppColors.spacingM,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppColors.spacingXL),

                  // Menu Items
                  _buildAccountItem(
                    context,
                    icon: Icons.subscriptions_outlined,
                    label: "My Subscriptions",
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionScreen(),
                          ),
                        ),
                  ),
                  _buildAccountItem(
                    context,
                    icon: Icons.shopping_bag_outlined,
                    label: "My Orders",
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderScreen(),
                          ),
                        ),
                  ),
                  _buildAccountItem(
                    context,
                    icon: Icons.help_outline,
                    label: "Help",
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpScreen(),
                          ),
                        ),
                  ),
                  _buildAccountItem(
                    context,
                    icon: Icons.info_outline,
                    label: "About",
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutScreen(),
                          ),
                        ),
                  ),

                  // --- THEME TOGGLE (MODIFIED) ---
                  BlocBuilder<ThemeCubit, ThemeMode>(
                    builder: (context, themeMode) {
                      final isDarkMode =
                          themeMode == ThemeMode.dark ||
                          (themeMode == ThemeMode.system &&
                              MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark);
                      return _buildAccountItem(
                        context,
                        icon:
                            isDarkMode
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                        label: 'Dark Mode',
                        onTap: () {
                          context.read<ThemeCubit>().toggleTheme(!isDarkMode);
                        },
                        trailing: CustomSwitch(
                          value: isDarkMode,
                          onChanged: (value) {
                            context.read<ThemeCubit>().toggleTheme(value);
                          },
                          activeColor: colorScheme.primary,
                          inactiveColor: theme.dividerColor,
                          thumbColor: Colors.white,
                          width: 50,
                          height: 30,
                        ),
                      );
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppColors.spacingL,
                    ),
                    child: Divider(color: theme.dividerColor),
                  ),

                  _buildAccountItem(
                    context,
                    icon: Icons.logout,
                    label: "Logout",
                    onTap: () => _handleLogout(context),
                    isDestructive: true,
                  ),
                  const SizedBox(height: AppColors.spacingXL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGET WITH THEME APPLIED ---
  Widget _buildAccountItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final iconColor = isDestructive ? colorScheme.error : colorScheme.primary;
    final textColor = isDestructive ? colorScheme.error : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppColors.spacingS),
        padding: const EdgeInsets.symmetric(
          horizontal: AppColors.spacingL,
          vertical: AppColors.spacingL,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppColors.radiusM),
          border: Border.all(
            color:
                isDestructive
                    ? colorScheme.error.withOpacity(0.3)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(
                AppColors.shadowOpacityLight,
              ),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppColors.spacingS),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppColors.radiusS),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppColors.spacingL),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
          ],
        ),
      ),
    );
  }
}
