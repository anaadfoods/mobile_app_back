import 'package:country_state_city_picker/country_state_city_picker.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/user_model.dart';
import 'package:grocery_app/screens/checkout/checkout_screen.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Updated version – auto‑recalculates delivery charges when
/// state & city are both chosen, and shows the pre‑filled address
/// in the dropdowns.
class AddressSelectionScreen extends StatefulWidget {
  final CartModel? cart;
  final ProductVariant? singleProduct;
  final double? price;
  final int? quantity;
  final bool isSubscription;
  final int selectedPlan;
  final UserModel? user = AuthService().currentUser;
  double? deliveryCharges;
  final bool showNewAddressForm;

  AddressSelectionScreen({
    super.key,
    this.cart,
    this.showNewAddressForm = true,
    this.price,
    this.singleProduct,
    this.quantity,
    this.isSubscription = false,
    this.selectedPlan = 0,
  }) : assert(cart != null || (singleProduct != null && quantity != null));

  @override
  _AddressSelectionScreenState createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _deliveryCharges;

  List<Map<String, String>> _savedAddresses = [];
  String _selectedAddressType = 'saved'; // 'saved' or 'new'

  // ────────────────────────────────────────────────────────────
  /// When both state **and** city have values, (re)query delivery fee.
  void _maybeRecalculateCharges() {
    final state = _stateController.text.trim();
    final city = _cityController.text.trim();
    if (state.isNotEmpty && city.isNotEmpty) {
      _calculateDeliveryCharges(state, city);
    }
  }

  @override
  void initState() {
    super.initState();
    // _loadUserAddress();
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
          _countryController.text = 'India';
          _stateController.text = user.state ?? '';
          _pincodeController.text = user.pincode ?? '';
          _phoneController.text = user.phoneNumber ?? '';
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
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
          'country': 'India',
          'state': widget.user!.state!,
          'pincode': widget.user!.pincode!,
          'phone': widget.user!.phoneNumber!,
        });
      }

      // If there are no saved addresses, default to new.
      if (_savedAddresses.isEmpty) _selectedAddressType = 'new';
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
          'https://app.anaadfoods.com/api/core/delivery/calculate-charges/',
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

  /// Fills controllers from a saved address & triggers charge calc.
  void _selectAddress(Map<String, String> address) {
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
      setState(
        () =>
            _error =
                'Selected address is incomplete. Please edit or add a new address.',
      );
      return;
    }

    setState(() {
      _addressController.text = addr!;
      _cityController.text = city!;
      _stateController.text = state!;
      _countryController.text = 'India';
      _pincodeController.text = pincode!;
      _phoneController.text = phone!;
    });
    _calculateDeliveryCharges(state!, city!);
  }

  // ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Address'), elevation: 0),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Saved address radio
                    if (_savedAddresses.isNotEmpty)
                      Card(
                        child: RadioListTile<String>(
                          value: 'saved',
                          groupValue: _selectedAddressType,
                          onChanged: (val) {
                            setState(() => _selectedAddressType = val!);
                            if (val == 'saved')
                              _selectAddress(_savedAddresses[0]);
                          },
                          title: Text(_savedAddresses[0]['address']!),
                          subtitle: Text(
                            '${_savedAddresses[0]['city']}, ${_savedAddresses[0]['state']}\n${_savedAddresses[0]['phone']}',
                          ),
                        ),
                      ),

                    // New address radio
                    Card(
                      child: RadioListTile<String>(
                        value: 'new',
                        groupValue: _selectedAddressType,
                        onChanged: (val) {
                          setState(() => _selectedAddressType = val!);
                        },
                        title: const Text('Fill New Address'),
                      ),
                    ),

                    // New address form
                    if (_selectedAddressType == 'new')
                      _buildNewAddressForm(context),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    if (_deliveryCharges != null) _buildDeliveryCard(context),

                    const SizedBox(height: 24),
                    _buildContinueButton(context),
                  ],
                ),
              ),
    );
  }

  // ───────────────── UI helpers ───────────────────────────────
  Widget _buildNewAddressForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Delivery Address',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        v == null || v.isEmpty
                            ? 'Please enter your address'
                            : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: SelectState(
                      // countryController: _countryController,
                      // stateController: _stateController,
                      // cityController: _cityController,
                      onCountryChanged:
                          (_) =>
                              setState(() => _countryController.text = 'India'),
                      onStateChanged: (v) {
                        setState(() => _stateController.text = v);
                        _maybeRecalculateCharges();
                      },
                      onCityChanged: (v) {
                        setState(() => _cityController.text = v);
                        _maybeRecalculateCharges();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      decoration: const InputDecoration(
                        labelText: 'Pincode',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? 'Please enter your pincode'
                                  : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? 'Please enter your phone number'
                                  : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Charges',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '₹${_deliveryCharges!['delivery_charges']}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            if (_deliveryCharges!['error'] != null) ...[
              const SizedBox(height: 4),
              Text(
                _deliveryCharges!['error'],
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _onContinuePressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Save Address & Continue',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  void _onContinuePressed() async {
    if (_selectedAddressType == 'saved') {
      final user = widget.user;
      if (user == null ||
          [
            user.address,
            user.city,
            user.state,
            user.pincode,
            user.phoneNumber,
          ].any((e) => e == null || e!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved address is incomplete.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Ensure we have delivery fee
      if (_deliveryCharges == null)
        await _calculateDeliveryCharges(user.state!, user.city!);
      if (_deliveryCharges == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to calculate delivery charges. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      _navigateToCheckout({
        'address': user.address!,
        'city': user.city!,
        'state': user.state!,
        'pincode': user.pincode!,
        'phone': user.phoneNumber!,
      });
    } else {
      // new address validation
      if (!_formKey.currentState!.validate()) return;
      if (_deliveryCharges == null)
        await _calculateDeliveryCharges(
          _stateController.text,
          _cityController.text,
        );
      if (_deliveryCharges == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to calculate delivery charges. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      _navigateToCheckout({
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
        'phone': _phoneController.text,
      });
    }
  }

  void _navigateToCheckout(Map<String, String> shippingDetails) {
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
              shippingDetails: shippingDetails,
              deliveryCharges:
                  double.tryParse(
                    _deliveryCharges?['delivery_charges']?.toString() ?? '0',
                  ) ??
                  0.0,
            ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    super.dispose();
  }
}
