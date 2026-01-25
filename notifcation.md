Based on your 
NotificationService
 code (specifically the 
handleRedirection
 method starting at line 501 and 
_handleNotificationAction
 at line 460), here is the expected JSON format for notifications sent from your backend.

The system supports a modern "Screen-Based" format (preferred) and a fallback "Type-Based" format.

1. Preferred Format (Screen-Based)
Use this format to explicitly route users to specific screens like Product Details, Order Tracking, etc.

Common Structure:

json
{
  "token": "USER_FCM_TOKEN",
  "notification": {
    "title": "Notification Title",
    "body": "Notification Body Text",
    "image": "https://example.com/image.png"
  },
  "data": {
    "screen": "SCREEN_NAME",
    "type": "CHANNEL_TYPE",
    "image": "https://example.com/image.png",
    ... specific_id_fields ...
  }
}
Specific Data Payloads by Scenario:
A. Order Tracking

json
"data": {
  "screen": "order_tracking",
  "order_id": "12345",
  "type": "order"
}
B. Product Detail

json
"data": {
  "screen": "product_detail",
  "product_id": "987",
  "type": "product"
}
C. Subscription Detail

json
"data": {
  "screen": "subscription_detail",
  "subscription_id": "555",
  "type": "subscription"
}
D. Other Screens

Cart: "screen": "cart"
Profile: "screen": "profile"
Home: "screen": "home"
General Notifications: "screen": "notifications"
2. Fallback Format (Type-Based)
If the screen key is missing, the app uses type and id to route.

Structure:

json
"data": {
  "type": "order",      // or 'subscription', 'product', 'promotional'
  "id": "12345"         // The ID of the item to view
}
Key Reference
screen key: Determines the destination (Lines 501-546).
type key: Determines the Android Notification Channel (High vs Low importance) (Lines 407-423).
Values: order, subscription, payment, product, promotional, system.
