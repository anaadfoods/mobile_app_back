import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum AppRoute {
  // Auth & Onboarding
  splash(path: '/splash', name: 'splash'),
  welcome(path: '/welcome', name: 'welcome'),
  login(path: '/login', name: 'login'),
  signup(path: '/signup', name: 'signup'),
  forgotPassword(path: '/forgot-password', name: 'forgot_password'),

  // Tab Routes (Shell paths)
  home(path: '/home', name: 'home'),
  categories(path: '/categories', name: 'categories'),
  cart(path: '/cart', name: 'cart'),
  wishlist(path: '/wishlist', name: 'wishlist'),
  profile(path: '/profile', name: 'profile'),

  // Product & Order Routes
  productDetails(path: '/product/:id', name: 'product_details'),
  allProducts(path: '/products', name: 'products'),
  featuredProducts(path: '/featured-products', name: 'featured_products'),
  categoryItems(path: '/category-items', name: 'category_items'),
  orderList(path: '/orders', name: 'order_list'),
  orderDetails(path: '/order/:id', name: 'order_details'),
  checkout(path: '/checkout', name: 'checkout'),
  address(path: '/address', name: 'address'),
  orderAccepted(path: '/order-accepted', name: 'order_accepted'),

  // Subscription Routes
  subscriptionList(path: '/subscriptions', name: 'subscription_list'),
  subscriptionDetails(path: '/subscription/:id', name: 'subscription_details'),

  // Profile & Setting Routes
  editProfile(path: '/edit-profile', name: 'edit_profile'),
  notifications(path: '/notifications', name: 'notifications'),
  aboutUs(path: '/about-us', name: 'about_us'),
  help(path: '/help', name: 'help'),
  legal(path: '/legal', name: 'legal'),

  // RFP Routes
  delivery(path: '/delivery', name: 'delivery'),
  contractFarming(path: '/contract-farming', name: 'contract_farming'),

  // Innovations & Games
  innovations(path: '/innovations', name: 'innovations'),
  games(path: '/games', name: 'games'),
  panchang(path: '/panchang', name: 'panchang'),
  robots(path: '/robots', name: 'robots'),
  redemptions(path: '/redemptions', name: 'redemptions'),
  referEarn(path: '/refer-earn', name: 'refer_earn'),

  // Individual Game Routes
  seedSavior(path: '/seed-savior', name: 'seed_savior'),
  rituChakra(path: '/ritu-chakra', name: 'ritu_chakra'),
  microbeMania(path: '/microbe-mania', name: 'microbe_mania'),
  cowToSoil(path: '/cow-to-soil', name: 'cow_to_soil'),
  compostCommander(path: '/compost-commander', name: 'compost_commander'),

  // Panchang Sub-Routes
  panchangMonth(path: '/panchang-month', name: 'panchang_month'),
  panchangGuidance(path: '/panchang-guidance', name: 'panchang_guidance'),
  panchangGuidanceProfile(
    path: '/panchang-guidance-profile',
    name: 'panchang_guidance_profile',
  ),
  panchangFestivals(path: '/panchang-festivals', name: 'panchang_festivals'),
  panchangAdvancedTimings(
    path: '/panchang-advanced-timings',
    name: 'panchang_advanced_timings',
  ),

  // Misc
  webview(path: '/webview', name: 'webview'),
  filter(path: '/filter', name: 'filter'),
  communityDetails(path: '/community-details', name: 'community_details'),
  explore(path: '/explore', name: 'explore');

  final String path;
  final String name;
  const AppRoute({required this.path, required this.name});
}

extension GoRouterExtension on BuildContext {
  /// Safely pops the current screen. If it's the only screen in the stack
  /// (e.g., opened via deep link), it routes to a fallback target (like Home).
  void safePop({String fallbackLocation = '/home'}) {
    if (canPop()) {
      pop();
    } else {
      go(fallbackLocation);
    }
  }
}
