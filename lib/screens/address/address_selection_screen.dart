import 'package:country_state_city_pro/country_state_city_pro.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/user_model.dart';
import 'package:grocery_app/screens/checkout/checkout_screen.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddressSelectionScreen extends StatefulWidget {
  final CartModel? cart;
  final ProductVariant? singleProduct;
  final double? price;
  final int? quantity;
  final bool isSubscription;
  final int? selectedPlan;
  final UserModel? user = AuthService().currentUser;
  double? deliveryCharges;

  AddressSelectionScreen({
    super.key,
    this.cart,
    this.price,
    this.singleProduct,
    this.quantity,
    this.isSubscription = false,
    this.selectedPlan,
  }) : assert(cart != null || (singleProduct != null && quantity != null));

  @override
  _AddressSelectionScreenState createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _deliveryCharges;
  bool _showNewAddressForm = false;
  List<Map<String, String>> _savedAddresses = [];

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
    _loadSavedAddresses();
  }

  Future<void> _loadUserAddress() async {
    try {
      final authService = AuthService();
      final user = authService.currentUser;

      if (user != null) {
        setState(() {
          _addressController.text = user.address ?? '';
          _cityController.text = user.city ?? '';
          _stateController.text = user.state ?? '';
          _pincodeController.text = user.pincode ?? '';
          _phoneController.text = user.phoneNumber ?? '';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _loadSavedAddresses() async {
    setState(() {
      _savedAddresses = [];
      if ((widget.user?.address?.isNotEmpty ?? false) &&
          (widget.user?.city?.isNotEmpty ?? false) &&
          (widget.user?.state?.isNotEmpty ?? false) &&
          (widget.user?.pincode?.isNotEmpty ?? false) &&
          (widget.user?.phoneNumber?.isNotEmpty ?? false)) {
        _savedAddresses.add({
          'address': widget.user!.address!,
          'city': widget.user!.city!,
          'state': widget.user!.state!,
          'pincode': widget.user!.pincode!,
          'phone': widget.user!.phoneNumber!,
        });
      }
    });
  }

  Future<void> _calculateDeliveryCharges(String state, String city) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://13.203.212.133:8000/api/core/delivery/calculate-charges/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'product_variant_id':
              widget.singleProduct?.id ??
              widget.cart?.items.first.productVariant.id,
          'delivery_state': state,
          'delivery_city': city,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _deliveryCharges = jsonDecode(response.body);
          print('Delivery charges response: $_deliveryCharges');
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to calculate delivery charges');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectAddress(Map<String, String?> address) async {
    print('Selected address: ' + address.toString());
    final state = address['state'];
    final city = address['city'];
    final addr = address['address'];
    final pincode = address['pincode'];
    final phone = address['phone'];

    if ([
      state,
      city,
      addr,
      pincode,
      phone,
    ].any((v) => v == null || v.isEmpty)) {
      setState(() {
        _error =
            'Selected address is incomplete. Please edit or add a new address.';
      });
      return;
    }

    setState(() {
      _addressController.text = addr!;
      _cityController.text = city!;
      _stateController.text = state!;
      _pincodeController.text = pincode!;
      _phoneController.text = phone!;
      _showNewAddressForm = false;
    });
    await _calculateDeliveryCharges(state!, city!);
  }

  void _proceedToCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    // Calculate delivery charges if not already calculated
    if (_deliveryCharges == null) {
      await _calculateDeliveryCharges(
        _stateController.text,
        _cityController.text,
      );
      if (_deliveryCharges == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to calculate delivery charges. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    print('Proceeding to checkout with:');
    print('cart: ${widget.cart}');
    print('singleProduct: ${widget.singleProduct}');
    print('price: ${widget.price}');
    print('quantity: ${widget.quantity}');
    print('isSubscription: ${widget.isSubscription}');
    print('selectedPlan: ${widget.selectedPlan}');
    print('shippingDetails:');
    print('  address: ${_addressController.text}');
    print('  city: ${_cityController.text}');
    print('  state: ${_stateController.text}');
    print('  pincode: ${_pincodeController.text}');
    print('  phone: ${_phoneController.text}');
    print('deliveryCharges: $_deliveryCharges');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CheckoutScreen(
              cart: widget.cart,
              singleProduct: widget.singleProduct,
              price: widget.price,
              quantity: widget.quantity,
              isSubscription: widget.isSubscription,
              selectedPlan: widget.selectedPlan,
              shippingDetails: {
                'address': _addressController.text,
                'city': _cityController.text,
                'state': _stateController.text,
                'pincode': _pincodeController.text,
                'phone': _phoneController.text,
              },
              deliveryCharges: double.parse(
                _deliveryCharges?['delivery_charges'] ?? '0',
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Delivery Address'), elevation: 0),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Saved Addresses Section
                    if (!_showNewAddressForm) ...[
                      // Text(
                      //   'Select Delivery Address',
                      //   style: Theme.of(context).textTheme.titleLarge,
                      // ),
                      // SizedBox(height: 16),
                      // ..._savedAddresses
                      //     .where(
                      //       (address) =>
                      //           address['address']?.isNotEmpty == true &&
                      //           address['city']?.isNotEmpty == true &&
                      //           address['state']?.isNotEmpty == true &&
                      //           address['pincode']?.isNotEmpty == true &&
                      //           address['phone']?.isNotEmpty == true,
                      //     )
                      //     .map(
                      //       (address) => Card(
                      //         margin: EdgeInsets.only(bottom: 16),
                      //         child: ListTile(
                      //           title: Text(address['address']!),
                      //           subtitle: Text(
                      //             '${address['city']}, ${address['state']}',
                      //           ),
                      //           trailing: Icon(Icons.arrow_forward_ios),
                      //           onTap: () => _selectAddress(address),
                      //         ),
                      //       ),
                      //     ),
                      // SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showNewAddressForm = true;
                          });
                        },
                        icon: Icon(Icons.add),
                        label: Text('Add New Address'),
                      ),
                    ] else ...[
                      // New Address Form
                      Form(
                        key: _formKey,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'New Delivery Address',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          _showNewAddressForm = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: InputDecoration(
                                    labelText: 'Address',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your address';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    // Expanded(
                                    //   child: TextFormField(
                                    //     controller: _cityController,
                                    //     decoration: InputDecoration(
                                    //       labelText: 'City',
                                    //       border: OutlineInputBorder(),
                                    //     ),
                                    //     validator: (value) {
                                    //       if (value == null || value.isEmpty) {
                                    //         return 'Please enter your city';
                                    //       }
                                    //       return null;
                                    //     },
                                    //   ),
                                    // ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: CountryStateCityPicker(
                                        country: TextEditingController(
                                          text: "India",
                                        ),
                                        state: TextEditingController(
                                          text: _stateController.text,
                                        ),
                                        city: TextEditingController(
                                          text: _cityController.text,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _pincodeController,
                                        decoration: InputDecoration(
                                          labelText: 'Pincode',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your pincode';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _phoneController,
                                        decoration: InputDecoration(
                                          labelText: 'Phone Number',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.phone,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your phone number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_error != null)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    if (_deliveryCharges != null) ...[
                      SizedBox(height: 16),
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
                                'Delivery Charges',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '₹${_deliveryCharges!['delivery_charges']}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _proceedToCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save Address & Continue',
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

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
