import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/services/navigation_service.dart';
import 'package:grocery_app/services/notification_service.dart';
import 'package:grocery_app/service_locator.dart';

import '../../domain/usecases/get_local_notifications_use_case.dart';
import '../../domain/usecases/get_unread_count_use_case.dart';
import '../../domain/usecases/sync_notifications_use_case.dart';
import '../../domain/usecases/mark_notifications_as_read_use_case.dart';
import '../../domain/usecases/dismiss_notifications_use_case.dart';
import '../../domain/usecases/register_device_token_use_case.dart';
import '../../domain/usecases/unregister_device_token_use_case.dart';
import '../../domain/usecases/reset_notification_badge_use_case.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final GetLocalNotificationsUseCase _getLocalNotificationsUseCase;
  final GetUnreadCountUseCase _getUnreadCountUseCase;
  final SyncNotificationsUseCase _syncNotificationsUseCase;
  final MarkNotificationsAsReadUseCase _markNotificationsAsReadUseCase;
  final DismissNotificationsUseCase _dismissNotificationsUseCase;
  final RegisterDeviceTokenUseCase _registerDeviceTokenUseCase;
  final UnregisterDeviceTokenUseCase _unregisterDeviceTokenUseCase;
  final ResetNotificationBadgeUseCase _resetNotificationBadgeUseCase;

  NotificationCubit({
    GetLocalNotificationsUseCase? getLocalNotificationsUseCase,
    GetUnreadCountUseCase? getUnreadCountUseCase,
    SyncNotificationsUseCase? syncNotificationsUseCase,
    MarkNotificationsAsReadUseCase? markNotificationsAsReadUseCase,
    DismissNotificationsUseCase? dismissNotificationsUseCase,
    RegisterDeviceTokenUseCase? registerDeviceTokenUseCase,
    UnregisterDeviceTokenUseCase? unregisterDeviceTokenUseCase,
    ResetNotificationBadgeUseCase? resetNotificationBadgeUseCase,
  })  : _getLocalNotificationsUseCase =
            getLocalNotificationsUseCase ?? getIt<GetLocalNotificationsUseCase>(),
        _getUnreadCountUseCase =
            getUnreadCountUseCase ?? getIt<GetUnreadCountUseCase>(),
        _syncNotificationsUseCase =
            syncNotificationsUseCase ?? getIt<SyncNotificationsUseCase>(),
        _markNotificationsAsReadUseCase =
            markNotificationsAsReadUseCase ?? getIt<MarkNotificationsAsReadUseCase>(),
        _dismissNotificationsUseCase =
            dismissNotificationsUseCase ?? getIt<DismissNotificationsUseCase>(),
        _registerDeviceTokenUseCase =
            registerDeviceTokenUseCase ?? getIt<RegisterDeviceTokenUseCase>(),
        _unregisterDeviceTokenUseCase =
            unregisterDeviceTokenUseCase ?? getIt<UnregisterDeviceTokenUseCase>(),
        _resetNotificationBadgeUseCase =
            resetNotificationBadgeUseCase ?? getIt<ResetNotificationBadgeUseCase>(),
        super(const NotificationInitial()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    emit(NotificationLoading(
      notifications: state.notifications,
      unreadCount: state.unreadCount,
      fcmToken: state.fcmToken,
    ));

    try {
      final notifications = await _getLocalNotificationsUseCase();
      final unreadCount = await _getUnreadCountUseCase();
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

  Future<void> syncNotifications() async {
    emit(NotificationLoading(
      notifications: state.notifications,
      unreadCount: state.unreadCount,
      fcmToken: state.fcmToken,
    ));
    try {
      final notifications = await _syncNotificationsUseCase(0);
      final unreadCount = await _getUnreadCountUseCase();
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

  Future<void> markAsRead(List<String> ids) async {
    try {
      await _markNotificationsAsReadUseCase(ids);
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

  Future<void> dismiss(List<String> ids) async {
    try {
      await _dismissNotificationsUseCase(ids);
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

  Future<void> clearAllNotifications() async {
    try {
      final ids = state.notifications.map((n) => n.id).toList();
      if (ids.isNotEmpty) {
        await _dismissNotificationsUseCase(ids);
        await loadNotifications();
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

  Future<void> resetNotificationBadgeCount() async {
    try {
      await _resetNotificationBadgeUseCase();
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

  Future<void> registerDeviceToken(String fcmToken) async {
    try {
      await _registerDeviceTokenUseCase(fcmToken);
      emit(NotificationSuccess(
        notifications: state.notifications,
        unreadCount: state.unreadCount,
        fcmToken: fcmToken,
      ));
    } catch (_) {}
  }

  Future<void> registerDevice() async {
    final token = state.fcmToken;
    if (token != null) {
      await registerDeviceToken(token);
    }
  }

  Future<void> unregisterDevice() async {
    try {
      await _unregisterDeviceTokenUseCase();
      emit(const NotificationSuccess(
        notifications: [],
        unreadCount: 0,
        fcmToken: null,
      ));
    } catch (_) {}
  }

  void handleNotificationTap(RemoteMessage message) {
    NavigationService.safeNavigate(() {
      getIt<NotificationService>().handleRedirection(message.data);
    });
  }

  void handleForegroundNotification(RemoteMessage message) {
    emit(NotificationReceived(
      message,
      notifications: state.notifications,
      unreadCount: state.unreadCount,
      fcmToken: state.fcmToken,
    ));
    emit(NotificationSuccess(
      notifications: state.notifications,
      unreadCount: state.unreadCount,
      fcmToken: state.fcmToken,
    ));
  }
}
