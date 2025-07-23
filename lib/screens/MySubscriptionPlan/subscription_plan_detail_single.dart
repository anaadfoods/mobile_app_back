import 'package:flutter/material.dart';
import 'package:grocery_app/models/subscription_model.dart';
import 'package:grocery_app/services/subscription_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:grocery_app/services/auth_service.dart';

class SubscriptionPlanDetailScreen extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionPlanDetailScreen({super.key, required this.subscription});

  @override
  State<SubscriptionPlanDetailScreen> createState() =>
      _SubscriptionPlanDetailScreenState();
}

class _SubscriptionPlanDetailScreenState
    extends State<SubscriptionPlanDetailScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['details'] ?? 'Subscription status updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the subscription data
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['details'] ?? 'Failed to update subscription status',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('End date must be after start date'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    if (!isCurrentlyPaused && maxPausesLeft <= 0) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'No pauses remaining for this subscription',
                          ),
                          backgroundColor: Colors.red,
                        ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Subscription cancelled successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the subscription data
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Failed to cancel subscription',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
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
          IconButton(
            icon: Icon(Icons.download),
            tooltip: 'Download Invoice',
            onPressed: () async {
              final url =
                  'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
              final response = await http.get(Uri.parse(url));
              final dir = await getTemporaryDirectory();
              final file = File(
                '${dir.path}/subscription_invoice_${widget.subscription.id}.pdf',
              );
              await file.writeAsBytes(response.bodyBytes);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invoice downloaded to ${file.path}')),
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Receipt downloaded to ${file.path}',
                                    ),
                                  ),
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Could not open WhatsApp')));
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
