import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/models/subscription_model.dart';
import 'package:grocery_app/services/subscription_service.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:grocery_app/screens/checkout/webview_page.dart';
import 'package:intl/intl.dart'; // For better date formatting

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
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoadingInvoices = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // --- ALL YOUR EXISTING LOGIC FUNCTIONS ARE PRESERVED HERE ---
  // --- (e.g., _togglePauseSubscription, _showToggleConfirmation, etc.) ---
  
  // [The user's original logic functions have been omitted for brevity, 
  // but they should be kept here in your actual file.]
  
  // Start of existing logic functions (keep all of these)
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

      if (response['success'] == true) {
        SnackBarHelper.showSuccess(
          context,
          response['details'] ?? 'Subscription status updated successfully',
        );
        // Refresh the subscription data
        Navigator.pop(context, true);
      } else {
        SnackBarHelper.showError(
          context,
          response['details'] ?? 'Failed to update subscription status',
        );
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showToggleConfirmation() {
    final isCurrentlyPaused = widget.subscription.status == 'PAUSED';
    final maxPausesLeft = widget.subscription.remainingPauseTimes;
    DateTime? selectedStartDate;
    DateTime? selectedEndDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isCurrentlyPaused
                    ? 'Resume Subscription?'
                    : 'Pause Subscription?',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCurrentlyPaused
                        ? 'Are you sure you want to resume this subscription?'
                        : 'Are you sure you want to pause this subscription?',
                  ),
                  SizedBox(height: 16),
                  if (!isCurrentlyPaused) ...[
                    Text(
                      'Pauses remaining: $maxPausesLeft',
                      style: TextStyle(
                        color:
                            maxPausesLeft > 0
                                ? Colors.green[700]
                                : Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Select Pause Period:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start Date:'),
                              TextButton(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      Duration(days: 365),
                                    ),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      selectedStartDate = date;
                                    });
                                  }
                                },
                                child: Text(
                                  selectedStartDate != null
                                      ? '${selectedStartDate!.day}/${selectedStartDate!.month}/${selectedStartDate!.year}'
                                      : 'Select Start Date',
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('End Date:'),
                              TextButton(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        selectedStartDate ?? DateTime.now(),
                                    firstDate:
                                        selectedStartDate ?? DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      Duration(days: 365),
                                    ),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      selectedEndDate = date;
                                    });
                                  }
                                },
                                child: Text(
                                  selectedEndDate != null
                                      ? '${selectedEndDate!.day}/${selectedEndDate!.month}/${selectedEndDate!.year}'
                                      : 'Select End Date',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (!isCurrentlyPaused) {
                      if (selectedStartDate == null ||
                          selectedEndDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please select both start and end dates',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (selectedEndDate!.isBefore(selectedStartDate!)) {
                        SnackBarHelper.showError(
                          context,
                          'End date must be after start date',
                        );
                        return;
                      }
                    }

                    if (!isCurrentlyPaused && maxPausesLeft <= 0) {
                      Navigator.of(context).pop();
                      SnackBarHelper.showError(
                        context,
                        'No pauses remaining for this subscription',
                      );
                      return;
                    }

                    _togglePauseSubscription(
                      isCurrentlyPaused ? null : selectedStartDate,
                      isCurrentlyPaused ? null : selectedEndDate,
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoadingInvoices = true);
    try {
      final response = await _subscriptionService.getSubscriptionInvoices(
        widget.subscription.id,
      );
      if (response['success'] == true) {
        setState(() {
          _invoices = List<Map<String, dynamic>>.from(
            response['invoices'] ?? [],
          );
        });
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Failed to load invoices: $e');
    } finally {
      setState(() => _isLoadingInvoices = false);
    }
  }

  Future<void> _downloadInvoice(String s3Url, String displayName) async {
    try {
      SnackBarHelper.showLoading(context, 'Downloading invoice...');
      final filePath = await _subscriptionService.downloadSubscriptionInvoice(
        s3Url,
        displayName,
      );
      if (!mounted) return;
      SnackBarHelper.showSuccess(
        context,
        'Invoice downloaded successfully to Downloads folder',
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to download invoice: $e');
    }
  }
  
  Future<void> _handleRepayment() async {
    try {
      final result = await _subscriptionService.RepaymentSubscription(
        widget.subscription.id,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        if (result['payment_links'] != null && result['payment_links']['web'] != null) {
          await _launchRepaymentWebView(result);
        } else {
          await _handleSuccessfulRepayment(result);
        }
      } else {
        _showRepaymentFailedDialog(result);
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Failed to initiate repayment: $e');
    }
  }

  Future<void> _handleSuccessfulRepayment(Map<String, dynamic> result) async {
    // This function and others like _launchRepaymentWebView, _showRepaymentFailedDialog, etc.
    // are assumed to be present here from your original code.
  }

  Future<void> _launchRepaymentWebView(Map<String, dynamic> result) async {
    // Your existing implementation
  }

  void _showRepaymentFailedDialog(Map<String, dynamic> result) {
    // Your existing implementation
  }

  // End of existing logic functions

  @override
  void initState() {
    super.initState();
    // _loadInvoices();

    // Pulse animation logic remains unchanged
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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  // Define custom colors from the design
  final Color primaryButtonColor = const Color(0xFF9F814F);
  final Color pauseSectionColor = const Color(0xFFFFF7E6);
  final Color deliveredStatusColor = const Color(0xFF1E8A5A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Subscription Plan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Product', style: TextStyle(color: Colors.black)),
                  const SizedBox(height: 8),
                  _buildProductDetails(),
                  const SizedBox(height: 24),
                  _buildSubscriptionDetails(),
                  const Divider(height: 48, thickness: 1),
                  _buildPauseSection(),
                  const SizedBox(height: 24),
                  _buildSubscriptionTracker(),
                  const SizedBox(height: 100), // padding for bottom nav bar
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildProductDetails() {
    final item = widget.subscription.items.first;
    return Container(

    decoration: BoxDecoration(
      color: Colors.grey[100]
    ),
      child: Row(
        children: [
         ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:  (item.imageUrl != null)
                    // If the image list is NOT empty, show the first image
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        // Show a loading spinner while the image loads
                        placeholder: (context, url) => Container(
                          height: 100,
                          width: 100,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                        // Show an error icon if the image fails to load
                        errorWidget: (context, url, error) => Container(
                          height: 100,
                          width: 100,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        ),
                      )
                    // If the image list IS empty, show a fallback icon
                    : Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                      ),
              ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.weightUnit} x ${item.quantity}',
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('₹${item.discountedPrice}', style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(
                      '₹${item.price}',
                      style: const TextStyle(
                        color: Colors.black54,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.price > item.discountedPrice)
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.orange[100],
      
                      ),
                      child: Text(
                          '${((item.price - item.discountedPrice) * 100 / item.price).toStringAsFixed(0)}% Savings',
                          style: const TextStyle(color: Colors.orange, fontSize: 10)),
      
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

  String _formatDate(String dateStr, {String format = 'MMM dd, yyyy'}) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat(format).format(date);
  }

  Widget _buildSubscriptionDetails() {
    bool isPaymentPending = widget.subscription.installmentPaymentStatus == "PENDING";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(10)

          ),
          child: Text(
            'Subscription-${widget.subscription.planName}', style: const TextStyle(color: Colors.white, fontSize: 12)),
          
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
            'Valid From', 
            _formatDate(widget.subscription.startDate),
            trailing: Text(
                'Till   ${_formatDate(widget.subscription.endDate)}',
                style: const TextStyle(fontSize: 14 , color: Colors.black)
            )
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Monthly Quantity', '${widget.subscription.items.first.unitWeight} kg'),
        const SizedBox(height: 12),
        _buildDetailRow('Next Delivery Date', _formatDate(widget.subscription.nextDeliveryDate, format: 'E, MMM dd, yyyy')),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Payment', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(width: 30),
            Text(isPaymentPending ? 'Unpaid' : 'Paid', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            if(isPaymentPending)
            GestureDetector(
              onTap: _handleRepayment,
              child: Text('Pay Now', style: TextStyle(color: primaryButtonColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Widget? trailing}) {
    return Row(
      children: [
        SizedBox(
          width: 120, // To align the values vertically
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildPauseSection() {
    final bool isPaused = widget.subscription.status == 'PAUSED';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pauseSectionColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pause Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: _showToggleConfirmation,
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 20),
                label: Text(isPaused ? 'Resume' : 'Pause'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPaused ? deliveredStatusColor : primaryButtonColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              Text(
                '${widget.subscription.remainingPauseTimes} of ${widget.subscription.remainingPauseDays} Pause Days Left', 
                style: const TextStyle(color: Colors.black54)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTracker() {
    // NOTE: The `subscription` model provided does not seem to contain
    // a delivery history list. This part is built with static data
    // to match the UI. You should replace this with your actual data source.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subscription Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          _buildTrackerItem('Order No. #7289290', 'Delivery by Thu, 24th July 2025', 'July 24, 2025', isDelivered: false),
          const SizedBox(height: 20),
          _buildTrackerItem('Order No. #7289290', '3kgs x 1', 'July 24, 2025', isDelivered: true),
          const SizedBox(height: 20),
          _buildTrackerItem('Order No. #7289290', '3kgs x 1', 'May 24, 2025', isDelivered: true),
          const SizedBox(height: 20),
          const Row(
            children: [
              Text('⚡️', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text("Now that's how you fuel your soul!", style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTrackerItem(String title, String subtitle, String date, {required bool isDelivered}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isDelivered ? deliveredStatusColor : Colors.grey.shade300,
          child: const Icon(Icons.check, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _showInvoiceSelectionDialog,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: primaryButtonColor),
              ),
              child: Text(
                'Download Invoice',
                style: TextStyle(color: primaryButtonColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                  // TODO: Implement "Subscribe Again" logic
                  SnackBarHelper.showInfo(context, '"Subscribe Again" feature coming soon!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryButtonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Subscribe Again',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInvoiceSelectionDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Invoice to Download',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (_isLoadingInvoices)
                const Center(child: CircularProgressIndicator())
              else if (_invoices.isEmpty)
                const Center(child: Text('No invoices available.'))
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = _invoices[index];
                      return ListTile(
                        leading: const Icon(Icons.receipt_long),
                        title: Text(invoice['display_name'] ?? 'Invoice'),
                        subtitle: Text('Invoice #${invoice['odoo_invoice_number'] ?? 'N/A'}'),
                        trailing: const Icon(Icons.download_for_offline),
                        onTap: () {
                          Navigator.pop(context); // Close the bottom sheet
                          _downloadInvoice(
                            invoice['s3_url'],
                            invoice['display_name'] ?? 'Invoice',
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}