import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/helpers/animated_transitions.dart';
import 'package:grocery_app/helpers/notification_helper.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail.dart';
import 'package:grocery_app/screens/checkout/webview_page.dart';
import 'package:grocery_app/styles/colors.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import '../screens/MySubscriptionPlan/subscription_plan_detail_single.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';

class SubscriptionCard extends StatelessWidget {
  final String productName;
  final String planName;
  final int quantity;
  final DateTime nextDeliveryDate;
  final int deliveriesLeft;
  final double discountedPrice;
  final double totalPrice;
  final int totalDeliveries;
  final bool isPaused;
  final VoidCallback onViewDetails;
  final VoidCallback onTogglePause;
  final VoidCallback onRepayment;
  final int completedDeliveries;
  final String installmantPaymentStatus;
  final String imageUrl;

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
    required this.onRepayment,
    required this.completedDeliveries,
    required this.imageUrl,
    this.installmantPaymentStatus = "PAID", required this.discountedPrice, required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        color: Colors.grey[100],
        // ADDED THIS BOXSHADOW FOR ELEVATION
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.08),
        //     blurRadius: 10,
        //     offset: const Offset(0, 4),
        //   ),
        // ],
      ),
      padding: const EdgeInsets.all(12.0),
      child: GestureDetector(
        onTap: onViewDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subscription Plan Tag
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    "Subscription - $planName",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Product Row
            Container(
              padding: EdgeInsets.all(6),
              margin: EdgeInsets.all(1),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8)
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (imageUrl.isNotEmpty)
                    // If the image list is NOT empty, show the first image
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
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

                  // ClipRRect(
                  //   borderRadius: BorderRadius.circular(12),
                  //   child: Image.network(
                  //     imageUrl[0],
                  //     // replace with product image
                  //     height: 100,
                  //     width: 100,
                  //     fit: BoxFit.cover,
                  //   ),
                  // ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(productName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          "$planName – ${quantity}x",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Text("₹$discountedPrice",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Text("₹$totalPrice",
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough)),
                            SizedBox(width: 8),
                            Container(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text("20% Off",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.orange[800])),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 9),

            // Actions
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bottonBackgroundColor,
                    foregroundColor: Colors.white, // Set icon and text color to white
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(isPaused ? "Resume" : "Pause"),
                  onPressed: onTogglePause,
                ),
                SizedBox(width: 10),
                Text(
                  "$deliveriesLeft/$totalDeliveries Deliveries Left",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.bottonBackgroundColor),
                )
              ],
            ),

            SizedBox(height: 5),

            // Footer
            Text(
              "Next Delivery By ${_getMonthName(nextDeliveryDate.month)} ${nextDeliveryDate.day} • $installmantPaymentStatus",
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            )
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

  get isSubscription => true;

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
  bool isSubscription = true;

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
        SnackBarHelper.showSuccess(
          context,
          response['message'] ?? 'Subscription paused successfully',
        );
        await _loadSubscriptions(); // Reload subscriptions after toggle
      } else {
        SnackBarHelper.showError(
          context,
          response['detail'] ?? response['message'] ?? 'Failed to toggle pause',
        );
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Failed to toggle pause: $e');
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
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text("")],
        ),
      );
    }

    if (_subscriptions.isEmpty) {
      return Center(child: Text(""));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Active Subscription",
                  style: TextStyle(
                    color: Colors.black,
                     fontSize: 18 , 
                     fontWeight: FontWeight.bold ,
                     ) 
                     
                ),
                 GestureDetector(
                  onTap: () => {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SubscriptionScreen()))
                  },
                   child: const Text(
                    "See all Plans",
                    style: TextStyle(
                      color: AppColors.primaryColor
                      , fontSize: 14 , 
                      fontWeight: FontWeight.bold),
                                   ),
                 ),
            
              ],
            ),
          ),
          SizedBox(height: 10,),
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
                      discountedPrice : item.discountedPrice,
                      totalPrice : item.price,
                      imageUrl: item.imageUrl ?? '',
                      nextDeliveryDate: DateTime.parse(
                        subscription.nextDeliveryDate,
                      ),
                      totalDeliveries: subscription.totalDeliveries,
                      deliveriesLeft:
                          (subscription.totalDeliveries -
                              subscription.completedDeliveries),
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
                      completedDeliveries: subscription.completedDeliveries,
                      installmantPaymentStatus:
                          subscription.installmentPaymentStatus,
                      onRepayment: () {
                        _handleUPISubscription(subscription.id);
                      },
                    );
                  },
                ),
                // Navigation Arrows
                // Positioned(
                //   left: 0,
                //   top: 0,

                //   bottom: 0,
                //   child: Center(
                //     child: IconButton(
                //       icon: Icon(
                //         Icons.chevron_left,
                //         size: 32,
                //         color: Colors.indigo[900],
                //       ),
                //       onPressed: () {
                //         if (_currentPage > 0) {
                //           _pageController.previousPage(
                //             duration: Duration(milliseconds: 300),
                //             curve: Curves.easeInOut,
                //           );
                //         }
                //       },
                //     ),
                //   ),
                // ),
                // Positioned(
                //   right: 0,
                //   top: 0,
                //   bottom: 0,
                //   child: Center(
                //     child: IconButton(
                //       icon: Icon(
                //         Icons.chevron_right,
                //         size: 32,
                //         color: Colors.indigo[900],
                //       ),
                //       onPressed: () {
                //         if (_currentPage < _subscriptions.length - 1) {
                //           _pageController.nextPage(
                //             duration: Duration(milliseconds: 300),
                //             curve: Curves.easeInOut,
                //           );
                //         }
                //       },
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          // SizedBox(height: 8),
          // SingleChildScrollView(
          //   scrollDirection: Axis.horizontal,
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: List.generate(
          //       _subscriptions.length,
          //       (index) => Container(
          //         width: 8,
          //         height: 8,
          //         margin: EdgeInsets.symmetric(horizontal: 4),
          //         decoration: BoxDecoration(
          //           shape: BoxShape.circle,
          //           color:
          //               _currentPage == index
          //                   ? AppColors.primaryColor
          //                   : Colors.grey[300],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      
    );
  }

  Future<void> _handleUPISubscription(int subscriptionId) async {
    try {
      final result = await _subscriptionService.RepaymentSubscription(
        subscriptionId,
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
            await _launchSubscriptionWebView(result);

            // Send notification for subscription repayment with pending payment
            NotificationHelper.showNotification(
              title: 'Repayment Initiated!',
              body:
                  'Subscription ID: ${result['subscription_id']}\nPayment Mode: UPI\nStatus: Pending Payment',
            );
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
        _showSubscriptionFailedDialog(result);
      }
    } catch (e) {
      print('Error in _handleUPISubscription: $e');
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
            AnimatedTransitions.fadeScale(
              SubscriptionPlanDetailScreen(
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

  Future<void> _handleSuccessfulSubscription(
    Map<String, dynamic> result,
  ) async {
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
            AnimatedTransitions.fadeScale(
              SubscriptionPlanDetailScreen(
                subscription: subscriptionDetails['data'],
              ),
            ),
            (route) => route.isFirst,
          );
        } else {
          // If fetching details fails, show success message
          _showSubscriptionSuccessMessage(result);
        }
      } else {
        _showSubscriptionSuccessMessage(result);
      }
    } catch (e) {
      print('Error fetching subscription details: $e');
      _showSubscriptionSuccessMessage(result);
    }
  }

  Future<void> _launchSubscriptionWebView(Map<String, dynamic> result) async {
    print("=== _launchSubscriptionWebView called ===");
    print("Result: $result");

    try {
      final paymentUrl = result['payment_links']['web'];
      final subscriptionId = result['subscription_id'];

      print("Payment URL: $paymentUrl");
      print("Subscription ID: $subscriptionId");
      print("Is Subscription: ${widget.isSubscription}");

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
        AnimatedTransitions.slideFromBottom(
          WebViewPage(
            url: paymentUrl,
            orderId: parsedSubscriptionId,
            title: 'UPI Payment',
            subID: parsedSubscriptionId,
            isSubscription: widget.isSubscription,
            onPaymentSuccess: (url) async {
              print("Payment success callback triggered");
              // Fetch subscription details after successful payment
              try {
                final subscriptionDetails = await _subscriptionService
                    .getSubscriptionDetails(parsedSubscriptionId);

                if (subscriptionDetails['success'] == true && mounted) {
                  // Send notification for successful payment
                  NotificationHelper.showNotification(
                    title: 'Payment Successful!',
                    body:
                        'Subscription ID: $parsedSubscriptionId\nPayment Mode: UPI\nStatus: Paid',
                  );

                  Navigator.pushAndRemoveUntil(
                    context,
                    AnimatedTransitions.fadeScale(
                      SubscriptionPlanDetailScreen(
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
                print('Error fetching subscription details after payment: $e');
                Navigator.pop(context);
                _showRepaymentSuccessMessage(result);
              }
            },
            onPaymentFailure: (url) {
              print("Payment failure callback triggered");
              Navigator.pop(context);

              // Send notification for payment failure
              NotificationHelper.showNotification(
                title: 'Payment Failed!',
                body:
                    'Subscription ID: $parsedSubscriptionId\nPayment Mode: UPI\nStatus: Failed',
              );

              SnackBarHelper.showError(context, 'Payment failed or cancelled');
            },
          ),
        ),
      );

      print("Navigation to WebView completed");
    } catch (e) {
      print("Error in _launchSubscriptionWebView: $e");
      SnackBarHelper.showError(context, 'Failed to launch payment page: $e');
    }
  }

  // Show repayment success message
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

  // Show subscription success message
  void _showSubscriptionSuccessMessage(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Subscription Created'),
            content: Text('Your subscription has been created successfully!'),
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

  void _showSubscriptionFailedDialog(Map<String, dynamic> result) {
    String errorMessage = _parseServerError(
      result['message'] ?? result['errors'] ?? 'Failed to create subscription',
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Subscription Failed'),
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

  // void _showSubscriptionDetails(
  //   BuildContext context,
  //   Subscription subscription,
  // ) {
  //   final item = subscription.items.first;
  //   showModalBottomSheet(
  //     context: context,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (BuildContext context) {
  //       return Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Text(
  //               'Subscription Details',
  //               style: TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.indigo[900],
  //               ),
  //             ),
  //             SizedBox(height: 16),
  //             ListTile(
  //               leading: Icon(Icons.shopping_basket, color: Colors.indigo),
  //               title: Text('Product'),
  //               subtitle: Text(item.productName),
  //             ),
  //             ListTile(
  //               leading: Icon(Icons.card_membership, color: Colors.indigo),
  //               title: Text('Plan'),
  //               subtitle: Text(subscription.planName),
  //             ),
  //             ListTile(
  //               leading: Icon(Icons.calendar_today, color: Colors.indigo),
  //               title: Text('Next Delivery'),
  //               subtitle: Text(subscription.nextDeliveryDate),
  //             ),
  //             ListTile(
  //               leading: Icon(Icons.local_shipping, color: Colors.indigo),
  //               title: Text('Deliveries Left'),
  //               subtitle: Text(
  //                 (subscription.endDate.difference(DateTime.now()).inDays / 30)
  //                     .ceil()
  //                     .toString(),
  //               ),
  //             ),
  //             ListTile(
  //               leading: Icon(Icons.location_on, color: Colors.indigo),
  //               title: Text('Delivery Address'),
  //               subtitle: Text(
  //                 '${subscription.deliveryAddress}, ${subscription.deliveryCity}, ${subscription.deliveryState} - ${subscription.deliveryPincode}',
  //               ),
  //             ),
  //             ListTile(
  //               leading: Icon(Icons.phone, color: Colors.indigo),
  //               title: Text('Contact Number'),
  //               subtitle: Text(subscription.deliveryPhone),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// extension on String {
//   difference(DateTime dateTime) {}
// }
