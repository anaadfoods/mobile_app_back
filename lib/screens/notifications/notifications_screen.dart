import 'dart:math' as math;
import 'package:flutter/services.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Modern U-Shape Header
          _buildAnimatedHeader(context, theme, colorScheme, isDark),
          
          // Filter Chips Section
          SliverToBoxAdapter(
            child: _buildModernFilterChips(theme, colorScheme, isDark),
          ),
          
          // Notifications Content
          _isLoading
              ? SliverFillRemaining(
                  child: _buildLoadingState(theme),
                )
              : _buildNotificationsContent(theme, colorScheme, isDark),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme, bool isDark) {
    final unreadCount = _notifications.where((n) => n['read'] != true).length;
    
    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),

            // Animated Bell Icon
            Positioned(
              top: 60,
              right: 30,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: math.sin(value * math.pi * 4) * 0.15 * (1 - value),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Header Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row with Back Button and Clear Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        if (_notifications.isNotEmpty)
                          GestureDetector(
                            onTap: _clearAllNotifications,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete_sweep_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    // Title
                    Text(
                      "Notifications",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unreadCount > 0 
                          ? '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}'
                          : 'All caught up!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildModernFilterChips(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    final filterIcons = {
      'all': Icons.inbox_rounded,
      'payment': Icons.payment_rounded,
      'subscription': Icons.card_membership_rounded,
      'order': Icons.shopping_bag_rounded,
      'product': Icons.inventory_2_rounded,
      'promotional': Icons.local_offer_rounded,
      'system': Icons.settings_rounded,
    };
    
    final filterColors = {
      'all': colorScheme.primary,
      'payment': Colors.green,
      'subscription': Colors.purple,
      'order': Colors.blue,
      'product': Colors.orange,
      'promotional': Colors.pink,
      'system': Colors.grey,
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filterOptions.map((filter) {
            final isSelected = _selectedFilter == filter;
            final icon = filterIcons[filter] ?? Icons.notifications;
            final color = filterColors[filter] ?? colorScheme.primary;
            final count = _getFilterCount(filter);
            
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedFilter = filter;
                    _tabController.animateTo(_filterOptions.indexOf(filter));
                  });
                  _filterNotifications();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? color
                        : (isDark ? Colors.grey.shade800 : Colors.white),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? color : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isSelected ? Colors.white : color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        filter[0].toUpperCase() + filter.substring(1),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected 
                              ? Colors.white 
                              : (isDark ? Colors.white70 : Colors.grey.shade700),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.white.withOpacity(0.3)
                                : color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            count.toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isSelected ? Colors.white : color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  int _getFilterCount(String filter) {
    if (filter == 'all') return _notifications.length;
    if (filter == 'promotional') return _promotionalNotifications.length;
    return _notifications.where((n) => n['type'] == filter).length;
  }
  
  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * math.pi * 2,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationsContent(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    List<Map<String, dynamic>> displayList;
    if (_selectedFilter == 'all') {
      displayList = _notifications;
    } else if (_selectedFilter == 'promotional') {
      displayList = _promotionalNotifications;
    } else {
      displayList = _notifications.where((n) => n['type'] == _selectedFilter).toList();
    }
    
    if (displayList.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(theme, colorScheme),
      );
    }
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final notification = displayList[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: _buildModernNotificationCard(
                context, 
                notification, 
                theme, 
                colorScheme, 
                isDark,
                index,
              ),
            );
          },
          childCount: displayList.length,
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withOpacity(0.1),
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 64,
              color: colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up! Check back later.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernNotificationCard(
    BuildContext context,
    Map<String, dynamic> notification,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    int index,
  ) {
    final messageType = MessageUtility.getMessageType(notification);
    final icon = MessageUtility.getMessageIcon(messageType);
    final color = MessageUtility.getMessageColor(messageType);
    final timestamp = notification['timestamp'] as int? ?? 0;
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final isHighPriority = MessageUtility.isHighPriority(notification);
    final isRead = notification['read'] == true;
    
    return Dismissible(
      key: Key(notification['id']?.toString() ?? '$timestamp$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _onNotificationDismiss(notification),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _onNotificationTap(notification);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighPriority 
                  ? color.withOpacity(0.5)
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              width: isHighPriority ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isHighPriority ? color : theme.shadowColor).withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isRead ? theme.hintColor : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isHighPriority)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'URGENT',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isRead 
                                ? theme.hintColor.withOpacity(0.7)
                                : theme.hintColor,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: theme.hintColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            MessageUtility.formatTimestamp(timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          const Spacer(),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: theme.hintColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
