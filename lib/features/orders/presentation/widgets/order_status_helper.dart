import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

class OrderStatusInfo {
  final Color color;
  final IconData icon;
  final String label;

  const OrderStatusInfo({
    required this.color,
    required this.icon,
    required this.label,
  });
}

class OrderStatusHelper {
  static OrderStatusInfo getStatusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return const OrderStatusInfo(
          color: AppColors.deepSoilGreen,
          icon: Icons.check_circle_rounded,
          label: 'Delivered',
        );
      case 'CANCELLED':
        return const OrderStatusInfo(
          color: AppColors.rawEarth,
          icon: Icons.cancel_rounded,
          label: 'Cancelled',
        );
      case 'SHIPPED':
        return const OrderStatusInfo(
          color: AppColors.harvestAmber,
          icon: Icons.local_shipping_rounded,
          label: 'Shipped',
        );
      case 'OUT_FOR_DELIVERY':
        return const OrderStatusInfo(
          color: AppColors.harvestAmber,
          icon: Icons.delivery_dining_rounded,
          label: 'Out for Delivery',
        );
      case 'PLACED':
      default:
        return const OrderStatusInfo(
          color: AppColors.harvestAmber,
          icon: Icons.pending_rounded,
          label: 'Order Placed',
        );
    }
  }
}
