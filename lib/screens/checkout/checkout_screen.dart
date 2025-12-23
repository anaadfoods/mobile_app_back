// ignore_for_file: unused_element // Disables warnings for unused private methods

import 'package:grocery_app/common_widgets/global_import.dart';
// Add any other necessary imports
// import 'package:grocery_app/models/cart_model.dart';
// import 'package:grocery_app/models/product_model.dart';
// ... etc.

class CheckoutScreen extends StatefulWidget {
  final CartModel? cart;
  final Product? singleProduct;
  final double? price;
  final int? quantity;
  final bool isSubscription;
  final String? paymentType;
  final int? selectedPlan;
  final Map<String, String>? shippingDetails;
  final double deliveryCharges;
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
    required this.deliveryCharges,
    required this.expectedDeliveryDate, this.paymentType,
  }) : assert(cart != null || (singleProduct != null && quantity != null));

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();
  final AuthService _authService = AuthService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  ShippingDetails? _shippingDetails;
  SubscriptionPlan? subscription;
  List<SubscriptionPlan> planDescriptions = [];

  bool _isLoading = true;
  String? _error;
  String _selectedPaymentMethod = 'UPI';
  bool _useExistingAddress = true;
  late String _selectedPaymentType;

  // Calculate total items and price
  int get totalItems => widget.cart?.totalItems ?? widget.quantity!;
  String get totalPrice {
    double basePrice;
    if (widget.isSubscription) {
      // --- BUG FIX HERE ---
      // Original was: widget.price ?? 0.0 * widget.quantity!
      // Which evaluates to: widget.price ?? (0.0 * widget.quantity!)
      // Corrected version:
      basePrice = (widget.price ?? 0.0) * (widget.quantity ?? 1);
    } else {
      basePrice = widget.cart?.totalPrice != null
          ? double.parse(widget.cart!.totalPrice)
          : (widget.singleProduct!.finalPrice * widget.quantity!);
    }

    return (basePrice + widget.deliveryCharges).toString();
  }

  @override
  void initState() {
    super.initState();

    if (widget.isSubscription) {
      _selectedPaymentType = widget.paymentType ?? 'PAID_FULL';
    } else {
      _selectedPaymentType = 'FULL';
    }

    _initializeCheckout();
  }

  // --- ALL LOGIC METHODS (UNCHANGED AS REQUESTED) ---

  Future<void> _initializeCheckout() async {
    // This check is important. If shippingDetails are passed, they are *new*
    if (widget.shippingDetails != null) {
      await _prepareShippingDetails();
    } else {
      // Otherwise, we load the user's *existing* details
      await _loadShippingDetails();
    }

    if (widget.isSubscription) {
      await _fetchPlansAndAssign();
    }
    
    // Final loading state update
    _setLoadingState(false);
  }

  // Step 1: Prepare Shipping Details
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

  // Step 2: Validate Shipping
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

  // Step 3: Set Loading State
  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        if (loading) _error = null;
      });
    }
  }

  // Main Checkout Flow
  Future<void> _createOrder() async {
    // Step 1: Validate Shipping (Details are already prepared in initState)
    if (!_validateShipping()) return;

    // Step 2: Set Loading State
    _setLoadingState(true);

    try {
      // Step 3: Check Payment Method
      if (_selectedPaymentMethod == 'UPI') {
        await _handleUPIPayment();
      } else {
        await _handleNonUPIPayment();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      // Step 4: Set Loading False (if mounted)
      _setLoadingState(false);
    }
  }

  // Handle UPI Payment Flow
  Future<void> _handleUPIPayment() async {
    if (widget.isSubscription) {
      await _handleUPISubscription();
    } else {
      await _handleUPIOrder();
    }
  }

  // Handle UPI Subscription
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

  // Handle Non-UPI Subscription
  Future<void> _handleNonUPISubscription() async {
    final result = await _createSubscription();

    if (!mounted) return;

    if (result['success'] == true) {
      await _handleSuccessfulSubscription(result);

      NotificationHelper.showNotification(
        title: 'Subscription Created!',
        body:
            'Subscription ID: ${result['subscription_id']}\nPayment Mode: Cash on Delivery\nStatus: Pending Payment',
      );
    } else {
      _showSubscriptionFailedDialog(result);
    }
  }

  // Handle successful subscription creation
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
      builder: (context) => AlertDialog(
        title: Text('Subscription Created'),
        content: Text('Your subscription has been created successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('OK'),
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
            'Order ID: ${response.orderNumber}\nPayment Mode: Cash on Delivery\nStatus: Pending Payment',
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
          'Order ID: ${createdOrder.orderNumber}\nPayment Mode: Cash on Delivery\nStatus: Pending Payment',
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
    print("delivery charges are  + ${widget.deliveryCharges}");
    final request = SubscriptionCreateRequest(
      plan: widget.selectedPlan,
      deliveryAddress: _shippingDetails!.address ?? "",
      deliveryCity: _shippingDetails!.city ?? "",
      deliveryState: _shippingDetails!.state ?? "",
      deliveryPincode: _shippingDetails!.pincode ?? "",
      deliveryPhone: _shippingDetails!.phone ?? "",
      paymentType: _selectedPaymentType,
      paymentMethod: _selectedPaymentMethod,
      deliveryFee: widget.deliveryCharges,
      expectedDeliveryDate: widget.expectedDeliveryDate,
      items: [
        SubscriptionCreateItem(
          productVariantId: widget.singleProduct!.id,
          quantity: widget.quantity!,
        ),
      ],
    );
    print('${request.paymentMethod}  ${request.items[0]}');

    return await _subscriptionService.createSubscription(request);
  }

  OrderModel _createOrderModel() {
    return OrderModel.fromShippingDetails(
      paymentMethod: _selectedPaymentMethod,
      shippingDetails: _shippingDetails!,
      expectedDeliveryDate: widget.expectedDeliveryDate,
      deliveryFee: widget.deliveryCharges,
      items: _getOrderItems(),
      notes: null,
    );
  }

  Future<void> _launchSubscriptionWebView(Map<String, dynamic> result) async {
    try {
      final paymentUrl = result['payment_links']['web'];
      final subscriptionId = result['subscription_id'];

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
            onPaymentSuccess: (url) async {
              try {
                final subscriptionDetails = await _subscriptionService
                    .getSubscriptionDetails(parsedSubscriptionId);

                if (subscriptionDetails['success'] == true && mounted) {
                  NotificationHelper.showNotification(
                    title: 'Payment Successful!',
                    body:
                        'Subscription ID: $parsedSubscriptionId\nPayment Mode: UPI\nStatus: Paid',
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
                    'Subscription ID: $parsedSubscriptionId\nPayment Mode: UPI\nStatus: Failed',
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment failed or cancelled'),
                  backgroundColor: Colors.red,
                ),
              );
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
                  'Order ID: ${response.orderId}\nPayment Mode: UPI\nStatus: Failed',
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
              'Order ID: ${response.orderId}\nPayment Mode: UPI\nStatus: Paid',
        );

        Navigator.pushReplacement(
          context,
          AnimatedTransitions.fadeScale(OrderDetailScreen(order: order)),
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
    Navigator.pushAndRemoveUntil(
      context,
      AnimatedTransitions.fadeScale(
        SubscriptionPlanDetailScreen(subscription: subscription),
      ),
      (route) => route.isFirst,
    );
  }

  void _navigateToOrderAccepted(Order order) {
    Navigator.pushReplacement(
      context,
      AnimatedTransitions.fadeScale(
        OrderDetailScreen(
          order: order,
        ),
      ),
    );
  }

  void _showSubscriptionFailedDialog(Map<String, dynamic> result) {
    String errorMessage = _parseServerError(
      result['message'] ?? result['errors'] ?? 'Failed to create subscription',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Subscription Failed'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Go Back'),
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
    } else {
      print('Failed to fetch plans: ${result['message']}');
    }
  }

  Future<void> _fetchSubscriptionDetails(int subscriptionId) async {
    final result = await _subscriptionService.getSubscriptionDetails(
      subscriptionId,
    );
    if (result['success'] == true && mounted) {
      setState(() {
        subscription = result['data'];
      });
    } else {
      print('Failed to fetch subscription details: ${result['message']}');
    }
  }

  Future<void> _loadShippingDetails() async {
    // Already in a loading state from _initializeCheckout
    try {
      final details = await _orderService.getUserShippingDetails();
      if (mounted) {
        setState(() {
          _shippingDetails = details;
          // Don't set loading to false here, _initializeCheckout will
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          // Don't set loading to false here, _initializeCheckout will
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

  // --- REFACTORED BUILD AND UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(widget.isSubscription ? 'Subscription Checkout' : 'Checkout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDeliveryTime(theme),
                  const SizedBox(height: 16),
                  
                  // This widget now correctly checks for _shippingDetails
                  if (_shippingDetails != null)
                    _buildShippingAddress(theme),
                  
                  const SizedBox(height: 16),
                  
                  // This widget now checks for null `subscription`
                  if (widget.isSubscription && subscription != null)
                    _buildCongratulation(theme, subscription!),

                  const SizedBox(height: 16),
                  // _buildPaymentTypeSelector(theme),
                  const SizedBox(height: 16),
                  _buildOrderSummary(theme),
                  const SizedBox(height: 16),
                  _buildPaymentMethodSelector(theme),
                  const SizedBox(height: 24), // Extra space at the bottom
                ],
              ),
            ),
      bottomNavigationBar: _isLoading ? null : _buildBottomBar(theme),
    );
  }

  /// Builds the correct bottom bar based on order type
  Widget _buildBottomBar(ThemeData theme) {
    if (widget.isSubscription && subscription != null) {
      return _buildSubscriptionBottomBar(theme, subscription!);
    } else {
      return _buildStandardBottomBar(theme);
    }
  }

  /// Bottom bar for regular "Place Order"
  Widget _buildStandardBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: ElevatedButton(
        onPressed: _createOrder,
        child: Text('Place Order'),
      ),
    );
  }

  /// Styled bottom bar for Subscription summary and payment
  Widget _buildSubscriptionBottomBar(ThemeData theme, SubscriptionPlan subscription) {
    final totalMonthlyPrice = double.tryParse(totalPrice) ?? 0.0;
    final fullSubscriptionPrice = totalMonthlyPrice * subscription.durationMonths;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            " Your ${subscription.durationMonths}-Month Journey",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
      if (widget.paymentType == 'PAID_FULL')
            Text(
              "₹${fullSubscriptionPrice.toStringAsFixed(2)} upfront (One-time payment for the entire ${subscription.durationMonths}-month plan)",
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            )
          else
          Text(
            "₹${(fullSubscriptionPrice) / (subscription.durationMonths/(subscription.installmentFrequencyMonths) )  } per  installments (Billed ₹${fullSubscriptionPrice.toStringAsFixed(2)} upfront)",
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _createOrder,
            child: Text('Subscribe Now'),
          ),
        ],
      ),
    );
  }

  /// Styled congratulation message for subscriptions
  Widget _buildCongratulation(ThemeData theme, SubscriptionPlan subscription) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.primary, // Using theme color
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.celebration_outlined,
            color: theme.colorScheme.onPrimary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "A wonderful commitment to your well-being.",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "This ${subscription.durationMonths}-month journey is the first step toward a life of harmony and pure nourishment.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTime(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          const Text('🚚', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            "Estimated Delivery by ${widget.expectedDeliveryDate}",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddress(ThemeData theme) {
    // --- BUG FIX HERE ---
    // Added null check and now using `_shippingDetails` state variable
    // instead of `widget.shippingDetails`
    if (_shippingDetails == null) {
      return const SizedBox.shrink(); // Or a "Please add address" widget
    }

    return ExpansionTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      collapsedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      backgroundColor: theme.cardColor,
      collapsedBackgroundColor: theme.cardColor,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          Icon(Icons.location_on_outlined, color: theme.disabledColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _shippingDetails!.address,
              style: theme.textTheme.bodyLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      children: [
        ListTile(
          title: Text(_shippingDetails!.address),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_shippingDetails!.city}, ${_shippingDetails!.state}'),
              Text('Pincode: ${_shippingDetails!.pincode}'),
              Text('Phone: ${_shippingDetails!.phone}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isSubscription
                  ? 'Subscription ${subscription?.name ?? 'Summary'}'
                  : 'Order Summary',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // --- List of Items (Single or Cart) ---
            if (widget.singleProduct != null)
              Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _buildProductImage(widget.singleProduct!),
                    title: Text(widget.singleProduct!.productName,
                        style: theme.textTheme.bodyMedium),
                    subtitle: Text('Quantity: ${widget.quantity}'),
                    trailing: Text(widget.isSubscription
                        ? '₹${widget.price!.toStringAsFixed(2)}'
                        : '₹${widget.singleProduct!.finalPrice.toStringAsFixed(2)}'),
                  ),
                  if (widget.isSubscription && subscription != null)
                    ExpansionTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      backgroundColor: theme.cardColor,
                      collapsedBackgroundColor: theme.cardColor,
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 8),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "₹$totalPrice / month", // Uses the getter
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "incl. ${subscription?.discountPercentage.toStringAsFixed(0)}% savings + delivery",
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize:
                                  theme.textTheme.bodySmall?.fontSize ?? 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      children: [
                        ListTile(
                          title: Text(
                            "Price Breakdown (per month):",
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Subtotal:",
                                      style: theme.textTheme.bodyMedium),
                                  Text(
                                      "₹${(double.parse(totalPrice) - widget.deliveryCharges).toStringAsFixed(2)}",
                                      style: theme.textTheme.bodyMedium),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Delivery Charges:",
                                      style: theme.textTheme.bodyMedium),
                                  Text(
                                      "₹${widget.deliveryCharges.toStringAsFixed(2)}",
                                      style: theme.textTheme.bodyMedium),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                ],
              )
            else
              ...widget.cart!.items.map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _buildProductImage(item.productVariant),
                    title: Text(item.productVariant.productName),
                    subtitle: Text('Quantity: ${item.quantity}'),
                    trailing: Text('₹${item.totalPrice}'),
                  )),
            
            // --- LAYOUT FIX: Moved Totals outside the if/else ---
            
            if (widget.deliveryCharges > 0 && !widget.isSubscription)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Delivery Charges', style: theme.textTheme.bodyLarge),
                    Text('₹${widget.deliveryCharges.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              
            // Don't show total for subscription, it's in the bottom bar
            if (!widget.isSubscription) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount', style: theme.textTheme.titleLarge),
                  Text(
                    '₹${(double.parse(totalPrice)).toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypeSelector(ThemeData theme) {
    if (!widget.isSubscription || subscription == null) {
      return const SizedBox.shrink();
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Payment Type', style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              value: 'PAID_FULL',
              groupValue: _selectedPaymentType,
              onChanged: (value) => setState(() => _selectedPaymentType = value!),
              title: const Text('Pay in Full'),
              subtitle: const Text('Pay the entire amount upfront'),
            ),
            if (subscription!.allowsInstallments)
              RadioListTile<String>(
                value: 'INSTALLMENT',
                groupValue: _selectedPaymentType,
                onChanged: (value) =>
                    setState(() => _selectedPaymentType = value!),
                title: const Text('Pay in Installments'),
                subtitle: const Text('Pay in monthly installments'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: _showPaymentMethodSelectionDialog,
        leading: Icon(
          _selectedPaymentMethod == 'COD' ? Icons.money : Icons.payment,
          color: theme.colorScheme.primary,
        ),
        title: Text('Pay Using',
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(_selectedPaymentMethod == 'COD'
            ? 'Cash on Delivery'
            : 'UPI / Card / NetBanking'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Future<void> _showPaymentMethodSelectionDialog() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String? newSelection = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Select Payment Method', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              if (!widget.isSubscription)
                ListTile(
                  leading: Icon(Icons.money, color: colorScheme.primary),
                  title: const Text('Cash on Delivery'),
                  onTap: () => Navigator.pop(context, 'COD'),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  tileColor: _selectedPaymentMethod == 'COD'
                      ? colorScheme.primary.withOpacity(0.1)
                      : null,
                ),
              if (!widget.isSubscription) const Divider(),
              ListTile(
                leading: Icon(Icons.payment, color: colorScheme.secondary),
                title: const Text('Pay Online'),
                subtitle: const Text('UPI / Card / NetBanking'),
                onTap: () => Navigator.pop(context, 'UPI'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                tileColor: _selectedPaymentMethod == 'UPI'
                    ? colorScheme.secondary.withOpacity(0.1)
                    : null,
              ),
            ],
          ),
        );
      },
    );
    if (newSelection != null) {
      setState(() {
        _selectedPaymentMethod = newSelection;
      });
    }
  }

  Widget _buildProductImage(Product variant) {
    final theme = Theme.of(context);
    String? imageUrl =
        variant.productImages.isNotEmpty ? variant.productImages[0].image : null;
    return Container(
      width: 50,
      height: 50,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.splashColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.shopping_bag_outlined, color: theme.disabledColor),
            )
          : Icon(Icons.shopping_bag_outlined, color: theme.disabledColor),
    );
  }
}

