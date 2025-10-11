import 'package:flutter/material.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/screens/address/address_selection_screen.dart';
import 'package:grocery_app/screens/order/order_detail_screen.dart';
import 'package:grocery_app/screens/order/status_animation.dart';
import 'package:grocery_app/services/order_service.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:intl/intl.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "My Orders",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Error: $error"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOrders,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: orders.isEmpty ? 1 : orders.length + 1,
        itemBuilder: (context, index) {
          if (orders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 50.0),
                child: Text("You have no orders yet."),
              ),
            );
          }

          if (index == orders.length) {
            return const _RaiseIssueCard();
          }

          final order = orders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
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

  ({Color color, IconData icon, String text}) _getStatusProperties() {
    switch (order.status) {
      case "DELIVERED":
        return (
          color: AppColors.orderDelivered,
          icon: Icons.check_circle,
          text: 'Order Delivered'
        );
      case "CANCELLED":
        return (
          color: AppColors.orderCancelled,
          icon: Icons.cancel,
          text: 'Order Cancelled'
        );
      case "PLACED":
      default:
        return (
          color: AppColors.orderPlaced,
          icon: Icons.circle,
          text: 'Order Placed'
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _getStatusProperties();
    final isDelivered = order.status == 'DELIVERED';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
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
                  const Text('Order ID',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text("#${order.orderNumber}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Delivery By $deliveryDate',
                      style: const TextStyle(color: Colors.black, fontSize: 10)),
                  Text(order.paymentStatus,
                      style: const TextStyle(color: Colors.black, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              LiveStatusIcon(icon: status.icon, color: status.color),
              const SizedBox(width: 8),
              Text(status.text,
                  style: TextStyle(
                      color: status.color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onViewDetails,
            child: _ProductDetailsPreview(order: order),
          ),
          const SizedBox(height: 16),
          _buildActionButtons(context, isDelivered),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDelivered) {
    if (isDelivered) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement reorder logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8860B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          TextButton(
            onPressed: onViewDetails,
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
    final items = order.items;

    return Container(
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                '${items.length} item${items.length > 1 ? 's' : ''} ordered',
                style: TextStyle(color: Colors.grey.shade800),
              ),
            ],
          ),
          ListView.builder(
            itemCount: items.length > 2 ? 2 : items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final item = items[index];
              final product = item.productDetails;
              final imageUrl = (product.productImages.isNotEmpty)
                  ? product.productImages[0].image
                  : null;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.grey.shade200,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: (imageUrl != null)
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image, color: Colors.grey),
                              )
                            : const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.productName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  overflow: TextOverflow.ellipsis),
                              maxLines: 2),
                          const SizedBox(height: 4),
                          Text(product.productCategory,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('Qty: ${item.quantity}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              const SizedBox(width: 16),
                              Text("₹${product.finalPrice.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              if (product.discountPercentage > 0)
                                Text(
                                  "₹${product.price.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: 12),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
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
    return TextButton(
      onPressed: onPressed,
      child: const Text(
        'Download Invoice',
        style: TextStyle(
          color: Colors.black,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _RaiseIssueCard extends StatelessWidget {
  const _RaiseIssueCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Have an issue with the delivery or items ordered?'),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {},
            child: const Text(
              'Raise an Issue Here',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
