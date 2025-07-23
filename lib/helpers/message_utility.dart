import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class MessageUtility {
  // Message types
  static const String messageTypeOrder = 'order';
  static const String messageTypeProduct = 'product';
  static const String messageTypeSubscription = 'subscription';
  static const String messageTypePromo = 'promo';
  static const String messageTypeGeneral = 'general';

  // Action types
  static const String actionViewOrder = 'view_order';
  static const String actionViewProduct = 'view_product';
  static const String actionViewSubscription = 'view_subscription';
  static const String actionOpenCart = 'open_cart';
  static const String actionOpenProfile = 'open_profile';
  static const String actionOpenPromo = 'open_promo';
  static const String actionOpenSettings = 'open_settings';

  // Message priority levels
  static const String priorityHigh = 'high';
  static const String priorityMedium = 'medium';
  static const String priorityLow = 'low';

  /// Parse message data and extract relevant information
  static Map<String, dynamic> parseMessageData(RemoteMessage message) {
    Map<String, dynamic> data = message.data;
    
    return {
      'type': data['type'] ?? messageTypeGeneral,
      'action': data['action'],
      'id': data['id'],
      'title': message.notification?.title ?? data['title'],
      'body': message.notification?.body ?? data['body'],
      'image': data['image'],
      'priority': data['priority'] ?? priorityMedium,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    };
  }

  /// Get message type from data
  static String getMessageType(Map<String, dynamic> data) {
    return data['type'] ?? messageTypeGeneral;
  }

  /// Get action from data
  static String? getAction(Map<String, dynamic> data) {
    return data['action'];
  }

  /// Get ID from data
  static String? getId(Map<String, dynamic> data) {
    return data['id'];
  }

  /// Check if message is high priority
  static bool isHighPriority(Map<String, dynamic> data) {
    return data['priority'] == priorityHigh;
  }

  /// Check if message is order related
  static bool isOrderMessage(Map<String, dynamic> data) {
    return data['type'] == messageTypeOrder;
  }

  /// Check if message is product related
  static bool isProductMessage(Map<String, dynamic> data) {
    return data['type'] == messageTypeProduct;
  }

  /// Check if message is subscription related
  static bool isSubscriptionMessage(Map<String, dynamic> data) {
    return data['type'] == messageTypeSubscription;
  }

  /// Check if message is promo related
  static bool isPromoMessage(Map<String, dynamic> data) {
    return data['type'] == messageTypePromo;
  }

  /// Get appropriate icon for message type
  static IconData getMessageIcon(String messageType) {
    switch (messageType) {
      case messageTypeOrder:
        return Icons.shopping_bag;
      case messageTypeProduct:
        return Icons.inventory;
      case messageTypeSubscription:
        return Icons.subscriptions;
      case messageTypePromo:
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  /// Get appropriate color for message type
  static Color getMessageColor(String messageType) {
    switch (messageType) {
      case messageTypeOrder:
        return Colors.blue;
      case messageTypeProduct:
        return Colors.green;
      case messageTypeSubscription:
        return Colors.orange;
      case messageTypePromo:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get appropriate background color for message type
  static Color getMessageBackgroundColor(String messageType) {
    switch (messageType) {
      case messageTypeOrder:
        return Colors.blue.withOpacity(0.1);
      case messageTypeProduct:
        return Colors.green.withOpacity(0.1);
      case messageTypeSubscription:
        return Colors.orange.withOpacity(0.1);
      case messageTypePromo:
        return Colors.red.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  /// Format timestamp for display
  static String formatTimestamp(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  /// Create notification payload for local notifications
  static String createNotificationPayload({
    required String type,
    String? action,
    String? id,
    Map<String, dynamic>? additionalData,
  }) {
    Map<String, dynamic> payload = {
      'type': type,
      'action': action,
      'id': id,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    if (additionalData != null) {
      payload.addAll(additionalData);
    }

    return json.encode(payload);
  }

  /// Parse notification payload
  static Map<String, dynamic> parseNotificationPayload(String payload) {
    try {
      return json.decode(payload);
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
      return {};
    }
  }

  /// Validate message data
  static bool isValidMessage(Map<String, dynamic> data) {
    return data.containsKey('type') && data['type'] != null;
  }

  /// Get message summary for display
  static String getMessageSummary(Map<String, dynamic> data) {
    String type = data['type'] ?? messageTypeGeneral;
    String? title = data['title'];
    String? body = data['body'];

    if (title != null && title.isNotEmpty) {
      return title;
    } else if (body != null && body.isNotEmpty) {
      // Truncate body if too long
      return body.length > 50 ? '${body.substring(0, 47)}...' : body;
    } else {
      return 'New $type notification';
    }
  }

  /// Check if message should show in foreground
  static bool shouldShowInForeground(Map<String, dynamic> data) {
    String priority = data['priority'] ?? priorityMedium;
    return priority == priorityHigh || priority == priorityMedium;
  }

  /// Get notification sound based on priority
  static String? getNotificationSound(String priority) {
    switch (priority) {
      case priorityHigh:
        return 'high_priority_sound.mp3';
      case priorityMedium:
        return 'medium_priority_sound.mp3';
      case priorityLow:
        return 'low_priority_sound.mp3';
      default:
        return null;
    }
  }

  /// Get vibration pattern based on priority
  static List<int>? getVibrationPattern(String priority) {
    switch (priority) {
      case priorityHigh:
        return [0, 500, 200, 500]; // Strong vibration
      case priorityMedium:
        return [0, 300, 100, 300]; // Medium vibration
      case priorityLow:
        return [0, 200]; // Light vibration
      default:
        return null;
    }
  }

  /// Create message for order status update
  static Map<String, dynamic> createOrderMessage({
    required String orderId,
    required String status,
    String? title,
    String? body,
  }) {
    return {
      'type': messageTypeOrder,
      'action': actionViewOrder,
      'id': orderId,
      'title': title ?? 'Order Update',
      'body': body ?? 'Your order #$orderId status has been updated to $status',
      'priority': priorityHigh,
      'orderStatus': status,
    };
  }

  /// Create message for product availability
  static Map<String, dynamic> createProductMessage({
    required String productId,
    required String productName,
    String? action,
    String? body,
  }) {
    return {
      'type': messageTypeProduct,
      'action': action ?? actionViewProduct,
      'id': productId,
      'title': 'Product Update',
      'body': body ?? '$productName is now available',
      'priority': priorityMedium,
      'productName': productName,
    };
  }

  /// Create message for subscription update
  static Map<String, dynamic> createSubscriptionMessage({
    required String subscriptionId,
    required String status,
    String? title,
    String? body,
  }) {
    return {
      'type': messageTypeSubscription,
      'action': actionViewSubscription,
      'id': subscriptionId,
      'title': title ?? 'Subscription Update',
      'body': body ?? 'Your subscription status has been updated to $status',
      'priority': priorityHigh,
      'subscriptionStatus': status,
    };
  }

  /// Create message for promotion
  static Map<String, dynamic> createPromoMessage({
    required String promoId,
    required String promoTitle,
    String? body,
    String? discount,
  }) {
    return {
      'type': messageTypePromo,
      'action': actionOpenPromo,
      'id': promoId,
      'title': promoTitle,
      'body': body ?? 'Special offer available!',
      'priority': priorityMedium,
      'discount': discount,
    };
  }

  /// Get action description for UI
  static String getActionDescription(String? action) {
    switch (action) {
      case actionViewOrder:
        return 'View Order';
      case actionViewProduct:
        return 'View Product';
      case actionViewSubscription:
        return 'View Subscription';
      case actionOpenCart:
        return 'Open Cart';
      case actionOpenProfile:
        return 'Open Profile';
      case actionOpenPromo:
        return 'View Offer';
      case actionOpenSettings:
        return 'Open Settings';
      default:
        return 'View Details';
    }
  }

  /// Check if message requires user action
  static bool requiresUserAction(Map<String, dynamic> data) {
    String? action = data['action'];
    return action != null && action.isNotEmpty;
  }

  /// Get message category for grouping
  static String getMessageCategory(String messageType) {
    switch (messageType) {
      case messageTypeOrder:
      case messageTypeSubscription:
        return 'orders';
      case messageTypeProduct:
        return 'products';
      case messageTypePromo:
        return 'promotions';
      default:
        return 'general';
    }
  }
} 