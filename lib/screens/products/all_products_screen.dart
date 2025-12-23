import 'package:grocery_app/common_widgets/global_import.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key, this.products});
  final List<Product>? products;

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final CategoryService _productService = CategoryService();
  List<Product> _products = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts(widget.products ?? []);
  }

  Future<void> _loadProducts(List<Product> products) async {
    try {
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('All Products')),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppColors.spacingXL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: AppColors.spacingL),
                      Text(
                        _error!,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
              : _products.isEmpty
              ? Center(
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
                        'No products available',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppColors.spacingS),
                      Text(
                        'Check back later for new products',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(AppColors.spacingL),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: AppColors.spacingM,
                  mainAxisSpacing: AppColors.spacingM,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return GestureDetector(
                    onTap:
                        product.isInStock
                            ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ProductDetailsScreen(
                                        product: product,
                                      ),
                                ),
                              );
                            }
                            : null,
                    child: Opacity(
                      opacity: product.isInStock ? 1.0 : 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(
                            AppColors.radiusL,
                          ),
                          border: Border.all(
                            color:
                                isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(
                                AppColors.shadowOpacityLight,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(AppColors.radiusL),
                                  ),
                                  color:
                                      isDark
                                          ? Colors.grey.shade900
                                          : Colors.grey.shade100,
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(AppColors.radiusL),
                                  ),
                                  child:
                                      product.productImages.isNotEmpty
                                          ? Image.network(
                                            product.productImages[0].image,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Center(
                                                  child: Icon(
                                                    Icons
                                                        .image_not_supported_outlined,
                                                    color: theme.disabledColor,
                                                    size: 40,
                                                  ),
                                                ),
                                          )
                                          : Center(
                                            child: Icon(
                                              Icons.image_outlined,
                                              color: theme.disabledColor,
                                              size: 40,
                                            ),
                                          ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppColors.spacingM),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.productName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppColors.spacingXS),
                                  Text(
                                    '₹${product.price.toStringAsFixed(2)}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
