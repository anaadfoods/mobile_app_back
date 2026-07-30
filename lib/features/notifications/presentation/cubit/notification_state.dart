import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../domain/entities/notification_entity.dart';

abstract class NotificationState extends Equatable {
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final String? fcmToken;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.fcmToken,
  });

  @override
  List<Object?> get props => [notifications, unreadCount, fcmToken];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial() : super();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading({
    super.notifications,
    super.unreadCount,
    super.fcmToken,
  });
}

class NotificationSuccess extends NotificationState {
  const NotificationSuccess({
    super.notifications,
    super.unreadCount,
    super.fcmToken,
  });
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(
    this.message, {
    super.notifications,
    super.unreadCount,
    super.fcmToken,
  });

  @override
  List<Object?> get props => [message, notifications, unreadCount, fcmToken];
}

class NotificationReceived extends NotificationState {
  final RemoteMessage message;

  const NotificationReceived(
    this.message, {
    super.notifications,
    super.unreadCount,
    super.fcmToken,
  });

  @override
  List<Object?> get props => [message, notifications, unreadCount, fcmToken];
}
