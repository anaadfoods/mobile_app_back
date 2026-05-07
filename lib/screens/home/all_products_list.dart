import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/routes/app_routes.dart';
import 'package:grocery_app/screens/home/home_featured_products.dart';

class AllProductsList extends StatefulWidget {
  const AllProductsList({super.key});

  @override
  State<AllProductsList> createState() => _AllProductsListState();
}

class _AllProductsListState extends State<AllProductsList> {
  // Cache the future so it doesn't re-fetch on every rebuild
  late final Future<List<Product>> _allProductsFuture;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _allProductsFuture = CategoryService.fetchAllProducts();
  }

  Future<void> _onSeeAll() async {
    HapticFeedback.lightImpact();
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    try {
      final products = await _allProductsFuture;
      if (mounted) {
        context.push(
          AppRoute.categoryItems.path,
          extra: {'name': "All Products", 'products': products},
        );
      }
    } catch (e) {
      debugPrint("Error fetching all products: $e");
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Products",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              GestureDetector(
                onTap: _onSeeAll,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:
                      _isNavigating
                          ? SizedBox(
                            width: 56,
                            height: 16,
                            child: ShimmerLoading(
                              isLoading: true,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          )
                          : Text(
                            "See All →",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: FutureBuilder<List<Product>>(
            future: _allProductsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const FeaturedProductsSkeleton(); // Reuse skeleton
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              final products = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return FeaturedProductCard(
                    product: product,
                    index: index,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                    onTap: () {
                      context.push('/product/${product.id}');
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
