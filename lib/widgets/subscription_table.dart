import 'package:flutter/material.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/subscription_plan_model.dart';
import 'package:grocery_app/models/subscription_plan_product_model.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/services/subscription_service.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/common_widgets/skeleton_loader.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSubscriptionPlans();
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
    try {
      final result = await _subscriptionService.getSubscriptionPlanProducts(
        planId,
      );
      if (mounted) {
        if (result['success']) {
          final response = result['data'] as SubscriptionPlanProductsResponse;
          setState(() {
            _planProducts[planId] = response.products;
          });
        } else {
          if (result['requiresLogin'] == true) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to load products'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSubscribe(SubscriptionPlan plan) async {
    try {
      final result = await _subscriptionService.subscribeToPlan(plan.id);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error subscribing to plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  Widget _buildPlanCard(SubscriptionPlan plan) {
    return Container(
      width: 50,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.green.withOpacity(0.1)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  plan.tagline,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Duration', '${plan.durationMonths} months'),
                _buildInfoRow(
                  'Total Discount',
                  '${plan.totalDiscountPercentage}%',
                ),
                _buildInfoRow('Base Discount', '${plan.discountPercentage}%'),
                _buildInfoRow('Add. Discount', '${plan.discountPercentage}%'),
                _buildInfoRow(
                  'Installments',
                  plan.allowsInstallments ? 'Available' : 'Not Available',
                ),
                if (plan.allowsInstallments)
                  _buildInfoRow(
                    'Frequency',
                    '${plan.installmentFrequencyMonths} months',
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Available Products:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _planProducts[plan.id]?.map((product) {
                        return DropdownMenuItem<String>(
                          value: product.productName,
                          child: GestureDetector(
                            onTap: () async {
                              Future<Product> productData =
                                  CategoryService.fetchProductById(
                                    product.productId,
                                  );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => FutureBuilder<Product>(
                                        future: productData,
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return ProductDetailsScreen(
                                              product: snapshot.data!,
                                            );
                                          }
                                          return Text("Loading....");
                                        },
                                      ),
                                ),
                              );
                            },
                            child: Text(product.productName),
                          ),
                        );
                      }).toList() ??
                      [],
                  onChanged: (_) {},
                  hint: const Text('Select Product'),
                  onTap: () {
                    if (!_planProducts.containsKey(plan.id)) {
                      _loadPlanProducts(plan.id);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  plan.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ElevatedButton(
              onPressed: plan.isActive ? () => _handleSubscribe(plan) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                plan.isActive ? 'Subscribe Now' : 'Not Available',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
        child: Container(), // Placeholder, won't be shown while loading
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadSubscriptionPlans,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _plans.length,
            itemBuilder: (context, index) => _buildPlanCard(_plans[index]),
          );
        },
      ),
    );
  }
}
