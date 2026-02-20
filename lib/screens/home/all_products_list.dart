import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/screens/category_items_screen.dart';
import 'package:grocery_app/screens/home/home_featured_products.dart';

class AllProductsList extends StatefulWidget {
  const AllProductsList({super.key});

  @override
  State<AllProductsList> createState() => _AllProductsListState();
}

class _AllProductsListState extends State<AllProductsList> {
  @override
  void initState() {
    super.initState();
    _fetchAllProducts();
  }

  Future<void> _fetchAllProducts() async {
    // We can use the cubit or directly service if cubit doesn't have "all products" state separate from featured
    // Let's use a local state for simplicity as ProductCubit might be scoped to featured
    // but actually, let's try to find a cleaner way.
    // For now, I'll use a FutureBuilder with the service for "All Products"
    // to keep it isolated and simple.
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

              TextButton(
                onPressed: () async {
                  // Show loading indicator or simple localized feedback?
                  // For now, let's just push and let the screen handle data if we had it,
                  // but CategoryItemsScreen requires data.
                  // We can fetch it here.
                  try {
                    final products = await CategoryService.fetchAllProducts();
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        AnimatedTransitions.fadeScale(
                          CategoryItemsScreen(
                            name: "All Products",
                            allProducts: products,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    // Handle error silently or show snackbar
                    debugPrint("Error fetching all products: $e");
                  }
                },
                child: const Text("See All"),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: FutureBuilder<List<Product>>(
            future: CategoryService.fetchAllProducts(),
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
                      Navigator.push(
                        context,
                        AnimatedTransitions.fadeScale(
                          ProductDetailsScreen(product: product),
                        ),
                      );
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
