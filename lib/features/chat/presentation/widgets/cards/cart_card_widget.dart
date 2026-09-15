import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

class CartCardWidget extends StatelessWidget {
  final Map<String, dynamic> cartData;

  const CartCardWidget({super.key, required this.cartData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = cartData['items'] as List<dynamic>? ?? [];
    final total = cartData['total']?.toString() ?? '₹0';
    final itemCount = items.length;

    return Container(
      margin: const EdgeInsets.only(top: 10.0, bottom: 4.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.softCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : AppColors.deepSoilGreen.withValues(alpha: 0.15),
          width: 1,
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
                "Your Cart",
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.charcoal,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (itemCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.harvestAmber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$itemCount item${itemCount > 1 ? 's' : ''}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            _buildEmptyCart(context, isDark)
          else
            _buildCartItems(context, items, total, isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, bool isDark) {
    return Column(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "Your cart is empty",
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.charcoal54,
                fontSize: 13,
              ),
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.harvestAmber,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => context.push('/products'),
            child: const Text(
              "Browse Products",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItems(
    BuildContext context,
    List<dynamic> items,
    String total,
    bool isDark,
  ) {
    return Column(
      children: [
        ...items.take(3).map((item) {
          final name = item['name']?.toString() ?? 'Product';
          final qty = item['quantity']?.toString() ?? '1';
          final price = item['price']?.toString() ?? '₹0';
          final lineTotal = item['line_total']?.toString() ?? price;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : AppColors.deepSoilGreen)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: isDark ? Colors.white38 : AppColors.charcoal54,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.charcoal,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Qty: $qty × $price",
                        style: TextStyle(
                          color: isDark ? Colors.white54 : AppColors.charcoal54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  lineTotal,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.charcoal,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
        if (items.length > 3)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              "+ ${items.length - 3} more items",
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.charcoal54,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        Divider(
          color: (isDark ? Colors.white : AppColors.charcoal).withValues(alpha: 0.08),
          height: 24,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total",
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.charcoal,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              total,
              style: const TextStyle(
                color: AppColors.harvestAmber,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isDark ? Colors.white : AppColors.deepSoilGreen,
                  side: BorderSide(
                    color: isDark
                        ? Colors.white30
                        : AppColors.deepSoilGreen.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => context.push('/products'),
                child: const Text(
                  "Continue Shopping",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.harvestAmber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => context.push('/checkout'),
                child: const Text(
                  "Checkout",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
