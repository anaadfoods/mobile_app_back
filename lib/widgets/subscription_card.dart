import 'package:flutter/material.dart';

class SubscriptionCard extends StatelessWidget {
  final String productName;
  final String planName;
  final int quantity;
  final DateTime nextDeliveryDate;
  final int deliveriesLeft;
  final bool isPaused;
  final VoidCallback onViewDetails;
  final VoidCallback onTogglePause;

  const SubscriptionCard({
    super.key,
    required this.productName,
    required this.planName,
    required this.quantity,
    required this.nextDeliveryDate,
    required this.deliveriesLeft,
    required this.isPaused,
    required this.onViewDetails,
    required this.onTogglePause,
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
                fontSize: 20,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                    crossAxisAlignment: CrossAxisAlignment.end,
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
                        Text(
                          deliveriesLeft.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[900],
                          ),
                        ),
                        Text(
                          'Deliveries Left',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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

  final List<Map<String, dynamic>> subscriptions = [
    {
      'productName': 'Organic Fruits',
      'planName': 'Premium Plan',
      'quantity': 5,
      'nextDeliveryDate': DateTime(2025, 8, 1),
      'deliveriesLeft': 3,
      'isPaused': false,
      'maxPausesLeft': 2,
      'pauseStartDate': null,
      'pauseEndDate': null,
    },
    {
      'productName': 'Fresh Vegetables',
      'planName': 'Basic Plan',
      'quantity': 3,
      'nextDeliveryDate': DateTime(2025, 8, 5),
      'deliveriesLeft': 5,
      'isPaused': true,
      'maxPausesLeft': 1,
      'pauseStartDate': DateTime(2025, 7, 25),
      'pauseEndDate': DateTime(2025, 8, 25),
    },
    {
      'productName': 'Mixed Basket',
      'planName': 'Family Plan',
      'quantity': 8,
      'nextDeliveryDate': DateTime(2025, 8, 10),
      'deliveriesLeft': 2,
      'isPaused': false,
      'maxPausesLeft': 3,
      'pauseStartDate': null,
      'pauseEndDate': null,
    },
    {
      'productName': 'Seasonal Fruits',
      'planName': 'Summer Special',
      'quantity': 6,
      'nextDeliveryDate': DateTime(2025, 8, 15),
      'deliveriesLeft': 4,
      'isPaused': false,
      'maxPausesLeft': 2,
      'pauseStartDate': null,
      'pauseEndDate': null,
    },
    {
      'productName': 'Organic Greens',
      'planName': 'Weekly Plan',
      'quantity': 4,
      'nextDeliveryDate': DateTime(2025, 8, 20),
      'deliveriesLeft': 6,
      'isPaused': true,
      'maxPausesLeft': 0,
      'pauseStartDate': DateTime(2025, 7, 20),
      'pauseEndDate': DateTime(2025, 8, 20),
    },
    {
      'productName': 'Exotic Fruits',
      'planName': 'Premium Plus',
      'quantity': 7,
      'nextDeliveryDate': DateTime(2025, 8, 25),
      'deliveriesLeft': 1,
      'isPaused': false,
      'maxPausesLeft': 1,
      'pauseStartDate': null,
      'pauseEndDate': null,
    },
    {
      'productName': 'Local Produce',
      'planName': 'Community Plan',
      'quantity': 5,
      'nextDeliveryDate': DateTime(2025, 8, 30),
      'deliveriesLeft': 8,
      'isPaused': false,
      'maxPausesLeft': 2,
      'pauseStartDate': null,
      'pauseEndDate': null,
    },
  ];

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} days';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hours';
    } else {
      return '${duration.inMinutes} minutes';
    }
  }

  void _showToggleConfirmation(BuildContext context, int index) {
    final subscription = subscriptions[index];
    final isCurrentlyPaused = subscription['isPaused'] ?? false;
    final maxPausesLeft = subscription['maxPausesLeft'] ?? 0;

    String timeRemaining = '';
    if (isCurrentlyPaused && subscription['pauseEndDate'] != null) {
      final now = DateTime.now();
      final endDate = subscription['pauseEndDate'] as DateTime;
      if (endDate.isAfter(now)) {
        timeRemaining = _formatDuration(endDate.difference(now));
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isCurrentlyPaused ? 'Resume Subscription?' : 'Pause Subscription?',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCurrentlyPaused
                    ? 'Are you sure you want to resume the ${subscription['productName']} subscription?'
                    : 'Are you sure you want to pause the ${subscription['productName']} subscription?',
              ),
              SizedBox(height: 16),
              if (isCurrentlyPaused && timeRemaining.isNotEmpty)
                Text(
                  'Time remaining in current pause: $timeRemaining',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (!isCurrentlyPaused)
                Text(
                  'Pauses remaining: $maxPausesLeft',
                  style: TextStyle(
                    color:
                        maxPausesLeft > 0 ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
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

                setState(() {
                  subscriptions[index]['isPaused'] = !isCurrentlyPaused;
                  if (!isCurrentlyPaused) {
                    // Starting a new pause
                    subscriptions[index]['pauseStartDate'] = DateTime.now();
                    subscriptions[index]['pauseEndDate'] = DateTime.now().add(
                      Duration(days: 30),
                    );
                    subscriptions[index]['maxPausesLeft'] = (maxPausesLeft - 1)
                        .clamp(0, double.infinity);
                  } else {
                    // Resuming from pause
                    subscriptions[index]['pauseStartDate'] = null;
                    subscriptions[index]['pauseEndDate'] = null;
                  }
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isCurrentlyPaused
                          ? 'Subscription resumed successfully'
                          : 'Subscription paused successfully',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                itemCount: subscriptions.length,
                itemBuilder: (context, index) {
                  final subscription = subscriptions[index];
                  return SubscriptionCard(
                    productName: subscription['productName'],
                    planName: subscription['planName'],
                    quantity: subscription['quantity'],
                    nextDeliveryDate: subscription['nextDeliveryDate'],
                    deliveriesLeft: subscription['deliveriesLeft'],
                    isPaused: subscription['isPaused'],
                    onViewDetails:
                        () => _showSubscriptionDetails(context, subscription),
                    onTogglePause:
                        () => _showToggleConfirmation(context, index),
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
                      if (_currentPage < subscriptions.length - 1) {
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
            subscriptions.length,
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
    Map<String, dynamic> subscription,
  ) {
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
                subtitle: Text(subscription['productName']),
              ),
              ListTile(
                leading: Icon(Icons.card_membership, color: Colors.indigo),
                title: Text('Plan'),
                subtitle: Text(subscription['planName']),
              ),
              ListTile(
                leading: Icon(Icons.calendar_today, color: Colors.indigo),
                title: Text('Next Delivery'),
                subtitle: Text(
                  '${subscription['nextDeliveryDate'].day} - ${_getMonthName(subscription['nextDeliveryDate'].month)} - ${subscription['nextDeliveryDate'].year}',
                ),
              ),
              ListTile(
                leading: Icon(Icons.local_shipping, color: Colors.indigo),
                title: Text('Deliveries Left'),
                subtitle: Text(subscription['deliveriesLeft'].toString()),
              ),
            ],
          ),
        );
      },
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
