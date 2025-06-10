import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/models/favorite_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/subscription_plan_model.dart';
import 'package:grocery_app/models/subscription_request_create_model.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail_single.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/screens/checkout/checkout_screen.dart';
import 'package:grocery_app/screens/address/address_selection_screen.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/services/cart_service.dart';
import 'package:grocery_app/services/favorite_state_service.dart';
import 'package:grocery_app/services/subscription_service.dart';
import 'package:grocery_app/widgets/item_counter_widget.dart';
import 'package:grocery_app/models/plan_search_result.dart';
import 'package:grocery_app/services/plan_search_service.dart';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';

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
  double priceSubscription = 0.0;
  double get currentPrice => widget.product.finalPrice * amount;
  double get originalPrice => widget.product.price * 1.2 * amount;

  late final List<String> tempImages =
      widget.product.productImages.map((e) => e.image).toList();

  List<String> planNames = ["Aarambh", "Pathik", "Tapasvi", "Siddh"];
  List<SubscriptionPlan> planDescriptions = [];

  final FavoriteStateService _favoriteStateService = FavoriteStateService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final AuthService _authService = AuthService();

  // Add state for enabled plans
  List<PlanSearchResult> enabledPlanNames = [];
  bool _isLoadingPlans = true;

  Future<void> _subscriptions() async {
    final result = await _subscriptionService.getSubscriptionPlans();
    if (mounted) {
      if (result['success']) {
        setState(() {
          planDescriptions = result['data'] as List<SubscriptionPlan>;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    print(
      'ProductDetailsScreen initState called for product: ${widget.product.id}',
    );
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _initializeFavoriteState();
    _fetchEnabledPlans();
    _subscriptions();
  }

  @override
  void didUpdateWidget(ProductDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('ProductDetailsScreen didUpdateWidget called');
    if (oldWidget.product.id != widget.product.id) {
      _fetchEnabledPlans();
    }
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

  Future<void> _fetchEnabledPlans() async {
    try {
      print('Fetching plans for variant: ${widget.product.id}');
      final plans = await PlanSearchService.fetchPlansForVariant(
        widget.product.id,
      );
      print('Plans fetched: $plans');
      setState(() {
        enabledPlanNames = plans;
        print(enabledPlanNames);
        _isLoadingPlans = false;
      });
    } catch (e) {
      print('Error fetching plans: $e');
      setState(() {
        enabledPlanNames = [];
        _isLoadingPlans = false;
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
    final product = widget.product;
    final images = product.productImages;
    final double imageHeight = MediaQuery.of(context).size.height * 0.4;

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
          product.productCategory,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child:
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
                      onToggle: () => handleFavoriteToggle(product.id),
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Name at the top
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 16.0,
              ),
              child: Text(
                product.productName,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
            ),
            // Image Carousel
            CarouselSlider(
              items:
                  images.isNotEmpty
                      ? images
                          .map(
                            (img) => Container(
                              width: double.infinity,
                              height: imageHeight,
                              child: Image.network(
                                img.image,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: imageHeight,
                                errorBuilder:
                                    (context, error, stackTrace) => Icon(
                                      Icons.broken_image,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                              ),
                            ),
                          )
                          .toList()
                      : [
                        Container(
                          width: double.infinity,
                          height: imageHeight,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                      ],
              options: CarouselOptions(
                height: imageHeight,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                enlargeCenterPage: true,
              ),
            ),
            // Price and quantity selector in a row below the image
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Price: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  if (product.price != product.finalPrice)
                    Text(
                      '₹${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (product.price != product.finalPrice) SizedBox(width: 8),
                  Text(
                    '₹${product.finalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  SizedBox(width: 24),
                  // Quantity selector in the same row
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  _buildBottomButtons(),
                  SizedBox(height: 10),
                  // Product Description Preview
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          product.productDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('Product Description'),
                                      content: SingleChildScrollView(
                                        child: Text(product.productDescription),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: Text('Close'),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            child: Text('See more'),
                          ),
                        ),
                      ],
                    ),
                  ),
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
          if (_isLoadingPlans)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(planNames.length, (index) {
                final planName = planNames[index];

                // Always return a PlanSearchResult, never null
                final enabledPlan = enabledPlanNames.firstWhere(
                  (e) =>
                      e.planName.trim().toLowerCase() ==
                      planName.trim().toLowerCase(),
                  orElse:
                      () => PlanSearchResult(
                        planId: 0,
                        planName: planName,
                        discountedPrice: 0.0,
                      ),
                );

                final isEnabled = enabledPlan.discountedPrice > 0;
                final isActive = isEnabled && _selectedTab == index;

                return GestureDetector(
                  onTap:
                      isEnabled
                          ? () {
                            setState(() {
                              _selectedTab = index;
                            });
                          }
                          : null,
                  child: Opacity(
                    opacity: isEnabled ? 1.0 : 0.4,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            enabledPlan.discountedPrice > 0
                                ? "₹${enabledPlan.discountedPrice.toStringAsFixed(0)}"
                                : "",
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            planName,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.black87,
                              fontWeight:
                                  isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          SizedBox(height: 16),
          (planDescriptions.isEmpty || _selectedTab >= planDescriptions.length)
              ? Center(child: Text('No plan description available'))
              : Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.green[700],
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            planDescriptions[_selectedTab].name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[900],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Colors.blueGrey,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Duration: ',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${planDescriptions[_selectedTab].durationMonths} months',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.percent, color: Colors.orange, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Total Discount: ',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${planDescriptions[_selectedTab].totalDiscountPercentage}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.payments, color: Colors.purple, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Allows Installments: ',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  planDescriptions[_selectedTab]
                                          .allowsInstallments
                                      ? Colors.green[100]
                                      : Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              planDescriptions[_selectedTab].allowsInstallments
                                  ? 'Yes'
                                  : 'No',
                              style: TextStyle(
                                color:
                                    planDescriptions[_selectedTab]
                                            .allowsInstallments
                                        ? Colors.green[800]
                                        : Colors.red[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.teal,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'One-time Allowance: ',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  planDescriptions[_selectedTab].isOneTimeOnly
                                      ? Colors.green[100]
                                      : Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              planDescriptions[_selectedTab].isOneTimeOnly
                                  ? 'Yes'
                                  : 'No',
                              style: TextStyle(
                                color:
                                    planDescriptions[_selectedTab].isOneTimeOnly
                                        ? Colors.green[800]
                                        : Colors.red[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.repeat,
                            color: Colors.deepOrange,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Installment Frequency: ',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${planDescriptions[_selectedTab].installmentFrequencyMonths} months',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Divider(),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blueGrey,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              planDescriptions[_selectedTab].description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
              planDescriptions[_selectedTab].description,
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
    if (enabledPlanNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No subscription plans available for this product'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedPlan = enabledPlanNames[_selectedTab];
    if (planDescriptions[_selectedTab].name ==
        enabledPlanNames[_selectedTab].planName) {
      print('Selected plan: ${planDescriptions[_selectedTab].name}');
    } else {
      print('Selected plan does not match enabled plan names');
    }
    if (selectedPlan.discountedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected plan is not available for subscription'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      priceSubscription = selectedPlan.discountedPrice;
    });

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

      // Navigate to checkout screen for subscription
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => AddressSelectionScreen(
                singleProduct: widget.product.toProductVariant(),
                quantity: amount,
                price: priceSubscription,
                isSubscription: true,
                selectedPlan: _selectedTab + 1,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
                              (context) => AddressSelectionScreen(
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
