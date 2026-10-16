import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/rfp_plan.dart';

/// Storefront Plan Card with tick/checkbox selection for multi-plan bundling.
class RfpStorefrontPlanCard extends StatelessWidget {
  final RfpPlan plan;
  final bool isSelected;
  final bool isConfigured;
  final VoidCallback onToggleSelect;
  final VoidCallback onConfigureTap;
  final String? configuredVariantLabel;

  const RfpStorefrontPlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.isConfigured,
    required this.onToggleSelect,
    required this.onConfigureTap,
    this.configuredVariantLabel,
  });

  String _getBadgeText() {
    if (plan.isFull) {
      return 'PLAN FULL';
    }
    if (plan.badge != null && plan.badge!.isNotEmpty) {
      return plan.badge!.toUpperCase();
    }
    if (plan.tier.isNotEmpty) {
      return plan.tier.toUpperCase();
    }
    return plan.code?.toUpperCase() ?? 'PREMIUM';
  }

  double? _getLowestPrice() {
    if (plan.pricings.isEmpty) return null;
    double? lowest;
    for (final pricing in plan.pricings) {
      final price = pricing.pricePerDelivery;
      if (lowest == null || price < lowest) {
        lowest = price;
      }
    }
    return lowest;
  }

  List<String> _getPreviewVeggies() {
    final veggies = plan.availableVegetables;
    final count = veggies.length > 4 ? 4 : veggies.length;
    return veggies.take(count).map((v) => v.name).toList();
  }

  @override
  Widget build(BuildContext context) {
    final badgeText = _getBadgeText();
    final lowestPrice = _getLowestPrice();
    final priceString =
        lowestPrice != null
            ? NumberFormat.currency(
              symbol: '₹',
              decimalDigits: 0,
              locale: 'en_IN',
            ).format(lowestPrice)
            : '';

    final previewVeggies = _getPreviewVeggies();
    final description = plan.description;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF003629) : Colors.transparent,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isSelected
                    ? const Color(0xFF003629).withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.04),
            blurRadius: isSelected ? 10 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Badge, Slots badge, and Tick Checkbox
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFFC9EEA9)
                              : const Color(0xFFE8ECE9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color:
                            isSelected
                                ? const Color(0xFF003629)
                                : const Color(0xFF425049),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          plan.isFull
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            plan.isFull
                                ? const Color(0xFFFFCDD2)
                                : const Color(0xFFA7F3D0),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                plan.isFull
                                    ? Colors.red
                                    : const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          plan.isFull
                              ? '0 SLOTS LEFT'
                              : '${plan.slotsRemaining} SLOTS LEFT',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color:
                                plan.isFull
                                    ? const Color(0xFFC62828)
                                    : const Color(0xFF065F46),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Tick / Checkbox toggle button
              GestureDetector(
                onTap: plan.isFull ? null : onToggleSelect,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        plan.isFull
                            ? const Color(0xFFE0E0E0)
                            : (isSelected
                                ? const Color(0xFF003629)
                                : const Color(0xFFF1F3F2)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          plan.isFull
                              ? const Color(0xFFBDBDBD)
                              : (isSelected
                                  ? const Color(0xFF003629)
                                  : const Color(0xFFB0BDB6)),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        plan.isFull
                            ? Icons.block_rounded
                            : (isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded),
                        size: 15,
                        color:
                            plan.isFull
                                ? Colors.grey
                                : (isSelected
                                    ? const Color(0xFFC9EEA9)
                                    : Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        plan.isFull
                            ? 'FULL'
                            : (isSelected ? 'SELECTED' : 'SELECT'),
                        style: TextStyle(
                          color:
                              plan.isFull
                                  ? Colors.grey[700]
                                  : (isSelected
                                      ? Colors.white
                                      : Colors.black87),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Plan Title & Price in a clean compact row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B2A24),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (lowestPrice != null &&
                  lowestPrice > 0 &&
                  priceString.isNotEmpty)
                Text(
                  'Starts at $priceString/deliv',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF003629),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Compact Description
          if (description.isNotEmpty) ...[
            Text(
              description,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.black.withValues(alpha: 0.65),
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],

          // Vegetables Preview Chips
          if (previewVeggies.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children:
                  previewVeggies.map((vegName) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF6EE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        vegName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Footer action row
          Row(
            children: [
              if (configuredVariantLabel != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    configuredVariantLabel!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2A4D3E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: plan.isFull ? null : onConfigureTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF003629),
                      side: BorderSide(
                        color:
                            plan.isFull ? Colors.grey : const Color(0xFF003629),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(
                      plan.isFull
                          ? Icons.block_rounded
                          : (isConfigured
                              ? Icons.tune_rounded
                              : Icons.auto_awesome_rounded),
                      size: 14,
                    ),
                    label: Text(
                      plan.isFull
                          ? 'Plan Full'
                          : (isConfigured
                              ? 'Customise Veggies'
                              : 'Configure & Add'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
