import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/features/products/domain/entities/product_entity.dart';
import 'package:grocery_app/features/products/presentation/cubit/product_cubit.dart';
import 'package:grocery_app/features/products/presentation/cubit/product_state.dart';
import 'package:grocery_app/common_widgets/grocery_item_card_widget.dart';
import 'package:grocery_app/common_widgets/anaad_section_header.dart';
import 'home_skeletons.dart';

class HomeFeaturedSection extends StatelessWidget {
  final String title;
  final bool isBestseller;

  const HomeFeaturedSection({
    super.key,
    required this.title,
    this.isBestseller = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return const HomeProductSkeleton();
        }

        final List<ProductEntity> productEntities =
            (state is ProductSuccess)
                ? (isBestseller
                    ? state.bestsellerProducts
                    : state.featuredProducts)
                : [];

        if (productEntities.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnaadSectionHeader(
              title: title,
              actionLabel: 'See all',
              onAction: () => context.push('/products'),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            ),
            SizedBox(
              height: 230,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: productEntities.length,
                itemBuilder: (context, index) {
                  final product = Product.fromEntity(productEntities[index]);
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: GroceryItemCardWidget(
                      item: product,
                      heroSuffix: isBestseller ? 'bestseller' : 'featured',
                    ),
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
