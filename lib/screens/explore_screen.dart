import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grocery_app/screens/category_items_screen.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/widgets/category_item_card_widget.dart';
import 'package:grocery_app/widgets/search_bar_widget.dart';
import 'package:grocery_app/widgets/grocery_item_card_widget.dart';

class ExploreScreen extends StatefulWidget {
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
        title: Text("Explore", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _loadData)],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: SearchBarWidget(
                hintText: 'Search Categories...',
                onChanged: _filterCategories,
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: Icon(Icons.refresh),
                label: Text('Refresh Page'),
              ),
            ],
          ),
        ),
      );
    }

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
          // Bestsellers Sectionif (_bestsellers.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.all(16),
            child:
                 Text(
                  _bestsellers.isNotEmpty
                    ?
                      'Trending Products'
                      :
                      '',
                      style: TextStyle(
                        fontSize: _bestsellers.isNotEmpty
                            ? 20
                            : 0,
                        fontWeight: FontWeight.bold,
                      ),
                    )
          ),

          _bestsellers.isNotEmpty
              ? SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  itemCount: _bestsellers.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => ProductDetailsScreen(
                                  product: _bestsellers[index],
                                ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: GroceryItemCardWidget(
                          item: _bestsellers[index],
                          heroSuffix: 'bestseller',
                        ),
                      ),
                    );
                  },
                ),
              )
              : SizedBox(height: 20),
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
          childAspectRatio: 0.75,
        ),
        itemCount: _filteredCategories.length,
        itemBuilder: (context, index) {
          final category = _filteredCategories[index];
          return GestureDetector(
            onTap: () => _onCategoryItemClicked(context, category),
            child: CategoryItemCardWidget(item: category),
          );
        },
      ),
    );
  }

  void _onCategoryItemClicked(BuildContext context, Category category) async {
    final products = await CategoryService.fetchProductsByCategory(
      category.name,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                CategoryItemsScreen(name: category.name, allProducts: products),
      ),
    );
  }
}
