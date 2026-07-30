import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:grocery_app/features/products/domain/entities/product_entity.dart';
import 'package:grocery_app/features/products/presentation/widgets/expandable_description.dart';

class ProductDescriptionSection extends StatelessWidget {
  final ProductEntity product;
  final bool isDark;

  const ProductDescriptionSection({
    super.key,
    required this.product,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Description",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.parchment : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          ExpandableDescription(
            text: product.productDescription,
          ),
          if (product.cropCycleId != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final webBaseUrl =
                      dotenv.env['WEB_BASE_URL'] ?? 'https://web.anaadfoods.com';
                  final baseUri = Uri.parse(webBaseUrl);
                  final url = baseUri.replace(
                    path: '/traceability-journey/',
                    queryParameters: {
                      'crop_id': product.cropCycleId!,
                    },
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    SnackBarHelper.showError(
                      context,
                      'Could not launch URL',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Traceability Journey',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
