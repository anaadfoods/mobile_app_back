import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grocery_app/screens/category_items_screen.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/widgets/category_item_card_widget.dart';
import 'package:grocery_app/widgets/search_bar_widget.dart';

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
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

      final categories = await CategoryService.fetchCategories();

      setState(() {
        _categories = categories;
        _filteredCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading categories: $e';
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
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadCategories),
        ],
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
                onPressed: _loadCategories,
                icon: Icon(Icons.refresh),
                label: Text('Retry Connection'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredCategories.isEmpty) {
      return Center(
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
      );
    }

    return _buildCategoryGrid();
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
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
