import 'package:flutter/material.dart';
import 'package:grocery_app/models/order_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(title: Text("Order #${order.id}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("Date", order.date.toLocal().toString().split(" ")[0]),
            SizedBox(height: 8),
            _buildDetailRow(
              "Status",
              order.status,
              trailingColor: _getStatusColor(order.status),
            ),
            SizedBox(height: 8),
            _buildDetailRow("Total", "\$${order.total.toStringAsFixed(2)}"),
            SizedBox(height: 16),
            Text(
              "Items",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            ...order.items.map(
              (item) => Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text("1"),
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                  ),
                  title: Text(item),
                  subtitle: Text("1 Kg"),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
              ),
            ),
           
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? trailingColor}) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: trailingColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
