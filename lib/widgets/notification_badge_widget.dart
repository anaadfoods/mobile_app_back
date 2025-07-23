import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../helpers/message_utility.dart';

class NotificationBadgeWidget extends StatefulWidget {
  final Widget child;
  final bool showBadge;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;
  final VoidCallback? onTap;

  const NotificationBadgeWidget({
    Key? key,
    required this.child,
    this.showBadge = true,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
    this.onTap,
  }) : super(key: key);

  @override
  State<NotificationBadgeWidget> createState() => _NotificationBadgeWidgetState();
}

class _NotificationBadgeWidgetState extends State<NotificationBadgeWidget> {
  int _notificationCount = 0;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
    _listenToNotifications();
  }

  Future<void> _loadNotificationCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt('notification_count') ?? 0;
    if (mounted) {
      setState(() {
        _notificationCount = count;
      });
    }
  }

  void _listenToNotifications() {
    _notificationService.onMessageReceived.listen((message) {
      _incrementNotificationCount();
    });
  }

  Future<void> _incrementNotificationCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt('notification_count') ?? 0;
    int newCount = currentCount + 1;
    
    await prefs.setInt('notification_count', newCount);
    
    if (mounted) {
      setState(() {
        _notificationCount = newCount;
      });
    }
  }

  Future<void> _clearNotificationCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_count', 0);
    
    if (mounted) {
      setState(() {
        _notificationCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showBadge && _notificationCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () {
                widget.onTap?.call();
                _clearNotificationCount();
              },
              child: Container(
                width: widget.badgeSize ?? 20,
                height: widget.badgeSize ?? 20,
                decoration: BoxDecoration(
                  color: widget.badgeColor ?? Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _notificationCount > 99 ? '99+' : _notificationCount.toString(),
                    style: TextStyle(
                      color: widget.textColor ?? Colors.white,
                      fontSize: (widget.badgeSize ?? 20) * 0.6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class NotificationListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final Function(Map<String, dynamic>)? onNotificationTap;
  final Function(Map<String, dynamic>)? onNotificationDismiss;

  const NotificationListWidget({
    Key? key,
    required this.notifications,
    this.onNotificationTap,
    this.onNotificationDismiss,
  }) : super(key: key);

  @override
  State<NotificationListWidget> createState() => _NotificationListWidgetState();
}

class _NotificationListWidgetState extends State<NotificationListWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.notifications.length,
      itemBuilder: (context, index) {
        final notification = widget.notifications[index];
        return _NotificationListItem(
          notification: notification,
          onTap: () => widget.onNotificationTap?.call(notification),
          onDismiss: () => widget.onNotificationDismiss?.call(notification),
        );
      },
    );
  }
}

class _NotificationListItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _NotificationListItem({
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final messageType = MessageUtility.getMessageType(notification);
    final icon = MessageUtility.getMessageIcon(messageType);
    final color = MessageUtility.getMessageColor(messageType);
    final backgroundColor = MessageUtility.getMessageBackgroundColor(messageType);
    final timestamp = notification['timestamp'] as int? ?? 0;
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final isHighPriority = MessageUtility.isHighPriority(notification);

    return Dismissible(
      key: Key(notification['id']?.toString() ?? timestamp.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onDismiss?.call(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighPriority ? color : Colors.transparent,
            width: isHighPriority ? 2 : 0,
          ),
        ),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (body.isNotEmpty)
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Text(
                MessageUtility.formatTimestamp(timestamp),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: isHighPriority
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}

class NotificationSettingsWidget extends StatefulWidget {
  final Function(bool)? onOrderNotificationsChanged;
  final Function(bool)? onProductNotificationsChanged;
  final Function(bool)? onPromoNotificationsChanged;
  final Function(bool)? onSubscriptionNotificationsChanged;

  const NotificationSettingsWidget({
    Key? key,
    this.onOrderNotificationsChanged,
    this.onProductNotificationsChanged,
    this.onPromoNotificationsChanged,
    this.onSubscriptionNotificationsChanged,
  }) : super(key: key);

  @override
  State<NotificationSettingsWidget> createState() => _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends State<NotificationSettingsWidget> {
  bool _orderNotifications = true;
  bool _productNotifications = true;
  bool _promoNotifications = true;
  bool _subscriptionNotifications = true;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderNotifications = prefs.getBool('order_notifications') ?? true;
      _productNotifications = prefs.getBool('product_notifications') ?? true;
      _promoNotifications = prefs.getBool('promo_notifications') ?? true;
      _subscriptionNotifications = prefs.getBool('subscription_notifications') ?? true;
    });
  }

  Future<void> _saveNotificationSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('order_notifications', _orderNotifications);
    await prefs.setBool('product_notifications', _productNotifications);
    await prefs.setBool('promo_notifications', _promoNotifications);
    await prefs.setBool('subscription_notifications', _subscriptionNotifications);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildNotificationSetting(
          title: 'Order Updates',
          subtitle: 'Get notified about order status changes',
          icon: Icons.shopping_bag,
          color: Colors.blue,
          value: _orderNotifications,
          onChanged: (value) {
            setState(() {
              _orderNotifications = value;
            });
            _saveNotificationSettings();
            widget.onOrderNotificationsChanged?.call(value);
          },
        ),
        _buildNotificationSetting(
          title: 'Product Updates',
          subtitle: 'Get notified about product availability',
          icon: Icons.inventory,
          color: Colors.green,
          value: _productNotifications,
          onChanged: (value) {
            setState(() {
              _productNotifications = value;
            });
            _saveNotificationSettings();
            widget.onProductNotificationsChanged?.call(value);
          },
        ),
        _buildNotificationSetting(
          title: 'Promotions',
          subtitle: 'Get notified about special offers and deals',
          icon: Icons.local_offer,
          color: Colors.red,
          value: _promoNotifications,
          onChanged: (value) {
            setState(() {
              _promoNotifications = value;
            });
            _saveNotificationSettings();
            widget.onPromoNotificationsChanged?.call(value);
          },
        ),
        _buildNotificationSetting(
          title: 'Subscription Updates',
          subtitle: 'Get notified about subscription changes',
          icon: Icons.subscriptions,
          color: Colors.orange,
          value: _subscriptionNotifications,
          onChanged: (value) {
            setState(() {
              _subscriptionNotifications = value;
            });
            _saveNotificationSettings();
            widget.onSubscriptionNotificationsChanged?.call(value);
          },
        ),
      ],
    );
  }

  Widget _buildNotificationSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color,
        ),
      ),
    );
  }
} 