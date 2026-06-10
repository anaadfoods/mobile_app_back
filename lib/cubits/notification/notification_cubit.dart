import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/repositories/notification_repository.dart';
import 'package:grocery_app/cubits/notification/notification_state.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/services/notification_service.dart';
import 'package:grocery_app/services/navigation_service.dart';
import 'package:grocery_app/services/notification_sync_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cubit for managing notification state and device registration.
///
/// IMPORTANT: Notification tap handling is delegated to NotificationService.handleRedirection
/// for centralized, consistent routing based on the `screen` key in the payload.
class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _notificationRepository;
  final NotificationSyncManager _syncManager;
  final NotificationService _notificationService;
  StreamSubscription? _syncSubscription;
  StreamSubscription? _messageReceivedSubscription;

  NotificationCubit({
    required NotificationRepository notificationRepository,
    NotificationSyncManager? syncManager,
    NotificationService? notificationService,
  })  : _notificationRepository = notificationRepository,
        _syncManager = syncManager ?? getIt<NotificationSyncManager>(),
        _notificationService = notificationService ?? getIt<NotificationService>(),
        super(const NotificationInitial()) {
    
    // Listen to sync events from NotificationSyncManager to auto-refresh state
    _syncSubscription = _syncManager.onSyncEvent.listen((_) {
      loadNotifications();
    });

    // Listen to new foreground messages to auto-refresh state
    _messageReceivedSubscription = _notificationService.onMessageReceived.listen((_) {
      loadNotifications();
    });

    // Initial load
    loadNotifications();
  }

  /// Load notifications from local storage and update unread count
  Future<void> loadNotifications() async {
    emit(NotificationLoading(
      notifications: state.notifications,
      unreadCount: state.unreadCount,
      fcmToken: state.fcmToken,
    ));

    try {
      final notifications = await _syncManager.getLocalNotifications();
      final unreadCount = await _syncManager.getUnreadCount();
      emit(NotificationSuccess(
        notifications: notifications,
        unreadCount: unreadCount,
        fcmToken: state.fcmToken,
      ));
    } catch (e) {
      emit(NotificationError(
        e.toString(),
        notifications: state.notifications,
        unreadCount: state.unreadCount,
        fcmToken: state.fcmToken,
      ));
    }
  }

  /// Trigger synchronization with Django backend
  Future<void> syncNotifications() async {
    emit(NotificationLoading(
      notifications: state.notifications,
      unreadCount: state.unreadCount,
      fcmToken: state.fcmToken,
    ));
    try {
      await _syncManager.flushPendingQueue();
      await _syncManager.syncWithBackend();
      await loadNotifications();
    } catch (e) {
      emit(NotificationError(
        e.toString(),
        notifications: state.notifications,
        unreadCount: state.unreadCount,
        fcmToken: state.fcmToken,
      ));
    }
  }

  /// Mark specific notifications as read
  Future<void> markAsRead(List<String> ids) async {
    try {
      await _syncManager.markAsRead(ids);
    } catch (e) {
      emit(NotificationError(
        e.toString(),
        notifications: state.notifications,
        unreadCount: state.unreadCount,
        fcmToken: state.fcmToken,
      ));
    }
  }

  /// Dismiss/remove specific notifications
  Future<void> dismiss(List<String> ids) async {
    try {
      await _syncManager.dismiss(ids);
      await _syncManager.markAsRead(ids); // Match dismiss + markAsRead logic
    } catch (e) {
      emit(NotificationError(
        e.toString(),
        notifications: state.notifications,
        unreadCount: state.unreadCount,
        fcmToken: state.fcmToken,
      ));
    }
  }

  /// Dismiss and clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final ids = state.notifications.map((n) => n.id).toList();
      if (ids.isNotEmpty) {
        await _syncManager.dismiss(ids);
      }
    } catch (e) {
      emit(NotificationError(
        e.toString(),
        notifications: state.notifications,
        unreadCount: state.unreadCount,
        fcmToken: state.fcmToken,
      ));
    }
  }

  /// Resets local notification count and emits state updates.
  Future<void> resetNotificationBadgeCount() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_count', 0);
      emit(NotificationSuccess(
        notifications: state.notifications,
        unreadCount: 0,
        fcmToken: state.fcmToken,
      ));
    } catch (e) {
      emit(NotificationError(
        e.toString(),
        notifications: state.notifications,
        unreadCount: state.unreadCount,
        fcmToken: state.fcmToken,
      ));
    }
  }

  /// Called on login to register the device token with the backend.
  Future<void> registerDevice() async {
    final fcmToken = await _notificationRepository.getStoredFCMToken();
    if (fcmToken != null) {
      await _notificationRepository.registerToken(fcmToken);
      emit(NotificationSuccess(
        notifications: state.notifications,
        unreadCount: state.unreadCount,
        fcmToken: fcmToken,
      ));
    }
  }

  /// Called on logout to remove the device token from the backend.
  Future<void> unregisterDevice() async {
    await _notificationRepository.removeToken();
    emit(const NotificationSuccess(
      notifications: [],
      unreadCount: 0,
      fcmToken: null,
    ));
  }

  /// Processes a notification that was tapped by the user.
  ///
  /// IMPORTANT: Delegates to NotificationService.handleRedirection for consistent
  /// screen-based routing. Uses lifecycle-safe navigation wrapper.
  void handleNotificationTap(RemoteMessage message) {
    // Delegate to centralized routing in NotificationService
    // This ensures consistent navigation using the 'screen' key from payload
    NavigationService.safeNavigate(() {
      getIt<NotificationService>().handleRedirection(message.data);
    });
  }

  /// Processes a notification received while the app is in the foreground.
  void handleForegroundNotification(RemoteMessage message) {
    // Emits a state that the UI can listen to for showing an in-app banner.
    emit(NotificationReceived(
      message,
      notifications: state.notifications,
      unreadCount: state.unreadCount,
      fcmToken: state.fcmToken,
    ));
    // Immediately revert to steady success state to maintain conscious state.
    emit(NotificationSuccess(
      notifications: state.notifications,
      unreadCount: state.unreadCount,
      fcmToken: state.fcmToken,
    ));
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    _messageReceivedSubscription?.cancel();
    return super.close();
  }
}
