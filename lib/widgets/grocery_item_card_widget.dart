import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GroceryItemCardWidget extends StatelessWidget {
  GroceryItemCardWidget({Key? key, required this.item, this.heroSuffix})
    : super(key: key);
  final Product item;
  final String? heroSuffix;

  final double width = 174;
  final double height = 360;
  final Color borderColor = Color(0xffE2E2E2);
  final double borderRadius = 18;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.grey[100],
                  width: 140,
                  height: 120,
                  child: imageWidget(),
                ),
              ),
            ),
            SizedBox(height: 20),
            AppText(
              text: item.productName,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            AppText(
              text: item.productCategory,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7C7C7C),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                AppText(
                  text: "Rs.${item.price.toStringAsFixed(2)}",
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget imageWidget() {
    if (item.productImages.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.productImages[0].image,
        fit: BoxFit.cover,
        width: 140,
        height: 120,
        placeholder:
            (context, url) => Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                ),
              ),
            ),
        errorWidget:
            (context, url, error) => Container(
              color: Colors.grey[200],
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            ),
        memCacheWidth: 200,
        memCacheHeight: 200,
        maxWidthDiskCache: 200,
        maxHeightDiskCache: 200,
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
      );
    }
  }

  Widget addWidget() {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: AppColors.primaryColor,
      ),
      child: Center(child: Icon(Icons.add, color: Colors.white, size: 25)),
    );
  }
}
