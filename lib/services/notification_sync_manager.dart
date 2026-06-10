import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:grocery_app/service_locator.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import 'connectivity_service.dart';
import 'token_service.dart';


enum QueueActionType { registerLocal, markRead, dismiss }

class PendingQueueItem {
  final String id;
  final QueueActionType actionType;
  final Map<String, dynamic> data;
  final int retryCount;

  PendingQueueItem({
    required this.id,
    required this.actionType,
    required this.data,
    this.retryCount = 0,
  });

  factory PendingQueueItem.fromJson(Map<String, dynamic> json) {
    return PendingQueueItem(
      id: json['id'] ?? '',
      actionType: QueueActionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['action_type'],
        orElse: () => QueueActionType.markRead,
      ),
      data: json['data'] ?? {},
      retryCount: json['retry_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action_type': actionType.toString().split('.').last,
      'data': data,
      'retry_count': retryCount,
    };
  }

  PendingQueueItem copyWith({
    String? id,
    QueueActionType? actionType,
    Map<String, dynamic>? data,
    int? retryCount,
  }) {
    return PendingQueueItem(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      data: data ?? this.data,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}


class NotificationSyncManager {
  static final NotificationSyncManager _instance = NotificationSyncManager._internal();
  factory NotificationSyncManager() => getIt<NotificationSyncManager>();
  NotificationSyncManager._internal() {
    _initConnectivityListener();
  }
  static NotificationSyncManager create() => NotificationSyncManager._internal();

  final NotificationRepository _repository = getIt<NotificationRepository>();
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();
  final TokenService _tokenService = getIt<TokenService>();

  // Keys for SharedPreferences
  static const String _notificationsKey = 'notifications';
  static const String _syncVersionKey = 'notification_sync_version';
  static const String _unreadCountKey = 'notification_count';
  static const String _pendingQueueKey = 'notification_pending_queue';

  // Broadcast stream to notify UI of any notification state changes
  final StreamController<void> _syncEventController = StreamController<void>.broadcast();
  Stream<void> get onSyncEvent => _syncEventController.stream;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void _initConnectivityListener() {
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((results) async {
      final isConnected = !results.contains(ConnectivityResult.none);
      if (isConnected) {
        debugPrint('[SyncManager] Internet reconnected. Flushing offline queue and syncing...');
        await flushPendingQueue();
        await syncWithBackend();
      }
    });
  }

  /// Get the current local notifications list
  Future<List<NotificationModel>> getLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_notificationsKey);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => NotificationModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('[SyncManager] Error reading local notifications: $e');
      return [];
    }
  }

  /// Save notifications list locally
  Future<void> _saveLocalNotifications(List<NotificationModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    // Trim the list to the latest 100 items to prevent storage bloat and ensure fast serialization (production-hardened limit)
    final trimmedList = list.length > 100 ? list.sublist(0, 100) : list;
    final jsonStr = jsonEncode(trimmedList.map((n) => n.toJson()).toList());
    await prefs.setString(_notificationsKey, jsonStr);
    
    // Recalculate unread count
    final unread = trimmedList.where((n) => !n.isRead && !n.isDismissed).length;
    await prefs.setInt(_unreadCountKey, unread);
    _syncEventController.add(null);
  }

  /// Save a server-pushed notification to local storage
  Future<void> saveServerPushNotification(NotificationModel notification) async {
    final localList = await getLocalNotifications();
    localList.removeWhere((n) => n.id == notification.id);
    localList.insert(0, notification);
    await _saveLocalNotifications(localList);
  }

  /// Get stored sync version
  Future<int> getSyncVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_syncVersionKey) ?? 0;
  }

  /// Save sync version
  Future<void> _saveSyncVersion(int version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_syncVersionKey, version);
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_unreadCountKey) ?? 0;
  }

  /// Perform incremental synchronization with Django backend
  Future<void> syncWithBackend() async {
    final isLoggedIn = await _tokenService.isLoggedIn();
    if (!isLoggedIn) {
      debugPrint('[SyncManager] Sync skipped: user not logged in');
      return;
    }
    if (_isSyncing) {
      debugPrint('[SyncManager] Sync skipped: already syncing');
      return;
    }
    _isSyncing = true;
    _syncEventController.add(null);

    try {
      final currentVersion = await getSyncVersion();
      debugPrint('[SyncManager] Starting sync since version $currentVersion');

      final syncData = await _repository.syncNotifications(currentVersion);
      final List<NotificationModel> serverChanges = syncData['notifications'];
      final int latestVersion = syncData['latest_version'];

      debugPrint('[SyncManager] Server returned ${serverChanges.length} changes, latest_version=$latestVersion');

      if (serverChanges.isNotEmpty) {
        final localList = await getLocalNotifications();
        debugPrint('[SyncManager] Local list has ${localList.length} notifications before merge');
        final Map<String, NotificationModel> merged = {
          for (var n in localList) n.id: n
        };

        for (var serverNotif in serverChanges) {
          if (serverNotif.isDismissed) {
            // Remove swiped away notifications from local view
            merged.remove(serverNotif.id);
          } else {
            merged[serverNotif.id] = serverNotif;
          }
        }

        final updatedList = merged.values.toList();
        // Sort by timestamp descending
        updatedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        await _saveLocalNotifications(updatedList);
        debugPrint('[SyncManager] Saved ${updatedList.length} notifications after merge');
      } else {
        debugPrint('[SyncManager] No new changes from server');
      }

      await _saveSyncVersion(latestVersion);
      
      // Update unread count from server to ensure perfect synchronization
      try {
        final serverUnread = await _repository.getUnreadCount();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_unreadCountKey, serverUnread);
        debugPrint('[SyncManager] Unread count from server: $serverUnread');
      } catch (e) {
        debugPrint('[SyncManager] Error getting server unread count: $e');
      }

      debugPrint('[SyncManager] Sync completed. New version: $latestVersion');
    } catch (e, stackTrace) {
      debugPrint('[SyncManager] Sync failed: $e');
      debugPrint('[SyncManager] Stack trace: $stackTrace');
    } finally {
      _isSyncing = false;
      _syncEventController.add(null);
    }
  }

  /// Register a locally generated notification immediately and push to backend
  Future<void> registerLocalNotification(NotificationModel notification) async {
    // 1. Save locally first (Optimistic)
    final localList = await getLocalNotifications();
    localList.insert(0, notification);
    await _saveLocalNotifications(localList);

    // 2. Try registering with backend
    if (await _connectivityService.hasConnection && await _tokenService.isLoggedIn()) {
      try {
        debugPrint('[SyncManager] Pushing local notification to backend...');
        final registered = await _repository.registerLocalNotification(notification);
        
        // Update local list with server-provided ID and version
        final currentList = await getLocalNotifications();
        final index = currentList.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          currentList[index] = registered;
          await _saveLocalNotifications(currentList);
        }
        debugPrint('[SyncManager] Local notification successfully registered.');
      } catch (e) {
        debugPrint('[SyncManager] Registration failed, queuing for offline retry: $e');
        await _enqueueAction(QueueActionType.registerLocal, notification.id, notification.toJson());
      }
    } else {
      debugPrint('[SyncManager] Offline. Queuing local registration.');
      await _enqueueAction(QueueActionType.registerLocal, notification.id, notification.toJson());
    }
  }

  /// Mark notifications as read optimistically, and push to backend
  Future<void> markAsRead(List<String> ids) async {
    if (ids.isEmpty) return;

    // 1. Optimistic Update locally
    final localList = await getLocalNotifications();
    bool updated = false;
    for (var i = 0; i < localList.length; i++) {
      if (ids.contains(localList[i].id)) {
        localList[i] = localList[i].copyWith(isRead: true);
        updated = true;
      }
    }
    if (updated) {
      await _saveLocalNotifications(localList);
    }

    // 2. Call backend or queue
    if (await _connectivityService.hasConnection && await _tokenService.isLoggedIn()) {
      try {
        final result = await _repository.markNotificationsAsRead(ids);
        if (result['sync_version'] != null) {
          await _saveSyncVersion(result['sync_version']);
        }
        debugPrint('[SyncManager] Marked read on backend.');
      } catch (e) {
        debugPrint('[SyncManager] Mark read failed. Queuing.');
        await _enqueueAction(QueueActionType.markRead, ids.first, {'ids': ids});
      }
    } else {
      await _enqueueAction(QueueActionType.markRead, ids.first, {'ids': ids});
    }
  }

  /// Swiped away / Dismissed notifications optimistically, and push to backend
  Future<void> dismiss(List<String> ids) async {
    if (ids.isEmpty) return;

    // 1. Optimistic Update locally (Remove from UI immediately)
    final localList = await getLocalNotifications();
    final updatedList = localList.where((n) => !ids.contains(n.id)).toList();
    await _saveLocalNotifications(updatedList);

    // 2. Call backend or queue
    if (await _connectivityService.hasConnection && await _tokenService.isLoggedIn()) {
      try {
        final result = await _repository.markNotificationsAsDismissed(ids);
        if (result['sync_version'] != null) {
          await _saveSyncVersion(result['sync_version']);
        }
        debugPrint('[SyncManager] Dismissed on backend.');
      } catch (e) {
        debugPrint('[SyncManager] Dismiss failed. Queuing.');
        await _enqueueAction(QueueActionType.dismiss, ids.first, {'ids': ids});
      }
    } else {
      await _enqueueAction(QueueActionType.dismiss, ids.first, {'ids': ids});
    }
  }

  /// Save action in offline pending queue
  Future<void> _enqueueAction(QueueActionType type, String id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString(_pendingQueueKey);
    List<PendingQueueItem> queue = [];
    if (queueStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(queueStr);
        queue = decoded.map((item) => PendingQueueItem.fromJson(item)).toList();
      } catch (e) {
        debugPrint('[SyncManager] Corrupt pending queue json, resetting: $e');
        await prefs.remove(_pendingQueueKey);
      }
    }
    
    // Avoid duplicates for same id and action
    queue.removeWhere((item) => item.id == id && item.actionType == type);
    
    queue.add(PendingQueueItem(id: id, actionType: type, data: data, retryCount: 0));
    await prefs.setString(_pendingQueueKey, jsonEncode(queue.map((item) => item.toJson()).toList()));
  }

  /// Flush/process the offline action queue
  Future<void> flushPendingQueue() async {
    if (!await _connectivityService.hasConnection) return;
    if (!await _tokenService.isLoggedIn()) return;

    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString(_pendingQueueKey);
    if (queueStr == null) return;

    List<PendingQueueItem> queue;
    try {
      final List<dynamic> decoded = jsonDecode(queueStr);
      queue = decoded.map((item) => PendingQueueItem.fromJson(item)).toList();
    } catch (e) {
      debugPrint('[SyncManager] Corrupt pending queue json on flush, clearing: $e');
      await prefs.remove(_pendingQueueKey);
      return;
    }

    if (queue.isEmpty) return;
    debugPrint('[SyncManager] Flushing ${queue.length} pending offline actions...');

    List<PendingQueueItem> failedItems = [];

    for (var item in queue) {
      try {
        switch (item.actionType) {
          case QueueActionType.registerLocal:
            final notif = NotificationModel.fromJson(item.data);
            final registered = await _repository.registerLocalNotification(notif);
            
            // Reconcile registered local notification database ID
            final currentList = await getLocalNotifications();
            final index = currentList.indexWhere((n) => n.id == notif.id);
            if (index != -1) {
              currentList[index] = registered;
              await _saveLocalNotifications(currentList);
            }
            break;
          case QueueActionType.markRead:
            final List<String> ids = List<String>.from(item.data['ids'] ?? []);
            final result = await _repository.markNotificationsAsRead(ids);
            if (result['sync_version'] != null) {
              await _saveSyncVersion(result['sync_version']);
            }
            break;
          case QueueActionType.dismiss:
            final List<String> ids = List<String>.from(item.data['ids'] ?? []);
            final result = await _repository.markNotificationsAsDismissed(ids);
            if (result['sync_version'] != null) {
              await _saveSyncVersion(result['sync_version']);
            }
            break;
        }
      } catch (e) {
        debugPrint('[SyncManager] Action ${item.actionType} failed during flush: $e');
        final incremented = item.copyWith(retryCount: item.retryCount + 1);
        if (incremented.retryCount >= 5) {
          debugPrint('[SyncManager] Action ${item.actionType} reached max retries (5) and was discarded.');
        } else {
          failedItems.add(incremented);
        }
      }
    }

    // Save remaining failed items back to queue
    await prefs.setString(_pendingQueueKey, jsonEncode(failedItems.map((item) => item.toJson()).toList()));
    debugPrint('[SyncManager] Offline queue flush cycle completed. Remaining actions: ${failedItems.length}');
  }

  // --- FUTURE WEBSOCKET ARCHITECTURE PREPARATION ---

  // Placeholder fields for WebSocket client connection
  Object? _webSocketChannel; // Will be IOWebSocketChannel once imported
  Timer? _wsReconnectTimer;

  /// Setup websocket-ready structure and stub routing
  Future<void> connectWebSocket() async {
    final token = await _tokenService.getAccessToken();
    if (token == null) return;
    
    final deviceId = await _repository.getDeviceId();
    final platform = Platform.isAndroid ? 'android' : 'ios';
    final wsUrl = 'wss://bck.anaadfoods.com/ws/notifications/?token=$token&device_id=$deviceId&platform=$platform';
    
    debugPrint('[SyncManager] Preparing WebSocket connection placeholder to: $wsUrl');
    // In future integration:
    // _webSocketChannel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
    // _webSocketChannel.stream.listen((message) => _handleWebSocketEvent(message), ...);
  }

  /// Stub event handler for incoming WebSocket synchronized packets
  void handleWebSocketEventPlaceholder(String eventPayload) {
    try {
      final Map<String, dynamic> event = jsonDecode(eventPayload);
      final String type = event['type'] ?? '';
      
      switch (type) {
        case 'NOTIFICATION_CREATED':
          debugPrint('[SyncManager] WS: Notification created.');
          // Sync dynamically or parse direct notification payload
          syncWithBackend();
          break;
        case 'NOTIFICATION_READ':
          debugPrint('[SyncManager] WS: Notification read.');
          syncWithBackend();
          break;
        case 'NOTIFICATION_DISMISSED':
          debugPrint('[SyncManager] WS: Notification dismissed.');
          syncWithBackend();
          break;
      }
    } catch (e) {
      debugPrint('[SyncManager] Error in WebSocket event parsing: $e');
    }
  }

  void disconnectWebSocket() {
    _wsReconnectTimer?.cancel();
    // Close channel if initialized
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncEventController.close();
    disconnectWebSocket();
  }
}
