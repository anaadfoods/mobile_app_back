import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/cubits/notification/notification_cubit.dart';
import 'package:grocery_app/cubits/notification/notification_state.dart';

class NotificationBadgeWidget extends StatelessWidget {
  final Widget child;
  final bool showBadge;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;
  final VoidCallback? onTap;

  const NotificationBadgeWidget({
    super.key,
    required this.child,
    this.showBadge = true,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bColor = badgeColor ?? theme.colorScheme.error;
    final tColor = textColor ?? theme.colorScheme.onError;

    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final notificationCount = state.unreadCount;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (showBadge && notificationCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: GestureDetector(
                  onTap: () {
                    onTap?.call();
                    context.read<NotificationCubit>().resetNotificationBadgeCount();
                  },
                  child: Container(
                    width: badgeSize ?? 22,
                    height: badgeSize ?? 22,
                    decoration: BoxDecoration(
                      color: bColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.cardColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        notificationCount > 99
                            ? '99+'
                            : notificationCount.toString(),
                        style: TextStyle(
                          color: tColor,
                          fontSize: (badgeSize ?? 22) * 0.55,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class NotificationListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final Function(Map<String, dynamic>)? onNotificationTap;
  final Function(Map<String, dynamic>)? onNotificationDismiss;

  const NotificationListWidget({
    super.key,
    required this.notifications,
    this.onNotificationTap,
    this.onNotificationDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text('No notifications yet', style: textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _NotificationListItem(
          notification: notification,
          onTap: () => onNotificationTap?.call(notification),
          onDismiss: () => onNotificationDismiss?.call(notification),
        );
      },
    );
  }
}

class _NotificationListItem extends StatefulWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _NotificationListItem({
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<_NotificationListItem> createState() => _NotificationListItemState();
}

class _NotificationListItemState extends State<_NotificationListItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final messageType = MessageUtility.getMessageType(widget.notification);
    final icon = MessageUtility.getMessageIcon(messageType);
    final color = MessageUtility.getMessageColor(messageType);
    final backgroundColor = MessageUtility.getMessageBackgroundColor(
      messageType,
    );
    final timestamp = widget.notification['timestamp'] as int? ?? 0;
    final title = widget.notification['title'] as String? ?? '';
    final body = widget.notification['body'] as String? ?? '';
    final isHighPriority = MessageUtility.isHighPriority(widget.notification);

    final needsExpansion = body.length > 100;

    return Dismissible(
      key: Key(widget.notification['id']?.toString() ?? timestamp.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => widget.onDismiss?.call(),
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighPriority ? color : AppColors.transparent,
            width: isHighPriority ? 2 : 0,
          ),
        ),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            title,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (body.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      body,
                      style: textTheme.bodyMedium,
                      maxLines: _isExpanded ? null : 2,
                      overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    ),
                    if (needsExpansion)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _isExpanded ? 'Show less' : 'Show more',
                            style: textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 4),
              Text(
                MessageUtility.formatTimestamp(timestamp),
                style: textTheme.bodySmall,
              ),
            ],
          ),
          trailing:
              isHighPriority
                  ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'URGENT',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.parchment,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  : null,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class NotificationSettingsWidget extends StatefulWidget {
  final ValueChanged<bool>? onOrderNotificationsChanged;
  final ValueChanged<bool>? onProductNotificationsChanged;
  final ValueChanged<bool>? onPromoNotificationsChanged;
  final ValueChanged<bool>? onSubscriptionNotificationsChanged;

  const NotificationSettingsWidget({
    super.key,
    this.onOrderNotificationsChanged,
    this.onProductNotificationsChanged,
    this.onPromoNotificationsChanged,
    this.onSubscriptionNotificationsChanged,
  });

  @override
  State<NotificationSettingsWidget> createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState
    extends State<NotificationSettingsWidget> {
  bool _orderNotifications = true;
  bool _productNotifications = true;
  bool _promoNotifications = true;
  bool _subscriptionNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _orderNotifications = prefs.getBool('order_notifications') ?? true;
        _productNotifications = prefs.getBool('product_notifications') ?? true;
        _promoNotifications = prefs.getBool('promo_notifications') ?? true;
        _subscriptionNotifications =
            prefs.getBool('subscription_notifications') ?? true;
      });
    }
  }

  Future<void> _saveNotificationSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('order_notifications', _orderNotifications);
    await prefs.setBool('product_notifications', _productNotifications);
    await prefs.setBool('promo_notifications', _promoNotifications);
    await prefs.setBool(
      'subscription_notifications',
      _subscriptionNotifications,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildNotificationSetting(
          title: 'Order Updates',
          subtitle: 'Get notified about order status changes',
          icon: Icons.shopping_bag,
          color: AppColors.deepSoilGreen,
          value: _orderNotifications,
          onChanged: (value) {
            setState(() => _orderNotifications = value);
            _saveNotificationSettings();
            widget.onOrderNotificationsChanged?.call(value);
          },
        ),
        _buildNotificationSetting(
          title: 'Product Updates',
          subtitle: 'Get notified about product availability',
          icon: Icons.inventory,
          color: AppColors.deepSoilGreen,
          value: _productNotifications,
          onChanged: (value) {
            setState(() => _productNotifications = value);
            _saveNotificationSettings();
            widget.onProductNotificationsChanged?.call(value);
          },
        ),
        _buildNotificationSetting(
          title: 'Promotions',
          subtitle: 'Get notified about special offers and deals',
          icon: Icons.local_offer,
          color: AppColors.rawEarth,
          value: _promoNotifications,
          onChanged: (value) {
            setState(() => _promoNotifications = value);
            _saveNotificationSettings();
            widget.onPromoNotificationsChanged?.call(value);
          },
        ),
        _buildNotificationSetting(
          title: 'Subscription Updates',
          subtitle: 'Get notified about subscription changes',
          icon: Icons.subscriptions,
          color: AppColors.harvestAmber,
          value: _subscriptionNotifications,
          onChanged: (value) {
            setState(() => _subscriptionNotifications = value);
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle, style: textTheme.bodyMedium),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: color,
          inactiveTrackColor: color.withValues(alpha: 0.3),
          activeTrackColor: color.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
