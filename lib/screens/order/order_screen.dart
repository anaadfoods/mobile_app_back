
import 'package:flutter/material.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/screens/order/order_detail_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with SingleTickerProviderStateMixin {
  final List<Order> orders = [
    Order(
      id: "1234",
      date: DateTime.now().subtract(Duration(days: 1)),
      status: "In Progress",
      total: 59.99,
      items: ["Apples", "Bananas", "Milk"],
    ),
    Order(
      id: "1235",
      date: DateTime.now().subtract(Duration(days: 3)),
      status: "In Progress",
      total: 32.50,
      items: ["Bread", "Cheese"],
    ),
    Order(
      id: "1236",
      date: DateTime.now().subtract(Duration(days: 5)),
      status: "Cancelled",
      total: 20.00,
      items: ["Juice", "Eggs"],
    ),
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case "Delivered":
        return Colors.green;
      case "In Progress":
        return Colors.orange;
      case "Cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Order> _filterOrders(String status) {
    return orders.where((order) => order.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("My Orders"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Delivered"),
              Tab(text: "In Progress"),
              Tab(text: "Cancelled"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList("Delivered"),
            _buildOrderList("In Progress"),
            _buildOrderList("Cancelled"),
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
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final order = filtered[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                      "Order #${order.id}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.status,
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  "Date: ${order.date.toLocal().toString().split(' ')[0]}",
                  style: TextStyle(color: Colors.grey[700]),
                ),
                SizedBox(height: 4),
                Text(
                  "Total: \$${order.total.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: -8,
                  children: order.items
                      .map((item) => Chip(
                            label: Text(item),
                            backgroundColor: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ))
                      .toList(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailScreen(order: order),
                        ),
                      );
                    },
                    icon: Icon(Icons.arrow_forward_ios, size: 16),
                    label: Text("View Details"),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

