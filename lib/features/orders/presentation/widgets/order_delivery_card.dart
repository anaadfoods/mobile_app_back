import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:grocery_app/features/orders/domain/entities/order_entity.dart';
import 'order_detail_card.dart';

class OrderDeliveryCard extends StatelessWidget {
  final OrderEntity order;

  const OrderDeliveryCard({
    super.key,
    required this.order,
  });

  String _getRecipientName(BuildContext context) {
    if (order.recipientName.isNotEmpty) {
      return order.recipientName;
    }

    final authState = context.read<AuthCubit>().state;
    final user = authState is Authenticated ? authState.user : null;
    if (user != null) {
      final firstName = user.firstName;
      final lastName = user.lastName;
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
    }

    return 'Valued Customer';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return OrderDetailCard(
      icon: Icons.location_on_rounded,
      title: 'Delivery Address',
      color: AppColors.rawEarth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.parchment.withValues(alpha: 0.05)
                  : AppColors.rawEarth54.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getRecipientName(context),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.deliveryAddress,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${order.deliveryCity}, ${order.deliveryState}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                Text(
                  order.deliveryPincode,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: theme.hintColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.deliveryPhone,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Expected delivery
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.harvestAmber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.harvestAmber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.harvestAmber,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected Delivery',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      Text(
                        ApiConfig.showExpectedDeliveryDate
                            ? _formatDate(order.expectedDeliveryDate)
                            : ApiConfig.alternativeDeliveryText,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.harvestAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
