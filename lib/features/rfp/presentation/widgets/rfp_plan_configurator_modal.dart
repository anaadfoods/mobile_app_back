import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/rfp_plan.dart';
import '../../domain/entities/rfp_plan_pricing.dart';
import '../cubit/rfp_batch_cubit.dart';
import '../rfp_theme.dart';
import 'rfp_delivery_frequency_section.dart';
import 'rfp_plan_vegetable_selection.dart';

/// Modal bottom sheet allowing the user to configure one selected RFP plan.
class RfpPlanConfiguratorModal extends StatefulWidget {
  final RfpPlan plan;
  final ScrollController? scrollController;

  const RfpPlanConfiguratorModal({
    super.key,
    required this.plan,
    this.scrollController,
  });

  static void show(BuildContext context, RfpPlan plan) {
    context.read<RfpBatchCubit>().initializeVegetablesForPlan(plan);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RfpTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RfpTheme.radiusXl),
        ),
      ),
      builder:
          (ctx) => BlocProvider.value(
            value: context.read<RfpBatchCubit>(),
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return RfpPlanConfiguratorModal(
                  plan: plan,
                  scrollController: scrollController,
                );
              },
            ),
          ),
    );
  }

  @override
  State<RfpPlanConfiguratorModal> createState() =>
      _RfpPlanConfiguratorModalState();
}

