
import 'dart:convert';
import 'package:grocery_app/models/category_model.dart';
import 'package:http/http.dart' as http;



Future<List<Category>> fetchCategories() async {
  final url = 'http://127.0.0.1:8000/api/products/categories/'; // Replace with your API URL
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    // Parse the JSON data and map to a list of Category objects
    List<dynamic> jsonData = json.decode(response.body);
    return jsonData.map((data) => Category.fromJson(data)).toList();
  } else {
    throw Exception('Failed to load categories');
  }
}

var categoryItemsDemo = fetchCategories();


// var categoryItemsDemo = [
//   CategoryItem(
//     name: "Fresh Fruits & Vegetables",
//     imagePath: "assets/images/categories_images/fruit.png",
//   ),
//   CategoryItem(
//     name: "Cooking Oil",
//     imagePath: "assets/images/categories_images/oil.png",
//   ),
//   CategoryItem(
//     name: "Meat & Fish",
//     imagePath: "assets/images/categories_images/meat.png",
//   ),
//   CategoryItem(
//     name: "Bakery & Snacks",
//     imagePath: "assets/images/categories_images/bakery.png",
//   ),
//   CategoryItem(
//     name: "Dairy & Eggs",
//     imagePath: "assets/images/categories_images/dairy.png",
//   ),
//   CategoryItem(
//     name: "Beverages",
//     imagePath: "assets/images/categories_images/beverages.png",
//   ),
// ];
