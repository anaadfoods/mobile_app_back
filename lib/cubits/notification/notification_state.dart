import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

/// A state that holds the current FCM token, if available.
class NotificationSuccess extends NotificationState {
  final String? fcmToken;
  const NotificationSuccess({this.fcmToken});
  @override
  List<Object?> get props => [fcmToken];
}

/// A transient state emitted when a notification is received in the foreground.
/// The UI can listen for this to show an in-app banner or SnackBar.
class NotificationReceived extends NotificationState {
  final RemoteMessage message;
  const NotificationReceived(this.message);
  @override
  List<Object?> get props => [message];
}

/// A transient state representing the intent to navigate.
/// This decouples the Cubit from the NavigationService.
class NavigateToRoute extends NotificationState {
  final String routeName;
  final int? arguments; // Use a simple type like int for the ID

  const NavigateToRoute(this.routeName, {this.arguments});

  @override
  List<Object?> get props => [routeName, arguments];
}