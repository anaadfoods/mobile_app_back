import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/common_widgets/modern_back_button.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/core/theme/app_text_styles.dart';
import '../cubit/rfp_batch_cubit.dart';
import '../cubit/rfp_dashboard_cubit.dart';
import '../rfp_theme.dart';
import '../widgets/rfp_hero_card.dart';
import '../widgets/rfp_benefit_card.dart';
import '../widgets/rfp_city_selection_sheet.dart';

/// RFP Landing Screen — faithful reproduction of rfp_landing/screen.png
///
/// Entry point to the RFP feature, accessed from the home screen.
/// Shows hero card, benefits grid, yield status teaser, and CTA.
class RfpLandingScreen extends StatelessWidget {
  const RfpLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RfpBatchCubit, RfpBatchState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: RfpTheme.surface,
          body: SafeArea(
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
                        _buildHeader(context, state),
                        const SizedBox(height: RfpTheme.spaceLg),
                        const RfpHeroCard(),
                        const SizedBox(height: RfpTheme.spaceLg),
                        _buildBenefitsSection(),
                        const SizedBox(height: RfpTheme.spaceLg),
                        _buildYieldTeaser(),
                        const SizedBox(height: RfpTheme.spaceLg),
                        _buildActions(context),
                        const SizedBox(height: RfpTheme.spaceXl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, RfpBatchState state) {
    return Row(
      children: [
        if (Navigator.of(context).canPop()) ...[
          ModernBackButton(onPressed: () => Navigator.of(context).pop()),
          const SizedBox(width: RfpTheme.spaceSm),
        ],
        // Logo placeholder
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
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => RfpCitySelectionSheet.show(context, state),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location',
                style: RfpTheme.labelSm.copyWith(
                  color: RfpTheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  Text(
                    state.selectedCityName,
                    style: RfpTheme.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.expand_more,
                    size: 16,
                    color: RfpTheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        BlocBuilder<RfpDashboardCubit, RfpDashboardState>(
          builder: (context, dashboardState) {
            final hasBooking = dashboardState.hasBooking;
            return InkWell(
              onTap: () => context.push('/rfp/dashboard'),
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      hasBooking
                          ? AppColors.deepSoilGreen.withValues(alpha: 0.1)
                          : AppColors.charcoal.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppColors.radiusRound),
                  border: Border.all(
                    color:
                        hasBooking
                            ? AppColors.deepSoilGreen.withValues(alpha: 0.3)
                            : AppColors.charcoal.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasBooking ? Icons.eco_rounded : Icons.dashboard_outlined,
                      size: 14,
                      color:
                          hasBooking
                              ? AppColors.deepSoilGreen
                              : AppColors.charcoal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasBooking ? 'My Active Plan' : 'Dashboard',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            hasBooking
                                ? AppColors.deepSoilGreen
                                : AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Why Choose RFP', style: RfpTheme.headlineSm),
            Text(
              'Sustainable & Direct',
              style: RfpTheme.labelSm.copyWith(color: RfpTheme.secondary),
            ),
          ],
        ),
        const SizedBox(height: RfpTheme.spaceMd),
        const RfpBenefitCard(
          icon: Icons.eco,
          iconBg: RfpTheme.secondaryContainer,
          iconColor: RfpTheme.onSecondaryContainer,
          title: 'Fresh Farm Vegetables',
          subtitle:
              'Direct from verified organic farms straight to your doorstep.',
        ),
        const SizedBox(height: RfpTheme.spaceMd),
        const RfpBenefitCard(
          icon: Icons.calendar_month,
          iconBg: RfpTheme.primaryFixed,
          iconColor: RfpTheme.onPrimaryFixed,
          title: '12-Week Farming Cycle',
          subtitle:
              'Structured seasonal planning aligned with nature\'s rhythm.',
        ),
        const SizedBox(height: RfpTheme.spaceMd),
        const RfpBenefitCard(
          icon: Icons.local_shipping,
          iconBg: RfpTheme.tertiaryFixedDim,
          iconColor: RfpTheme.onTertiary,
          title: 'Scheduled Bi-weekly Drops',
          subtitle: 'Reliable Monday & Thursday deliveries for peak freshness.',
        ),
        const SizedBox(height: RfpTheme.spaceMd),
        Row(
          children: [
            Expanded(
              child: RfpSmallBenefitCard(
                icon: Icons.grid_view,
                iconBg: RfpTheme.secondaryContainer.withValues(alpha: 0.60),
                title: 'Preferred Patches',
                subtitle: 'Select from P1 to P4 specialized plots.',
              ),
            ),
            const SizedBox(width: RfpTheme.spaceMd),
            Expanded(
              child: RfpSmallBenefitCard(
                icon: Icons.tune,
                iconBg: RfpTheme.primaryFixedDim.withValues(alpha: 0.60),
                title: 'Custom Harvest',
                subtitle: 'Exclude up to your preferred limit.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYieldTeaser() {
    return Container(
      padding: const EdgeInsets.all(RfpTheme.spaceMd),
      decoration: BoxDecoration(
        color: RfpTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(RfpTheme.radiusXl),
      ),
      child: Row(
        children: [
          // Farm image placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: RfpTheme.surfaceContainerLowest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(Icons.grass, color: RfpTheme.primary, size: 24),
          ),
          const SizedBox(width: RfpTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Yield Status',
                  style: RfpTheme.headlineSm.copyWith(fontSize: 14),
                ),
                Text(
                  'Patch 02 is 85% flourishing',
                  style: RfpTheme.bodySm.copyWith(
                    color: RfpTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: RfpTheme.secondary),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Primary CTA
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              context.push('/rfp/batches');
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
                  'Explore RFP Plans',
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
        const SizedBox(height: RfpTheme.spaceSm),
        // Secondary link
        TextButton(
          onPressed: () {
            context.push('/rfp/batches');
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on,
                size: 18,
                color: RfpTheme.secondary,
              ),
              const SizedBox(width: RfpTheme.spaceXs),
              Text(
                'Check availability in your location',
                style: RfpTheme.bodySm.copyWith(color: RfpTheme.secondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
