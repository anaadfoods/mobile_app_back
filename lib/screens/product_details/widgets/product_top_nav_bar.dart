import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:share_plus/share_plus.dart';
import 'package:grocery_app/routes/app_routes.dart';

class ProductTopNavBar extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final bool isLoadingFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTriggerHaptic;

  const ProductTopNavBar({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.isLoadingFavorite,
    required this.onFavoriteToggle,
    required this.onTriggerHaptic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => context.safePop(fallbackLocation: AppRoute.home.path),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.parchment,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? AppColors.parchment : AppColors.pureBlack,
                size: 20,
              ),
            ),
          ),

          // Actions
          Row(
            children: [
              // Share
              Builder(
                builder: (ctx) {
                  return GestureDetector(
                    onTap: () {
                      onTriggerHaptic();
                      final box = ctx.findRenderObject() as RenderBox?;
                      Share.share(
                        'Check out this product: https://anaadfoods.com/product/${product.id}',
                        sharePositionOrigin:
                            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.parchment,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.share_outlined,
                        color: isDark ? AppColors.parchment : AppColors.pureBlack,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              // Favorite
              isLoadingFavorite
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        onTriggerHaptic();
                        onFavoriteToggle();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isFavorite
                              ? AppColors.softRed.withValues(alpha: 0.1)
                              : (isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.pureWhite),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFavorite
                                ? AppColors.softRed.withValues(alpha: 0.3)
                                : AppColors.darkSurface.withValues(
                                    alpha: 0.08,
                                  ),
                          ),
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? AppColors.softRed
                              : (isDark
                                  ? AppColors.parchment
                                  : AppColors.pureBlack),
                          size: 20,
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
