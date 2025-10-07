import 'package:flutter/material.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/models/subscription_plan_model.dart';
import 'package:grocery_app/models/subscription_request_create_model.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail_single.dart';
import 'package:grocery_app/services/cart_service.dart';
import 'package:grocery_app/services/order_service.dart';
import 'package:grocery_app/screens/checkout/shipping_details_form.dart';
import 'package:grocery_app/screens/order_accepted_screen.dart';
import 'package:grocery_app/screens/order_failed_dialog.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/services/subscription_service.dart';
import 'package:grocery_app/screens/checkout/webview_page.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:grocery_app/helpers/notification_helper.dart';
import 'package:grocery_app/helpers/animated_transitions.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'dart:convert';

class CheckoutScreen extends StatefulWidget {
  final CartModel? cart;
  final ProductVariant? singleProduct;
  final double? price;
  final int? quantity;
  final bool isSubscription;
  final int selectedPlan;
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
    this.selectedPlan = 0,
    this.shippingDetails,
    required this.deliveryCharges, required this.expectedDeliveryDate,
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
  String _selectedPaymentType = 'FULL';

  // Calculate total items and price
  int get totalItems => widget.cart?.totalItems ?? widget.quantity!;
  String get totalPrice {
    double basePrice;
    if (widget.isSubscription) {
      basePrice = widget.price ?? 0.0;
    } else {
      basePrice =
          widget.cart?.totalPrice != null
              ? double.parse(widget.cart!.totalPrice)
              : (double.parse(widget.singleProduct!.finalPrice) *
                  widget.quantity!);
    }

    return (basePrice + widget.deliveryCharges).toString();
  }

  @override
  void initState() {
    super.initState();
    _initializeCheckout();
  }

