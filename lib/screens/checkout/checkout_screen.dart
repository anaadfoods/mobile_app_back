// ignore_for_file: unused_element

import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/common_widgets/error_dialog.dart';
import 'package:grocery_app/routes/app_routes.dart';
import 'package:grocery_app/services/referral_reward_service.dart';
import 'package:grocery_app/utils/checkout_calculator.dart';
import 'package:grocery_app/service_locator.dart';

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
  final OrderService _orderService = getIt<OrderService>();
  // final CartService _cartService = CartService(); // Unused - commented out
  // final AuthService _authService = AuthService(); // Unused - commented out
  final SubscriptionService _subscriptionService = getIt<SubscriptionService>();
  final ReferralRewardService _rewardService = getIt<ReferralRewardService>();
  final PaymentService _paymentService = getIt<PaymentService>();

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
      _selectedPaymentType = widget.paymentType ?? 'PAID_FULL';
      _selectedPaymentMethod = 'UPI';
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

  /// Whether the selected payment method is an online (non-COD) method.
  bool get _isOnlinePayment => _selectedPaymentMethod != 'COD';

  Future<void> _createOrder() async {
    HapticFeedback.mediumImpact();
    if (!_validateShipping()) return;

    _setLoadingState(true);

    try {
      if (_isOnlinePayment) {
        await _handleOnlinePayment();
      } else {
        await _handleCODPayment();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _handleOnlinePayment() async {
    if (widget.isSubscription) {
      await _handleOnlineSubscription();
    } else {
      await _handleOnlineOrder();
    }
  }

  Future<void> _handleOnlineSubscription() async {
    final result = await _createSubscription();

    if (!mounted) return;

    if (result['success'] == true) {
      final checkoutUrl = result['checkout_url'];

      if (checkoutUrl != null) {
        await _launchSubscriptionWebView(result);
      } else if (result['payment_required'] == true) {
        _showSubscriptionFailedDialog({
          'message':
              result['payment_error'] ??
              'Payment initiation failed. Please try again.',
        });
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

  Future<void> _handleCODSubscription() async {
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
    if (result['subscription_id'] != null) {
      try {
        int subId = int.parse(result['subscription_id'].toString());
        _navigateToSubscriptionDetails(subId);
        return;
      } catch (_) {}
    }

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
                      context.goNamed(AppRoute.subscriptionList.name);
                      context.pushNamed(
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

  Future<void> _handleOnlineOrder() async {
    final order = _createOrderModel();
    final response = await _orderService.createOrder(order);

    if (!mounted) return;

    if (response is OrderCreateResponse && response.paymentRequired) {
      // Order created but payment initiation failed — show error with retry hint
      _showOrderFailedDialog(
        response.paymentError ?? 'Payment initiation failed. Please try again.',
      );
    } else if (response is OrderCreateResponse &&
        response.success &&
        response.checkoutUrl != null) {
      await _launchOrderWebView(response);
    } else if (response is OrderCreateResponse && !response.success) {
      _showOrderFailedDialog(
        _parseServerError(response.message ?? 'Payment initiation failed.'),
      );
    } else {
      // Missing checkout URL means the third party gateway failed to initialize.
      _showOrderFailedDialog(
        'We couldn\'t start the payment process. Please check your connection and try again.',
      );
    }
  }

  Future<void> _handleCODOrder() async {
    final order = _createOrderModel();
    final createdOrder = await _orderService.createOrder(order);

    if (!mounted) return;

    _navigateToOrderAccepted(createdOrder);
  }

  Future<void> _handleCODPayment() async {
    if (widget.isSubscription) {
      await _handleCODSubscription();
    } else {
      await _handleCODOrder();
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
      final paymentUrl = result['checkout_url'];
      final subscriptionId = result['subscription_id'];
      final subscriptionNumber =
          result['subscription_number']?.toString() ?? "";
      final merchantTransactionId =
          result['merchant_transaction_id'] as String?;

      if (paymentUrl == null) {
        throw Exception('Payment URL is null');
      }

      int parsedSubscriptionId = 0;
      if (subscriptionId != null) {
        try {
          parsedSubscriptionId = int.parse(subscriptionId.toString());
        } catch (_) {}
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
            reference: subscriptionNumber,
            onPaymentSuccess: (url) async {
              try {
                // Verify payment status first (robust check using PaymentService)
                PaymentStatusResponse? statusResponse;
                final ref =
                    subscriptionNumber.isNotEmpty
                        ? subscriptionNumber
                        : merchantTransactionId ??
                            parsedSubscriptionId.toString();
                statusResponse = await _paymentService.pollStatus(ref);

                if (statusResponse.isSuccess) {
                  int? subId;
                  try {
                    final subscriptionsResult =
                        await _subscriptionService.getSubscriptions();
                    if (subscriptionsResult['success'] == true) {
                      final subscriptions = List<Subscription>.from(
                        subscriptionsResult['data'],
                      );
                      final matchingSub = subscriptions.firstWhere(
                        (s) =>
                            s.subscriptionNumber == subscriptionNumber ||
                            (parsedSubscriptionId != 0 &&
                                s.id == parsedSubscriptionId),
                      );
                      subId = matchingSub.id;
                    }
                  } catch (e) {
                    AppLogger.instance.e("Error finding subscription: $e");
                  }

                  final targetId = subId ?? parsedSubscriptionId;
                  if (targetId == 0) {
                    Navigator.pop(context);
                    _showSubscriptionSuccessMessage(result);
                    return;
                  }

                  final subscriptionDetails = await _subscriptionService
                      .getSubscriptionDetails(targetId);

                  if (subscriptionDetails['success'] == true && mounted) {
                    Navigator.pop(context); // Close WebView
                    context.goNamed(AppRoute.subscriptionList.name);
                    context.pushNamed(
                      AppRoute.subscriptionDetails.name,
                      pathParameters: {'id': targetId.toString()},
                      extra: subscriptionDetails['data'],
                    );
                  } else {
                    Navigator.pop(context);
                    _showSubscriptionSuccessMessage(result);
                  }
                } else {
                  Navigator.pop(context);
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
    final paymentUrl = response.checkoutUrl!;
    final merchantTxnId = response.merchantTransactionId;
    final orderNumber = response.orderNumber ?? "";

    Navigator.push(
      context,
      AnimatedTransitions.slideFromBottom(
        WebViewPage(
          url: paymentUrl,
          orderId: 0, // Legacy field — order is identified by orderNumber now
          title: 'Secure Payment',
          merchantTransactionId: merchantTxnId,
          reference: orderNumber,
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
      // Use PaymentService polling for robust status verification
      final orderNumber = response.orderNumber ?? "";
      PaymentStatusResponse? statusResponse;

      if (orderNumber.isNotEmpty) {
        statusResponse = await _paymentService.pollStatus(orderNumber);
      } else {
        // Fallback to merchant transaction ID if order number is missing
        final txnId = response.merchantTransactionId;
        if (txnId != null && txnId.isNotEmpty) {
          statusResponse = await _paymentService.pollStatus(txnId);
        } else {
          throw Exception('No reference available for status polling');
        }
      }

      if (statusResponse.isSuccess) {
        int? orderId;
        try {
          final orders = await _orderService.getOrders();
          final matchingOrder = orders.firstWhere(
            (o) => o.orderNumber == orderNumber,
          );
          orderId = matchingOrder.id;
        } catch (e) {
          AppLogger.instance.e("Error finding order by order number: $e");
        }

        if (orderId == null || orderId == 0) {
          if (mounted) Navigator.pop(context);
          if (mounted) {
            SnackBarHelper.showInfo(
              context,
              'Payment successful! Order is placed.',
            );
            context.goNamed(AppRoute.orderList.name);
          }
          return;
        }

        final order = await _orderService.getOrderById(orderId);

        if (mounted) Navigator.pop(context); // Close WebView
        if (mounted) {
          context.goNamed(AppRoute.orderList.name);
          context.pushNamed(
            AppRoute.orderDetails.name,
            pathParameters: {'id': order.id.toString()},
            extra: order,
          );
        }
      } else if (statusResponse.isPending) {
        // Webhook hasn't arrived yet — tell user and navigate anyway
        if (mounted) Navigator.pop(context);
        if (mounted) {
          SnackBarHelper.showInfo(
            context,
            'Payment is being processed. We\'ll notify you once confirmed.',
          );
          context.goNamed(AppRoute.orderList.name);
        }
      } else {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          SnackBarHelper.showError(context, 'Payment not successful!');
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to verify payment!');
      }
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
    context.goNamed(AppRoute.subscriptionList.name);
    context.pushNamed(
      AppRoute.subscriptionDetails.name,
      pathParameters: {'id': idStr},
      extra:
          (subscription is Subscription || subscription is Map)
              ? subscription
              : null,
    );
  }

  void _navigateToOrderAccepted(Order order) {
    context.goNamed(AppRoute.orderList.name);
    context.pushNamed(
      AppRoute.orderDetails.name,
      pathParameters: {'id': order.id.toString()},
      extra: order,
    );
  }

  void _showSubscriptionFailedDialog(Map<String, dynamic> result) {
    final errorMessage = _parseServerError(result);
    AppLogger.instance.log('Subscription error - Full response: $result');

    showDialog(
      context: context,
      builder:
          (context) => ErrorDialog(
            title: 'Subscription Failed',
            message:
                errorMessage.isNotEmpty
                    ? errorMessage
                    : 'We couldn\'t create your subscription. Please try again.',
            icon: Icons.card_giftcard_rounded,
            iconColor: AppColors.harvestAmber,
            showCloseButton: true,
          ),
    );
  }

  void _showOrderFailedDialog(String error) {
    final cleanMsg = _parseServerError(error);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OrderFailedDialog(error: cleanMsg);
      },
    );
  }

  void _handleError(dynamic error) {
    if (!mounted) return;

    final cleanMsg = _parseServerError(error);
    setState(() {
      _error = cleanMsg;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OrderFailedDialog(error: cleanMsg);
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
    if (error == null) return 'An unexpected error occurred. Please try again.';

    final errorString = error.toString().toLowerCase();
    if (errorString.contains('method not allowed') ||
        (errorString.contains('post') && errorString.contains('not allowed')) ||
        errorString.contains('405')) {
      return 'Action not allowed. Please contact support.';
    }

    List<String> messages = [];

    if (error is Map) {
      final map = Map<String, dynamic>.from(error);

      // 1. Check 'message'
      if (map['message'] != null) {
        final msg = _cleanSingleErrorMessage(map['message']);
        if (msg.isNotEmpty) messages.add(msg);
      }

      // 2. Check 'detail' / 'error'
      if (map['detail'] != null) {
        final d = _cleanSingleErrorMessage(map['detail']);
        if (d.isNotEmpty && !messages.contains(d)) messages.add(d);
      } else if (map['error'] != null && map['error'] is String) {
        final e = _cleanSingleErrorMessage(map['error']);
        if (e.isNotEmpty && !messages.contains(e)) messages.add(e);
      }

      // 3. Check 'errors' (map or list or string)
      if (map['errors'] != null) {
        final errs = map['errors'];
        if (errs is Map) {
          errs.forEach((key, val) {
            final parsedVal = _cleanSingleErrorMessage(val);
            if (parsedVal.isNotEmpty && !messages.contains(parsedVal)) {
              messages.add(parsedVal);
            }
          });
        } else if (errs is List) {
          for (var item in errs) {
            final parsedVal = _cleanSingleErrorMessage(item);
            if (parsedVal.isNotEmpty && !messages.contains(parsedVal)) {
              messages.add(parsedVal);
            }
          }
        } else if (errs is String) {
          final parsedVal = _cleanSingleErrorMessage(errs);
          if (parsedVal.isNotEmpty && !messages.contains(parsedVal)) {
            messages.add(parsedVal);
          }
        }
      }

      // 4. Check 'items' (cart item validation)
      if (map['items'] is List) {
        for (var item in (map['items'] as List)) {
          if (item is Map) {
            item.forEach((key, value) {
              final parsedVal = _cleanSingleErrorMessage(value);
              if (parsedVal.isNotEmpty && !messages.contains(parsedVal)) {
                messages.add(parsedVal);
              }
            });
          }
        }
      }

      if (messages.isNotEmpty) {
        return messages.join('\n\n');
      }
    }

    final singleClean = _cleanSingleErrorMessage(error);
    return singleClean.isNotEmpty ? singleClean : error.toString();
  }

  String _cleanSingleErrorMessage(dynamic raw) {
    if (raw == null) return '';
    String text = '';

    if (raw is List) {
      text = raw
          .map((e) => _cleanSingleErrorMessage(e))
          .where((e) => e.isNotEmpty)
          .join('\n\n');
    } else if (raw is Map) {
      List<String> list = [];
      raw.forEach((key, val) {
        final cleanVal = _cleanSingleErrorMessage(val);
        if (cleanVal.isNotEmpty && !list.contains(cleanVal)) {
          list.add(cleanVal);
        }
      });
      text = list.join('\n\n');
    } else {
      text = raw.toString();
    }

    // Strip square brackets e.g. "[You have already used...]"
    text = text
        .replaceAll(RegExp(r'^\[\s*'), '')
        .replaceAll(RegExp(r'\s*\]$'), '')
        .trim();

    // Strip field bullet prefixes e.g. "• plan: " or "plan: "
    text = text.replaceAll(RegExp(r'^\s*•?\s*\w+:\s*'), '');

    // Strip JSON string quotes if wrapped
    if (text.startsWith('"') && text.endsWith('"') && text.length > 2) {
      text = text.substring(1, text.length - 1);
    }

    return text.trim();
  }

  // --- MODERN UI BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffold = Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
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
                        SizedBox(
                          height:
                              (widget.isSubscription && subscription != null
                                  ? 172.0
                                  : 88.0) +
                              MediaQuery.paddingOf(context).bottom +
                              16.0,
                        ),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.isSubscription) {
          context.goNamed(AppRoute.subscriptionList.name);
        } else {
          context.goNamed(AppRoute.orderList.name);
        }
      },
      child: scaffold,
    );
  }

  Widget _buildAnimatedHeader(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        height: 170,
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
        child: Stack(
          children: [
            // Header Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 10, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    // Title Row
                    Row(
                      children: [
                        // Back button
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.parchment,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            if (widget.isSubscription) {
                              context.goNamed(AppRoute.subscriptionList.name);
                            } else {
                              context.goNamed(AppRoute.orderList.name);
                            }
                          },
                        ),
                        // const SizedBox(width: 12),
                        // Container(
                        //   padding: const EdgeInsets.all(12),
                        //   decoration: BoxDecoration(
                        //     color: AppColors.parchment.withValues(alpha: 0.2),
                        //     borderRadius: BorderRadius.circular(16),
                        //   ),
                        //   child: Icon(
                        //     widget.isSubscription
                        //         ? Icons.card_membership_rounded
                        //         : Icons.shopping_bag_rounded,
                        //     color: AppColors.amberWarnBg,
                        //     size: 28,
                        //   ),
                        // ),
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
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: AppColors.parchment,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$totalItems item${totalItems > 1 ? 's' : ''} ready to order",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.parchment.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            AppColors.deepSoilGreen,
            AppColors.deepSoilGreen.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepSoilGreen.withValues(alpha: 0.3),
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
                  ApiConfig.showExpectedDeliveryDate
                      ? widget.expectedDeliveryDate
                      : ApiConfig.alternativeDeliveryText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.harvestAmber,
                    fontSize: 12, // Reduced size
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
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
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.deepSoilGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.deepSoilGreen),
              ),
              child: Row(
                spacing: 10,
                children: [
                  Icon(
                    Icons.autorenew_rounded,
                    color: AppColors.parchment,
                    size: 20,
                  ),
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

  // ─── Payment method helpers ─────────────────────────────────────────
  IconData _paymentMethodIcon(String method) {
    switch (method) {
      case 'UPI':
        return Icons.account_balance_wallet_rounded;
      case 'CARD':
        return Icons.credit_card_rounded;
      case 'NETBANKING':
        return Icons.account_balance_rounded;
      case 'INSTALLMENT':
        return Icons.payment_rounded;
      case 'COD':
      default:
        return Icons.money_rounded;
    }
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'UPI':
        return 'UPI';
      case 'CARD':
        return 'Credit / Debit Card';
      case 'NETBANKING':
        return 'Net Banking';
      case 'INSTALLMENT':
        return 'Installment Plan';
      case 'COD':
      default:
        return 'Cash on Delivery';
    }
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
                _paymentMethodIcon(_selectedPaymentMethod),
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
                    _paymentMethodLabel(_selectedPaymentMethod),
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
                        SizedBox(width: 3),
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
    final isInstallment = _selectedPaymentType == 'INSTALLMENT';
    final displayPrice =
        isInstallment
            ? totalMonthlyPrice * subscription.installmentFrequencyMonths
            : totalMonthlyPrice * subscription.durationMonths;

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
                          isInstallment
                              ? 'Monthly installments'
                              : 'One-time payment',
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
                        '₹${displayPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isInstallment ? 'due now' : 'total',
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
              _buildPaymentOption(
                theme,
                isDark,
                'UPI',
                'UPI',
                'Pay securely using any UPI app',
                Icons.account_balance_wallet_rounded,
                AppColors.deepSoilGreen,
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                theme,
                isDark,
                'CARD',
                'Credit / Debit Card',
                'Visa, Mastercard, RuPay & more',
                Icons.credit_card_rounded,
                AppColors.harvestAmber,
              ),
              const SizedBox(height: 12),
              if (widget.isSubscription) ...[
                _buildPaymentOption(
                  theme,
                  isDark,
                  'NETBANKING',
                  'Net Banking',
                  'Pay via your bank\'s online portal',
                  Icons.account_balance_rounded,
                  AppColors.rawEarth70,
                ),
                const SizedBox(height: 12),
              ],
              if (!widget.isSubscription) ...[
                _buildPaymentOption(
                  theme,
                  isDark,
                  'COD',
                  'Cash on Delivery',
                  'Pay when you receive your order',
                  Icons.money_rounded,
                  AppColors.rawEarth26,
                ),
                const SizedBox(height: 12),
              ],
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
