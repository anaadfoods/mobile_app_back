import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

/// Renders the visual Order Status Stepper Card matching the mockup design.
class OrderStatusCardWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderStatusCardWidget({Key? key, required this.orderData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawOrderId = orderData['order_id'] ?? orderData['id'];
    final rawOrderNum = orderData['order_number']?.toString();
    final targetRouteParam =
        (rawOrderId != null && rawOrderId.toString().isNotEmpty)
            ? rawOrderId.toString()
            : (rawOrderNum != null && rawOrderNum.isNotEmpty
                ? rawOrderNum
                : 'latest');
    final orderNumber =
        rawOrderNum ??
        (rawOrderId != null ? 'ORD-$rawOrderId' : 'ORD-9823');
    final expectedDelivery =
        orderData['expected_delivery']?.toString() ?? 'Aug 9';
    final currentStep =
        (orderData['current_step'] as int?) ??
        3; // 1=Placed, 2=Shipped, 3=Out for delivery, 4=Delivered

    final steps = [
      {"label": "Placed", "step": 1},
      {"label": "Shipped", "step": 2},
      {"label": "Out for delivery", "step": 3},
      {"label": "Delivered", "step": 4},
    ];

    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.softCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : AppColors.deepSoilGreen.withValues(alpha: 0.15),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Order $orderNumber",
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.charcoal,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () => context.push('/order/$targetRouteParam'),
                child: const Row(
                  children: [
                    Text(
                      "Details",
                      style: TextStyle(
                        color: AppColors.harvestAmber,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: AppColors.harvestAmber,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Stepper Timeline Line & Nodes ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final stepNum = steps[index]["step"] as int;
              final isDone = stepNum < currentStep;
              final isCurrent = stepNum == currentStep;
              final label = steps[index]["label"] as String;
              final inactiveColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (index > 0)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isDone ? AppColors.successGreen : inactiveColor,
                            ),
                          ),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? AppColors.successGreen
                                : (isCurrent
                                    ? AppColors.harvestAmber
                                    : inactiveColor),
                          ),
                          child: Center(
                            child: Icon(
                              isDone
                                  ? Icons.check
                                  : (isCurrent
                                      ? Icons.circle
                                      : Icons.radio_button_unchecked),
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (index < steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isDone ? AppColors.successGreen : inactiveColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDone || isCurrent
                            ? (isDark ? Colors.white : AppColors.charcoal)
                            : (isDark ? Colors.white54 : AppColors.charcoal54),
                        fontSize: 10,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            "Expected delivery: $expectedDelivery",
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.charcoal70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
