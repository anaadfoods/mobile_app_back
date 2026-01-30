import 'package:intl/intl.dart';

/// Helper function to parse dates in format "DD-MM-YYYY HH:mm"
DateTime? _parseCustomDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;

  try {
    // Try parsing "DD-MM-YYYY HH:mm" format
    final format = DateFormat('dd-MM-yyyy HH:mm');
    return format.parseStrict(dateString);
  } catch (_) {
    // Try ISO 8601 as fallback
    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return null;
    }
  }
}

/// Model representing Shiprocket order tracking data.
class OrderTracking {
  final int id;
  final int order;
  final int? subscription;
  final String orderNumber;
  final String? subscriptionNumber;
  final String orderStatus;
  final String? awbNumber;
  final DateTime? estimatedDelivery;
  final DateTime? pickupScheduledAt;
  final String status; // Top-level status like "IN TRANSIT"
  final List<TrackingEvent> trackingEvents;

  OrderTracking({
    required this.id,
    required this.order,
    this.subscription,
    required this.orderNumber,
    this.subscriptionNumber,
    required this.orderStatus,
    this.awbNumber,
    this.estimatedDelivery,
    this.pickupScheduledAt,
    required this.status,
    required this.trackingEvents,
  });

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    return OrderTracking(
      id: json['id'] ?? 0,
      order: json['order'] ?? 0,
      subscription: json['subscription'],
      orderNumber: json['order_number'] ?? '',
      subscriptionNumber: json['subscription_number'],
      orderStatus: json['order_status'] ?? '',
      awbNumber: json['awb_number'],
      estimatedDelivery: _parseCustomDate(json['estimated_delivery']),
      pickupScheduledAt: _parseCustomDate(json['pickup_scheduled_at']),
      status: json['status'] ?? '',
      trackingEvents:
          (json['tracking_events'] as List<dynamic>?)
              ?.map((e) => TrackingEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Get the current stage index for the status stepper (0-4)
  /// Uses the top-level status field for accurate tracking
  int get currentStageIndex {
    final currentStatus = status.toUpperCase().replaceAll(' ', '_');
    switch (currentStatus) {
      case 'MANIFESTED':
      case 'PENDING':
      case 'OUT_FOR_PICKUP':
        return 0;
      case 'PICKED_UP':
      case 'PICKUP':
        return 1;
      case 'IN_TRANSIT':
      case 'SHIPPED':
        return 2;
      case 'OUT_FOR_DELIVERY':
        return 3;
      case 'DELIVERED':
        return 4;
      case 'CANCELLED':
      case 'RTO':
        return -1; // Special case for cancelled/returned orders
      default:
        return 0;
    }
  }

  /// Check if order is in a terminal state
  bool get isTerminalState =>
      status.toUpperCase() == 'DELIVERED' ||
      status.toUpperCase() == 'CANCELLED' ||
      status.toUpperCase() == 'RTO';
}

/// Model representing a single tracking event from the courier.
class TrackingEvent {
  final int id;
  final String status;
  final String location;
  final String activity;
  final DateTime timestamp;
  final String courierStatus;
  final String courierStatusCode;
  final DateTime createdAt;

  TrackingEvent({
    required this.id,
    required this.status,
    required this.location,
    required this.activity,
    required this.timestamp,
    required this.courierStatus,
    required this.courierStatusCode,
    required this.createdAt,
  });

  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      location: json['location'] ?? '',
      activity: json['activity'] ?? '',
      timestamp: _parseCustomDate(json['timestamp']) ?? DateTime(1970, 1, 1),
      courierStatus: json['courier_status'] ?? '',
      courierStatusCode: (json['courier_status_code'] ?? '').toString(),
      createdAt: _parseCustomDate(json['created_at']) ?? DateTime(1970, 1, 1),
    );
  }
}
