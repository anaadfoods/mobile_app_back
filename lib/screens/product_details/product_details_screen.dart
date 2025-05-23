import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/models/favorite_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/subscription_request_create_model.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/screens/checkout/checkout_screen.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/services/cart_service.dart';
import 'package:grocery_app/services/favorite_state_service.dart';
import 'package:grocery_app/services/subscription_service.dart';
import 'package:grocery_app/widgets/item_counter_widget.dart';

import 'favourite_toggle_icon_widget.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({Key? key, required this.product})
    : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  int selectedImageIndex = 0;
  late TabController _tabController;
  int _selectedTab = 0;
  bool isFavorite = false;
  bool _isLoadingFavorite = true;
  bool _isSubscribing = false;
  int amount = 1;
  double get currentPrice => widget.product.finalPrice * amount;
  double get originalPrice => widget.product.price * 1.2 * amount;

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

  final FavoriteStateService _favoriteStateService = FavoriteStateService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final AuthService _authService = AuthService();

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
        final favorites = (result['data'] as List<FavoriteModel>);
        if (mounted) {
          setState(() {
            isFavorite = favorites.any((fav) => fav.id == widget.product.id);
            _isLoadingFavorite = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isFavorite = false;
            _isLoadingFavorite = false;
          });
        }
      }
    } catch (e) {
      print('Error initializing favorite state: $e');
      if (mounted) {
        setState(() {
          isFavorite = false;
          _isLoadingFavorite = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.3,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 6,
                  ),
                  child: Row(
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
                      Container(
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: getDetailsColumn(originalPrice, currentPrice),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  _buildBottomButtons(),
                  SizedBox(height: 10),
                  getPlanTabSection(),
                ],
              ),
            ),
          ],
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
    return Container(
      height: 50,
      child: SingleChildScrollView(
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
      ),
    );
  }

  Widget getDetailsColumn(double originalPrice, double discountPrice) {
    return Container(
      height: 200,
      child: Column(
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
                "₹${originalPrice.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8),
              Text(
                "₹${discountPrice.toStringAsFixed(2)}",
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
      ),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(planNames.length, (index) {
              final bool isActive = _selectedTab == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTab = index;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    planNames[index],
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black87,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 16),
          Text(
            planDescriptions[_selectedTab],
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTapDown: (_) => setState(() => _subscribeBtnPressed = true),
              onTapUp: (_) => setState(() => _subscribeBtnPressed = false),
              onTapCancel: () => setState(() => _subscribeBtnPressed = false),
              onTap: _handleSubscribe,
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
                    child:
                        _isSubscribing
                            ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
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

        // Notify other screens about the change
        _favoriteStateService.notifyFavoriteChanged();

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

  Future<void> _handleSubscribe() async {
    if (_isSubscribing) return;

    setState(() {
      _isSubscribing = true;
    });

    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please login to subscribe'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Login',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ),
        );
        return;
      }

      // Create subscription request
      final request = SubscriptionCreateRequest(
        plan: _selectedTab + 1, // Plan ID based on selected tab
        deliveryAddress:
            "123 Green Lane, New Delhi", // TODO: Get from user profile
        deliveryCity: "New Delhi",
        deliveryState: "Delhi",
        deliveryPincode: "110001",
        deliveryPhone: "+911234567890",
        paymentType: "FULL",
        items: [
          SubscriptionCreateItem(
            productVariantId: widget.product.id,
            quantity: amount,
          ),
        ],
      );

      final result = await _subscriptionService.createSubscription(request);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        // TODO: Navigate to subscription details or success screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating subscription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubscribing = false;
        });
      }
    }
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Price:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${currentPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final authService = AuthService();
                      final token = await authService.getAccessToken();

                      if (token == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please login to add items to cart'),
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
                      await cartService.addToCart(widget.product.id, amount);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${widget.product.productName} added to cart',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      print('Add to cart error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add item to cart'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Add to Cart'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final authService = AuthService();
                      final token = await authService.getAccessToken();

                      if (token == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please login to proceed with purchase',
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

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CheckoutScreen(
                                singleProduct:
                                    widget.product.toProductVariant(),
                                quantity: amount,
                              ),
                        ),
                      );
                    } catch (e) {
                      print('Buy now error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to proceed with purchase'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Buy Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
