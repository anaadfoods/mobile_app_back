import 'package:grocery_app/common_widgets/global_import.dart';




class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

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
  List<Map<String, dynamic>> _promotionalNotifications = [];

  late TabController _tabController;

  static const List<String> _filterOptions = [
    'all',
    'payment',
    'subscription',
    'order',
    'product',
    'promotional',
    'system',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterOptions.length, vsync: this);
    _loadNotifications();
    _loadPromotionalNotifications();
    _listenToNewNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Clear promotional notifications when leaving the screen
    _clearPromotionalNotifications();
    super.dispose();
  }

  void _clearPromotionalNotifications() {
    setState(() {
      _promotionalNotifications.clear();
    });
    _savePromotionalNotifications();
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

      // Handle promotional notifications differently
      if (notificationData['type'] == 'promotional') {
        _addPromotionalNotification(notificationData);
      } else {
        _addNotification(notificationData);
      }
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
      } else if (_selectedFilter == 'promotional') {
        _filteredNotifications = List.from(_promotionalNotifications);
      } else {
        _filteredNotifications =
            _notifications
                .where(
                  (notification) => notification['type'] == _selectedFilter,
                )
                .toList();
      }
    });
  }

  Future<void> _saveNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications', json.encode(_notifications));
  }

  Future<void> _loadPromotionalNotifications() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? promotionalJson = prefs.getString('promotional_notifications');

      if (promotionalJson != null) {
        List<dynamic> promotionalList = json.decode(promotionalJson);
        setState(() {
          _promotionalNotifications =
              promotionalList.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error loading promotional notifications: $e');
    }
  }

  Future<void> _savePromotionalNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'promotional_notifications',
      json.encode(_promotionalNotifications),
    );
  }

  void _addPromotionalNotification(Map<String, dynamic> notification) {
    setState(() {
      _promotionalNotifications.insert(0, notification);
    });
    _savePromotionalNotifications();
  }

  void _removePromotionalNotification(Map<String, dynamic> notification) {
    setState(() {
      _promotionalNotifications.remove(notification);
    });
    _savePromotionalNotifications();
  }

  void _onNotificationTap(Map<String, dynamic> notification) {
    String? action = MessageUtility.getAction(notification);
    String? id = MessageUtility.getId(notification);
    String? type = notification['type'];

    // Handle different notification types
    switch (type) {
      case 'payment':
        _navigateToSubscription(
          id,
        ); // Redirect to subscription detail for payment reminders
        break;
      case 'subscription':
        _navigateToSubscription(
          id,
        ); // Redirect to subscription detail for subscription updates
        break;
      case 'order':
        _navigateToOrder(id); // Redirect to order screen
        break;
      case 'product':
        _navigateToHome(); // Redirect to home screen
        break;
      case 'promotional':
        _addPromotionalNotification(notification);
        _showPromotionalCard(notification);
        return;
      case 'system':
        // System updates - just show the notification, no navigation needed
        debugPrint('System notification: ${notification['title']}');
        break;
      default:
        // Fallback to action-based navigation
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
            debugPrint('Unknown notification type: $type and action: $action');
        }
    }
  }

  void _showPromotionalCard(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image section
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: NetworkImage(
                          notification['image'] ??
                              'https://via.placeholder.com/300x200',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Title
                  Text(
                    notification['title'] ?? 'Promotional Offer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  // Body
                  Text(
                    notification['body'] ?? 'Special offer just for you!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _removePromotionalNotification(notification);
                          },
                          child: Text(
                            'Dismiss',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _removePromotionalNotification(notification);
                            // Handle promotional action here
                            _handlePromotionalAction(notification);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'View Offer',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _handlePromotionalAction(Map<String, dynamic> notification) {
    // Handle promotional action based on notification data
    String? action = notification['action'];
    String? id = notification['id'];
    String? type = notification['type'];

    // Handle based on type first, then action
    switch (type) {
      case 'payment':
        _navigateToSubscription(id);
        break;
      case 'subscription':
        _navigateToSubscription(id);
        break;
      case 'order':
        _navigateToOrder(id);
        break;
      case 'product':
        _navigateToHome();
        break;
      case 'promotional':
        // Stay on notifications screen for promotional
        break;
      case 'system':
        // No navigation for system notifications
        break;
      default:
        // Fallback to action-based navigation
        switch (action) {
          case 'view_product':
            _navigateToProduct(id);
            break;
          case 'view_subscription':
            _navigateToSubscription(id);
            break;
          case 'open_cart':
            _navigateToCart();
            break;
          default:
            debugPrint('Unknown promotional action: $action');
        }
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
    if (orderId != null) {
      NavigationService.navigateToOrderDetails(orderId);
    }
    Navigator.pop(context);
  }

  void _navigateToProduct(String? productId) {
    if (productId != null) {
      NavigationService.navigateToProductDetails(productId);
    }
    Navigator.pop(context);
  }

  void _navigateToSubscription(String? subscriptionId) {
    if (subscriptionId != null) {
      NavigationService.navigateToSubscriptionDetails(subscriptionId);
    }
    Navigator.pop(context);
  }

  void _navigateToCart() {
    NavigationService.navigateToCart();
    Navigator.pop(context);
  }

  void _navigateToProfile() {
    NavigationService.navigateToAccount();
    Navigator.pop(context);
  }

  void _navigateToPromo(String? promoId) {
    // For promotional notifications, stay on notifications screen
    debugPrint('Navigate to promo: $promoId');
    Navigator.pop(context);
  }

  void _navigateToHome() {
    NavigationService.navigateToHome();
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
                int count;
                if (filter == 'all') {
                  count = _notifications.length;
                } else if (filter == 'promotional') {
                  count = _promotionalNotifications.length;
                } else {
                  count =
                      _notifications
                          .where(
                            (notification) => notification['type'] == filter,
                          )
                          .length;
                }

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
                      List<Map<String, dynamic>> filteredList;
                      if (filter == 'all') {
                        filteredList = _notifications;
                      } else if (filter == 'promotional') {
                        filteredList = _promotionalNotifications;
                      } else {
                        filteredList =
                            _notifications
                                .where(
                                  (notification) =>
                                      notification['type'] == filter,
                                )
                                .toList();
                      }

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
