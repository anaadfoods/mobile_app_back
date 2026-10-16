import 'package:flutter/material.dart';
import '../../domain/entities/rfp_plan.dart';
import '../../domain/entities/rfp_batch.dart';
import '../../domain/entities/rfp_plan_pricing.dart';
import '../../domain/entities/rfp_pricing.dart';
import '../cubit/rfp_batch_state.dart';
import '../rfp_theme.dart';

/// Fresh Harvest Ledger card shown in the RFP Checkout screen.
///
/// Displays selected plans and configurations, selected delivery days,
/// and exact pricing returned by POST /api/rfp_subscription/subscriptions/calculate/.
class RfpFreshHarvestLedger extends StatelessWidget {
  final List<RfpPlan> plans;
  final Map<String, RfpPlanConfig> planConfigurations;
  final RfpBatch? batch;
  final RfpPricing? pricing;

  // Single-plan parameters for backwards-compatibility
  final RfpPlan? plan;
  final RfpPlanPricing? variant;
  final int frequency;
  final Set<int> deliveryDays;

  const RfpFreshHarvestLedger({
    super.key,
    this.plans = const [],
    this.planConfigurations = const {},
    required this.batch,
    this.pricing,
    this.plan,
    this.variant,
    this.frequency = 1,
    this.deliveryDays = const {},
  });

