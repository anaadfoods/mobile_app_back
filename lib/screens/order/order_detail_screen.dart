import 'package:grocery_app/common_widgets/global_import.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  bool _isCancelling = false;
  late Order _currentOrder;
  List<TextDto> orderList = [];
  List<TextDto> shippedList = [];
  List<TextDto> outOfDeliveryList = [];
  List<TextDto> deliveredList = [];

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _setupOrderStatusSteps();
  }

  String _formatDate(DateTime date) {
    return DateFormat('E, MMMM d, yyyy').format(date);
  }

  void _setupOrderStatusSteps() {
    orderList.add(
      TextDto(
        "Your order has been placed",
        _formatDate(_currentOrder.createdAt),
      ),
    );
    if (_currentOrder.status == 'SHIPPED' ||
        _currentOrder.status == 'OUT_FOR_DELIVERY' ||
        _currentOrder.status == 'DELIVERED') {
      shippedList.add(
        TextDto("Your order has been shipped", "Update with actual ship date"),
      );
    }
    if (_currentOrder.status == 'OUT_FOR_DELIVERY' ||
        _currentOrder.status == 'DELIVERED') {
      outOfDeliveryList.add(
        TextDto(
          "Your item is out for delivery",
          "Update with actual delivery date",
        ),
      );
    }
    if (_currentOrder.status == 'DELIVERED') {
      deliveredList.add(
        TextDto(
          "Your order has been delivered",
          _formatDate(_currentOrder.updatedAt),
        ),
      );
    }
  }

  void _copyOrderNumber() async {
    await Clipboard.setData(ClipboardData(text: _currentOrder.orderNumber));
    if (!mounted) return;
    SnackBarHelper.showSuccess(context, 'Order number copied to clipboard');
  }

  void _navigateToHelp() {
    _copyOrderNumber();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => HelpScreen(orderNumber: _currentOrder.orderNumber),
      ),
    );
  }

  Future<void> _cancelOrder() async {
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

  void _handleBuyAgain() {}

  void _handleGiveReview() {
    SnackBarHelper.showWarning(context, 'Review functionality coming soon!');
  }

  Future<void> _downloadInvoice() async {
    try {
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${_currentOrder.orderNumber}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_copy),
            tooltip: 'Download Invoice',
            onPressed: _downloadInvoice,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppColors.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderInfoCard(),
            const SizedBox(height: AppColors.spacingL),
            _buildProductsCard(),
            const SizedBox(height: AppColors.spacingL),
            _buildShippingDetailsCard(),
            const SizedBox(height: AppColors.spacingL),
            _buildActionButton(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: _buildWhatsAppFAB(),
    );
  }

  Widget _buildOrderInfoCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppColors.spacingL),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppColors.radiusL),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(AppColors.shadowOpacityLight),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrderTracker(
            status: Status.values.firstWhere(
              (e) =>
                  e.toString() ==
                  'Status.${_currentOrder.status.toLowerCase()}',
              orElse: () => Status.order,
            ),
            activeColor: AppColors.success,
            inActiveColor: theme.disabledColor,
            orderTitleAndDateList: orderList,
            shippedTitleAndDateList: shippedList,
            outOfDeliveryTitleAndDateList: outOfDeliveryList,
            deliveredTitleAndDateList: deliveredList,
          ),
          const SizedBox(height: AppColors.spacingL),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppColors.spacingS),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppColors.radiusS),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppColors.spacingM),
              Text(
                "Order Information",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spacingL),
          _buildDetailRow("Order Number", _currentOrder.orderNumber),
          const SizedBox(height: AppColors.spacingS),
          _buildDetailRow("Date", _formatDate(_currentOrder.createdAt)),
          const SizedBox(height: AppColors.spacingS),
          _buildStatusRow("Status", _currentOrder.status, _getStatusColor),
          const SizedBox(height: AppColors.spacingS),
          _buildStatusRow(
            "Payment Status",
            _currentOrder.paymentStatus,
            _getPaymentStatusColor,
          ),
          const SizedBox(height: AppColors.spacingS),
          _buildDetailRow(
            "Expected Delivery",
            _formatDate(_currentOrder.expectedDeliveryDate),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppColors.spacingL),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppColors.radiusL),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(AppColors.shadowOpacityLight),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppColors.spacingS),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppColors.radiusS),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppColors.spacingM),
              Text(
                "Products",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._currentOrder.items.map((item) {
            final product = item.productDetails;
            final imageUrl =
                product.productImages.isNotEmpty
                    ? product.productImages[0].image
                    : null;
            return GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ProductDetailsScreen(product: product),
                    ),
                  ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppColors.radiusM,
                            ),
                            color:
                                isDark
                                    ? Colors.grey.shade900
                                    : Colors.grey.shade100,
                            border: Border.all(
                              color:
                                  isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppColors.radiusM,
                            ),
                            child:
                                imageUrl != null
                                    ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.image_not_supported_outlined,
                                            color: theme.disabledColor,
                                          ),
                                    )
                                    : Icon(
                                      Icons.image_outlined,
                                      color: theme.disabledColor,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.productName,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                product.productCategory,
                                style: textTheme.bodySmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${product.weight} ${product.weightUnit}',
                                style: textTheme.bodySmall,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    'Qty: ${item.quantity}',
                                    style: textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    "₹${product.finalPrice.toStringAsFixed(2)}",
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (product.discountPercentage > 0)
                                    Text(
                                      "₹${product.price.toStringAsFixed(2)}",
                                      style: textTheme.bodySmall?.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${item.price.toStringAsFixed(2)}',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Total: ₹${item.total.toStringAsFixed(2)}',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (item != _currentOrder.items.last)
                    const Divider(height: 16),
                ],
              ),
            );
          }),
          const Divider(height: AppColors.spacingXL),
          _buildPriceSummary(),
        ],
      ),
    );
  }

  Widget _buildShippingDetailsCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppColors.spacingL),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppColors.radiusL),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(AppColors.shadowOpacityLight),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppColors.spacingS),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppColors.radiusS),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppColors.spacingM),
              Text(
                "Shipping Details",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spacingL),
          _buildDetailRow("Address", _currentOrder.deliveryAddress),
          _buildDetailRow("City", _currentOrder.deliveryCity),
          _buildDetailRow("State", _currentOrder.deliveryState),
          _buildDetailRow("PIN Code", _currentOrder.deliveryPincode),
          _buildDetailRow("Phone", _currentOrder.deliveryPhone),
          const SizedBox(height: AppColors.spacingL),
          const _RaiseIssueCard(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return const SizedBox.shrink();
  }

  FloatingActionButton _buildWhatsAppFAB() {
    return FloatingActionButton(
      backgroundColor: AppColors.success,
      foregroundColor: Colors.white,
      child: const Icon(Icons.message),
      onPressed: () async {
        final user = AuthService().currentUser;
        const phone = '919518095953';
        final message = Uri.encodeComponent(
          'Order Support Request\n'
          'User: ${user?.firstName ?? ''} ${user?.lastName ?? ''}\n'
          'Phone: ${user?.phoneNumber ?? ''}\n'
          'Order Number: ${_currentOrder.orderNumber}\n'
          'Order Status: ${_currentOrder.status}\n'
          'Total: ${_currentOrder.total}',
        );
        final url = 'https://wa.me/$phone?text=$message';
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          } else {
            throw 'Could not launch $url';
          }
        } catch (e) {
          if (!mounted) return;
          SnackBarHelper.showError(context, e.toString());
        }
      },
    );
  }

  Widget _buildStatusRow(
    String label,
    String value,
    Color Function(String) colorFunction,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spacingM,
            vertical: AppColors.spacingXS,
          ),
          decoration: BoxDecoration(
            color: colorFunction(value).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppColors.radiusRound),
          ),
          child: Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorFunction(value),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppColors.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(width: AppColors.spacingL),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppColors.spacingL),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildPriceRow(
            "Subtotal",
            "₹${_currentOrder.subtotal.toStringAsFixed(2)}",
          ),
          const SizedBox(height: AppColors.spacingS),
          _buildPriceRow(
            "Discount",
            "- ₹${_currentOrder.discount.toStringAsFixed(2)}",
            isDiscount: true,
          ),
          const SizedBox(height: AppColors.spacingS),
          _buildPriceRow(
            "Delivery Charges",
            "₹${_currentOrder.deliveryCharges.toStringAsFixed(2)}",
          ),
          Divider(
            height: AppColors.spacingXL,
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
          _buildPriceRow(
            "Total Amount",
            "₹${_currentOrder.total.toStringAsFixed(2)}",
            isBold: true,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    TextStyle? style;
    if (isTotal) {
      style = textTheme.titleLarge;
    } else if (isBold) {
      style = textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold);
    } else {
      style = textTheme.bodyMedium;
    }

    Color valueColor;
    if (isDiscount) {
      valueColor = AppColors.success;
    } else if (isTotal) {
      valueColor = colorScheme.primary;
    } else {
      valueColor = colorScheme.onSurface;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style?.copyWith(color: valueColor)),
        Text(value, style: style?.copyWith(color: valueColor)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    final theme = Theme.of(context);
    switch (status.toUpperCase()) {
      case "DELIVERED":
        return AppColors.success;
      case "PLACED":
        return AppColors.warning;
      case "CANCELLED":
        return theme.colorScheme.error;
      default:
        return theme.disabledColor;
    }
  }

  Color _getPaymentStatusColor(String status) {
    final theme = Theme.of(context);
    switch (status.toUpperCase()) {
      case "PAID":
        return AppColors.success;
      case "PENDING":
        return AppColors.warning;
      case "FAILED":
        return theme.colorScheme.error;
      default:
        return theme.disabledColor;
    }
  }
}

class _RaiseIssueCard extends StatelessWidget {
  const _RaiseIssueCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.spacingL),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppColors.spacingS),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppColors.radiusS),
            ),
            child: Icon(Icons.help_outline, color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: AppColors.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Have an issue?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppColors.spacingXS),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (builder) => HelpScreen()),
                    );
                  },
                  child: Text(
                    'Raise an Issue Here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: theme.colorScheme.primary,
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