class _RfpPlanConfiguratorModalState extends State<RfpPlanConfiguratorModal> {
  String? _validationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cubit = context.read<RfpBatchCubit>();
        if (cubit.state.selectedPlan?.id != widget.plan.id) {
          cubit.initializeVegetablesForPlan(widget.plan);
        }
      }
    });
  }

  void _clearValidationError() {
    if (_validationError != null) {
      setState(() => _validationError = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RfpBatchCubit, RfpBatchState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildTopBanner(context),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(RfpTheme.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RfpPlanVegetableSelection(
                      plan: widget.plan,
                      onSelectionChanged: _clearValidationError,
                    ),
                    const SizedBox(height: RfpTheme.spaceLg),
                    _buildVariantSelection(context, state),
                    const SizedBox(height: RfpTheme.spaceLg),
                    RfpDeliveryFrequencySection(plan: widget.plan),
                    const SizedBox(height: RfpTheme.spaceLg),
                    _buildConfirmButton(context, state),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBanner(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: RfpTheme.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RfpTheme.radiusXl),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: RfpTheme.spaceMd,
        vertical: RfpTheme.spaceLg,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(RfpTheme.spaceSm),
              decoration: const BoxDecoration(
                color: RfpTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, color: RfpTheme.onPrimary),
            ),
            const SizedBox(width: RfpTheme.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'CUSTOM HARVEST BOX',
                        style: RfpTheme.labelSm.copyWith(
                          color: RfpTheme.secondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              widget.plan.isFull
                                  ? Colors.red.withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.plan.isFull
                              ? 'FULL'
                              : '${widget.plan.slotsRemaining} SLOTS LEFT',
                          style: RfpTheme.labelSm.copyWith(
                            color: RfpTheme.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'CONFIGURE YOUR ${widget.plan.name.toUpperCase()}',
                    style: RfpTheme.headlineSm.copyWith(
                      color: RfpTheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: RfpTheme.onPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantSelection(BuildContext context, RfpBatchState state) {
    if (widget.plan.pricings.isEmpty) {
      return const SizedBox.shrink();
    }
    final uniqueWeights =
        widget.plan.pricings.map((p) => p.weightKg).toSet().toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CHOOSE YOUR VARIANT', style: RfpTheme.headlineSm),
        const SizedBox(height: RfpTheme.spaceXs),
        Text(
          'Select portion weight suited for your household',
          style: RfpTheme.bodySm.copyWith(color: RfpTheme.onSurfaceVariant),
        ),
        const SizedBox(height: RfpTheme.spaceMd),
        Wrap(
          spacing: RfpTheme.spaceSm,
          runSpacing: RfpTheme.spaceSm,
          children:
              uniqueWeights.map((weight) {
                final pricings = widget.plan.pricings.cast<RfpPlanPricing>();
                final pricingForWeight = pricings.firstWhere(
                  (p) =>
                      p.weightKg == weight &&
                      p.frequencyPerWeek == state.selectedFrequency,
                  orElse:
                      () => pricings.firstWhere((p) => p.weightKg == weight),
                );
                final isSelected =
                    state.selectedPricingVariant?.weightKg == weight;

                return ChoiceChip(
                  key: Key('variant_chip_${weight.toStringAsFixed(1)}'),
                  label: Text(
                    '${weight.toStringAsFixed(1)} KG • ${pricingForWeight.variantName}',
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<RfpBatchCubit>().selectPricingVariant(
                        pricingForWeight,
                      );
                      _clearValidationError();
                    }
                  },
                  selectedColor: RfpTheme.secondaryContainer,
                  backgroundColor: RfpTheme.surfaceContainerLow,
                  labelStyle: RfpTheme.labelMd.copyWith(
                    color: isSelected ? RfpTheme.primary : RfpTheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),
        if (state.selectedPricingVariant != null) ...[
          const SizedBox(height: RfpTheme.spaceMd),
          Container(
            padding: const EdgeInsets.all(RfpTheme.spaceMd),
            decoration: BoxDecoration(
              color: RfpTheme.primaryContainer,
              borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: RfpTheme.onPrimary),
                const SizedBox(width: RfpTheme.spaceSm),
                Expanded(
                  child: Text(
                    'Seasonal Thali Price ₹${state.selectedPricingVariant!.pricePerDelivery.toStringAsFixed(0)}/delivery (${state.selectedFrequency}x/week)',
                    style: RfpTheme.labelMd.copyWith(color: RfpTheme.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _onSave(BuildContext context, RfpBatchState state) {
    if (widget.plan.availableVegetables.isNotEmpty) {
      final selectedCount = state.selectedVegetableIds.length;
      final limit = widget.plan.selectionLimit;
      final maxAvailable = widget.plan.availableVegetables.length;
      final requiredCount =
          (limit > 0 && limit < maxAvailable)
              ? limit
              : (limit > 0 ? maxAvailable : 0);

      if (requiredCount > 0 && selectedCount < requiredCount) {
        final missing = requiredCount - selectedCount;
        final errorMsg =
            'Please select $missing more vegetable${missing > 1 ? "s" : ""} to complete your box ($requiredCount required).';
        setState(() => _validationError = errorMsg);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (requiredCount == 0 && selectedCount == 0) {
        const errorMsg =
            'Please select at least one vegetable for your harvest box.';
        setState(() => _validationError = errorMsg);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(errorMsg),
            backgroundColor: Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (widget.plan.pricings.isNotEmpty &&
        state.selectedPricingVariant == null) {
      const errorMsg = 'Please choose a weight/pricing variant.';
      setState(() => _validationError = errorMsg);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(errorMsg),
          backgroundColor: Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _validationError = null);
    context.read<RfpBatchCubit>().confirmPlanConfiguration();
    Navigator.pop(context);
  }

  Widget _buildConfirmButton(BuildContext context, RfpBatchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_validationError != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RfpTheme.spaceMd,
              vertical: RfpTheme.spaceSm,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFECEB),
              borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFC62828),
                  size: 18,
                ),
                const SizedBox(width: RfpTheme.spaceSm),
                Expanded(
                  child: Text(
                    _validationError!,
                    style: RfpTheme.bodySm.copyWith(
                      color: const Color(0xFFC62828),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RfpTheme.spaceMd),
        ],
        ElevatedButton(
          key: const Key('rfp_save_plan_config_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: RfpTheme.primary,
            foregroundColor: RfpTheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: RfpTheme.spaceLg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
            ),
          ),
          onPressed: () => _onSave(context, state),
          child: const Text('CONFIRM CONFIGURATION'),
        ),
      ],
    );
  }
}
