import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/subscription_request_create_model.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail_single.dart';
import 'package:grocery_app/services/cart_service.dart';
import 'package:grocery_app/services/order_service.dart';
import 'package:grocery_app/screens/checkout/shipping_details_form.dart';
import 'package:grocery_app/screens/order_accepted_screen.dart';
import 'package:grocery_app/screens/order_failed_dialog.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/services/subscription_service.dart';

class CheckoutScreen extends StatefulWidget {
  final CartModel? cart;
  final ProductVariant? singleProduct;
  final double? price;
  final int? quantity;
  final bool isSubscription;
  final int? selectedPlan;
  final Map<String, String>? shippingDetails;
  final double deliveryCharges;

  const CheckoutScreen({
    Key? key,
    this.cart,
    this.price,
    this.singleProduct,
    this.quantity,
    this.isSubscription = false,
    this.selectedPlan,
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
    if (widget.shippingDetails != null) {
      _shippingDetails = ShippingDetails(
        address: widget.shippingDetails!['address'] ?? '',
        name: widget.shippingDetails!['name'] ?? '',
        city: widget.shippingDetails!['city'] ?? '',
        state: widget.shippingDetails!['state'] ?? '',
        pincode: widget.shippingDetails!['pincode'] ?? '',
        phone: widget.shippingDetails!['phone'] ?? '',
      );
    }
    _loadShippingDetails();
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

  Future<void> _createOrder() async {
    // Always refresh _shippingDetails from user if using existing address
    if (_useExistingAddress) {
      final user = _authService.currentUser;
      _shippingDetails = ShippingDetails(
        address: user?.address ?? '',
        name: ((user?.firstName ?? '') + ' ' + (user?.lastName ?? '')).trim(),
        city: user?.city ?? '',
        state: user?.state ?? '',
        pincode: user?.pincode ?? '',
        phone: user?.phoneNumber ?? '',
      );
    }

    if (_shippingDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in shipping details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_shippingDetails!.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all shipping details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (_selectedPaymentMethod == 'UPI') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('UPI payment integration coming soon!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (widget.isSubscription) {
        // Handle subscription creation
        final user = _authService.currentUser;
        final request = SubscriptionCreateRequest(
          plan: widget.selectedPlan!,
          deliveryAddress: _shippingDetails!.address,
          deliveryCity: _shippingDetails!.city,
          deliveryState: _shippingDetails!.state,
          deliveryPincode: _shippingDetails!.pincode,
          deliveryPhone: _shippingDetails!.phone,
          paymentType: _selectedPaymentType,
          items: [
            SubscriptionCreateItem(
              productVariantId: widget.singleProduct!.id,
              quantity: widget.quantity!,
            ),
          ],
        );

        final result = await _subscriptionService.createSubscription(request);

        if (!mounted) return;

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SubscriptionPlanDetailScreen(
                    subscription: result['data'],
                  ),
            ),
            (route) => route.isFirst,
          );
        } else {
          String errorMessage =
              result['message'] ?? 'Failed to create subscription';
          if (result['errors'] != null) {
            errorMessage += '\n${result['errors']}';
          }
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
      } else {
        // Handle regular order creation
        final order = OrderModel.fromShippingDetails(
          paymentMethod: _selectedPaymentMethod,
          shippingDetails: _shippingDetails!,
          items: _getOrderItems(),
          notes: null,
        );

        final createdOrder = await _orderService.createOrder(order);

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (context) => OrderAcceptedScreen(
                  order: createdOrder,
                  isSubscription: false,
                ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      print('Failed to create order: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return OrderFailedDialog(error: _error);
        },
      );
    }
  }

  Widget _buildAddressSelector() {
    final user = _authService.currentUser;
    if (user == null || user.address == null || user.address!.isEmpty) {
      return ShippingDetailsForm(
        initialDetails: _shippingDetails,
        onSaved: (details) {
          setState(() {
            _shippingDetails = details;
          });
        },
      );
    }
    print(user.address);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  'Delivery Address',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                RadioListTile<bool>(
                  value: true,
                  groupValue: _useExistingAddress,
                  onChanged: (value) {
                    setState(() {
                      _useExistingAddress = value!;
                      if (value) {
                        _shippingDetails = ShippingDetails(
                          address: user.address ?? '',
                          name:
                              ((user.firstName ?? '') +
                                      ' ' +
                                      (user.lastName ?? ''))
                                  .trim(),
                          city: user.city ?? '',
                          state: user.state ?? '',
                          pincode: user.pincode ?? '',
                          phone: user.phoneNumber ?? '',
                        );
                      }
                    });
                  },
                  title: Text('Use Existing Address'),
                  subtitle: Text(
                    '${user.firstName ?? ''} ${user.lastName ?? ''}\n ${user.phoneNumber ?? ''}\n ${user.address ?? ''}, ${user.city ?? ''}, ${user.state ?? ''} - ${user.pincode ?? ''}',
                  ),
                ),
                RadioListTile<bool>(
                  value: false,
                  groupValue: _useExistingAddress,
                  onChanged: (value) {
                    setState(() {
                      _useExistingAddress = value!;
                    });
                  },
                  title: Text('Use New Address'),
                ),
              ],
            ),
          ),
        ),
        if (!_useExistingAddress) ...[
          SizedBox(height: 16),
          ShippingDetailsForm(
            initialDetails: _shippingDetails,
            onSaved: (details) {
              setState(() {
                _shippingDetails = details;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentTypeSelector() {
    if (!widget.isSubscription) return SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Type', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
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
                  SizedBox(width: 12),
                  Text('Pay in Full'),
                ],
              ),
              subtitle: Text('Pay the entire amount upfront'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
                  SizedBox(width: 12),
                  Text('Pay in Installments'),
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
        padding: EdgeInsets.all(16),
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
                  Text('UPI Payment'),
                ],
              ),
              subtitle: Text('Coming soon'),
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
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Delivery Address Card
                    if (widget.shippingDetails != null)
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
                                'Delivery Address',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 16),
                              Text(widget.shippingDetails!['address']!),
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
                      ),
                    SizedBox(height: 16),
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
                    SizedBox(height: 24),
                    _buildPaymentTypeSelector(),
                    // Payment Method Selector
                    _buildPaymentMethodSelector(),
                    SizedBox(height: 24),
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