  String _fmt(num n) => n.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  static String _formatDeliveryDays(Set<int> days) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = days.toList()..sort();
    return sorted.map((d) => names[d % 7]).join(' & ');
  }

  @override
  Widget build(BuildContext context) {
    final activePlans =
        plans.isNotEmpty ? plans : (plan != null ? [plan!] : <RfpPlan>[]);

    return Container(
      padding: const EdgeInsets.all(RfpTheme.spaceLg),
      decoration: BoxDecoration(
        color: RfpTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
        boxShadow: RfpTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _badge(
                'Fresh Harvest Ledger',
                RfpTheme.secondaryContainer,
                RfpTheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              if (activePlans.length > 1)
                _badge(
                  '${activePlans.length} Thalis Configured',
                  const Color(0xFFDCFCE7),
                  const Color(0xFF15803D),
                )
              else if (batch != null)
                _badge(
                  '${batch!.totalWeeks} Weeks Batch',
                  RfpTheme.surfaceContainerHigh,
                  RfpTheme.onSurface,
                ),
            ],
          ),
          const SizedBox(height: RfpTheme.spaceMd),

          if (activePlans.isNotEmpty) ...[
            for (var i = 0; i < activePlans.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _buildPlanTile(activePlans[i], i + 1, activePlans.length),
            ],
          ],

          const Divider(color: RfpTheme.outlineVariant, height: 24),

          if (pricing != null) ...[
            _priceRow(
              'Base Farm Share (${pricing!.deliveriesCount} Deliveries)',
              '₹${_fmt(pricing!.basePrice)}',
            ),
            if (pricing!.discountPercentage > 0 || pricing!.discountAmount > 0)
              _priceRow(
                '${pricing!.discountPercentage.toStringAsFixed(pricing!.discountPercentage.truncateToDouble() == pricing!.discountPercentage ? 0 : 1)}% Multi-Plan Discount',
                '-₹${_fmt(pricing!.discountAmount)}',
                isDiscount: true,
              ),
            const Divider(color: RfpTheme.outlineVariant, height: 16),
            _priceRow(
              'Season Total',
              '₹${_fmt(pricing!.finalPrice)}',
              isBold: true,
            ),
            const SizedBox(height: 4),
            _priceRow(
              'Due Today (Booking Deposit)',
              '₹${_fmt(pricing!.bookingAmount)}',
            ),
            _priceRow(
              'Due Later (${pricing!.remainingDeliveries} Deliveries)',
              '₹${_fmt(pricing!.remainingAmount)}',
            ),
          ] else if (plan != null) ...[
            _priceRow(
              'Base Farm Share (${batch?.totalWeeks ?? 12} Wks)',
              '₹${_fmt(plan!.totalPrice + plan!.discountAmount)}',
            ),
            if (plan!.hasDiscount)
              _priceRow(
                '${plan!.discountPercent?.toStringAsFixed(0) ?? '8'}% Multi-Plan Harvest Voucher',
                '-₹${_fmt(plan!.discountAmount)}',
                isDiscount: true,
              ),
            const Divider(color: RfpTheme.outlineVariant, height: 24),
            _priceRow(
              'Season Subtotal',
              '₹${_fmt(plan!.totalPrice)}',
              isBold: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanTile(RfpPlan p, int index, int total) {
    final cfg = planConfigurations[p.id];
    final activeVariant =
        cfg?.selectedPricing ??
        variant ??
        (p.pricings.isNotEmpty ? p.pricings.first : null);
    final freq = cfg?.selectedFrequency ?? frequency;
    final days =
        (cfg != null && cfg.selectedDeliveryDays.isNotEmpty)
            ? cfg.selectedDeliveryDays
            : deliveryDays;
    final vegCount =
        cfg?.selectedVegetableIds.isNotEmpty == true
            ? cfg!.selectedVegetableIds.length
            : (p.selectionLimit > 0
                ? p.selectionLimit
                : p.availableVegetables.length);

    final titlePrefix = total > 1 ? 'Thali $index: ' : '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: RfpTheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.spa,
              color: RfpTheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: RfpTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$titlePrefix${p.name}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (p.tier.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.tier.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                if (activeVariant != null)
                  Text(
                    '${activeVariant.weightKg.toStringAsFixed(activeVariant.weightKg.truncateToDouble() == activeVariant.weightKg ? 0 : 1)} KG / box',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF003629),
                    ),
                  ),
                if (days.isNotEmpty)
                  Text(
                    '$freq Deliver${freq > 1 ? 'ies' : 'y'} each week • ${_formatDeliveryDays(days)}',
                    style: RfpTheme.bodySm.copyWith(
                      color: RfpTheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  '$vegCount Curated Vegetables Selected',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF15803D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_resolveVegNames(p, cfg).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children:
                        _resolveVegNames(p, cfg).map((vegName) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: RfpTheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              vegName,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: RfpTheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
                if (activeVariant != null && batch != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '₹${_fmt(activeVariant.pricePerDelivery)} / delivery × ${batch!.totalWeeks * freq} deliveries',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _resolveVegNames(RfpPlan p, RfpPlanConfig? cfg) {
    final names = <String>[];
    if (cfg?.selectedVegetableIds != null &&
        cfg!.selectedVegetableIds.isNotEmpty) {
      for (final v in p.availableVegetables) {
        if (cfg.selectedVegetableIds.contains(v.id)) {
          names.add(v.name);
        }
      }
    } else {
      final defaults =
          p.availableVegetables.where((v) => v.isDefaultSelected).toList();
      if (defaults.isNotEmpty) {
        names.addAll(defaults.map((v) => v.name));
      } else {
        final limit =
            p.selectionLimit > 0
                ? p.selectionLimit
                : p.availableVegetables.length;
        names.addAll(p.availableVegetables.take(limit).map((v) => v.name));
      }
    }
    return names;
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(RfpTheme.radiusFull),
      ),
      child: Text(text, style: RfpTheme.labelSm.copyWith(color: fg)),
    );
  }

  Widget _priceRow(
    String label,
    String value, {
    bool isBold = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style:
                  isBold
                      ? RfpTheme.bodyMd.copyWith(fontWeight: FontWeight.w600)
                      : RfpTheme.bodyMd,
            ),
          ),
          Text(
            value,
            style: (isBold
                    ? RfpTheme.bodyMd.copyWith(fontWeight: FontWeight.w600)
                    : RfpTheme.bodyMd)
                .copyWith(color: isDiscount ? RfpTheme.secondary : null),
          ),
        ],
      ),
    );
  }
}
