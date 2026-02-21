// ignore_for_file: unused_element

import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/routes/app_routes.dart';
import 'package:grocery_app/services/referral_reward_service.dart';

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

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
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
  String _selectedPaymentMethod = 'UPI';
  bool _useExistingAddress = true;
  late String _selectedPaymentType;
  int _pendingRewardsCount = 0;

  // Animation Controllers
  late AnimationController _headerController;
  late AnimationController _contentController;
  late AnimationController _particleController;
  late AnimationController _bottomBarController;

  late Animation<double> _headerSlide;
  late Animation<double> _headerFade;
  late Animation<double> _contentFade;
  late Animation<double> _bottomBarSlide;

  int get totalItems => widget.cart?.totalItems ?? widget.quantity!;
  double get currentDeliveryCharge {
    return _selectedPaymentMethod == 'COD'
        ? widget.codDeliveryCharge
        : widget.prepaidDeliveryCharge;
  }

  String get totalPrice {
    double basePrice;
    if (widget.isSubscription) {
      basePrice = (widget.price ?? 0.0) * (widget.quantity ?? 1);
    } else {
      basePrice =
          widget.cart?.totalPrice != null
              ? double.parse(widget.cart!.totalPrice)
              : (widget.singleProduct!.finalPrice * widget.quantity!);
    }
    return (basePrice + currentDeliveryCharge).toString();
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();

    if (widget.isSubscription) {
      _selectedPaymentType = widget.paymentType ?? 'PAID_FULL';
    } else {
      _selectedPaymentType = 'FULL';
    }

    _initializeCheckout();
  }

  void _initAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _bottomBarController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _headerSlide = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _bottomBarSlide = Tween<double>(begin: 100, end: 0).animate(
      CurvedAnimation(parent: _bottomBarController, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    _particleController.dispose();
    _bottomBarController.dispose();
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
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _bottomBarController.forward();
    });
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
          await _handleSuccessfulSubscription(result);
        }
      } else {
        await _handleSuccessfulSubscription(result);
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

      NotificationHelper.showNotification(
        title: 'Subscription Created!',
        body:
            'Subscription ID: ${result['subscription_id']}\n'
            'Payment Mode: Cash on Delivery\n'
            'Status: Pending Payment',
        payload: json.encode({
          'screen': 'subscription_detail',
          'subscription_id': result['subscription_id'],
          'type': 'subscription',
        }),
      );
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
                  Navigator.of(context).pop();
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
    } else if (response is Order) {
      _navigateToOrderAccepted(response);

      NotificationHelper.showNotification(
        title: 'Order Created!',
        body:
            'Order ID: ${response.orderNumber}\n'
            'Payment Mode: Cash on Delivery\n'
            'Status: Pending Payment',
        payload: json.encode({
          'screen': 'order_tracking',
          'order_id': response.id,
          'type': 'order',
        }),
      );
    } else {
      _showOrderFailedDialog(_parseServerError(response));
    }
  }

  Future<void> _handleNonUPIOrder() async {
    final order = _createOrderModel();
    final createdOrder = await _orderService.createOrder(order);

    if (!mounted) return;

    _navigateToOrderAccepted(createdOrder);

    NotificationHelper.showNotification(
      title: 'Order Created!',
      body:
          'Order ID: ${createdOrder.orderNumber}\n'
          'Payment Mode: Cash on Delivery\n'
          'Status: Pending Payment',
      payload: json.encode({
        'screen': 'order_tracking',
        'order_id': createdOrder.id,
        'type': 'order',
      }),
    );
  }

  Future<void> _handleNonUPIPayment() async {
    if (widget.isSubscription) {
      await _handleNonUPISubscription();
    } else {
      await _handleNonUPIOrder();
    }
  }

  Future<Map<String, dynamic>> _createSubscription() async {
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

    return await _subscriptionService.createSubscription(request);
  }

  OrderModel _createOrderModel() {
    return OrderModel.fromShippingDetails(
      paymentMethod: _selectedPaymentMethod,
      shippingDetails: _shippingDetails!,
      expectedDeliveryDate: widget.expectedDeliveryDate,
      deliveryFee: currentDeliveryCharge,
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
            title: 'UPI Payment',
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
                    NotificationHelper.showNotification(
                      title: 'Payment Successful!',
                      body:
                          'Subscription ID: $parsedSubscriptionId\n'
                          'Payment Mode: UPI\n'
                          'Status: Paid',
                      payload: json.encode({
                        'screen': 'subscription_detail',
                        'subscription_id': parsedSubscriptionId,
                        'type': 'subscription',
                      }),
                    );

                    Navigator.pushAndRemoveUntil(
                      context,
                      AnimatedTransitions.fadeScale(
                        SubscriptionPlanDetailScreen(
                          subscription: subscriptionDetails['data'],
                        ),
                      ),
                      (route) => route.isFirst,
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

              NotificationHelper.showNotification(
                title: 'Payment Failed!',
                body:
                    'Subscription ID: $parsedSubscriptionId\n'
                    'Payment Mode: UPI\n'
                    'Status: Failed',
                payload: json.encode({
                  'screen': 'subscription_detail',
                  'subscription_id': parsedSubscriptionId,
                  'type': 'subscription',
                }),
              );

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
          title: 'UPI Payment',
          onPaymentSuccess: (url) async {
            await _verifyAndHandlePaymentSuccess(response);
          },
          onPaymentFailure: (url) {
            Navigator.pop(context);
            NotificationHelper.showNotification(
              title: 'Payment Failed!',
              body:
                  'Order ID: ${response.orderId}\n'
                  'Payment Mode: UPI\n'
                  'Status: Failed',
              payload: json.encode({
                'screen': 'order_tracking',
                'order_id': response.orderId,
                'type': 'order',
              }),
            );
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

        NotificationHelper.showNotification(
          title: 'Payment Successful!',
          body:
              'Order ID: ${response.orderId}\n'
              'Payment Mode: UPI\n'
              'Status: Paid',
          payload: json.encode({
            'screen': 'order_tracking',
            'order_id': response.orderId,
            'type': 'order',
          }),
        );

        context.replaceNamed(
          AppRoute.orderDetails.name,
          pathParameters: {'id': order.id.toString()},
          extra: order,
        );
      } else {
        Navigator.pop(context);
        SnackBarHelper.showError(context, 'Payment not successful!');
      }
    } catch (e) {
      Navigator.pop(context);
      SnackBarHelper.showError(context, 'Failed to verify payment!');
    }
  }

  void _navigateToSubscriptionDetails(dynamic subscription) {
    context.go(AppRoute.home.path);
    context.pushNamed(
      AppRoute.subscriptionDetails.name,
      pathParameters: {'id': subscription['id'].toString()},
      extra: subscription,
    );
  }

  void _navigateToOrderAccepted(Order order) {
    context.replaceNamed(
      AppRoute.orderDetails.name,
      pathParameters: {'id': order.id.toString()},
      extra: order,
    );
  }

  void _showSubscriptionFailedDialog(Map<String, dynamic> result) {
    String errorMessage = _parseServerError(
      result['message'] ?? result['errors'] ?? 'Failed to create subscription',
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Subscription Failed'),
            content: Text(errorMessage),
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
                  child: AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - _contentFade.value)),
                        child: Opacity(
                          opacity: _contentFade.value,
                          child: child,
                        ),
                      );
                    },
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
      child: AnimatedBuilder(
        animation: _headerController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _headerSlide.value),
            child: Opacity(opacity: _headerFade.value, child: child),
          );
        },
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.85),
                isDark
                    ? theme.colorScheme.primary.withValues(alpha: 0.7)
                    : Colors.green.shade400,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Floating Particles
              ...List.generate(8, (index) => _buildFloatingParticle(index)),

              // Decorative circles
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // Header Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      _buildIconButton(Icons.arrow_back_ios_new_rounded, () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      }),
                      const Spacer(),
                      // Title Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              widget.isSubscription
                                  ? Icons.card_membership_rounded
                                  : Icons.shopping_bag_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isSubscription
                                      ? "Subscription"
                                      : "Checkout",
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$totalItems item${totalItems > 1 ? 's' : ''} ready to order",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = math.Random(index);
    final size = 4.0 + random.nextDouble() * 6;
    final startX = random.nextDouble() * 400;
    final startY = random.nextDouble() * 180;
    final duration = 10 + random.nextInt(10);

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value * duration) % 1.0;
        final x = startX + math.sin(progress * math.pi * 2 + index) * 20;
        final y = startY + math.cos(progress * math.pi * 2 + index) * 12;
        final opacity = 0.1 + (math.sin(progress * math.pi * 2) * 0.15);

        return Positioned(
          left: x,
          top: y,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: opacity.clamp(0.05, 0.25)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
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
            const Color(0xFFFF9800).withValues(alpha: 0.9),
            const Color(0xFFFFB74D).withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.3),
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
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Colors.white,
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _pendingRewardsCount == 1
                      ? 'You have 1 referral reward waiting in your orders!'
                      : 'You have $_pendingRewardsCount referral rewards waiting in your orders!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white.withValues(alpha: 0.7),
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
            Colors.green.withValues(alpha: 0.15),
            Colors.green.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.green,
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
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (currentDeliveryCharge == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'FREE',
                style: TextStyle(
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
                  color: theme.colorScheme.primary,
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
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: Colors.green.shade700,
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: Colors.white,
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Your ${subscription.durationMonths}-month journey to wellness begins here.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
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
                color: theme.colorScheme.primary,
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.autorenew_rounded,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Products delivered every month for ${subscription!.durationMonths} months',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade800,
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
                  color: Colors.green,
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
                  color: theme.colorScheme.primary,
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
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.savings_rounded,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Total over ${subscription!.durationMonths} months: ₹${(double.parse(totalPrice) * subscription!.durationMonths).toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade800,
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
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
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
                    ? Colors.green
                    : isDelivery && value == 'FREE'
                    ? Colors.green
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
                color: theme.colorScheme.primary,
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
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
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
      child: AnimatedBuilder(
        animation: _bottomBarController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bottomBarSlide.value),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.15),
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
                          color: theme.colorScheme.primary,
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
                        foregroundColor: Colors.white,
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
      child: AnimatedBuilder(
        animation: _bottomBarController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bottomBarSlide.value),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.15),
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
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
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
                            widget.paymentType == 'PAID_FULL'
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
                      foregroundColor: Colors.white,
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
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
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
              if (!widget.isSubscription) ...[
                _buildPaymentOption(
                  theme,
                  isDark,
                  'COD',
                  'Cash on Delivery',
                  'Pay when you receive your order',
                  Icons.money_rounded,
                  Colors.orange,
                ),
                const SizedBox(height: 12),
              ],
              _buildPaymentOption(
                theme,
                isDark,
                'UPI',
                'Pay Online',
                'UPI / Card / NetBanking',
                Icons.payment_rounded,
                theme.colorScheme.primary,
              ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? color
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
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
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme) {
    return Container(
      color: Colors.black.withOpacity(0.3),
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
