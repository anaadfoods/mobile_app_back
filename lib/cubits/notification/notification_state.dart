import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:grocery_app/models/notification_model.dart';

abstract class NotificationState extends Equatable {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? fcmToken;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.fcmToken,
    this.isLoading = false,
    this.error,
  });

  @override
  List<Object?> get props => [notifications, unreadCount, fcmToken, isLoading, error];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial() : super(isLoading: false);
}

class NotificationLoading extends NotificationState {
  const NotificationLoading({
    super.notifications,
    super.unreadCount,
    super.fcmToken,
  }) : super(isLoading: true);
}

/// A state that holds the current FCM token and notifications list.
class NotificationSuccess extends NotificationState {
  const NotificationSuccess({
    super.notifications,
    super.unreadCount,
    super.fcmToken,
  }) : super(isLoading: false);

  NotificationSuccess copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    String? fcmToken,
  }) {
    return NotificationSuccess(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(
    this.message, {
    super.notifications,
    super.unreadCount,
    super.fcmToken,
  }) : super(isLoading: false, error: message);

  @override
  List<Object?> get props => [...super.props, message];
}

/// A transient state emitted when a notification is received in the foreground.
/// The UI can listen for this to show an in-app banner or SnackBar.
class NotificationReceived extends NotificationState {
  final RemoteMessage message;
  const NotificationReceived(
    this.message, {
    super.notifications,
    super.unreadCount,
    super.fcmToken,
  }) : super(isLoading: false);

  @override
  List<Object?> get props => [...super.props, message];
}

/// A transient state representing the intent to navigate.
/// This decouples the Cubit from the NavigationService.
class NavigateToRoute extends NotificationState {
  final String routeName;
  final int? arguments; // Use a simple type like int for the ID

  const NavigateToRoute(
    this.routeName, {
    this.arguments,
    super.notifications,
    super.unreadCount,
    super.fcmToken,
  }) : super(isLoading: false);

  @override
  List<Object?> get props => [...super.props, routeName, arguments];
}