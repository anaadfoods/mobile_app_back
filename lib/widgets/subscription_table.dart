import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/helpers/animated_transitions.dart';
import 'package:grocery_app/helpers/responsive_helper.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/subscription_plan_model.dart';
import 'package:grocery_app/models/subscription_plan_product_model.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/services/cart_service.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/services/subscription_service.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/common_widgets/skeleton_loader.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';


class SubscriptionTable extends StatefulWidget {
  final Function(SubscriptionPlan)? onPlanSelected;

  const SubscriptionTable({super.key, this.onPlanSelected});

  @override
  _SubscriptionTableState createState() => _SubscriptionTableState();
}

class _SubscriptionTableState extends State<SubscriptionTable> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  String? _error;

    // MODIFICATION 1: Create static variables for caching
  static List<SubscriptionPlan>? _cachedPlans;
  static final Map<int, List<SubscriptionPlanProduct>> _cachedPlanProducts = {};

  final Map<int, List<SubscriptionPlanProduct>> _planProducts = {};
  final Map<int, bool> _loadingProducts = {};
  bool _isLoadingDropdownData = true;
  List<String> _dropdownItems = [];
  late ResponsiveHelper responsive = ResponsiveHelper(
    context,
    BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width,
      minWidth: 0,
      minHeight: 0,
      maxHeight: MediaQuery.of(context).size.height,
    ),
  );
  
  // MODIFICATION 1: Add a state variable to track the current index
  int _currentIndex = 1; // Start at 1 to match initialPage

    @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Check cache first
    if (_cachedPlans != null && _cachedPlans!.isNotEmpty) {
      setState(() {
        _plans = _cachedPlans!;
        _isLoading = false;
      });
      // Pre-load products from cache or fetch if not available
      _cachedPlans!.forEach((plan) => _loadPlanProducts(plan.id));
    } else {
      // Fetch from network if cache is empty
      await _loadSubscriptionPlans();
    }
  }
  // ... (Your existing data loading methods like _loadSubscriptionPlans, _loadPlanProducts, etc. remain unchanged)
  Future<void> _loadSubscriptionPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _subscriptionService.getSubscriptionPlans();
      if (mounted) {
        if (result['success']) {
          setState(() {
            _plans = result['data'] as List<SubscriptionPlan>;
            _cachedPlans = _plans; // Cache the fetched plans
            _isLoading = false;
          });
          // Pre-load products after fetching plans
          _plans.forEach((plan) => _loadPlanProducts(plan.id));
        } else {
          setState(() {
            _error = result['message'];
            _isLoading = false;
          });
        }
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

  Future<void> _loadPlanProducts(int planId) async {
        if (_cachedPlanProducts.containsKey(planId)) {
      setState(() {
        _planProducts[planId] = _cachedPlanProducts[planId]!;
      });

      return;
    }

    if (_loadingProducts[planId] == true) return; // Prevent multiple calls

    setState(() {
      _loadingProducts[planId] = true;
    });

     try {
      final result = await _subscriptionService.getSubscriptionPlanProducts(planId);
      if (mounted) {
        if (result['success']) {
          final response = result['data'] as SubscriptionPlanProductsResponse;
          setState(() {
            _planProducts[planId] = response.products;
            _cachedPlanProducts[planId] = response.products; // Cache products
            //...
          });
        }  else {
          if (result['requiresLogin'] == true) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          } else {
            SnackBarHelper.showError(
              context,
              result['message'] ?? 'Failed to load products',
            );
          }
          setState(() {
            _loadingProducts[planId] = false;
            _isLoadingDropdownData = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error loading products: $e');
        setState(() {
          _loadingProducts[planId] = false;
          _isLoadingDropdownData = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    // Clear cache
    _cachedPlans = null;
    _cachedPlanProducts.clear();
    // Fetch fresh data
    await _loadSubscriptionPlans();
  }
  Future<void> _handleSubscribe(SubscriptionPlan plan) async {
    try {
      final result = await _subscriptionService.subscribeToPlan(plan.id);

      if (!mounted) return;

      if (result['success']) {
        SnackBarHelper.showSuccess(context, result['message']);
        if (widget.onPlanSelected != null) {
          widget.onPlanSelected!(plan);
        }
      } else {
        String errorMsg = result['message'] ?? 'Failed to subscribe';
        if (result['errors'] != null) {
          errorMsg += '\n${result['errors']}';
        }
        if (result['requiresLogin'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          SnackBarHelper.showError(context, errorMsg);
        }
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Error subscribing to plan: $e');
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _error ?? 'An error occurred',
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSubscriptionPlans,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SkeletonAnimation(
        isLoading: true,
        loadingWidget: SubscriptionSkeletonLoader(responsive: responsive),
        child: Container(),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SizedBox(
        height: 500,
        // MODIFICATION 2: Use CarouselSlider.builder for conditional styling
        child: CarouselSlider.builder(
          itemCount: _plans.length,
          itemBuilder: (context, index, realIndex) {
            final plan = _plans[index];
            // Determine if the current card is the one in the center
            final isSelected = (index == _currentIndex);
            // Pass the `isSelected` flag to the card builder
            return _buildPlanCard(plan, isSelected: isSelected);
          },
          // MODIFICATION 3: Update CarouselOptions for the desired effect
          options: CarouselOptions(
            height: 500,
            viewportFraction: 0.8,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            enlargeCenterPage: true, // Make the center card larger
            enlargeFactor: 0.3, // Control the scaling of the center card
            enableInfiniteScroll: true,
            initialPage: 1,
            onPageChanged: (index, reason) {
              // Update the state when the page changes
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }

  // MODIFICATION 4: Update the card builder to accept and use the `isSelected` flag
  Widget _buildPlanCard(SubscriptionPlan plan, {required bool isSelected}) {
    // Use AnimatedContainer for smooth transitions between selected/unselected states
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      decoration: BoxDecoration(
        // Conditionally change color opacity
        color: isSelected ? AppColors.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // Only show shadow on the selected card for a "lifting" effect
          if (isSelected)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
        ],
        // Conditionally change border opacity
        border: Border.all(
          color: isSelected ? Colors.white : Colors.black.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        // Conditionally change text opacity
                        color: isSelected ? Colors.white : Colors.black.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? Colors.white : Colors.black.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              // Icon
              Container(
                margin: const EdgeInsets.only(left: 12),
                width: 65,
                height: 65,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.eco,
                    color: Color(0xFF2E5E3A),
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Know More Button
          OutlinedButton.icon(
            onPressed: () {
              final products = _planProducts[plan.id] ?? [];
              showSubscriptionPopup(context, plan, products);
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isSelected ? Colors.white : Colors.black.withOpacity(0.7),
                width: 1.5,
              ),
              foregroundColor: isSelected ? Colors.white : Colors.black.withOpacity(0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Text(
              "Know More",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            label: const Icon(Icons.arrow_forward, size: 14),
          ),
          const SizedBox(height: 8),
          // Divider
          Divider(color: Colors.white.withOpacity(0.6), thickness: 1),
          const SizedBox(height: 8),
          // Info Rows
          _styledInfoRow(
            icon: Icons.check_circle,
            label: "Duration",
            value: "${plan.durationMonths} Months",
            isSelected: isSelected,
          ),
          const SizedBox(height: 8),
          _styledInfoRow(
            icon: Icons.check_circle,
            label: "One-Time Allowance",
            value: plan.isOneTimeOnly ? "Yes" : "No",
            isSelected: isSelected,
          ),
          const SizedBox(height: 8),
          _styledInfoRow(
            icon: Icons.check_circle,
            label: "Savings",
            value: "${plan.totalDiscountPercentage}% off 🔥",
            isSelected: isSelected,
          ),
        ],
      ),
    );
  }

  // Helper for info row (also updated to use `isSelected`)
  Widget _styledInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isSelected,
  }) {
    final Color textColor = isSelected ? Colors.white : Colors.black.withOpacity(0.85);
    return Row(
      children: [
        Icon(icon, color: textColor, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.18)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}
/// POPUP CODE
void showSubscriptionPopup(
  BuildContext context,
  SubscriptionPlan plan,
  List<SubscriptionPlanProduct> products,
) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black.withOpacity(0.3),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.52,
                width: MediaQuery.of(context).size.width * 0.9,
                child: _SubscriptionPopupContent(
                  plan: plan,
                  products: products,
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
        child: child,
      );
    },
  );
}

class _SubscriptionPopupContent extends StatefulWidget {
  final SubscriptionPlan plan;
  final List<SubscriptionPlanProduct> products;

  const _SubscriptionPopupContent({
    super.key,
    required this.plan,
    required this.products,
  });

  @override
  State<_SubscriptionPopupContent> createState() =>
      _SubscriptionPopupContentState();
}

class _SubscriptionPopupContentState extends State<_SubscriptionPopupContent> {
  String? _selectedProduct;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + Icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.plan.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 32,
              child: Icon(Icons.eco, color: Color(0xFF2E5E3A), size: 32),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Description
        Text(
          widget.plan.description,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const Divider(color: Colors.white54, height: 30),

        // Info rows
        _infoRow("Duration", "${widget.plan.durationMonths} Months"),
        _infoRow(
          "Allows Installments",
          widget.plan.allowsInstallments ? "Yes" : "No",
        ),
        _infoRow(
          "One-Time Allowance",
          widget.plan.isOneTimeOnly ? "Yes" : "No",
        ),
        _infoRow(
          "Savings",
          "${widget.plan.totalDiscountPercentage}% Discount ",
        ),
        _infoRow(
          "Installments",
          "${widget.plan.installmentFrequencyMonths} Installments",
        ),
        _infoRow("Active", widget.plan.isActive ? "Yes" : "No"),

        const Spacer(),

        // Dropdown for products
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),

            border: Border.all(color: Colors.white, width: 1),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            dropdownColor: AppColors.primaryColor,
            value: _selectedProduct,
            borderRadius: BorderRadius.circular(30),
            style: TextStyle(color: Colors.white),
            hint: const Text(
              "Select Product",
              style: TextStyle(color: Colors.white),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            items:
                widget.products.map((p) {
                  return DropdownMenuItem<String>(
                    value: p.productName,
                    child: Text(p.productName),
                    onTap: () async {
                      final product = await CategoryService.fetchProductById(p.productId);

                                   Navigator.push(
                      context,
                      AnimatedTransitions.fadeScale(ProductDetailsScreen(product: product)));
                    },
                  );
                }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedProduct = val;
              });
            },
          ),
        ),

        const SizedBox(height: 8),

        // Subscribe button
        // SizedBox(
        //   width: double.infinity,
        //   child: ElevatedButton(
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: Colors.white,
        //       foregroundColor: const Color(0xFF2E5E3A),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(16),
        //       ),
        //       padding: const EdgeInsets.symmetric(vertical: 14),
        //     ),
        //     onPressed: () {
        //       Navigator.pop(context); // close popup
        //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //         content: Text(
        //             "Subscribed to ${widget.plan.name} with product $_selectedProduct"),
        //       ));
        //     },
        //     child: const Text("Subscribe",
        //         style: TextStyle(fontWeight: FontWeight.bold)),
        //   ),
        // ),
      ],
    );
  }
}

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}
