import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/rfp_plan.dart';
import '../cubit/rfp_batch_cubit.dart';
import '../rfp_theme.dart';
import 'rfp_frequency_option.dart';

/// Delivery frequency selection section (1 Day / Week vs 2 Days / Week).
class RfpDeliveryFrequencySection extends StatelessWidget {
  final RfpPlan plan;

  const RfpDeliveryFrequencySection({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RfpBatchCubit, RfpBatchState>(
      buildWhen:
          (prev, curr) =>
              prev.selectedFrequency != curr.selectedFrequency ||
              prev.selectedPricingVariant != curr.selectedPricingVariant,
      builder: (context, state) {
        final currentFreq = state.selectedFrequency;
        final cubit = context.read<RfpBatchCubit>();
        final currentWeight = state.selectedPricingVariant?.weightKg;

        final supportedFrequencies =
            plan.pricings.map((p) => p.frequencyPerWeek).toSet().toList()
              ..sort();
        final frequencies =
            supportedFrequencies.isNotEmpty ? supportedFrequencies : [1];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DELIVERY FREQUENCY', style: RfpTheme.headlineSm),
            const SizedBox(height: RfpTheme.spaceXs),
            Text(
              'Choose how often your fresh harvest is dispatched',
              style: RfpTheme.bodySm.copyWith(color: RfpTheme.onSurfaceVariant),
            ),
            const SizedBox(height: RfpTheme.spaceMd),
            ...frequencies.map((freq) {
              final matchingPricings = plan.pricings.where(
                (p) =>
                    p.frequencyPerWeek == freq &&
                    (currentWeight == null || p.weightKg == currentWeight),
              );
              final price =
                  matchingPricings.isNotEmpty
                      ? matchingPricings.first.pricePerDelivery
                      : (plan.pricings
                              .where((p) => p.frequencyPerWeek == freq)
                              .isNotEmpty
                          ? plan.pricings
                              .firstWhere((p) => p.frequencyPerWeek == freq)
                              .pricePerDelivery
                          : null);

              final title = freq == 1 ? '1 Day / Week' : '$freq Days / Week';
              final subtitle =
                  freq == 1
                      ? 'One harvest delivery every week'
                      : (freq == 2
                          ? 'Two harvest deliveries every week'
                          : '$freq harvest deliveries every week');
              final isRecommended =
                  freq == 2 ||
                  (frequencies.length > 1 && freq == frequencies.last);

              return Padding(
                padding: const EdgeInsets.only(bottom: RfpTheme.spaceSm),
                child: RfpFrequencyOption(
                  title: title,
                  subtitle: subtitle,
                  isSelected: currentFreq == freq,
                  isRecommended: isRecommended,
                  trailing:
                      price != null
                          ? Text(
                            '₹${price.toStringAsFixed(0)}/del',
                            style: RfpTheme.labelMd.copyWith(
                              color:
                                  currentFreq == freq
                                      ? RfpTheme.primary
                                      : RfpTheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                  onTap: () => cubit.setDeliveryFrequency(freq),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
