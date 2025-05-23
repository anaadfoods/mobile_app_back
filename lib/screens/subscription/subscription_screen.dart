import 'package:flutter/material.dart';
import 'package:grocery_app/models/subscription_plan_model.dart';
import 'package:grocery_app/widgets/subscription_table.dart';
import 'package:grocery_app/models/subscription_model.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription Plans'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Your Plan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Select a subscription plan that best suits your needs',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SubscriptionTable(
                onPlanSelected: (SubscriptionPlan plan) {
                  // Handle plan selection
                  print('Selected plan: ${plan.name}');
                  // You can navigate to checkout or show more details
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
