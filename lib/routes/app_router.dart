import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/services/product_service.dart'; // CategoryService is defined here
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/services/navigation_service.dart';

// Screens
import 'package:grocery_app/screens/dashboard/dashboard_screen.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/screens/welcome_screen.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/screens/order/order_detail_screen.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail_single.dart';
import 'package:grocery_app/screens/cart/cart_screen.dart';
import 'package:grocery_app/screens/account/account_screen_final.dart';
import 'package:grocery_app/screens/notifications/notifications_screen.dart';

class AppRouter {
  // Static instance
  static final AppRouter _instance = AppRouter._internal();
  factory AppRouter() => _instance;
  AppRouter._internal();

  // GoRouter configuration
  late final GoRouter router = GoRouter(
    navigatorKey: NavigationService().navigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: _GoRouterRefreshStream(AuthService.authStateChanges),
    redirect: (context, state) async {
      final isLoggedIn = await AuthService().isLoggedIn();
      final isLoggingIn = state.uri.path == '/login';
      final isWelcome = state.uri.path == '/welcome';

      // If not logged in and trying to access restricted routes
      if (!isLoggedIn) {
        // Allow access to welcome and login pages
        if (isLoggingIn || isWelcome) return null;

        // For deep links to specific content, we might want to redirect to login
        // and then back to the content. content param can be added.
        // For now, simple redirect to login.
        return '/login';
      }

      // If logged in and trying to access login/welcome, redirect to home
      if (isLoggedIn && (isLoggingIn || isWelcome)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder:
            (context, state) =>
                DashboardScreen(key: DashboardScreen.dashboardKey),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        name: 'product_details',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return ProductDetailsRouteWrapper(productId: id);
        },
      ),
      GoRoute(
        path: '/orders/:id',
        name: 'order_details',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return OrderDetailScreen(orderId: id ?? '');
        },
      ),
      GoRoute(
        path: '/subscriptions/:id',
        name: 'subscription_details',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return SubscriptionPlanDetailScreen(subscriptionId: id);
        },
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => CartScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => AccountScreenFinal(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => NotificationsScreen(),
      ),
    ],
    errorBuilder:
        (context, state) =>
            Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
}

// Helper to convert Stream to Listenable for GoRouter
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Wrapper for Product Details to fetch data
class ProductDetailsRouteWrapper extends StatefulWidget {
  final String? productId;

  const ProductDetailsRouteWrapper({super.key, required this.productId});

  @override
  State<ProductDetailsRouteWrapper> createState() =>
      _ProductDetailsRouteWrapperState();
}

class _ProductDetailsRouteWrapperState
    extends State<ProductDetailsRouteWrapper> {
  Product? _product;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    if (widget.productId == null) {
      setState(() {
        _error = 'Invalid Product ID';
        _isLoading = false;
      });
      return;
    }

    try {
      final id = int.tryParse(widget.productId!);
      if (id == null) {
        setState(() {
          _error = 'Invalid Product ID Format';
          _isLoading = false;
        });
        return;
      }

      final product = await CategoryService.fetchProductById(id);
      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Product not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    return ProductDetailsScreen(product: _product!);
  }
}
