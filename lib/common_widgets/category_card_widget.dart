import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grocery_app/models/category_model.dart';

class CategoryCardWidget extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const CategoryCardWidget({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: category.isActive ? onTap : null,
      child: Opacity(
        opacity: category.isActive ? 1.0 : 0.5,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // gradient: LinearGradient(
            //   colors: [Color(0xFFFFF3E0), Color(0xFFFFF8E1)],
            //   begin: Alignment.topLeft,
            //   end: Alignment.bottomRight,
            // // ),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.black12,
            //     blurRadius: 4,
            //     offset: Offset(2, 2),
            //   )
            // ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  child: CachedNetworkImage(
                    imageUrl: category.image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
