import 'package:flutter/material.dart';
import 'package:grocery_app/models/subscription_model.dart';
import 'package:grocery_app/services/subscription_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:grocery_app/screens/checkout/webview_page.dart';

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

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Subscription?'),
          content: Text(
            'Are you sure you want to cancel this subscription? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('No, Keep It'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _cancelSubscription();
              },
              child: Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelSubscription() async {
    setState(() => _isLoading = true);
    try {
      final response = await _subscriptionService.cancelSubscription(
        widget.subscription.id,
      );

      if (response['success'] == true) {
        SnackBarHelper.showSuccess(
          context,
          response['message'] ?? 'Subscription cancelled successfully',
        );
        // Refresh the subscription data
        Navigator.pop(context, true);
      } else {
        SnackBarHelper.showError(
          context,
          response['message'] ?? 'Failed to cancel subscription',
        );
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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

      print("Repayment subscription response: $result");

      if (!mounted) return;

      if (result['success'] == true) {
        print("Success is true, checking payment_links...");
        print("payment_links: ${result['payment_links']}");
        print("payment_links type: ${result['payment_links']?.runtimeType}");

        if (result['payment_links'] != null) {
          print("payment_links is not null");
          print("payment_links['web']: ${result['payment_links']['web']}");
          print(
            "payment_links['web'] type: ${result['payment_links']['web']?.runtimeType}",
          );

          if (result['payment_links']['web'] != null) {
            print("Payment links found, launching WebView...");
            print("Payment URL: ${result['payment_links']['web']}");
            // Launch WebView for UPI payment
            await _launchRepaymentWebView(result);
          } else {
            // No payment required, or payment_links missing, treat as success
            await _handleSuccessfulRepayment(result);
          }
        } else {
          // No payment required, or payment_links missing, treat as success
          await _handleSuccessfulRepayment(result);
        }
      } else {
        // Show the failed dialog
        _showRepaymentFailedDialog(result);
      }
    } catch (e) {
      print('Error in _handleRepayment: $e');
      SnackBarHelper.showError(context, 'Failed to initiate repayment: $e');
    }
  }

  Future<void> _handleSuccessfulRepayment(Map<String, dynamic> result) async {
    try {
      // Fetch subscription details using subscription_id
      if (result['subscription_id'] != null) {
        final subscriptionDetails = await _subscriptionService
            .getSubscriptionDetails(
              int.parse(result['subscription_id'].toString()),
            );

        if (subscriptionDetails['success'] == true && mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SubscriptionPlanDetailScreen(
                    subscription: subscriptionDetails['data'],
                  ),
            ),
            (route) => route.isFirst,
          );
        } else {
          // If fetching details fails, show success message
          _showRepaymentSuccessMessage(result);
        }
      } else {
        _showRepaymentSuccessMessage(result);
      }
    } catch (e) {
      print('Error fetching subscription details: $e');
      _showRepaymentSuccessMessage(result);
    }
  }

  Future<void> _launchRepaymentWebView(Map<String, dynamic> result) async {
    print("=== _launchRepaymentWebView called ===");
    print("Result: $result");

    try {
      final paymentUrl = result['payment_links']['web'];
      final subscriptionId = result['subscription_id'];

      print("Payment URL: $paymentUrl");
      print("Subscription ID: $subscriptionId");

      if (subscriptionId == null) {
        throw Exception('Subscription ID is null');
      }

      // Parse subscription ID to int
      int parsedSubscriptionId;
      try {
        parsedSubscriptionId = int.parse(subscriptionId.toString());
      } catch (e) {
        throw Exception('Invalid subscription ID format: $subscriptionId');
      }

      if (!mounted) {
        print("Widget not mounted, cannot navigate");
        return;
      }

      print("About to navigate to WebView...");

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => WebViewPage(
                url: paymentUrl,
                orderId: parsedSubscriptionId,
                title: 'UPI Payment',
                subID: parsedSubscriptionId,
                isSubscription: true,
                onPaymentSuccess: (url) async {
                  print("Payment success callback triggered");
                  // Fetch subscription details after successful payment
                  try {
                    final subscriptionDetails = await _subscriptionService
                        .getSubscriptionDetails(parsedSubscriptionId);

                    if (subscriptionDetails['success'] == true && mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SubscriptionPlanDetailScreen(
                                subscription: subscriptionDetails['data'],
                              ),
                        ),
                        (route) => route.isFirst,
                      );
                    } else {
                      // If fetching details fails, show success message
                      Navigator.pop(context);
                      _showRepaymentSuccessMessage(result);
                    }
                  } catch (e) {
                    print(
                      'Error fetching subscription details after payment: $e',
                    );
                    Navigator.pop(context);
                    _showRepaymentSuccessMessage(result);
                  }
                },
                onPaymentFailure: (url) {
                  print("Payment failure callback triggered");
                  Navigator.pop(context);
                  SnackBarHelper.showError(
                    context,
                    'Payment failed or cancelled',
                  );
                },
              ),
        ),
      );

      print("Navigation to WebView completed");
    } catch (e) {
      print("Error in _launchRepaymentWebView: $e");
      SnackBarHelper.showError(context, 'Failed to launch payment page: $e');
    }
  }

  void _showRepaymentSuccessMessage(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Repayment Successful'),
            content: Text(
              'Your subscription repayment has been processed successfully!',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showRepaymentFailedDialog(Map<String, dynamic> result) {
    String errorMessage = _parseServerError(
      result['message'] ?? result['errors'] ?? 'Failed to process repayment',
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Repayment Failed'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Go Back'),
              ),
            ],
          ),
    );
  }

  String _parseServerError(dynamic error) {
    if (error is String) {
      return error;
    }

    if (error is Map<String, dynamic>) {
      if (error.containsKey('items') && error['items'] is List) {
        List<String> itemErrors = [];
        for (var item in error['items']) {
          if (item is Map<String, dynamic>) {
            item.forEach((key, value) {
              if (value is List) {
                itemErrors.addAll(value.map((e) => e.toString()));
              } else if (value is String) {
                itemErrors.add(value);
              }
            });
          }
        }
        if (itemErrors.isNotEmpty) {
          return itemErrors.join('\n');
        }
      }

      if (error.containsKey('message')) {
        return error['message'];
      }

      if (error.containsKey('errors')) {
        var errors = error['errors'];
        if (errors is Map<String, dynamic>) {
          List<String> errorMessages = [];
          errors.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.map((e) => e.toString()));
            } else if (value is String) {
              errorMessages.add(value);
            }
          });
          return errorMessages.join('\n');
        } else if (errors is String) {
          return errors;
        }
      }
    }

    return error.toString();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadInvoices();

    // Initialize pulse animation for repayment button
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start pulse animation if payment is pending
    if (widget.subscription.installmentPaymentStatus == "PENDING") {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaused = widget.subscription.status == 'PAUSED';
    final isCancelled = widget.subscription.status == 'CANCELLED';

    // Dummy data for demonstration
    final List<Map<String, String>> deliveryHistory = [
      {"date": "2024-06-01", "status": "Done"},
      {"date": "2024-05-25", "status": "Done"},
      {"date": "2024-05-18", "status": "Done"},
      {"date": "2024-05-11", "status": "Done"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription Plan Details'),
        actions: [
          if (!isCancelled) ...[
            // Pause/Resume button
            IconButton(
              icon: Icon(
                isPaused ? Icons.play_circle_fill : Icons.pause_circle_filled,
                color: isPaused ? Colors.green : Colors.orange,
              ),
              onPressed: _isLoading ? null : _showToggleConfirmation,
            ),
            // Cancel button
            IconButton(
              icon: Icon(Icons.cancel, color: Colors.red),
              onPressed: _isLoading ? null : _showCancelConfirmation,
            ),
          ],
          // Repayment button for pending payments
          if (widget.subscription.installmentPaymentStatus == "PENDING")
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.payment, color: Colors.white, size: 24),
                      tooltip: 'Repayment Required',
                      onPressed: _isLoading ? null : () => _handleRepayment(),
                    ),
                  ),
                );
              },
            ),
         
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plan Status Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.subscription.planName,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo[900],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isPaused
                                            ? Colors.orange[100]
                                            : Colors.green[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.subscription.status,
                                    style: TextStyle(
                                      color:
                                          isPaused
                                              ? Colors.orange[900]
                                              : Colors.green[900],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            _buildInfoRow(
                              'Total Weight',
                              '${widget.subscription.items.map((item) => item.unitWeight).reduce((a, b) => a + b)} kg',
                            ),
                            _buildInfoRow(
                              'Delivery Charges',
                              '₹${widget.subscription.deliveryCharges}',
                            ),
                            _buildInfoRow(
                              'Total Amount',
                              '₹${widget.subscription.total}',
                            ),
                            _buildInfoRow(
                              'Remaining Amount',
                              '₹${widget.subscription.remainingAmount}',
                            ),

                            _buildInfoRow(
                              'Next Delivery',
                              _formatDate(widget.subscription.nextDeliveryDate),
                            ),
                            _buildInfoRow(
                              'Amount Paid',
                              '₹${widget.subscription.amountPaid}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[900],
                      ),
                    ),
                    SizedBox(height: 8),
                    ...widget.subscription.items.map(
                      (item) => Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                  size: 32,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      ' ${item.weightUnit}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Qty: ${item.quantity}',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        if (item.price >
                                            item.discountedPrice) ...[
                                          SizedBox(width: 6),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green[50],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Save ₹${(item.price - item.discountedPrice).toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${item.discountedPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Total: ₹${(item.discountedPrice * item.quantity).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Delivery Details Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[900],
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildInfoRow(
                              'Address',
                              widget.subscription.deliveryAddress,
                            ),
                            _buildInfoRow(
                              'City',
                              widget.subscription.deliveryCity,
                            ),
                            _buildInfoRow(
                              'State',
                              widget.subscription.deliveryState,
                            ),
                            _buildInfoRow(
                              'Pincode',
                              widget.subscription.deliveryPincode,
                            ),
                            _buildInfoRow(
                              'Phone',
                              widget.subscription.deliveryPhone,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Additional Details Card
                    if (widget.subscription.notes != null &&
                        widget.subscription.notes!.isNotEmpty)
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Additional Notes',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo[900],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.subscription.notes!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (widget.subscription.status == 'CANCELLED')
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Subscription cancelled'),
                        ),
                      ),
                    SizedBox(height: 16),

                    // Repayment Alert Section
                    if (widget.subscription.installmentPaymentStatus ==
                        "PENDING")
                      Card(
                        elevation: 6,
                        color: Colors.red[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.red[300]!, width: 2),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Payment Required',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red[800],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Your subscription payment is pending. Please complete the payment to continue your subscription.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.red[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () => _handleRepayment(),
                                  icon: Icon(
                                    Icons.payment,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'Pay Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Invoices Section
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Invoices',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo[900],
                                  ),
                                ),
                                if (_isLoadingInvoices)
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 16),
                            if (_invoices.isEmpty && !_isLoadingInvoices)
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'No invoices available',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ..._invoices
                                  .map(
                                    (invoice) => Card(
                                      margin: EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.receipt,
                                          color: Colors.indigo,
                                          size: 32,
                                        ),
                                        title: Text(
                                          invoice['display_name'] ?? 'Invoice',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Invoice #${invoice['odoo_invoice_number'] ?? 'N/A'}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(
                                            Icons.download,
                                            color: Colors.green,
                                          ),
                                          tooltip: 'Download Invoice',
                                          onPressed:
                                              () => _downloadInvoice(
                                                invoice['s3_url'],
                                                invoice['display_name'] ??
                                                    'Invoice',
                                              ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    /*
                    Text(
                      'Delivery History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[900],
                      ),
                    ),
                    SizedBox(height: 8),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: deliveryHistory.length,
                        separatorBuilder: (context, idx) => Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final entry = deliveryHistory[idx];
                          return ListTile(
                            leading: Icon(
                              Icons.calendar_today,
                              color: Colors.blueGrey,
                              size: 28,
                            ),
                            title: Text(
                              entry["date"]!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              entry["status"]!,
                              style: TextStyle(
                                color:
                                    entry["status"] == "Done"
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.download, color: Colors.indigo),
                              tooltip: 'Download Receipt',
                              onPressed: () async {
                                final url =
                                    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
                                final response = await http.get(Uri.parse(url));
                                final dir = await getTemporaryDirectory();
                                final file = File(
                                  '${dir.path}/delivery_${entry["date"]}.pdf',
                                );
                                await file.writeAsBytes(response.bodyBytes);
                                if (!mounted) return;
                                SnackBarHelper.showSuccess(
                                  context,
                                  'Receipt downloaded to Downloads folder',
                                );
                              },
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          );
                        },
                      ),
                    ),
                    */
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: Icon(Icons.message),
        onPressed: () async {
          final user = await AuthService().currentUser;
          final phone = '917014234352'; // Replace with your WhatsApp number
          final message = Uri.encodeComponent(
            'Subscription Support Request\n' +
                'User: ${user?.firstName ?? ''} ${user?.lastName ?? ''}\n' +
                'Phone: ${user?.phoneNumber ?? ''}\n' +
                'Subscription ID: ${widget.subscription.id}\n' +
                'Plan: ${widget.subscription.planName}\n' +
                'Status: ${widget.subscription.status}\n' +
                'Total Amount: ${widget.subscription.total}',
          );
          final uri = Uri.parse('https://wa.me/$phone?text=$message');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            SnackBarHelper.showError(context, 'Could not open WhatsApp');
          }
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label : ',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.indigo[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
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
    return '${date.day}-${months[date.month - 1]}-${date.year}';
  }
}
