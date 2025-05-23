import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/services/cart_service.dart';
import 'package:grocery_app/services/order_service.dart';
import 'package:grocery_app/screens/checkout/shipping_details_form.dart';
import 'package:grocery_app/screens/order_accepted_screen.dart';
import 'package:grocery_app/screens/order_failed_dialog.dart';

class CheckoutScreen extends StatefulWidget {
  final CartModel? cart;
  final ProductVariant? singleProduct;
  final int? quantity;

  const CheckoutScreen({Key? key, this.cart, this.singleProduct, this.quantity})
    : assert(cart != null || (singleProduct != null && quantity != null)),
      super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();

  ShippingDetails? _shippingDetails;
  bool _isLoading = true;
  String? _error;
  String _selectedPaymentMethod = 'UPI';

  // Calculate total items and price
  int get totalItems => widget.cart?.totalItems ?? widget.quantity!;
  String get totalPrice =>
      widget.cart?.totalPrice ??
      (double.parse(widget.singleProduct!.finalPrice) * widget.quantity!)
          .toString();

  @override
  void initState() {
    super.initState();
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

      // Create order model using the new factory constructor
      final order = OrderModel.fromShippingDetails(
        paymentMethod: _selectedPaymentMethod,
        shippingDetails: _shippingDetails!,
        items: _getOrderItems(),
        notes: null,
      );

      print('Creating order with data: ${order.toJson()}');

      // Create order
      final createdOrder = await _orderService.createOrder(order);

      print('Order created successfully: ${createdOrder.orderNumber}');

      // Clear cart if checkout was from cart
      // if (widget.cart != null) {
      //   await _cartService.clearCart();
      // }

      if (!mounted) return;

      // Show success screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => OrderAcceptedScreen(order: createdOrder),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      print('Failed to create order: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });

      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return OrderFailedDialog(error: _error);
        },
      );
    }
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
      appBar: AppBar(title: Text('Checkout'), elevation: 0),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                              'Order Summary',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(height: 16),
                            if (widget.singleProduct != null) ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(widget.singleProduct!.productName),
                                subtitle: Text('Quantity: ${widget.quantity}'),
                                trailing: Text(
                                  '₹${widget.singleProduct!.finalPrice}',
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Items:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '$totalItems',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹$totalPrice',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Shipping Details Form
                    ShippingDetailsForm(
                      initialDetails: _shippingDetails,
                      onSaved: (details) {
                        setState(() {
                          _shippingDetails = details;
                        });
                      },
                    ),
                    SizedBox(height: 16),
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
                        'Place Order',
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
