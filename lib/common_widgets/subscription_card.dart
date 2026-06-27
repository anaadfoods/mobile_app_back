import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/common_widgets/pause_date_picker_sheet.dart';
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
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<SubscriptionCubit>().fetchUserSubscriptions();
    }
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

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const SizedBox.shrink();
        }

        return BlocConsumer<SubscriptionCubit, SubscriptionState>(
          listener: (context, state) {
            if (state is SubscriptionActionSuccess) {
              SnackBarHelper.showSuccess(context, state.message);
              context.read<SubscriptionCubit>().fetchUserSubscriptions();
            } else if (state is SubscriptionError) {
              SnackBarHelper.showError(
                context,
                "Looks like a network hiccup! Please check your internet and try again.",
              );
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
                  child: Text(""),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
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

  void _showConfirmationPopup(
    BuildContext context,
    bool isPause,
    VoidCallback onConfirm,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dynamically set the theme color based on the action
    final Color primaryColor =
        isPause ? AppColors.harvestAmber : AppColors.deepSoilGreen;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    isDark
                        ? [
                          AppColors.darkSurfaceElevated,
                          AppColors.darkSurfaceElevated,
                        ]
                        : [AppColors.parchment, AppColors.parchment],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.charcoal.withValues(
                    alpha: isDark ? 0.3 : 0.1,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPause
                        ? Icons.pause_circle_rounded
                        : Icons.play_circle_rounded,
                    color: primaryColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isPause ? 'Pause Subscription?' : 'Resume Subscription?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  isPause
                      ? 'Are you sure you want to pause your subscription for the selected dates?'
                      : 'Are you sure you want to resume your subscription? Your deliveries will restart from the next scheduled date.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isDark
                            ? AppColors.pureWhite.withValues(alpha: 0.7)
                            : AppColors.charcoal60,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color:
                                isDark
                                    ? AppColors.pureWhite.withValues(alpha: 0.7)
                                    : AppColors.charcoal60,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: AppColors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(dialogContext);
                              onConfirm();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  isPause ? 'Pause' : 'Resume',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.parchment,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showToggleConfirmation(Subscription subscription) {
    final isCurrentlyPaused = subscription.status == 'PAUSED';

    if (!isCurrentlyPaused && subscription.remainingPauseTimes <= 0) {
      SnackBarHelper.showError(
        context,
        "Looks like you've used all your pauses for this plan!",
      );
      return;
    }

    if (isCurrentlyPaused) {
      _showConfirmationPopup(
        context,
        false, // isPause = false
        () {
          context.read<SubscriptionCubit>().togglePauseSubscription(
            subscription.id,
            null,
            null,
          );
        },
      );
      return;
    }

    // Show pause date picker first, then confirm
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder:
          (context) => PauseDatePickerSheet(
            maxPausesLeft: subscription.remainingPauseTimes,
            maxPauseDaysLeft: subscription.remainingPauseDays,
            onConfirm: (start, end) {
              _showConfirmationPopup(
                context,
                true, // isPause = true
                () {
                  context.read<SubscriptionCubit>().togglePauseSubscription(
                    subscription.id,
                    start,
                    end,
                  );
                },
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
                      ? [
                        AppColors.darkSurfaceElevated,
                        AppColors.darkSurfaceElevated,
                      ]
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
                                      : AppColors.harvestAmber.withValues(
                                        alpha: 0.08,
                                      ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.harvestAmber.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_shipping_rounded,
                                  color: AppColors.harvestAmber,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDate(subscription.nextDeliveryDate),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.harvestAmber,
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
                                  '${item.unitWeight} kg • ${item.quantity} units',
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
                                            color: AppColors.getPriceColor(
                                              context,
                                            ),
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
                                    backgroundColor: AppColors.deepSoilGreen
                                        .withValues(alpha: 0.15),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
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
