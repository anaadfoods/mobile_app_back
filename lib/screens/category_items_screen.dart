import 'package:grocery_app/common_widgets/global_import.dart';

class CategoryItemsScreen extends StatefulWidget {
  final String name;
  final List<Product> allProducts;

  const CategoryItemsScreen({
    super.key,
    required this.name,
    required this.allProducts,
  });

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  late List<Product> filteredProducts;

  @override
  void initState() {
    super.initState();
    filteredProducts = List<Product>.from(widget.allProducts);
  }

  void _sortById() {
    setState(() {
      filteredProducts.sort((a, b) => a.id.compareTo(b.id));
    });
  }

  void _sortByPrice() {
    setState(() {
      filteredProducts.sort((a, b) => a.price.compareTo(b.price));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: AppText(text: widget.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'id') {
                _sortById();
              } else if (value == 'price') {
                _sortByPrice();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'price',
                    child: Text('Sort by Price'),
                  ),
                ],
          ),
        ],
      ),
      body:
          filteredProducts.isNotEmpty
              ? ListView.builder(
                padding: const EdgeInsets.all(AppColors.spacingL),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppColors.spacingM),
                    child: Opacity(
                      opacity: filteredProducts[index].isInStock ? 1.0 : 0.5,
                      child: GroceryItemCardWidget(
                        item: filteredProducts[index],
                        heroSuffix: "home_screen",
                        onTap:
                            filteredProducts[index].isInStock
                                ? () =>
                                    _onProductClicked(filteredProducts[index])
                                : null,
                      ),
                    ),
                  );
                },
              )
              : Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppColors.spacingXL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: theme.disabledColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: AppColors.spacingL),
                      Text(
                        'No products found',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppColors.spacingS),
                      Text(
                        'Check back later for new items',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  void _onProductClicked(Product item) {
    Navigator.push(
      context,
      AnimatedTransitions.fadeScale(ProductDetailsScreen(product: item)),
    );
  }
}

