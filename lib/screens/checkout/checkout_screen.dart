// ignore_for_file: unused_element

import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/routes/app_routes.dart';
import 'package:grocery_app/services/referral_reward_service.dart';
import 'package:grocery_app/utils/checkout_calculator.dart';

class CheckoutScreen extends StatefulWidget {
  final CartModel? cart;
  final Product? singleProduct;
  final double? price;
  final int? quantity;
  final bool isSubscription;
  final String? paymentType;
  final int? selectedPlan;
  final Map<String, String>? shippingDetails;
  final double codDeliveryCharge;
  final double prepaidDeliveryCharge;
  final String expectedDeliveryDate;

  const CheckoutScreen({
    super.key,
    this.cart,
    this.price,
    this.singleProduct,
    this.quantity,
    this.isSubscription = false,
    this.selectedPlan,
    this.shippingDetails,
    required this.codDeliveryCharge,
    required this.prepaidDeliveryCharge,
    required this.expectedDeliveryDate,
    this.paymentType,
  }) : assert(cart != null || (singleProduct != null && quantity != null));

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderService _orderService = OrderService();
  // final CartService _cartService = CartService(); // Unused - commented out
  // final AuthService _authService = AuthService(); // Unused - commented out
  final SubscriptionService _subscriptionService = SubscriptionService();
  final ReferralRewardService _rewardService = ReferralRewardService();

  ShippingDetails? _shippingDetails;
  SubscriptionPlan? subscription;
  List<SubscriptionPlan> planDescriptions = [];

  bool _isLoading = true;
  String? _error;
  // String _selectedPaymentMethod = 'UPI';
  // COD restriction: Default selection to Cash on Delivery (COD)
  String _selectedPaymentMethod = 'COD';
  bool _useExistingAddress = true;
  late String _selectedPaymentType;
  int _pendingRewardsCount = 0;

  int get totalItems => widget.cart?.totalItems ?? widget.quantity ?? 0;
  double get currentDeliveryCharge => CheckoutCalculator.deliveryCharge(
    paymentMethod: _selectedPaymentMethod,
    codCharge: widget.codDeliveryCharge,
    prepaidCharge: widget.prepaidDeliveryCharge,
  );

  String get totalPrice {
    double basePrice;
    if (widget.isSubscription) {
      basePrice = CheckoutCalculator.subscriptionBasePrice(
        widget.price,
        widget.quantity,
      );
    } else {
      if (widget.cart != null) {
        basePrice = CheckoutCalculator.cartBasePrice(widget.cart);
      } else if (widget.singleProduct != null) {
        basePrice = CheckoutCalculator.singleProductBasePrice(
          widget.singleProduct!.finalPrice,
          widget.quantity,
        );
      } else {
        basePrice = 0.0;
      }
    }
    return CheckoutCalculator.total(
      basePrice,
      currentDeliveryCharge,
    ).toString();
  }

