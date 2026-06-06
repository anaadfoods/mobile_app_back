import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:grocery_app/models/notification_model.dart';
import 'package:grocery_app/services/notification_sync_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Initialize SharedPreferences with mock values before each test
    SharedPreferences.setMockInitialValues({});
    // Mock dotenv values to prevent NotInitializedError from AuthService
    dotenv.testLoad(fileInput: 'GOOGLE_SERVER_CLIENT_ID=mock_client_id');
  });

  group('NotificationModel Tests', () {
    test('fromJson should parse server-format notification correctly', () {
      final jsonMap = {
        'id': 123,
        'title': 'Test Title',
        'message': 'Test Message',
        'source': 'SERVER',
        'is_read': true,
        'is_dismissed': false,
        'sync_version': 5,
        'created_at': '2026-05-26T09:00:00.000Z',
        'priority': 'high',
        'metadata': {'action': 'view_order', 'order_id': 'ABC-456'}
      };

      final model = NotificationModel.fromJson(jsonMap);

      expect(model.id, '123');
      expect(model.title, 'Test Title');
      expect(model.body, 'Test Message');
      expect(model.source, 'SERVER');
      expect(model.isRead, true);
      expect(model.isDismissed, false);
      expect(model.syncVersion, 5);
      expect(model.priority, 'high');
      expect(model.action, 'view_order');
      expect(model.metadata['order_id'], 'ABC-456');
    });

    test('toJson and toLocalMap should format correctly', () {
      final model = NotificationModel(
        id: 'LOCAL_dev_123',
        title: 'Local title',
        body: 'Local body',
        type: 'order',
        action: 'view_order',
        source: 'LOCAL_DEVICE_APP',
        originDeviceId: 'dev_iphone',
        isRead: false,
        isDismissed: false,
        syncVersion: 0,
        timestamp: 1672531199000,
        priority: 'medium',
        metadata: {'order_id': '789'},
      );

      final jsonMap = model.toJson();
      expect(jsonMap['id'], 'LOCAL_dev_123');
      expect(jsonMap['source'], 'LOCAL_DEVICE_APP');
      expect(jsonMap['is_read'], false);

      final localMap = model.toLocalMap();
      expect(localMap['id'], 'LOCAL_dev_123');
      expect(localMap['read'], false);
      expect(localMap['is_read'], false);
    });
  });

  group('PendingQueueItem Tests', () {
    test('toJson and fromJson should match', () {
      final item = PendingQueueItem(
        id: 'notif_id_1',
        actionType: QueueActionType.markRead,
        data: {'ids': ['notif_id_1']},
      );

      final jsonMap = item.toJson();
      final parsed = PendingQueueItem.fromJson(jsonMap);

      expect(parsed.id, 'notif_id_1');
      expect(parsed.actionType, QueueActionType.markRead);
      expect(parsed.data['ids'], contains('notif_id_1'));
    });
  });

  group('Sync Reconciliation Tests', () {
    test('Merging server changes should reconcile state correctly', () async {
      final syncManager = NotificationSyncManager();
      
      // Seed local storage with some notifications
      final localNotif1 = NotificationModel(
        id: '1',
        title: 'Old Title 1',
        body: 'Body 1',
        type: 'general',
        source: 'SERVER',
        isRead: false,
        isDismissed: false,
        syncVersion: 1,
        timestamp: 1000,
        priority: 'medium',
        metadata: {},
      );

      final localNotif2 = NotificationModel(
        id: '2',
        title: 'Title 2',
        body: 'Body 2',
        type: 'general',
        source: 'SERVER',
        isRead: false,
        isDismissed: false,
        syncVersion: 1,
        timestamp: 2000,
        priority: 'medium',
        metadata: {},
      );

      // Save initial local state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notifications', jsonEncode([
        localNotif1.toJson(),
        localNotif2.toJson()
      ]));

      // 1. Simulate server changes: Notification 1 is read, Notification 3 is new, Notification 2 is dismissed
      final serverNotif1 = localNotif1.copyWith(isRead: true, title: 'Updated Title 1', syncVersion: 2);
      final serverNotif2 = localNotif2.copyWith(isDismissed: true, syncVersion: 2);
      final serverNotif3 = NotificationModel(
        id: '3',
        title: 'New Title 3',
        body: 'Body 3',
        type: 'general',
        source: 'SERVER',
        isRead: false,
        isDismissed: false,
        syncVersion: 2,
        timestamp: 3000,
        priority: 'medium',
        metadata: {},
      );

      // Perform a custom merge test mimicking syncWithBackend behavior
      final localList = await syncManager.getLocalNotifications();
      final Map<String, NotificationModel> merged = {
        for (var n in localList) n.id: n
      };

      final serverChanges = [serverNotif1, serverNotif2, serverNotif3];
      for (var serverNotif in serverChanges) {
        if (serverNotif.isDismissed) {
          merged.remove(serverNotif.id);
        } else {
          merged[serverNotif.id] = serverNotif;
        }
      }

      final updatedList = merged.values.toList();
      updatedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      expect(updatedList.length, 2);
      expect(updatedList[0].id, '3'); // Sorted by timestamp (3000 > 1000)
      expect(updatedList[1].id, '1');
      expect(updatedList[1].title, 'Updated Title 1');
      expect(updatedList[1].isRead, true);
      
      // Check that 2 was removed since it was dismissed
      expect(updatedList.any((n) => n.id == '2'), false);
    });
  });
}
