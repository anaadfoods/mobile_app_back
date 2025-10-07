
// import 'package:flutter/material.dart';
// import 'package:grocery_app/common_widgets/app_text.dart';
// import 'package:grocery_app/styles/colors.dart';

// class GroceryFeaturedItem {
//   final String name;
//   final String imagePath;
//   final String description;

//   GroceryFeaturedItem(this.name, this.imagePath, this.description);
// }

// var groceryFeaturedItems = [
//   GroceryFeaturedItem(
//     "Grinity",
//     "assets/images/grocery_images/apple.png",
//     "Grahak community",
//   ),
//   GroceryFeaturedItem(
//     "Krinity",
//     "assets/images/grocery_images/apple.png",
//     "Krishi community",
//   ),
// ];

// class GroceryFeaturedCard extends StatelessWidget {
//   const GroceryFeaturedCard(
//     this.groceryFeaturedItem, {super.key, 
//     this.color = AppColors.primaryColor,
//   });

//   final GroceryFeaturedItem groceryFeaturedItem;
//   final Color color;

//   @override
//   Widget build(BuildContext context) {
//     return Flexible(
//       child: Container(
//         height: 100,
//         padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
//         decoration: BoxDecoration(
//           color: color.withAlpha(100),
//           borderRadius: BorderRadius.circular(18),
//           border: Border.all(color: color),
//         ),

//         child: Row(
//           children: [
//             // Image(
//             //   image: AssetImage(groceryFeaturedItem.imagePath),
//             // ),
//             SizedBox(width: 8),
//             AppText(
//               text: groceryFeaturedItem.name,
//               fontSize: 20,
//               fontWeight: FontWeight.w600,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
