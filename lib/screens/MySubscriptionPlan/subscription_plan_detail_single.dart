import 'package:grocery_app/common_widgets/global_import.dart';

import 'package:grocery_app/common_widgets/pause_date_picker_sheet.dart';
import 'package:grocery_app/routes/app_routes.dart';

class SubscriptionPlanDetailScreen extends StatefulWidget {
  final Subscription? subscription;
  final String? subscriptionId;

  const SubscriptionPlanDetailScreen({
    super.key,
    this.subscription,
    this.subscriptionId,
  });

  @override
  State<SubscriptionPlanDetailScreen> createState() =>
      _SubscriptionPlanDetailScreenState();
}

class _SubscriptionPlanDetailScreenState
    extends State<SubscriptionPlanDetailScreen>
    with TickerProviderStateMixin {
  // --- ALL ORIGINAL STATE AND LOGIC ARE PRESERVED ---
  final SubscriptionService _subscriptionService = SubscriptionService();
  final bool _isLoading = false;
  List<Invoice> _invoices = [];
  bool _isLoadingInvoices = true;
  String? _invoiceError;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Subscription?
  _currentOrder; // Using _currentOrder as the state variable for subscription
  bool _isLoadingSubscription = false;

  List<TextDto> orderList = [];
  List<TextDto> shippedList = [];
  List<TextDto> outOfDeliveryList = [];
  List<TextDto> deliveredList = [];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.subscription != null) {
      _currentOrder = widget.subscription;
      _initAnimationsAndData();
    } else if (widget.subscriptionId != null) {
      _loadSubscription(widget.subscriptionId!);
    }
  }

  void _initAnimationsAndData() {
    if (_currentOrder?.installmentPaymentStatus == "PENDING") {
      _pulseController.repeat(reverse: true);
    }
    _loadInvoices();
  }

  Future<void> _loadSubscription(String id) async {
    setState(() => _isLoadingSubscription = true);
    try {
      final response = await _subscriptionService.getSubscriptionDetails(
        int.parse(id),
      );
      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          setState(() {
            _currentOrder = response['data'] as Subscription?;
            _isLoadingSubscription = false;
          });
          _initAnimationsAndData();
        } else {
          setState(() => _isLoadingSubscription = false);
          SnackBarHelper.showError(
            context,
            response['message'] ?? 'Failed to load subscription details',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSubscription = false);
        SnackBarHelper.showError(context, 'Failed to load subscription: $e');
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoadingInvoices = true;
      _invoiceError = null;
    });
    if (_currentOrder == null) return;
    try {
      final response = await _subscriptionService.getSubscriptionInvoices(
        _currentOrder!.id,
      );
      if (mounted) {
        setState(() {
          _invoices = response.invoices;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _invoiceError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInvoices = false;
        });
      }
    }
  }

  Future<void> _downloadAndOpenInvoice(Invoice invoice) async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          final result = await Permission.storage.request();
          if (!result.isGranted) {
            if (mounted) {
              SnackBarHelper.showError(
                context,
                'Please provide media access to download the invoice.',
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: AppColors.parchment,
                  onPressed: openAppSettings,
                ),
              );
            }
            return;
          }
        }
      }
    }

    SnackBarHelper.showInfo(context, 'Downloading ${invoice.displayName}...');
    try {
      final savedPath = await _subscriptionService.downloadInvoice(
        invoice.s3Url,
        invoice.displayName,
      );

      SnackBarHelper.showInvoiceDownloaded(context);

      // The service already opens the file, but just in case or if we want to log it
      print('Invoice downloaded and opened: $savedPath');
    } catch (e) {
      // Parse error message and show user-friendly text
      String errorMessage =
          'Unable to download invoice. Please try again later.';
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('400') || errorStr.contains('bad request')) {
        errorMessage = 'Invoice is not available yet. Please try again later.';
      } else if (errorStr.contains('404') || errorStr.contains('not found')) {
        errorMessage = 'Invoice not found. It may have been removed.';
      } else if (errorStr.contains('network') ||
          errorStr.contains('socket') ||
          errorStr.contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (errorStr.contains('permission') ||
          errorStr.contains('storage')) {
        errorMessage = 'Storage permission required to save the invoice.';
      } else if (errorStr.contains('timeout')) {
        errorMessage = 'Download timed out. Please try again.';
      }

      SnackBarHelper.showError(context, errorMessage);
    }
  }

  Future<void> _togglePauseSubscription(
    Subscription subscription,
    DateTime? pauseStartDate,
    DateTime? pauseEndDate,
  ) async {
    // Use SubscriptionCubit to toggle pause - this updates state and refreshes list
    await context.read<SubscriptionCubit>().togglePauseSubscription(
      subscription.id,
      pauseStartDate,
      pauseEndDate,
    );

    if (!mounted) return;

    // Check cubit state for result
    final state = context.read<SubscriptionCubit>().state;
    if (state is SubscriptionActionSuccess) {
      SnackBarHelper.showSuccess(context, state.message);
      // Pop back to refresh the list
      Navigator.pop(context);
    } else if (state is SubscriptionError) {
      SnackBarHelper.showError(context, state.message);
    }
  }

  void _showConfirmationPopup(
    BuildContext context,
    bool isPause,
    VoidCallback onConfirm,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
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
                        ? [AppColors.darkSurfaceElevated, AppColors.darkSurfaceElevated]
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
                    color: (isPause
                            ? AppColors.harvestAmber
                            : AppColors.harvestAmber)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPause
                        ? Icons.pause_circle_rounded
                        : Icons.play_circle_rounded,
                    color:
                        isPause
                            ? AppColors.harvestAmber
                            : AppColors.harvestAmber,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isPause ? 'Pause Subscription?' : 'Resume Subscription?',
                  style: theme.textTheme.headlineSmall?.copyWith(
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
                    color: theme.hintColor,
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
                            color: theme.hintColor,
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
                            colors:
                                isPause
                                    ? [
                                      AppColors.harvestAmber,
                                      AppColors.harvestAmber.withValues(
                                        alpha: 0.8,
                                      ),
                                    ]
                                    : [
                                      AppColors.harvestAmber,
                                      AppColors.harvestAmber.withValues(
                                        alpha: 0.8,
                                      ),
                                    ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (isPause
                                      ? AppColors.harvestAmber
                                      : AppColors.harvestAmber)
                                  .withValues(alpha: 0.3),
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

    if (isCurrentlyPaused) {
      _showConfirmationPopup(
        context,
        false, // isPause = false
        () => _togglePauseSubscription(subscription, null, null),
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
            onConfirm: (start, end) {
              _showConfirmationPopup(
                context,
                true, // isPause = true
                () => _togglePauseSubscription(subscription, start, end),
              );
            },
          ),
    );
  }

  // Future<void> _togglePauseSubscription(DateTime? startDate, DateTime? endDate) async {
  //   // This logic is preserved
  // }

  // void _showToggleConfirmation() {
  //   // This logic is preserved
  // }

  // Future<void> _handleRepayment() async {
  //   await SubscriptionHandler().processUPIRepayment(context, _currentOrder!.id);
  // }

  // void _setupOrderStatusSteps() {
  //   // This logic is preserved
  // }

  String _formatDate(String dateStr, {String format = 'MMM dd, yyyy'}) {
    var date = DateTime.tryParse(dateStr);

    // Try to handle DD-MM-YYYY format if standard parse fails
    if (date == null) {
      try {
        final parts = dateStr.split(RegExp(r'[-/]'));
        if (parts.length >= 3) {
          // Assuming DD-MM-YYYY
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(
            parts[2].split(' ')[0],
          ); // Handle potential time
          date = DateTime(year, month, day);
        }
      } catch (_) {}
    }

    if (date == null) return dateStr;

    // Fix 2-digit years or 00xx years
    if (date.year < 100) {
      date = DateTime(
        date.year + 2000,
        date.month,
        date.day,
        date.hour,
        date.minute,
        date.second,
      );
    }

    return DateFormat(format).format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSubscription) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentOrder == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Invalid Link'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Invalid link or unauthorized access',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'We could not load the subscription details. The link may be invalid, or you might not have permission to view it.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 32),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, authState) {
                    final isAuthenticated = authState is Authenticated;
                    return ElevatedButton.icon(
                      onPressed: () {
                        if (isAuthenticated) {
                          context.goNamed(AppRoute.home.name);
                        } else {
                          context.goNamed(AppRoute.login.name);
                        }
                      },
                      icon: Icon(
                        isAuthenticated
                            ? Icons.home_rounded
                            : Icons.login_rounded,
                      ),
                      label: Text(isAuthenticated ? 'Go to Home' : 'Log In'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.goNamed(AppRoute.home.name);
      },
      child: Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.parchment,
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger a refresh of subscription details and invoices
          if (_currentOrder != null) {
            await _loadSubscription(_currentOrder!.id.toString());
          } else if (widget.subscriptionId != null) {
            await _loadSubscription(widget.subscriptionId!);
          }
          await _loadInvoices();
        },
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Modern U-Shape Header
            _buildAnimatedHeader(theme, isDark),
            // Content
            SliverToBoxAdapter(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          20,
                          16,
                          MediaQuery.of(context).padding.bottom + 100,
                        ),
                        child: Column(
                          children: [
                            _buildPaymentPendingHeader(theme),
                            _buildHeroProductCard(theme, isDark),
                            const SizedBox(height: 20),
                            _buildModernSummaryCard(theme, isDark),
                            const SizedBox(height: 20),
                            _buildDeliveryProgressCard(theme, isDark),
                            const SizedBox(height: 20),
                            _buildDeliveryAddressCard(theme, isDark),
                            const SizedBox(height: 20),
                            _buildModernPauseSection(theme, isDark),
                            const SizedBox(height: 20),
                            _buildModernSectionCard(
                              theme: theme,
                              isDark: isDark,
                              icon: Icons.description_rounded,
                              title: 'Invoices',
                              gradient: [
                                AppColors.deepSoilGreen,
                                AppColors.deepSoilGreen.withValues(alpha: 0.7),
                              ],
                              child: InvoiceTrackerWidget(
                                isLoading: _isLoadingInvoices,
                                error: _invoiceError,
                                invoices: _invoices,
                                onInvoiceTap: (invoice) {
                                  _downloadAndOpenInvoice(invoice);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildModernBottomButtons(theme, isDark),
      ),
    );
  }

  Widget _buildAnimatedHeader(ThemeData theme, bool isDark) {
    final subscription = _currentOrder!;
    final item =
        subscription.items.isNotEmpty ? subscription.items.first : null;

    return SliverToBoxAdapter(
      child: Container(
        constraints: const BoxConstraints(minHeight: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [
                      AppColors.deepSoilGreen,
                      AppColors.deepSoilGreen.withValues(alpha: 0.8),
                    ]
                    : [AppColors.deepSoilGreen, AppColors.deepSoilGreen],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepSoilGreen.withValues(alpha: 0.3),
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
                  color: AppColors.parchment.withValues(alpha: 0.1),
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
                  color: AppColors.parchment.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Header Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row with Back Button and Refresh
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildBackButton(theme, isDark),
                        const SizedBox(width: 8),
                        const AnaadLogoMark(),
                        GestureDetector(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            SnackBarHelper.showLoading(
                              context,
                              'Refreshing...',
                            );

                            // Re-load subscription details and invoices
                            if (_currentOrder != null) {
                              await _loadSubscription(
                                _currentOrder!.id.toString(),
                              );
                            } else if (widget.subscriptionId != null) {
                              await _loadSubscription(widget.subscriptionId!);
                            }
                            await _loadInvoices();

                            if (mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.parchment.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: AppColors.parchment,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Title and Status Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Subscription Details",
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.parchment,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(theme, isDark),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item != null
                          ? item.productName
                          : "View your subscription",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.parchment.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildStatusBadge(ThemeData theme, bool isDark) {
    final subscription = _currentOrder!;
    final isPaused = subscription.status == 'PAUSED';
    final isCancelled = subscription.status == 'CANCELLED';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isPaused) {
      statusColor = AppColors.harvestAmber;
      statusIcon = Icons.pause_circle_rounded;
      statusText = 'Paused';
    } else if (isCancelled) {
      statusColor = AppColors.rawEarth;
      statusIcon = Icons.cancel_rounded;
      statusText = 'Cancelled';
    } else {
      statusColor = AppColors.harvestAmber;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: AppColors.parchment, size: 16),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.parchment,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroProductCard(ThemeData theme, bool isDark) {
    final item = _currentOrder!.items.first;
    final double discountPercent =
        item.price > 0
            ? ((item.price - item.discountedPrice) / item.price) * 100
            : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [AppColors.darkSurfaceElevated, AppColors.darkSurfaceElevated]
                  : [AppColors.parchment, AppColors.parchment!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.charcoal.withValues(
                    alpha: isDark ? 0.4 : 0.15,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  (item.imageUrl != null)
                      ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        height: 110,
                        width: 110,
                        fit: BoxFit.cover,
                        placeholder:
                            (_, __) => Container(
                              color:
                                  isDark
                                      ? AppColors.darkSurfaceElevated
                                      : AppColors.parchment,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        errorWidget:
                            (_, __, ___) => Container(
                              color:
                                  isDark
                                      ? AppColors.darkSurfaceElevated
                                      : AppColors.parchment,
                              child: Icon(
                                Icons.image_rounded,
                                color: theme.hintColor,
                              ),
                            ),
                      )
                      : Container(
                        color:
                            isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
                        child: Icon(
                          Icons.image_rounded,
                          color: theme.hintColor,
                          size: 40,
                        ),
                      ),
                  // Discount badge
                  if (discountPercent > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.harvestAmber,
                              AppColors.harvestAmber.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.harvestAmber.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${discountPercent.toStringAsFixed(0)}% OFF',
                          style: TextStyle(
                            color: isDark ? AppColors.parchment : AppColors.charcoal,
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
          const SizedBox(width: 18),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.parchment : AppColors.charcoal,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.harvestAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.harvestAmber.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '${item.weightUnit} × ${item.quantity} units',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.deepSoilGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '₹${item.discountedPrice.toStringAsFixed(0)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.parchment : AppColors.harvestAmber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
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
    );
  }

  Widget _buildModernSummaryCard(ThemeData theme, bool isDark) {
    final subscription = _currentOrder!;
    final isPaymentPending = subscription.installmentPaymentStatus == 'PENDING';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [AppColors.darkSurfaceElevated, AppColors.darkSurfaceElevated]
                  : [AppColors.parchment, AppColors.parchment!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Plan name row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.harvestAmber, AppColors.harvestAmber],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.harvestAmber.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.card_membership_rounded,
                  color: AppColors.parchment,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.planName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.parchment : AppColors.charcoal,
                      ),
                    ),
                    Text(
                      'Subscription Plan',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Payment status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isPaymentPending
                            ? [
                              AppColors.rawEarth,
                              AppColors.rawEarth.withValues(alpha: 0.8),
                            ]
                            : [
                              AppColors.deepSoilGreen,
                              AppColors.deepSoilGreen.withValues(alpha: 0.8),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isPaymentPending
                              ? AppColors.rawEarth
                              : AppColors.harvestAmber)
                          .withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  isPaymentPending ? 'Unpaid' : 'Paid',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.parchment,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Info grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.parchment.withValues(alpha: 0.05)
                      : AppColors.harvestAmber.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    theme,
                    isDark,
                    Icons.calendar_month_rounded,
                    'Next Delivery',
                    _formatDate(
                      subscription.nextDeliveryDate,
                      format: 'MMM dd, yyyy',
                    ),
                    AppColors.harvestAmber,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.rawEarth12,
                ),
                Expanded(
                  child: _buildInfoItem(
                    theme,
                    isDark,
                    Icons.date_range_rounded,
                    'Valid Till',
                    _formatDate(subscription.endDate, format: 'MMM dd, yyyy'),
                    AppColors.harvestAmber,
                  ),
                ),
              ],
            ),
          ),
          // Pay Now button if pending
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    ThemeData theme,
    bool isDark,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  Widget _buildDeliveryProgressCard(ThemeData theme, bool isDark) {
    final subscription = _currentOrder;
    final deliveriesLeft =
        subscription!.totalDeliveries - subscription.completedDeliveries;
    final progress =
        subscription.totalDeliveries > 0
            ? (subscription.completedDeliveries / subscription.totalDeliveries)
                .clamp(0.0, 1.0)
            : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [AppColors.darkSurfaceElevated, AppColors.darkSurfaceElevated]
                  : [AppColors.parchment, AppColors.parchment!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.harvestAmber,
                      AppColors.harvestAmber.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.harvestAmber.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.parchment,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.parchment : AppColors.charcoal,
                      ),
                    ),
                    Text(
                      '$deliveriesLeft deliveries remaining',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor:
                          isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.harvestAmber,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.parchment : AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor:
                  isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.harvestAmber,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressStat(
                theme,
                '${subscription.totalDeliveries}',
                'Total',
                AppColors.harvestAmber,
              ),
              _buildProgressStat(
                theme,
                '${subscription.completedDeliveries}',
                'Completed',
                AppColors.harvestAmber,
              ),
              _buildProgressStat(
                theme,
                '$deliveriesLeft',
                'Remaining',
                AppColors.harvestAmber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(
    ThemeData theme,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  Widget _buildBackButton(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.goNamed(AppRoute.home.name);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.parchment.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.harvestAmber,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPaymentPendingHeader(ThemeData theme) {
    if ((_currentOrder!.installmentInfo?.installmentPaymentStatus ?? '')
            .toUpperCase() !=
        'PENDING') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.rawEarth.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.rawEarth.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: AppColors.rawEarth, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Payment Pending',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.rawEarth,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_currentOrder!.lastPaymentDate}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.rawEarth,
                  ),
                ),
              ],
            ),
          ),
          SubscriptionRepaymentButton(
            subscription: _currentOrder!,
            isExpanded: false,
            showLabel: true,
          ),
        ],
      ),
    );
  }

  Widget _buildModernPauseSection(ThemeData theme, bool isDark) {
    final subscription = _currentOrder;
    final bool isPaused = subscription!.status == 'PAUSED';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isPaused
                  ? [
                    AppColors.harvestAmber.withValues(alpha: 0.15),
                    AppColors.harvestAmber.withValues(alpha: 0.08),
                  ]
                  : isDark
                  ? [AppColors.darkSurfaceElevated, AppColors.darkSurfaceElevated]
                  : [AppColors.parchment, AppColors.parchment!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border:
            isPaused
                ? Border.all(
                  color: AppColors.harvestAmber.withValues(alpha: 0.3),
                  width: 1.5,
                )
                : null,
        boxShadow: [
          BoxShadow(
            color: (isPaused ? AppColors.harvestAmber : AppColors.charcoal)
                .withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isPaused
                            ? [
                              AppColors.harvestAmber,
                              AppColors.harvestAmber.withValues(alpha: 0.8),
                            ]
                            : [
                              AppColors.deepSoilGreen,
                              AppColors.deepSoilGreen,
                            ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (isPaused
                              ? AppColors.harvestAmber
                              : AppColors.harvestAmber)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  isPaused
                      ? Icons.pause_circle_rounded
                      : Icons.schedule_rounded,
                  color: AppColors.parchment,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPaused ? 'Subscription Paused' : 'Pause Controls',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.parchment : AppColors.charcoal,
                      ),
                    ),
                    Text(
                      isPaused
                          ? 'Resume to continue deliveries'
                          : '${subscription.remainingPauseTimes} pauses remaining',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.parchment.withValues(alpha: 0.1)
                          : AppColors.parchment,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${subscription.remainingPauseTimes}/${subscription.remainingPauseDays}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    isPaused
                        ? [
                          AppColors.harvestAmber,
                          AppColors.harvestAmber.withValues(alpha: 0.85),
                        ]
                        : [
                          AppColors.harvestAmber,
                          AppColors.harvestAmber.withValues(alpha: 0.85),
                        ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isPaused
                          ? AppColors.harvestAmber
                          : AppColors.harvestAmber)
                      .withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: () => _showToggleConfirmation(subscription),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPaused
                            ? Icons.play_circle_rounded
                            : Icons.pause_circle_rounded,
                        color: AppColors.parchment,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isPaused ? 'Resume Subscription' : 'Pause Subscription',
                        style: theme.textTheme.titleMedium?.copyWith(
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
        ],
      ),
    );
  }

  Widget _buildModernSectionCard({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required String title,
    required List<Color> gradient,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [AppColors.darkSurfaceElevated, AppColors.darkSurfaceElevated]
                  : [AppColors.parchment, AppColors.parchment!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.parchment, size: 24),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildModernBottomButtons(ThemeData theme, bool isDark) {
    final subscription = widget.subscription;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.harvestAmber, width: 2),
                ),
                child: Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    onTap: _loadInvoices,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: AppColors.harvestAmber,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Refresh',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.parchment : AppColors.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Expanded(
            //   flex: 2,
            //   child: Container(
            //     decoration: BoxDecoration(
            //       gradient: LinearGradient(
            //         colors: [AppColors.deepSoilGreen, AppColors.deepSoilGreen],
            //       ),
            //       borderRadius: BorderRadius.circular(16),
            //       boxShadow: [
            //         BoxShadow(
            //           color: AppColors.deepSoilGreen.withValues(alpha: 0.4),
            //           blurRadius: 12,
            //           offset: const Offset(0, 5),
            //         ),
            //       ],
            //     ),
            //     child: Material(
            //       color: AppColors.transparent,
            //       child: InkWell(
            //         onTap: () async {
            //           final product = await CategoryService.fetchProductById(
            //             subscription.items.first.productVariant,
            //           );
            //           Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder:
            //                   (builder) => AddressSelectionScreen(
            //                     isSubscription: true,
            //                     price: subscription.items.first.discountedPrice,
            //                     selectedPlan: subscription.plan,
            //                     quantity: subscription.items.first.quantity,
            //                     singleProduct: product,
            //                   ),
            //             ),
            //           );
            //         },
            //         borderRadius: BorderRadius.circular(16),
            //         child: Padding(
            //           padding: const EdgeInsets.symmetric(vertical: 16),
            //           child: Row(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             children: [
            //               const Icon(
            //                 Icons.replay_rounded,
            //                 color: AppColors.parchment,
            //                 size: 22,
            //               ),
            //               const SizedBox(width: 8),
            //               Text(
            //                 'Subscribe Again',
            //                 style: theme.textTheme.titleMedium?.copyWith(
            //                   color: AppColors.parchment,
            //                   fontWeight: FontWeight.bold,
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Color _outlineColor(ThemeData theme) {
    final cs = theme.colorScheme;
    return cs.outlineVariant;
  }

  Widget _buildDeliveryAddressCard(ThemeData theme, bool isDark) {
    final subscription = _currentOrder!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.harvestAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.harvestAmber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Delivery Address',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.parchment : AppColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getRecipientName(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subscription.deliveryAddress,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          Text(
            '${subscription.deliveryCity}, ${subscription.deliveryState} - ${subscription.deliveryPincode}',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone_rounded, size: 16, color: theme.hintColor),
              const SizedBox(width: 8),
              Text(
                subscription.deliveryPhone,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRecipientName() {
    if (_currentOrder != null && _currentOrder!.recipientName.isNotEmpty) {
      return _currentOrder!.recipientName;
    }

    final user = AuthService().currentUser;
    if (user != null) {
      final firstName = user.firstName;
      final lastName = user.lastName;
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
    }

    return 'Valued Customer';
  }
}
