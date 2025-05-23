import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/services/order_service.dart';
import 'package:grocery_app/screens/help/help_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  void _copyOrderNumber() async {
    await Clipboard.setData(ClipboardData(text: _currentOrder.orderNumber));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order number copied to clipboard'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      setState(() {
        _isCancelling = true;
      });

      final success = await _orderService.cancelOrder(
        _currentOrder.orderNumber,
      );

      if (mounted) {
        if (success) {
          setState(() {
            _currentOrder = _currentOrder.copyWith(status: "CANCELLED");
            _isCancelling = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order cancelled successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Return updated order status to previous screen
          Navigator.pop(context, _currentOrder);
        } else {
          setState(() {
            _isCancelling = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel order'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildActionButton() {
    if (_currentOrder.status == "CANCELLED") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(Icons.help_outline),
          label: Text('Need Help?'),
          onPressed: _navigateToHelp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    } else if (_currentOrder.canBeCancelled) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isCancelling ? null : _cancelOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          child:
              _isCancelling
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Cancel Order'),
        ),
      );
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${_currentOrder.orderNumber}"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderInfoCard(),
              SizedBox(height: 16),
              _buildProductsCard(),
              if (_currentOrder.shippingDetails != null) ...[
                SizedBox(height: 16),
                _buildShippingDetailsCard(),
              ],
              SizedBox(height: 24),
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order Information",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            _buildDetailRow("Order Number", _currentOrder.orderNumber),
            SizedBox(height: 8),
            _buildDetailRow(
              "Date",
              _currentOrder.createdAt.toLocal().toString().split(" ")[0],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Status",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      _currentOrder.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentOrder.status,
                    style: TextStyle(
                      color: _getStatusColor(_currentOrder.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Payment Status",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(
                      _currentOrder.paymentStatus,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentOrder.paymentStatus,
                    style: TextStyle(
                      color: _getPaymentStatusColor(
                        _currentOrder.paymentStatus,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Products", style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            ..._currentOrder.products
                .map(
                  (product) => Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            product.image != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product.image!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.image, color: Colors.grey),
                                ),
                        title: Text(
                          product.productName,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Quantity: ${product.quantity}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: Text(
                          '₹${product.price}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (product != _currentOrder.products.last)
                        Divider(height: 16),
                    ],
                  ),
                )
                .toList(),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Amount",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  "₹${_currentOrder.total}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingDetailsCard() {
    final details = _currentOrder.shippingDetails!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Shipping Details",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            _buildDetailRow("Address", details.address),
            SizedBox(height: 8),
            _buildDetailRow("City", details.city),
            SizedBox(height: 8),
            _buildDetailRow("State", details.state),
            SizedBox(height: 8),
            _buildDetailRow("PIN Code", details.pincode),
            SizedBox(height: 8),
            _buildDetailRow("Phone", details.phone),
          ],
        ),
      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(value, style: TextStyle(fontSize: 16, color: Colors.black87)),
      ],
    );
  }
}
