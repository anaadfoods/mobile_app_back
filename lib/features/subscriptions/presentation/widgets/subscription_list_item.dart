import 'package:flutter/material.dart';
import '../../domain/entities/subscription_entity.dart';
import 'package:grocery_app/styles/colors.dart';

class SubscriptionListItem extends StatelessWidget {
  final SubscriptionEntity subscription;
  final VoidCallback onTap;

  const SubscriptionListItem({
    super.key,
    required this.subscription,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(subscription.planName),
        subtitle: Text('Status: ${subscription.status}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
