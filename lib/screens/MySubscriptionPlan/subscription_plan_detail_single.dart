import 'package:flutter/material.dart';
import 'package:grocery_app/models/subscription_model.dart';
import 'package:grocery_app/services/subscription_service.dart';

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
                              '${widget.subscription.totalWeight} kg',
                            ),
                            _buildInfoRow(
                              'Total Amount',
                              '₹${widget.subscription.totalAmount}',
                            ),
                            _buildInfoRow(
                              'Next Delivery',
                              widget.subscription.nextDeliveryDate,
                            ),
                            // _buildInfoRow(
                            //   'Created On',
                            //   widget.subscription.createdAt,
                            // ),
                          ],
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
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.indigo[900],
            ),
          ),
        ],
      ),
    );
  }
}
