import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/rfp_batch_cubit.dart';
import '../rfp_theme.dart';
import '../widgets/rfp_storefront_header.dart';
import '../widgets/rfp_storefront_plan_card.dart';
import '../widgets/rfp_plan_configurator_modal.dart';
import '../widgets/rfp_batch_info_section.dart';
import '../widgets/rfp_selection_summary_bar.dart';

/// Batch Builder Storefront — Screen 1 from the design mockup.
///
/// Phase 1: Displays available batches from GET /api/rfp_subscription/batches/active/
/// with batch image, name, date range, capacity/slots, and group transparency.
/// Phase 2: Once a batch is selected, shows plan cards with vegetable previews
/// and "CONFIGURE & ADD" CTAs, with selection summary bar for live pricing quote.
class RfpBatchesScreen extends StatelessWidget {
  const RfpBatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RfpBatchCubit, RfpBatchState>(
      builder: (context, state) {
        if (state.isLoading) {
          return _buildLoadingScreen();
        }
        if (state.error != null) {
          return _buildErrorScreen(context, state);
        }
        if (state.batches.isEmpty) {
          return _buildEmptyScreen(context);
        }
        return _buildStorefront(context, state);
      },
    );
  }

  // ─── Loading State ──────────────────────────────────────────────────────

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 140,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 260,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 2,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder:
                      (_, _) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Error State ────────────────────────────────────────────────────────

  Widget _buildErrorScreen(BuildContext context, RfpBatchState state) {
    return Scaffold(
      backgroundColor: RfpTheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(RfpTheme.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: RfpTheme.error),
              const SizedBox(height: 16),
              Text('Something went wrong', style: RfpTheme.headlineSm),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: RfpTheme.bodySm.copyWith(
                  color: RfpTheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<RfpBatchCubit>().loadBatchData(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RfpTheme.primary,
                  foregroundColor: RfpTheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Empty State ────────────────────────────────────────────────────────

  Widget _buildEmptyScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1F1A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.eco_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No Batches Available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'There are no active farming batches at the moment.\nCheck back soon for upcoming harvest seasons.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed:
                      () => context.read<RfpBatchCubit>().loadBatchData(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text(
                    'Refresh',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Main Storefront ───────────────────────────────────────────────────

  Widget _buildStorefront(BuildContext context, RfpBatchState state) {
    final batch = state.selectedBatch;
    if (batch == null) {
      return _buildEmptyScreen(context);
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0F1F1A),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RfpStorefrontHeader(
                          batch: batch,
                          onBackTap: () => Navigator.of(context).pop(),
                        ),
                        RfpBatchInfoSection(batch: batch, state: state),
                        if (!batch.isFull) ...[
                          const SizedBox(height: 24),
                          _buildPlanCards(context, state),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (!batch.isFull) const RfpSelectionSummaryBar(),
          ],
        ),
      ),
    );
  }

  // ─── Plan Cards ─────────────────────────────────────────────────────────

  Widget _buildPlanCards(BuildContext context, RfpBatchState state) {
    if (state.plans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            'No plans available for this batch',
            style: RfpTheme.bodyMd.copyWith(color: Colors.white70),
          ),
        ),
      );
    }
    return Column(
      children: [
        if (state.hasDiscount)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFC9EEA9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF486730), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_offer,
                    size: 18,
                    color: Color(0xFF003629),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🎉 Multi-Plan Bundle Discount: ${state.discountPercentage.toInt()}% OFF applied!',
                      style: const TextStyle(
                        color: Color(0xFF003629),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ...state.plans.map((plan) {
          final isSelected = state.isPlanSelected(plan.id);
          final config = state.planConfigurations[plan.id];
          final isConfigured = config?.isConfigured ?? false;
          final configuredVariantLabel =
              config?.selectedPricing != null
                  ? '${config!.selectedPricing!.weightKg} KG • ${config.selectedFrequency}x/wk'
                  : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: RfpStorefrontPlanCard(
              plan: plan,
              isSelected: isSelected,
              isConfigured: isConfigured,
              configuredVariantLabel: configuredVariantLabel,
              onToggleSelect: () {
                context.read<RfpBatchCubit>().togglePlanSelection(plan.id);
              },
              onConfigureTap: () {
                context.read<RfpBatchCubit>().selectPlan(plan);
                RfpPlanConfiguratorModal.show(context, plan);
              },
            ),
          );
        }),
      ],
    );
  }
}
