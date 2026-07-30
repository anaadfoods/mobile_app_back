import 'package:flutter/material.dart';
import '../../domain/entities/subscription_entity.dart';

class SubscriptionDetailHeader extends StatelessWidget {
  final SubscriptionEntity subscription;

  const SubscriptionDetailHeader({
    super.key,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subscription.planName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Status: ${subscription.status}'),
            Text('Start Date: ${subscription.startDate}'),
            Text('End Date: ${subscription.endDate}'),
            Text('Next Delivery: ${subscription.nextDeliveryDate}'),
            const SizedBox(height: 16),
            const Text('Payment Info', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Method: ${subscription.paymentMethod}'),
            Text('Status: ${subscription.paymentStatus}'),
            if (subscription.installmentInfo != null) ...[
              Text('Installment Status: ${subscription.installmentInfo!.installmentPaymentStatus}'),
              Text('Remaining Installments: ${subscription.installmentInfo!.remainingInstallments}'),
            ],
          ],
        ),
      ),
    );
  }
}
