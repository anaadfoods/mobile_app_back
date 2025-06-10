import 'package:flutter/material.dart';
import 'package:grocery_app/styles/colors.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import 'FillImageWithColor.dart';
import '../screens/MySubscriptionPlan/subscription_plan_detail_single.dart';

class SubscriptionCard extends StatelessWidget {
  final String productName;
  final String planName;
  final int quantity;
  final DateTime nextDeliveryDate;
  final int deliveriesLeft;
  final int totalDeliveries;
  final bool isPaused;
  final VoidCallback onViewDetails;
  final VoidCallback onTogglePause;
  final int completedDeliveries;

  const SubscriptionCard({
    super.key,
    required this.productName,
    required this.planName,
    required this.quantity,
    required this.nextDeliveryDate,
    required this.deliveriesLeft,
    required this.totalDeliveries,
    required this.isPaused,
    required this.onViewDetails,
    required this.onTogglePause,
    required this.completedDeliveries,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(
              '$productName - $planName',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 8),

            // Info Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        quantity.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[900],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Next Delivery',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        '${nextDeliveryDate.day} - ${_getMonthName(nextDeliveryDate.month)} - ${nextDeliveryDate.year}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.indigo[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Divider(color: Colors.grey[300], thickness: 1),
            SizedBox(height: 8),

            // Actions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onViewDetails,
                    child: Text(
                      'View Details',
                      style: TextStyle(color: Colors.indigo[900]),
                    ),
                  ),
                ),
                Container(height: 24, width: 1, color: Colors.grey[300]),
                IconButton(
                  icon: Column(
                    children: [
                      Icon(
                        isPaused
                            ? Icons.play_circle_fill
                            : Icons.pause_circle_filled,
                      ),
                      Text(isPaused ? "play" : "pause"),
                    ],
                  ),
                  onPressed: onTogglePause,
                ),
                Container(height: 24, width: 1, color: Colors.grey[300]),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Column(
                      children: [
                        GestureDetector(
                          onLongPress: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text('Delivery Info'),
                                    content: Text(
                                      '$deliveriesLeft deliveries left out of $totalDeliveries',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        child: Text('OK'),
                                      ),
                                    ],
                                  ),
                            );
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onHover: (event) {
                              final dynamic tooltip = Tooltip(
                                message:
                                    '$deliveriesLeft deliveries left out of $totalDeliveries',
                                child: SizedBox.shrink(),
                              );
                            },
                            child: FillImageWithColor(
                              imageUrl: 'assets/images/delivery_box.svg',
                              fillColor: AppColors.primaryColor,
                              baseColor: const Color.fromARGB(
                                255,
                                209,
                                182,
                                182,
                              ),
                              percentage:
                                  (((completedDeliveries) / totalDeliveries) *
                                          100)
                                      .clamp(0, 100)
                                      .toInt(),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${completedDeliveries} Deliveries',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.indigo[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  String _getMonthName(int month) {
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
    return months[month - 1];
  }
}

class SubscriptionCarousel extends StatefulWidget {
  const SubscriptionCarousel({super.key});

  @override
  State<SubscriptionCarousel> createState() => _SubscriptionCarouselState();
}