// --- GLOBAL HELPER WIDGETS (UNCHANGED) ---

extension on String {
  String toStringAsFixed(int i) {
    return double.tryParse(this)?.toStringAsFixed(i) ?? this;
  }
}

void _showSubscriptionDetails(
  BuildContext context,
  SubscriptionPlan subscription,
  int selectedPlan,
  double price,
  double deliveryCharges, {
  bool showAmountPerDelivery = false,
}) {
  double perDeliveryAmount = price;
  double perDeliveryCharge = deliveryCharges;
  double totalAmount =
      (perDeliveryAmount + perDeliveryCharge) * subscription.durationMonths;

  double amountPerDelivery =
      (totalAmount / subscription.installmentFrequencyMonths);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Payment Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 26, 126, 31),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    leading: Icon(
                      Icons.shopping_basket,
                      color: Colors.indigo,
                      size: 28,
                    ),
                    title: Text(
                      'Plan name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      subscription.name,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.card_membership,
                      color: Colors.indigo,
                      size: 28,
                    ),
                    title: Text(
                      'Plan Duration (months)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      subscription.durationMonths.toString(),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.local_shipping,
                      color: Colors.indigo,
                      size: 28,
                    ),
                    title: Text(
                      'Number of Deliveries',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      subscription.durationMonths.toString(),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Divider(),
                  if (showAmountPerDelivery) ...[
                    ListTile(
                      leading: Icon(
                        Icons.payments,
                        color: Colors.purple,
                        size: 28,
                      ),
                      title: Text(
                        'Amount per Delivery (Installment)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '₹${amountPerDelivery.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Divider(),
                  ],
                  ListTile(
                    leading: Icon(
                      Icons.attach_money,
                      color: Colors.green,
                      size: 28,
                    ),
                    title: Text(
                      'Amount per Delivery',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '₹${perDeliveryAmount.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.local_shipping,
                      color: Colors.orange,
                      size: 28,
                    ),
                    title: Text(
                      'Delivery Charges per Delivery',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '₹${perDeliveryCharge.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Divider(thickness: 2),
                  ListTile(
                    leading: Icon(
                      Icons.calculate,
                      color: Colors.blue,
                      size: 28,
                    ),
                    title: Text(
                      'Total Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      '(${perDeliveryAmount.toStringAsFixed(2)} + ${perDeliveryCharge.toStringAsFixed(2)}) x ${subscription.durationMonths} = ₹${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    },
  );
}