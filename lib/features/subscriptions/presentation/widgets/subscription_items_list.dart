import 'package:flutter/material.dart';
import '../../domain/entities/subscription_entity.dart';

class SubscriptionItemsList extends StatelessWidget {
  final List<SubscriptionItemEntity> items;

  const SubscriptionItemsList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                title: Text(item.productName),
                subtitle: Text('${item.quantity} x ${item.unitWeight} ${item.weightUnit}'),
                trailing: Text('₹${item.discountedPrice}'),
              ),
            );
          },
        ),
      ],
    );
  }
}
