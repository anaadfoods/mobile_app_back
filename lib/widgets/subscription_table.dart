import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/subscription_plan_model.dart';
import 'package:grocery_app/models/subscription_plan_product_model.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/services/subscription_service.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/common_widgets/skeleton_loader.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';

class SubscriptionTable extends StatefulWidget {
  final Function(SubscriptionPlan)? onPlanSelected;

  const SubscriptionTable({Key? key, this.onPlanSelected}) : super(key: key);

  @override
  _SubscriptionTableState createState() => _SubscriptionTableState();
}

class _SubscriptionTableState extends State<SubscriptionTable> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  String? _error;
  Map<int, List<SubscriptionPlanProduct>> _planProducts = {};
  Map<int, bool> _loadingProducts = {};
  bool _isLoadingDropdownData = true;
  List<String> _dropdownItems = [];

  @override
  void initState() {
    super.initState();
    _loadSubscriptionPlans();
    _loadPlanProducts(1);
    _loadPlanProducts(2);
    _loadPlanProducts(3);
    _loadPlanProducts(4);
  }

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
            _isLoading = false;
          });
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
    if (_loadingProducts[planId] == true) return; // Prevent multiple calls

    setState(() {
      _loadingProducts[planId] = true;
    });

    try {
      print('Fetching products for plan $planId');
      final result = await _subscriptionService.getSubscriptionPlanProducts(
        planId,
      );
      print('Received result: $result');

      if (mounted) {
        if (result['success']) {
          final response = result['data'] as SubscriptionPlanProductsResponse;
          print('Products loaded: ${response.products.length}');
          setState(() {
            _planProducts[planId] = response.products;
            _loadingProducts[planId] = false;
            _isLoadingDropdownData = false;
            _dropdownItems =
                response.products.map((p) => p.productName).toList();
          });
        } else {
          print('Failed to load products: ${result['message']}');
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
      print('Error in _loadPlanProducts: $e');
      if (mounted) {
        SnackBarHelper.showError(context, 'Error loading products: $e');
        setState(() {
          _loadingProducts[planId] = false;
          _isLoadingDropdownData = false;
        });
      }
    }
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
          errorMsg += '\n' + result['errors'].toString();
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
            child: Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
        loadingWidget: SubscriptionSkeletonLoader(),
        child: Container(),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadSubscriptionPlans,
      child: Container(
        height: 850,
        child: CarouselSlider(
          options: CarouselOptions(
            height: 850,
            viewportFraction: 0.75,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            enlargeFactor: 0.3,
            enableInfiniteScroll: true,
            padEnds: true,
            aspectRatio: 16 / 9,
            initialPage: 1,
          ),
          items: _plans.map((plan) => _buildPlanCard(plan)).toList(),
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final double cardHeight = MediaQuery.of(context).size.height - 80;
    return Container(
      width: MediaQuery.of(context).size.width * 0.90,
      height: 800,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.primaryColor.withOpacity(0.15)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  plan.tagline,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  plan.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 702,
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      _buildInfoRow(
                        'Duration',
                        '${plan.durationMonths} months',
                      ),
                      _buildInfoRow(
                        'Total Discount',
                        '${plan.totalDiscountPercentage}%',
                      ),
                      // _buildInfoRow(
                      //   'Base Discount',
                      //   '${plan.discountPercentage}%',
                      // ),
                      _buildInfoRow(
                        'Allows Installments',
                        plan.allowsInstallments ? 'Yes' : 'No',
                      ),

                      _buildInfoRow(
                        'one-time allowance',
                        plan.isOneTimeOnly ? 'Yes' : 'No',
                      ),
                      _buildInfoRow(
                        'Installments',
                        '${plan.installmentFrequencyMonths} months',
                        // plan.allowsInstallments ? 'Available' : 'Not Available',
                      ),
                      // if (plan.allowsInstallments)
                      //   _buildInfoRow(
                      //     'Frequency',
                      //     '${plan.installmentFrequencyMonths} months',
                      //   ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // const Text(
                        //   'Available Products:',
                        //   style: TextStyle(
                        //     fontWeight: FontWeight.bold,
                        //     fontSize: 16,
                        //   ),
                        // ),
                        if (_loadingProducts[plan.id] == true)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 1.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          GestureDetector(
                            onTap: () {
                              if (!_planProducts.containsKey(plan.id)) {
                                _loadPlanProducts(plan.id);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: SizedBox(
                                height: 45,
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                  value: null,
                                  items:
                                      _isLoadingDropdownData
                                          ? [
                                            DropdownMenuItem(
                                              value: null,
                                              child: Center(
                                                child: SizedBox(
                                                  height: 18,
                                                  width: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ]
                                          : _dropdownItems.map((item) {
                                            return DropdownMenuItem(
                                              value: item,
                                              child: Text(item),
                                            );
                                          }).toList(),
                                  onChanged:
                                      _isLoadingDropdownData
                                          ? null
                                          : (value) async {
                                            if (value != null) {
                                              final selectedProduct =
                                                  _planProducts[plan.id]
                                                      ?.firstWhere(
                                                        (product) =>
                                                            product
                                                                .productName ==
                                                            value,
                                                      );
                                              if (selectedProduct != null) {
                                                try {
                                                  final productData =
                                                      await CategoryService.fetchProductById(
                                                        selectedProduct
                                                            .productId,
                                                      );
                                                  if (mounted) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              context,
                                                            ) => ProductDetailsScreen(
                                                              product:
                                                                  productData,
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Error loading product details: $e',
                                                        ),
                                                        backgroundColor:
                                                            AppColors.error,
                                                      ),
                                                    );
                                                  }
                                                }
                                              }
                                            }
                                          },
                                  hint: Text(
                                    'Select Product',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  dropdownColor: Colors.white,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.primaryColor,
                                    size: 24,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  onTap: () {
                                    if (!_planProducts.containsKey(plan.id)) {
                                      _loadPlanProducts(plan.id);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //     Container(
  //       padding: const EdgeInsets.all(12),
  //       decoration: BoxDecoration(
  //         color: Colors.grey[50],
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       child: Text(
  //         plan.description,
  //         style: TextStyle(
  //           fontSize: 14,
  //           color: AppColors.textSecondary,
  //           height: 1.5,
  //         ),
  //         textAlign: TextAlign.center,
  //       ),
  //     ),
  //     ElevatedButton(
  //       onPressed: () => _handleSubscribe(plan),
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: AppColors.primaryColor,
  //         padding: const EdgeInsets.symmetric(
  //           horizontal: 32,
  //           vertical: 12,
  //         ),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //       ),
  //       child: const Text(
  //         'Subscribe Now',
  //         style: TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.white,
  //         ),
  //       ),
  //     ),
  //   ],
  // ),
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
