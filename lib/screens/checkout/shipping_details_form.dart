import 'package:country_state_city_picker/country_state_city_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/services/order_service.dart';
import 'package:country_state_city_pro/country_state_city_pro.dart';

class ShippingDetailsForm extends StatefulWidget {
  final ShippingDetails? initialDetails;
  final Function(ShippingDetails) onSaved;

  const ShippingDetailsForm({
    Key? key,
    this.initialDetails,
    required this.onSaved,
  }) : super(key: key);

  @override
  _ShippingDetailsFormState createState() => _ShippingDetailsFormState();
}

class _ShippingDetailsFormState extends State<ShippingDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  ShippingDetails? _savedAddress;
  bool _useExistingAddress = false;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _countryController;
  late final TextEditingController _stateController;
  late final TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialDetails?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialDetails?.phone ?? '',
    );
    _addressController = TextEditingController(
      text: widget.initialDetails?.address ?? '',
    );
    _pincodeController = TextEditingController(
      text: widget.initialDetails?.pincode ?? '',
    );
    _countryController = TextEditingController();
    _stateController = TextEditingController(
      text: widget.initialDetails?.state ?? '',
    );
    _cityController = TextEditingController(
      text: widget.initialDetails?.city ?? '',
    );
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    try {
      final savedAddress = await _orderService.getUserShippingDetails();
      if (mounted) {
        setState(() {
          _savedAddress = savedAddress;
          _isLoading = false;
          if (savedAddress != null && widget.initialDetails == null) {
            _useExistingAddress = true;
            _updateFormWithSavedAddress();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateFormWithSavedAddress() {
    if (_savedAddress != null) {
      _nameController.text = _savedAddress!.name;
      _phoneController.text = _savedAddress!.phone;
      _addressController.text = _savedAddress!.address;
      _pincodeController.text = _savedAddress!.pincode;
      _countryController.text = 'India';
      _stateController.text = _savedAddress!.state;
      _cityController.text = _savedAddress!.city;
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _pincodeController.clear();
    _countryController.text = 'India';
    _stateController.clear();
    _cityController.clear();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final details = ShippingDetails(
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
      );
      widget.onSaved(details);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          onChanged: _saveForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length != 10) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    
                         SelectState(
              onCountryChanged: (value) {
              setState(() {
                _countryController.text = value;
              });
            },
            onStateChanged:(value) {
              setState(() {
                _stateController.text = value;
              });
            },
             onCityChanged:(value) {
              setState(() {
                _cityController.text = value;
              });
            },
            
            ),
                    //   defaultCountry: CscCountry.India,
                    //   onCountryChanged: (value) =>
                    //       _countryController.text = value ?? 'India',
                    //   onStateChanged:
                    //       (value) => _stateController.text = value ?? '',
                    // //   onCityChanged:
                    // //       (value) => _cityController.text = value ?? '',
                     
                    // // ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _pincodeController,
                decoration: InputDecoration(
                  labelText: 'PIN Code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter PIN code';
                  }
                  if (value.length != 6) {
                    return 'Please enter a valid 6-digit PIN code';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
