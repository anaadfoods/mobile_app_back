import "package:grocery_app/common_widgets/global_import.dart";


class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  // Helper method now takes BuildContext to access the theme
  Widget _buildBenefitItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 28, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: textTheme.bodyLarge)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme properties to apply them to the UI
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // AppBar is styled by the theme in main.dart
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome to Annad",
              // Using themed text style
              style: textTheme.displaySmall,
            ),
            const SizedBox(height: 20), // Increased spacing
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()));
              },
              style: theme.elevatedButtonTheme.style?.copyWith(
                minimumSize: MaterialStateProperty.all(const Size(double.infinity, 50)),
              ),
              child: Text(
                "Create account",
                // Using themed text style for text on a primary button
                style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
                shape: theme.elevatedButtonTheme.style?.shape?.resolve({}), // Match button shape
              ),
              child: Text("Login", style: textTheme.labelLarge),
            ),
            const SizedBox(height: 30),
            _buildBenefitItem(context, Icons.currency_rupee, "Upto ₹100 cashback on your first order"),
            _buildBenefitItem(context, Icons.local_shipping, "Free Delivery on first order – for top categories"),
            _buildBenefitItem(context, Icons.money, "Pay on Delivery"),
          ],
        ),
      ),
    );
  }
}

