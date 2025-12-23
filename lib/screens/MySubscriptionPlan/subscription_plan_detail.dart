import 'package:grocery_app/common_widgets/global_import.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  // --- All original state and logic are preserved ---
  List<Subscription> allSubscriptions = [];
  List<Subscription> filteredSubscriptions = [];
  String currentFilter = "ACTIVE";
  bool _isLoading = true;
  final SubscriptionService _subscriptionService = SubscriptionService();

  Future<void> _fetchSubscriptions() async {
    setState(() => _isLoading = true);
    try {
      final response = await _subscriptionService.getSubscriptions();
      if (!mounted) return;
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        setState(() {
          allSubscriptions = data.map((item) => item as Subscription).toList();
          _filterSubscriptions(currentFilter);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(
          context,
          response['message'] ?? 'Failed to fetch subscriptions',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackBarHelper.showError(
        context,
        'An error occurred while fetching subscriptions',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSubscriptions();
    });
  }

  void _filterSubscriptions(String status) {
    setState(() {
      currentFilter = status;
      if (status == "All") {
        filteredSubscriptions = allSubscriptions;
      } else {
        filteredSubscriptions =
            allSubscriptions
                .where((subscription) => subscription.status == status)
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Subscriptions"),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: _fetchSubscriptions,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
          ],
          bottom: TabBar(
            onTap: (index) {
              if (index == 0) _filterSubscriptions("ACTIVE");
              if (index == 1) _filterSubscriptions("PAUSED");
              if (index == 2) _filterSubscriptions("CANCELLED");
              if (index == 3) _filterSubscriptions("COMPLETED");
            },
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: theme.textTheme.labelMedium,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: "Active"),
              Tab(text: "Paused"),
              Tab(text: "Cancelled"),
              Tab(text: "Completed"),
            ],
          ),
        ),
        body: _buildSubscriptionList(),
      ),
    );
  }

  Widget _buildSubscriptionList() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (filteredSubscriptions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _fetchSubscriptions,
      color: theme.colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppColors.spacingS),
        itemCount: filteredSubscriptions.length,
        itemBuilder: (context, index) {
          final subscription = filteredSubscriptions[index];
          return _SubscriptionListItem(
            subscription: subscription,
            onUpdate: _fetchSubscriptions,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String statusText;
    IconData statusIcon;

    switch (currentFilter) {
      case 'ACTIVE':
        statusText = 'No active subscriptions';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'PAUSED':
        statusText = 'No paused subscriptions';
        statusIcon = Icons.pause_circle_outline;
        break;
      case 'CANCELLED':
        statusText = 'No cancelled subscriptions';
        statusIcon = Icons.cancel_outlined;
        break;
      case 'COMPLETED':
        statusText = 'No completed subscriptions';
        statusIcon = Icons.task_alt;
        break;
      default:
        statusText = 'No subscriptions found';
        statusIcon = Icons.inbox_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppColors.spacingXL),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                statusIcon,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppColors.spacingXL),
            Text(
              statusText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppColors.spacingS),
            Text(
              'Pull down to refresh',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppColors.spacingS),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spacingL,
            vertical: AppColors.spacingS,
          ),
          child: ShimmerLoading(
            isLoading: true,
            child: Container(
              padding: const EdgeInsets.all(AppColors.spacingM),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppColors.radiusL),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.splashColor,
                      borderRadius: BorderRadius.circular(AppColors.radiusM),
                    ),
                  ),
                  const SizedBox(width: AppColors.spacingL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: theme.splashColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: AppColors.spacingS),
                        Container(
                          width: 100,
                          height: 14,
                          decoration: BoxDecoration(
                            color: theme.splashColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: AppColors.spacingS),
                        Container(
                          width: 70,
                          height: 14,
                          decoration: BoxDecoration(
                            color: theme.splashColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- NEW HELPER WIDGET TO MANAGE ITS OWN STATE ---
class _SubscriptionListItem extends StatefulWidget {
  final Subscription subscription;
  final VoidCallback onUpdate;
  const _SubscriptionListItem({
    required this.subscription,
    required this.onUpdate,
  });

  @override
  State<_SubscriptionListItem> createState() => _SubscriptionListItemState();
}

class _SubscriptionListItemState extends State<_SubscriptionListItem> {
  bool _isLoading = false;
  final SubscriptionService _subscriptionService = SubscriptionService();

  Future<void> _togglePauseSubscription(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    setState(() => _isLoading = true);
    try {
      final response = await _subscriptionService.togglePauseSubscription(
        widget.subscription.id,
        startDate,
        endDate,
      );
      if (!mounted) return;
      if (response['success'] == true) {
        SnackBarHelper.showSuccess(
          context,
          response['details'] ?? 'Subscription status updated successfully',
        );
        widget.onUpdate(); // Call the parent's refresh method
      } else {
        SnackBarHelper.showError(
          context,
          response['details'] ?? 'Failed to update subscription status',
        );
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToggleConfirmation() {
    final theme = Theme.of(context);
    final isCurrentlyPaused = widget.subscription.status == 'PAUSED';
    final maxPausesLeft = widget.subscription.remainingPauseTimes;
    DateTime? selectedStartDate;
    DateTime? selectedEndDate;

    if (isCurrentlyPaused) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Resume Subscription?'),
              content: const Text(
                'Are you sure you want to resume this subscription?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _togglePauseSubscription(null, null);
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
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                        Text('Pause From', style: theme.textTheme.displaySmall),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
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
                              setDialogState(() => selectedStartDate = date);
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
                              setDialogState(() => selectedEndDate = date);
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
                          Navigator.pop(context);
                          _togglePauseSubscription(
                            selectedStartDate!,
                            selectedEndDate!,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final subscription = widget.subscription;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    SubscriptionPlanDetailScreen(subscription: subscription),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppColors.spacingL,
          vertical: AppColors.spacingS,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppColors.radiusL),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(
                AppColors.shadowOpacityLight,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Subscription - ${subscription.planName}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      Text(
                        'Next Delivery: ${subscription.nextDeliveryDate.toString().split(' ')[0]}',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        subscription
                                    .installmentInfo
                                    ?.installmentPaymentStatus ==
                                "PENDING"
                            ? "Pending"
                            : "Paid",
                        style: textTheme.labelLarge?.copyWith(
                          color:
                              subscription.installmentPaymentStatus == "PENDING"
                                  ? colorScheme.error
                                  : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppColors.spacingS),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppColors.radiusM),
                        child:
                            (subscription.items.isNotEmpty &&
                                    subscription.items[0].imageUrl != null &&
                                    subscription.items[0].imageUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                  imageUrl: subscription.items[0].imageUrl!,
                                  height: 90,
                                  width: 90,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        height: 90,
                                        width: 90,
                                        decoration: BoxDecoration(
                                          color: theme.splashColor,
                                          borderRadius: BorderRadius.circular(
                                            AppColors.radiusM,
                                          ),
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: theme.disabledColor,
                                          ),
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Container(
                                        height: 90,
                                        width: 90,
                                        decoration: BoxDecoration(
                                          color: theme.splashColor,
                                          borderRadius: BorderRadius.circular(
                                            AppColors.radiusM,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.error_outline,
                                          color: theme.disabledColor,
                                          size: 32,
                                        ),
                                      ),
                                )
                                : Container(
                                  height: 90,
                                  width: 90,
                                  decoration: BoxDecoration(
                                    color: theme.splashColor,
                                    borderRadius: BorderRadius.circular(
                                      AppColors.radiusM,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: theme.disabledColor,
                                    size: 32,
                                  ),
                                ),
                      ),
                      const SizedBox(width: AppColors.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              subscription.items[0].productName,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '₹${subscription.items[0].discountedPrice.toStringAsFixed(0)}',
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '₹${subscription.items[0].price.toStringAsFixed(0)}',
                                  style: textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: theme.disabledColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: ElevatedButton.icon(
                    style: theme.elevatedButtonTheme.style,
                    icon: Icon(
                      subscription.status == "PAUSED"
                          ? Icons.play_arrow
                          : Icons.pause,
                      size: 18,
                    ),
                    label: FittedBox(
                      child: Text(
                        subscription.status == "PAUSED" ? "Resume" : "Pause",
                      ),
                    ),
                    onPressed: _isLoading ? null : _showToggleConfirmation,
                  ),
                ),
                FittedBox(
                  child: Text(
                    '${(subscription.totalDeliveries) - (subscription.completedDeliveries)} /${subscription.totalDeliveries} Deliveries Left',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
