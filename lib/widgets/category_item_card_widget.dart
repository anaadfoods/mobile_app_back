import 'package:flutter/material.dart';
import 'package:grocery_app/models/category_item.dart';
import 'package:grocery_app/models/category_model.dart';

class CategoryItemCardWidget extends StatelessWidget {
  CategoryItemCardWidget({
    super.key,
    required this.item,
    this.color = Colors.blue,
  });

  final Category item;
  final double height = 120.0;
  final double width = 140.0;
  final Color color;
  final double borderRadius = 18;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withOpacity(0.7),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          SizedBox(
            height: 50,
            width: 50,
            child: imageWidget(),
          ),
          const SizedBox(height: 10),
          // Name
          Flexible(
            child: Text(
              item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget imageWidget() {
    return Image.asset(
      item.image,
      fit: BoxFit.contain,
    );
  }
}
