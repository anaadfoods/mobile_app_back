import 'package:country_state_city_picker/country_state_city_picker.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/imput_widget.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/user_model.dart';
import 'package:grocery_app/screens/checkout/checkout_screen.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Updated version with a modern green theme, which calculates delivery
/// charges based on the pincode and passes all delivery details
/// to the CheckoutScreen.
class AddressSelectionScreen extends StatefulWidget {
  final CartModel? cart;
  final Product? singleProduct;
  final double? price;
  final int? quantity;
  final bool isSubscription;
  final int? selectedPlan;
  final UserModel? user = AuthService().currentUser;

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

  // No need for a separate country controller if it's always India
  final String _country = 'India';

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _deliveryDetails;

  List<Map<String, String>> _savedAddresses = [];
  String _selectedAddressType = 'saved'; // 'saved' or 'new'

  @override
  void initState() {
    super.initState();
    _pincodeController.addListener(_onPincodeChanged);
    _loadSavedAddresses();
  }

  /// Recalculates charges when the pincode is 6 digits long.
  void _onPincodeChanged() {
    final pincode = _pincodeController.text.trim();
    if (pincode.length == 6) {
      _calculateDeliveryCharges(pincode);
    } else {
      // Clear previous delivery details if pincode becomes invalid
      setState(() {
        _deliveryDetails = null;
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
          (widget.user?.phoneNumber.isNotEmpty ?? false)) {
        final savedAddress = {
          'address': widget.user!.address!,
          'city': widget.user!.city!,
          'state': widget.user!.state!,
          'pincode': widget.user!.pincode!,
          'phone': widget.user!.phoneNumber,
        };
        _savedAddresses.add(savedAddress);
        // Pre-select and calculate charges for the saved address
        _selectAddress(savedAddress);
      } else {
        // If there's no complete saved address, default to the new address form
        _selectedAddressType = 'new';
      }
    });
  }

  /// **CHANGED**: Calculates charges using pincode for better accuracy.
  Future<void> _calculateDeliveryCharges(String pincode) async {
    if (pincode.length != 6) return;

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
          'product_variant_id': widget.singleProduct?.id ??
              widget.cart?.items.first.productVariant.id,
          'delivery_pincode': pincode,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _deliveryDetails = jsonDecode(response.body);
        });
        print(_deliveryDetails);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to calculate delivery charges');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _deliveryDetails = null; // Clear details on error
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectAddress(Map<String, String> address) {
    setState(() {
      _addressController.text = address['address']!;
      _cityController.text = address['city']!;
      _stateController.text = address['state']!;
      _pincodeController.text = address['pincode']!;
      _phoneController.text = address['phone']!;
    });
    // The listener on _pincodeController will automatically trigger charge calculation.
  }

  void _clearAddressForm() {
    _formKey.currentState?.reset();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _pincodeController.clear();
    _phoneController.clear();
    setState(() {
      _deliveryDetails = null;
      _error = null;
    });
  }
  // ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = Colors.green.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Address'),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_savedAddresses.isNotEmpty)
              _buildSavedAddressOption(theme, primaryColor),

            _buildNewAddressOption(theme, primaryColor),

            if (_selectedAddressType == 'new') _buildNewAddressForm(theme, primaryColor),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_deliveryDetails != null) _buildDeliveryDetailsCard(theme),

            const SizedBox(height: 24),
            _buildContinueButton(AppColors.bottonBackgroundColor),
          ],
        ),
      ),
    );
  }

  // ───────────────── UI Helpers ───────────────────────────────

  Card _buildSavedAddressOption(ThemeData theme, Color primaryColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: RadioListTile<String>(
        value: 'saved',
        groupValue: _selectedAddressType,
        onChanged: (val) {
          setState(() => _selectedAddressType = val!);
          _selectAddress(_savedAddresses[0]);
        },
        title: Text('Use Saved Address', style: theme.textTheme.titleMedium),
        subtitle: Text(
          '${_savedAddresses[0]['address']}, ${_savedAddresses[0]['city']}',
          style: theme.textTheme.bodySmall,
        ),
        activeColor: primaryColor,
      ),
    );
  }

  Card _buildNewAddressOption(ThemeData theme, Color primaryColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: RadioListTile<String>(
        value: 'new',
        groupValue: _selectedAddressType,
        onChanged: (val) {
          setState(() => _selectedAddressType = val!);
          _clearAddressForm();
        },
        title: Text('Add a New Address', style: theme.textTheme.titleMedium),
        activeColor: primaryColor,
      ),
    );
  }

  Widget _buildNewAddressForm(ThemeData theme, Color primaryColor) {
    return Form(
      key: _formKey,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Delivery Address', style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),
             CustomInput(
                    hintText: "Address",
                    controller: _addressController,
                    keyboardType: TextInputType.text,
                    validator: (v) {
                      if (v!.isEmpty) return 'Enter a message';
                      return null;
                    },
                  ),
              const SizedBox(height: 16),
              // Using the package for State/City selection
              SelectState(
                onCountryChanged: (_) {}, // Country is fixed to India
                onStateChanged: (v) => setState(() => _stateController.text = v),
                onCityChanged: (v) => setState(() => _cityController.text = v),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              CustomInput(
                hintText: "Pincode",
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v!.isEmpty) return 'Pincode is required';
                  if (v.length != 6) return 'Enter a valid 6-digit pincode';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomInput(
                hintText: "Phone Number",
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Phone number is required' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// **NEW**: Modern delivery details card with icons.
  Widget _buildDeliveryDetailsCard(ThemeData theme) {
    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200),
      ),
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Details', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.local_shipping, color: Colors.green),
              title: const Text('Delivery Charges'),
              trailing: Text(
                '₹${_deliveryDetails!['delivery_charges']}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.green),
              title: const Text('Expected Delivery Date'),
              trailing: Text(
                _deliveryDetails!['expected_delivery_date'] ?? 'N/A',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(Color primaryColor) {
    return ElevatedButton(
      onPressed: _onContinuePressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text(
        'Save Address & Continue',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
  
  InputDecoration _inputDecoration(String label, Color primaryColor) {
    return InputDecoration(
      labelText: label,
      counterText: "", // Hides the counter for maxLength
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  void _onContinuePressed() {
    // Validate form if a new address is being entered
    if (_selectedAddressType == 'new' && !_formKey.currentState!.validate()) {
      return;
    }

    // Check if delivery details have been calculated
    if (_deliveryDetails == null) {
      SnackBarHelper.showError(
        context,
        'Please enter a valid pincode to calculate delivery charges.',
      );
      return;
    }

    final shippingDetails = {
      'address': _addressController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'pincode': _pincodeController.text,
      'phone': _phoneController.text,
    };

    _navigateToCheckout(shippingDetails);
  }

  /// **UPDATED**: Passes the full delivery details to the next screen.
  void _navigateToCheckout(Map<String, String> shippingDetails) {

    print(widget.cart);
    print(widget.selectedPlan);
    print(widget.isSubscription);

   
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cart: widget.cart,
          singleProduct: widget.singleProduct,
          price: widget.price,
          quantity: widget.quantity,
          isSubscription: widget.isSubscription,
          selectedPlan: widget.selectedPlan,
          shippingDetails: shippingDetails,
          deliveryCharges: double.tryParse(
                _deliveryDetails?['delivery_charges']?.toString() ?? '0.0',
              ) ?? 0.0,
          // **FIXED**: Now passing the expected delivery date
          expectedDeliveryDate: _deliveryDetails?['expected_delivery_date'] ?? '',
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
    _pincodeController.removeListener(_onPincodeChanged); // Important!
    _pincodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}