import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Stream controllers for notification events
  final StreamController<RemoteMessage> _onMessageOpenedAppController =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<RemoteMessage> _onMessageReceivedController =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<String> _onTokenRefreshController =
      StreamController<String>.broadcast();

  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  // Getters for streams
  Stream<RemoteMessage> get onMessageOpenedApp =>
      _onMessageOpenedAppController.stream;
  Stream<RemoteMessage> get onMessageReceived =>
      _onMessageReceivedController.stream;
  Stream<String> get onTokenRefresh => _onTokenRefreshController.stream;

  // Notification action types
  static const String actionViewOrder = 'view_order';
  static const String actionViewProduct = 'view_product';
  static const String actionViewSubscription = 'view_subscription';
  static const String actionViewPaymentReminder = 'view_payment_reminder';
  static const String actionOpenCart = 'open_cart';
  static const String actionOpenProfile = 'open_profile';
  static const String actionOpenPromo = 'open_promo';
  static String platform = Platform.isAndroid ? "android" : "ios";

  // Get device id
  static Future<String> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id ?? "unknown_android_id"; // Best option for Android
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ??
          "unknown_ios_id"; // Best option for iOS
    } else {
      return "unsupported_platform";
    }
  }

  // Get device id
  static Future<String> deviceId = getDeviceId();

  Future<void> initialize(NotificationCubit read) async {
    try {
      // Initialize Firebase Messaging
      await _initializeFirebaseMessaging();

      // Initialize Local Notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      // Get FCM token
      await _getFCMToken();

      // Set up message handlers
      _setupMessageHandlers();

      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Set foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle initial message when app is opened from terminated state
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel orderChannel =
          AndroidNotificationChannel(
            'orders',
            'Orders',
            description: 'Notifications for order status changes',
            importance: Importance.high,
          );

      const AndroidNotificationChannel subscriptionChannel =
          AndroidNotificationChannel(
            'subscriptions',
            'Subscriptions',
            description:
                'Notifications for subscription updates and payment reminders',
            importance: Importance.high,
          );

      const AndroidNotificationChannel productChannel =
          AndroidNotificationChannel(
            'products',
            'Products',
            description: 'Notifications for product launches and updates',
            importance: Importance.low,
          );

      const AndroidNotificationChannel promotionalChannel =
          AndroidNotificationChannel(
            'promotions',
            'Promotions',
            description: 'Notifications for marketing and promotional offers',
            importance: Importance.low,
          );

      const AndroidNotificationChannel systemChannel =
          AndroidNotificationChannel(
            'system',
            'System',
            description: 'Notifications for system updates and maintenance',
            importance: Importance.none,
          );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(orderChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(subscriptionChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(productChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(promotionalChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(systemChannel);
    }
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _getFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveFCMToken(token);
      debugPrint('FCM Token: $token');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveFCMToken(newToken);
      _onTokenRefreshController.add(newToken);
    });
  }

  Future<void> _saveFCMToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  Future<String?> getFCMToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  // Method to get fresh FCM token and print it
  Future<String?> getFreshFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
        debugPrint('FCM Token: $token');
        print('FCM Token: $token'); // Also print to console for easy access
      } else {
        debugPrint('Failed to get FCM token');
        print('Failed to get FCM token');
      }
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      print('Error getting FCM token: $e');
      return null;
    }
  }

  void _setupMessageHandlers() {
    // Set up message handlers for different notification types
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint(
        'Message also contained a notification: ${message.notification}',
      );

      // Show local notification
      _showLocalNotification(message);

      // Add to stream for UI updates
      _onMessageReceivedController.add(message);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App opened from notification: ${message.data}');
    _onMessageOpenedAppController.add(message);
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle local notification tap
    if (response.payload != null) {
      try {
        Map<String, dynamic> data = json.decode(response.payload!);
        _handleNotificationAction(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
        // Default to notifications screen if payload parsing fails
        NavigationService.navigateToNotifications();
      }
    } else {
      // Default to notifications screen if no payload
      NavigationService.navigateToNotifications();
    }
  }

  // In notification_service.dart

Future<void> _showLocalNotification(RemoteMessage message) async {
  String channelId = _getChannelId(message.data);
  String title = message.notification?.title ?? 'New Notification';
  String body = message.notification?.body ?? '';

  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    channelId,
    _getChannelName(channelId),
    channelDescription: _getChannelDescription(channelId),
    importance: Importance.max, // Use max importance for heads-up
    priority: Priority.high,
    ticker: 'ticker',
    icon: '@mipmap/ic_launcher',
    color: const Color(0xFF4CAF50),

    // ADD THIS TO MAKE THE NOTIFICATION EXPANDABLE
    styleInformation: BigTextStyleInformation(
      body, // The main text to be displayed in expanded view
      htmlFormatBigText: true,
      contentTitle: title, // Title to be shown in expanded view
      htmlFormatContentTitle: true,
    ),
  );

  DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    subtitle: 'New Notification', // You can add a subtitle for iOS
  );

  NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails, // Make sure to include iOS details
  );

  await _localNotifications.show(
    message.hashCode,
    title,
    body,
    notificationDetails,
    payload: json.encode(message.data), // The payload will handle the redirect
  );
}

  String _getChannelId(Map<String, dynamic> data) {
    String? type = data['type'];
    switch (type) {
      case 'order':
        return 'orders';
      case 'subscription':
      case 'payment':
        return 'subscriptions';
      case 'product':
        return 'products';
      case 'promotional':
        return 'promotions';
      case 'system':
        return 'system';
      default:
        return 'orders';
    }
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'orders':
        return 'Orders';
      case 'subscriptions':
        return 'Subscriptions';
      case 'products':
        return 'Products';
      case 'promotions':
        return 'Promotions';
      case 'system':
        return 'System';
      default:
        return 'Orders';
    }
  }

  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'orders':
        return 'Notifications for order status changes';
      case 'subscriptions':
        return 'Notifications for subscription updates and payment reminders';
      case 'products':
        return 'Notifications for product launches and updates';
      case 'promotions':
        return 'Notifications for marketing and promotional offers';
      case 'system':
        return 'Notifications for system updates and maintenance';
      default:
        return 'Notifications for order updates';
    }
  }

  void _handleNotificationAction(Map<String, dynamic> data) {
    String? action = data['type'];
    String? id = data['id'];

    switch (action) {
      case "order":
        // Redirect to order screen
        _navigateToOrder(id);
        break;
      case "subscription":
      case "payment":
        // Redirect to subscription detail screen
        _navigateToSubscription(id);
        break;
      case "product":
      case "promotional":
        // Redirect to home screen
        _navigateToHome();
        break;
      case "system":
        // Stay on notifications screen for system updates
        _navigateToNotifications();
        break;
      default:
        debugPrint('Unknown notification action: $action');
        // Default to notifications screen
        _navigateToNotifications();
    }
  }

  // Navigation methods - these will be implemented by the app
  void _navigateToOrder(String? orderId) {
    debugPrint('Navigate to order: $orderId');
    NavigationService.navigateToOrderDetails(orderId);
  }

  void _navigateToSubscription(String? subscriptionId) {
    debugPrint('Navigate to subscription: $subscriptionId');
    NavigationService.navigateToSubscriptionDetails(subscriptionId);
  }

  // void _navigateToPaymentReminder(String? subscriptionId) {
  //   debugPrint('Navigate to payment reminder: $subscriptionId');
  //   NavigationService.navigateToSubscriptionDetails(subscriptionId);
  // }

  // void _navigateToCart() {
  //   debugPrint('Navigate to cart');
  //   NavigationService.navigateToCart();
  // }

  void _navigateToProfile() {
    debugPrint('Navigate to profile');
    NavigationService.navigateToAccount();
  }

  void _navigateToPromo(String? promoId) {
    debugPrint('Navigate to promo: $promoId');
    NavigationService.navigateToPromoDetails(promoId);
  }

  void _navigateToProduct(String? productId) {
    debugPrint('Navigate to product: $productId');
    NavigationService.navigateToProductDetails(productId);
  }

  void _navigateToHome() {
    debugPrint('Navigate to home');
    NavigationService.navigateToHome();
  }

  void _navigateToNotifications() {
    debugPrint('Navigate to notifications');
    NavigationService.navigateToNotifications();
  }

  // Public methods for sending local notifications
  // In notification_service.dart

