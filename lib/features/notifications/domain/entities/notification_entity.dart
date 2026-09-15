/// Pure Dart domain entity representing a notification.
class NotificationEntity {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? action;
  final String source;
  final String? originDeviceId;
  final bool isRead;
  final bool isDismissed;
  final int syncVersion;
  final int timestamp;
  final String? image;
  final String priority;
  final Map<String, dynamic> metadata;

  const NotificationEntity({
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

  NotificationEntity copyWith({
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
    return NotificationEntity(
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
}
