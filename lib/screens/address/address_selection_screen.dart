import "package:grocery_app/common_widgets/global_import.dart";
import "package:grocery_app/common_widgets/global_import.dart" as http;
import "package:grocery_app/common_widgets/select_state.dart";

enum OrderType { self, other }

class AddressSelectionScreen extends StatefulWidget {
  final CartModel? cart;
  final Product? singleProduct;
  final String? paymentType;
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
    this.paymentType,
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
  Map<String, dynamic>? _deliveryDetails;
  Map<String, String>? _savedAddress;

  final authService = AuthService();

  OrderType _orderType = OrderType.self;

  // default to 'new' so UI won't assume saved address exists
  String _selectedAddressType = 'new';

  @override
  void initState() {
    super.initState(); 
    _pincodeController.addListener(_onPincodeChanged);
    _loadSavedAddress();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.removeListener(_onPincodeChanged);
    _pincodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onPincodeChanged() {
    final pincode = _pincodeController.text.trim();
    if (pincode.length == 6 && RegExp(r'^\d{6}$').hasMatch(pincode)) {
      _calculateDeliveryCharges(pincode);
    } else {
      setState(() {
        _deliveryDetails = null;
        _error = null;
      });
    }
  }

  void _loadSavedAddress() {
    final user = widget.user;
    if (user != null &&
        (user.address?.isNotEmpty ?? false) &&
        (user.city?.isNotEmpty ?? false) &&
        (user.state?.isNotEmpty ?? false) &&
        (user.pincode?.isNotEmpty ?? false) &&
        (user.phoneNumber.isNotEmpty)) {
      _savedAddress = {
        'address': user.address!,
        'city': user.city!,
        'state': user.state!,
        'pincode': user.pincode!,
        'phone': user.phoneNumber,
      };
      // default to saved if we have one
      _selectedAddressType = 'saved';
      // set form fields from saved address
      _selectAddress(_savedAddress!);
    } else {
      _selectedAddressType = 'new';
    }
    // ensure UI updates
    setState(() {});
  }

 Future<void> _calculateDeliveryCharges(String pincode) async {
  if (pincode.length != 6) return;

  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    // determine product_variant_id (safe null checks)
    final int? variantId = widget.singleProduct?.id ??
        widget.cart?.items.first.productVariant.id;

    if (variantId == null) {
      throw Exception('No product variant found to calculate delivery charges.');
    }

    final body = jsonEncode({
      'delivery_pincode': pincode,
      'items': [
        {'product_variant_id': variantId}
      ]
    });

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/core/delivery/calculate-charges/'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      // expected response: { "expected_delivery_date": "...", "delivery_charges": 93, "currency": "INR" }
      setState(() {
        _deliveryDetails = jsonDecode(response.body) as Map<String, dynamic>?;
        _error = null;
      });
    } else {
      final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      throw Exception(
          (errorBody is Map && errorBody['error'] != null) ? errorBody['error'] : 'Failed to calculate delivery charges');
    }
  } catch (e) {
    setState(() {
      _error = e.toString().replaceFirst('Exception: ', '');
      _deliveryDetails = null;
    });
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    } else {
      _isLoading = false;
    }
  }
}

  void _selectAddress(Map<String, String> address) {
    // Defensive: ensure keys exist
    setState(() {
      _addressController.text = address['address'] ?? '';
      _cityController.text = address['city'] ?? '';
      _stateController.text = address['state'] ?? '';
      _pincodeController.text = address['pincode'] ?? '';
      _phoneController.text = address['phone'] ?? '';
    });

    // After programmatic set, check pincode and calculate delivery if valid
    final pincode = (address['pincode'] ?? '').trim();
    if (pincode.length == 6 && RegExp(r'^\d{6}$').hasMatch(pincode)) {
      // run calculation; don't await here to keep UI responsive
      _calculateDeliveryCharges(pincode);
    } else {
      setState(() {
        _deliveryDetails = null;
      });
    }
  }

  void _clearAddressForm() {
    _formKey.currentState?.reset();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _pincodeController.clear();
    _phone_controller_clear_and_reset_delivery();
  }

  // small helper to clear pincode/delivery error state when clearing form
  void _phone_controller_clear_and_reset_delivery() {
    _phoneController.clear();
    setState(() {
      _deliveryDetails = null;
      _error = null;
    });
  }
  

  Future<bool> _updateUserAddress(Map<String, String> addressDetails) async {
    setState(() => _isLoading = true);
    final success = await AuthService().updateUserAddress(addressDetails);
    setState(() => _isLoading = false);

    if (!success && mounted) {
      SnackBarHelper.showError(context, 'Failed to save address. Please try again.');
    } else if (success && mounted) {
      SnackBarHelper.showSuccess(context, 'Address saved to your profile!');
    }
    return success;
  }

  void _onContinuePressed() async {
    if ((_orderType == OrderType.other ||
            (_orderType == OrderType.self && _selectedAddressType == 'new')) &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_deliveryDetails == null) {
      SnackBarHelper.showError(context, 'Please enter a valid pincode to check delivery.');
      return;
    }

    final shippingDetails = {
      'address': _addressController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'pincode': _pincodeController.text,
      'phone': _phoneController.text,
    };

    if (_orderType == OrderType.self && _selectedAddressType == 'new') {
      final wasSaved = await _updateUserAddress(shippingDetails);
      if (!wasSaved) return;
    }

    _navigateToCheckout(shippingDetails);
  }

  void _navigateToCheckout(Map<String, String> shippingDetails) {
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
                  _deliveryDetails?['delivery_charges']?.toString() ?? '0.0') ??
              0.0,
          expectedDeliveryDate: _deliveryDetails?['expected_delivery_date'] ?? '',
          paymentType: widget.paymentType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOrderTypeSelector(theme),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _orderType == OrderType.self
                  ? Column(
                      key: const ValueKey('self'),
                      children: [
                        if (_savedAddress != null) _buildSavedAddressOption(theme),
                        _buildNewAddressOption(theme, isForSelf: true),
                        if (_selectedAddressType == 'new') _buildNewAddressForm(theme, isForSelf: true),
                      ],
                    )
                  : Column(
                      key: const ValueKey('other'),
                      children: [
                        _buildNewAddressForm(theme, isForSelf: false),
                      ],
                    ),
            ),
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
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_deliveryDetails != null) _buildDeliveryDetailsCard(theme),
            const SizedBox(height: 24),
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeSelector(ThemeData theme) {
    return SegmentedButton<OrderType>(
      segments: const <ButtonSegment<OrderType>>[
        ButtonSegment(value: OrderType.self, label: Text('For Myself'), icon: Icon(Icons.person)),
        ButtonSegment(
            value: OrderType.other, label: Text('For Someone Else'), icon: Icon(Icons.card_giftcard)),
      ],
      selected: {_orderType},
      onSelectionChanged: (Set<OrderType> newSelection) {
        setState(() {
          _orderType = newSelection.first;
          if (_orderType == OrderType.self) {
            _loadSavedAddress();
          } else {
            _selectedAddressType = 'new';
            _clearAddressForm();
          }
        });
      },
      style: SegmentedButton.styleFrom(
          selectedBackgroundColor: theme.colorScheme.primary.withOpacity(0.2),
          selectedForegroundColor: theme.colorScheme.primary,
          textStyle: theme.textTheme.labelLarge),
    );
  }

  Widget _buildSavedAddressOption(ThemeData theme) {
    if (_savedAddress == null) return const SizedBox.shrink();

    final bool isSelected = _selectedAddressType == 'saved';
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAddressType = 'saved';
          // ensure saved address exists
          if (_savedAddress != null) _selectAddress(_savedAddress!);
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? theme.colorScheme.primary.withOpacity(0.6) : theme.dividerColor,
            width: 1.25,
          ),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // selection indicator (check icon)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
                  color: isSelected ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent,
                ),
                child: Icon(
                  isSelected ? Icons.check : Icons.check_box_outline_blank,
                  size: 18,
                  color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                ),
              ),
              const SizedBox(width: 12),
              // content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Use Saved Address', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${_savedAddress!['address']}, ${_savedAddress!['city']}',
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewAddressOption(ThemeData theme, {required bool isForSelf}) {
    final bool isSelected = _selectedAddressType == 'new';
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAddressType = 'new';
          _clearAddressForm();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? theme.colorScheme.primary.withOpacity(0.6) : theme.dividerColor,
            width: 1.25,
          ),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
                  color: isSelected ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent,
                ),
                child: Icon(
                  isSelected ? Icons.check : Icons.add,
                  size: 18,
                  color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isForSelf ? 'Add & Save a New Address' : 'Add a New Address',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewAddressForm(ThemeData theme, {bool isForSelf = true}) {
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
              Text(
                isForSelf ? 'New Address (will be saved)' : "Recipient's Address",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              CustomInput(
                hintText: "Full Address (House No, Street, Landmark)",
                controller: _addressController,
                keyboardType: TextInputType.streetAddress,
                validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: 16),
              SelectState(
                onCountryChanged: (_) {},
                onStateChanged: (v) => setState(() => _state_controller_safe_set(v)),
                onCityChanged: (v) => setState(() => _city_controller_safe_set(v)),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              CustomInput(
                hintText: "Pincode",
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Pincode is required';
                  final val = v.trim();
                  if (!RegExp(r'^\d{6}$').hasMatch(val)) return 'Enter a valid 6-digit pincode';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomInput(
                hintText: "Recipient's Phone Number",
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone number is required';
                  final val = v.trim();
                  if (!RegExp(r'^\d{10}$').hasMatch(val)) return 'Enter a valid 10-digit number';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // helper setters to avoid null-check operators in callbacks
  void _state_controller_safe_set(String? v) {
    _stateController.text = v ?? '';
  }

  void _city_controller_safe_set(String? v) {
    _cityController.text = v ?? '';
  }

  Widget _buildDeliveryDetailsCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 2,
      color: colorScheme.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
      ),
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.local_shipping, color: colorScheme.primary),
              title: const Text('Delivery Charges'),
              trailing: Text(
                '₹${_deliveryDetails?['delivery_charges'] ?? '0.0'}',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.calendar_today, color: colorScheme.primary),
              title: const Text('Expected Delivery'),
              trailing: Text(
                _deliveryDetails?['expected_delivery_date'] ?? 'N/A',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _onContinuePressed,
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
            )
          : const Text('Save Address & Continue'),
    );
  }
}
