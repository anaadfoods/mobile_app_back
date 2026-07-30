import 'package:grocery_app/services/token_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart' as dio;
import '../models/notification_model.dart';
import 'package:grocery_app/features/notifications/data/datasources/notifications_local_data_source.dart';
import 'package:grocery_app/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:grocery_app/service_locator.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => getIt<NotificationService>();
  NotificationService._internal();
  static NotificationService create() => NotificationService._internal();

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

  // Store initial message if app was launched from terminated state
  RemoteMessage? _pendingInitialMessage;
  bool _isInitialized = false;

  Future<void> initialize(NotificationCubit read) async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // Initialize Firebase Messaging
      await _initializeFirebaseMessaging();

      // Initialize Local Notifications
      await _initializeLocalNotifications();

      // Set up message handlers
      _setupMessageHandlers();

      // Check if permission is already granted to fetch the token silently
      final settings = await _firebaseMessaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _getFCMToken();
      }

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
      debugPrint('Initial message receiving: ${initialMessage.data}');
      _pendingInitialMessage = initialMessage;
    }
  }

  /// Called from AppInitializer when navigator is ready.
  /// CRITICAL: Handles cold start / terminated state navigation.
  void processInitialMessage() {
    if (_pendingInitialMessage != null) {
      debugPrint(
        'Processing pending initial notification message: ${_pendingInitialMessage!.data}',
      );
      final messageData = Map<String, dynamic>.from(
        _pendingInitialMessage!.data,
      );
      _pendingInitialMessage = null;

      // LIFECYCLE SAFETY: Ensure navigation happens after MaterialApp is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('Executing cold start navigation with data: $messageData');
        handleRedirection(messageData);
      });
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

  Future<void> requestNotificationPermission() async {
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

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _getFCMToken();
      final token = await getFCMToken();
      if (token != null) {
        final isLoggedIn = await getIt<TokenService>().isLoggedIn();
        if (isLoggedIn) {
          final bearerToken = await getIt<TokenService>().getAccessToken();
          if (bearerToken != null) {
            await registerFcmTokenWithBackend(token, bearerToken);
          }
        }
      }
    }
  }



  Future<void> _getFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveFCMToken(token);
      debugPrint('FCM Token: $token');

      final isLoggedIn = await getIt<TokenService>().isLoggedIn();
      if (isLoggedIn) {
        final bearerToken = await getIt<TokenService>().getAccessToken();
        if (bearerToken != null) {
          await registerFcmTokenWithBackend(token, bearerToken);
        }
      }
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      await _saveFCMToken(newToken);
      _onTokenRefreshController.add(newToken);

      final isLoggedIn = await getIt<TokenService>().isLoggedIn();
      if (isLoggedIn) {
        final bearerToken = await getIt<TokenService>().getAccessToken();
        if (bearerToken != null) {
          await registerFcmTokenWithBackend(newToken, bearerToken);
        }
      }
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
        AppLogger.instance.log(
          'FCM Token: $token',
        ); // Also print to console for easy access
      } else {
        debugPrint('Failed to get FCM token');
        AppLogger.instance.log('Failed to get FCM token');
      }
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      AppLogger.instance.log('Error getting FCM token: $e');
      return null;
    }
  }

  void _setupMessageHandlers() {
    // Listeners are already registered in _initializeFirebaseMessaging.
    // This method is kept as a placeholder for any additional setup.
    // Do NOT re-register onMessage / onMessageOpenedApp here to avoid
    // duplicate processing of every notification.
  }

  bool _shouldSuppressForegroundBanner(String title, String body, Map<String, dynamic> data) {
    final titleLower = title.toLowerCase();
    final bodyLower = body.toLowerCase();
    final type = (data['type'] ?? '').toString().toLowerCase();
    final action = (data['action'] ?? '').toString().toLowerCase();
    final screen = (data['screen'] ?? '').toString().toLowerCase();

    // 1. Order Creation
    if (type == 'order' || action == 'view_order' || screen == 'order_tracking') {
      if (titleLower.contains('placed') ||
          titleLower.contains('created') ||
          titleLower.contains('success') ||
          bodyLower.contains('placed') ||
          bodyLower.contains('created') ||
          bodyLower.contains('success')) {
        return true;
      }
    }

    // 2. Subscription Creation
    if (type == 'subscription' || action == 'view_subscription' || screen == 'subscription_detail') {
      if (titleLower.contains('created') ||
          titleLower.contains('success') ||
          titleLower.contains('active') ||
          titleLower.contains('activated') ||
          bodyLower.contains('created') ||
          bodyLower.contains('success') ||
          bodyLower.contains('active') ||
          bodyLower.contains('activated')) {
        return true;
      }
    }

    // 3. Profile Update
    if (type == 'profile' || action == 'open_profile' || screen == 'profile') {
      if (titleLower.contains('updated') ||
          titleLower.contains('success') ||
          titleLower.contains('change') ||
          bodyLower.contains('updated') ||
          bodyLower.contains('success') ||
          bodyLower.contains('change')) {
        return true;
      }
    }

    // Fallback general substring check
    if (titleLower.contains('order placed') ||
        titleLower.contains('subscription created') ||
        titleLower.contains('profile updated')) {
      return true;
    }

    return false;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint(
        'Message also contained a notification: ${message.notification}',
      );
    }

    // Determine title and body from notification payload OR data payload.
    // This ensures data-only messages from the backend are also handled.
    final String title =
        message.notification?.title ??
        message.data['title'] ??
        'New Notification';
    final String body =
        message.notification?.body ?? message.data['body'] ?? '';

    // Only skip truly empty messages (no notification AND no useful data)
    if (message.notification == null &&
        title == 'New Notification' &&
        body.isEmpty &&
        message.data.isEmpty) {
      debugPrint('Skipping empty foreground message with no data');
      return;
    }

    // Save notification to local storage via data source
    try {
      getIt<NotificationsLocalDataSource>().saveServerPushNotification(message.data);
    } catch (e) {
      debugPrint('Error saving foreground notification: $e');
    }

    // Check if we should suppress the local notification banner
    if (!_shouldSuppressForegroundBanner(title, body, message.data)) {
      // Show local notification (heads-up banner)
      _showLocalNotification(message);
    } else {
      debugPrint('Suppressing foreground banner for $title');
    }

    // Add to stream for UI updates (badge, in-app list refresh)
    _onMessageReceivedController.add(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App opened from notification: ${message.data}');
    _onMessageOpenedAppController.add(message);
    // LIFECYCLE SAFETY: Delay navigation until UI is ready
    // Critical for background -> foreground transitions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleRedirection(message.data);
    });
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // LIFECYCLE SAFETY: Delay navigation until UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (response.payload != null) {
        try {
          Map<String, dynamic> data = json.decode(response.payload!);
          // Use handleRedirection for consistent routing
          handleRedirection(data);
        } catch (e) {
          debugPrint('Error parsing notification payload: $e');
          // Default to notifications screen if payload parsing fails
          NavigationService.navigateToNotifications();
        }
      } else {
        // Default to notifications screen if no payload
        NavigationService.navigateToNotifications();
      }
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    String channelId = _getChannelId(message.data);
    String title =
        message.notification?.title ??
        message.data['title'] ??
        'New Notification';
    String body = message.notification?.body ?? message.data['body'] ?? '';

    // Get image URL from notification or data payload
    String? imageUrl =
        message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl ??
        message.data['image'] ??
        message.data['image_url'];

    // Prepare style information based on whether image exists
    StyleInformation styleInformation;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        // Download image for BigPictureStyle notification using vanilla Dio
        final dioClient = dio.Dio();
        final response = await dioClient.get<List<int>>(
          imageUrl,
          options: dio.Options(responseType: dio.ResponseType.bytes),
        );
        if (response.statusCode == 200 && response.data != null) {
          final bytes = Uint8List.fromList(response.data!);
          styleInformation = BigPictureStyleInformation(
            ByteArrayAndroidBitmap(bytes),
            largeIcon: ByteArrayAndroidBitmap(bytes),
            contentTitle: title,
            htmlFormatContentTitle: true,
            summaryText: body,
            htmlFormatSummaryText: true,
          );
          debugPrint('Image loaded successfully for notification');
        } else {
          debugPrint('Failed to load image: ${response.statusCode}');
          styleInformation = BigTextStyleInformation(
            body,
            htmlFormatBigText: true,
            contentTitle: title,
            htmlFormatContentTitle: true,
          );
        }
      } catch (e) {
        debugPrint('Error loading image for notification: $e');
        styleInformation = BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
        );
      }
    } else {
      styleInformation = BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      );
    }

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      color: AppColors.parchment,
      styleInformation: styleInformation,
    );

    DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: title,
      // iOS handles image from notification.image automatically via FCM
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Include image URL in payload for in-app display
    Map<String, dynamic> payloadData = Map<String, dynamic>.from(message.data);
    if (imageUrl != null) {
      payloadData['image'] = imageUrl;
    }

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      notificationDetails,
      payload: json.encode(payloadData),
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

  /// Handles deep linking redirection from FCM notification payloads.
  /// Supports Django backend payload format with 'screen', 'product_id', 'order_id' keys.
  /// Falls back to existing type-based routing for other notification types.
  ///
  /// Screen-based routing (primary):
  ///   - order_tracking: requires order_id
  ///   - product_detail: requires product_id
  ///   - subscription_detail: requires subscription_id
  ///   - cart, profile, home, notifications: no ID required
  ///
  /// Type-based fallback (when screen is missing):
  ///   - Uses 'type' and 'id' fields for routing
  void handleRedirection(Map<String, dynamic> data) {
    debugPrint('handleRedirection called with data: $data');

    // Helper to safely convert any ID type (int or String) to String
    String? toStringId(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    // Parse metadata if present (can be a JSON string or nested map)
    Map<String, dynamic> metadata = {};
    if (data['metadata'] != null) {
      if (data['metadata'] is Map) {
        metadata = Map<String, dynamic>.from(data['metadata']);
      } else if (data['metadata'] is String) {
        try {
          metadata = json.decode(data['metadata']);
        } catch (_) {}
      }
    }

    // Extract type and ID from metadata
    final String? metadataType =
        metadata['type']?.toString() ?? metadata['screen']?.toString();
    final String? metadataId = toStringId(
      metadata['id'] ??
          metadata['order_id'] ??
          metadata['product_id'] ??
          metadata['subscription_id'],
    );

    final String? type =
        (metadataType != null && metadataType.isNotEmpty)
            ? metadataType
            : data['type'] as String?;

    final String? genericId =
        (metadataId != null && metadataId.isNotEmpty)
            ? metadataId
            : toStringId(data['id']);

    // Handle type-based routing (using 'type' field from backend)
    if (type != null && type.isNotEmpty) {
      debugPrint('Handling type-based redirection: $type');
      switch (type) {
        case 'product':
        case 'product_detail':
          final productId =
              toStringId(data['id']) ??
              toStringId(data['product_id']) ??
              genericId;
          if (productId != null && productId.isNotEmpty) {
            debugPrint('Navigating to product_detail with id: $productId');
            NavigationService.navigateToProductDetails(productId);
          } else {
            debugPrint('product_id missing for product screen');
            _navigateToNotifications();
          }
          return;
        case 'order':
        case 'order_tracking':
          final orderId =
              toStringId(data['id']) ??
              toStringId(data['order_id']) ??
              genericId;
          if (orderId != null && orderId.isNotEmpty) {
            debugPrint('Navigating to order_tracking with id: $orderId');
            NavigationService.navigateToOrderDetails(orderId);
          } else {
            debugPrint('order_id missing for order screen');
            _navigateToNotifications();
          }
          return;
        case 'subscription':
        case 'subscription_detail':
        case 'payment':
        case 'payment_subscription':
          final subscriptionId =
              toStringId(data['id']) ??
              toStringId(data['subscription_id']) ??
              genericId;
          if (subscriptionId != null && subscriptionId.isNotEmpty) {
            debugPrint(
              'Navigating to subscription_detail with id: $subscriptionId',
            );
            NavigationService.navigateToSubscriptionDetails(subscriptionId);
          } else {
            debugPrint('subscription_id missing for subscription screen');
            _navigateToNotifications();
          }
          return;
        case 'cart':
          debugPrint('Navigating to cart');
          NavigationService.navigateToCart();
          return;
        case 'profile':
          debugPrint('Navigating to profile');
          NavigationService.navigateToAccount();
          return;
        case 'home':
          debugPrint('Navigating to home');
          NavigationService.navigateToHome();
          return;
        case 'notifications':
        case 'promotional':
        case 'system':
        default:
          debugPrint('Type $type -> navigating to notifications');
          _navigateToNotifications();
          return;
      }
    }

    // No type found, go to notifications
    debugPrint('No type found, falling back to notifications');
    _navigateToNotifications();
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
    String deviceId = await getDeviceId();
    String localId =
        'LOCAL_${deviceId}_${DateTime.now().millisecondsSinceEpoch}';

    // Parse metadata from payload if any
    Map<String, dynamic> metadataVal = {};
    String? actionVal;
    if (payload != null) {
      try {
        metadataVal = jsonDecode(payload) as Map<String, dynamic>;
        actionVal = metadataVal['action'] as String?;
      } catch (e) {
        debugPrint('Error parsing payload: $e');
      }
    }

    final model = NotificationModel(
      id: localId,
      title: title,
      body: body,
      type: type ?? metadataVal['type'] ?? 'general',
      action: actionVal,
      source: 'LOCAL_DEVICE_APP',
      originDeviceId: deviceId,
      isRead: false,
      isDismissed: false,
      syncVersion: 0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      image: metadataVal['image'] ?? metadataVal['image_url'],
      priority: metadataVal['priority'] ?? 'medium',
      metadata: metadataVal,
    );

    // Save and register local notification optimistically
    await getIt<NotificationsLocalDataSource>().saveServerPushNotification(model.toLocalMap());

    String channelId = _getChannelId({'type': type ?? model.type});

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      color: AppColors.parchment,
      // Style for better text display
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
      '${ApiConfig.baseUrl}/api/notifications/register-token/',
    );
    try {
      final response = await ApiClient.instance.post(
        '/api/notifications/register-token/',
        options: dio.Options(headers: {'Authorization': 'Bearer $bearerToken'}),
        data: {
          'token': fcmToken.toString(),
          'device_id': deviceID.toString(),
          'platform': platform.toString(),
        },
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
    try {
      String deviceID = await getDeviceId();
      final response = await ApiClient.instance.post(
        '/api/notifications/logout-device/',
        options: dio.Options(headers: {'Authorization': 'Bearer $bearerToken'}),
        data: {'token': fcmToken.toString(), 'device_id': deviceID},
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
  await Firebase.initializeApp();

  // Initialize service locator if not already registered
  if (!getIt.isRegistered<NotificationsLocalDataSource>()) {
    setupLocator();
  }

  debugPrint('Handling a background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');

  if (message.data.isNotEmpty) {
    try {
      final localDataSource = getIt<NotificationsLocalDataSource>();
      await localDataSource.saveServerPushNotification(message.data);
    } catch (e) {
      debugPrint('Error saving background notification: $e');
    }
  }
}
