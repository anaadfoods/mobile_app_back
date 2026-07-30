import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/features/products/presentation/widgets/product_image_zoom_viewer.dart';

class ProductImageCarousel extends StatelessWidget {
  final Product product;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onTriggerHaptic;

  const ProductImageCarousel({
    super.key,
    required this.product,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onTriggerHaptic,
  });

  @override
  Widget build(BuildContext context) {
    final productImages = product.productImages;
    if (productImages.isEmpty) {
      return Container(
        height: 250,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.rawEarth54.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, color: AppColors.rawEarth26, size: 48),
              const SizedBox(height: 8),
              Text(
                'No Images Available',
                style: TextStyle(color: AppColors.rawEarth26, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          width: double.infinity,
          child: PageView.builder(
            controller: pageController,
            itemCount: productImages.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.charcoal.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GestureDetector(
                    onTap: () {
                      onTriggerHaptic();
                      showDialog(
                        context: context,
                        barrierColor: Colors.black.withValues(alpha: 0.96),
                        builder: (context) {
                          return ProductImageZoomViewer(
                            imageUrl: productImages[index].image,
                          );
                        },
                      );
                    },
                    child: CachedNetworkImage(
                      imageUrl: productImages[index].image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.rawEarth12,
                        highlightColor: AppColors.parchment,
                        child: Container(color: AppColors.rawEarth12),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.parchment,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.rawEarth54,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (productImages.length > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(productImages.length, (index) {
              final isActive = currentPage == index;
              return GestureDetector(
                onTap: () {
                  onTriggerHaptic();
                  pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  height: 8.0,
                  width: isActive ? 28.0 : 8.0,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [
                              AppColors.deepSoilGreen,
                              AppColors.deepSoilGreen,
                            ],
                          )
                        : null,
                    color: isActive ? null : AppColors.rawEarth70,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
