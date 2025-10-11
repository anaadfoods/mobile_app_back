import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grocery_app/screens/category_items_screen.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/services/cart_service.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/widgets/search_bar_widget.dart';
import 'package:grocery_app/widgets/grocery_item_card_widget.dart';
import 'package:grocery_app/helpers/animated_transitions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart'; // Import the shimmer package

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // ---------- Simple In-Memory Cache ----------
  static List<Category>? _cachedCategories;
  static List<Product>? _cachedBestsellers;

  // ---------- State Variables ----------
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  List<Product> _bestsellers = [];
  bool _isLoading = true;
  bool _isLoadingBestsellers = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCachedOrFetch();
  }

  // ---------- Initial Loading with Cache ----------
  Future<void> _loadCachedOrFetch() async {
    if (_cachedCategories != null && _cachedBestsellers != null) {
      // Use cached data instantly
      setState(() {
        _categories = _cachedCategories!;
        _filteredCategories = _categories;
        _bestsellers = _cachedBestsellers!;
        _isLoading = false;
      });
    } else if (_cachedCategories != null && _cachedBestsellers == null) {
      // Categories available, load bestsellers in background
      setState(() {
        _categories = _cachedCategories!;
        _filteredCategories = _categories;
        _isLoading = false;
      });
      _loadBestsellersInBackground();
    } else {
      // Full first-time load
      _loadData();
    }
  }

  // ---------- Main Loader (Categories first, then Bestsellers) ----------
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isConnected = await CategoryService.testConnection();
      if (!isConnected) {
        setState(() {
          _error = 'Cannot connect to server. Please check your network.';
          _isLoading = false;
        });
        return;
      }

      // Load categories first
      final categories = await CategoryService.fetchCategories();

      setState(() {
        _categories = categories;
        _filteredCategories = categories;
        _cachedCategories = categories;
        _isLoading = false;
      });

      // Load bestsellers quietly
      _loadBestsellersInBackground();
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  // ---------- Background Bestsellers Loader ----------
  Future<void> _loadBestsellersInBackground() async {
    if (_isLoadingBestsellers || _cachedBestsellers != null) return;

    setState(() => _isLoadingBestsellers = true);

    // Optional small delay for smoother UX
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final bestsellers = await CategoryService.fetchBestsellerProducts();
      setState(() {
        _bestsellers = bestsellers;
        _cachedBestsellers = bestsellers;
      });
    } catch (_) {
      // ignore failure silently, user already sees categories
    } finally {
      if (mounted) {
        setState(() => _isLoadingBestsellers = false);
      }
    }
  }

  // ---------- Search ----------
  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories
            .where((category) =>
                category.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.arrow_back),
        centerTitle: false,
        title: const Text(
          "Category",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Clear cache and reload everything fresh
              _cachedCategories = null;
              _cachedBestsellers = null;
              _loadData();
            },
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildSkeletonLoader() // Use skeleton loader on initial load
            : _error != null
                ? Center(
                    child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ))
                : Column(
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

  // ---------- UI Body ----------
  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- Categories ----------
          const Padding(
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
                children: const [
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

          // ---------- Bestsellers ----------
          if (_bestsellers.isNotEmpty || _isLoadingBestsellers)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Text(
                'Trending Products',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
            ),
          if (_isLoadingBestsellers && _bestsellers.isEmpty)
            _buildBestsellerListSkeleton() // Use skeleton for bestsellers
          else if (_bestsellers.isNotEmpty)
            ListView.builder(
              itemCount: _bestsellers.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = _bestsellers[index];
                return GestureDetector(
                  onTap: item.isInStock ? () => _onProductClicked(item) : null,
                  child: Opacity(
                    opacity: item.isInStock ? 1.0 : 0.5,
                    child: GroceryItemCardWidget(
                      item: item,
                      heroSuffix: "home_screen",
                      onAddToCart: (id, q) => CartService().addToCart(id, q),
                    ),
                  ),
                );
              },
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ---------- Category Grid ----------
  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.9, // Adjust aspect ratio for card
        ),
        itemCount: _filteredCategories.length,
        itemBuilder: (context, index) {
          final category = _filteredCategories[index];
          return GestureDetector(
            onTap: category.isActive
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

  // ---------- Cached Category Image Card ----------
  Widget _buildCachedCategoryCard(Category category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.bottonBackgroundColor,
                      width: 2,
                                   )                 ),
                  child: CachedNetworkImage(
                    imageUrl: category.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.image_not_supported,
                          color: Colors.grey[400], size: 40),
                    ),
                    memCacheWidth: 150,
                    memCacheHeight: 150,
                    maxWidthDiskCache: 150,
                    maxHeightDiskCache: 150,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: Colors.white,
                  child: Center(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  // ---------- Navigation ----------
  void _onProductClicked(Product item) {
    Navigator.push(
      context,
      AnimatedTransitions.fadeScale(ProductDetailsScreen(product: item)),
    );
  }

  void _onCategoryItemClicked(BuildContext context, Category category) async {
    final products =
        await CategoryService.fetchProductsByCategory(category.name);

    Navigator.of(context).push(
      AnimatedTransitions.slideFromRight(
        CategoryItemsScreen(name: category.name, allProducts: products),
      ),
    );
  }

  // ---------- SKELETON WIDGETS ----------

  /// A reusable box for skeleton placeholders.
  Widget _skeletonBox({
    double? width,
    double? height,
    double radius = 8.0,
    EdgeInsetsGeometry margin = EdgeInsets.zero,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  /// The main skeleton loader for the entire screen.
  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar Skeleton
            _skeletonBox(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            // "Categories" Title Skeleton
            _skeletonBox(
              width: 150,
              height: 24,
              margin: const EdgeInsets.all(16),
            ),
            // Category Grid Skeleton
            _buildCategoryGridSkeleton(),
            // "Trending Products" Title Skeleton
            _skeletonBox(
              width: 200,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            // Bestseller List Skeleton
            _buildBestsellerListSkeleton(),
          ],
        ),
      ),
    );
  }

  /// Builds a skeleton placeholder for the category grid.
  Widget _buildCategoryGridSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.9,
        ),
        itemCount: 4, // Display 4 placeholder items
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: _skeletonBox()),
              const SizedBox(height: 8),
              Expanded(flex: 1, child: _skeletonBox()),
            ],
          );
        },
      ),
    );
  }

  /// Builds a skeleton placeholder for the bestseller list.
  Widget _buildBestsellerListSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 3, // Display 3 placeholder items
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _skeletonBox(width: 80, height: 80),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _skeletonBox(height: 20),
                      const SizedBox(height: 8),
                      _skeletonBox(height: 16, width: 100),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _skeletonBox(height: 20, width: 60),
                          _skeletonBox(height: 30, width: 30, radius: 15),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}