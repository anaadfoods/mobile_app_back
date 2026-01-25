import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:grocery_app/services/navigation_service.dart';

/// DeepLinkService handles incoming deep links from both cold starts and foreground.
/// Supports HTTPS App Links (Android) and Universal Links (iOS).
///
/// Supported URL patterns:
/// - https://app.anaadfoods.com/products/{id}
/// - https://app.anaadfoods.com/orders/{id}
/// - https://app.anaadfoods.com/subscriptions/{id}
/// - https://app.anaadfoods.com/cart
/// - https://app.anaadfoods.com/profile
/// - https://app.anaadfoods.com/notifications
/// - https://app.anaadfoods.com/ or /home
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _isInitialized = false;

  /// Initialize the deep link service. Call this once in main.dart after app setup.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // Handle initial link if app was opened via deep link (cold start)
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('DeepLinkService: Initial deep link: $initialLink');
        _handleDeepLink(initialLink);
      }

      // Listen for deep links while app is running (foreground)
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          debugPrint('DeepLinkService: Received deep link: $uri');
          _handleDeepLink(uri);
        },
        onError: (error) {
          debugPrint('DeepLinkService: Error receiving deep link: $error');
        },
      );
    } catch (e) {
      debugPrint('DeepLinkService: Error initializing: $e');
    }
  }

  /// Parse and handle the incoming deep link URI
  void _handleDeepLink(Uri uri) {
    final String path = uri.path;
    final List<String> segments = uri.pathSegments;

    debugPrint('DeepLinkService: Handling path: $path, segments: $segments');

    if (segments.isEmpty || path == '/' || path == '/home') {
      NavigationService.navigateToHome();
      return;
    }

    final String firstSegment = segments.first;
    final String? id = segments.length > 1 ? segments[1] : null;

    switch (firstSegment) {
      case 'products':
        if (id != null) {
          NavigationService.navigateToProductDetails(id);
        } else {
          NavigationService.navigateToHome();
        }
        break;

      case 'orders':
        if (id != null) {
          NavigationService.navigateToOrderDetails(id);
        } else {
          NavigationService.navigateToNotifications();
        }
        break;

      case 'subscriptions':
        if (id != null) {
          NavigationService.navigateToSubscriptionDetails(id);
        } else {
          NavigationService.navigateToNotifications();
        }
        break;

      case 'cart':
        NavigationService.navigateToCart();
        break;

      case 'profile':
      case 'account':
        NavigationService.navigateToAccount();
        break;

      case 'notifications':
        NavigationService.navigateToNotifications();
        break;

      default:
        debugPrint('DeepLinkService: Unknown path segment: $firstSegment');
        NavigationService.navigateToHome();
    }
  }

  /// Dispose of the link subscription
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _isInitialized = false;
  }
}
