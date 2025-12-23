import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/common_widgets/global_import.dart' as http;

class SubscriptionPlanDetailScreen extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionPlanDetailScreen({super.key, required this.subscription});

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
  late Subscription _currentOrder; // Assuming Order is part of your model
  List<TextDto> orderList = [];
  List<TextDto> shippedList = [];
  List<TextDto> outOfDeliveryList = [];
  List<TextDto> deliveredList = [];

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.subscription; // Placeholder, adjust as needed
    _loadInvoices();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.subscription.installmentPaymentStatus == "PENDING") {
      _pulseController.repeat(reverse: true);
    }
    // _setupOrderStatusSteps();
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
    try {
      final response = await _subscriptionService.getSubscriptionInvoices(
        widget.subscription.id,
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
    SnackBarHelper.showInfo(context, 'Downloading ${invoice.displayName}...');
    try {
      final response = await http.get(Uri.parse(invoice.s3Url));
      if (response.statusCode == 200) {
        Directory? downloadsDir;
        if (Platform.isAndroid) {
          downloadsDir = Directory('/storage/emulated/0/Download');
        } else {
          downloadsDir = await getApplicationDocumentsDirectory();
        }
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        final filePath = '${downloadsDir.path}/${invoice.displayName}.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        SnackBarHelper.showSuccess(
          context,
          'Invoice saved to Downloads folder!',
        );
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done) {
          SnackBarHelper.showError(
            context,
            'Could not open file: ${result.message}.',
          );
        }
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Error downloading invoice: $e');
    }
  }

  Future<void> _togglePauseSubscription(
    Subscription subscription,
    DateTime? pauseStartDate,
    DateTime? pauseEndDate,
  ) async {
    try {
      final response = await _subscriptionService.togglePauseSubscription(
        subscription.id,
        pauseStartDate,
        pauseEndDate,
      );
      if (!mounted) return;
      if (response['success'] == true) {
        SnackBarHelper.showSuccess(
          context,
          response['message'] ?? 'Subscription paused successfully',
        );
      } else {
        SnackBarHelper.showError(
          context,
          response['detail'] ?? response['message'] ?? 'Failed to toggle pause',
        );
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to toggle pause: $e');
    }
  }

  void _showToggleConfirmation(Subscription subscription) {
    // The logic is unchanged, but the dialogs will use the app's theme.
    final isCurrentlyPaused = subscription.status == 'PAUSED';
    final maxPausesLeft = subscription.remainingPauseTimes;
    DateTime? selectedStartDate;
    DateTime? selectedEndDate;
    DateTime? selectedNextDeliveryDate;

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
                    _togglePauseSubscription(
                      subscription,
                      selectedStartDate,
                      selectedEndDate,
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
      builder: (BuildContext context) {
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
                          Navigator.pop(context);
                          _togglePauseSubscription(
                            subscription,
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
        onTap: onTap as void Function()?,
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

  // Future<void> _togglePauseSubscription(DateTime? startDate, DateTime? endDate) async {
  //   // This logic is preserved
  // }

  // void _showToggleConfirmation() {
  //   // This logic is preserved
  // }

  // Future<void> _handleRepayment() async {
  //   await SubscriptionHandler().processUPIRepayment(context, widget.subscription.id);
  // }

  // void _setupOrderStatusSteps() {
  //   // This logic is preserved
  // }

  String _formatDate(String dateStr, {String format = 'MMM dd, yyyy'}) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat(format).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Subscription Details'), elevation: 0),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppColors.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppColors.spacingS),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppColors.radiusS,
                            ),
                          ),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppColors.spacingM),
                        Text(
                          'Product',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppColors.spacingM),
                    _buildProductDetails(),
                    const SizedBox(height: AppColors.spacingXL),
                    _buildSubscriptionDetails(),
                    Divider(
                      height: AppColors.spacingXXL * 1.5,
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    ),
                    _buildPauseSection(),
                    const SizedBox(height: AppColors.spacingXL),
                    InvoiceTrackerWidget(
                      isLoading: _isLoadingInvoices,
                      error: _invoiceError,
                      invoices: _invoices,
                      onInvoiceTap: (invoice) {
                        _downloadAndOpenInvoice(invoice);
                      },
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
      bottomNavigationBar: _buildBottomButtons(widget.subscription),
    );
  }

  Widget _buildProductDetails() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;
    final item = widget.subscription.items.first;

    return Container(
      padding: const EdgeInsets.all(AppColors.spacingL),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppColors.radiusL),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(AppColors.shadowOpacityLight),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.radiusM),
            child:
                (item.imageUrl != null)
                    ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
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
                        borderRadius: BorderRadius.circular(AppColors.radiusM),
                      ),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: theme.disabledColor,
                        size: 32,
                      ),
                    ),
          ),
          const SizedBox(width: AppColors.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppColors.spacingXS),
                Text(
                  '${item.weightUnit} x ${item.quantity}',
                  style: textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: AppColors.spacingS),
                Row(
                  children: [
                    Text(
                      '₹${item.discountedPrice.toStringAsFixed(0)}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppColors.spacingS),
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: textTheme.bodyMedium?.copyWith(
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
    );
  }

  Widget _buildSubscriptionDetails() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    bool isPaymentPending =
        widget.subscription.installmentPaymentStatus == "PENDING";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Subscription-${widget.subscription.planName}',
            style: textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          "Valid From",
          _formatDate(widget.subscription.startDate),
          trailing: Text(
            'Till ${_formatDate(widget.subscription.endDate)}',
            style: textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Monthly Quantity',
          '${widget.subscription.items.first.unitWeight} kg',
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Next Delivery Date',
          _formatDate(
            widget.subscription.nextDeliveryDate,
            format: 'E, MMM dd, yyyy',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Payment',
              style: textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(width: 30),
            Text(
              isPaymentPending ? 'Unpaid' : 'Paid',
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (isPaymentPending)
              GestureDetector(
                onTap: () async {
                  final handler = SubscriptionHandler(context);
                  await handler.processUPIRepayment(widget.subscription.id);
                },
                child: Text(
                  'Pay Now',
                  style: textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Widget? trailing}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildPauseSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;
    final bool isPaused = widget.subscription.status == 'PAUSED';

    return Container(
      padding: const EdgeInsets.all(AppColors.spacingL),
      decoration: BoxDecoration(
        color:
            isPaused
                ? AppColors.warning.withOpacity(0.1)
                : theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppColors.radiusL),
        border: Border.all(
          color:
              isPaused
                  ? AppColors.warning.withOpacity(0.3)
                  : theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppColors.spacingS),
                decoration: BoxDecoration(
                  color:
                      isPaused
                          ? AppColors.warning.withOpacity(0.2)
                          : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppColors.radiusS),
                ),
                child: Icon(
                  isPaused ? Icons.pause_circle_outline : Icons.schedule,
                  color:
                      isPaused ? AppColors.warning : theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppColors.spacingM),
              Text(
                isPaused ? 'Subscription Paused' : 'Pause Subscription',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showToggleConfirmation(widget.subscription),
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 20),
                label: Text(isPaused ? 'Resume' : 'Pause'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isPaused ? AppColors.success : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppColors.spacingL,
                    vertical: AppColors.spacingM,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppColors.spacingM,
                  vertical: AppColors.spacingS,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AppColors.radiusRound),
                ),
                child: Text(
                  '${widget.subscription.remainingPauseTimes} of ${widget.subscription.remainingPauseDays} Pauses Left',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ALL OTHER CODE IN THE FILE REMAINS THE SAME ---

  Widget _buildBottomButtons(Subscription subscription) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppColors.spacingL),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(AppColors.shadowOpacityLight),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoadingInvoices ? null : _loadInvoices,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppColors.spacingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusM),
                  ),
                  side: BorderSide(color: colorScheme.primary),
                  foregroundColor: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: AppColors.spacingL),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final product = await CategoryService.fetchProductById(
                    subscription.items.first.productVariant,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (builder) => AddressSelectionScreen(
                            isSubscription: true,
                            price: subscription.items.first.discountedPrice,
                            selectedPlan: subscription.plan,
                            quantity: subscription.items.first.quantity,
                            singleProduct: product,
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppColors.spacingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusM),
                  ),
                ),
                child: Text(
                  'Subscribe Again',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
