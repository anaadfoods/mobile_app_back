import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/subscription_plan_model.dart';

class OrderSummaryCard extends StatelessWidget {
  final bool isSubscription;
  final CartModel? cart;
  final Product? singleProduct;
  final int? quantity;
  final double? price;
  final SubscriptionPlan? subscription;
  final String totalPrice;
  final double currentDeliveryCharge;

  const OrderSummaryCard({
    super.key,
    required this.isSubscription,
    required this.cart,
    required this.singleProduct,
    required this.quantity,
    required this.price,
    required this.subscription,
    required this.totalPrice,
    required this.currentDeliveryCharge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.harvestAmber,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isSubscription ? 'Subscription Summary' : 'Order Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (isSubscription && subscription != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.deepSoilGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.deepSoilGreen),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.autorenew_rounded,
                    color: AppColors.parchment,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Products delivered every month',
                      style: TextStyle(
                        color: AppColors.parchment,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (singleProduct != null)
            _buildProductItem(
              theme,
              isDark,
              singleProduct!,
              quantity!,
              isSubscription ? price! : singleProduct!.finalPrice,
            )
          else if (cart != null)
            ...cart!.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildProductItem(
                  theme,
                  isDark,
                  item.productVariant,
                  item.quantity,
                  item.productVariant.finalPrice,
                ),
              ),
            ),
          const Divider(height: 32),
          if (isSubscription && subscription != null) ...[
            _buildPriceRow(
              theme,
              'Unit Price (per item)',
              '₹${(price ?? 0).toStringAsFixed(2)}',
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                'Exclusive discount added',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: AppColors.deepSoilGreen,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              theme,
              'Quantity (per month)',
              '× $quantity',
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              theme,
              'Monthly Product Cost',
              '₹${((price ?? 0) * (quantity ?? 1)).toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              theme,
              'Delivery (per month)',
              currentDeliveryCharge > 0
                  ? '₹${currentDeliveryCharge.toStringAsFixed(2)}'
                  : 'FREE',
              isDelivery: true,
            ),
            const SizedBox(height: 8),
          ] else ...[
            _buildPriceRow(
              theme,
              'Subtotal',
              '₹${(double.tryParse(totalPrice) ?? 0.0 - currentDeliveryCharge).toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              theme,
              'Delivery Charges',
              currentDeliveryCharge > 0
                  ? '₹${currentDeliveryCharge.toStringAsFixed(2)}'
                  : 'FREE',
              isDelivery: true,
            ),
          ],
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSubscription ? 'Monthly Total' : 'Total Amount',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isSubscription && subscription != null)
                    Text(
                      'Billed each month',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              Text(
                '₹${(double.tryParse(totalPrice) ?? 0.0).toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.harvestAmber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (isSubscription && subscription != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.deepSoilGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.deepSoilGreen),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.savings_rounded,
                    color: AppColors.harvestAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Total over ${subscription!.durationMonths} months: ₹${((double.tryParse(totalPrice) ?? 0.0) * subscription!.durationMonths).toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.harvestAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductItem(
    ThemeData theme,
    bool isDark,
    Product product,
    int quantity,
    double price,
  ) {
    String? imageUrl =
        product.productImages.isNotEmpty ? product.productImages[0].image : null;

    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isDark ? AppColors.charcoal : AppColors.parchment,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Icon(
                      Icons.shopping_bag_outlined,
                      color: theme.disabledColor,
                    ),
                  )
                : Icon(
                    Icons.shopping_bag_outlined,
                    color: theme.disabledColor,
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.productName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Qty: $quantity',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${price.toStringAsFixed(2)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    ThemeData theme,
    String label,
    String value, {
    bool isDelivery = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDiscount
                ? AppColors.deepSoilGreen
                : isDelivery && value == 'FREE'
                    ? AppColors.deepSoilGreen
                    : null,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
