import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/order_tracking_model.dart';
import 'package:grocery_app/routes/app_routes.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order? order;
  final String? orderId;
  const OrderDetailScreen({super.key, this.order, this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  bool _isCancelling = false;
  Order? _currentOrder;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Tracking state
  OrderTracking? _orderTracking;
  bool _isLoadingTracking = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    if (widget.order != null) {
      _currentOrder = widget.order;
      _animController.forward();
      _fetchTracking();
    } else if (widget.orderId != null) {
      _loadOrder(widget.orderId!);
    } else {
      // Handle error case - maybe pop or show error
    }
  }

  /// Fetches tracking data for the current order
  Future<void> _fetchTracking() async {
    if (_currentOrder == null) return;
    if (_isLoadingTracking) return;

    setState(() => _isLoadingTracking = true);
    try {
      final tracking = await _orderService.getOrderTracking(
        _currentOrder!.orderNumber,
      );
      if (mounted) {
        setState(() {
          _orderTracking = tracking;
          _isLoadingTracking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTracking = false);
      }
    }
  }

  Future<void> _loadOrder(String id) async {
    setState(() => _isLoading = true);
    try {
      final order = await _orderService.getOrderById(int.parse(id));
      if (mounted) {
        setState(() {
          _currentOrder = order;
          _isLoading = false;
        });
        _animController.forward();
        _fetchTracking();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Failed to load order: $e');
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    if (date.year == 1970) return 'Delivery date pending';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatShortDate(DateTime date) {
    if (date.year == 1970) return 'Date unknown';
    return DateFormat('MMM d, h:mm a').format(date);
  }

  void _copyOrderNumber() async {
    if (_currentOrder == null) return;
    await Clipboard.setData(ClipboardData(text: _currentOrder!.orderNumber));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    SnackBarHelper.showSuccess(context, 'Order number copied!');
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _CancelConfirmDialog(),
    );

    if (confirmed != true) return;

    if (_currentOrder == null) return;

    try {
      setState(() => _isCancelling = true);
      final success = await _orderService.cancelOrder(_currentOrder!.id);
      if (mounted) {
        if (success) {
          setState(() {
            _currentOrder = _currentOrder!.copyWith(status: "CANCELLED");
            _isCancelling = false;
          });
          SnackBarHelper.showSuccess(context, 'Order cancelled successfully');
          Navigator.pop(context, true);
        } else {
          setState(() => _isCancelling = false);
          SnackBarHelper.showError(context, 'Failed to cancel order');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        AppErrorHelper.showErrorSnackbar(context, error: e);
      }
    }
  }

  Future<void> _downloadInvoice() async {
    try {
      HapticFeedback.lightImpact();

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt <= 32) {
          final status = await Permission.storage.status;
          if (!status.isGranted) {
            final result = await Permission.storage.request();
            if (!result.isGranted) {
              if (mounted) {
                SnackBarHelper.showError(
                  context,
                  'Please provide media access to download the invoice.',
                  action: SnackBarAction(
                    label: 'Settings',
                    textColor: AppColors.parchment,
                    onPressed: openAppSettings,
                  ),
                );
              }
              return;
            }
          }
        }
      }

      SnackBarHelper.showLoading(context, 'Downloading invoice...');

      if (_currentOrder == null) return;

      final filePath = await _orderService.downloadOrderInvoice(
        _currentOrder!.orderNumber,
      );

      if (!mounted) return;
      SnackBarHelper.showSuccess(
        context,
        'Invoice downloaded successfully!',
        action: SnackBarAction(
          label: 'Open',
          textColor: AppColors.parchment,
          onPressed: () {
            SnackBarHelper.showInfo(context, 'File saved to: $filePath');
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String message = e.toString().replaceAll('Exception: ', '');
      // Remove any remaining wrapping if it exists (though we fixed service to not wrap known ones)
      if (message.startsWith('Failed to download invoice: ')) {
        message = message.replaceAll('Failed to download invoice: ', '');
      }

      final isSpecificError = message.contains('No invoice available');

      SnackBarHelper.showError(
        context,
        isSpecificError ? message : 'Failed to download invoice: $message',
        action: SnackBarAction(
          label: 'Retry',
          textColor: AppColors.parchment,
          onPressed: _downloadInvoice,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentOrder == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Invalid Link'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Invalid link or unauthorized access',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'We could not load the order details. The link may be invalid, or you might not have permission to view it.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 32),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, authState) {
                    final isAuthenticated = authState is Authenticated;
                    return ElevatedButton.icon(
                      onPressed: () {
                        if (isAuthenticated) {
                          context.goNamed(AppRoute.home.name);
                        } else {
                          context.goNamed(AppRoute.login.name);
                        }
                      },
                      icon: Icon(
                        isAuthenticated
                            ? Icons.home_rounded
                            : Icons.login_rounded,
                      ),
                      label: Text(isAuthenticated ? 'Go to Home' : 'Log In'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = _getStatusInfo(_currentOrder!.status);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.goNamed(AppRoute.home.name);
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.parchment,
        body: RefreshIndicator(
          onRefresh: () async {
            // Refresh order details and tracking
            final updatedOrder = await _orderService.getOrderById(
              _currentOrder!.id,
            );
            if (updatedOrder.id == _currentOrder!.id) {
              setState(() {
                _currentOrder = updatedOrder;
              });
            }
            await _fetchTracking();
          },
          color: theme.colorScheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Premium U-Shape Header
              _buildAnimatedHeader(theme, isDark, status),
              // Content
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    child: Column(
                      children: [
                        // Premium Delivery Header (Amazon-style)
                        _buildDeliveryDateHeader(theme, isDark),
                        const SizedBox(height: 16),
                        // Order Timeline with tracking
                        _buildTrackingTimelineCard(theme, isDark),
                        const SizedBox(height: 16),
                        // Referral Reward Banner
                        if (_currentOrder!.hasReferralReward)
                          _buildReferralRewardBanner(theme, isDark),
                        if (_currentOrder!.hasReferralReward)
                          const SizedBox(height: 16),
                        // Products
                        _buildProductsCard(theme, isDark),
                        const SizedBox(height: 16),
                        // Price Summary
                        _buildPriceSummaryCard(theme, isDark),
                        const SizedBox(height: 16),
                        // Delivery Details
                        _buildDeliveryCard(theme, isDark),
                        const SizedBox(height: 16),
                        // Actions
                        _buildActionsCard(theme, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildWhatsAppFAB(),
      ),
    );
  }

  Widget _buildAnimatedHeader(
    ThemeData theme,
    bool isDark,
    _StatusInfo status,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        constraints: const BoxConstraints(minHeight: 220),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [status.color, status.color.withValues(alpha: 0.8)],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: status.color.withValues(alpha: 0.3),
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

            // Header Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row with Back Button and Invoice Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AnaadLogoMark(),
                        // Action Buttons: Refresh, Invoice
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                SnackBarHelper.showLoading(
                                  context,
                                  'Refreshing...',
                                );
                                final updatedOrder = await _orderService
                                    .getOrderById(_currentOrder!.id);
                                if (updatedOrder.id == _currentOrder!.id) {
                                  setState(() => _currentOrder = updatedOrder);
                                }
                                await _fetchTracking();
                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.parchment.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  color: AppColors.harvestAmber,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _downloadInvoice,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.parchment.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: AppColors.harvestAmber,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.parchment.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status.icon,
                            size: 16,
                            color: AppColors.harvestAmber,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status.label,
                            style: const TextStyle(
                              color: AppColors.harvestAmber,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Order number and copy button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Order #${_currentOrder!.orderNumber}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: AppColors.parchment,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Placed on ${_formatShortDate(_currentOrder!.createdAt)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.parchment.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Copy button
                        GestureDetector(
                          onTap: _copyOrderNumber,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.parchment.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.copy_rounded,
                              color: AppColors.harvestAmber,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildBackButton(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.goNamed(AppRoute.home.name);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.parchment.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.harvestAmber,
          size: 20,
        ),
      ),
    );
  }

  // ==================== PREMIUM DELIVERY HEADER ====================
  /// Amazon-style delivery header showing estimated delivery prominently
  Widget _buildDeliveryDateHeader(ThemeData theme, bool isDark) {
    // Determine the delivery date to display
    final DateTime? estimatedDelivery =
        _orderTracking?.estimatedDelivery ??
        (_currentOrder!.expectedDeliveryDate.year != 1970
            ? _currentOrder!.expectedDeliveryDate
            : null);

    final bool isDelivered = _currentOrder!.status.toUpperCase() == 'DELIVERED';
    final bool isCancelled = _currentOrder!.status.toUpperCase() == 'CANCELLED';

    // Format the delivery date
    String deliveryText;
    Color headerColor;
    IconData headerIcon;

    if (isDelivered) {
      deliveryText =
          'Delivered on ${DateFormat('d MMM, h:mm a').format(_currentOrder!.updatedAt)}';
      headerColor = AppColors.deepSoilGreen;
      headerIcon = Icons.check_circle_rounded;
    } else if (isCancelled) {
      deliveryText = 'Order Cancelled';
      headerColor = AppColors.deepSoilGreen;
      headerIcon = Icons.local_shipping_rounded;
    } else if (estimatedDelivery != null) {
      deliveryText =
          'Arriving by ${DateFormat('d MMM, h:mm a').format(estimatedDelivery)}';
      headerColor = AppColors.deepSoilGreen;
      headerIcon = Icons.local_shipping_rounded;
    } else {
      deliveryText = 'Delivery date pending';
      headerColor = AppColors.deepSoilGreen;
      headerIcon = Icons.local_shipping_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            headerColor.withValues(alpha: 0.15),
            headerColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: headerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: headerColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(headerIcon, color: headerColor, size: 28),
          ),
          const SizedBox(width: 16),
          // Delivery text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deliveryText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: headerColor,
                    fontSize: 18,
                  ),
                ),
                if (_orderTracking?.awbNumber != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code_rounded,
                        size: 14,
                        color: theme.hintColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AWB: ${_orderTracking!.awbNumber}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Product thumbnail (first item)
          if (_currentOrder!.items.isNotEmpty) _buildProductThumbnail(isDark),
        ],
      ),
    );
  }

  Widget _buildProductThumbnail(bool isDark) {
    final firstItem = _currentOrder!.items.first;
    final imageUrl =
        firstItem.productDetails.productImages.isNotEmpty
            ? firstItem.productDetails.productImages[0].image
            : null;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.parchment24 : AppColors.rawEarth12,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child:
            imageUrl != null
                ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImagePlaceholder(isDark),
                )
                : _buildImagePlaceholder(isDark),
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
      child: Icon(
        Icons.image_outlined,
        color: isDark ? AppColors.parchment24 : AppColors.rawEarth26,
        size: 20,
      ),
    );
  }

  // ==================== TRACKING TIMELINE CARD ====================
  /// Premium tracking timeline with "See all updates" link
  Widget _buildTrackingTimelineCard(ThemeData theme, bool isDark) {
    return _ModernCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            theme,
            icon: Icons.timeline_rounded,
            title: 'Order Timeline',
            color: AppColors.harvestAmber,
          ),
          const SizedBox(height: 20),
          // Timeline stepper
          _buildTrackingTimeline(theme, isDark),
          // "See all updates" link
          if (_orderTracking != null &&
              _orderTracking!.trackingEvents.isNotEmpty) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showTrackingHistorySheet(theme, isDark),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: AppColors.harvestAmber,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'See all ${_orderTracking!.trackingEvents.length} updates',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.harvestAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.harvestAmber,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build the tracking timeline using tracking data if available
  Widget _buildTrackingTimeline(ThemeData theme, bool isDark) {
    final steps = _getTrackingTimelineSteps();

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        final isCompleted = step.isCompleted;
        final isCurrent = step.isCurrent;

        return GestureDetector(
          onTap: () {
            // Open tracking history sheet if tracking data is available
            if (_orderTracking != null &&
                _orderTracking!.trackingEvents.isNotEmpty) {
              _showTrackingHistorySheet(theme, isDark);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          isCompleted || isCurrent
                              ? step.color
                              : (isDark
                                  ? AppColors.charcoal87
                                  : AppColors.parchment),
                      shape: BoxShape.circle,
                      boxShadow:
                          isCurrent
                              ? [
                                BoxShadow(
                                  color: step.color.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                              : null,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_rounded : step.icon,
                      color:
                          isCompleted || isCurrent
                              ? AppColors.parchment
                              : (isDark
                                  ? AppColors.rawEarth70
                                  : AppColors.rawEarth26),
                      size: 16,
                    ),
                  ),
                  if (!isLast)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 2,
                      height: 40,
                      color:
                          isCompleted
                              ? step.color.withValues(alpha: 0.5)
                              : (isDark
                                  ? AppColors.charcoal87
                                  : AppColors.parchment),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Step content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color:
                                    isCompleted || isCurrent
                                        ? null
                                        : theme.hintColor,
                              ),
                            ),
                          ),
                          // Show arrow indicator if tracking data is available
                          if (_orderTracking != null &&
                              _orderTracking!.trackingEvents.isNotEmpty)
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: theme.hintColor.withValues(alpha: 0.5),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Get timeline steps based on tracking data or order status
  /// Uses the tracking.status field (shipping status) when available,
  /// falling back to order status
  List<_TimelineStep> _getTrackingTimelineSteps() {
    // Use tracking.status (shipping status like "IN TRANSIT") if available,
    // otherwise fall back to order status
    final rawStatus =
        _orderTracking?.status.isNotEmpty == true
            ? _orderTracking!.status
            : _currentOrder!.status;
    // Normalize: uppercase and replace spaces with underscores
    final status = rawStatus.toUpperCase().replaceAll(' ', '_');
    final steps = <_TimelineStep>[];

    // Order Placed
    steps.add(
      _TimelineStep(
        title: 'Order Placed',
        subtitle: _formatShortDate(_currentOrder!.createdAt),
        icon: Icons.shopping_bag_outlined,
        color: AppColors.harvestAmber,
        isCompleted: true,
        isCurrent: status == 'PLACED' || status == 'CREATED',
      ),
    );

    // Shipped
    final isShipped = [
      'PACKED',
      'PICKED_UP',
      'PICKUP',
      'MANIFESTED',
      'SHIPPED',
      'IN_TRANSIT',
      'OUT_FOR_DELIVERY',
      'DELIVERED',
    ].contains(status);
    final isCurrentShipped = [
      'PACKED',
      'PICKED_UP',
      'PICKUP',
      'MANIFESTED',
      'SHIPPED',
      'IN_TRANSIT',
    ].contains(status);

    // Try to get shipped date from tracking events
    String shippedSubtitle = 'Waiting for shipment';
    if (isShipped &&
        _orderTracking != null &&
        _orderTracking!.trackingEvents.isNotEmpty) {
      // Find the SHIPPED or PICKED UP event (events are ordered oldest to newest)
      final shippedEvent = _orderTracking!.trackingEvents.firstWhere((e) {
        final s = e.status.toUpperCase().replaceAll(' ', '_');
        return s == 'SHIPPED' || s == 'PICKED_UP' || s == 'IN_TRANSIT';
      }, orElse: () => _orderTracking!.trackingEvents.first);
      if (shippedEvent.timestamp.year != 1970) {
        shippedSubtitle = _formatShortDate(shippedEvent.timestamp);
      } else {
        shippedSubtitle = 'Package is on the way';
      }
    } else if (isShipped) {
      shippedSubtitle = 'Package is on the way';
    }

    steps.add(
      _TimelineStep(
        title: 'Shipped',
        subtitle: shippedSubtitle,
        icon: Icons.local_shipping_outlined,
        color: AppColors.harvestAmber,
        isCompleted: isShipped && !isCurrentShipped,
        isCurrent: isCurrentShipped,
      ),
    );

    // Out for Delivery
    final isOutForDelivery = ['OUT_FOR_DELIVERY', 'DELIVERED'].contains(status);

    // Try to get out for delivery date from tracking events
    String outForDeliverySubtitle = 'Pending';
    if (isOutForDelivery &&
        _orderTracking != null &&
        _orderTracking!.trackingEvents.isNotEmpty) {
      // Find the OUT FOR DELIVERY event (specifically, not OUT FOR PICKUP)
      final ofdEvent = _orderTracking!.trackingEvents
          .cast<TrackingEvent?>()
          .firstWhere((e) {
            final s = e!.status.toUpperCase().replaceAll(' ', '_');
            return s == 'OUT_FOR_DELIVERY' || s.contains('OFD');
          }, orElse: () => null);
      if (ofdEvent != null && ofdEvent.timestamp.year != 1970) {
        outForDeliverySubtitle = _formatShortDate(ofdEvent.timestamp);
      } else {
        outForDeliverySubtitle = 'Package is with the delivery agent';
      }
    } else if (isOutForDelivery) {
      outForDeliverySubtitle = 'Package is with the delivery agent';
    }

    steps.add(
      _TimelineStep(
        title: 'Out for Delivery',
        subtitle: outForDeliverySubtitle,
        icon: Icons.delivery_dining_outlined,
        color: AppColors.harvestAmber,
        isCompleted: status == 'DELIVERED',
        isCurrent: status == 'OUT_FOR_DELIVERY',
      ),
    );

    // Delivered
    final isDelivered = status == 'DELIVERED';

    // Get delivered/expected date
    String deliveredSubtitle;
    if (isDelivered) {
      // Try to get delivered date from tracking events
      if (_orderTracking != null && _orderTracking!.trackingEvents.isNotEmpty) {
        final deliveredEvent = _orderTracking!.trackingEvents.firstWhere(
          (e) => e.status.toUpperCase().contains('DELIVER'),
          orElse: () => _orderTracking!.trackingEvents.first,
        );
        if (deliveredEvent.timestamp.year != 1970) {
          deliveredSubtitle = _formatShortDate(deliveredEvent.timestamp);
        } else {
          deliveredSubtitle = _formatShortDate(_currentOrder!.updatedAt);
        }
      } else {
        deliveredSubtitle = _formatShortDate(_currentOrder!.updatedAt);
      }
    } else {
      // Show expected delivery date
      if (_orderTracking?.estimatedDelivery != null &&
          _orderTracking!.estimatedDelivery!.year != 1970) {
        deliveredSubtitle =
            'Expected: ${DateFormat('MMM d').format(_orderTracking!.estimatedDelivery!)}';
      } else if (_currentOrder!.expectedDeliveryDate.year != 1970) {
        deliveredSubtitle =
            'Expected: ${DateFormat('MMM d').format(_currentOrder!.expectedDeliveryDate)}';
      } else {
        deliveredSubtitle = 'TBD';
      }
    }

    steps.add(
      _TimelineStep(
        title: 'Delivered',
        subtitle: deliveredSubtitle,
        icon: Icons.home_outlined,
        color: AppColors.harvestAmber,
        isCompleted: isDelivered,
        isCurrent: isDelivered,
      ),
    );

    return steps;
  }

  // ==================== TRACKING HISTORY BOTTOM SHEET ====================
  void _showTrackingHistorySheet(ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder:
          (context) => _TrackingHistorySheet(
            tracking: _orderTracking!,
            theme: theme,
            isDark: isDark,
          ),
    );
  }

  Widget _buildReferralRewardBanner(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.parchment.withValues(alpha: 0.15),
            AppColors.parchment.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.parchment, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.parchment.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.parchment, AppColors.parchment],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.parchment.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.parchment,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎁 Referral Reward Order!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.parchment,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This order contains your referral reward. Enjoy your free gift!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        isDark ? AppColors.parchment70 : AppColors.charcoal60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsCard(ThemeData theme, bool isDark) {
    return _ModernCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            theme,
            icon: Icons.shopping_bag_rounded,
            title: 'Items (${_currentOrder!.items.length})',
            color: AppColors.deepSoilGreen,
          ),
          const SizedBox(height: 16),
          ..._currentOrder!.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == _currentOrder!.items.length - 1;
            return _buildProductItem(theme, isDark, item, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildProductItem(
    ThemeData theme,
    bool isDark,
    OrderItemResponse item,
    bool isLast,
  ) {
    final product = item.productDetails;
    final imageUrl =
        product.productImages.isNotEmpty
            ? product.productImages[0].image
            : null;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(product: product),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.parchment.withValues(alpha: 0.05)
                      : AppColors.rawEarth54.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Product image
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.parchment!,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child:
                        imageUrl != null
                            ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      _buildImagePlaceholder(isDark),
                            )
                            : _buildImagePlaceholder(isDark),
                  ),
                ),
                const SizedBox(width: 14),
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.weight} ${product.weightUnit}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.harvestAmber.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Qty: ${item.quantity}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.harvestAmber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '× ₹${product.finalPrice.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.total.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.harvestAmber,
                      ),
                    ),
                    if (product.discountPercentage > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.harvestAmber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.harvestAmber,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!isLast) const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPriceSummaryCard(ThemeData theme, bool isDark) {
    return _ModernCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            theme,
            icon: Icons.receipt_rounded,
            title: 'Payment Summary',
            color: AppColors.deepSoilGreen,
          ),
          const SizedBox(height: 20),
          _buildPriceRow(theme, 'Subtotal', _currentOrder!.subtotal),
          const SizedBox(height: 12),
          _buildPriceRow(
            theme,
            'Discount included',
            -_currentOrder!.discount,
            isDiscount: true,
          ),
          const SizedBox(height: 12),
          _buildPriceRow(theme, 'Delivery', _currentOrder!.deliveryCharges),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.harvestAmber.withValues(alpha: 0.1),
                  AppColors.harvestAmber.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${_currentOrder!.total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.harvestAmber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Payment status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getPaymentStatusColor(
                _currentOrder!.paymentStatus,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getPaymentStatusColor(
                  _currentOrder!.paymentStatus,
                ).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _currentOrder!.paymentStatus == 'PAID'
                      ? Icons.check_circle_rounded
                      : Icons.pending_rounded,
                  color: _getPaymentStatusColor(_currentOrder!.paymentStatus),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment ${_currentOrder!.paymentStatus}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _getPaymentStatusColor(
                            _currentOrder!.paymentStatus,
                          ),
                        ),
                      ),
                      Text(
                        'via ${_currentOrder!.paymentMethod}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    ThemeData theme,
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        Text(
          '${isDiscount && amount != 0 ? '-' : ''}₹${amount.abs().toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDiscount ? AppColors.harvestAmber : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryCard(ThemeData theme, bool isDark) {
    return _ModernCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            theme,
            icon: Icons.location_on_rounded,
            title: 'Delivery Address',
            color: AppColors.rawEarth,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.parchment.withValues(alpha: 0.05)
                      : AppColors.rawEarth54.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getRecipientName(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentOrder!.deliveryAddress,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_currentOrder!.deliveryCity}, ${_currentOrder!.deliveryState}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                Text(
                  _currentOrder!.deliveryPincode,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: theme.hintColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentOrder!.deliveryPhone,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Expected delivery
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.harvestAmber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.harvestAmber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: AppColors.harvestAmber,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected Delivery',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      Text(
                        _formatDate(_currentOrder!.expectedDeliveryDate),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.harvestAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(ThemeData theme, bool isDark) {
    final canCancel =
        _currentOrder!.status != 'DELIVERED' &&
        _currentOrder!.status != 'CANCELLED' &&
        _currentOrder!.status != 'SHIPPED';

    return _ModernCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            theme,
            icon: Icons.touch_app_rounded,
            title: 'Quick Actions',
            color: AppColors.harvestAmber,
          ),
          const SizedBox(height: 16),
          // Help button
          _buildActionButton(
            theme,
            isDark,
            icon: Icons.support_agent_rounded,
            title: 'Need Help?',
            subtitle: 'Contact support for any issues',
            color: AppColors.harvestAmber,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                          HelpScreen(orderNumber: _currentOrder!.orderNumber),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Download invoice
          _buildActionButton(
            theme,
            isDark,
            icon: Icons.download_rounded,
            title: 'Download Invoice',
            subtitle: 'Get PDF copy of your order',
            color: AppColors.harvestAmber,
            onTap: _downloadInvoice,
          ),
          if (canCancel) ...[
            const SizedBox(height: 12),
            _buildActionButton(
              theme,
              isDark,
              icon: Icons.cancel_outlined,
              title: 'Cancel Order',
              subtitle: 'Request order cancellation',
              color: AppColors.rawEarth,
              isDestructive: true,
              isLoading: _isCancelling,
              onTap: _cancelOrder,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDestructive ? 0.08 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  isLoading
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                      : Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? color : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  FloatingActionButton _buildWhatsAppFAB() {
    return FloatingActionButton.extended(
      backgroundColor: AppColors.parchment,
      foregroundColor: AppColors.charcoal,
      icon: const Icon(Icons.chat_rounded),
      label: const Text('Chat Support'),
      onPressed: () async {
        HapticFeedback.lightImpact();
        final user = AuthService().currentUser;
        const phone = '+919996166186';
        final message = Uri.encodeComponent(
          'Hi! I need help with my order.\n\n'
          'Order #${_currentOrder!.orderNumber}\n'
          'Status: ${_currentOrder!.status}\n'
          'Amount: ₹${_currentOrder!.total}\n\n'
          'Name: ${user?.firstName ?? ''} ${user?.lastName ?? ''}\n'
          'Phone: ${user?.phoneNumber ?? ''}',
        );
        final url = 'https://wa.me/$phone?text=$message';
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          }
        } catch (e) {
          if (!mounted) return;
          SnackBarHelper.showError(context, 'Could not open WhatsApp');
        }
      },
    );
  }

  List<_TimelineStep> _getTimelineSteps() {
    final status = _currentOrder!.status.toUpperCase();
    final steps = <_TimelineStep>[];

    // Order Placed - always completed
    steps.add(
      _TimelineStep(
        title: 'Order Placed',
        subtitle: _formatShortDate(_currentOrder!.createdAt),
        icon: Icons.check_circle_outline,
        color: AppColors.harvestAmber,
        isCompleted: true,
        isCurrent: status == 'PLACED',
      ),
    );

    // Shipped
    final isShipped = [
      'SHIPPED',
      'OUT_FOR_DELIVERY',
      'DELIVERED',
    ].contains(status);
    steps.add(
      _TimelineStep(
        title: 'Order Shipped',
        subtitle: isShipped ? 'Your order is on the way' : 'Pending',
        icon: Icons.local_shipping_outlined,
        color: AppColors.harvestAmber,
        isCompleted: isShipped,
        isCurrent: status == 'SHIPPED',
      ),
    );

    // Out for Delivery
    final isOutForDelivery = ['OUT_FOR_DELIVERY', 'DELIVERED'].contains(status);
    steps.add(
      _TimelineStep(
        title: 'Out for Delivery',
        subtitle: isOutForDelivery ? 'Arriving soon' : 'Pending',
        icon: Icons.delivery_dining_outlined,
        color: AppColors.harvestAmber,
        isCompleted: isOutForDelivery,
        isCurrent: status == 'OUT_FOR_DELIVERY',
      ),
    );

    // Delivered
    final isDelivered = status == 'DELIVERED';
    steps.add(
      _TimelineStep(
        title: 'Delivered',
        subtitle:
            isDelivered
                ? _formatShortDate(_currentOrder!.updatedAt)
                : 'Expected: ${DateFormat('MMM d').format(_currentOrder!.expectedDeliveryDate)}',
        icon: Icons.home_outlined,
        color: AppColors.harvestAmber,
        isCompleted: isDelivered,
        isCurrent: isDelivered,
      ),
    );

    return steps;
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return _StatusInfo(
          color: AppColors.deepSoilGreen,
          icon: Icons.check_circle_rounded,
          label: 'Delivered',
        );
      case 'CANCELLED':
        return _StatusInfo(
          color: AppColors.rawEarth,
          icon: Icons.cancel_rounded,
          label: 'Cancelled',
        );
      case 'SHIPPED':
        return _StatusInfo(
          color: AppColors.deepSoilGreen,
          icon: Icons.local_shipping_rounded,
          label: 'Shipped',
        );
      case 'OUT_FOR_DELIVERY':
        return _StatusInfo(
          color: AppColors.deepSoilGreen,
          icon: Icons.delivery_dining_rounded,
          label: 'Out for Delivery',
        );
      case 'PLACED':
      default:
        return _StatusInfo(
          color: AppColors.deepSoilGreen,
          icon: Icons.pending_rounded,
          label: 'Order Placed',
        );
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return AppColors.deepSoilGreen;
      case 'PENDING':
        return AppColors.harvestAmber;
      case 'FAILED':
        return AppColors.rawEarth;
      default:
        return AppColors.rawEarth54;
    }
  }

  String _getRecipientName() {
    if (_currentOrder!.recipientName.isNotEmpty) {
      return _currentOrder!.recipientName;
    }

    final user = AuthService().currentUser;
    if (user != null) {
      final firstName = user.firstName;
      final lastName = user.lastName;
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
    }

    return 'Valued Customer';
  }
}

// Helper Classes
class _StatusInfo {
  final Color color;
  final IconData icon;
  final String label;

  _StatusInfo({required this.color, required this.icon, required this.label});
}

class _TimelineStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isCompleted;
  final bool isCurrent;

  _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isCompleted,
    required this.isCurrent,
  });
}

// Modern Card Widget
class _ModernCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _ModernCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? AppColors.charcoal.withValues(alpha: 0.3)
                    : AppColors.charcoal.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );
  }
}