  @override
  void initState() {
    super.initState();
    // Removed broken animations
    if (widget.isSubscription) {
      _selectedPaymentType = 'PAID_FULL';
      _selectedPaymentMethod = 'COD';
    } else {
      _selectedPaymentType = 'FULL';
      _selectedPaymentMethod = 'COD';
    }

    _initializeCheckout();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // --- ALL LOGIC METHODS (PRESERVED) ---

  Future<void> _initializeCheckout() async {
    if (widget.shippingDetails != null) {
      await _prepareShippingDetails();
    } else {
      await _loadShippingDetails();
    }

    if (widget.isSubscription) {
      await _fetchPlansAndAssign();
    }

    // Fetch pending rewards count
    await _fetchPendingRewards();

    _setLoadingState(false);
  }

  Future<void> _fetchPendingRewards() async {
    final count = await _rewardService.getPendingRewardsCount();
    if (mounted) {
      setState(() => _pendingRewardsCount = count);
    }
  }

  Future<void> _prepareShippingDetails() async {
    if (widget.shippingDetails != null) {
      _shippingDetails = ShippingDetails(
        address: widget.shippingDetails!['address'] ?? '',
        name: widget.shippingDetails!['name'] ?? '',
        city: widget.shippingDetails!['city'] ?? '',
        state: widget.shippingDetails!['state'] ?? '',
        pincode: widget.shippingDetails!['pincode'] ?? '',
        phone: widget.shippingDetails!['phone'] ?? '',
      );
      _useExistingAddress = false;
    }
  }

  bool _validateShipping() {
    if (_shippingDetails == null) {
      SnackBarHelper.showError(context, 'Please fill in shipping details');
      return false;
    }

    if (!_shippingDetails!.isComplete) {
      SnackBarHelper.showError(context, 'Please fill in all shipping details');
      return false;
    }

    return true;
  }

  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        if (loading) _error = null;
      });
    }
  }

  Future<void> _createOrder() async {
    HapticFeedback.mediumImpact();
    if (!_validateShipping()) return;

    _setLoadingState(true);

    try {
      if (widget.isSubscription) {
        _selectedPaymentMethod = 'COD';
        _selectedPaymentType = 'PAID_FULL';
      }

      if (_selectedPaymentMethod == 'UPI') {
        await _handleUPIPayment();
      } else {
        await _handleNonUPIPayment();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _handleUPIPayment() async {
    if (widget.isSubscription) {
      await _handleUPISubscription();
    } else {
      await _handleUPIOrder();
    }
  }

  Future<void> _handleUPISubscription() async {
    final result = await _createSubscription();

    if (!mounted) return;

    if (result['success'] == true) {
      if (result['payment_links'] != null) {
        if (result['payment_links']['web'] != null) {
          await _launchSubscriptionWebView(result);
        } else {
          _showSubscriptionFailedDialog({
            'message':
                'We couldn\'t start the payment process. Please check your connection and try again.',
          });
        }
      } else {
        _showSubscriptionFailedDialog({
          'message':
              'We couldn\'t start the payment process. Please check your connection and try again.',
        });
      }
    } else {
      _showSubscriptionFailedDialog(result);
    }
  }

  Future<void> _handleNonUPISubscription() async {
    final result = await _createSubscription();

    if (!mounted) return;

    if (result['success'] == true) {
      await _handleSuccessfulSubscription(result);
    } else {
      _showSubscriptionFailedDialog(result);
    }
  }

  Future<void> _handleSuccessfulSubscription(
    Map<String, dynamic> result,
  ) async {
    try {
      if (result['subscription_id'] != null) {
        int parsedSubscriptionId;
        try {
          parsedSubscriptionId = int.parse(
            result['subscription_id'].toString(),
          );
        } catch (e) {
          _showSubscriptionSuccessMessage(result);
          return;
        }

        final subscriptionDetails = await _subscriptionService
            .getSubscriptionDetails(parsedSubscriptionId);

        if (subscriptionDetails['success'] == true && mounted) {
          _navigateToSubscriptionDetails(subscriptionDetails['data']);
        } else {
          _showSubscriptionSuccessMessage(result);
        }
      } else {
        _showSubscriptionSuccessMessage(result);
      }
    } catch (e) {
      _showSubscriptionSuccessMessage(result);
    }
  }

  void _showSubscriptionSuccessMessage(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Subscription Created'),
            content: const Text(
              'Your subscription has been created successfully!',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (result['subscription_id'] != null) {
                    try {
                      int subId = int.parse(
                        result['subscription_id'].toString(),
                      );
                      context.goNamed(
                        AppRoute.subscriptionDetails.name,
                        pathParameters: {'id': subId.toString()},
                      );
                    } catch (e) {
                      context.go(AppRoute.home.path);
                    }
                  } else {
                    context.go(AppRoute.home.path);
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _handleUPIOrder() async {
    final order = _createOrderModel();
    final response = await _orderService.createOrder(order);

    if (!mounted) return;

    if (response is OrderCreateResponse &&
        response.success &&
        response.paymentLinks?.web != null) {
      await _launchOrderWebView(response);
    } else if (response is OrderCreateResponse && !response.success) {
      _showOrderFailedDialog(
        _parseServerError(response.message ?? 'Payment initiation failed.'),
      );
    } else {
      // Missing payment_links means the third party gateway failed to initialize.
      _showOrderFailedDialog(
        'We couldn\'t start the payment process. Please check your connection and try again.',
      );
    }
  }

  Future<void> _handleNonUPIOrder() async {
    final order = _createOrderModel();
    final createdOrder = await _orderService.createOrder(order);

    if (!mounted) return;

    _navigateToOrderAccepted(createdOrder);
  }

  Future<void> _handleNonUPIPayment() async {
    if (widget.isSubscription) {
      await _handleNonUPISubscription();
    } else {
      await _handleNonUPIOrder();
    }
  }

  /// Validates subscription request payload before API call
  ///
  /// Expected API Request Format:
  /// ```json
  /// {
  ///   "plan": 4,
  ///   "delivery_address": "Village Bhurri",
  ///   "delivery_city": "Sonipat",
  ///   "delivery_state": "Haryana",
  ///   "delivery_pincode": "131101",
  ///   "delivery_phone": "7027277570",
  ///   "recipient_name": "Hemant",
  ///   "payment_type": "PAID_FULL|INSTALLMENT",
  ///   "payment_method": "COD|UPI",
  ///   "delivery_fee": 127.00,
  ///   "expected_delivery_date": "2025-10-15",
  ///   "items": [
  ///     {
  ///       "product_variant_id": 6,
  ///       "quantity": 1
  ///     }
  ///   ]
  /// }
  /// ```
  ///
  /// Authentication: Bearer token automatically added via AuthInterceptor
  /// Response: Returns subscription object with payment_links for UPI or direct subscription for COD
  Map<String, dynamic> _validateSubscriptionPayload() {
    assert(_shippingDetails != null, 'Shipping details must not be null');
    assert(widget.selectedPlan != null, 'Plan must be selected');
    assert(widget.singleProduct != null, 'Product must be selected');
    assert(
      widget.quantity != null && widget.quantity! > 0,
      'Quantity must be greater than 0',
    );

    return {
      'plan': widget.selectedPlan,
      'delivery_address': _shippingDetails!.address,
      'delivery_city': _shippingDetails!.city ?? "",
      'delivery_state': _shippingDetails!.state ?? "",
      'delivery_pincode': _shippingDetails!.pincode ?? "",
      'delivery_phone': _shippingDetails!.phone ?? "",
      'recipient_name': _shippingDetails!.name,
      'payment_type': _selectedPaymentType, // PAID_FULL or INSTALLMENT
      'payment_method': _selectedPaymentMethod, // COD or UPI
      'delivery_fee': currentDeliveryCharge,
      'expected_delivery_date': widget.expectedDeliveryDate,
      'product_variant_id': widget.singleProduct!.id,
      'quantity': widget.quantity,
    };
  }

  /// Creates subscription via API with authentication token
  /// Token is automatically added by AuthInterceptor
  ///
  /// Expected Response (Success):
  /// ```json
  /// {
  ///   "id": 4,
  ///   "plan": 4,
  ///   "plan_name": "SIDDH",
  ///   "status": "ACTIVE",
  ///   "payment_status": "PAID_FULL",
  ///   ...full subscription details...
  /// }
  /// ```
  Future<Map<String, dynamic>> _createSubscription() async {
    try {
      // Validate payload structure
      _validateSubscriptionPayload();

      // Build request with all required fields
      final request = SubscriptionCreateRequest(
        plan: widget.selectedPlan,
        deliveryAddress: _shippingDetails!.address,
        deliveryName: _shippingDetails!.name,
        deliveryCity: _shippingDetails!.city ?? "",
        deliveryState: _shippingDetails!.state ?? "",
        deliveryPincode: _shippingDetails!.pincode ?? "",
        deliveryPhone: _shippingDetails!.phone ?? "",
        paymentType: _selectedPaymentType,
        paymentMethod: _selectedPaymentMethod,
        deliveryFee: currentDeliveryCharge,
        expectedDeliveryDate: widget.expectedDeliveryDate,
        items: [
          SubscriptionCreateItem(
            productVariantId: widget.singleProduct!.id,
            quantity: widget.quantity!,
          ),
        ],
      );

      // Log request payload for debugging
      AppLogger.instance.log(
        'Creating subscription with payload: ${request.toJson()}',
      );

      // API call with automatic bearer token via AuthInterceptor
      final result = await _subscriptionService.createSubscription(request);

      // Log response for debugging
      AppLogger.instance.log('Subscription response: $result');

      return result;
    } catch (e, stackTrace) {
      AppLogger.instance.log(
        'Error creating subscription: $e\nStackTrace: $stackTrace',
      );
      return {
        'success': false,
        'message': 'Error creating subscription',
        'error': e.toString(),
      };
    }
  }

  OrderModel _createOrderModel() {
    return OrderModel.fromShippingDetails(
      paymentMethod: _selectedPaymentMethod,
      shippingDetails: _shippingDetails!,
      // expectedDeliveryDate: widget.expectedDeliveryDate,
      // deliveryFee: currentDeliveryCharge,
      items: _getOrderItems(),
      notes: null,
    );
  }

  Future<void> _launchSubscriptionWebView(Map<String, dynamic> result) async {
    try {
      final paymentUrl = result['payment_links']['web'];
      final subscriptionId = result['subscription_id'];
      final merchantTransactionId =
          result['merchant_transaction_id'] as String?;

      if (subscriptionId == null) {
        throw Exception('Subscription ID is null');
      }

      int parsedSubscriptionId;
      try {
        parsedSubscriptionId = int.parse(subscriptionId.toString());
      } catch (e) {
        throw Exception('Invalid subscription ID format: $subscriptionId');
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        AnimatedTransitions.slideFromBottom(
          WebViewPage(
            url: paymentUrl,
            orderId: parsedSubscriptionId,
            title: 'Secure Payment',
            subID: parsedSubscriptionId,
            isSubscription: widget.isSubscription,
            merchantTransactionId: merchantTransactionId,
            onPaymentSuccess: (url) async {
              try {
                // Verify payment status first (robust check transferred from WebViewPage)
                final subscriptionStatus = await _subscriptionService
                    .fetchSubscriptionPaymentStatus(parsedSubscriptionId);

                if (subscriptionStatus != null &&
                    (subscriptionStatus.transactionStatus == 'SUCCESS' ||
                        subscriptionStatus.transactionStatus == 'ACTIVE')) {
                  final subscriptionDetails = await _subscriptionService
                      .getSubscriptionDetails(parsedSubscriptionId);

                  if (subscriptionDetails['success'] == true && mounted) {
                    Navigator.pop(context); // Close WebView
                    context.goNamed(
                      AppRoute.subscriptionDetails.name,
                      pathParameters: {'id': parsedSubscriptionId.toString()},
                      extra: subscriptionDetails['data'],
                    );
                  } else {
                    Navigator.pop(context);
                    _showSubscriptionSuccessMessage(result);
                  }
                } else {
                  Navigator.pop(context);
                  // If verification failed but we got a success URL, we might want to tell the user to check later
                  // or just show the generic success message if we think it might be a lag.
                  // But for now, let's treat it as a potential issue or just fall back to generic message.
                  _showSubscriptionSuccessMessage(result);
                }
              } catch (e) {
                Navigator.pop(context);
                _showSubscriptionSuccessMessage(result);
              }
            },
            onPaymentFailure: (url) {
              Navigator.pop(context);

              SnackBarHelper.showPaymentIssue(context);
            },
          ),
        ),
      );
    } catch (e) {
      SnackBarHelper.showError(context, 'Failed to launch payment page: $e');
    }
  }

  Future<void> _launchOrderWebView(OrderCreateResponse response) async {
    final paymentUrl = response.paymentLinks!.web;

    Navigator.push(
      context,
      AnimatedTransitions.slideFromBottom(
        WebViewPage(
          url: paymentUrl,
          orderId: int.parse(response.orderId!),
          title: 'Secure Payment',
          onPaymentSuccess: (url) async {
            await _verifyAndHandlePaymentSuccess(response);
          },
          onPaymentFailure: (url) {
            Navigator.pop(context);
            SnackBarHelper.showError(context, 'Payment failed or cancelled');
          },
        ),
      ),
    );
  }

  Future<void> _verifyAndHandlePaymentSuccess(
    OrderCreateResponse response,
  ) async {
    try {
      final paymentStatus = await _orderService.fetchPaymentStatus(
        int.parse(response.orderId!),
      );

      if (paymentStatus.paymentStatus == 'PAID' &&
          paymentStatus.transactionStatus == 'SUCCESS') {
        final order = await _orderService.getOrderById(paymentStatus.orderId);

        Navigator.pop(context); // Close WebView
        context.goNamed(
          AppRoute.orderDetails.name,
          pathParameters: {'id': order.id.toString()},
          extra: order,
        );
      } else {
        if (mounted) Navigator.pop(context);
        if (mounted)
          SnackBarHelper.showError(context, 'Payment not successful!');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted)
        SnackBarHelper.showError(context, 'Failed to verify payment!');
    }
  }

  void _navigateToSubscriptionDetails(dynamic subscription) {
    String idStr;
    if (subscription is Subscription) {
      idStr = subscription.id.toString();
    } else if (subscription is Map) {
      idStr = subscription['id'].toString();
    } else {
      idStr = subscription.toString();
    }
    context.goNamed(
      AppRoute.subscriptionDetails.name,
      pathParameters: {'id': idStr},
      extra: subscription,
    );
  }

  void _navigateToOrderAccepted(Order order) {
    context.goNamed(
      AppRoute.orderDetails.name,
      pathParameters: {'id': order.id.toString()},
      extra: order,
    );
  }

  void _showSubscriptionFailedDialog(Map<String, dynamic> result) {
    String errorMessage = _parseServerError(
      result['message'] ?? result['errors'] ?? 'Failed to create subscription',
    );

    // Add detailed error information
    if (result['error'] != null) {
      errorMessage += '\n\nDetails: ${result['error']}';
    }

    // Add validation errors if present
    if (result['errors'] is Map && (result['errors'] as Map).isNotEmpty) {
      final errors = result['errors'] as Map;
      String errorDetails = '';
      errors.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          errorDetails += '\n• $key: ${value.join(', ')}';
        } else {
          errorDetails += '\n• $key: $value';
        }
      });
      if (errorDetails.isNotEmpty) {
        errorMessage += '\n\nValidation Errors:$errorDetails';
      }
    }

    AppLogger.instance.log('Subscription error - Full response: $result');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Subscription Failed'),
            content: SingleChildScrollView(child: Text(errorMessage)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
    );
  }

  void _showOrderFailedDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OrderFailedDialog(error: error);
      },
    );
  }

  void _handleError(dynamic error) {
    if (!mounted) return;

    setState(() {
      _error = _parseServerError(error);
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OrderFailedDialog(error: _error);
      },
    );
  }

  Future<void> _fetchPlansAndAssign() async {
    final result = await _subscriptionService.getSubscriptionPlans();
    if (result['success'] == true && mounted) {
      setState(() {
        planDescriptions = result['data'] as List<SubscriptionPlan>;
        if (planDescriptions.isNotEmpty &&
            widget.selectedPlan! > 0 &&
            widget.selectedPlan! <= planDescriptions.length) {
          subscription =
              planDescriptions.where((p) => p.id == widget.selectedPlan).first;
        }
      });
    }
  }

  Future<void> _loadShippingDetails() async {
    try {
      final details = await _orderService.getUserShippingDetails();
      if (mounted) {
        setState(() {
          _shippingDetails = details;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  List<OrderItem> _getOrderItems() {
    if (widget.cart != null) {
      return widget.cart!.items
          .map(
            (item) => OrderItem(
              productVariantId: item.productVariant.id,
              quantity: item.quantity,
            ),
          )
          .toList();
    } else {
      return [
        OrderItem(
          productVariantId: widget.singleProduct!.id,
          quantity: widget.quantity!,
        ),
      ];
    }
  }

  String _parseServerError(dynamic error) {
    if (error is String) {
      return error;
    }

    if (error is Map<String, dynamic>) {
      if (error.containsKey('items') && error['items'] is List) {
        List<String> itemErrors = [];
        for (var item in error['items']) {
          if (item is Map<String, dynamic>) {
            item.forEach((key, value) {
              if (value is List) {
                itemErrors.addAll(value.map((e) => e.toString()));
              } else if (value is String) {
                itemErrors.add(value);
              }
            });
          }
        }
        if (itemErrors.isNotEmpty) {
          return itemErrors.join('\n');
        }
      }

      if (error.containsKey('message')) {
        return error['message'];
      }

      if (error.containsKey('errors')) {
        var errors = error['errors'];
        if (errors is Map<String, dynamic>) {
          List<String> errorMessages = [];
          errors.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.map((e) => e.toString()));
            } else if (value is String) {
              errorMessages.add(value);
            }
          });
          return errorMessages.join('\n');
        } else if (errors is String) {
          return errors;
        }
      }
    }

    return error.toString();
  }

  // --- MODERN UI BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Animated Header
              _buildAnimatedHeader(theme, isDark),

              // Content
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDeliveryTimeCard(theme, isDark),
                        const SizedBox(height: 16),
                        if (_shippingDetails != null)
                          _buildShippingAddressCard(theme, isDark),
                        const SizedBox(height: 16),
                        if (widget.isSubscription && subscription != null)
                          _buildCongratulationCard(theme, subscription!),
                        const SizedBox(height: 16),
                        _buildOrderSummaryCard(theme, isDark),
                        const SizedBox(height: 16),
                        if (_pendingRewardsCount > 0)
                          _buildRewardNotificationCard(theme, isDark),
                        const SizedBox(height: 16),
                        _buildPaymentMethodCard(theme, isDark),
                        const SizedBox(height: 180),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Bottom Bar
          if (!_isLoading) _buildBottomBar(theme, isDark),

          // Loading Overlay
          if (_isLoading) _buildLoadingOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        constraints: const BoxConstraints(minHeight: 180),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.harvestAmber,
              AppColors.harvestAmber.withValues(alpha: 0.85),
              isDark
                  ? AppColors.harvestAmber.withValues(alpha: 0.7)
                  : AppColors.harvestAmber,
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.harvestAmber.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ANAAD Logo
                const AnaadLogoMark(),
                const SizedBox(height: 24),
                // Title Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.parchment.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.isSubscription
                            ? Icons.card_membership_rounded
                            : Icons.shopping_bag_rounded,
                        color: AppColors.amberWarnBg,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.isSubscription
                                  ? "Subscription"
                                  : "Checkout",
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: AppColors.parchment,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$totalItems item${totalItems > 1 ? 's' : ''} ready to order",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.parchment.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Removed unused _buildFloatingParticle

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.parchment.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.parchment, size: 22),
        ),
      ),
    );
  }

  Widget _buildRewardNotificationCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.parchment.withValues(alpha: 0.9),
            AppColors.parchment.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.parchment.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.parchment.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.harvestAmber,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎁 Rewards Waiting!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.parchment,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _pendingRewardsCount == 1
                      ? 'You have 1 referral reward waiting in your orders!'
                      : 'You have $_pendingRewardsCount referral rewards waiting in your orders!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.parchment.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.parchment.withValues(alpha: 0.7),
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.deepSoilGreen.withValues(alpha: 0.15),
            AppColors.deepSoilGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.deepSoilGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.deepSoilGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: AppColors.harvestAmber,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Delivery',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.expectedDeliveryDate,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.harvestAmber,
                  ),
                ),
              ],
            ),
          ),
          if (currentDeliveryCharge == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.deepSoilGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'FREE',
                style: TextStyle(
                  color: AppColors.parchment,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShippingAddressCard(ThemeData theme, bool isDark) {
    if (_shippingDetails == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.harvestAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Delivery Address',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.amberWarn,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: AppColors.amberWarn,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name and Address
          if (_shippingDetails?.name.isNotEmpty ?? false) ...[
            Text(
              _shippingDetails!.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(_shippingDetails!.address, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            '${_shippingDetails!.city}, ${_shippingDetails!.state} - ${_shippingDetails!.pincode}',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone_rounded, size: 16, color: theme.hintColor),
              const SizedBox(width: 6),
              Text(
                _shippingDetails!.phone,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCongratulationCard(
    ThemeData theme,
    SubscriptionPlan subscription,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.parchment.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: AppColors.harvestAmber,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Great Choice!",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.parchment,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Your ${subscription.durationMonths}-month journey to wellness begins here.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.parchment.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: AppColors.harvestAmber,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                widget.isSubscription
                    ? 'Subscription Summary'
                    : 'Order Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Subscription delivery info banner
          if (widget.isSubscription && subscription != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.deepSoilGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.deepSoilGreen),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.autorenew_rounded,
                    color: AppColors.parchment,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Products delivered every month for ${subscription!.durationMonths} months',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.parchment,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Product Items
          if (widget.singleProduct != null)
            _buildProductItem(
              theme,
              isDark,
              widget.singleProduct!,
              widget.quantity!,
              widget.isSubscription
                  ? widget.price!
                  : widget.singleProduct!.finalPrice,
            )
          else
            ...widget.cart!.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildProductItem(
                  theme,
                  isDark,
                  item.productVariant,
                  item.quantity,
                  item.productVariant.finalPrice,
                ),
              ),
            ),

          const Divider(height: 32),

          // Price Breakdown
          if (widget.isSubscription && subscription != null) ...[
            // Subscription-specific breakdown
            _buildPriceRow(
              theme,
              'Unit Price (per item)',
              '₹${(widget.price ?? 0).toStringAsFixed(2)}',
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                'Exclusive discount added',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: AppColors.deepSoilGreen,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              theme,
              'Quantity (per month)',
              '× ${widget.quantity}',
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              theme,
              'Monthly Product Cost',
              '₹${((widget.price ?? 0) * (widget.quantity ?? 1)).toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              theme,
              'Delivery (per month)',
              currentDeliveryCharge > 0
                  ? '₹${currentDeliveryCharge.toStringAsFixed(2)}'
                  : 'FREE',
              isDelivery: true,
            ),
            const SizedBox(height: 8),
            // _buildPriceRow(
            //   theme,
            //   'Discount Applied',
            //   '-${subscription!.discountPercentage.toStringAsFixed(0)}%',
            //   isDiscount: true,
            // ),
          ] else ...[
            // Regular order breakdown
            _buildPriceRow(
              theme,
              'Subtotal',
              '₹${(double.parse(totalPrice) - currentDeliveryCharge).toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              theme,
              'Delivery Charges',
              currentDeliveryCharge > 0
                  ? '₹${currentDeliveryCharge.toStringAsFixed(2)}'
                  : 'FREE',
              isDelivery: true,
            ),
          ],

          const Divider(height: 32),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isSubscription ? 'Monthly Total' : 'Total Amount',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.isSubscription && subscription != null)
                    Text(
                      'Billed each month',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              Text(
                '₹${double.parse(totalPrice).toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.harvestAmber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Total subscription cost hint
          if (widget.isSubscription && subscription != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.deepSoilGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.deepSoilGreen),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.savings_rounded,
                    color: AppColors.harvestAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Total over ${subscription!.durationMonths} months: ₹${(double.parse(totalPrice) * subscription!.durationMonths).toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.harvestAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductItem(
    ThemeData theme,
    bool isDark,
    Product product,
    int quantity,
    double price,
  ) {
    String? imageUrl =
        product.productImages.isNotEmpty
            ? product.productImages[0].image
            : null;

    final bool hasDiscount = product.price > price;

    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isDark ? AppColors.charcoal : AppColors.parchment,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                imageUrl != null
                    ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget:
                          (context, url, error) => Icon(
                            Icons.shopping_bag_outlined,
                            color: theme.disabledColor,
                          ),
                    )
                    : Icon(
                      Icons.shopping_bag_outlined,
                      color: theme.disabledColor,
                    ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.productName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Qty: $quantity',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${price.toStringAsFixed(2)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    ThemeData theme,
    String label,
    String value, {
    bool isDelivery = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color:
                isDiscount
                    ? AppColors.deepSoilGreen
                    : isDelivery && value == 'FREE'
                    ? AppColors.deepSoilGreen
                    : null,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showPaymentMethodSelectionDialog();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _selectedPaymentMethod == 'COD'
                    ? Icons.money_rounded
                    : Icons.payment_rounded,
                color: AppColors.harvestAmber,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedPaymentMethod == 'COD'
                        ? 'Cash on Delivery'
                        : 'UPI / Card / NetBanking',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal87 : AppColors.parchment,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: theme.hintColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, bool isDark) {
    if (widget.isSubscription && subscription != null) {
      return _buildSubscriptionBottomBar(theme, isDark, subscription!);
    } else {
      return _buildStandardBottomBar(theme, isDark);
    }
  }

  Widget _buildStandardBottomBar(ThemeData theme, bool isDark) {
    final total = double.parse(totalPrice);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : AppColors.parchment,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.harvestAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _createOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: AppColors.parchment,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Place Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
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

  Widget _buildSubscriptionBottomBar(
    ThemeData theme,
    bool isDark,
    SubscriptionPlan subscription,
  ) {
    final totalMonthlyPrice = double.tryParse(totalPrice) ?? 0.0;
    final fullSubscriptionPrice =
        totalMonthlyPrice * subscription.durationMonths;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : AppColors.parchment,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.charcoal60 : AppColors.rawEarth12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.card_membership_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${subscription.durationMonths}-Month Plan',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _selectedPaymentType == 'PAID_FULL'
                              ? 'One-time payment'
                              : 'Monthly installments',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${fullSubscriptionPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _createOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: AppColors.parchment,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Subscribe Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPaymentMethodSelectionDialog() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String? newSelection = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.charcoal60 : AppColors.rawEarth12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Select Payment Method',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (widget.isSubscription) ...[
                _buildPaymentOption(
                  theme,
                  isDark,
                  'COD',
                  'Cash on Delivery',
                  'Pay when you receive your subscription',
                  Icons.money_rounded,
                  AppColors.harvestAmber,
                ),
              ] else ...[
                _buildPaymentOption(
                  theme,
                  isDark,
                  'COD',
                  'Cash on Delivery',
                  'Pay when you receive your order',
                  Icons.money_rounded,
                  AppColors.harvestAmber,
                ),
                const SizedBox(height: 12),
                _buildPaymentOption(
                  theme,
                  isDark,
                  'UPI',
                  'Pay Online',
                  'UPI / Card / NetBanking',
                  Icons.payment_rounded,
                  theme.colorScheme.primary,
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );

    if (newSelection != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedPaymentMethod = newSelection;
      });
    }
  }

  Widget _buildPaymentOption(
    ThemeData theme,
    bool isDark,
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? color
                    : (isDark ? AppColors.charcoal87 : AppColors.parchment),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(
                  Icons.check,
                  color: AppColors.parchment,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme) {
    return Container(
      color: AppColors.charcoal.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Processing your order...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- GLOBAL HELPER WIDGETS ---

extension on String {
  String toStringAsFixed(int i) {
    return double.tryParse(this)?.toStringAsFixed(i) ?? this;
  }
}
