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
          height: responsive.value(mobile: 290, tablet: 320),
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
          height: responsive.value(mobile: 290, tablet: 320),
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
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => _navigateToDetails(context, widget.subscription),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: AppColors.animFast),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: AppColors.animMedium),
          margin: EdgeInsets.symmetric(
            vertical: widget.responsive.S,
            horizontal: widget.responsive.screenPadding / 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusL),
            border: Border.all(color: theme.dividerColor),
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(
                  _isPressed ? 0.02 : AppColors.shadowOpacityLight,
                ),
                blurRadius: _isPressed ? 4 : 10,
                offset: Offset(0, _isPressed ? 1 : 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(
            widget.responsive.value(mobile: 12, tablet: 16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeader(context),
              _buildProductDetails(context),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: theme.colorScheme.onPrimary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            "Subscription - ${widget.subscription.planName}",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final item = widget.subscription.items.first;
    final double discountPercent =
        item.price > 0
            ? ((item.price - item.discountedPrice) / item.price) * 100
            : 0;

    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.all(2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl ?? '',
              height: widget.responsive.value(mobile: 80, tablet: 100),
              width: widget.responsive.value(mobile: 80, tablet: 100),
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Container(
                    color: theme.splashColor,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    color: theme.splashColor,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: theme.iconTheme.color?.withOpacity(0.5),
                    ),
                  ),
            ),
          ),
          SizedBox(width: widget.responsive.S),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${widget.subscription.planName} – ${item.quantity} units",
                  style: textTheme.bodyMedium,
                ),
                SizedBox(height: widget.responsive.S),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "₹${item.discountedPrice.toStringAsFixed(0)}",
                      style: textTheme.displaySmall,
                    ),
                    SizedBox(width: widget.responsive.S),
                    Text(
                      "₹${item.price.toStringAsFixed(0)}",
                      style: textTheme.bodyLarge?.copyWith(
                        color: theme.disabledColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    if (discountPercent > 0) ...[
                      SizedBox(width: widget.responsive.S),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${discountPercent.toStringAsFixed(0)}% Off",
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final deliveriesLeft =
        widget.subscription.totalDeliveries -
        widget.subscription.completedDeliveries;
    final bool isPaused = widget.subscription.status == 'PAUSED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              style: theme.elevatedButtonTheme.style,
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 20),
              label: Text(isPaused ? "Resume" : "Pause"),
              onPressed: widget.onTogglePause,
            ),
            SizedBox(width: widget.responsive.S),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.subscription.remainingPauseTimes} Pause Left",
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.buttonBackgroundColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "$deliveriesLeft/${widget.subscription.totalDeliveries} Deliveries Left",
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.buttonBackgroundColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: widget.responsive.S),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Next Delivery: ${_formatDate(widget.subscription.nextDeliveryDate)}",
                style: textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.subscription.installmentInfo != null &&
                widget.subscription.canPayNextInstallment == true)
              Text(
                "${widget.subscription.installmentInfo?.installmentPaymentStatus.toUpperCase()}",
              ),
            if (widget.subscription.canPayNextInstallment) ...[
              if (widget
                          .subscription
                          .installmentInfo
                          ?.installmentPaymentStatus ==
                      "PENDING" &&
                  widget.subscription.installmentInfo!.currentInstallment > 1)
                TextButton(
                  onPressed: widget.onRepayment,
                  child: Text(
                    "Pay Now",
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
            ],
          ],
        ),
      ],
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
