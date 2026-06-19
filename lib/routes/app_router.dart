import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/user_model.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/models/subscription_model.dart';
import 'package:grocery_app/routes/app_routes.dart';

// Screens
import 'package:grocery_app/screens/welcome_screen.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/screens/auth/signup_screen.dart';
import 'package:grocery_app/screens/auth/forget_password_screen.dart';
import 'package:grocery_app/screens/splash/splash_screen.dart';

import 'package:grocery_app/screens/dashboard/dashboard_screen.dart';
import 'package:grocery_app/screens/home/home_screen.dart';
import 'package:grocery_app/screens/innovations/anaad_innovations_screen.dart';
import 'package:grocery_app/screens/innovations/anaad_games_screen.dart';
import 'package:grocery_app/screens/innovations/anaad_robots_screen.dart';
import 'package:grocery_app/screens/innovations/anaad_redemptions_screen.dart';
import 'package:grocery_app/screens/innovations/refer_earn_screen.dart';
import 'package:grocery_app/screens/innovations/games/seed_savior_game_screen.dart';
import 'package:grocery_app/screens/innovations/games/ritu_chakra_game_screen.dart';
import 'package:grocery_app/screens/innovations/games/microbe_mania_game_screen.dart';
import 'package:grocery_app/screens/innovations/games/cow_to_soil_cycle_game_screen.dart';
import 'package:grocery_app/screens/innovations/games/compost_commander_game_screen.dart';
import 'package:grocery_app/screens/innovations/panchang/panchang_home_screen.dart';
import 'package:grocery_app/screens/innovations/panchang/panchang_month_screen.dart';
import 'package:grocery_app/screens/innovations/panchang/panchang_guidance_screen.dart';
import 'package:grocery_app/screens/innovations/panchang/panchang_guidance_profile_screen.dart';
import 'package:grocery_app/screens/innovations/panchang/panchang_festivals_screen.dart';
import 'package:grocery_app/screens/innovations/panchang/panchang_advanced_timings_screen.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';

import 'package:grocery_app/screens/explore_screen.dart';
import 'package:grocery_app/screens/category_items_screen.dart';
import 'package:grocery_app/screens/products/all_products_screen.dart';
import 'package:grocery_app/screens/featured_products_screen.dart';

import 'package:grocery_app/screens/cart/cart_screen.dart';
import 'package:grocery_app/screens/checkout/checkout_screen.dart';
import 'package:grocery_app/screens/address/address_selection_screen.dart';

import 'package:grocery_app/screens/favourite_screen.dart';

import 'package:grocery_app/screens/account/account_screen_final.dart';
import 'package:grocery_app/screens/profile/edit_profile_screen.dart';
import 'package:grocery_app/screens/order/order_screen.dart';
import 'package:grocery_app/screens/order/order_detail_screen.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail_single.dart';
import 'package:grocery_app/screens/notifications/notifications_screen.dart';
import 'package:grocery_app/screens/about/about_screen.dart';
import 'package:grocery_app/screens/help/help_screen.dart';
import 'package:grocery_app/screens/legal/legal_content_screen.dart';
import 'package:grocery_app/screens/RFP/delivery_screen.dart';
import 'package:grocery_app/screens/RFP/contract_farming_screen.dart';
import 'package:grocery_app/models/legal_document_model.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorHomeKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final GlobalKey<NavigatorState> _shellNavigatorCategoriesKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellCategories');
final GlobalKey<NavigatorState> _shellNavigatorCartKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellCart');
final GlobalKey<NavigatorState> _shellNavigatorWishlistKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellWishlist');
final GlobalKey<NavigatorState> _shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

class AppRouter {
  // Static instance
  static final AppRouter _instance = AppRouter._internal();
  factory AppRouter() => _instance;
  AppRouter._internal();

  // GoRouter configuration
  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoute.splash.path,
    debugLogDiagnostics: true,

    // Auth Guard Implementation
    redirect: (BuildContext context, GoRouterState state) async {
      final bool isLoggedIn = await getIt<TokenService>().isLoggedIn();

      final String path = state.uri.path;

      // Routes that are strictly for authentication
      final bool isAuthRoute =
          path == AppRoute.login.path ||
          path == AppRoute.signup.path ||
          path == AppRoute.welcome.path ||
          path == AppRoute.forgotPassword.path ||
          path == '/'; // Allow initial root until initialized

      // Routes that require authentication
      final bool isProtectedRoute =
          path.startsWith('/profile') ||
          path.startsWith('/order') ||
          path.startsWith('/subscription') ||
          path.startsWith('/notifications') ||
          path.startsWith('/checkout') ||
          path.startsWith('/address');

      // Allow splash to resolve itself
      if (path == AppRoute.splash.path) return null;

      // Unauthenticated users trying to access protected routes
      if (!isLoggedIn && isProtectedRoute) {
        return '${AppRoute.login.path}?redirect=${Uri.encodeComponent(state.uri.toString())}';
      }

      // Authenticated users trying to access login/signup pages
      if (isLoggedIn && isAuthRoute && path != '/') {
        return AppRoute.home.path;
      }

      return null;
    },

