import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../helpers/message_utility.dart';
import '../../widgets/notification_badge_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _filteredNotifications = [];
  String _selectedFilter = 'all';
  bool _isLoading = true;

  late TabController _tabController;

  final List<String> _filterOptions = [
    'all',
    'orders',
    'products',
    'subscriptions',
    'promotions',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterOptions.length, vsync: this);
    _loadNotifications();
    _listenToNewNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? notificationsJson = prefs.getString('notifications');

      if (notificationsJson != null) {
        List<dynamic> notificationsList = json.decode(notificationsJson);
        _notifications = notificationsList.cast<Map<String, dynamic>>();
      }

      _filterNotifications();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _listenToNewNotifications() {
    _notificationService.onMessageReceived.listen((message) {
      Map<String, dynamic> notificationData = MessageUtility.parseMessageData(
        message,
      );
      _addNotification(notificationData);
    });
  }

  void _addNotification(Map<String, dynamic> notification) {
    setState(() {
      _notifications.insert(0, notification);
    });
    _filterNotifications();
    _saveNotifications();
  }

  void _filterNotifications() {
    setState(() {
      if (_selectedFilter == 'all') {
        _filteredNotifications = List.from(_notifications);
      } else {
        _filteredNotifications =
            _notifications
                .where(
                  (notification) =>
                      MessageUtility.getMessageCategory(notification['type']) ==
                      _selectedFilter,
                )
                .toList();
      }
    });
  }

  Future<void> _saveNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications', json.encode(_notifications));
  }

  void _onNotificationTap(Map<String, dynamic> notification) {
    String? action = MessageUtility.getAction(notification);
    String? id = MessageUtility.getId(notification);

    switch (action) {
      case MessageUtility.actionViewOrder:
        _navigateToOrder(id);
        break;
      case MessageUtility.actionViewProduct:
        _navigateToProduct(id);
        break;
      case MessageUtility.actionViewSubscription:
        _navigateToSubscription(id);
        break;
      case MessageUtility.actionOpenCart:
        _navigateToCart();
        break;
      case MessageUtility.actionOpenProfile:
        _navigateToProfile();
        break;
      case MessageUtility.actionOpenPromo:
        _navigateToPromo(id);
        break;
      default:
        debugPrint('Unknown notification action: $action');
    }
  }

  void _onNotificationDismiss(Map<String, dynamic> notification) {
    setState(() {
      _notifications.remove(notification);
    });
    _filterNotifications();
    _saveNotifications();
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Notifications'),
            content: const Text(
              'Are you sure you want to clear all notifications?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _notifications.clear();
                    _filteredNotifications.clear();
                  });
                  _saveNotifications();
                  Navigator.pop(context);
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }

  void _navigateToOrder(String? orderId) {
    // TODO: Navigate to order details
    debugPrint('Navigate to order: $orderId');
    Navigator.pop(context);
  }

  void _navigateToProduct(String? productId) {
    // TODO: Navigate to product details
    debugPrint('Navigate to product: $productId');
    Navigator.pop(context);
  }

  void _navigateToSubscription(String? subscriptionId) {
    // TODO: Navigate to subscription details
    debugPrint('Navigate to subscription: $subscriptionId');
    Navigator.pop(context);
  }

  void _navigateToCart() {
    // TODO: Navigate to cart
    debugPrint('Navigate to cart');
    Navigator.pop(context);
  }

  void _navigateToProfile() {
    // TODO: Navigate to profile
    debugPrint('Navigate to profile');
    Navigator.pop(context);
  }

  void _navigateToPromo(String? promoId) {
    // TODO: Navigate to promo details
    debugPrint('Navigate to promo: $promoId');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAllNotifications,
              tooltip: 'Clear all notifications',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs:
              _filterOptions.map((filter) {
                String title = filter[0].toUpperCase() + filter.substring(1);
                int count =
                    _notifications
                        .where(
                          (notification) =>
                              filter == 'all' ||
                              MessageUtility.getMessageCategory(
                                    notification['type'],
                                  ) ==
                                  filter,
                        )
                        .length;

                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
          onTap: (index) {
            setState(() {
              _selectedFilter = _filterOptions[index];
            });
            _filterNotifications();
          },
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children:
                    _filterOptions.map((filter) {
                      List<Map<String, dynamic>> filteredList =
                          filter == 'all'
                              ? _notifications
                              : _notifications
                                  .where(
                                    (notification) =>
                                        MessageUtility.getMessageCategory(
                                          notification['type'],
                                        ) ==
                                        filter,
                                  )
                                  .toList();

                      return NotificationListWidget(
                        notifications: filteredList,
                        onNotificationTap: _onNotificationTap,
                        onNotificationDismiss: _onNotificationDismiss,
                      );
                    }).toList(),
              ),
    );
  }
}
