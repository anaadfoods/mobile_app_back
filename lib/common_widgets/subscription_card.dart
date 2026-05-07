import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/cubits/subscription/subscription_state.dart';
import 'package:grocery_app/common_widgets/pause_date_picker_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/routes/app_routes.dart';

class SubscriptionCarousel extends StatefulWidget {
  const SubscriptionCarousel({super.key});

  @override
  State<SubscriptionCarousel> createState() => _SubscriptionCarouselState();
}

class _SubscriptionCarouselState extends State<SubscriptionCarousel>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<SubscriptionCubit>().fetchUserSubscriptions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final responsive = ResponsiveHelper(
      context,
      BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
        maxHeight: MediaQuery.of(context).size.height,
      ),
    );

    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      listener: (context, state) {
        if (state is SubscriptionActionSuccess) {
          SnackBarHelper.showSuccess(context, state.message);
          context.read<SubscriptionCubit>().fetchUserSubscriptions();
        } else if (state is SubscriptionError) {
          SnackBarHelper.showError(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is SubscriptionInitial || state is SubscriptionLoading) {
          return _buildSkeletonLoader(responsive);
        }

        if (state is SubscriptionSuccess) {
          final subscriptions = state.userSubscriptions;
          if (subscriptions.isEmpty) {
            return const SizedBox.shrink();
          }
          return _buildCarouselContent(subscriptions, responsive);
        }

        if (state is SubscriptionError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(responsive.screenPadding),
              child: Text("Couldn't load subscriptions.\n${state.message}"),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCarouselContent(
    List<Subscription> subscriptions,
    ResponsiveHelper responsive,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: responsive.S,
            horizontal: responsive.screenPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Active Subscription", style: theme.textTheme.displaySmall),
              GestureDetector(
                onTap: () {
                  context.pushNamed(AppRoute.subscriptionList.name);
                },
                child: Text(
                  "See all Plans",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.S),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: responsive.screenPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                subscriptions.map((subscription) {
                  return Container(
                    width:
                        MediaQuery.of(context).size.width -
                        (responsive.screenPadding * 2),
                    padding: const EdgeInsets.only(right: 12),
                    child: SubscriptionCard(
                      subscription: subscription,
                      responsive: responsive,
                      onTogglePause:
                          () => _showToggleConfirmation(subscription),
                      onRepayment: () {
                        final handler = SubscriptionHandler(context);
                        handler.processUPIRepayment(subscription.id);
                      },
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoader(ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.screenPadding),
          child: ShimmerLoading(
            isLoading: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 150, height: 24, color: AppColors.parchment),
                Container(width: 80, height: 24, color: AppColors.parchment),
              ],
            ),
          ),
        ),
        SizedBox(height: responsive.S),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.screenPadding),
          child: SubscriptionCardSkeleton(responsive: responsive),
        ),
      ],
    );
  }

  void _showToggleConfirmation(Subscription subscription) {
    final isCurrentlyPaused = subscription.status == 'PAUSED';
    final maxPausesLeft = subscription.remainingPauseTimes;
    DateTime? selectedStartDate;
    DateTime? selectedEndDate;

    if (isCurrentlyPaused) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.transparent,
        builder:
            (context) => ResumeSubscriptionSheet(
              onConfirm: () {
                context.read<SubscriptionCubit>().togglePauseSubscription(
                  subscription.id,
                  null,
                  null,
                );
              },
            ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder:
          (context) => PauseDatePickerSheet(
            maxPausesLeft: subscription.remainingPauseTimes,
            onConfirm: (start, end) {
              context.read<SubscriptionCubit>().togglePauseSubscription(
                subscription.id,
                start,
                end,
              );
            },
          ),
    );
  }
}

