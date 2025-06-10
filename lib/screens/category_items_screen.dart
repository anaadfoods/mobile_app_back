import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/widgets/grocery_item_card_widget.dart';
import 'filter_screen.dart';

class CategoryItemsScreen extends StatefulWidget {
  final String name;
  final List<Product> allProducts;

  CategoryItemsScreen({Key? key, required this.name, required this.allProducts})
    : super(key: key);

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  late List<Product> filteredProducts;

  @override
  void initState() {
    super.initState();
    filteredProducts = List<Product>.from(widget.allProducts);
  }

  void _sortById() {
    setState(() {
      filteredProducts.sort((a, b) => a.id.compareTo(b.id));
    });
  }

  void _sortByPrice() {
    setState(() {
      filteredProducts.sort((a, b) => a.price.compareTo(b.price));
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            padding: EdgeInsets.only(left: 25),
            child: Icon(Icons.arrow_back_ios, color: Colors.black),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: Colors.black),
            onSelected: (value) {
              if (value == 'id') {
                _sortById();
              } else if (value == 'price') {
                _sortByPrice();
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(value: 'price', child: Text('Sort by Price')),
                ],
          ),
        ],
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: AppText(
            text: widget.name,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: StaggeredGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 3.0,
          crossAxisSpacing: 0.0,
          children:
              filteredProducts.map((product) {
                return GestureDetector(
                  onTap: () {
                    onItemClicked(context, product);
                  },
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: GroceryItemCardWidget(
                      item: product,
                      heroSuffix: "explore_screen",
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  void onItemClicked(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
  }
}
