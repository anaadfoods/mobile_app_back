import 'package:flutter/material.dart';
import '../core/analytics/analytics_service.dart';

class AnalyticsRouteObserver extends NavigatorObserver {
  String? _previousRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _recordNavigation(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _recordNavigation(newRoute, oldRoute);
  }

  void _recordNavigation(Route<dynamic> route, Route<dynamic>? previous) {
    String? screenName = route.settings.name;
    if (screenName == null || screenName == '{}' || screenName.trim().isEmpty) {
      final args = route.settings.arguments;
      if (args != null && args is String && args.isNotEmpty && args != '{}') {
        screenName = args;
      } else {
        return; // Ignore internal transitions or empty routes
      }
    }

    if (screenName != _previousRouteName) {
      AnalyticsService().currentScreen = screenName;
      AnalyticsService().trackEvent(
        eventName: 'screen_viewed',
        feature: 'navigation',
        screen: screenName,
        properties: {
          'current_screen': screenName,
          'previous_screen': _previousRouteName ?? 'none',
          'element_text': 'Screen: $screenName',
          'target_element': 'Screen: $screenName',
        },
      );
      _previousRouteName = screenName;
    }
  }
}
