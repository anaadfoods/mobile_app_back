import 'package:grocery_app/core/theme/app_colors.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/anaad_logo_mark.dart';
import 'package:grocery_app/models/rfp_plan_model.dart';
import 'package:grocery_app/screens/RFP/plan_deliveries_screen.dart';
import 'package:grocery_app/services/rfp_services.dart';
import 'package:grocery_app/styles/colors.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen>
    with TickerProviderStateMixin {
  final DeliveryService _deliveryService = DeliveryService();
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
            _buildAnimatedHeader(theme, isDark),

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
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.rawEarth,
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

  Widget _buildAnimatedHeader(ThemeData theme, bool isDark) {
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    final screenHeight = mediaQuery.size.height;
    final headerHeight = (statusBarHeight + 160).clamp(
      180.0,
      math.max(180.0, screenHeight * 0.25).toDouble(),
    );

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _headerController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _headerSlide.value),
            child: Opacity(opacity: _headerFade.value, child: child),
          );
        },
        child: Container(
          constraints: BoxConstraints(minHeight: headerHeight),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.parchment,
                theme.colorScheme.primary.withValues(alpha: 0.85),
                isDark ? AppColors.parchment : AppColors.deepSoilGreen,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.parchment.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.parchment.withValues(alpha: 0.06),
                  ),
                ),
              ),

              // Content
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (Navigator.canPop(context))
                            _buildGlassButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                            )
                          else
                            const AnaadLogoMark(),
                          _buildGlassButton(
                            icon: Icons.refresh_rounded,
                            onTap: _handleRefresh,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Row(
                        children: [
                          const Icon(
                            Icons.eco_rounded,
                            color: AppColors.parchment,
                            size: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Your Farm Plans",
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: AppColors.parchment,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Track your seasonal harvest plans and weekly deliveries",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.parchment.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.parchment.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.parchment.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: AppColors.parchment, size: 20),
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
            colors:
                isDark
                    ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                    : [AppColors.deepSoilGreen, AppColors.deepSoilGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.parchment.withValues(alpha: 0.4),
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
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        plan.isActive
                            ? AppColors.deepSoilGreen
                            : AppColors.rawEarth54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    plan.status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.parchment,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Text(
            //   plan.customerNumber,
            //   style: theme.textTheme.bodySmall?.copyWith(
            //     color: AppColors.parchment.withValues(alpha: 0.6),
            //   ),
            // ),
            if (plan.desc.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                plan.desc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.parchment.withValues(alpha: 0.85),
                ),
              ),
            ],

            const SizedBox(height: 16),

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
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: plan.progress,
                minHeight: 8,
                backgroundColor: AppColors.parchment.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.parchment,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Date info row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.parchment.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateInfo("Start", _formatDate(plan.startDate)),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: AppColors.parchment.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _buildDateInfo("End", _formatDate(plan.endDate)),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: AppColors.parchment.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _buildDateInfo("Duration", "${plan.duration} days"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Tap hint
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 16,
                    color: AppColors.parchment.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Tap to view deliveries",
                    style: TextStyle(
                      color: AppColors.parchment.withValues(alpha: 0.5),
                      fontSize: 12,
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
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.parchment.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.parchment,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanTile(ThemeData theme, RfpPlan plan) {
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _onPlanTapped(plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.charcoal.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        plan.isActive
                            ? AppColors.deepSoilGreen
                            : AppColors.rawEarth54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan.status,
                    style: const TextStyle(
                      color: AppColors.parchment,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              plan.customerNumber,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            if (plan.desc.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(plan.desc, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: theme.hintColor),
                const SizedBox(width: 4),
                Text(
                  "${_formatDate(plan.startDate)} – ${_formatDate(plan.endDate)}",
                  style: theme.textTheme.bodySmall,
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
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: plan.progress,
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.deepSoilGreen,
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
