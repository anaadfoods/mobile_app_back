import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:grocery_app/features/notifications/domain/usecases/get_local_notifications_use_case.dart';
import 'package:grocery_app/features/notifications/domain/usecases/get_unread_count_use_case.dart';
import 'package:grocery_app/features/notifications/domain/usecases/sync_notifications_use_case.dart';
import 'package:grocery_app/features/notifications/domain/usecases/mark_notifications_as_read_use_case.dart';
import 'package:grocery_app/features/notifications/domain/usecases/dismiss_notifications_use_case.dart';
import 'package:grocery_app/features/notifications/domain/usecases/register_device_token_use_case.dart';
import 'package:grocery_app/features/notifications/domain/usecases/unregister_device_token_use_case.dart';
import 'package:grocery_app/features/notifications/domain/usecases/reset_notification_badge_use_case.dart';
import 'package:grocery_app/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:grocery_app/features/notifications/presentation/cubit/notification_state.dart';

class MockGetLocalNotificationsUseCase extends Mock implements GetLocalNotificationsUseCase {}
class MockGetUnreadCountUseCase extends Mock implements GetUnreadCountUseCase {}
class MockSyncNotificationsUseCase extends Mock implements SyncNotificationsUseCase {}
class MockMarkNotificationsAsReadUseCase extends Mock implements MarkNotificationsAsReadUseCase {}
class MockDismissNotificationsUseCase extends Mock implements DismissNotificationsUseCase {}
class MockRegisterDeviceTokenUseCase extends Mock implements RegisterDeviceTokenUseCase {}
class MockUnregisterDeviceTokenUseCase extends Mock implements UnregisterDeviceTokenUseCase {}
class MockResetNotificationBadgeUseCase extends Mock implements ResetNotificationBadgeUseCase {}

void main() {
  late MockGetLocalNotificationsUseCase mockGetLocalNotifications;
  late MockGetUnreadCountUseCase mockGetUnreadCount;
  late MockSyncNotificationsUseCase mockSyncNotifications;
  late MockMarkNotificationsAsReadUseCase mockMarkAsRead;
  late MockDismissNotificationsUseCase mockDismiss;
  late MockRegisterDeviceTokenUseCase mockRegisterToken;
  late MockUnregisterDeviceTokenUseCase mockUnregisterToken;
  late MockResetNotificationBadgeUseCase mockResetBadge;

  const testNotif = NotificationEntity(
    id: '1',
    title: 'Test Notification',
    body: 'Test Body',
    type: 'general',
    source: 'SERVER',
    isRead: false,
    isDismissed: false,
    syncVersion: 1,
    timestamp: 1600000000000,
    priority: 'medium',
    metadata: {},
  );

  setUp(() {
    mockGetLocalNotifications = MockGetLocalNotificationsUseCase();
    mockGetUnreadCount = MockGetUnreadCountUseCase();
    mockSyncNotifications = MockSyncNotificationsUseCase();
    mockMarkAsRead = MockMarkNotificationsAsReadUseCase();
    mockDismiss = MockDismissNotificationsUseCase();
    mockRegisterToken = MockRegisterDeviceTokenUseCase();
    mockUnregisterToken = MockUnregisterDeviceTokenUseCase();
    mockResetBadge = MockResetNotificationBadgeUseCase();

    when(() => mockGetLocalNotifications()).thenAnswer((_) async => [testNotif]);
    when(() => mockGetUnreadCount()).thenAnswer((_) async => 1);
  });

  NotificationCubit buildCubit() {
    return NotificationCubit(
      getLocalNotificationsUseCase: mockGetLocalNotifications,
      getUnreadCountUseCase: mockGetUnreadCount,
      syncNotificationsUseCase: mockSyncNotifications,
      markNotificationsAsReadUseCase: mockMarkAsRead,
      dismissNotificationsUseCase: mockDismiss,
      registerDeviceTokenUseCase: mockRegisterToken,
      unregisterDeviceTokenUseCase: mockUnregisterToken,
      resetNotificationBadgeUseCase: mockResetBadge,
    );
  }

  test('loadNotifications emits NotificationLoading then NotificationSuccess', () async {
    final cubit = buildCubit();
    await cubit.loadNotifications();

    expect(cubit.state, isA<NotificationSuccess>());
    expect(cubit.state.notifications.length, 1);
    expect(cubit.state.unreadCount, 1);
  });

  test('markAsRead calls use case and reloads notifications', () async {
    when(() => mockMarkAsRead(['1'])).thenAnswer((_) async {});
    final cubit = buildCubit();
    await cubit.markAsRead(['1']);

    verify(() => mockMarkAsRead(['1'])).called(1);
    expect(cubit.state, isA<NotificationSuccess>());
  });

  test('dismiss calls use case and reloads notifications', () async {
    when(() => mockDismiss(['1'])).thenAnswer((_) async {});
    final cubit = buildCubit();
    await cubit.dismiss(['1']);

    verify(() => mockDismiss(['1'])).called(1);
    expect(cubit.state, isA<NotificationSuccess>());
  });

  test('resetNotificationBadgeCount sets unreadCount to 0', () async {
    when(() => mockResetBadge()).thenAnswer((_) async {});
    final cubit = buildCubit();
    await cubit.resetNotificationBadgeCount();

    verify(() => mockResetBadge()).called(1);
    expect(cubit.state.unreadCount, 0);
  });
}