// Cancel Confirmation Dialog
class _CancelConfirmDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.rawEarth.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.warning_rounded,
              color: AppColors.rawEarth,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Cancel Order?'),
        ],
      ),
      content: Text(
        'Are you sure you want to cancel this order? This action cannot be undone.',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No, Keep It'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.rawEarth),
          child: const Text('Yes, Cancel'),
        ),
      ],
    );
  }
}

// ==================== TRACKING HISTORY BOTTOM SHEET ====================
/// Full expanded tracking history with all events grouped by date
class _TrackingHistorySheet extends StatelessWidget {
  final OrderTracking tracking;
  final ThemeData theme;
  final bool isDark;

  const _TrackingHistorySheet({
    required this.tracking,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Group events by date
    final groupedEvents = _groupEventsByDate();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.charcoal60 : AppColors.rawEarth12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.harvestAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_shipping_rounded,
                    color: AppColors.harvestAmber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tracking History',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (tracking.awbNumber != null)
                        Text(
                          'AWB: ${tracking.awbNumber}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.parchment,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: theme.hintColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Events list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: groupedEvents.length,
              itemBuilder: (context, index) {
                final entry = groupedEvents.entries.elementAt(index);
                return _buildDateGroup(entry.key, entry.value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<TrackingEvent>> _groupEventsByDate() {
    final grouped = <String, List<TrackingEvent>>{};

    // Sort events in reverse chronological order
    final sortedEvents = List<TrackingEvent>.from(tracking.trackingEvents)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    for (final event in sortedEvents) {
      final dateKey = DateFormat('EEEE, d MMMM yyyy').format(event.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(event);
    }

    return grouped;
  }

  Widget _buildDateGroup(String date, List<TrackingEvent> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: theme.hintColor,
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
        // Events for this date
        ...events.asMap().entries.map((entry) {
          final isLast = entry.key == events.length - 1;
          return _buildEventRow(entry.value, isLast);
        }),
      ],
    );
  }

  Widget _buildEventRow(TrackingEvent event, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot and line
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.harvestAmber,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.harvestAmber.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isDark ? AppColors.charcoal60 : AppColors.rawEarth12,
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Event content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time
                Text(
                  DateFormat('h:mm a').format(event.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.harvestAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // Status
                Text(
                  event.courierStatus.isNotEmpty
                      ? event.courierStatus
                      : event.status,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Activity description
                if (event.activity.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.activity,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
                // Location
                if (event.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: theme.hintColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
