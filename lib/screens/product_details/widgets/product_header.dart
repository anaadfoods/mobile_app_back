import 'package:grocery_app/common_widgets/global_import.dart';

class ProductHeader extends StatelessWidget {
  final Product product;

  const ProductHeader({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    double discount = ((product.price - product.finalPrice) / product.price) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        (() {
          final formattedTitle = ProductTitleFormatter.format(
            product.productName,
            product.weight,
            product.weightUnit,
          );
          final variety = formattedTitle['variety'] ?? '';
          final productType = formattedTitle['productType'] ?? '';
          final weight = formattedTitle['weight'] ?? '';
          
          return Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$variety${productType.isNotEmpty ? " — $productType" : ""}\n',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.parchment : AppColors.charcoal,
                    height: 1.3,
                  ),
                ),
                TextSpan(
                  text: weight,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.parchment.withValues(alpha: 0.7)
                        : AppColors.rawEarth54,
                  ),
                ),
              ],
            ),
          );
        })(),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${product.finalPrice.toStringAsFixed(0)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.harvestAmber,
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '₹${product.price.toStringAsFixed(0)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: isDark
                      ? AppColors.parchment.withValues(alpha: 0.5)
                      : AppColors.rawEarth54,
                ),
              ),
            ),
            const Spacer(),
            if (discount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.harvestAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.harvestAmber),
                ),
                child: Text(
                  '${discount.toStringAsFixed(0)}% OFF',
                  style: const TextStyle(
                    color: AppColors.harvestAmber,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class ProductTitleFormatter {
  static Map<String, String> format(String rawName, String rawWeight, String rawUnit) {
    String cleaned = rawName;
    cleaned = cleaned.replaceAll(RegExp(r'\s*-\s*\d+(\.\d+)?\s*(kg|g|l|ml)?\s*$', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*\d+(\.\d+)?\s*(kg|g|l|ml)?\s*$', caseSensitive: false), '');
    cleaned = cleaned.trim();

    String variety = '';
    String productType = '';

    final lowerClean = cleaned.toLowerCase();
    if (lowerClean.startsWith('sona moti')) {
      variety = 'Sona Moti';
      String rest = cleaned.substring('sona moti'.length).trim();
      if (rest.isEmpty || rest.toLowerCase() == 'wheat flour' || rest.toLowerCase() == 'flour') {
        productType = 'Stone-Ground Wheat Flour';
      } else {
        productType = rest;
      }
    } else if (lowerClean.startsWith('desi cow') || lowerClean.startsWith('desi')) {
      variety = lowerClean.startsWith('desi cow') ? 'Desi Cow' : 'Desi';
      String rest = cleaned.substring(variety.length).trim();
      productType = rest;
    } else if (lowerClean.startsWith('a2 cow') || lowerClean.startsWith('a2')) {
      variety = lowerClean.startsWith('a2 cow') ? 'A2 Cow' : 'A2';
      String rest = cleaned.substring(variety.length).trim();
      productType = rest;
    } else {
      if (cleaned.contains(' — ')) {
        final parts = cleaned.split(' — ');
        variety = parts[0].trim();
        productType = parts[1].trim();
      } else if (cleaned.contains(' - ')) {
        final parts = cleaned.split(' - ');
        variety = parts[0].trim();
        productType = parts[1].trim();
      } else {
        final words = cleaned.split(' ');
        if (words.length > 1) {
          variety = words[0];
          productType = words.sublist(1).join(' ');
        } else {
          variety = cleaned;
          productType = '';
        }
      }
    }

    String w = rawWeight.toLowerCase().trim();
    String u = rawUnit.toLowerCase().trim();
    w = w.replaceAll(u, '').trim();
    w = w.replaceAll('kg', '').replaceAll('g', '').replaceAll('ml', '').replaceAll('l', '').trim();

    if (u.isEmpty) {
      if (rawWeight.toLowerCase().contains('kg')) u = 'kg';
      else if (rawWeight.toLowerCase().contains('g')) u = 'g';
      else if (rawWeight.toLowerCase().contains('ml')) u = 'ml';
      else if (rawWeight.toLowerCase().contains('l')) u = 'L';
    }

    if (u == 'kg') u = 'kg';
    else if (u == 'g' || u == 'gm' || u == 'grams') u = 'g';
    else if (u == 'l' || u == 'litre' || u == 'litres') u = 'L';
    else if (u == 'ml') u = 'ml';

    String weightString = '$w $u'.trim();
    if (weightString.isEmpty) {
      weightString = rawWeight;
    }

    return {
      'variety': variety,
      'productType': productType,
      'weight': weightString,
    };
  }
}

