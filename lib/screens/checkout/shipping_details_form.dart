import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/services/order_service.dart';

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
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;

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
    _cityController = TextEditingController(
      text: widget.initialDetails?.city ?? '',
    );
    _stateController = TextEditingController(
      text: widget.initialDetails?.state ?? '',
    );
    _pincodeController = TextEditingController(
      text: widget.initialDetails?.pincode ?? '',
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
      _cityController.text = _savedAddress!.city;
      _stateController.text = _savedAddress!.state;
      _pincodeController.text = _savedAddress!.pincode;
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _pincodeController.clear();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
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
                'Shipping Details',
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
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
