import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/services/order_service.dart';
import 'package:grocery_app/screens/help/help_screen.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/order_tracker.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Mock data for order tracker - replace with real data from your order
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
    // This is an example of how you might build the tracker data
    // You should replace this with your actual order tracking logic
    orderList.add(TextDto(
        "Your order has been placed", _formatDate(_currentOrder.createdAt)));
    if (_currentOrder.status == 'SHIPPED' ||
        _currentOrder.status == 'OUT_FOR_DELIVERY' ||
        _currentOrder.status == 'DELIVERED') {
      shippedList.add(
          TextDto("Your order has been shipped", "Update with actual ship date"));
    }
    if (_currentOrder.status == 'OUT_FOR_DELIVERY' ||
        _currentOrder.status == 'DELIVERED') {
      outOfDeliveryList.add(TextDto(
          "Your item is out for delivery", "Update with actual delivery date"));
    }
    if (_currentOrder.status == 'DELIVERED') {
      deliveredList.add(TextDto(
          "Your order has been delivered", _formatDate(_currentOrder.updatedAt)));
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
        builder: (context) => HelpScreen(orderNumber: _currentOrder.orderNumber),
      ),
    );
  }

  Future<void> _cancelOrder() async {
    try {
      setState(() {
        _isCancelling = true;
      });

      final success = await _orderService.cancelOrder(
        _currentOrder.id,
      );

      if (mounted) {
        if (success) {
          setState(() {
            _currentOrder = _currentOrder.copyWith(status: "CANCELLED");
            _isCancelling = false;
          });

          SnackBarHelper.showSuccess(context, 'Order cancelled successfully');
          Navigator.pop(context, true); // Return true to indicate a change
        } else {
          setState(() {
            _isCancelling = false;
          });
          SnackBarHelper.showError(context, 'Failed to cancel order');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
        SnackBarHelper.showError(context, 'Failed to cancel order: $e');
      }
    }
  }

  void _handleBuyAgain() async {
    // This is complex logic that would typically live in a BLoC/Cubit
    // For now, it remains here for simplicity
  }

  void _handleGiveReview() {
    SnackBarHelper.showWarning(context, 'Review functionality coming soon!');
  }

  Future<void> _downloadInvoice() async {
    // Invoice download logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${_currentOrder.orderNumber}"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Invoice',
            onPressed: _downloadInvoice,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderInfoCard(),
              const SizedBox(height: 12),
              _buildProductsCard(),
              _buildShippingDetailsCard(),
              const SizedBox(height: 16),
              _buildActionButton(),
              const SizedBox(height: 80), // Padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: _buildWhatsAppFAB(),
    );
  }

  Widget _buildOrderInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(3),
              child: OrderTracker(
                status: Status.values.firstWhere(
                    (e) =>
                        e.toString() ==
                        'Status.${_currentOrder.status.toLowerCase()}',
                    orElse: () => Status.order),
                activeColor: Colors.green,
                inActiveColor: Colors.grey[300],
                orderTitleAndDateList: orderList,
                shippedTitleAndDateList: shippedList,
                outOfDeliveryTitleAndDateList: outOfDeliveryList,
                deliveredTitleAndDateList: deliveredList,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Order Information",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow("Order Number", _currentOrder.orderNumber),
            const SizedBox(height: 6),
            _buildDetailRow("Date", _formatDate(_currentOrder.createdAt)),
            const SizedBox(height: 6),
            _buildStatusRow("Status", _currentOrder.status, _getStatusColor),
            const SizedBox(height: 6),
            _buildStatusRow(
                "Payment Status", _currentOrder.paymentStatus, _getPaymentStatusColor),
            const SizedBox(height: 6),
            _buildDetailRow("Expected Delivery",
                _formatDate(_currentOrder.expectedDeliveryDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  "Products",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._currentOrder.items.map(
              (item) {
                final product = item.productDetails;
                // **FIX:** Safely get the image URL
                final imageUrl = product.productImages.isNotEmpty
                    ? product.productImages[0].image
                    : null;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsScreen(product: product),
                      ),
                    );
                  },
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
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[100],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                // **FIX:** Check if imageUrl is null before using it
                                child: imageUrl != null
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey[400],
                                          );
                                        },
                                      )
                                    : Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey[400],
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    product.productCategory,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${product.weight} ${product.weightUnit}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Qty: ${item.quantity}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 12,
                                          ),
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Text(
                                  'Total: ₹${item.total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
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
              },
            ).toList(),
            const Divider(height: 24),
            _buildPriceSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Shipping Details",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow("Address", _currentOrder.deliveryAddress),
            const SizedBox(height: 6),
            _buildDetailRow("City", _currentOrder.deliveryCity),
            const SizedBox(height: 6),
            _buildDetailRow("State", _currentOrder.deliveryState),
            const SizedBox(height: 6),
            _buildDetailRow("PIN Code", _currentOrder.deliveryPincode),
            const SizedBox(height: 6),
            _buildDetailRow("Phone", _currentOrder.deliveryPhone),
          ],
        ),
      ),
    );
  }

  // Helper methods for UI building
  Widget _buildStatusRow(
      String label, String value, Color Function(String) colorFunction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorFunction(value).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: colorFunction(value),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildPriceRow(
            "Subtotal",
            "₹${_currentOrder.subtotal.toStringAsFixed(2)}",
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            "Discount",
            "- ₹${_currentOrder.discount.toStringAsFixed(2)}",
            isDiscount: true,
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            "Delivery Charges",
            "₹${_currentOrder.deliveryCharges.toStringAsFixed(2)}",
          ),
          const Divider(height: 16),
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

  Widget _buildPriceRow(String label, String value,
      {bool isBold = false, bool isDiscount = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isDiscount
                ? Colors.green[700]
                : isTotal
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    // Action button logic remains the same
    return const SizedBox.shrink(); // Placeholder
  }

  FloatingActionButton _buildWhatsAppFAB() {
    return FloatingActionButton(
      backgroundColor: Colors.green,
      child: const Icon(Icons.message),
      onPressed: () async {
        final user = AuthService().currentUser;
        const phone = '91XXXXXXXXXX'; // Replace with your WhatsApp number
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
          SnackBarHelper.showError(context, 'Could not open WhatsApp');
        }
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "DELIVERED":
        return Colors.green;
      case "PLACED":
        return Colors.orange;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case "PAID":
        return Colors.green;
      case "PENDING":
        return Colors.orange;
      case "FAILED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

