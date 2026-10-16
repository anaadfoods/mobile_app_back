import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/rfp_batch_cubit.dart';
import '../rfp_theme.dart';

/// Modal bottom sheet allowing the user to view and change their RFP city and delivery location.
class RfpCitySelectionSheet extends StatelessWidget {
  final RfpBatchState state;

  const RfpCitySelectionSheet({super.key, required this.state});

  static void show(BuildContext context, RfpBatchState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RfpTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RfpTheme.radiusXl),
        ),
      ),
      builder: (ctx) => RfpCitySelectionSheet(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cityCtrl = TextEditingController(text: state.selectedCityName);
    return Padding(
      padding: EdgeInsets.only(
        left: RfpTheme.gutter,
        right: RfpTheme.gutter,
        top: RfpTheme.spaceLg,
        bottom: MediaQuery.of(context).viewInsets.bottom + RfpTheme.spaceXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Farming Location', style: RfpTheme.headlineSm),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: RfpTheme.spaceXs),
          Text(
            'Enter your city name or choose your nearest delivery cluster',
            style: RfpTheme.bodySm.copyWith(color: RfpTheme.onSurfaceVariant),
          ),
          const SizedBox(height: RfpTheme.spaceMd),
          TextField(
            controller: cityCtrl,
            decoration: InputDecoration(
              labelText: 'City / Region Name',
              hintText: 'e.g. Gurugram, Delhi NCR, Noida',
              prefixIcon: const Icon(
                Icons.location_city,
                color: RfpTheme.primary,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check, color: RfpTheme.primary),
                onPressed: () {
                  final text = cityCtrl.text.trim();
                  if (text.isNotEmpty) {
                    context.read<RfpBatchCubit>().setLocation('loc_01', text);
                    Navigator.pop(context);
                  }
                },
              ),
              filled: true,
              fillColor: RfpTheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                context.read<RfpBatchCubit>().setLocation('loc_01', val.trim());
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: RfpTheme.spaceMd),
          Text(
            'Available RFP Hubs',
            style: RfpTheme.labelSm.copyWith(color: RfpTheme.onSurfaceVariant),
          ),
          const SizedBox(height: RfpTheme.spaceXs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCityOptionChip(
                context,
                'Valley Sector 4',
                'loc_01',
                state.selectedCityName,
              ),
              _buildCityOptionChip(
                context,
                'Green Valley Estate',
                'loc_02',
                state.selectedCityName,
              ),
              _buildCityOptionChip(
                context,
                'Sunrise Organic Farms',
                'loc_03',
                state.selectedCityName,
              ),
              _buildCityOptionChip(
                context,
                'Gurugram Central',
                'loc_01',
                state.selectedCityName,
              ),
              _buildCityOptionChip(
                context,
                'South Delhi Cluster',
                'loc_02',
                state.selectedCityName,
              ),
            ],
          ),
          const SizedBox(height: RfpTheme.spaceLg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final text = cityCtrl.text.trim();
                if (text.isNotEmpty) {
                  context.read<RfpBatchCubit>().setLocation('loc_01', text);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RfpTheme.primary,
                foregroundColor: RfpTheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
                ),
              ),
              child: const Text('Confirm Location'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityOptionChip(
    BuildContext context,
    String cityName,
    String locId,
    String selectedCity,
  ) {
    final isSelected = cityName.toLowerCase() == selectedCity.toLowerCase();
    return FilterChip(
      label: Text(cityName),
      selected: isSelected,
      onSelected: (_) {
        context.read<RfpBatchCubit>().setLocation(locId, cityName);
        Navigator.pop(context);
      },
      selectedColor: RfpTheme.primaryContainer,
      labelStyle: RfpTheme.bodySm.copyWith(
        color: isSelected ? RfpTheme.onPrimaryContainer : RfpTheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      backgroundColor: RfpTheme.surfaceContainerLow,
      side: BorderSide(
        color: isSelected ? RfpTheme.primary : RfpTheme.outlineVariant,
      ),
    );
  }
}
