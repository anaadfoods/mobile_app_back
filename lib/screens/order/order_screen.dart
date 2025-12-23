import 'package:grocery_app/common_widgets/global_import.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final OrderService _orderService = OrderService();
  List<Order> orders = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoading = true;
        error = null;
      });
      final fetchedOrders = await _orderService.getOrders();
      if (!mounted) return;
      setState(() {
        orders = fetchedOrders;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('E, MMMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("My Orders")),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppColors.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error.withOpacity(0.5),
              ),
              const SizedBox(height: AppColors.spacingL),
              Text("Failed to load orders", style: theme.textTheme.titleMedium),
              const SizedBox(height: AppColors.spacingS),
              Text(
                error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppColors.spacingXL),
              ElevatedButton.icon(
                onPressed: _fetchOrders,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppColors.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: theme.disabledColor.withOpacity(0.5),
              ),
              const SizedBox(height: AppColors.spacingL),
              Text("No orders yet", style: theme.textTheme.titleMedium),
              const SizedBox(height: AppColors.spacingS),
              Text(
                "Start shopping to see your orders here",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: theme.colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppColors.spacingL),
        itemCount: orders.length + 1,
        itemBuilder: (context, index) {
          if (index == orders.length) {
            return const _RaiseIssueCard();
          }
          final order = orders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppColors.spacingL),
            child: _OrderCard(
              order: order,
              deliveryDate: _formatDate(order.expectedDeliveryDate),
              onViewDetails: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(order: order),
                  ),
                );
                if (result == true) {
                  await _fetchOrders();
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ShimmerLoading(
            isLoading: true,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(width: 70, height: 70, color: theme.cardColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: theme.cardColor,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 14,
                          color: theme.cardColor,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 50,
                          height: 16,
                          color: theme.cardColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(width: 60, height: 36, color: theme.cardColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final String deliveryDate;
  final VoidCallback onViewDetails;

  const _OrderCard({
    required this.order,
    required this.deliveryDate,
    required this.onViewDetails,
  });

  ({Color color, IconData icon, String text}) _getStatusProperties(
    ThemeData theme,
  ) {
    switch (order.status) {
      case "DELIVERED":
        return (
          color: AppColors.success,
          icon: Icons.check_circle,
          text: 'Order Delivered',
        );
      case "CANCELLED":
        return (
          color: theme.colorScheme.error,
          icon: Icons.cancel,
          text: 'Order Cancelled',
        );
      case "PLACED":
      default:
        return (
          color: theme.colorScheme.primary,
          icon: Icons.circle,
          text: 'Order Placed',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final status = _getStatusProperties(theme);
    final isDelivered = order.status == 'DELIVERED';
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        final orderunique = await OrderService().getOrderById(order.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (builder) {
              return OrderDetailScreen(order: orderunique);
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppColors.spacingL),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppColors.radiusL),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(
                AppColors.shadowOpacityLight,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "#${order.orderNumber}",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Delivery By',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      deliveryDate,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppColors.spacingL),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppColors.spacingM,
                vertical: AppColors.spacingXS,
              ),
              decoration: BoxDecoration(
                color: status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppColors.radiusRound),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LiveStatusIcon(icon: status.icon, color: status.color),
                  const SizedBox(width: AppColors.spacingS),
                  Text(
                    status.text,
                    style: textTheme.labelMedium?.copyWith(
                      color: status.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColors.spacingM),
            _ProductDetailsPreview(order: order),
            const SizedBox(height: AppColors.spacingL),
            _buildActionButtons(context, isDelivered),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDelivered) {
    final theme = Theme.of(context);
    if (isDelivered) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                /* TODO: Implement reorder logic */
              },
              style: theme.elevatedButtonTheme.style,
              child: const Text('Reorder'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _InvoiceLink(onPressed: () {})),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ₹${order.total.toStringAsFixed(2)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () async {
              final orderunique = await OrderService().getOrderById(order.id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (builder) {
                    return OrderDetailScreen(order: orderunique);
                  },
                ),
              );
            },
            child: const Text("View Details"),
          ),
        ],
      );
    }
  }
}

class _ProductDetailsPreview extends StatelessWidget {
  final Order order;
  const _ProductDetailsPreview({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final items = order.items;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppColors.spacingM),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: AppColors.spacingS),
              Text(
                '${items.length} item${items.length > 1 ? 's' : ''} ordered',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spacingS),
          ListView.builder(
            itemCount: items.length > 2 ? 2 : items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final item = items[index];
              final product = item.productDetails;
              final imageUrl =
                  (product.productImages.isNotEmpty)
                      ? product.productImages[0].image
                      : null;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppColors.spacingS,
                ),
                child: Row(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppColors.radiusS),
                        color: theme.cardColor,
                        border: Border.all(
                          color:
                              isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade200,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppColors.radiusS),
                        child:
                            (imageUrl != null)
                                ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Icon(
                                        Icons.image,
                                        color: theme.disabledColor,
                                      ),
                                )
                                : Icon(Icons.image, color: theme.disabledColor),
                      ),
                    ),
                    const SizedBox(width: AppColors.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.productName,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Qty: ${item.quantity} × ₹${product.finalPrice.toStringAsFixed(0)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${(item.quantity * product.finalPrice).toStringAsFixed(0)}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (items.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: AppColors.spacingS),
              child: Text(
                '+${items.length - 2} more item${items.length - 2 > 1 ? 's' : ''}',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InvoiceLink extends StatelessWidget {
  final VoidCallback onPressed;
  const _InvoiceLink({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.textTheme.bodyLarge?.color;
    return TextButton(
      onPressed: onPressed,
      child: Text(
        'Download Invoice',
        style: theme.textTheme.bodyLarge?.copyWith(
          decoration: TextDecoration.underline,
          color: color,
          decorationColor: color,
        ),
      ),
    );
  }
}

class _RaiseIssueCard extends StatelessWidget {
  const _RaiseIssueCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.spacingL),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppColors.spacingM),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppColors.radiusS),
            ),
            child: Icon(
              Icons.help_outline,
              color: theme.colorScheme.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppColors.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Have an issue?',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppColors.spacingXS),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (builder) => HelpScreen()),
                    );
                  },
                  child: Text(
                    'Raise an issue here →',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
