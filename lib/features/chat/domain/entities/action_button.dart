/// Domain entity for interactive UI Action Buttons returned alongside AI chat responses.
class ActionButton {
  /// Label text for the button (e.g. "🛍️ View Product Details", "📦 View & Track Order")
  final String label;

  /// Action type identifier (e.g. "NAVIGATE_TO_PRODUCT_DETAIL", "OPEN_ORDER_TRACKER")
  final String actionType;

  /// Target screen name (e.g. "ProductDetailScreen", "OrderTrackerScreen")
  final String targetScreen;

  /// Data payload (e.g. {"variant_id": 12} or {"order_id": 9823})
  final Map<String, dynamic> data;

  const ActionButton({
    required this.label,
    required this.actionType,
    required this.targetScreen,
    required this.data,
  });

  factory ActionButton.fromJson(Map<String, dynamic> json) {
    return ActionButton(
      label: json['label'] as String? ?? '',
      actionType: json['action_type'] as String? ?? '',
      targetScreen: json['target_screen'] as String? ?? '',
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
    );
  }

  /// Create an ActionButton from legacy ui_action dict if action_buttons list is omitted.
  factory ActionButton.fromUiAction(Map<String, dynamic> uiAction) {
    final String actionType =
        (uiAction['action_type'] ?? uiAction['type'] ?? '').toString();
    final String targetScreen = (uiAction['target_screen'] ?? '').toString();
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      uiAction['data'] as Map? ?? uiAction,
    );

    String label = "View Details";
    final dynamic variantId =
        data['variant_id'] ?? uiAction['product_id'] ?? uiAction['variant_id'];
    final dynamic orderId = data['order_id'] ?? uiAction['order_id'];
    final String customTitle =
        data['title'] as String? ?? uiAction['title'] as String? ?? '';

    if (actionType == "NAVIGATE_TO_PRODUCT_DETAIL" ||
        targetScreen == "ProductDetailScreen" ||
        variantId != null) {
      label = customTitle.isNotEmpty ? customTitle : "🛍️ View Product Details";
    } else if (actionType == "OPEN_CART_DRAWER" ||
        targetScreen == "CartScreen") {
      label = customTitle.isNotEmpty ? customTitle : "🛒 View Shopping Cart";
    } else if (actionType == "OPEN_ORDER_TRACKER" ||
        targetScreen == "OrderTrackerScreen" ||
        orderId != null) {
      label = customTitle.isNotEmpty ? customTitle : "📦 Track Order Details";
    } else if (actionType == "OPEN_SUBSCRIPTION_PICKER" ||
        targetScreen == "SubscriptionScreen") {
      label = customTitle.isNotEmpty ? customTitle : "📅 Explore Subscriptions";
    }

    return ActionButton(
      label: label,
      actionType: actionType.isNotEmpty ? actionType : "NAVIGATE",
      targetScreen: targetScreen,
      data: data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'action_type': actionType,
      'target_screen': targetScreen,
      'data': data,
    };
  }
}
