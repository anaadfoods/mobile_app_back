import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/animated_screen_header.dart';
import 'package:grocery_app/common_widgets/glassmorphic_icon_button.dart';
import 'package:grocery_app/models/rfp_plan_model.dart';
import 'package:grocery_app/features/rfp/presentation/screens/plan_deliveries_screen.dart';
import 'package:grocery_app/services/rfp_services.dart';

import 'package:grocery_app/service_locator.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen>
    with TickerProviderStateMixin {
  final DeliveryService _deliveryService = getIt<DeliveryService>();
  late Future<List<RfpPlan>> _plansFuture;

  late AnimationController _headerController;
  late AnimationController _contentController;

  late Animation<double> _headerSlide;
  late Animation<double> _headerFade;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _plansFuture = _deliveryService.fetchPlans();
    _initAnimations();
  }

  void _initAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerSlide = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleRefresh() {
    HapticFeedback.mediumImpact();
    setState(() {
      _plansFuture = _deliveryService.fetchPlans();
    });
  }

  void _onPlanTapped(RfpPlan plan) {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PlanDeliveriesScreen(plan: plan)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _handleRefresh(),
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Animated Header
            SliverToBoxAdapter(
              child: AnimatedScreenHeader(
                title: "Your Farm Plans",
                subtitle: "Track seasonal harvest plans and deliveries",
                icon: Icons.eco_rounded,
                animationController: _headerController,
                showBack: true,
                showLogo: true,
                actions: [
                  GlassmorphicIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: _handleRefresh,
                  ),
                ],
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _contentController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - _contentFade.value)),
                    child: Opacity(opacity: _contentFade.value, child: child),
                  );
                },
                child: FutureBuilder<List<RfpPlan>>(
                  future: _plansFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: isDark ? AppColors.darkSoftRed : AppColors.softRed,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Failed to load plans",
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${snapshot.error}",
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _handleRefresh,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Retry"),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: theme.hintColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No plans found",
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Your RFP plans will appear here",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return _buildPlansContent(theme, snapshot.data!);
                  },
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }


  Widget _buildPlansContent(ThemeData theme, List<RfpPlan> plans) {
    final activePlan = plans.firstWhere(
      (p) => p.isActive,
      orElse: () => plans.first,
    );
    final otherPlans = plans.where((p) => p.id != activePlan.id).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Active Plan',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Active plan card
          _buildActivePlanCard(theme, activePlan),

          if (otherPlans.isNotEmpty) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.harvestAmber, AppColors.rawEarth],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'All Plans',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...otherPlans.map((plan) => _buildPlanTile(theme, plan)),
          ],
        ],
      ),
    );
  }

  Widget _buildActivePlanCard(ThemeData theme, RfpPlan plan) {
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _onPlanTapped(plan),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkSurfaceElevated, AppColors.darkSurface]
                : [AppColors.deepSoilGreen, AppColors.deepSoilGreen.withValues(alpha: 0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppColors.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.charcoal.withValues(alpha: isDark ? 0.3 : 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.parchment,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: plan.isActive
                        ? AppColors.pureWhite.withValues(alpha: 0.15)
                        : AppColors.rawEarth.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppColors.radiusRound),
                    border: Border.all(
                      color: AppColors.parchment.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    plan.status.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.parchment,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            if (plan.desc.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                plan.desc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.parchment.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${plan.daysRemaining} days remaining",
                  style: const TextStyle(
                    color: AppColors.parchment70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${(plan.progress * 100).toInt()}%",
                  style: const TextStyle(
                    color: AppColors.parchment70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
              child: LinearProgressIndicator(
                value: plan.progress,
                minHeight: 8,
                backgroundColor: AppColors.parchment.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.parchment,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Date info row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.parchment.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppColors.radiusM),
                border: Border.all(
                  color: AppColors.parchment.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateInfo("START DATE", _formatDate(plan.startDate)),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.parchment.withValues(alpha: 0.15),
                  ),
                  Expanded(
                    child: _buildDateInfo("END DATE", _formatDate(plan.endDate)),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.parchment.withValues(alpha: 0.15),
                  ),
                  Expanded(
                    child: _buildDateInfo("DURATION", "${plan.duration} Days"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tap hint
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 16,
                    color: AppColors.parchment.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Tap to view delivery schedule",
                    style: TextStyle(
                      color: AppColors.parchment.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.parchment70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.parchment,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanTile(ThemeData theme, RfpPlan plan) {
    final isDark = theme.brightness == Brightness.dark;
    final badgeBg = plan.isActive
        ? (isDark ? AppColors.darkSuccessGreen.withValues(alpha: 0.15) : AppColors.successGreen.withValues(alpha: 0.1))
        : (isDark ? AppColors.rawEarth.withValues(alpha: 0.25) : AppColors.rawEarth.withValues(alpha: 0.1));
    final badgeText = plan.isActive
        ? (isDark ? AppColors.darkSuccessGreen : AppColors.successGreen)
        : (isDark ? AppColors.parchment70 : AppColors.rawEarth);

    return GestureDetector(
      onTap: () => _onPlanTapped(plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(AppColors.radiusM),
          border: Border.all(
            color: isDark
                ? AppColors.parchment.withValues(alpha: 0.08)
                : AppColors.deepSoilGreen.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.charcoal.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.parchment : AppColors.charcoal,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(AppColors.radiusRound),
                  ),
                  child: Text(
                    plan.status.toUpperCase(),
                    style: TextStyle(
                      color: badgeText,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Ref: ${plan.customerNumber}",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (plan.desc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                plan.desc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.parchment70 : AppColors.charcoal87,
                  height: 1.3,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: isDark ? AppColors.parchment54 : AppColors.rawEarth70,
                ),
                const SizedBox(width: 6),
                Text(
                  "${_formatDate(plan.startDate)} – ${_formatDate(plan.endDate)}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.parchment70 : AppColors.charcoal70,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.hintColor,
                ),
              ],
            ),
            if (plan.isActive) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppColors.radiusRound),
                child: LinearProgressIndicator(
                  value: plan.progress,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? AppColors.parchment.withValues(alpha: 0.08)
                      : AppColors.deepSoilGreen.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.darkSuccessGreen : AppColors.deepSoilGreen,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}