    refreshListenable: _GoRouterRefreshStream(TokenService.authStateChanges),

    routes: <RouteBase>[
      // --- Splash Route ---
      GoRoute(
        path: AppRoute.splash.path,
        name: AppRoute.splash.name,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),

      // --- Auth Routes (Full Screen) ---
      GoRoute(
        path: AppRoute.welcome.path,
        name: AppRoute.welcome.name,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder:
            (context, state) => LoginScreen(
              redirectPath: state.uri.queryParameters['redirect'],
            ),
      ),
      GoRoute(
        path: AppRoute.signup.path,
        name: AppRoute.signup.name,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoute.forgotPassword.path,
        name: AppRoute.forgotPassword.name,
        builder: (context, state) => const ForgetPasswordScreen(),
      ),

      GoRoute(
        path: AppRoute.innovations.path,
        name: AppRoute.innovations.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AnaadInnovationsScreen(),
      ),
      GoRoute(
        path: AppRoute.panchang.path,
        name: AppRoute.panchang.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PanchangHomeScreen(),
      ),
      GoRoute(
        path: AppRoute.games.path,
        name: AppRoute.games.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AnaadGamesScreen(),
      ),
      GoRoute(
        path: AppRoute.robots.path,
        name: AppRoute.robots.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AnaadRobotsScreen(),
      ),
      GoRoute(
        path: AppRoute.redemptions.path,
        name: AppRoute.redemptions.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AnaadRedemptionsScreen(),
      ),
      GoRoute(
        path:
            '${AppRoute.referEarn.path}', // Adding slash explicitly to signify root level
        name: AppRoute.referEarn.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReferEarnScreen(),
      ),
      // Game routes
      GoRoute(
        path: AppRoute.seedSavior.path,
        name: AppRoute.seedSavior.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SeedSaviorGameScreen(),
      ),
      GoRoute(
        path: AppRoute.rituChakra.path,
        name: AppRoute.rituChakra.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RituChakraGameScreen(),
      ),
      GoRoute(
        path: AppRoute.microbeMania.path,
        name: AppRoute.microbeMania.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MicrobeManiaGameScreen(),
      ),
      GoRoute(
        path: AppRoute.cowToSoil.path,
        name: AppRoute.cowToSoil.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CowToSoilCycleGameScreen(),
      ),
      GoRoute(
        path: AppRoute.compostCommander.path,
        name: AppRoute.compostCommander.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CompostCommanderGameScreen(),
      ),
      // Panchang sub-routes
      GoRoute(
        path: AppRoute.panchangMonth.path,
        name: AppRoute.panchangMonth.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PanchangMonthScreen(),
      ),
      GoRoute(
        path: AppRoute.panchangGuidance.path,
        name: AppRoute.panchangGuidance.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PanchangGuidanceScreen(),
      ),
      GoRoute(
        path: AppRoute.panchangGuidanceProfile.path,
        name: AppRoute.panchangGuidanceProfile.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PanchangGuidanceProfileScreen(),
      ),
      GoRoute(
        path: AppRoute.panchangFestivals.path,
        name: AppRoute.panchangFestivals.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PanchangFestivalsScreen(),
      ),
      GoRoute(
        path: '${AppRoute.panchangAdvancedTimings.path}',
        name: AppRoute.panchangAdvancedTimings.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder:
            (context, state) => PanchangAdvancedTimingsScreen(
              selectedDate: state.extra as DateTime? ?? DateTime.now(),
            ),
      ),
      GoRoute(
        path: AppRoute.checkout.path,
        name: AppRoute.checkout.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};

          CartModel? cart;
          final cartVal = extra['cart'];
          if (cartVal is CartModel) {
            cart = cartVal;
          } else if (cartVal is Map<String, dynamic>) {
            cart = CartModel.fromJson(cartVal);
          }

          Product? singleProduct;
          final productVal = extra['singleProduct'];
          if (productVal is Product) {
            singleProduct = productVal;
          } else if (productVal is Map<String, dynamic>) {
            singleProduct = Product.fromJson(productVal);
          }

          int? quantity;
          final quantityVal = extra['quantity'];
          if (quantityVal is int) {
            quantity = quantityVal;
          } else if (quantityVal != null) {
            quantity = int.tryParse(quantityVal.toString());
          }

          bool isSubscription = false;
          final subVal = extra['isSubscription'];
          if (subVal is bool) {
            isSubscription = subVal;
          } else if (subVal != null) {
            isSubscription = subVal.toString().toLowerCase() == 'true';
          }

          int? selectedPlan;
          final planVal = extra['selectedPlan'];
          if (planVal is int) {
            selectedPlan = planVal;
          } else if (planVal != null) {
            selectedPlan = int.tryParse(planVal.toString());
          }

          double? price;
          final priceVal = extra['price'];
          if (priceVal is num) {
            price = priceVal.toDouble();
          } else if (priceVal != null) {
            price = double.tryParse(priceVal.toString());
          }

          return CheckoutScreen(
            cart: cart,
            singleProduct: singleProduct,
            price: price,
            quantity: quantity,
            isSubscription: isSubscription,
            selectedPlan: selectedPlan,
            codDeliveryCharge: 0,
            prepaidDeliveryCharge: 0,
            expectedDeliveryDate: '',
            paymentType: extra['paymentType'] as String?,
          );
        },
      ),
      GoRoute(
        path:
            AppRoute
                .editProfile
                .path, // Needs explicit slash if path doesn't have it
        name: AppRoute.editProfile.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          UserModel? userProfile;
          final extra = state.extra;
          if (extra is UserModel) {
            userProfile = extra;
          } else if (extra is Map<String, dynamic>) {
            try {
              userProfile = UserModel.fromJson(extra);
            } catch (_) {
              userProfile = null;
            }
          }
          userProfile ??= getIt<TokenService>().currentUser;
          return EditProfileScreen(
            userProfile:
                userProfile ??
                UserModel(
                  email: '',
                  username: '',
                  password: '',
                  confirmPassword: '',
                  firstName: '',
                  lastName: '',
                  phoneNumber: '',
                  gender: '',
                ),
          );
        },
      ),
      GoRoute(
        path: AppRoute.orderList.path,
        name: AppRoute.orderList.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OrderScreen(),
      ),
      GoRoute(
        path: AppRoute.subscriptionList.path,
        name: AppRoute.subscriptionList.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      // These routes are directly under the root navigator.
      // They will NEVER show the BottomNavigationBar.

      // --- Deep Link Routes ---
      GoRoute(
        path: '/product/:id',
        name: AppRoute.productDetails.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          Product? product;
          final extra = state.extra;
          if (extra is Product) {
            product = extra;
          } else if (extra is Map<String, dynamic>) {
            product = Product.fromJson(extra);
          }
          return ProductDetailsRouteWrapper(
            productId: state.pathParameters['id'],
            initialProduct: product,
          );
        },
      ),
      GoRoute(
        path: '/order/:id',
        name: AppRoute.orderDetails.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          Order? order;
          if (extra is Order) {
            order = extra;
          }
          final idParam = state.pathParameters['id'];
          // Ensure we don't crash if the ID is not an integer
          if (idParam != null && int.tryParse(idParam) == null) {
            return const Scaffold(body: Center(child: Text('Invalid Link')));
          }
          return OrderDetailScreen(orderId: idParam, order: order);
        },
      ),
      GoRoute(
        path: '/subscription/:id',
        name: AppRoute.subscriptionDetails.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          Subscription? sub;
          if (extra is Subscription) {
            sub = extra;
          } else if (extra is Map<String, dynamic>) {
            try {
              sub = Subscription.fromJson(extra);
            } catch (e) {
              sub = null;
            }
          }
          final idParam = state.pathParameters['id'];
          // Ensure we don't crash if the ID is not an integer
          if (idParam != null && int.tryParse(idParam) == null) {
            return const Scaffold(body: Center(child: Text('Invalid Link')));
          }
          return SubscriptionPlanDetailScreen(
            subscriptionId: idParam,
            subscription: sub,
          );
        },
      ),

      // --- Product Browsing Routes (no bottom nav) ---
      GoRoute(
        path: AppRoute.allProducts.path,
        name: AppRoute.allProducts.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AllProductsScreen(),
      ),
      GoRoute(
        path: AppRoute.featuredProducts.path,
        name: AppRoute.featuredProducts.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extraList = state.extra as List?;
          final products = extraList?.map((e) {
            if (e is Product) return e;
            if (e is Map<String, dynamic>) return Product.fromJson(e);
            return e as Product;
          }).toList() ?? [];
          return FeaturedProductsScreen(products: products);
        },
      ),
      GoRoute(
        path: AppRoute.categoryItems.path,
        name: AppRoute.categoryItems.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final productsList = extra['products'] as List?;
          return CategoryItemsScreen(
            name: extra['name'] as String? ?? '',
            allProducts: productsList?.map((e) {
              if (e is Product) return e;
              if (e is Map<String, dynamic>) return Product.fromJson(e);
              return e as Product;
            }).toList() ?? [],
          );
        },
      ),

      // --- Address & Checkout Routes (no bottom nav) ---
      GoRoute(
        path: AppRoute.address.path,
        name: AppRoute.address.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};

          CartModel? cart;
          final cartVal = extra['cart'];
          if (cartVal is CartModel) {
            cart = cartVal;
          } else if (cartVal is Map<String, dynamic>) {
            cart = CartModel.fromJson(cartVal);
          }

          Product? singleProduct;
          final productVal = extra['singleProduct'];
          if (productVal is Product) {
            singleProduct = productVal;
          } else if (productVal is Map<String, dynamic>) {
            singleProduct = Product.fromJson(productVal);
          }

          double? price;
          final priceVal = extra['price'];
          if (priceVal is num) {
            price = priceVal.toDouble();
          } else if (priceVal != null) {
            price = double.tryParse(priceVal.toString());
          }

          int? quantity;
          final quantityVal = extra['quantity'];
          if (quantityVal is int) {
            quantity = quantityVal;
          } else if (quantityVal != null) {
            quantity = int.tryParse(quantityVal.toString());
          }

          bool isSubscription = false;
          final subVal = extra['isSubscription'];
          if (subVal is bool) {
            isSubscription = subVal;
          } else if (subVal != null) {
            isSubscription = subVal.toString().toLowerCase() == 'true';
          }

          int? selectedPlan;
          final planVal = extra['selectedPlan'];
          if (planVal is int) {
            selectedPlan = planVal;
          } else if (planVal != null) {
            selectedPlan = int.tryParse(planVal.toString());
          }

          final paymentType = extra['paymentType'] as String?;

          return AddressSelectionScreen(
            cart: cart,
            singleProduct: singleProduct,
            price: price,
            quantity: quantity,
            isSubscription: isSubscription,
            selectedPlan: selectedPlan,
            paymentType: paymentType,
          );
        },
      ),
      GoRoute(
        path: AppRoute.orderAccepted.path,
        name: AppRoute.orderAccepted.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return Scaffold(body: Center(child: Text('Order Accepted')));
        },
      ),

      // --- Profile Sub-Routes at root level (no bottom nav) ---
      GoRoute(
        path: AppRoute.notifications.path,
        name: 'root_notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoute.aboutUs.path,
        name: AppRoute.aboutUs.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoute.help.path,
        name: AppRoute.help.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: AppRoute.legal.path,
        name: AppRoute.legal.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final document = state.extra as LegalDocument?;
          if (document == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Legal')),
              body: const Center(child: Text('No document provided')),
            );
          }
          return LegalContentScreen(document: document);
        },
      ),

      // --- RFP Routes (no bottom nav) ---
      GoRoute(
        path: AppRoute.delivery.path,
        name: AppRoute.delivery.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DeliveryScreen(),
      ),
      GoRoute(
        path: AppRoute.contractFarming.path,
        name: AppRoute.contractFarming.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CombinedScreen(),
      ),

      // --- Main Shell Route for Bottom Navigation ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardScreen(navigationShell: navigationShell);
        },
        branches: [
          // 0: HOME BRANCH
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: AppRoute.home.path,
                name: AppRoute.home.name,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  // No longer nesting deep routes here to truly escape shell nav
                ],
              ),
            ],
          ),

          // 1: CATEGORIES BRANCH
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCategoriesKey,
            routes: [
              GoRoute(
                path: AppRoute.categories.path,
                name: AppRoute.categories.name,
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),

          // 2: CART BRANCH
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCartKey,
            routes: [
              GoRoute(
                path: AppRoute.cart.path,
                name: AppRoute.cart.name,
                builder: (context, state) => CartScreen(),
                routes: [
                  // No longer nesting deep routes here to truly escape shell nav
                ],
              ),
            ],
          ),

          // 3: WISHLIST BRANCH
          StatefulShellBranch(
            navigatorKey: _shellNavigatorWishlistKey,
            routes: [
              GoRoute(
                path: AppRoute.wishlist.path,
                name: AppRoute.wishlist.name,
                builder: (context, state) => const FavouriteScreen(),
              ),
            ],
          ),

          // 4: PROFILE BRANCH
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: AppRoute.profile.path,
                name: AppRoute.profile.name,
                builder: (context, state) => const AccountScreenFinal(),
                routes: [
                  // No longer nesting deep routes here to truly escape shell nav
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      final theme = Theme.of(context);
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.explore_off_rounded,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Page Not Found',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sorry for the inconvenience.\nThe page you\'re looking for doesn\'t exist or has been moved.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(AppRoute.home.path),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Go Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: AppColors.parchment,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
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
  final Product? initialProduct;

  const ProductDetailsRouteWrapper({
    super.key,
    required this.productId,
    this.initialProduct,
  });

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
    if (widget.initialProduct != null) {
      _product = widget.initialProduct;
      _isLoading = false;
    } else {
      _fetchProduct();
    }
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
