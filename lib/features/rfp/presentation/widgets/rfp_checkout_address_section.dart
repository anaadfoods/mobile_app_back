import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_address.dart';
import '../cubit/rfp_checkout_cubit.dart';
import '../rfp_theme.dart';
import 'rfp_address_editor_sheet.dart';

/// Delivery destination section and editor for RFP Checkout, connected to UserAddress model.
class RfpCheckoutAddressSection extends StatelessWidget {
  final RfpCheckoutState state;

  const RfpCheckoutAddressSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final hasAddress =
        state.fullName.isNotEmpty || state.addressLine.isNotEmpty;
    final UserAddress? selectedAddress =
        state.savedAddresses.where((a) => a.id == state.addressId).firstOrNull;
    final addressLabel =
        selectedAddress?.label ?? (state.addressId != null ? 'SAVED' : null);

    return Container(
      padding: const EdgeInsets.all(RfpTheme.spaceLg),
      decoration: BoxDecoration(
        color: RfpTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
        boxShadow: RfpTheme.shadowSm,
        border: Border.all(
          color: RfpTheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: RfpTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DELIVERY DESTINATION',
                    style: RfpTheme.labelSm.copyWith(
                      color: RfpTheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => RfpAddressEditorSheet.show(context, state),
                icon: Icon(
                  hasAddress
                      ? Icons.edit_outlined
                      : Icons.add_location_alt_outlined,
                  size: 16,
                  color: RfpTheme.primary,
                ),
                label: Text(
                  hasAddress ? 'Change' : 'Add Address',
                  style: RfpTheme.labelMd.copyWith(
                    color: RfpTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (state.isLoadingAddresses)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (!hasAddress) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => RfpAddressEditorSheet.show(context, state),
              borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RfpTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
                  border: Border.all(
                    color: RfpTheme.outlineVariant,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: RfpTheme.primaryFixed,
                      child: Icon(
                        Icons.add_home_outlined,
                        color: RfpTheme.onPrimaryFixed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No delivery address selected',
                            style: RfpTheme.headlineSm.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to select a saved address or enter a new one',
                            style: RfpTheme.bodySm.copyWith(
                              color: RfpTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: RfpTheme.outline),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: RfpTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
                border: Border.all(
                  color: RfpTheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getLabelIcon(addressLabel),
                        size: 18,
                        color: RfpTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.fullName.isEmpty ? 'Customer' : state.fullName,
                          style: RfpTheme.headlineSm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: RfpTheme.onSurface,
                          ),
                        ),
                      ),
                      if (addressLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: RfpTheme.primaryFixed,
                            borderRadius: BorderRadius.circular(
                              RfpTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            addressLabel.toUpperCase(),
                            style: RfpTheme.labelSm.copyWith(
                              color: RfpTheme.onPrimaryFixed,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      if (selectedAddress?.isDefault == true) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: RfpTheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(
                              RfpTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            'DEFAULT',
                            style: RfpTheme.labelSm.copyWith(
                              color: RfpTheme.onSecondaryContainer,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (state.addressLine.isNotEmpty)
                    Text(
                      state.addressLine,
                      style: RfpTheme.bodyMd.copyWith(
                        color: RfpTheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                  if (state.city.isNotEmpty || state.pincode.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        [
                          if (state.city.isNotEmpty) state.city,
                          if (state.state.isNotEmpty) state.state,
                          if (state.pincode.isNotEmpty) 'PIN: ${state.pincode}',
                        ].join(', '),
                        style: RfpTheme.bodySm.copyWith(
                          color: RfpTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (state.phone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: RfpTheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          state.phone,
                          style: RfpTheme.bodySm.copyWith(
                            color: RfpTheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Multiple saved addresses switcher
            if (state.savedAddresses.length > 1) ...[
              const SizedBox(height: RfpTheme.spaceMd),
              Row(
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 14,
                    color: RfpTheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Saved Addresses (${state.savedAddresses.length}):',
                    style: RfpTheme.labelSm.copyWith(
                      color: RfpTheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      state.savedAddresses.map((addr) {
                        final isSelected = state.addressId == addr.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            avatar: Icon(
                              _getLabelIcon(addr.label),
                              size: 14,
                              color:
                                  isSelected
                                      ? RfpTheme.onPrimary
                                      : RfpTheme.onSurfaceVariant,
                            ),
                            label: Text(
                              '${addr.label} • ${addr.city}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isSelected
                                        ? RfpTheme.onPrimary
                                        : RfpTheme.onSurface,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: RfpTheme.primary,
                            backgroundColor: RfpTheme.surfaceContainerHigh,
                            onSelected: (_) {
                              context
                                  .read<RfpCheckoutCubit>()
                                  .selectSavedAddress(addr);
                            },
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  IconData _getLabelIcon(String? label) {
    switch (label?.toUpperCase()) {
      case 'HOME':
        return Icons.home_rounded;
      case 'OFFICE':
      case 'WORK':
        return Icons.business_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }
}
