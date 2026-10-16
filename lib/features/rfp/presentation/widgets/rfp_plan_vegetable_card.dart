import 'package:flutter/material.dart';
import '../../domain/entities/rfp_vegetable.dart';

/// Clean and customer-attracting vegetable item card for RFP plan configurator.
class RfpPlanVegetableCard extends StatelessWidget {
  final RfpVegetable vegetable;
  final bool isSelected;
  final bool canDeselect;
  final bool isDefault;
  final bool isAtLimit;
  final VoidCallback onTap;

  const RfpPlanVegetableCard({
    super.key,
    required this.vegetable,
    required this.isSelected,
    required this.canDeselect,
    required this.isDefault,
    required this.isAtLimit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = isAtLimit && !isSelected;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF2FBF4) : Colors.white,
          border: Border.all(
            color:
                isSelected ? const Color(0xFF003629) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
                      ? const Color(0xFF003629).withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Opacity(
          opacity: isDisabled ? 0.45 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: photo + action badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        (vegetable.imageUrl != null &&
                                vegetable.imageUrl!.isNotEmpty)
                            ? Image.network(
                              vegetable.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, _, _) => const Icon(
                                    Icons.eco_rounded,
                                    color: Color(0xFF2E7D32),
                                    size: 24,
                                  ),
                            )
                            : const Icon(
                              Icons.eco_rounded,
                              color: Color(0xFF2E7D32),
                              size: 24,
                            ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? (canDeselect
                                  ? const Color(0xFF003629)
                                  : const Color(0xFF94A3B8))
                              : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSelected
                          ? (canDeselect
                              ? Icons.check_rounded
                              : Icons.lock_rounded)
                          : Icons.add_rounded,
                      color:
                          isSelected ? Colors.white : const Color(0xFF64748B),
                      size: 16,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Tags Row
              if (isDefault ||
                  (vegetable.season.isNotEmpty &&
                      vegetable.season != 'All-season')) ...[
                Wrap(
                  spacing: 4,
                  children: [
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    if (vegetable.season.isNotEmpty &&
                        vegetable.season != 'All-season')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          vegetable.season.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Text(
                vegetable.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (vegetable.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  vegetable.description,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
