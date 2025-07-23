import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/screens/welcome_screen.dart';
import 'package:grocery_app/styles/theme.dart';
import 'package:grocery_app/screens/order_accepted_screen.dart';
import 'package:grocery_app/screens/dashboard/dashboard_screen.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/services/navigation_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.globalNavigatorKey,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: AuthService().isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data == true) {
            return DashboardScreen();
          } else {
            return WelcomeScreen();
          }
        },
      ),
      // Handle URL schemes for payment redirects
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('flutterpay://') == true) {
          // Handle payment redirect URLs
          final uri = Uri.parse(settings.name!);
          if (uri.path.contains('payment/success')) {
            return MaterialPageRoute(
              builder:
                  (context) => OrderAcceptedScreen(
                    paymentStatus: null,
                    isSubscription: false,
                  ),
            );
          }
        }
        return null;
      },
    );
  }
}
