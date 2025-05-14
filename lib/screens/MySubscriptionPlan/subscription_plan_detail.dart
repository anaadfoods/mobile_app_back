import 'package:flutter/material.dart';
import 'package:grocery_app/models/subscription_model.dart';
import 'package:grocery_app/screens/subscription/subscription_detail_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  final List<Subscription> allSubscriptions = [
    Subscription(
      id: "001",
      planName: "Natural Basmati Rice Plan",
      quantity: 5,
      nextDeliveryDate: DateTime(2025, 8, 1),
      deliveriesLeft: 3,
      status: "Active",
    ),
    Subscription(
      id: "002",
      planName: "Cold-Pressed Sona Moti Wheat Plan",
      quantity: 10,
      nextDeliveryDate: DateTime(2025, 8, 15),
      deliveriesLeft: 5,
      status: "Paused",
    ),
    Subscription(
      id: "003",
      planName: "Barnyard Millet Plan",
      quantity: 8,
      nextDeliveryDate: DateTime(2025, 7, 20),
      deliveriesLeft: 2,
      status: "Active",
    ),
    Subscription(
      id: "004",
      planName: "Foxtail Millet Plan",
      quantity: 4,
      nextDeliveryDate: DateTime(2025, 7, 30),
      deliveriesLeft: 6,
      status: "Cancelled",
    ),
  ];

  List<Subscription> filteredSubscriptions = [];

  @override
  void initState() {
    super.initState();
    filteredSubscriptions = allSubscriptions;
  }

  void _filterSubscriptions(String status) {
    setState(() {
      if (status == "All") {
        filteredSubscriptions = allSubscriptions;
      } else {
        filteredSubscriptions =
            allSubscriptions
                .where((subscription) => subscription.status == status)
                .toList();
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Active":
        return Colors.green;
      case "Paused":
        return Colors.orange;
      case "Cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text("My Subscriptions"),
          bottom: TabBar(
            onTap: (index) {
              if (index == 0) _filterSubscriptions("All");
              if (index == 1) _filterSubscriptions("Active");
              if (index == 2) _filterSubscriptions("Paused");
              if (index == 3) _filterSubscriptions("Cancelled");
            },
            tabs: [
              Tab(text: "All"),
              Tab(text: "Active"),
              Tab(text: "Paused"),
              Tab(text: "Cancelled"),
            ],
          ),
        ),
        body: _buildSubscriptionList(),
      ),
    );
  }

  Widget _buildSubscriptionList() {
    if (filteredSubscriptions.isEmpty) {
      return Center(child: Text("No matching subscriptions found"));
    }
    return ListView.builder(
      itemCount: filteredSubscriptions.length,
      itemBuilder: (context, index) {
        final subscription = filteredSubscriptions[index];
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(
                color: _getStatusColor(subscription.status),
                width: 8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.planName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Quantity: ${subscription.quantity}",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.blueGrey[900],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Next Delivery: ${subscription.nextDeliveryDate.toLocal().toString().split(' ')[0]}",
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  "Deliveries Left: ${subscription.deliveriesLeft}",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
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
