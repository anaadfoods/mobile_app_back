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

  const CheckoutScreen({
    Key? key,
    this.cart,
    this.price,
    this.singleProduct,
    this.quantity,
    this.isSubscription = false,
    this.selectedPlan = 0,
    this.shippingDetails,
    required this.deliveryCharges,
  }) : assert(cart != null || (singleProduct != null && quantity != null)),
       super(key: key);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in shipping details'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (!_shippingDetails!.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all shipping details'),
          backgroundColor: Colors.red,
        ),
      );
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

      // Show success notification
      // NotificationHelper.showNotification(
      //   title: 'Order Placed!',
      //   body: 'Your order has been placed successfully.',
      // );
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

    print("Create subscription response: $result");

    if (!mounted) return;

    if (result['success'] == true) {
      print("Success is true, checking payment_links...");
      print("payment_links: ${result['payment_links']}");
      print("payment_links type: ${result['payment_links'].runtimeType}");

      if (result['payment_links'] != null) {
        print("payment_links is not null");
        print("payment_links['web']: ${result['payment_links']['web']}");
        print(
          "payment_links['web'] type: ${result['payment_links']['web']?.runtimeType}",
        );

        if (result['payment_links']['web'] != null) {
          print("Payment links found, launching WebView...");
          print("Payment URL: ${result['payment_links']['web']}");
          // Launch WebView for UPI payment
          await _launchSubscriptionWebView(result);

          // Send notification for subscription created with pending payment
          NotificationHelper.showNotification(
            title: 'Subscription Created!',
            body:
                'Subscription ID: ${result['subscription_id']}\nPayment Mode: UPI\nStatus: Pending Payment',
          );
        } else {
          // No payment required, or payment_links missing, treat as success
          await _handleSuccessfulSubscription(result);
        }
      } else {
        // No payment required, or payment_links missing, treat as success
        await _handleSuccessfulSubscription(result);
      }
    } else {
      // Only here show the failed dialog
      _showSubscriptionFailedDialog(result);
    }
  }

  // Handle Non-UPI Subscription
  Future<void> _handleNonUPISubscription() async {
    final result = await _createSubscription();

    if (!mounted) return;

    if (result['success'] == true) {
      await _handleSuccessfulSubscription(result);

      // Send notification for subscription created with COD
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
      // Fetch subscription details using subscription_id
      if (result['subscription_id'] != null) {
        int parsedSubscriptionId;
        try {
          parsedSubscriptionId = int.parse(
            result['subscription_id'].toString(),
          );
        } catch (e) {
          print('Error parsing subscription ID: ${result['subscription_id']}');
          _showSubscriptionSuccessMessage(result);
          return;
        }

        final subscriptionDetails = await _subscriptionService
            .getSubscriptionDetails(parsedSubscriptionId);

        if (subscriptionDetails['success'] == true && mounted) {
          _navigateToSubscriptionDetails(subscriptionDetails['data']);
        } else {
          // If fetching details fails, show success message
          _showSubscriptionSuccessMessage(result);
        }
      } else {
        _showSubscriptionSuccessMessage(result);
      }
    } catch (e) {
      print('Error fetching subscription details: $e');
      _showSubscriptionSuccessMessage(result);
    }
  }

  // Show subscription success message
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
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  // Handle UPI Order
  Future<void> _handleUPIOrder() async {
    final order = _createOrderModel();
    final response = await _orderService.createOrder(order);

    if (!mounted) return;

    if (response is OrderCreateResponse &&
        response.success &&
        response.paymentLinks?.web != null) {
      // Launch WebView for UPI payment
      await _launchOrderWebView(response);

      // Send notification for order created with pending payment
      NotificationHelper.showNotification(
        title: 'Order Created!',
        body:
            'Order ID: ${response.orderId}\nPayment Mode: UPI\nStatus: Pending Payment',
      );
    } else if (response is OrderModel) {
      // Fallback: If response is OrderModel, treat as success (COD etc)
      _navigateToOrderAccepted(response);

      // Send notification for order created with COD
      NotificationHelper.showNotification(
        title: 'Order Created!',
        body:
            'Order ID: ${response.orderNumber}\nPayment Mode: Cash on Delivery\nStatus: Pending Payment',
      );
    } else {
      // Handle error
      _showOrderFailedDialog(_parseServerError(response));
    }
  }

  // Handle Non-UPI Order
  Future<void> _handleNonUPIOrder() async {
    final order = _createOrderModel();
    final createdOrder = await _orderService.createOrder(order);

    if (!mounted) return;

    _navigateToOrderAccepted(createdOrder);

    // Send notification for order created with COD
    NotificationHelper.showNotification(
      title: 'Order Created!',
      body:
          'Order ID: ${createdOrder.orderNumber}\nPayment Mode: Cash on Delivery\nStatus: Pending Payment',
    );
  }

  // Handle Non-UPI Payment Flow
  Future<void> _handleNonUPIPayment() async {
    if (widget.isSubscription) {
      await _handleNonUPISubscription();
    } else {
      await _handleNonUPIOrder();
    }
  }

  // Helper Methods
  Future<Map<String, dynamic>> _createSubscription() async {
    print("Payment method is ${_selectedPaymentMethod}");
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

    print(request.items);

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
    print("=== _launchSubscriptionWebView called ===");
    print("Result: $result");

    try {
      final paymentUrl = result['payment_links']['web'];
      final subscriptionId = result['subscription_id'];

      print("Payment URL: $paymentUrl");
      print("Subscription ID: $subscriptionId");
      print("Is Subscription: ${widget.isSubscription}");

      if (subscriptionId == null) {
        throw Exception('Subscription ID is null');
      }

      // Parse subscription ID to int
      int parsedSubscriptionId;
      try {
        parsedSubscriptionId = int.parse(subscriptionId.toString());
      } catch (e) {
        throw Exception('Invalid subscription ID format: $subscriptionId');
      }

      if (!mounted) {
        print("Widget not mounted, cannot navigate");
        return;
      }

      print("About to navigate to WebView...");

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
              print("Payment success callback triggered");
              // Fetch subscription details after successful payment
              try {
                final subscriptionDetails = await _subscriptionService
                    .getSubscriptionDetails(parsedSubscriptionId);

                if (subscriptionDetails['success'] == true && mounted) {
                  // Send notification for successful payment
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
                  // If fetching details fails, show success message
                  Navigator.pop(context);
                  _showSubscriptionSuccessMessage(result);
                }
              } catch (e) {
                print('Error fetching subscription details after payment: $e');
                Navigator.pop(context);
                _showSubscriptionSuccessMessage(result);
              }
            },
            onPaymentFailure: (url) {
              print("Payment failure callback triggered");
              Navigator.pop(context);

              // Send notification for payment failure
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

      print("Navigation to WebView completed");
    } catch (e) {
      print("Error in _launchSubscriptionWebView: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to launch payment page: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

            // Send notification for order payment failure
            NotificationHelper.showNotification(
              title: 'Payment Failed!',
              body:
                  'Order ID: ${response.orderId}\nPayment Mode: UPI\nStatus: Failed',
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
        final order = await _orderService.getOrderById(paymentStatus.orderId!);

        // Send notification for successful order payment
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment not successful!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to verify payment!'),
          backgroundColor: Colors.red,
        ),
      );
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

  // Existing helper methods
  Future<void> _fetchPlansAndAssign() async {
    final result = await _subscriptionService.getSubscriptionPlans();
    if (result['success'] == true && mounted) {
      setState(() {
        planDescriptions = result['data'] as List<SubscriptionPlan>;
        if (planDescriptions.isNotEmpty &&
            widget.selectedPlan != null &&
            widget.selectedPlan! > 0 &&
            widget.selectedPlan! <= planDescriptions.length) {
          subscription = planDescriptions[widget.selectedPlan!];
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

  // UI Methods
  Widget _buildPaymentTypeSelector() {
    if (!widget.isSubscription) return SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(8),
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
                children: [
                  Icon(Icons.payment, color: Colors.green),
                  SizedBox(width: 5),
                  Text('Pay in Full'),
                  SizedBox(width: 5),
                  if (widget.isSubscription)
                    GestureDetector(
                      onTap: () {
                        if (subscription != null) {
                          _showSubscriptionDetails(
                            context,
                            subscription!,
                            widget.selectedPlan!,
                            widget.price ?? 0.0,
                            widget.deliveryCharges,
                          );
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.only(left: 10),
                        child: Text(
                          "i",
                          style: TextStyle(color: Colors.blue, fontSize: 18),
                        ),
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
                  children: [
                    Icon(Icons.payment, color: Colors.blue),
                    SizedBox(width: 5),
                    Text('Pay in Installments'),
                    SizedBox(width: 5),
                    if (widget.isSubscription)
                      GestureDetector(
                        onTap: () {
                          if (subscription != null) {
                            _showSubscriptionDetails(
                              context,
                              subscription!,
                              widget.selectedPlan!,
                              widget.price ?? 0.0,
                              widget.deliveryCharges,
                              showAmountPerDelivery: true,
                            );
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.only(left: 10),
                          child: Text(
                            "i",
                            style: TextStyle(color: Colors.blue, fontSize: 18),
                          ),
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
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            RadioListTile<String>(
              value: 'COD',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              title: Row(
                children: [
                  Icon(Icons.money, color: Colors.green),
                  SizedBox(width: 12),
                  Text('Cash on Delivery'),
                ],
              ),
              subtitle: Text('Pay when you receive'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            RadioListTile<String>(
              value: 'UPI',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              title: Row(
                children: [
                  Icon(Icons.payment, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('UPI/Card/NetBanking'),
                ],
              ),
              subtitle: Text('pay now '),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                    if (widget.shippingDetails != null)
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(
                            'Delivery Address',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
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
                                title: Text(widget.singleProduct!.productName),
                                subtitle: Text('Quantity: ${widget.quantity}'),
                                trailing: Text(
                                  widget.isSubscription
                                      ? '₹${widget.price!.toStringAsFixed(2)}'
                                      : '₹${widget.singleProduct!.finalPrice}',
                                ),
                              ),
                            ] else ...[
                              ...widget.cart!.items.map(
                                (item) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.productVariant.productName),
                                  subtitle: Text('Quantity: ${item.quantity}'),
                                  trailing: Text('₹${item.totalPrice}'),
                                ),
                              ),
                            ],
                            Divider(height: 24),
                            // Delivery Charges
                            if (widget.deliveryCharges > 0)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Delivery Charges',
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
                            Divider(height: 24),
                            // Total Amount
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${double.parse(totalPrice).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Payment Method Selector
                    _buildPaymentMethodSelector(),
                    // Place Order Button
                    ElevatedButton(
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
                  ],
                ),
              ),
    );
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
