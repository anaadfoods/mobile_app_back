import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/services/notification_sync_manager.dart';
import 'package:grocery_app/models/notification_model.dart';
import 'package:grocery_app/cubits/notification/notification_cubit.dart';
import 'package:grocery_app/cubits/notification/notification_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late final NotificationService _notificationService =
      getIt<NotificationService>();
  String _selectedFilter = 'all';
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
    _loadPromotionalNotifications();

    // Consciously trigger initial load, badge reset and sync via Cubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationCubit>().loadNotifications();
        context.read<NotificationCubit>().resetNotificationBadgeCount();
        context.read<NotificationCubit>().syncNotifications();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clearPromotionalNotifications();
    super.dispose();
  }

  void _clearPromotionalNotifications() {
    _promotionalNotifications.clear();
    _savePromotionalNotifications();
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

  // Flag to prevent double navigation
  bool _isNavigating = false;

  void _onNotificationTap(Map<String, dynamic> notification) {
    if (_isNavigating) return;
    _isNavigating = true;

    // Reset flag after delay to allow future navigation
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _isNavigating = false;
      }
    });

    // Parse metadata if available to extract deep link targets
    Map<String, dynamic> metadata = {};
    if (notification['metadata'] != null) {
      if (notification['metadata'] is Map) {
        metadata = Map<String, dynamic>.from(notification['metadata']);
      } else if (notification['metadata'] is String) {
        try {
          metadata = json.decode(notification['metadata']);
        } catch (_) {}
      }
    }

    String? metadataType =
        metadata['type']?.toString() ?? metadata['screen']?.toString();
    String? metadataId =
        (metadata['id'] ??
                metadata['order_id'] ??
                metadata['product_id'] ??
                metadata['subscription_id'])
            ?.toString();

    String? type =
        (metadataType != null && metadataType.isNotEmpty)
            ? metadataType
            : notification['type'];

    String? id =
        (metadataId != null && metadataId.isNotEmpty)
            ? metadataId
            : MessageUtility.getId(notification);

    String? action =
        notification['action'] ??
        metadata['action'] ??
        MessageUtility.getAction(notification);

    debugPrint(
      'Tapped notification - Resolved Type: $type, ID: $id, Action: $action',
    );

    // Handle different notification types
    switch (type) {
      case 'payment':
        _navigateToSubscription(
          id,
          notification,
        ); // Redirect to subscription detail for payment reminders
        break;
      case 'subscription':
      case 'subscription_detail': // Added to match NotificationService
        _navigateToSubscription(
          id,
          notification,
        ); // Redirect to subscription detail for subscription updates
        break;
      case 'order':
      case 'order_tracking': // Added to match NotificationService
        _navigateToOrder(id, notification); // Redirect to order screen
        break;
      case 'product':
      case 'product_detail': // Added to match NotificationService
        _navigateToProduct(id, notification);
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
        if (action != null) {
          switch (action) {
            case MessageUtility.actionViewOrder:
              _navigateToOrder(id, notification);
              break;
            case MessageUtility.actionViewProduct:
              _navigateToProduct(id, notification);
              break;
            case MessageUtility.actionViewSubscription:
              _navigateToSubscription(id, notification);
              break;
            case MessageUtility.actionOpenCart:
              _navigateToCart(notification);
              break;
            case MessageUtility.actionOpenProfile:
              _navigateToProfile(notification);
              break;
            case MessageUtility.actionOpenPromo:
              _navigateToPromo(id, notification);
              break;
            default:
              debugPrint(
                'Unknown notification type: $type and action: $action',
              );
          }
        } else {
          // Fallback if no action, try to route by type again or just debug
          debugPrint('No action found for type: $type');
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
                      color: AppColors.charcoal87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  // Body
                  Text(
                    notification['body'] ?? 'Special offer just for you!',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.rawEarth70,
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
                            style: TextStyle(color: AppColors.rawEarth70),
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
                            backgroundColor: AppColors.deepSoilGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'View Offer',
                            style: TextStyle(color: AppColors.parchment),
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
        _navigateToSubscription(id, notification);
        break;
      case 'subscription':
        _navigateToSubscription(id, notification);
        break;
      case 'order':
        _navigateToOrder(id, notification);
        break;
      case 'product':
        _navigateToProduct(
          id,
          notification,
        ); // Changed from _navigateToHome to _navigateToProduct
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
            _navigateToProduct(id, notification);
            break;
          case 'view_subscription':
            _navigateToSubscription(id, notification);
            break;
          case 'open_cart':
            _navigateToCart(notification);
            break;
          default:
            debugPrint('Unknown promotional action: $action');
        }
    }
  }

  void _onNotificationDismiss(Map<String, dynamic> notification) {
    final id = notification['id']?.toString() ?? '';

    if (id.isNotEmpty) {
      context.read<NotificationCubit>().dismiss([id]);
      try {
        getIt<NotificationService>().cancelNotification(
          int.tryParse(id) ?? id.hashCode,
        );
      } catch (_) {}
    }
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
                onPressed: () async {
                  context.read<NotificationCubit>().clearAllNotifications();
                  Navigator.pop(context);
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }

  void _navigateToOrder(String? orderId, Map<String, dynamic> notification) {
    _deleteNotification(notification);
    if (orderId != null) {
      NavigationService.navigateToOrderDetails(orderId);
    }
    // Navigator.pop(context); // Removed to prevent navigation conflicts
  }

  void _navigateToProduct(
    String? productId,
    Map<String, dynamic> notification,
  ) {
    _deleteNotification(notification);
    if (productId != null) {
      NavigationService.navigateToProductDetails(productId);
    }
    // Navigator.pop(context);
  }

  void _navigateToSubscription(
    String? subscriptionId,
    Map<String, dynamic> notification,
  ) {
    _deleteNotification(notification);
    if (subscriptionId != null) {
      NavigationService.navigateToSubscriptionDetails(subscriptionId);
    }
    // Navigator.pop(context);
  }

  void _navigateToCart(Map<String, dynamic> notification) {
    _deleteNotification(notification);
    NavigationService.navigateToCart();
    // Navigator.pop(context);
  }

  void _navigateToProfile(Map<String, dynamic> notification) {
    _deleteNotification(notification);
    NavigationService.navigateToAccount();
    // Navigator.pop(context);
  }

  void _navigateToPromo(String? promoId, Map<String, dynamic> notification) {
    // For promotional notifications, stay on notifications screen
    debugPrint('Navigate to promo: $promoId');
    // Navigator.pop(context);
  }

  void _deleteNotification(Map<String, dynamic> notification) {
    final id = notification['id']?.toString() ?? '';

    if (id.isNotEmpty) {
      context.read<NotificationCubit>().dismiss([id]);
      try {
        getIt<NotificationService>().cancelNotification(
          int.tryParse(id) ?? id.hashCode,
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final notifications =
            state.notifications.map((n) => n.toLocalMap()).toList();
        final isLoading = state.isLoading && notifications.isEmpty;

        return Scaffold(
          backgroundColor:
              isDark ? theme.scaffoldBackgroundColor : AppColors.parchment,
          body: RefreshIndicator(
            onRefresh: () async {
              await context.read<NotificationCubit>().syncNotifications();
            },
            color: colorScheme.primary,
            child: CustomScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(), // Allow refresh pull even when list is empty
              slivers: [
                // Modern U-Shape Header
                _buildAnimatedHeader(
                  context,
                  theme,
                  colorScheme,
                  isDark,
                  state.unreadCount,
                  notifications.isNotEmpty,
                ),

                // Filter Chips Section
                SliverToBoxAdapter(
                  child: _buildModernFilterChips(
                    theme,
                    colorScheme,
                    isDark,
                    notifications,
                  ),
                ),

                // Notifications Content
                isLoading
                    ? SliverFillRemaining(child: _buildLoadingState(theme))
                    : _buildNotificationsContent(
                      theme,
                      colorScheme,
                      isDark,
                      notifications,
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    int unreadCount,
    bool hasNotifications,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
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
                  color: AppColors.parchment.withValues(alpha: 0.1),
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
                  color: AppColors.parchment.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Bell icon with light white background
            // Positioned(
            //   top: MediaQuery.of(context).padding.top + 12,
            //   right: 20,
            //   child: Container(
            //     padding: const EdgeInsets.all(12),
            //     decoration: BoxDecoration(
            //       color: AppColors.parchment.withValues(alpha: 0.2),
            //       shape: BoxShape.circle,
            //     ),
            //     child: const Icon(
            //       Icons.notifications_rounded,
            //       color: AppColors.parchment,
            //       size: 28,
            //     ),
            //   ),
            // ),

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
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.parchment,
                          ),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        if (hasNotifications)
                          GestureDetector(
                            onTap: _clearAllNotifications,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.parchment.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete_sweep_rounded,
                                color: AppColors.parchment,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    // Title
                    Row(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Notifications",
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: AppColors.parchment,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Container(
                        //   padding: const EdgeInsets.all(12),
                        //   decoration: BoxDecoration(
                        //     color: AppColors.parchment.withValues(alpha: 0.2),
                        //     shape: BoxShape.circle,
                        //   ),
                        //   child: const Icon(
                        //     Icons.notifications_rounded,
                        //     color: AppColors.parchment,
                        //     size: 28,
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unreadCount > 0
                          ? '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}'
                          : 'All caught up!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.parchment.withValues(alpha: 0.9),
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

  Widget _buildModernFilterChips(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    List<Map<String, dynamic>> notifications,
  ) {
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
      'payment': AppColors.deepSoilGreen,
      'subscription': AppColors.harvestAmber,
      'order': AppColors.deepSoilGreen,
      'product': AppColors.harvestAmber,
      'promotional': AppColors.harvestAmber,
      'system': AppColors.rawEarth54,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children:
              _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                final icon = filterIcons[filter] ?? Icons.notifications;
                final color = filterColors[filter] ?? colorScheme.primary;
                final count = _getFilterCount(filter, notifications);

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedFilter = filter;
                        _tabController.animateTo(
                          _filterOptions.indexOf(filter),
                        );
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? color
                                : (isDark
                                    ? AppColors.charcoal87
                                    : AppColors.parchment),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color:
                              isSelected
                                  ? color
                                  : (isDark
                                      ? AppColors.charcoal60
                                      : AppColors.parchment),
                          width: 1.5,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
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
                            color: isSelected ? AppColors.parchment : color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            filter[0].toUpperCase() + filter.substring(1),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  isSelected
                                      ? AppColors.parchment
                                      : (isDark
                                          ? AppColors.parchment70
                                          : AppColors.charcoal60),
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? AppColors.parchment.withValues(
                                          alpha: 0.3,
                                        )
                                        : color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                count.toString(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color:
                                      isSelected ? AppColors.parchment : color,
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

  int _getFilterCount(String filter, List<Map<String, dynamic>> notifications) {
    if (filter == 'all') return notifications.length;
    if (filter == 'promotional') return _promotionalNotifications.length;
    return notifications.where((n) => n['type'] == filter).length;
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
                    color: AppColors.parchment,
                    size: 32,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsContent(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    List<Map<String, dynamic>> notifications,
  ) {
    List<Map<String, dynamic>> displayList;
    if (_selectedFilter == 'all') {
      displayList = notifications;
    } else if (_selectedFilter == 'promotional') {
      displayList = _promotionalNotifications;
    } else {
      displayList =
          notifications.where((n) => n['type'] == _selectedFilter).toList();
    }

    if (displayList.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState(theme, colorScheme));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final notification = displayList[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
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
        }, childCount: displayList.length),
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
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.5),
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
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
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
            Icon(Icons.delete_rounded, color: AppColors.parchment, size: 28),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: AppColors.parchment,
                fontWeight: FontWeight.w600,
              ),
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
            color: isDark ? AppColors.charcoal : AppColors.parchment,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isHighPriority
                      ? color.withValues(alpha: 0.5)
                      : (isDark ? AppColors.charcoal87 : AppColors.parchment),
              width: isHighPriority ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isHighPriority ? color : theme.shadowColor).withValues(
                  alpha: 0.08,
                ),
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
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.1),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'URGENT',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.parchment,
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
                            color:
                                isRead
                                    ? theme.hintColor.withValues(alpha: 0.7)
                                    : theme.hintColor,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Display image if available
                      if (notification['image'] != null ||
                          notification['image_url'] != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            notification['image'] ?? notification['image_url'],
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? AppColors.charcoal87
                                          : AppColors.parchment,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                'Error loading notification image: $error',
                              );
                              return const SizedBox.shrink();
                            },
                          ),
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
