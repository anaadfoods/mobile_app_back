import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Define a type for our callback function for cleaner code
typedef AddToCartCallback = Future<void> Function(int productVariantId, int quantity);

class GroceryItemCardWidget extends StatefulWidget {
  final Product item;
  final String? heroSuffix;
  final AddToCartCallback onAddToCart; // The callback to execute on tap

  const GroceryItemCardWidget({
    super.key,
    required this.item,
    required this.onAddToCart,
    this.heroSuffix,
  });

  @override
  State<GroceryItemCardWidget> createState() => _GroceryItemCardWidgetState();
}

class _GroceryItemCardWidgetState extends State<GroceryItemCardWidget> {
  final double borderRadius = 16;
  bool _isAddingToCart = false; // State variable to track loading

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),

        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // IMAGE
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  width: 110,
                  height: 110,
                  child: imageWidget(),
                ),
              ),
              // // Bestseller Tag (only show if applicable)
              // if (widget.item.isBestseller) // Assuming your Product model has a boolean field like this
              //   Padding(
              //     padding: const EdgeInsets.all(8.0),
              //     child: Container(
              //       padding:
              //           const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              //       decoration: BoxDecoration(
              //         color: Colors.black.withOpacity(0.7),
              //         borderRadius: BorderRadius.circular(6),
              //       ),
              //       child: const Text(
              //         "Bestseller",
              //         style: TextStyle(
              //           color: Colors.white,
              //           fontSize: 8,
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          ),

          // DETAILS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  AppText(
                    text: widget.item.productName,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),

                  // Category
                  AppText(
                    text: widget.item.productCategory,
                    fontSize: 11,
                    color: Colors.grey,
                  ),

                  const SizedBox(height: 4),

                  // Ratings
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Price + Button
                  Row(
                    children: [
                      Text(
                        "₹${widget.item.price.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.item.price != null)
                        Text(
                          "₹${widget.item.price!.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      const Spacer(),
                      addButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget imageWidget() {
    if (widget.item.productImages.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.item.productImages[0].image,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, url, error) =>
            const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
    } else {
      return const Icon(Icons.image_not_supported, size: 40, color: Colors.grey);
    }
  }

  Widget addButton() {
    return InkWell(
      // Use InkWell for tap feedback
      onTap: _isAddingToCart
          ? null // Disable button while loading
          : () async {
              setState(() {
                _isAddingToCart = true;
              });

              try {
                // Call the function passed from the parent widget.
                // Assuming you add 1 item at a time.
                await widget.onAddToCart(widget.item.id, 1);

                // Show success feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${widget.item.productName} added to cart!"),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
              } catch (e) {
                // Show error feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error: ${e.toString()}"),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                // Ensure the loading state is always reset
                if (mounted) {
                  setState(() {
                    _isAddingToCart = false;
                  });
                }
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bottonBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: _isAddingToCart
            // Show a progress indicator when loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            // Show the "Add" text otherwise
            : const Text(
                "Add",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}