import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/rfp_patch.dart';
import '../cubit/rfp_patch_config_cubit.dart';
import '../cubit/rfp_batch_cubit.dart';
import '../rfp_theme.dart';
import '../widgets/rfp_vegetable_tile.dart';
import '../widgets/rfp_frequency_option.dart';

/// Configure Patch screen — reproduces configure_p1/screen.png
///
/// Vegetable toggle list, exclusion counter, weight selector,
/// delivery frequency radio, and "Save & Continue" CTA.
class RfpConfigurePatchScreen extends StatelessWidget {
  final String patchId;
  const RfpConfigurePatchScreen({super.key, required this.patchId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RfpPatchConfigCubit, RfpPatchConfigState>(
      builder: (context, state) {
        if (state.patch == null) {
          return const Scaffold(
            backgroundColor: RfpTheme.surface,
            body: Center(
              child: CircularProgressIndicator(color: RfpTheme.primary),
            ),
          );
        }
        return _buildContent(context, state);
      },
    );
  }

  Widget _buildContent(BuildContext context, RfpPatchConfigState state) {
    final patch = state.patch!;
    return Scaffold(
      backgroundColor: RfpTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: RfpTheme.gutter,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildHeader(context),
                          const SizedBox(height: RfpTheme.spaceMd),
                          _buildTitle(context, patch),
                          const SizedBox(height: RfpTheme.spaceLg),
                          _buildVegetableSection(context, state, patch),
                          const SizedBox(height: RfpTheme.spaceLg),
                          _buildWeightSection(context, state, patch),
                          const SizedBox(height: RfpTheme.spaceLg),
                          _buildFrequencySection(context, state),
                          const SizedBox(height: RfpTheme.spaceLg),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildSaveButton(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cityName = context.watch<RfpBatchCubit>().state.selectedCityName;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: RfpTheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.eco,
            color: RfpTheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        const SizedBox(width: RfpTheme.spaceSm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location',
              style: RfpTheme.labelSm.copyWith(
                color: RfpTheme.onSurfaceVariant,
              ),
            ),
            Text(
              cityName.isNotEmpty ? cityName : 'Selected Region',
              style: RfpTheme.bodyMd.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const Spacer(),
        CircleAvatar(
          radius: 16,
          backgroundColor: RfpTheme.primary,
          child: const Icon(Icons.person, color: RfpTheme.onPrimary, size: 18),
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context, RfpPatch patch) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back, color: RfpTheme.onSurface),
        ),
        const SizedBox(width: RfpTheme.spaceSm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configure ${patch.label}', style: RfpTheme.headlineMd),
            Text(
              'Customize vegetable preferences and delivery\nparameters for Patch ${patch.label}',
              style: RfpTheme.bodySm.copyWith(color: RfpTheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVegetableSection(
    BuildContext context,
    RfpPatchConfigState state,
    RfpPatch patch,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vegetable Preferences', style: RfpTheme.headlineSm),
                Text(
                  'Toggle items to include or\nexclude from this patch',
                  style: RfpTheme.bodySm.copyWith(
                    color: RfpTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            // Exclusion counter badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: RfpTheme.spaceMd,
                vertical: RfpTheme.spaceSm,
              ),
              decoration: BoxDecoration(
                color:
                    state.exclusionsUsed > 0
                        ? RfpTheme.tertiaryFixedDim.withValues(alpha: 0.3)
                        : RfpTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
              ),
              child: Text(
                '${state.exclusionsUsed} of ${state.maxExclusions}\nexclusions\nused',
                textAlign: TextAlign.center,
                style: RfpTheme.labelSm.copyWith(
                  color:
                      state.exclusionsUsed > 0
                          ? RfpTheme.tertiary
                          : RfpTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: RfpTheme.spaceMd),
        // Vegetable list
        ...patch.vegetables.map((veg) {
          final isExcluded = state.isExcluded(veg.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: RfpTheme.spaceSm),
            child: RfpVegetableTile(
              vegetable: veg,
              isExcluded: isExcluded,
              onToggle:
                  () => context
                      .read<RfpPatchConfigCubit>()
                      .toggleVegetableExclusion(veg.id),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWeightSection(
    BuildContext context,
    RfpPatchConfigState state,
    RfpPatch patch,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Packet Size', style: RfpTheme.headlineSm),
        Text(
          'Select your preferred harvest yield volume per delivery',
          style: RfpTheme.bodySm.copyWith(color: RfpTheme.onSurfaceVariant),
        ),
        const SizedBox(height: RfpTheme.spaceMd),
        Row(
          children:
              patch.availableWeights.map((w) {
                final isSelected = state.selectedWeight == w;
                final label =
                    w == 2.5
                        ? 'Small\nHousehold'
                        : w == 5.0
                        ? 'Standard\nFamily'
                        : 'Maximum\nYield';
                return Expanded(
                  child: GestureDetector(
                    onTap:
                        () =>
                            context.read<RfpPatchConfigCubit>().selectWeight(w),
                    child: Container(
                      margin: const EdgeInsets.only(right: RfpTheme.spaceSm),
                      padding: const EdgeInsets.symmetric(
                        vertical: RfpTheme.spaceMd,
                        horizontal: RfpTheme.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? RfpTheme.primaryContainer
                                : RfpTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
                        border: Border.all(
                          color:
                              isSelected
                                  ? RfpTheme.primary
                                  : RfpTheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${w == w.toInt() ? w.toInt().toString() : w.toString()} KG',
                            style: RfpTheme.headlineSm.copyWith(
                              color:
                                  isSelected
                                      ? RfpTheme.onPrimary
                                      : RfpTheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: RfpTheme.labelSm.copyWith(
                              color:
                                  isSelected
                                      ? RfpTheme.onPrimaryContainer
                                      : RfpTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildFrequencySection(
    BuildContext context,
    RfpPatchConfigState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery Frequency', style: RfpTheme.headlineSm),
        Text(
          'Choose how often your patch is harvested and dispatched',
          style: RfpTheme.bodySm.copyWith(color: RfpTheme.onSurfaceVariant),
        ),
        const SizedBox(height: RfpTheme.spaceMd),
        RfpFrequencyOption(
          title: 'Once a week',
          subtitle: 'One delivery every week on preferred day',
          isSelected: state.deliveryFrequency == 'once_a_week',
          onTap:
              () => context.read<RfpPatchConfigCubit>().selectFrequency(
                'once_a_week',
              ),
        ),
        const SizedBox(height: RfpTheme.spaceSm),
        RfpFrequencyOption(
          title: 'Twice a week',
          subtitle: 'Monday + Thursday - Recommended for peak freshness',
          isSelected: state.deliveryFrequency == 'twice_a_week',
          isRecommended: true,
          onTap:
              () => context.read<RfpPatchConfigCubit>().selectFrequency(
                'twice_a_week',
              ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context, RfpPatchConfigState state) {
    return Container(
      padding: const EdgeInsets.all(RfpTheme.gutter),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            // Save config to parent cubit
            context.read<RfpPatchConfigCubit>().markSaved();
            final config = state.toConfig();
            context.read<RfpBatchCubit>().updatePatchConfig(patchId, config);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: RfpTheme.primary,
            foregroundColor: RfpTheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
            ),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Save ${state.patch?.label ?? ''} & Continue',
                style: RfpTheme.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                  color: RfpTheme.onPrimary,
                ),
              ),
              const SizedBox(width: RfpTheme.spaceSm),
              const Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
