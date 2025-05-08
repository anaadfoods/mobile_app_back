import 'package:flutter/material.dart';
class OrderScreen extends StatelessWidget {
  final List<Order> orders = [
    Order(
      id: "1234",
      date: DateTime.now().subtract(Duration(days: 1)),
      status: "Delivered",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Orders"),
      ),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text("Order #${order.id}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${order.date.toLocal()}"),
                  Text("Status: ${order.status}",
                      style: TextStyle(color: _getStatusColor(order.status))),
                  Text("Total: \$${order.total}"),
                  Wrap(
                    spacing: 4,
                    children: order.items
                        .map((item) => Chip(label: Text(item)))
                        .toList(),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailScreen(order: order),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  OrderDetailScreen({required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order #${order.id}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date: ${order.date.toLocal()}"),
            Text("Status: ${order.status}"),
            Text("Total: \$${order.total}"),
            SizedBox(height: 20),
            Text("Items:", style: TextStyle(fontWeight: FontWeight.bold)),
            ...order.items.map((item) => ListTile(title: Text(item))).toList(),
            Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                // Logic to reorder
              },
              icon: Icon(Icons.shopping_cart),
              label: Text("Reorder"),
            )
          ],
        ),
      ),
    );
  }
}

class Order {
  final String id;
  final DateTime date;
  final String status;
  final double total;
  final List<String> items;

  Order({
    required this.id,
    required this.date,
    required this.status,
    required this.total,
    required this.items,
  });
}