Future<void> showLocalNotification({
  required String title,
  required String body,
  String? payload,
  int id = 0,
  String? type,
}) async {
  String channelId = _getChannelId({'type': type ?? 'order'});

  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    channelId,
    _getChannelName(channelId),
    channelDescription: _getChannelDescription(channelId),
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
    // ADD THE STYLE HERE AS WELL
    styleInformation: BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    ),
  );
  
  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await _localNotifications.show(
    id,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}

  // Method to subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  // Method to unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  // Method to clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Method to cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Dispose method to clean up streams
  void dispose() {
    _onMessageOpenedAppController.close();
    _onMessageReceivedController.close();
    _onTokenRefreshController.close();
  }

  // Register FCM token with backend
  Future<void> registerFcmTokenWithBackend(
    String fcmToken,
    String bearerToken,
  ) async {
    String deviceID = await getDeviceId();

    final url = Uri.parse(
      'https://app.anaadfoods.com/api/notifications/register-token/',
    );
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
        },
        body: jsonEncode({
          'token': fcmToken.toString(),
          'device_id': deviceID.toString(),
          'platform': platform.toString(),
        }),
      );
      if (response.statusCode == 200) {
        debugPrint('FCM token registered successfully with backend');
      } else {
        debugPrint('Failed to register FCM token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error registering FCM token: ${e.toString()}');
    }
  }

  // Remove FCM token from backend on logout
  Future<void> removeFcmTokenFromBackend(
    String fcmToken,
    String bearerToken,
  ) async {
    final url = Uri.parse(
      'https://app.anaadfoods.com/api/notifications/logout-device/',
    );
    try {
      String deviceID = await getDeviceId();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
        },
        body: jsonEncode({'token': fcmToken.toString(), 'device_id': deviceID}),
      );
      if (response.statusCode == 200) {
        debugPrint('FCM token removed successfully from backend');
      } else {
        debugPrint('Failed to remove FCM token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error removing FCM token: ${e.toString()}');
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  // await Firebase.initializeApp();

  debugPrint('Handling a background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
}
