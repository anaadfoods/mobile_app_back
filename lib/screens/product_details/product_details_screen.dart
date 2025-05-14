import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/models/favorite_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/widgets/item_counter_widget.dart';

import 'favourite_toggle_icon_widget.dart';
import 'package:grocery_app/services/cart_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  // final GroceryItem groceryItem;
  final String? heroSuffix;
  final Product product;

  const ProductDetailsScreen({
    super.key,
    this.heroSuffix,
    required this.product,
  });

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  int amount = 1;
  int selectedImageIndex = 0;
  late TabController _tabController;
  int _selectedTab = 0;
  bool isFavorite = false;
  bool _isLoadingFavorite = true;

  final List<String> tempImages = [
    'assets/images/grocery_images/apple.png',
    'assets/images/grocery_images/banana.png',
    'assets/images/grocery_images/ginger.png',
    'assets/images/grocery_images/pepper.png',
  ];

  final List<String> planNames = ["Aarambh", "Pathik", "Tapasvi", "Siddh"];
  final List<String> planDescriptions = [
    "Aarambh: The starter plan, perfect for trying out our service with a short-term commitment. Enjoy fresh products and flexible delivery.",
    "Pathik: The explorer plan, designed for those who want a longer experience and extra savings. Includes exclusive offers and priority support.",
    "Tapasvi: The disciplined plan, ideal for regular users who value consistency and maximum value. Get the best price and premium features.",
    "Siddh: The ultimate plan, for our most loyal customers. Unlock all benefits, maximum discounts, and VIP support.",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _initializeFavoriteState();
  }

  Future<void> _initializeFavoriteState() async {
    try {
      final authService = AuthService();
      final result = await authService.getFavorites();

      if (result['success']) {
        final favorites = result['data'] as List<FavoriteModel>;
        setState(() {
          isFavorite = favorites.any((fav) => fav.id == widget.product.id);
          _isLoadingFavorite = false;
        });
      } else {
        setState(() {
          isFavorite = false;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      print('Error initializing favorite state: $e');
      setState(() {
        isFavorite = false;
        _isLoadingFavorite = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double originalPrice = widget.product.price * 1.2;
    double discountPrice = widget.product.finalPrice;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          widget.product.productCategory,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      getImageHeaderWidget(),
                      const SizedBox(height: 10),
                      getImageThumbnailRow(),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: getDetailsColumn(originalPrice, discountPrice),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF007F5F),
                        side: BorderSide(color: Color(0xFF007F5F), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        try {
                          final authService = AuthService();
                          final token = await authService.getAccessToken();

                          if (token == null) {
                            // Show login prompt
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please login to add items to cart',
                                ),
                                backgroundColor: Colors.orange,
                                action: SnackBarAction(
                                  label: 'Login',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoginScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                            return;
                          }

                          final cartService = CartService();
                          await cartService.addToCart(
                            widget.product.id,
                            amount,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${widget.product.productName} added to cart',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          print(
                            'Add to cart error: $e',
                          ); // Add this for debugging
                          String errorMessage = 'Failed to add to cart';
                          Color backgroundColor = Colors.red;

                          if (e.toString().contains('Authentication failed')) {
                            errorMessage =
                                'Session expired. Please login again';
                            backgroundColor = Colors.orange;

                            // Show login prompt
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: backgroundColor,
                                action: SnackBarAction(
                                  label: 'Login',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoginScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: backgroundColor,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF007F5F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        elevation: 4,
                      ),
                      onPressed: () {},
                      child: Text(
                        'Buy Now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              getPlanTabSection(),
              getPlanTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget getImageHeaderWidget() {
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Image.asset(tempImages[selectedImageIndex], fit: BoxFit.contain),
      ),
    );
  }

  Widget getImageThumbnailRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tempImages.length, (index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedImageIndex = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color:
                      index == selectedImageIndex
                          ? Colors.green
                          : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(tempImages[index], height: 24, width: 24),
            ),
          );
        }),
      ),
    );
  }

  Widget getDetailsColumn(double originalPrice, double discountPrice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            widget.product.productName,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
          subtitle: AppText(
            text: widget.product.productCategory,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xff7C7C7C),
          ),
          trailing:
              _isLoadingFavorite
                  ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF007F5F),
                      ),
                    ),
                  )
                  : FavoriteToggleIcon(
                    favorite: isFavorite,
                    onToggle: () => handleFavoriteToggle(widget.product.id),
                  ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Text(
              "\$${originalPrice.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                decoration: TextDecoration.lineThrough,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 8),
            Text(
              "\$${discountPrice.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        ItemCounterWidget(
          amount: amount,
          onAmountChanged: (newAmount) {
            setState(() {
              amount = newAmount;
            });
          },
        ),
      ],
    );
  }

  // --- PLAN TABS ---
  Widget getPlanTabSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(planNames.length, (index) {
          final bool isActive = _selectedTab == index;
          return AnimatedContainer(
            duration: Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isActive ? Color(0xFF007F5F) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow:
                  isActive
                      ? [
                        BoxShadow(
                          color: Color(0xFF007F5F).withOpacity(0.18),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                      : [],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  planNames[index],
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget getPlanTabContent() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_selectedTab),
        margin: EdgeInsets.only(top: 18),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              planDescriptions[_selectedTab],
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTapDown: (_) => setState(() => _subscribeBtnPressed = true),
                onTapUp: (_) => setState(() => _subscribeBtnPressed = false),
                onTapCancel: () => setState(() => _subscribeBtnPressed = false),
                onTap: () {},
                child: AnimatedScale(
                  scale: _subscribeBtnPressed ? 0.97 : 1.0,
                  duration: Duration(milliseconds: 100),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF007F5F), Color(0xFFFFB300)],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Subscribe for Plan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _subscribeBtnPressed = false;

  double getTotalPrice() {
    return amount * widget.product.price;
  }

  void handleFavoriteToggle(int productId) async {
    if (_isLoadingFavorite) return; // Prevent multiple taps while loading

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final authService = AuthService();
      final result = await authService.toggleFavorite(productId);

      if (!mounted) return;

      setState(() {
        _isLoadingFavorite = false;
      });

      if (result['success']) {
        setState(() {
          isFavorite = !isFavorite;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  (isFavorite
                      ? "Added to favorites"
                      : "Removed from favorites"),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (result['requiresLogin'] == true) {
          // Navigate to login screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update favorite'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingFavorite = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorite: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
