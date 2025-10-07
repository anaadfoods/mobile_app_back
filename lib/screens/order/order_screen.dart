import 'package:flutter/material.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/screens/address/address_selection_screen.dart';
import 'package:grocery_app/screens/order/order_detail_screen.dart';
import 'package:grocery_app/screens/order/status_animation.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/services/order_service.dart';
import 'package:grocery_app/styles/colors.dart';
// Note: You might need to add an intl package for date formatting
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

  // --- LOGIC REMAINS UNCHANGED ---
  Future<void> _fetchOrders() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final fetchedOrders = await _orderService.getOrders();
      setState(() {
        orders = fetchedOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // Helper to format date, you can adjust as needed
  String _formatDate(DateTime date) {
    return DateFormat('E, MMMM d').format(date); // e.g., "Thu, July 24"
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Orders")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Orders")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Error: $error"),
              ElevatedButton(
                onPressed: _fetchOrders,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

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
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          // We add +1 to the item count to accommodate the "Raise an Issue" card at the end
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
            
            // If it's the last item in the list, show the "Raise an Issue" card
            if (index == orders.length) {
              return const _RaiseIssueCard();
            }

            final order = orders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: _OrderCard(
                order: order,
                deliveryDate: _formatDate(order.createdAt),
                onViewDetails: () async {
                  // Navigation logic is preserved
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailScreen(order: order),
                    ),
                  );
                  if (result != null) {
                    await _fetchOrders();
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- NEW UI WIDGETS ---

class _OrderCard extends StatelessWidget {
  final Order order;
  final String deliveryDate;
  final VoidCallback onViewDetails;

  const _OrderCard({
    required this.order,
    required this.deliveryDate,
    required this.onViewDetails,
  });
  
  // Helper to get status properties based on order status
  ({Color color, IconData icon, String text}) _getStatusProperties() {
    switch (order.status) {
      case "DELIVERED":
        return (color: AppColors.orderDelivered, icon: Icons.check_circle, text: 'Order Delivered');
      case "CANCELLED":
         return (color: AppColors.orderCancelled, icon: Icons.cancel, text: 'Order Cancelled');
      case "PLACED":
      default:
        return (color: AppColors.orderPlaced, icon: Icons.circle, text: 'Order Placed');
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
                  const Text('Order ID', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text("#${order.orderNumber}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Text(
                'Delivery By $deliveryDate  •  ${order.paymentStatus}', 
                style: const TextStyle(color: Colors.black, fontSize: 10)
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              LiveStatusIcon(icon: status.icon, color: status.color),
              const SizedBox(width: 8),
              Text(status.text, style: TextStyle(color: status.color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          // NOTE: This part is static as item details are not in the top-level Order model.
          // In a real app, you would pass item details here.
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(order: order),
                ),
              );
            },
            child: _ProductDetailsPreview(itemCount: order.itemsCount , products: order.products)),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddressSelectionScreen(isSubscription: false , cart: null, singleProduct: null, price: null, quantity: null,),
                  ),
                );
               },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8860B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Reorder'),
              
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _InvoiceLink(onPressed: () {/* TODO: Implement Download */})),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text(
            'Total: ₹${order.total}',
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
  final int itemCount;
  final List<OrderProduct> products;

  const _ProductDetailsPreview({required this.itemCount , required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Row(children: [
          Icon(Icons.shopping_bag, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$itemCount item${itemCount > 1 ? 's' : ''} ordered',
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ],),
        ListView.builder(
          itemCount: itemCount > 2 ? 2 : itemCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all( 8.0),
              child: Row(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(  8.0),
                      color: Colors.grey.shade200,
                    ),
                    child:  Image.network(
                      products[index].image ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                       const Icon(Icons.image, color: Colors.grey),
                   ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(products[index].productName, style: const TextStyle(fontWeight: FontWeight.w600, overflow: TextOverflow.clip)),
                        const SizedBox(height: 4),
                        Text(products[index].productDetails!.productCategory , style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text("₹${products[index].productDetails!.finalPrice}", style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                                                        Text("₹${products[index].productDetails!.price}", style: const TextStyle(fontWeight: FontWeight.w600 , decoration: TextDecoration.lineThrough , fontSize: 12)),
                    
                            const SizedBox(width: 16),
                            Text('Qty: ${products[index].quantity}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          ) // Placeholder for product image
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