class _SubscriptionCarouselState extends State<SubscriptionCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<Subscription> _subscriptions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    try {
      final response = await _subscriptionService.getSubscriptions();
      if (response['success'] == true && response['data'] != null) {
        final allSubscriptions = response['data'] as List<Subscription>;
        setState(() {
          _subscriptions =
              allSubscriptions.where((sub) => sub.status == 'ACTIVE').toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load subscriptions';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePauseSubscription(
    Subscription subscription,
    DateTime pauseStartDate,
    DateTime pauseEndDate,
  ) async {
    try {
      final response = await _subscriptionService.togglePauseSubscription(
        subscription.id,
        pauseStartDate,
        pauseEndDate,
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Subscription paused successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        await _loadSubscriptions(); // Reload subscriptions after toggle
      } else {
        print(response);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['detail'] ??
                  response['message'] ??
                  'Failed to toggle pause',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle pause: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showToggleConfirmation(
    BuildContext context,
    Subscription subscription,
  ) {
    final isCurrentlyPaused = subscription.status == 'PAUSED';
    final maxPausesLeft = subscription.remainingPauseTimes;
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
                        ? 'Are you sure you want to resume the ${subscription.items.first.productName} subscription?'
                        : 'Are you sure you want to pause the ${subscription.items.first.productName} subscription?',
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
                      subscription,
                      selectedStartDate ?? DateTime.now(),
                      selectedEndDate ?? DateTime.now().add(Duration(days: 1)),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(""),
            // Text('Error: $_error'),
            // ElevatedButton(onPressed: _loadSubscriptions, child: Text('Retry')),
          ],
        ),
      );
    }

    if (_subscriptions.isEmpty) {
      return Center(child: Text(""));
    }

    return Column(
      children: [
        const Text(
          "Active Subscription",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        SizedBox(
          height: 280,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _subscriptions.length,
                itemBuilder: (context, index) {
                  final subscription = _subscriptions[index];
                  final item = subscription.items.first;
                  return SubscriptionCard(
                    productName: item.productName,
                    planName: subscription.planName,
                    quantity: item.quantity,
                    nextDeliveryDate: DateTime.parse(
                      subscription.nextDeliveryDate,
                    ),
                    totalDeliveries: subscription.totalDeliveries,
                    deliveriesLeft:
                        (DateTime.parse(
                                  subscription.endDate,
                                ).difference(DateTime.now()).inDays /
                                30)
                            .ceil(),
                    isPaused: subscription.status == 'PAUSED',
                    onViewDetails: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SubscriptionPlanDetailScreen(
                                subscription: subscription,
                              ),
                        ),
                      );
                    },
                    onTogglePause:
                        () => _showToggleConfirmation(context, subscription),
                    completedDeliveries:
                        (DateTime.parse(
                                  subscription.endDate,
                                ).difference(DateTime.now()).inDays /
                                30)
                            .ceil(),
                  );
                },
              ),
              // Navigation Arrows
              Positioned(
                left: 0,
                top: 0,

                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      size: 32,
                      color: Colors.indigo[900],
                    ),
                    onPressed: () {
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      size: 32,
                      color: Colors.indigo[900],
                    ),
                    onPressed: () {
                      if (_currentPage < _subscriptions.length - 1) {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _subscriptions.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _currentPage == index
                        ? Colors.indigo[900]
                        : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSubscriptionDetails(
    BuildContext context,
    Subscription subscription,
  ) {
    final item = subscription.items.first;
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Subscription Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[900],
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.shopping_basket, color: Colors.indigo),
                title: Text('Product'),
                subtitle: Text(item.productName),
              ),
              ListTile(
                leading: Icon(Icons.card_membership, color: Colors.indigo),
                title: Text('Plan'),
                subtitle: Text(subscription.planName),
              ),
              ListTile(
                leading: Icon(Icons.calendar_today, color: Colors.indigo),
                title: Text('Next Delivery'),
                subtitle: Text(subscription.nextDeliveryDate),
              ),
              ListTile(
                leading: Icon(Icons.local_shipping, color: Colors.indigo),
                title: Text('Deliveries Left'),
                subtitle: Text(
                  (subscription.endDate.difference(DateTime.now()).inDays / 30)
                      .ceil()
                      .toString(),
                ),
              ),
              ListTile(
                leading: Icon(Icons.location_on, color: Colors.indigo),
                title: Text('Delivery Address'),
                subtitle: Text(
                  '${subscription.deliveryAddress}, ${subscription.deliveryCity}, ${subscription.deliveryState} - ${subscription.deliveryPincode}',
                ),
              ),
              ListTile(
                leading: Icon(Icons.phone, color: Colors.indigo),
                title: Text('Contact Number'),
                subtitle: Text(subscription.deliveryPhone),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

extension on String {
  difference(DateTime dateTime) {}
}
