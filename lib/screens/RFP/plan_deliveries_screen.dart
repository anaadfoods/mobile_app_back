import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/common_widgets/anaad_logo_mark.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/models/rfp_delivery_model.dart';
import 'package:grocery_app/services/rfp_services.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/models/rfp_plan_model.dart';

class PlanDeliveriesScreen extends StatefulWidget {
  final RfpPlan plan;

  const PlanDeliveriesScreen({super.key, required this.plan});

  @override
  State<PlanDeliveriesScreen> createState() => _PlanDeliveriesScreenState();
}

class _PlanDeliveriesScreenState extends State<PlanDeliveriesScreen> {
  final DeliveryService _service = DeliveryService();
  late Future<List<Delivery>> _deliveriesFuture;

  @override
  void initState() {
    super.initState();
    _deliveriesFuture = _service.fetchPlanDeliveries(widget.plan.id);
  }

  /// Group deliveries by iso_week
  Map<int, List<Delivery>> _groupByWeek(List<Delivery> deliveries) {
    final Map<int, List<Delivery>> grouped = {};
    for (final d in deliveries) {
      grouped.putIfAbsent(d.isoWeek, () => []).add(d);
    }
    // Sort each week's deliveries by delivery_seq_in_week
    for (final key in grouped.keys) {
      grouped[key]!.sort(
        (a, b) => a.deliverySeqInWeek.compareTo(b.deliverySeqInWeek),
      );
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = widget.plan;

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Stylish Header
          _buildHeader(theme, plan),

          // Deliveries Content
          SliverToBoxAdapter(
            child: FutureBuilder<List<Delivery>>(
              future: _deliveriesFuture,
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
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.rawEarth,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Failed to load deliveries",
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${snapshot.error}",
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed:
                                () => setState(
                                  () =>
                                      _deliveriesFuture = _service
                                          .fetchPlanDeliveries(plan.id),
                                ),
                            icon: const Icon(Icons.refresh, size: 18),
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
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: theme.hintColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No deliveries yet",
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Deliveries will appear here once scheduled",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final grouped = _groupByWeek(snapshot.data!);
                return _buildWeeklyDeliveries(theme, grouped);
              },
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, RfpPlan plan) {
    final isDark = theme.brightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: Container(
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
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Row(
                  children: [
                    const AnaadLogoMark(),
                    const Spacer(),
                    _buildGlassButton(
                      icon: Icons.refresh_rounded,
                      onTap:
                          () => setState(
                            () =>
                                _deliveriesFuture = _service
                                    .fetchPlanDeliveries(plan.id),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Plan name + status
                Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_rounded,
                      color: AppColors.parchment,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        plan.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
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
                const SizedBox(height: 6),
                // Text(
                //   plan.customerNumber,
                //   style: theme.textTheme.bodySmall?.copyWith(
                //     color: AppColors.parchment.withValues(alpha: 0.7),
                //   ),
                // ),
                const SizedBox(height: 16),

                // Progress
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
                      "${(plan.progress * 100).toInt()}% complete",
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
                    minHeight: 6,
                    backgroundColor: AppColors.parchment.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.parchment,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Stats chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatChip(
                        Icons.calendar_today_rounded,
                        "${plan.daysRemaining}/${plan.duration}",
                        "Days",
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        Icons.date_range_rounded,
                        _formatDate(plan.startDate),
                        "Start",
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        Icons.event_rounded,
                        _formatDate(plan.endDate),
                        "End",
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.parchment.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.parchment, size: 14),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: const TextStyle(
              color: AppColors.parchment,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyDeliveries(
    ThemeData theme,
    Map<int, List<Delivery>> grouped,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                'Delivery Schedule',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...grouped.entries.map(
            (entry) => _buildWeekSection(theme, entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSection(
    ThemeData theme,
    int weekNumber,
    List<Delivery> deliveries,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Week header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.1),
                theme.colorScheme.primary.withValues(
                  alpha: isDark ? 0.15 : 0.03,
                ),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'W$weekNumber',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Week $weekNumber',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${deliveries.length} ${deliveries.length == 1 ? 'delivery' : 'deliveries'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Delivery cards for this week
        ...deliveries.map((d) => _buildDeliveryCard(theme, d)),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDeliveryCard(ThemeData theme, Delivery delivery) {
    final statusColor = _getStatusColor(delivery.status);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Delivery sequence badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'D${delivery.deliverySeqInWeek}',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery ${delivery.deliverySeqInWeek}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: theme.hintColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(delivery.deliveryDate),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status + items count
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            delivery.status,
                            style: const TextStyle(
                              color: AppColors.parchment,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${delivery.itemsCount} items',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return AppColors.deepSoilGreen;
      case 'PENDING':
        return AppColors.harvestAmber;
      case 'IN_TRANSIT':
        return AppColors.deepSoilGreen;
      case 'CANCELLED':
        return AppColors.rawEarth;
      default:
        return AppColors.rawEarth54;
    }
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
