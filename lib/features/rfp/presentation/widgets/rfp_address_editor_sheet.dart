import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/rfp_checkout_cubit.dart';
import '../rfp_theme.dart';

/// Modal bottom sheet for viewing, selecting, and editing delivery addresses in RFP Checkout.
class RfpAddressEditorSheet extends StatefulWidget {
  final RfpCheckoutState state;

  const RfpAddressEditorSheet({super.key, required this.state});

  static Future<void> show(BuildContext context, RfpCheckoutState state) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RfpTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RfpTheme.radiusXl),
        ),
      ),
      builder: (ctx) => RfpAddressEditorSheet(state: state),
    );
  }

  @override
  State<RfpAddressEditorSheet> createState() => _RfpAddressEditorSheetState();
}

class _RfpAddressEditorSheetState extends State<RfpAddressEditorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addrCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _phoneCtrl;
  String _selectedLabel = 'HOME';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.state.fullName);
    _addrCtrl = TextEditingController(text: widget.state.addressLine);
    _cityCtrl = TextEditingController(text: widget.state.city);
    _stateCtrl = TextEditingController(text: widget.state.state);
    _pinCtrl = TextEditingController(text: widget.state.pincode);
    _phoneCtrl = TextEditingController(text: widget.state.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pinCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        RfpTheme.gutter,
        RfpTheme.spaceLg,
        RfpTheme.gutter,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery Address', style: RfpTheme.headlineSm),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            // Saved Addresses Picker
            if (state.savedAddresses.isNotEmpty) ...[
              const SizedBox(height: RfpTheme.spaceSm),
              Text(
                'Saved Addresses',
                style: RfpTheme.labelSm.copyWith(
                  color: RfpTheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              ...state.savedAddresses.map((addr) {
                final isSelected = state.addressId == addr.id;
                return InkWell(
                  onTap: () {
                    context.read<RfpCheckoutCubit>().selectSavedAddress(addr);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? RfpTheme.primary.withValues(alpha: 0.08)
                              : RfpTheme.surfaceContainerLowest,
                      border: Border.all(
                        color:
                            isSelected
                                ? RfpTheme.primary
                                : RfpTheme.outlineVariant,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color:
                              isSelected ? RfpTheme.primary : RfpTheme.outline,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    addr.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: RfpTheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      addr.label,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${addr.formattedAddress}, ${addr.city}, ${addr.pincode}',
                                style: TextStyle(
                                  color: RfpTheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: RfpTheme.spaceMd),
              const Divider(height: 1),
              const SizedBox(height: RfpTheme.spaceMd),
              Text(
                'Or Add / Edit Address',
                style: RfpTheme.labelSm.copyWith(
                  color: RfpTheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
            ],

            const SizedBox(height: RfpTheme.spaceSm),
            // Address Label Picker (Home / Office / Other)
            Row(
              children:
                  ['HOME', 'OFFICE', 'OTHER'].map((label) {
                    final isSel = _selectedLabel == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          label,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: isSel,
                        selectedColor: RfpTheme.primaryFixed,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedLabel = label;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: RfpTheme.spaceSm),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: RfpTheme.spaceSm),
            TextField(
              controller: _addrCtrl,
              decoration: const InputDecoration(
                labelText: 'Address (House/Flat, Street) *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: RfpTheme.spaceSm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _stateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: RfpTheme.spaceSm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pinCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Pincode *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: RfpTheme.spaceLg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final name = _nameCtrl.text.trim();
                  final addr = _addrCtrl.text.trim();
                  final city = _cityCtrl.text.trim();
                  final st = _stateCtrl.text.trim();
                  final pin = _pinCtrl.text.trim();
                  final phone = _phoneCtrl.text.trim();

                  if (name.isEmpty ||
                      addr.isEmpty ||
                      city.isEmpty ||
                      pin.isEmpty ||
                      phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please fill all required address fields',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  context.read<RfpCheckoutCubit>().saveNewAddress(
                    fullName: name,
                    addressLine: addr,
                    city: city,
                    state: st,
                    pincode: pin,
                    phone: phone,
                    label: _selectedLabel,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: RfpTheme.primary,
                  foregroundColor: RfpTheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
                  ),
                ),
                child: const Text('Save & Use Address'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
