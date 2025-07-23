# Firebase Notification System Setup

This document explains how to set up and use the comprehensive notification system for the Anaad Foods Flutter app.

## Overview

The notification system includes:
- Firebase Cloud Messaging (FCM) for push notifications
- Local notifications for in-app messaging
- Message utility for handling different notification types
- Notification badges and UI components
- Notification settings and preferences

## Dependencies Added

The following dependencies have been added to `pubspec.yaml`:

```yaml
firebase_messaging: ^15.1.3
firebase_analytics: ^11.3.8
```

## Files Created

### 1. Notification Service (`lib/services/notification_service.dart`)
- Handles Firebase Cloud Messaging setup
- Manages local notifications
- Provides streams for notification events
- Handles notification permissions
- Manages FCM token generation and storage

### 2. Message Utility (`lib/helpers/message_utility.dart`)
- Utility functions for parsing and handling messages
- Message type definitions and constants
- UI helpers for notification display
- Message validation and formatting

### 3. Notification Badge Widget (`lib/widgets/notification_badge_widget.dart`)
- Reusable notification badge component
- Notification list widget
- Notification settings widget
- Badge count management

### 4. Notification Screens
- `lib/screens/notifications/notifications_screen.dart` - Main notifications list
- `lib/screens/notifications/notification_settings_screen.dart` - Settings management

## Firebase Setup

### 1. Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing project
3. Add Android and iOS apps to your project
4. Download the configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS

### 2. Android Setup
1. Place `google-services.json` in `android/app/`
2. Update `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

3. Update `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 3. iOS Setup
1. Place `GoogleService-Info.plist` in `ios/Runner/`
2. Add it to your Xcode project
3. Update `ios/Runner/Info.plist`:
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

## Usage

### 1. Initialize Notification Service

The notification service is automatically initialized in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();
  runApp(const MyApp());
}
```

### 2. Using Notification Badge

Wrap any widget with the notification badge:

```dart
NotificationBadgeWidget(
  child: IconButton(
    icon: Icon(Icons.notifications),
    onPressed: () {
      // Navigate to notifications screen
    },
  ),
  onTap: () {
    // Handle badge tap
  },
)
```

### 3. Listening to Notifications

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _notificationService.onMessageReceived.listen((message) {
      // Handle received notification
      Map<String, dynamic> data = MessageUtility.parseMessageData(message);
      // Update UI or navigate
    });

    _notificationService.onMessageOpenedApp.listen((message) {
      // Handle notification tap when app is opened
      Map<String, dynamic> data = MessageUtility.parseMessageData(message);
      // Navigate to appropriate screen
    });
  }
}
```

### 4. Sending Local Notifications

```dart
await NotificationService().showLocalNotification(
  title: 'Order Update',
  body: 'Your order #12345 has been delivered',
  payload: MessageUtility.createNotificationPayload(
    type: MessageUtility.messageTypeOrder,
    action: MessageUtility.actionViewOrder,
    id: '12345',
  ),
);
```

### 5. Navigation Integration

Update the navigation methods in `NotificationService` to integrate with your app's navigation:

```dart
void _navigateToOrder(String? orderId) {
  Navigator.pushNamed(context, '/order-details', arguments: orderId);
}

void _navigateToProduct(String? productId) {
  Navigator.pushNamed(context, '/product-details', arguments: productId);
}
```

## Message Types and Actions

### Message Types
- `order` - Order status updates
- `product` - Product availability updates
- `subscription` - Subscription changes
- `promo` - Promotional offers
- `general` - General notifications

### Actions
- `view_order` - Navigate to order details
- `view_product` - Navigate to product details
- `view_subscription` - Navigate to subscription details
- `open_cart` - Navigate to cart
- `open_profile` - Navigate to profile
- `open_promo` - Navigate to promo details

## Firebase Cloud Messaging Payload Format