class SubscriptionCard extends StatefulWidget {
  final Subscription subscription;
  final VoidCallback onTogglePause;
  final VoidCallback onRepayment;
  final ResponsiveHelper responsive;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.onTogglePause,
    required this.onRepayment,
    required this.responsive,
  });

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  bool _isPressed = false;

  void _navigateToDetails(BuildContext context, Subscription subscription) {
    context.pushNamed(
      AppRoute.subscriptionDetails.name,
      pathParameters: {'id': subscription.id.toString()},
      extra: subscription,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subscription = widget.subscription;
    final item = subscription.items.first;
    final bool isPaused = subscription.status == 'PAUSED';
    final deliveriesLeft =
        subscription.totalDeliveries - subscription.completedDeliveries;
    final progress =
        subscription.totalDeliveries > 0
            ? (subscription.completedDeliveries / subscription.totalDeliveries)
                .clamp(0.0, 1.0)
            : 0.0;
    final double discountPercent =
        item.price > 0
            ? ((item.price - item.discountedPrice) / item.price) * 100
            : 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => _navigateToDetails(context, subscription),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          margin: EdgeInsets.symmetric(
            vertical: widget.responsive.S,
            horizontal: widget.responsive.screenPadding / 2,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isDark
                      ? [AppColors.darkSurfaceElevated, AppColors.darkSurfaceElevated]
                      : [AppColors.parchment, AppColors.parchment],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  isDark
                      ? AppColors.parchment.withValues(alpha: 0.1)
                      : AppColors.deepSoilGreen.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepSoilGreen.withValues(
                  alpha: isDark ? 0.15 : 0.08,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: AppColors.charcoal.withValues(
                  alpha: isDark ? 0.3 : 0.04,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background decoration
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.deepSoilGreen.withValues(alpha: 0.15),
                          AppColors.deepSoilGreen.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.deepSoilGreen.withValues(alpha: 0.1),
                          AppColors.deepSoilGreen.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.all(
                    widget.responsive.value(mobile: 16, tablet: 20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    isPaused
                                        ? [
                                          AppColors.harvestAmber,
                                          AppColors.harvestAmber.withValues(
                                            alpha: 0.8,
                                          ),
                                        ]
                                        : [
                                          AppColors.deepSoilGreen,
                                          AppColors.deepSoilGreen,
                                        ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: (isPaused
                                          ? AppColors.harvestAmber
                                          : AppColors.deepSoilGreen)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPaused
                                      ? Icons.pause_circle_rounded
                                      : Icons.autorenew_rounded,
                                  color: AppColors.parchment,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isPaused ? 'Paused' : subscription.planName,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.parchment,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Delivery Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? AppColors.darkCanvas
                                      : AppColors.deepSoilGreen.withValues(
                                        alpha: 0.08,
                                      ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.deepSoilGreen.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_shipping_rounded,
                                  color: AppColors.deepSoilGreen,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDate(subscription.nextDeliveryDate),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.deepSoilGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: widget.responsive.M),
                      // Product Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Product Image with modern styling
                          Container(
                            width: widget.responsive.value(
                              mobile: 85,
                              tablet: 100,
                            ),
                            height: widget.responsive.value(
                              mobile: 85,
                              tablet: 100,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.charcoal.withValues(
                                    alpha: isDark ? 0.4 : 0.12,
                                  ),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: item.imageUrl ?? '',
                                    height: double.infinity,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) => Container(
                                          color:
                                              isDark
                                                  ? AppColors.darkCanvas
                                                  : AppColors.parchment,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.deepSoilGreen
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ),
                                    errorWidget:
                                        (context, url, error) => Container(
                                          color:
                                              isDark
                                                  ? AppColors.darkCanvas
                                                  : AppColors.parchment,
                                          child: Icon(
                                            Icons.image_rounded,
                                            color: theme.hintColor,
                                            size: 32,
                                          ),
                                        ),
                                  ),
                                  // Discount Badge
                                  if (discountPercent > 0)
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.deepSoilGreen,
                                              AppColors.deepSoilGreen
                                                  .withValues(alpha: 0.85),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${discountPercent.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            color: AppColors.parchment,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: widget.responsive.M),
                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.quantity} units • ${subscription.planName}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text(
                                      '₹${item.discountedPrice.toStringAsFixed(0)}',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.deepSoilGreen,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹${item.price.toStringAsFixed(0)}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: theme.hintColor,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: widget.responsive.M),
                      // Progress Section
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? AppColors.darkCanvas
                                  : AppColors.deepSoilGreen.withValues(
                                    alpha: 0.04,
                                  ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.deepSoilGreen.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Circular Progress
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 4,
                                    backgroundColor:
                                        isDark
                                            ? AppColors.darkSurfaceElevated
                                            : AppColors.parchment,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.deepSoilGreen,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$deliveriesLeft deliveries remaining',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${subscription.completedDeliveries}/${subscription.totalDeliveries} completed • ${subscription.remainingPauseTimes} pauses left',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: widget.responsive.M),
                      // Action Buttons
                      Row(
                        children: [
                          // Pause/Resume Button
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      isPaused
                                          ? AppColors.deepSoilGreen
                                          : AppColors.harvestAmber,
                                  width: 1.5,
                                ),
                              ),
                              child: Material(
                                color: AppColors.transparent,
                                child: InkWell(
                                  onTap: widget.onTogglePause,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isPaused
                                                ? Icons.play_circle_rounded
                                                : Icons.pause_circle_rounded,
                                            color:
                                                isPaused
                                                    ? AppColors.deepSoilGreen
                                                    : AppColors.harvestAmber,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isPaused ? 'Resume' : 'Pause',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  color:
                                                      isPaused
                                                          ? AppColors
                                                              .deepSoilGreen
                                                          : AppColors
                                                              .harvestAmber,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Repayment Button
                          if ((subscription
                                          .installmentInfo
                                          ?.installmentPaymentStatus ??
                                      '')
                                  .toUpperCase() ==
                              'PENDING') ...[
                            const SizedBox(width: 12),
                            SubscriptionRepaymentButton(
                              subscription: subscription,
                              isExpanded: true,
                            ),
                          ],
                          const SizedBox(width: 12),
                          // View Details Button
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.deepSoilGreen,
                                    AppColors.deepSoilGreen,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.deepSoilGreen.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: AppColors.transparent,
                                child: InkWell(
                                  onTap:
                                      () => _navigateToDetails(
                                        context,
                                        subscription,
                                      ),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.visibility_rounded,
                                            color: AppColors.parchment,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Details',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  color: AppColors.parchment,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Payment Warning removed as per new design
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd').format(date);
    } catch (e) {
      return dateString;
    }
  }
}

class SubscriptionCardSkeleton extends StatelessWidget {
  final ResponsiveHelper responsive;
  const SubscriptionCardSkeleton({super.key, required this.responsive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShimmerLoading(
      isLoading: true,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: responsive.S,
          horizontal: responsive.screenPadding / 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.cardColor,
        ),
        padding: EdgeInsets.all(responsive.value(mobile: 12, tablet: 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(width: 140, height: 24, color: AppColors.parchment),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: responsive.value(mobile: 80, tablet: 100),
                  width: responsive.value(mobile: 80, tablet: 100),
                  color: AppColors.parchment,
                ),
                SizedBox(width: responsive.S),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: AppColors.parchment,
                      ),
                      SizedBox(height: responsive.S / 2),
                      Container(
                        width: 100,
                        height: 14,
                        color: AppColors.parchment,
                      ),
                      SizedBox(height: responsive.S),
                      Container(
                        width: 120,
                        height: 20,
                        color: AppColors.parchment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 40,
                      color: AppColors.parchment,
                    ),
                    SizedBox(width: responsive.S),
                    Container(
                      width: 150,
                      height: 16,
                      color: AppColors.parchment,
                    ),
                  ],
                ),
                SizedBox(height: responsive.S),
                Container(width: 200, height: 14, color: AppColors.parchment),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
