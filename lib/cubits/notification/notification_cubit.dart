import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/repositories/notification_repository.dart';
import 'package:grocery_app/cubits/notification/notification_state.dart';

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
    emit(const NotificationSuccess(fcmToken: null)); // Clear the token from state
  }

  /// Processes a notification that was tapped by the user.
  void handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final String? type = data['type'];
    final int? id = data['id'] != null ? int.tryParse(data['id']) : null;

    switch (type) {
      case 'order':
        emit(NavigateToRoute('/order_details', arguments: id));
        break;
      case 'subscription':
      case 'payment':
        emit(NavigateToRoute('/subscription_details', arguments: id));
        break;
      case 'product':
        emit(NavigateToRoute('/product_details', arguments: id));
        break;
      default:
        emit(const NavigateToRoute('/notifications'));
        break;
    }
  }

  /// Processes a notification received while the app is in the foreground.
  void handleForegroundNotification(RemoteMessage message) {
    // Emits a state that the UI can listen to for showing an in-app banner.
    emit(NotificationReceived(message));
  }
}