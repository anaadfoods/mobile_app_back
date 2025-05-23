import 'package:flutter/material.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/screens/category_items_screen.dart';
import 'package:grocery_app/screens/comingSoonPage/customer_support.dart';
import 'package:grocery_app/screens/comingSoonPage/farmer_support.dart';
import 'package:grocery_app/screens/explore_screen.dart';
import 'package:grocery_app/screens/home/home_video.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grocery_app/widgets/grocery_item_card_widget.dart';
import 'package:grocery_app/widgets/subscription_card.dart';
import 'package:grocery_app/widgets/subscription_table.dart';
import 'grocery_featured_Item_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _featuredProducts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeaturedProducts();
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      final products = await CategoryService.fetchFeaturedProducts();
      if (mounted) {
        setState(() {
          _featuredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildFeaturedProducts() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_featuredProducts.isEmpty) {
      return const Center(child: Text('No featured products available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Featured Products",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => CategoryItemsScreen(
                          name: "Featured Products",
                          allProducts: _featuredProducts,
                        ),
                  ),
                );
              },
              child: const Text('See All'),
            ),
          ],
        ),
        SizedBox(
          height: 250,
          child: getHorizontalItemSlider(_featuredProducts),

        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "AnaadFoods",
          style: TextStyle(
            fontSize: 24,
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              padded(const AssetVideoPlayer()),
              padded(
                const Text(
                  "Active Subscription",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                ),
              ),
              padded(SubscriptionCarousel()),
              padded(
                const Text(
                  "Subscription Plans",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: SubscriptionTable(),
              ),
              // padded(getHorizontalItemSlider(_featuredProducts)),
              padded(_buildFeaturedProducts()),
              padded(subTitle(context, "Coming Soon", show: false)),
              comingSoon(context),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget comingSoon(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _buildComingSoonCard(
            context,
            title: groceryFeaturedItems[0].name,
            subtitle: groceryFeaturedItems[0].description,

            imagePath: "assets/images/grocery_images/banana.png",
            color: const Color(0xffF8A44C),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FarmerSupport(),
                  ),
                ),
          ),
          const SizedBox(width: 16),
          _buildComingSoonCard(
            context,
            title: groceryFeaturedItems[1].name,
            subtitle: groceryFeaturedItems[1].description,

            imagePath: "assets/images/grocery_images/apple.png",
            color: const Color(0xffF78B42),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerSupport(),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String imagePath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "We promise purity, nutrition, and trust — so your family eats clean.",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget padded(Widget widget) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: widget,
    );
  }

  Widget getHorizontalItemSlider(List<Product> items) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      height: 250,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              onItemClicked(context, items[index]);
            },
            child: GroceryItemCardWidget(
              item: items[index],
              heroSuffix: "home_screen",
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return SizedBox(width: 20);
        },
      ),
    );
  }

  void onItemClicked(BuildContext context, Product item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: item),
      ),
    );
  }

  Widget subTitle(BuildContext context, String text, {show = true}) {
    return Row(
      children: [
        Text(text, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Spacer(),
        if (show)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExploreScreen()),
              );
            },
            child: Text(
              "See All",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget locationWidget() {
    String locationIconPath = "assets/icons/location_icon.svg";
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(locationIconPath),
        SizedBox(width: 8),
        Text(
          "Khartoum,Sudan",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
