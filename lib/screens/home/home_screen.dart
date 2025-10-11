import 'package:flutter/material.dart';

import 'package:grocery_app/helpers/animated_transitions.dart';
import 'package:grocery_app/helpers/skelton.dart';
import 'package:grocery_app/models/cummunity_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/screens/RFP/contract_farming_screen.dart';
import 'package:grocery_app/screens/category_items_screen.dart';
import 'package:grocery_app/screens/comingSoonPage/cummunity_detail_screen.dart';
import 'package:grocery_app/screens/explore_screen.dart';
import 'package:grocery_app/screens/home/top_curosel.dart';
import 'package:grocery_app/screens/notifications/notifications_screen.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/services/cart_service.dart';
import 'package:grocery_app/services/cummunity_service.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/widgets/grocery_item_card_widget.dart';
import 'package:grocery_app/widgets/subscription_card.dart';
import 'package:grocery_app/widgets/subscription_table.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _featuredProducts = [];

    // MODIFICATION 1: Create a static cache and a Future variable
  static List<Product>? _cachedFeaturedProducts;
  Future<List<Product>>? _featuredProductsFuture;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _featuredProductsFuture = _loadFeaturedProducts();
  }

    Future<List<Product>> _loadFeaturedProducts() async {
    // MODIFICATION 2: Check cache first
    if (_cachedFeaturedProducts != null) {
      return _cachedFeaturedProducts!;
    }
    
    try {
      // Add an artificial delay to see the loader
      await Future.delayed(const Duration(milliseconds: 800));
      
      final products = await CategoryService.fetchFeaturedProducts();
      _cachedFeaturedProducts = products; // Save to cache
      return products;
    } catch (e) {
      // Propagate error to FutureBuilder
      throw Exception('Failed to load featured products: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Header with BG + Notification + Search
              Stack(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.18,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Image.asset(
                      "assets/images/OnBoarding/background_home.png",
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Welcome User 👋",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      _searchBar(),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// 🔹 Hero Carousel
              padded( TopCurosel()),
              // heading("Active Subscriptions", "See all plans" , (){
              //    Navigator.push(
              //       context,
              //       AnimatedTransitions.slideFromRight(
              //         SubscriptionScreen()
              //       ),
              //     );
              // }),
              /// 🔹 Subscription Carousel
              padded(const SubscriptionCarousel()),

              heading("Subscription Plans", "See all plans →" , ()=>{

              }),
              /// 🔹 Subscription Plans Section
              _subscriptionSection(context),

              /// 🔹 Category Showcase
              padded(_buildCategoryShowcase()),


              /// 🔹 Featured Products
              _buildFeaturedProducts(),

              const SizedBox(height: 16),

              /// 🔹 Coming Soon Communities
              const SizedBox(height: 10),
              _buildCommunities(),
            ],
          ),
        ),
      ),
    );
  }

  /// ===============================
  /// 🔹 Featured Products Section
  /// ===============================
  Widget _buildFeaturedProducts() {
    // MODIFICATION 3: Use FutureBuilder
    return FutureBuilder<List<Product>>(
      future: _featuredProductsFuture,
      builder: (context, snapshot) {
        // --- Loading State ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildFeaturedProductsSkeleton();
        }

        // --- Error State ---
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        // --- Empty State ---
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No featured products found"));
        }

        // --- Success State ---
        final featuredProducts = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            padded(
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Featured Products",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        AnimatedTransitions.slideFromRight(
                          CategoryItemsScreen(name: "Featured Products", allProducts: featuredProducts),
                        ),
                      );
                    },
                    child: const Text("See All →"),
                  ),
                ],
              ),
            ),
            ListView.builder(
              itemCount: featuredProducts.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final product = featuredProducts[index];
                return GestureDetector(
                  onTap: product.isInStock ? () => _onProductClicked(product) : null,
                  child: Opacity(
                    opacity: product.isInStock ? 1.0 : 0.5,
                    child: GroceryItemCardWidget(
                      item: product,
                      heroSuffix: "home_screen",
                      onAddToCart: (productVariantId, quantity) => CartService().addToCart(productVariantId, quantity),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

    Widget _buildFeaturedProductsSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        padded(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Skeleton(width: 180, height: 24),
              Skeleton(width: 80, height: 24),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Simulate 3 list items loading
        for (int i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Skeleton(width: 80, height: 80, isCircle: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Skeleton(width: double.infinity, height: 20),
                      SizedBox(height: 8),
                      Skeleton(width: 100, height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }



  void _onProductClicked(Product item) {
    Navigator.push(
      context,
      AnimatedTransitions.fadeScale(ProductDetailsScreen(product: item)),
    );
  }

  /// ===============================
  /// 🔹 Communities Section
  /// ===============================
 Widget _buildCommunities() {
  return FutureBuilder<List<Community>>(
    future: CommunityService.fetchCommunities(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(child: Text('No communities found'));
      }

      final communities = snapshot.data!;
      return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: communities.length,
        itemBuilder: (context, index) {
          final community = communities[index];
          return GestureDetector(
            onTap: (){
              Navigator.push(
                          context,
                          AnimatedTransitions.fadeScale(
                            CommunityDetailScreen(community: community),
                          ),
                        );
            },
            child: Container(
              
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(community.image),
                  fit: BoxFit.cover,
            
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Coming soon badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              "Coming Soon ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.eco, size: 14, color: Colors.greenAccent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
            
                      // Title
                      Text(
                        community.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
            
                      // Subtitle / tagline
                      // Text(
                      //    "Take the health diet",
                      //   style: const TextStyle(
                      //     color: Colors.white70,
                      //     fontSize: 14,
                      //   ),
                      // ),
            
                      const SizedBox(height: 16),
            
                      // Learn more button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:AppColors.bottonBackgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical:1,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            AnimatedTransitions.fadeScale(
                              CommunityDetailScreen(community: community),
                            ),
                          );
                        },
                        child: const Text(
                          "Learn More →",
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  /// ===============================
  /// 🔹 Search Bar
  /// ===============================
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: "Search for products",
          prefixIcon: const Icon(Icons.search),

          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (query) => debugPrint("Searching for: $query"),
      ),
    );
  }

 // In home_screen.dart, find the _subscriptionSection method
// In home_screen.dart, find the _subscriptionSection method

Widget _subscriptionSection(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
    // ✨ MODIFICATION: Adjust the clamp values to reduce overall height.
    // Try reducing the max height significantly, and the min height if needed.
    height: (screenHeight * 0.50).clamp(350.0, 400.0), // Experiment with these values
    child: const SubscriptionTable(),
  );
}

Widget heading(String title, String? all, VoidCallback? onPressed) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black , fontSize: 18)),
        GestureDetector(
          onTap: onPressed!,
          child: Text(
            all!,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryColor),
          ),
        ),
      ],
    ),
  );
}

  /// 🔹 Padding Helper
  Widget padded(Widget widget) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: widget);

  /// 🔹 Subtitle
  Widget subTitle(BuildContext context, String text, {show = true}) {
    return Row(
      children: [
        Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (show)
          GestureDetector(
            onTap: () => Navigator.push(context, AnimatedTransitions.slideFromRight(ExploreScreen())),
            child: const Text("See All", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
          ),
      ],
    );
  }

  /// 🔹 Category Showcase (unchanged, but styled already)
  Widget _buildCategoryShowcase() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFD6A35A), Color(0xFF7B3F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Rejuvenating Earth\nNourishing Lives",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
          const SizedBox(height: 8),
          const Text("Our Categories you can shop from–",
              style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w400)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _categoryCard("Natural Farming", "assets/images/natural_farming.png" , CombinedScreen())),
              const SizedBox(width: 6),
              Expanded(child: _categoryCard("Naturally Grown Vegetables", "assets/images/natural_veggies.png" , ExploreScreen())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(String title, String imagePath ,Widget screen ) {
    return GestureDetector(
      onTap: () => Navigator.push(context, AnimatedTransitions.slideFromRight(screen) ),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD6A35A), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF7B3F00))),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                child: Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

