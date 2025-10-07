import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grocery_app/models/grocery_item.dart';
import 'package:grocery_app/screens/category_items_screen.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/services/cart_service.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/widgets/category_item_card_widget.dart';
import 'package:grocery_app/widgets/search_bar_widget.dart';
import 'package:grocery_app/widgets/grocery_item_card_widget.dart';
import 'package:grocery_app/helpers/animated_transitions.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  List<Product> _bestsellers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isConnected = await CategoryService.testConnection();

      if (!isConnected) {
        setState(() {
          _error =
              'Cannot connect to server. Please check your network connection and server status.';
          _isLoading = false;
        });
        return;
      }

      // Load categories and bestsellers in parallel
      final categories = await CategoryService.fetchCategories();
      final bestsellers = await CategoryService.fetchBestsellerProducts();

      setState(() {
        _categories = categories;
        _filteredCategories = categories;
        _bestsellers = bestsellers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories =
            _categories
                .where(
                  (category) =>
                      category.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.arrow_back),
        centerTitle: false,
        title: Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _loadData)],
      ),
      body: SafeArea(
        child:  Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchBarWidget(
                hintText: 'Search',
                onChanged: _filterCategories,
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
    );
  }

  Widget _buildBody() {

    return SingleChildScrollView(
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories Section
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Categories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          if (_filteredCategories.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No matching categories found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            _buildCategoryGrid(),
          // Bestsellers Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10 , vertical: 5),
            child: Text(
              _bestsellers.isNotEmpty ? 'Trending Products' : '',
              style: TextStyle(
                fontSize: _bestsellers.isNotEmpty ? 16 : 0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary
              ),
            ),
          ),

          _bestsellers.isNotEmpty
              ? ListView.builder(
              itemCount: _bestsellers.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return GestureDetector(

                onTap: _bestsellers[index].isInStock ? () => _onProductClicked(_bestsellers[index]) : null,
                child: Opacity(
                  opacity: _bestsellers[index].isInStock ? 1.0 : 0.5,
                                    child: GroceryItemCardWidget(item: _bestsellers[index], heroSuffix: "home_screen", onAddToCart: (productVariantId, quantity) => CartService().addToCart(productVariantId, quantity),),

                ),
              );
              },
            )
              : SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          // childAspectRatio: 0,
        ),
        itemCount: _filteredCategories.length,
        itemBuilder: (context, index) {
          final category = _filteredCategories[index];
          return GestureDetector(
            onTap:
                category.isActive
                    ? () => _onCategoryItemClicked(context, category)
                    : null,
            child: Opacity(
              opacity: category.isActive ? 1.0 : 0.5,
              child: _buildCachedCategoryCard(category),
            ),
          );
        },
      ),
    );
  }

 void _onProductClicked(Product item) {
    Navigator.push(
      context,
      AnimatedTransitions.fadeScale(ProductDetailsScreen(product: item)),
    );
  }



Widget _buildCachedCategoryCard(Category category) {
  return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child:
               Container(
    decoration: BoxDecoration(
      border: Border.all(
        color: AppColors.bottonBackgroundColor,
        width: 2
      )
    ),
    child: CachedNetworkImage(
                imageUrl: category.image,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
    
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[400]!,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[400],
                    size: 40,
                  ),
                ),
                memCacheWidth: 150,
                memCacheHeight: 150,
                maxWidthDiskCache: 150,
                maxHeightDiskCache: 150,
              ),),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: Colors.white,
                child: Center(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      
  );}



  void _onCategoryItemClicked(BuildContext context, Category category) async {
    final products = await CategoryService.fetchProductsByCategory(
      category.name,
    );

    Navigator.of(context).push(
      AnimatedTransitions.slideFromRight(
        CategoryItemsScreen(name: category.name, allProducts: products),
      ),
    );
  }
}
