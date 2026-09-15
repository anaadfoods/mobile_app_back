import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/routes/app_routes.dart';

/// Renders Product Card Grid matching mockup design.
class ProductCardGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  const ProductCardGridWidget({Key? key, required this.products})
    : super(key: key);

  void _onAddToCart(BuildContext context, Map<String, dynamic> p) {
    final dynamic idVal = p['id'] ?? p['variant_id'] ?? p['pk'];
    final int? variantId =
        idVal is int ? idVal : int.tryParse(idVal?.toString() ?? '');
    final String name =
        (p['product_name'] ??
                p['name'] ??
                p['title'] ??
                'Organic Product')
            .toString();
    final double price =
        double.tryParse(
          (p['final_price'] ?? p['price'] ?? p['original_price'] ?? '0')
              .toString(),
        ) ??
        0.0;
    final String weight = (p['weight'] ?? '1').toString();
    final String weightUnit = (p['weight_unit'] ?? 'item').toString();
    final String sku = (p['sku'] ?? 'SKU-${variantId ?? 0}').toString();

    if (variantId != null) {
      final product = Product(
        id: variantId,
        sku: sku,
        weight: weight,
        weightUnit: weightUnit,
        price: price,
        discountPercentage: 0.0,
        finalPrice: price,
        isInStock: true,
        isActive: true,
        productName: name,
        productDescription: '',
        productCategory: (p['category_name'] ?? 'Ayurvedic').toString(),
        productImages: [],
      );

      try {
        context.read<CartCubit>().addItem(product, 1);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.greenAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Added $name to cart',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'VIEW CART',
              textColor: AppColors.harvestAmber,
              onPressed: () {
                context.go(AppRoute.cart.path);
              },
            ),
          ),
        );
      } catch (_) {
        context.go(AppRoute.cart.path);
      }
    } else {
      context.push(AppRoute.allProducts.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
      child: SizedBox(
        height: 155,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final p = products[index];
            final String name =
                (p['product_name'] ??
                        p['name'] ??
                        p['title'] ??
                        'Organic Product')
                    .toString();
            final String price =
                (p['final_price'] ??
                        p['price'] ??
                        p['original_price'] ??
                        '0.00')
                    .toString();
            final String unit =
                (p['weight'] != null && p['weight_unit'] != null
                        ? '${p['weight']} ${p['weight_unit']}'.trim()
                        : (p['unit'] ?? p['weight'] ?? '1 item'))
                    .toString();
            final dynamic variantId = p['id'] ?? p['variant_id'] ?? p['pk'];

            return InkWell(
              onTap: () {
                if (variantId != null) {
                  context.push('/product/$variantId');
                } else {
                  context.push(AppRoute.allProducts.path);
                }
              },
              child: Container(
                width: 155,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.softCream,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon placeholder matching mockup
                    Container(
                      height: 40,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkCanvas : AppColors.harvestAmber)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          name.toLowerCase().contains("ghee")
                              ? Icons.water_drop_outlined
                              : Icons.eco_outlined,
                          color: AppColors.harvestAmber,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.charcoal,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "₹$price • $unit",
                      style: const TextStyle(
                        color: AppColors.harvestAmber,
                        fontSize: 11.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              isDark ? Colors.white : AppColors.deepSoilGreen,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white38
                                : AppColors.deepSoilGreen.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () => _onAddToCart(context, p),
                        child: const Text(
                          "Add to cart",
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
