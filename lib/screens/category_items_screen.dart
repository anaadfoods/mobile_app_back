import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/helpers/animated_transitions.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/services/cart_service.dart';
import 'package:grocery_app/widgets/grocery_item_card_widget.dart';
import 'filter_screen.dart';

class CategoryItemsScreen extends StatefulWidget {
  final String name;
  final List<Product> allProducts;

  const CategoryItemsScreen({super.key, required this.name, required this.allProducts});

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
        child: filteredProducts.isNotEmpty
              ? ListView.builder(
              itemCount: filteredProducts.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return GestureDetector(
                  
                onTap: filteredProducts[index].isInStock ? () => _onProductClicked(filteredProducts[index]) : null,
                child: Opacity(
                  opacity: filteredProducts[index].isInStock ? 1.0 : 0.5,
                  child: GroceryItemCardWidget(item: filteredProducts[index], heroSuffix: "home_screen", onAddToCart: (productVariantId, quantity) => CartService().addToCart(productVariantId, quantity),),

                ),
              );
              },
            )
              : SizedBox(height: 10),
        
      ),
    );
  }
 void _onProductClicked(Product item) {
    Navigator.push(
      context,
      AnimatedTransitions.fadeScale(ProductDetailsScreen(product: item)),
    );
  }
  // void onItemClicked(BuildContext context, Product product) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => ProductDetailsScreen(product: product),
  //     ),
  //   );
  // }
}