### Order Notification
```json
{
  "notification": {
    "title": "Order Update",
    "body": "Your order #12345 has been delivered"
  },
  "data": {
    "type": "order",
    "action": "view_order",
    "id": "12345",
    "priority": "high"
  }
}
```

### Product Notification
```json
{
  "notification": {
    "title": "Product Available",
    "body": "Fresh apples are now in stock"
  },
  "data": {
    "type": "product",
    "action": "view_product",
    "id": "apple-123",
    "priority": "medium"
  }
}
```

### Promo Notification
```json
{
  "notification": {
    "title": "Special Offer",
    "body": "Get 20% off on all fruits"
  },
  "data": {
    "type": "promo",
    "action": "open_promo",
    "id": "fruit-sale",
    "priority": "medium"
  }
}
```

## Testing Notifications

### 1. Local Testing
```dart
// Test local notification
await NotificationService().showLocalNotification(
  title: 'Test Notification',
  body: 'This is a test notification',
);
```

### 2. Firebase Console Testing
1. Go to Firebase Console > Cloud Messaging
2. Create a new campaign
3. Set target audience and message
4. Send test message

### 3. FCM Token Testing
```dart
String? token = await NotificationService().getFCMToken();
print('FCM Token: $token');
```

## Notification Settings

The notification settings screen allows users to:
- Enable/disable different notification types
- Configure notification channels (Push, Email, SMS)
- Set quiet hours
- View notification statistics
- Export/import settings

## Best Practices

### 1. Permission Handling
- Always request permissions before sending notifications
- Handle permission denial gracefully
- Provide clear explanations for permission requests

### 2. Message Content
- Keep titles under 50 characters
- Keep body text under 200 characters
- Use clear, actionable language
- Include relevant data for navigation

### 3. User Experience
- Don't spam users with notifications
- Respect quiet hours settings
- Provide clear actions for notification taps
- Allow users to customize notification preferences

### 4. Error Handling
- Handle network errors gracefully
- Log notification failures
- Provide fallback mechanisms
- Test on different devices and OS versions

## Troubleshooting

### Common Issues

1. **Notifications not showing on Android**
   - Check notification permissions
   - Verify notification channels are created
   - Ensure app is not in battery optimization

2. **Notifications not showing on iOS**
   - Check notification permissions in Settings
   - Verify APNs certificate is valid
   - Test on physical device (not simulator)

3. **FCM Token not generated**
   - Check Firebase configuration
   - Verify internet connection
   - Check Firebase project settings

4. **Background notifications not working**
   - Ensure background message handler is registered
   - Check app lifecycle handling
   - Verify Firebase configuration

### Debug Commands

```dart
// Check FCM token
String? token = await NotificationService().getFCMToken();
print('FCM Token: $token');

// Check notification permissions
NotificationSettings settings = await FirebaseMessaging.instance.getPermission();
print('Permission status: ${settings.authorizationStatus}');

// Test local notification
await NotificationService().showLocalNotification(
  title: 'Debug Test',
  body: 'Testing notification system',
);
```

## Security Considerations

1. **Token Security**
   - Store FCM tokens securely
   - Validate tokens on server side
   - Implement token refresh handling

2. **Message Validation**
   - Validate all incoming messages
   - Sanitize message content
   - Implement rate limiting

3. **User Privacy**
   - Respect user notification preferences
   - Provide clear privacy policy
   - Allow users to opt out

## Future Enhancements

1. **Rich Notifications**
   - Add images to notifications
   - Implement action buttons
   - Add progress indicators

2. **Advanced Features**
   - Notification scheduling
   - Geofencing notifications
   - A/B testing for notifications

3. **Analytics Integration**
   - Track notification engagement
   - Monitor delivery rates
   - Analyze user behavior

## Support

For issues or questions:
1. Check Firebase documentation
2. Review Flutter notification plugins
3. Test on multiple devices
4. Monitor Firebase Console logs 