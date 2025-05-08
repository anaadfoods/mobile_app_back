import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/styles/colors.dart';

class GroceryFeaturedItem {
  final String name;
  final String imagePath;

  GroceryFeaturedItem(this.name, this.imagePath);
}

var groceryFeaturedItems = [
  GroceryFeaturedItem("Farmer Cummunity", "assets/images/pulses.png"),
  GroceryFeaturedItem("Consumer Cummunity", "assets/images/rise.png"),
];

class GroceryFeaturedCard extends StatelessWidget {
  const GroceryFeaturedCard(this.groceryFeaturedItem,
      {this.color = AppColors.primaryColor});

  final GroceryFeaturedItem groceryFeaturedItem;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        height: 100,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
            color: color.withAlpha(100),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color,
            ),),
            
        child: Row(
          children: [
            // Image(
            //   image: AssetImage(groceryFeaturedItem.imagePath),
            // ),
            SizedBox(
              width: 8,
            ),
            AppText(
              text: groceryFeaturedItem.name,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            )
          ],
        ),
      ),
    );
  }
}
