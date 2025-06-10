import 'package:flutter/material.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/screens/order/order_detail_screen.dart';
import 'package:grocery_app/services/order_service.dart';
import 'package:grocery_app/styles/colors.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
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

  Color _getStatusColor(String status) {
    switch (status) {
      case "DELIVERED":
        return AppColors.orderDelivered;
      case "PLACED":
        return AppColors.orderPlaced;
      case "CANCELLED":
        return AppColors.orderCancelled;
      default:
        return AppColors.orderProcessing;
    }
  }

  List<Order> _filterOrders(String status) {
    return orders.where((order) => order.status == status).toList();
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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Orders"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "DELIVERED"),
              Tab(text: "PLACED"),
              Tab(text: "CANCELLED"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList("DELIVERED"),
            _buildOrderList("PLACED"),
            _buildOrderList("CANCELLED"),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(String status) {
    final filtered = _filterOrders(status);
    if (filtered.isEmpty) {
      return Center(child: Text("No $status orders"));
    }
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final order = filtered[index];
          final statusColor = _getStatusColor(order.status);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: statusColor.withOpacity(0.5), width: 2),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order #${order.orderNumber}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 12,
                      //     vertical: 6,
                      //   ),
                      //   decoration: BoxDecoration(
                      //     color: statusColor.withOpacity(0.1),
                      //     borderRadius: BorderRadius.circular(20),
                      //   ),
                      //   child: Text(
                      //     order.status,
                      //     style: TextStyle(
                      //       color: statusColor,
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Date: ${order.createdAt.toLocal().toString().split(' ')[0]}",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Total: ₹${order.total}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Items: ${order.itemsCount}",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              order.paymentStatus == "PAID"
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          order.paymentStatus,
                          style: TextStyle(
                            color:
                                order.paymentStatus == "PAID"
                                    ? AppColors.success
                                    : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => OrderDetailScreen(order: order),
                          ),
                        );

                        if (result != null && result is Order) {
                          await _fetchOrders();
                        }
                      },
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      label: const Text("View Details"),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
