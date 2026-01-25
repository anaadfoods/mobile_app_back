import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/widgets/pause_date_picker_sheet.dart';
import 'dart:math' as math;

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<Subscription> allSubscriptions = [];
  List<Subscription> filteredSubscriptions = [];
  String currentFilter = "ACTIVE";
  bool _isLoading = true;
  String? _errorMessage;
  final SubscriptionService _subscriptionService = SubscriptionService();

  final List<_FilterTab> _tabs = [
    _FilterTab('Active', 'ACTIVE', Icons.autorenew_rounded, AppColors.success),
    _FilterTab(
      'Paused',
      'PAUSED',
      Icons.pause_circle_outline,
      AppColors.warning,
    ),
    _FilterTab(
      'Cancelled',
      'CANCELLED',
      Icons.cancel_outlined,
      AppColors.error,
    ),
    _FilterTab(
      'Completed',
      'COMPLETED',
      Icons.check_circle_outline,
      AppColors.info,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
  }

  Future<void> _fetchSubscriptions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _subscriptionService.getSubscriptions();
      if (!mounted) return;

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<Subscription> subscriptionsList = [];

        if (data is List<Subscription>) {
          subscriptionsList = data;
        } else if (data is List) {
          subscriptionsList = data.whereType<Subscription>().toList();
        }

        setState(() {
          allSubscriptions = subscriptionsList;
          _filterSubscriptions(currentFilter);
          _isLoading = false;
        });
      } else {
        setState(() {
          allSubscriptions = [];
          filteredSubscriptions = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        allSubscriptions = [];
        filteredSubscriptions = [];
        _isLoading = false;
        _errorMessage = 'Unable to load subscriptions';
      });
      debugPrint('Error fetching subscriptions: $e');
    }
  }

  void _filterSubscriptions(String status) {
    setState(() {
      currentFilter = status;
      if (status == "All") {
        filteredSubscriptions = List.from(allSubscriptions);
      } else {
        filteredSubscriptions =
            allSubscriptions
                .where((subscription) => subscription.status == status)
                .toList();
      }
    });
  }

  int _getCountForStatus(String status) {
    if (allSubscriptions.isEmpty) return 0;
    return allSubscriptions.where((s) => s.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _fetchSubscriptions,
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Modern U-Shape Header
            _buildAnimatedHeader(theme, isDark),
            // Filter chips
            SliverToBoxAdapter(child: _buildFilterTabs(theme, isDark)),
            // Summary card
            SliverToBoxAdapter(child: _buildSummaryCard(theme, isDark)),
            // Content
            _buildContent(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(ThemeData theme, bool isDark) {
    final activeCount = _getCountForStatus('ACTIVE');
    final pausedCount = _getCountForStatus('PAUSED');
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;

    // Calculate dynamic header height based on screen size and content
    final screenHeight = mediaQuery.size.height;
    final hasStats = !_isLoading && allSubscriptions.isNotEmpty;
    // Base height accounts for: status bar + back button + title + subtitle + padding
    // Add extra height for stats row if visible
    final baseHeight = statusBarHeight + 140;
    final statsHeight = hasStats ? 44.0 : 0.0;
    final headerHeight = (baseHeight + statsHeight).clamp(
      180.0,
      math.max(180.0, screenHeight * 0.28).toDouble(),
    );

    return SliverToBoxAdapter(
      child: Container(
        constraints: BoxConstraints(minHeight: headerHeight),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)]
                    : [AppColors.primaryColor, AppColors.primaryDark],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.3),
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
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),

            // Animated Icon - position dynamically
            Positioned(
              top: statusBarHeight + 16,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.autorenew_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),

            // Header Content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row with Back Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      "My Subscriptions",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      allSubscriptions.isEmpty
                          ? "Your subscriptions will appear here"
                          : "${allSubscriptions.length} subscription${allSubscriptions.length != 1 ? 's' : ''} total",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    // Stats Row - scrollable to prevent overflow
                    if (hasStats) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildHeaderStatChip(
                              icon: Icons.autorenew_rounded,
                              label: 'Active',
                              count: activeCount,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            _buildHeaderStatChip(
                              icon: Icons.pause_circle_outline,
                              label: 'Paused',
                              count: pausedCount,
                              color: AppColors.warning,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStatChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              _tabs.map((tab) {
                final isSelected = currentFilter == tab.status;
                final count = _getCountForStatus(tab.status);

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _filterSubscriptions(tab.status);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient:
                            isSelected
                                ? LinearGradient(
                                  colors: [
                                    tab.color,
                                    tab.color.withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                : null,
                        color:
                            isSelected
                                ? null
                                : (isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.transparent
                                  : (isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[200]!),
                          width: 1.5,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: tab.color.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                                : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDark ? 0.3 : 0.05,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab.icon,
                            size: 18,
                            color: isSelected ? Colors.white : tab.color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tab.label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.grey[300]
                                          : theme.hintColor),
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.white.withOpacity(0.25)
                                        : tab.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                count.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : tab.color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, bool isDark) {
    if (_isLoading || allSubscriptions.isEmpty) return const SizedBox.shrink();

    final activeCount = _getCountForStatus('ACTIVE');
    final totalSpent = allSubscriptions
        .where((s) => s.status == 'ACTIVE' || s.status == 'COMPLETED')
        .fold<double>(
          0,
          (sum, sub) =>
              sum + (sub.items.isNotEmpty ? sub.items[0].discountedPrice : 0),
        );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [const Color(0xFF1E1E1E), const Color(0xFF2A2A2A)]
                  : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              theme,
              isDark,
              Icons.shopping_bag_rounded,
              activeCount.toString(),
              'Active',
              AppColors.success,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
          Expanded(
            child: _buildSummaryItem(
              theme,
              isDark,
              Icons.currency_rupee_rounded,
              '₹${totalSpent.toStringAsFixed(0)}',
              'Total Value',
              AppColors.primaryColor,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
          Expanded(
            child: _buildSummaryItem(
              theme,
              isDark,
              Icons.inventory_2_rounded,
              allSubscriptions.length.toString(),
              'Total',
              AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    ThemeData theme,
    bool isDark,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildLoadingState(isDark, index),
            childCount: 3,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(child: _buildErrorState(theme));
    }

    if (filteredSubscriptions.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState(theme));
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final subscription = filteredSubscriptions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _SubscriptionCard(
              subscription: subscription,
              onUpdate: _fetchSubscriptions,
              index: index,
            ),
          );
        }, childCount: filteredSubscriptions.length),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final currentTab = _tabs.firstWhere((t) => t.status == currentFilter);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxHeight < 600;
        final iconSize = isSmallScreen ? 48.0 : 64.0;
        final paddingContainer = isSmallScreen ? 20.0 : 32.0;
        final paddingScreen = isSmallScreen ? 24.0 : 40.0;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(paddingScreen),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(paddingContainer),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        currentTab.color.withOpacity(0.15),
                        currentTab.color.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: currentTab.color.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    currentTab.icon,
                    size: iconSize,
                    color: currentTab.color,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 32),
                Text(
                  currentFilter == 'ACTIVE'
                      ? "Automate Your Nutrition"
                      : 'No ${currentTab.label.toLowerCase()} subscriptions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 20 : 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  currentFilter == 'ACTIVE'
                      ? 'Toxin-free Food is a basic requirement, not a one-time purchase. Subscribe to staples and never run out of purity.'
                      : 'Your ${currentTab.label.toLowerCase()} subscriptions\nwill appear here',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 24 : 32),
                if (currentFilter == 'ACTIVE')
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryColor, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.shopping_bag_rounded),
                      label: const Text('Browse Products'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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

  Widget _buildErrorState(ThemeData theme) {
    return ErrorStateWidget(
      title: 'Failed to Load Subscriptions',
      subtitle: _errorMessage ?? 'Something went wrong. Please try again.',
      errorType: ErrorType.server,
      onRetry: _fetchSubscriptions,
    );
  }

  Widget _buildLoadingState(bool isDark, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + (index * 100)),
        curve: Curves.easeOut,
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: ShimmerLoading(
                isLoading: true,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Tab data class
class _FilterTab {
  final String label;
  final String status;
  final IconData icon;
  final Color color;

  _FilterTab(this.label, this.status, this.icon, this.color);
}

// Subscription Card
class _SubscriptionCard extends StatefulWidget {
  final Subscription subscription;
  final VoidCallback onUpdate;
  final int index;

  const _SubscriptionCard({
    required this.subscription,
    required this.onUpdate,
    this.index = 0,
  });

  @override
  State<_SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<_SubscriptionCard> {
  bool _isLoading = false;

  Future<void> _togglePauseSubscription(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    setState(() => _isLoading = true);

    // Use SubscriptionCubit to toggle pause - this updates state and refreshes list
    await context.read<SubscriptionCubit>().togglePauseSubscription(
      widget.subscription.id,
      startDate,
      endDate,
    );

    if (!mounted) return;

    // Check cubit state for result
    final state = context.read<SubscriptionCubit>().state;
    if (state is SubscriptionActionSuccess) {
      SnackBarHelper.showSuccess(context, state.message);
    } else if (state is SubscriptionError) {
      SnackBarHelper.showError(context, state.message);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showToggleConfirmation() {
    final isCurrentlyPaused = widget.subscription.status == 'PAUSED';

    if (isCurrentlyPaused) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder:
            (context) => ResumeSubscriptionSheet(
              onConfirm: () => _togglePauseSubscription(null, null),
            ),
      );
      return;
    }

    // Show pause date picker
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => PauseDatePickerSheet(
            maxPausesLeft: widget.subscription.remainingPauseTimes,
            onConfirm: (start, end) => _togglePauseSubscription(start, end),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subscription = widget.subscription;
    final status = _getStatusInfo(subscription.status);
    final deliveriesLeft =
        subscription.totalDeliveries - subscription.completedDeliveries;
    final progress =
        subscription.totalDeliveries > 0
            ? (subscription.completedDeliveries / subscription.totalDeliveries)
                .clamp(0.0, 1.0)
            : 0.0;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (widget.index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) =>
                      SubscriptionPlanDetailScreen(subscription: subscription),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isDark
                      ? [const Color(0xFF1E1E1E), const Color(0xFF252525)]
                      : [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isDark
                      ? Colors.grey[800]!.withOpacity(0.3)
                      : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: status.color.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Modern Header with gradient
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      status.color.withOpacity(0.12),
                      status.color.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(19),
                  ),
                ),
                child: Row(
                  children: [
                    // Status badge with glow effect
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [status.color, status.color.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: status.color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.icon, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            status.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Plan badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 14,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            subscription.planName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Next delivery
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.grey[850]
                                : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_shipping_rounded,
                            size: 14,
                            color: theme.hintColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(subscription.nextDeliveryDate),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.hintColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content with product info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image with elevated card style
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildProductImage(subscription, isDark),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Product details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscription.items.isNotEmpty
                                ? subscription.items[0].productName
                                : 'Subscription',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (subscription.items.isNotEmpty)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '₹${subscription.items[0].discountedPrice.toStringAsFixed(0)}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹${subscription.items[0].price.toStringAsFixed(0)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: theme.hintColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${((1 - subscription.items[0].discountedPrice / subscription.items[0].price) * 100).toStringAsFixed(0)}% OFF',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          // Progress with circular indicator
                          Row(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 3,
                                      backgroundColor:
                                          isDark
                                              ? Colors.grey[800]
                                              : Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$deliveriesLeft deliveries left',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${subscription.completedDeliveries} of ${subscription.totalDeliveries} completed',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: theme.hintColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons with modern design
              if (subscription.status == 'ACTIVE' ||
                  subscription.status == 'PAUSED')
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  subscription.status == 'PAUSED'
                                      ? AppColors.success
                                      : AppColors.warning,
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap:
                                  _isLoading ? null : _showToggleConfirmation,
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isLoading)
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  subscription.status ==
                                                          'PAUSED'
                                                      ? AppColors.success
                                                      : AppColors.warning,
                                                ),
                                          ),
                                        )
                                      else
                                        Icon(
                                          subscription.status == 'PAUSED'
                                              ? Icons.play_circle_rounded
                                              : Icons.pause_circle_rounded,
                                          size: 20,
                                          color:
                                              subscription.status == 'PAUSED'
                                                  ? AppColors.success
                                                  : AppColors.warning,
                                        ),
                                      const SizedBox(width: 8),
                                      Text(
                                        subscription.status == 'PAUSED'
                                            ? 'Resume'
                                            : 'Pause',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color:
                                                  subscription.status ==
                                                          'PAUSED'
                                                      ? AppColors.success
                                                      : AppColors.warning,
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
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryColor,
                                AppColors.primaryDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => SubscriptionPlanDetailScreen(
                                          subscription: subscription,
                                        ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.visibility_rounded,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'View Details',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
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
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(Subscription subscription, bool isDark) {
    if (subscription.items.isNotEmpty &&
        subscription.items[0].imageUrl != null &&
        subscription.items[0].imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: subscription.items[0].imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildImagePlaceholder(isDark),
        errorWidget: (_, __, ___) => _buildImagePlaceholder(isDark),
      );
    }
    return _buildImagePlaceholder(isDark);
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2D2D2D) : Colors.grey[100],
      child: Icon(
        Icons.image_outlined,
        color: isDark ? Colors.white24 : Colors.grey[400],
        size: 24,
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return _StatusInfo(
          AppColors.success,
          Icons.autorenew_rounded,
          'Active',
        );
      case 'PAUSED':
        return _StatusInfo(
          AppColors.warning,
          Icons.pause_circle_rounded,
          'Paused',
        );
      case 'CANCELLED':
        return _StatusInfo(AppColors.error, Icons.cancel_rounded, 'Cancelled');
      case 'COMPLETED':
        return _StatusInfo(
          AppColors.info,
          Icons.check_circle_rounded,
          'Completed',
        );
      default:
        return _StatusInfo(Colors.grey, Icons.help_outline, status);
    }
  }
}

class _StatusInfo {
  final Color color;
  final IconData icon;
  final String label;
  _StatusInfo(this.color, this.icon, this.label);
}

// Pause Date Picker Bottom Sheet
