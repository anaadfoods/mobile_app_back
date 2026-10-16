import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/rfp_patch.dart';
import '../rfp_theme.dart';

/// Sticky bottom summary bar for RFP patch and plan selection.
class RfpSummaryBar extends StatelessWidget {
  final int selectedPatchCount;
  final List<RfpPatch> selectedPatches;
  final String? firstSelectedPatchId;
  final bool canCheckout;

  const RfpSummaryBar({
    super.key,
    required this.selectedPatchCount,
    required this.selectedPatches,
    required this.firstSelectedPatchId,
    this.canCheckout = false,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = selectedPatches.fold<double>(
      0,
      (sum, p) => sum + p.startingPrice,
    );

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          RfpTheme.gutter,
          RfpTheme.spaceMd,
          RfpTheme.gutter,
          RfpTheme.spaceMd,
        ),
        decoration: BoxDecoration(
          color: RfpTheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Summary',
                    style: RfpTheme.labelSm.copyWith(
                      color: RfpTheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '$selectedPatchCount',
                        style: RfpTheme.headlineLg.copyWith(fontSize: 28),
                      ),
                      const SizedBox(width: 4),
                      Text('Patches', style: RfpTheme.bodySm),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: RfpTheme.spaceMd),
              Text(
                '—',
                style: RfpTheme.bodyMd.copyWith(
                  color: RfpTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: RfpTheme.spaceSm),
              Text(
                '₹${totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                style: RfpTheme.headlineSm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '/mo',
                style: RfpTheme.labelSm.copyWith(
                  color: RfpTheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (canCheckout) {
                    context.push('/rfp/checkout');
                  } else {
                    final patchId =
                        firstSelectedPatchId ??
                        (selectedPatches.isNotEmpty
                            ? selectedPatches.first.id
                            : 'patch_p1');
                    context.push('/rfp/configure/$patchId');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: RfpTheme.primary,
                  foregroundColor: RfpTheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      canCheckout
                          ? 'Proceed to\nCheckout'
                          : 'Configure &\nContinue',
                      style: RfpTheme.labelMd.copyWith(
                        color: RfpTheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
