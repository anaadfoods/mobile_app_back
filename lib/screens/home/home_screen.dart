import 'package:flutter/material.dart';
import 'package:grocery_app/models/cummunity_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/screens/category_items_screen.dart';
import 'package:grocery_app/screens/comingSoonPage/cummunity_detail_screen.dart';
import 'package:grocery_app/screens/comingSoonPage/customer_support.dart';
import 'package:grocery_app/screens/comingSoonPage/farmer_support.dart';
import 'package:grocery_app/screens/explore_screen.dart';
import 'package:grocery_app/screens/home/home_video.dart';
import 'package:grocery_app/screens/home/top_curosel.dart';
import 'package:grocery_app/screens/notifications/notifications_screen.dart';
import 'package:grocery_app/services/cummunity_service.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grocery_app/widgets/grocery_item_card_widget.dart';
import 'package:grocery_app/widgets/subscription_card.dart';
import 'package:grocery_app/widgets/subscription_table.dart';
import 'package:grocery_app/helpers/animated_transitions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
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
    if (_error != null) {
      return Center(child: Text("Error loading featured products"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            padded(
              const Text(
                "Featured Products",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  AnimatedTransitions.slideFromRight(
                    CategoryItemsScreen(
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
          height: 350,
          child: Skeletonizer(
            enabled: _isLoading,
            child: getHorizontalItemSlider(_featuredProducts),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set to true if user has an active subscription
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
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed:
                () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(),
                    ),
                  ),
                },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // padded(const AssetVideoPlayer()),
              padded(TopCurosel()),
              padded(SubscriptionCarousel()),
              Column(
                children: [
                  const Text(
                    "Subscription Plans",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: SubscriptionTable(),
                  ),
                ],
              ),

              // padded(getHorizontalItemSlider(_featuredProducts)),
              _buildFeaturedProducts(),
              SizedBox(height: 10),
              padded(subTitle(context, "Coming Soon", show: false)),
              const SizedBox(height: 15),
              FutureBuilder<List<Community>>(
                future: CommunityService.fetchCommunities(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No communities found'));
                  }
                  final communities = snapshot.data!;
                  return SizedBox(
                    height: 170,
                    child: GridView.builder(
                      physics:
                          NeverScrollableScrollPhysics(), // Let parent scroll
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: communities.length,
                      itemBuilder: (context, index) {
                        final community = communities[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              AnimatedTransitions.fadeScale(
                                CommunityDetailScreen(community: community),
                              ),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: community.image,
                                    width: double.infinity,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                    errorWidget:
                                        (context, url, error) => Image.asset(
                                          "assets/images/placeholder.png",
                                          width: double.infinity,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    community.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: 4),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget comingSoon(BuildContext context) {
  //   return SizedBox(
  //     height: 130,
  //     child: ListView(
  //       padding: const EdgeInsets.symmetric(horizontal: 16),
  //       scrollDirection: Axis.horizontal,
  //       children: [
  //         _buildComingSoonCard(
  //           context,
  //           title: groceryFeaturedItems[0].name,
  //           subtitle: groceryFeaturedItems[0].description,

  //           imagePath: "assets/images/grocery_images/banana.png",
  //           color: const Color(0xffF8A44C),
  //           onTap:
  //               () => Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => const FarmerSupport(),
  //                 ),
  //               ),
  //         ),
  //         const SizedBox(width: 16),
  //         _buildComingSoonCard(
  //           context,
  //           title: groceryFeaturedItems[1].name,
  //           subtitle: groceryFeaturedItems[1].description,

  //           imagePath: "assets/images/grocery_images/apple.png",
  //           color: const Color(0xffF78B42),
  //           onTap:
  //               () => Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => const CustomerSupport(),
  //                 ),
  //               ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildComingSoonCard(
  //   BuildContext context, {
  //   required String title,
  //   required String subtitle,
  //   required String imagePath,
  //   required Color color,
  //   required VoidCallback onTap,
  // }) {
  //   return InkWell(
  //     onTap: onTap,
  //     borderRadius: BorderRadius.circular(16),
  //     child: Container(
  //       width: MediaQuery.of(context).size.width * 0.85,
  //       padding: const EdgeInsets.all(16),
  //       decoration: BoxDecoration(
  //         border: Border.all(color: Colors.grey),
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(16),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.grey.withOpacity(0.3),
  //             blurRadius: 8,
  //             offset: const Offset(2, 4),
  //           ),
  //         ],
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               ClipRRect(
  //                 borderRadius: BorderRadius.circular(12),
  //                 child: Image.asset(
  //                   imagePath,
  //                   width: 70,
  //                   height: 70,
  //                   fit: BoxFit.cover,
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       title,
  //                       style: const TextStyle(
  //                         fontWeight: FontWeight.bold,
  //                         fontSize: 16,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 2),
  //                     Text(
  //                       subtitle,
  //                       maxLines: 2,
  //                       overflow: TextOverflow.ellipsis,
  //                       style: const TextStyle(
  //                         color: Colors.black54,
  //                         fontSize: 13,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 12),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget padded(Widget widget) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: widget,
    );
  }

  Widget getHorizontalItemSlider(List<Product> items) {
    return Skeletonizer(
      enabled: _isLoading,
      child: SizedBox(
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 20),
          itemCount: items.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return SizedBox(
              child: GestureDetector(
                onTap: () {
                  onItemClicked(context, items[index]);
                },
                child: GroceryItemCardWidget(
                  item: items[index],
                  heroSuffix: "home_screen",
                ),
              ),
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return SizedBox(width: 20);
          },
        ),
      ),
    );
  }

  void onItemClicked(BuildContext context, Product item) {
    Navigator.push(
      context,
      AnimatedTransitions.fadeScale(ProductDetailsScreen(product: item)),
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
                AnimatedTransitions.slideFromRight(ExploreScreen()),
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