  Future<void> _initializeCheckout() async {
    await _prepareShippingDetails();
    if (widget.isSubscription) {
      await _fetchPlansAndAssign();
    }
    await _loadShippingDetails();
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
    // Step 1: Prepare Shipping Details
    await _prepareShippingDetails();

    // Step 2: Validate Shipping
    if (!_validateShipping()) return;

    // Step 3: Set Loading State
    _setLoadingState(true);

    try {
      // Step 4: Check Payment Method
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
      builder:
          (context) => AlertDialog(
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
    } else if (response is OrderModel) {
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
    final request = SubscriptionCreateRequest(
      plan: widget.selectedPlan,
      deliveryAddress: _shippingDetails!.address ?? "",
      deliveryCity: _shippingDetails!.city ?? "",
      deliveryState: _shippingDetails!.state ?? "",
      deliveryPincode: _shippingDetails!.pincode ?? "",
      deliveryPhone: _shippingDetails!.phone ?? "",
      paymentType: _selectedPaymentType,
      paymentMethod: _selectedPaymentMethod,
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
          AnimatedTransitions.fadeScale(
            OrderAcceptedScreen(
              order: order,
              isSubscription: widget.isSubscription,
            ),
          ),
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

  void _navigateToOrderAccepted(OrderModel order) {
    Navigator.pushReplacement(
      context,
      AnimatedTransitions.fadeScale(
        OrderAcceptedScreen(order: order, isSubscription: false),
      ),
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
            widget.selectedPlan > 0 &&
            widget.selectedPlan <= planDescriptions.length) {
          subscription = planDescriptions[widget.selectedPlan];
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
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final details = await _orderService.getUserShippingDetails();
      if (mounted) {
        setState(() {
          _shippingDetails = details;
          _isLoading = false;
        });
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

  Widget _buildProductImage(ProductVariant variant) {
    String? imageUrl;
    if (variant.productImages.isNotEmpty &&
        variant.productImages[0] is String &&
        (variant.productImages[0] as String).isNotEmpty) {
      imageUrl = variant.productImages[0] as String;
    }

    return Container(
      width: 50,
      height: 50,
      clipBehavior: Clip.antiAlias, // To ensure the child (Image/Icon) is clipped
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.shopping_bag_outlined, color: Colors.grey);
              },
            )
          : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
    );
  }

  // UI Methods
  Future<void> _showPaymentMethodSelectionDialog() async {
    String? newSelection = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Select Payment Method',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.money, color: Colors.green),
                title: const Text('Cash on Delivery'),
                onTap: () => Navigator.pop(context, 'COD'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tileColor: _selectedPaymentMethod == 'COD' ? Colors.green.withOpacity(0.1) : null,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.blue),
                title: const Text('Pay Online'),
                subtitle: const Text('UPI / Card / NetBanking'),
                onTap: () => Navigator.pop(context, 'UPI'),
                 shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tileColor: _selectedPaymentMethod == 'UPI' ? Colors.blue.withOpacity(0.1) : null,
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

  Widget _buildPaymentTypeSelector() {
    if (!widget.isSubscription) return SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Type', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            RadioListTile<String>(
              value: 'FULL',
              groupValue: _selectedPaymentType,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentType = value!;
                });
              },
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.payment, color: Colors.green),
                  SizedBox(width: 3),
                  Text('Pay in Full'),
                  SizedBox(width: 1),
                  if (widget.isSubscription)
                    IconButton(
                      onPressed: () {
                        if (subscription != null) {
                          _showSubscriptionDetails(
                            context,
                            subscription!,
                            widget.selectedPlan,
                            widget.price ?? 0.0,
                            widget.deliveryCharges,
                            showAmountPerDelivery: false,
                          );
                        }
                      },
                      iconSize: 20,
                      icon: Icon(
                        Icons.info,
                        color: const Color.fromARGB(255, 80, 144, 196),
                      ),
                    ),
                ],
              ),
              subtitle: Text('Pay the entire amount upfront'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            if (subscription!.installmentFrequencyMonths > 0)
              RadioListTile<String>(
                value: 'INSTALLMENT',
                groupValue: _selectedPaymentType,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentType = value!;
                  });
                },
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.payment,
                      color: const Color.fromARGB(255, 86, 159, 219),
                    ),
                    SizedBox(width: 3),
                    Text('Pay in Installments'),
                    SizedBox(width: 0),
                    if (widget.isSubscription)
                      IconButton(
                        onPressed: () {
                          if (subscription != null) {
                            _showSubscriptionDetails(
                              context,
                              subscription!,
                              widget.selectedPlan,
                              widget.price ?? 0.0,
                              widget.deliveryCharges,
                              showAmountPerDelivery: true,
                            );
                          }
                        },
                        iconSize: 20,
                        icon: Icon(
                          Icons.info,
                          color: const Color.fromARGB(255, 80, 144, 196),
                        ),
                      ),
                  ],
                ),
                subtitle: Text('Pay in monthly installments'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: _showPaymentMethodSelectionDialog,
        leading: Icon(
          _selectedPaymentMethod == 'COD' ? Icons.money : Icons.payment,
          color: Theme.of(context).primaryColor,
        ),
        title: const Text(
          'Pay Using',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _selectedPaymentMethod == 'COD'
              ? 'Cash on Delivery'
              : 'UPI / Card / NetBanking',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          widget.isSubscription ? 'Subscription Checkout' : 'Checkout',
        ),
        elevation: 0,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Delivery Address Card
                    Column(
  children: [
    // 1. WIDGET FOR ESTIMATED DELIVERY DATE
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // Use a color that matches your design
        color: const Color(0xFFFEF5E7), 
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          // The truck emoji 🚚
          const Text('🚚', style: TextStyle(fontSize: 20)), 
          const SizedBox(width: 12),
          Text(
            // Using your variable for the date
            "Estimated Delivery by ${widget.expectedDeliveryDate}", 
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    ),

    const SizedBox(height: 10), // Adds a small space between the two sections

    // 2. WIDGET FOR THE SHIPPING ADDRESS
    ExpansionTile(
      // --- Style the ExpansionTile itself ---
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      backgroundColor: const Color(0xFFF8F9F9),
      collapsedBackgroundColor: const Color(0xFFF8F9F9),
      
      // Remove the default padding
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
      
      // --- The title you see when it's collapsed ---
      title: Row(
        children: [
          Icon(Icons.location_on_outlined, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded( // Use Expanded to prevent overflow with long addresses
            child: Text(
              widget.shippingDetails!['address']!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),

      // --- The content you see when it's expanded (your original code) ---
      children: [
        ListTile(
          title: Text(widget.shippingDetails!['address']!),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.shippingDetails!['city']}, ${widget.shippingDetails!['state']}',
              ),
              Text(
                'Pincode: ${widget.shippingDetails!['pincode']}',
              ),
              Text(
                'Phone: ${widget.shippingDetails!['phone']}',
              ),
            ],
          ),
        ),
      ],
    ),
  ],
),
                      _buildPaymentTypeSelector(),
                      // Order Summary Card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isSubscription
                                    ? 'Subscription Summary'
                                    : 'Order Summary',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 16),
                              if (widget.singleProduct != null) ...[
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: _buildProductImage(widget.singleProduct!),
                                  title: Text(widget.singleProduct!.productName , style: TextStyle(fontSize: 14),),  
                                  subtitle: Text('Quantity: ${widget.quantity}'),
                                  trailing: Text(
                                    widget.isSubscription
                                        ? '₹${widget.price!.toStringAsFixed(2)}'
                                        : '₹${widget.singleProduct!.finalPrice.toStringAsFixed(2)}',
                                  ),
                                ),
                              ] else ...[
                                ...widget.cart!.items.map(
                                  (item) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: _buildProductImage(item.productVariant),
                                    title: Text(item.productVariant.productName),
                                    subtitle: Text('Quantity: ${item.quantity}'),
                                    trailing: Text('₹${item.totalPrice}'),
                                  ),
                                ),
                              ],

                              Divider(height: 24),
                              // Delivery Charges
                              if (widget.deliveryCharges > 0 &&
                                  widget.isSubscription) ...[
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text("Delivery Charges"),
                                  subtitle: Text(
                                    "* for single delivery",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    '₹${widget.deliveryCharges.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text("Total delivery charges"),
                                  subtitle: Text(
                                    "* for ${subscription!.durationMonths} months",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    '₹${(subscription!.durationMonths.toDouble() * widget.deliveryCharges).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    "Price for ${subscription!.durationMonths} units",
                                  ),
                                  subtitle: Text(
                                    "* for ${subscription!.durationMonths} month plan",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    '₹${(subscription!.durationMonths.toDouble() * widget.price!).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text("Payable amount"),
                                  subtitle: Text(
                                    (_selectedPaymentType == 'FULL')
                                        ? "* for ${subscription!.durationMonths} month plan"
                                        : "* for ${subscription!.installmentFrequencyMonths} month installment",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    (_selectedPaymentType == 'FULL')
                                        ? '₹${(subscription!.durationMonths.toDouble() * double.parse(totalPrice)).toStringAsFixed(2)}'
                                        : '₹${(subscription!.installmentFrequencyMonths.toDouble() * double.parse(totalPrice)).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Delivery Charges',
                                        overflow: TextOverflow.clip,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Text(
                                        '₹${widget.deliveryCharges.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Padding(
                                //   padding: EdgeInsets.symmetric(vertical: 8),
                                //   child: Row(
                                //     mainAxisAlignment:
                                //         MainAxisAlignment.spaceBetween,
                                //     children: [
                                //       Text(
                                //         'Expected Delivery Date',
                                //         overflow: TextOverflow.clip,
                                //         style: TextStyle(fontSize: 16),
                                //       ),
                                //       Text(
                                //         widget.expectedDeliveryDate,
                                //         style: TextStyle(
                                //           fontSize: 16,
                                //           fontWeight: FontWeight.bold,
                                //         ),
                                //       ),
                                //     ],
                                //   ),
                                // ),
                                Divider(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Amount',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₹${(double.parse(totalPrice)).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              // Total Amount
                            ],
                          ),
                        ),
                      ),
                      // Payment Method Selector
                      _buildPaymentMethodSelector(),
                      ],
                  ),
                ),
                      // Place Order Button
                    bottomNavigationBar:   Container(
                      margin: EdgeInsets.all(12),
                      child: ElevatedButton(
                          onPressed: _createOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.isSubscription ? 'Subscribe Now' : 'Place Order',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ),
                    
    );
  }
}

extension on String {
  toStringAsFixed(int i) {
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

