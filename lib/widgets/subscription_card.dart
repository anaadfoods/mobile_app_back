import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/cubits/subscription/subscription_state.dart';

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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
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
        SizedBox(
          height: responsive.value(mobile: 390, tablet: 420),
          child: PageView.builder(
            controller: _pageController,
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              final subscription = subscriptions[index];
              return SubscriptionCard(
                subscription: subscription,
                responsive: responsive,
                onTogglePause: () => _showToggleConfirmation(subscription),
                onRepayment: () {
                  final handler = SubscriptionHandler(context);
                  handler.processUPIRepayment(subscription.id);
                },
              );
            },
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
                Container(width: 150, height: 24, color: Colors.white),
                Container(width: 80, height: 24, color: Colors.white),
              ],
            ),
          ),
        ),
        SizedBox(height: responsive.S),
        SizedBox(
          height: responsive.value(mobile: 390, tablet: 420),
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            children: [SubscriptionCardSkeleton(responsive: responsive)],
          ),
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
      showDialog(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Resume Subscription?'),
              content: const Text(
                'Are you sure you want to resume this subscription?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.read<SubscriptionCubit>().togglePauseSubscription(
                      subscription.id,
                      null,
                      null,
                    );
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pause From',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildDatePickerField(
                          context: context,
                          hintText: 'From',
                          selectedDate: selectedStartDate,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setState(() => selectedStartDate = date);
                            }
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('To'),
                        ),
                        _buildDatePickerField(
                          context: context,
                          hintText: 'To',
                          selectedDate: selectedEndDate,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedStartDate ?? DateTime.now(),
                              firstDate: selectedStartDate ?? DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setState(() => selectedEndDate = date);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (maxPausesLeft <= 0) {
                            SnackBarHelper.showError(
                              context,
                              'No pauses remaining.',
                            );
                            return;
                          }
                          if (selectedStartDate == null ||
                              selectedEndDate == null) {
                            SnackBarHelper.showError(
                              context,
                              'Please select both start and end dates.',
                            );
                            return;
                          }
                          if (selectedEndDate!.isBefore(selectedStartDate!)) {
                            SnackBarHelper.showError(
                              context,
                              'End date must be after start date.',
                            );
                            return;
                          }
                          Navigator.pop(dialogContext);
                          context
                              .read<SubscriptionCubit>()
                              .togglePauseSubscription(
                                subscription.id,
                                selectedStartDate,
                                selectedEndDate,
                              );
                        },
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required String hintText,
    required DateTime? selectedDate,
    required Function() onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color:
                hintText == 'From'
                    ? Colors.transparent
                    : theme.inputDecorationTheme.fillColor,
            border: Border.all(
              color:
                  hintText == 'From' ? colorScheme.primary : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: colorScheme.primary,
                size: 12,
              ),
              const SizedBox(width: 8),
              Text(
                selectedDate != null
                    ? DateFormat('MMM dd, yyyy').format(selectedDate)
                    : hintText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      selectedDate != null
                          ? theme.textTheme.bodyLarge?.color
                          : theme.hintColor,
                ),
              ),
            ],
          ),
        ),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                SubscriptionPlanDetailScreen(subscription: subscription),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subscription = widget.subscription;
    final item = subscription.items.first;
    final bool isPaused = subscription.status == 'PAUSED';
    final deliveriesLeft = subscription.totalDeliveries - subscription.completedDeliveries;
    final progress = subscription.totalDeliveries > 0
        ? (subscription.completedDeliveries / subscription.totalDeliveries).clamp(0.0, 1.0)
        : 0.0;
    final double discountPercent = item.price > 0
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
              colors: isDark
                  ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                  : [Colors.white, const Color(0xFFFAFBFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : AppColors.primaryColor.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(isDark ? 0.15 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
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
                          AppColors.primaryColor.withOpacity(0.15),
                          AppColors.primaryColor.withOpacity(0.0),
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
                          AppColors.primaryLight.withOpacity(0.1),
                          AppColors.primaryLight.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.all(widget.responsive.value(mobile: 16, tablet: 20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isPaused
                                    ? [AppColors.warning, AppColors.warning.withOpacity(0.8)]
                                    : [AppColors.primaryColor, AppColors.primaryDark],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: (isPaused ? AppColors.warning : AppColors.primaryColor)
                                      .withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPaused ? Icons.pause_circle_rounded : Icons.autorenew_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isPaused ? 'Paused' : subscription.planName,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Delivery Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : AppColors.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_shipping_rounded,
                                  color: AppColors.primaryColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDate(subscription.nextDeliveryDate),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.primaryColor,
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
                            width: widget.responsive.value(mobile: 85, tablet: 100),
                            height: widget.responsive.value(mobile: 85, tablet: 100),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
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
                                    placeholder: (context, url) => Container(
                                      color: isDark ? Colors.grey[850] : Colors.grey[100],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primaryColor.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: isDark ? Colors.grey[850] : Colors.grey[100],
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
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [AppColors.success, AppColors.success.withOpacity(0.85)],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${discountPercent.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            color: Colors.white,
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
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹${item.price.toStringAsFixed(0)}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        decoration: TextDecoration.lineThrough,
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
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : AppColors.primaryColor.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.1),
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
                                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
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
                                  color: isPaused ? AppColors.success : AppColors.warning,
                                  width: 1.5,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: widget.onTogglePause,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isPaused ? Icons.play_circle_rounded : Icons.pause_circle_rounded,
                                          color: isPaused ? AppColors.success : AppColors.warning,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isPaused ? 'Resume' : 'Pause',
                                          style: theme.textTheme.labelLarge?.copyWith(
                                            color: isPaused ? AppColors.success : AppColors.warning,
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
                          const SizedBox(width: 12),
                          // View Details Button
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primaryColor, AppColors.primaryDark],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryColor.withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _navigateToDetails(context, subscription),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.visibility_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Details',
                                          style: theme.textTheme.labelLarge?.copyWith(
                                            color: Colors.white,
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
                        ],
                      ),
                      // Payment Warning (if pending)
                      if (subscription.canPayNextInstallment &&
                          subscription.installmentInfo?.installmentPaymentStatus == "PENDING" &&
                          subscription.installmentInfo!.currentInstallment > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.error.withOpacity(0.1),
                                  AppColors.error.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Payment pending for installment',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: widget.onRepayment,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    backgroundColor: AppColors.error,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Pay Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
            Container(width: 140, height: 24, color: Colors.white),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: responsive.value(mobile: 80, tablet: 100),
                  width: responsive.value(mobile: 80, tablet: 100),
                  color: Colors.white,
                ),
                SizedBox(width: responsive.S),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      SizedBox(height: responsive.S / 2),
                      Container(width: 100, height: 14, color: Colors.white),
                      SizedBox(height: responsive.S),
                      Container(width: 120, height: 20, color: Colors.white),
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
                    Container(width: 100, height: 40, color: Colors.white),
                    SizedBox(width: responsive.S),
                    Container(width: 150, height: 16, color: Colors.white),
                  ],
                ),
                SizedBox(height: responsive.S),
                Container(width: 200, height: 14, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}
