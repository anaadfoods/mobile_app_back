import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/repositories/notification_repository.dart';
import 'package:grocery_app/cubits/notification/notification_state.dart';
import 'package:grocery_app/services/notification_service.dart';
import 'package:grocery_app/services/navigation_service.dart';

/// Cubit for managing notification state and device registration.
///
/// IMPORTANT: Notification tap handling is delegated to NotificationService.handleRedirection
/// for centralized, consistent routing based on the `screen` key in the payload.
class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationCubit({required NotificationRepository notificationRepository})
    : _notificationRepository = notificationRepository,
      super(NotificationInitial());

  /// Called on login to register the device token with the backend.
  Future<void> registerDevice() async {
    final fcmToken = await _notificationRepository.getStoredFCMToken();
    if (fcmToken != null) {
      await _notificationRepository.registerToken(fcmToken);
      emit(NotificationSuccess(fcmToken: fcmToken));
    }
  }

  /// Called on logout to remove the device token from the backend.
  Future<void> unregisterDevice() async {
    await _notificationRepository.removeToken();
    emit(
      const NotificationSuccess(fcmToken: null),
    ); // Clear the token from state
  }

  /// Processes a notification that was tapped by the user.
  ///
  /// IMPORTANT: Delegates to NotificationService.handleRedirection for consistent
  /// screen-based routing. Uses lifecycle-safe navigation wrapper.
  void handleNotificationTap(RemoteMessage message) {
    // Delegate to centralized routing in NotificationService
    // This ensures consistent navigation using the 'screen' key from payload
    NavigationService.safeNavigate(() {
      NotificationService().handleRedirection(message.data);
    });
  }

  /// Processes a notification received while the app is in the foreground.
  void handleForegroundNotification(RemoteMessage message) {
    // Emits a state that the UI can listen to for showing an in-app banner.
    emit(NotificationReceived(message));
  }
}
