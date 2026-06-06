import 'dart:convert';

class NotificationModel {
  final String id; // Keep as string for compatibility with LOCAL_DEVICE_ID_TIMESTAMP format
  final String title;
  final String body;
  final String type;
  final String? action;
  final String source; // 'SERVER' or 'LOCAL_DEVICE_APP'
  final String? originDeviceId;
  final bool isRead;
  final bool isDismissed;
  final int syncVersion;
  final int timestamp; // Milliseconds since epoch
  final String? image;
  final String priority;
  final Map<String, dynamic> metadata;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.action,
    required this.source,
    this.originDeviceId,
    required this.isRead,
    required this.isDismissed,
    required this.syncVersion,
    required this.timestamp,
    this.image,
    required this.priority,
    required this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Reconcile standard backend structure with existing app structure
    String extractedId = (json['id'] ?? '').toString();
    
    // Support backend 'message' field mapping to 'body'
    String bodyVal = json['body'] ?? json['message'] ?? '';
    
    // Parse metadata
    Map<String, dynamic> metadataVal = {};
    if (json['metadata'] != null) {
      if (json['metadata'] is String) {
        try {
          metadataVal = jsonDecode(json['metadata']);
        } catch (_) {}
      } else if (json['metadata'] is Map) {
        metadataVal = Map<String, dynamic>.from(json['metadata']);
      }
    }

    // Attempt to parse timestamp, default to now
    int ts = json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
    if (json['created_at'] != null) {
      try {
        ts = DateTime.parse(json['created_at']).millisecondsSinceEpoch;
      } catch (_) {}
    } else if (json['delivered_at'] != null) {
      try {
        ts = DateTime.parse(json['delivered_at']).millisecondsSinceEpoch;
      } catch (_) {}
    }

    return NotificationModel(
      id: extractedId,
      title: json['title'] ?? '',
      body: bodyVal,
      type: json['type'] ?? 'general',
      action: json['action'] ?? metadataVal['action'],
      source: json['source'] ?? 'SERVER',
      originDeviceId: json['origin_device_id'],
      isRead: json['is_read'] ?? json['read'] ?? false,
      isDismissed: json['is_dismissed'] ?? json['dismissed'] ?? false,
      syncVersion: json['sync_version'] ?? 0,
      timestamp: ts,
      image: json['image'] ?? json['image_url'] ?? metadataVal['image'],
      priority: json['priority'] ?? 'medium',
      metadata: metadataVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': int.tryParse(id) ?? id, // Attempt to parse as int for backend if numeric
      'title': title,
      'body': body,
      'message': body, // duplicate to match backend 'message' key
      'type': type,
      'action': action,
      'source': source,
      'origin_device_id': originDeviceId,
      'is_read': isRead,
      'is_dismissed': isDismissed,
      'sync_version': syncVersion,
      'timestamp': timestamp,
      'image': image,
      'priority': priority,
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? action,
    String? source,
    String? originDeviceId,
    bool? isRead,
    bool? isDismissed,
    int? syncVersion,
    int? timestamp,
    String? image,
    String? priority,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      action: action ?? this.action,
      source: source ?? this.source,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      syncVersion: syncVersion ?? this.syncVersion,
      timestamp: timestamp ?? this.timestamp,
      image: image ?? this.image,
      priority: priority ?? this.priority,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toLocalMap() {
    // For backward compatibility with existing screen code that expects standard map fields
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'action': action,
      'source': source,
      'origin_device_id': originDeviceId,
      'read': isRead,
      'is_read': isRead,
      'is_dismissed': isDismissed,
      'sync_version': syncVersion,
      'timestamp': timestamp,
      'image': image,
      'priority': priority,
      'metadata': metadata,
    };
  }
}
