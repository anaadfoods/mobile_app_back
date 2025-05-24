import 'package:flutter/material.dart';
import 'package:grocery_app/models/subscription_model.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail_single.dart';
import 'package:grocery_app/screens/subscription/subscription_detail_screen.dart';
import 'package:grocery_app/services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  List<Subscription> allSubscriptions = [];
  List<Subscription> filteredSubscriptions = [];
  String currentFilter = "All";

  final SubscriptionService _subscriptionService = SubscriptionService();

  Future<void> _fetchSubscriptions() async {
    try {
      final response = await _subscriptionService.getSubscriptions();
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        setState(() {
          allSubscriptions = data.map((item) => item as Subscription).toList();
          _filterSubscriptions(currentFilter);
        });
      } else {
        print('Error fetching subscriptions: ${response['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Failed to fetch subscriptions',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error fetching subscriptions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while fetching subscriptions'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch subscriptions immediately when the page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSubscriptions();
    });
  }

  void _filterSubscriptions(String status) {
    setState(() {
      currentFilter = status;
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
      case "ACTIVE":
        return Colors.green;
      case "PAUSED":
        return Colors.orange;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _togglePauseSubscription(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    // Implementation of _togglePauseSubscription method
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text("My Subscriptions"),
          actions: [
            IconButton(
              onPressed: _fetchSubscriptions,
              icon: Icon(Icons.refresh_sharp),
            ),
          ],
          bottom: TabBar(
            onTap: (index) {
              if (index == 0) _filterSubscriptions("All");
              if (index == 1) _filterSubscriptions("ACTIVE");
              if (index == 2) _filterSubscriptions("PAUSED");
              if (index == 3) _filterSubscriptions("CANCELLED");
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
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SubscriptionPlanDetailScreen(
                        subscription: subscription,
                      ),
                ),
              );
            },
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
                    "Items: ${subscription.items.map((item) => '${item.quantity}x Product ${item.productVariant}').join(', ')}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Next Delivery: ${subscription.startDate.toString().split(' ')[0]}",
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "End Date: ${subscription.endDate.toString().split(' ')[0]}",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
