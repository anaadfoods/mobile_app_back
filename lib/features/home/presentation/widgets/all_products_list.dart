import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/models/product_model.dart';
import 'home_featured_products.dart';
import '../../../../features/products/presentation/cubit/product_cubit.dart';
import '../../../../features/products/presentation/cubit/product_state.dart';

class AllProductsList extends StatelessWidget {
  const AllProductsList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        final products = (state is ProductSuccess)
            ? state.featuredProducts.map((e) => Product.fromEntity(e)).toList()
            : <Product>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Farm Offerings",
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/products', extra: products);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "See All",
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.deepSoilGreen
                                  : AppColors.pureBlack,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: isDark
                                ? AppColors.deepSoilGreen
                                : AppColors.pureBlack,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 280,
              child: state is ProductLoading
                  ? const FeaturedProductsSkeleton()
                  : products.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return FeaturedProductCard(
                              product: product,
                              index: index,
                              isDark: isDark,
                              onTap: () {
                                context.push('/product/${product.id}');
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
