import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/features/products/domain/entities/product_entity.dart';
import 'package:grocery_app/features/products/presentation/cubit/product_cubit.dart';
import 'package:grocery_app/features/products/presentation/cubit/product_state.dart';
import 'package:grocery_app/common_widgets/grocery_item_card_widget.dart';
import 'home_skeletons.dart';

class HomeAllProductsSection extends StatelessWidget {
  const HomeAllProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return const HomeProductSkeleton();
        }

        final List<ProductEntity> productEntities = (state is ProductSuccess) ? state.featuredProducts : [];

        if (productEntities.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'All Products Catalog',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: productEntities.length,
              itemBuilder: (context, index) {
                final product = Product.fromEntity(productEntities[index]);
                return GroceryItemCardWidget(
                  item: product,
                  heroSuffix: 'all_products',
                );
              },
            ),
          ],
        );
      },
    );
  }
}
