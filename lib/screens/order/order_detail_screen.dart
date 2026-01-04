import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  bool _isCancelling = false;
  late Order _currentOrder;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  String _formatShortDate(DateTime date) {
    return DateFormat('MMM d, h:mm a').format(date);
  }

  void _copyOrderNumber() async {
    await Clipboard.setData(ClipboardData(text: _currentOrder.orderNumber));
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

    try {
      setState(() => _isCancelling = true);
      final success = await _orderService.cancelOrder(_currentOrder.id);
      if (mounted) {
        if (success) {
          setState(() {
            _currentOrder = _currentOrder.copyWith(status: "CANCELLED");
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
        SnackBarHelper.showError(context, 'Failed to cancel order: $e');
      }
    }
  }

  Future<void> _downloadInvoice() async {
    try {
      HapticFeedback.lightImpact();
      SnackBarHelper.showLoading(context, 'Downloading invoice...');

      final filePath = await _orderService.downloadOrderInvoice(
        _currentOrder.orderNumber,
      );

      if (!mounted) return;
      SnackBarHelper.showSuccess(
        context,
        'Invoice downloaded successfully!',
        action: SnackBarAction(
          label: 'Open',
          textColor: Colors.white,
          onPressed: () {
            SnackBarHelper.showInfo(context, 'File saved to: $filePath');
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        'Failed to download invoice: $e',
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _downloadInvoice,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = _getStatusInfo(_currentOrder.status);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
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
                    // Order Timeline
                    _buildTimelineCard(theme, isDark),
                    const SizedBox(height: 16),
                    // Referral Reward Banner
                    if (_currentOrder.hasReferralReward)
                      _buildReferralRewardBanner(theme, isDark),
                    if (_currentOrder.hasReferralReward)
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
      floatingActionButton: _buildWhatsAppFAB(),
    );
  }

  Widget _buildAnimatedHeader(
    ThemeData theme,
    bool isDark,
    _StatusInfo status,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [status.color, status.color.withOpacity(0.8)],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: status.color.withOpacity(0.3),
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
                        GestureDetector(
                          onTap: _downloadInvoice,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.icon, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            status.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Order number and copy button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${_currentOrder.orderNumber}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Placed on ${_formatShortDate(_currentOrder.createdAt)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
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
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.copy_rounded,
                              color: Colors.white,
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

  Widget _buildTimelineCard(ThemeData theme, bool isDark) {
    return _ModernCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            theme,
            icon: Icons.timeline_rounded,
            title: 'Order Timeline',
            color: AppColors.info,
          ),
          const SizedBox(height: 20),
          _buildTimeline(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildReferralRewardBanner(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF9800).withOpacity(0.15),
            const Color(0xFFFFB74D).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9800), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.2),
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
                colors: [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9800).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Colors.white,
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
                    color: const Color(0xFFFF9800),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This order contains your referral reward. Enjoy your free gift!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme, bool isDark) {
    final steps = _getTimelineSteps();

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        final isCompleted = step.isCompleted;
        final isCurrent = step.isCurrent;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        isCompleted || isCurrent
                            ? step.color
                            : (isDark ? Colors.grey[800] : Colors.grey[200]),
                    shape: BoxShape.circle,
                    boxShadow:
                        isCurrent
                            ? [
                              BoxShadow(
                                color: step.color.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                            : null,
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_rounded
                        : (isCurrent ? step.icon : step.icon),
                    color:
                        isCompleted || isCurrent
                            ? Colors.white
                            : (isDark ? Colors.grey[600] : Colors.grey[400]),
                    size: 16,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color:
                        isCompleted
                            ? step.color.withOpacity(0.5)
                            : (isDark ? Colors.grey[800] : Colors.grey[200]),
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
                    Text(
                      step.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            isCompleted || isCurrent ? null : theme.hintColor,
                      ),
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
        );
      }),
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
            title: 'Items (${_currentOrder.items.length})',
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 16),
          ..._currentOrder.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == _currentOrder.items.length - 1;
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
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.05),
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
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Qty: ${item.quantity}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primaryColor,
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
                        color: AppColors.primaryColor,
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
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.success,
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

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2D2D2D) : Colors.grey[100],
      child: Icon(
        Icons.image_outlined,
        color: isDark ? Colors.white24 : Colors.grey[400],
        size: 24,
      ),
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
            color: AppColors.buttonBackgroundColor,
          ),
          const SizedBox(height: 20),
          _buildPriceRow(theme, 'Subtotal', _currentOrder.subtotal),
          const SizedBox(height: 12),
          _buildPriceRow(
            theme,
            'Discount',
            -_currentOrder.discount,
            isDiscount: true,
          ),
          const SizedBox(height: 12),
          _buildPriceRow(theme, 'Delivery', _currentOrder.deliveryCharges),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.1),
                  AppColors.primaryColor.withOpacity(0.05),
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
                  '₹${_currentOrder.total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
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
                _currentOrder.paymentStatus,
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getPaymentStatusColor(
                  _currentOrder.paymentStatus,
                ).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _currentOrder.paymentStatus == 'PAID'
                      ? Icons.check_circle_rounded
                      : Icons.pending_rounded,
                  color: _getPaymentStatusColor(_currentOrder.paymentStatus),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment ${_currentOrder.paymentStatus}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _getPaymentStatusColor(
                            _currentOrder.paymentStatus,
                          ),
                        ),
                      ),
                      Text(
                        'via ${_currentOrder.paymentMethod}',
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
            color: isDiscount ? AppColors.success : null,
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
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentOrder.deliveryAddress,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_currentOrder.deliveryCity}, ${_currentOrder.deliveryState}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                Text(
                  _currentOrder.deliveryPincode,
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
                      _currentOrder.deliveryPhone,
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
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: AppColors.success,
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
                        _formatDate(_currentOrder.expectedDeliveryDate),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
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
        _currentOrder.status != 'DELIVERED' &&
        _currentOrder.status != 'CANCELLED' &&
        _currentOrder.status != 'SHIPPED';

    return _ModernCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            theme,
            icon: Icons.touch_app_rounded,
            title: 'Quick Actions',
            color: AppColors.warning,
          ),
          const SizedBox(height: 16),
          // Help button
          _buildActionButton(
            theme,
            isDark,
            icon: Icons.support_agent_rounded,
            title: 'Need Help?',
            subtitle: 'Contact support for any issues',
            color: AppColors.info,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => HelpScreen(orderNumber: _currentOrder.orderNumber),
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
            color: AppColors.primaryColor,
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
              color: AppColors.error,
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
          color: color.withOpacity(isDestructive ? 0.08 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
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
            color: color.withOpacity(0.1),
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
      backgroundColor: const Color(0xFF25D366),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.chat_rounded),
      label: const Text('Chat Support'),
      onPressed: () async {
        HapticFeedback.lightImpact();
        final user = AuthService().currentUser;
        const phone = '919518095953';
        final message = Uri.encodeComponent(
          'Hi! I need help with my order.\n\n'
          'Order #${_currentOrder.orderNumber}\n'
          'Status: ${_currentOrder.status}\n'
          'Amount: ₹${_currentOrder.total}\n\n'
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
    final status = _currentOrder.status.toUpperCase();
    final steps = <_TimelineStep>[];

    // Order Placed - always completed
    steps.add(
      _TimelineStep(
        title: 'Order Placed',
        subtitle: _formatShortDate(_currentOrder.createdAt),
        icon: Icons.check_circle_outline,
        color: AppColors.success,
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
        color: AppColors.info,
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
        color: AppColors.warning,
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
                ? _formatShortDate(_currentOrder.updatedAt)
                : 'Expected: ${DateFormat('MMM d').format(_currentOrder.expectedDeliveryDate)}',
        icon: Icons.home_outlined,
        color: AppColors.success,
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
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
          label: 'Delivered',
        );
      case 'CANCELLED':
        return _StatusInfo(
          color: AppColors.error,
          icon: Icons.cancel_rounded,
          label: 'Cancelled',
        );
      case 'SHIPPED':
        return _StatusInfo(
          color: AppColors.info,
          icon: Icons.local_shipping_rounded,
          label: 'Shipped',
        );
      case 'OUT_FOR_DELIVERY':
        return _StatusInfo(
          color: AppColors.warning,
          icon: Icons.delivery_dining_rounded,
          label: 'Out for Delivery',
        );
      case 'PLACED':
      default:
        return _StatusInfo(
          color: AppColors.primaryColor,
          icon: Icons.pending_rounded,
          label: 'Order Placed',
        );
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'FAILED':
        return AppColors.error;
      default:
        return Colors.grey;
    }
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
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
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
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.warning_rounded,
              color: AppColors.error,
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
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Yes, Cancel'),
        ),
      ],
    );
  }
}
