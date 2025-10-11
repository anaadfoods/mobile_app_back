import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/helpers/animated_transitions.dart';
import 'package:grocery_app/helpers/notification_helper.dart';
import 'package:grocery_app/helpers/responsive_helper.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail.dart';
import 'package:grocery_app/screens/checkout/webview_page.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:intl/intl.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import '../screens/MySubscriptionPlan/subscription_plan_detail_single.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';


class SubscriptionCardSkeleton extends StatelessWidget {
  final ResponsiveHelper responsive;
  const SubscriptionCardSkeleton({super.key, required this.responsive});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      isLoading: true,
      child: Container(
        margin: EdgeInsets.symmetric(
            vertical: responsive.S, horizontal: responsive.screenPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        padding: EdgeInsets.all(responsive.value(mobile: 12, tablet: 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(width: 140, height: 24, color: Colors.white), // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: responsive.value(mobile: 80, tablet: 100),
                  width: responsive.value(mobile: 80, tablet: 100),
                  color: Colors.white,
                ), // Image
                SizedBox(width: responsive.S),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white),
                      SizedBox(height: responsive.S / 2),
                      Container(
                          width: 100, height: 14, color: Colors.white),
                      SizedBox(height: responsive.S),
                      Container(
                          width: 120, height: 20, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                        width: 100, height: 40, color: Colors.white), // Button
                    SizedBox(width: responsive.S),
                    Container(
                        width: 150, height: 16, color: Colors.white), // Text
                  ],
                ),
                SizedBox(height: responsive.S),
                Container(
                    width: 200, height: 14, color: Colors.white), // Footer
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [
            Color(0xFFEBEBF4),
            Color(0xFFF4F4F4),
            Color(0xFFEBEBF4),
          ],
          stops: [
            0.1,
            0.3,
            0.4,
          ],
          begin: Alignment(-1.0, -0.3),
          end: Alignment(1.0, 0.3),
          tileMode: TileMode.clamp,
        ).createShader(bounds);
      },
      child: widget.child,
    );
  }
}





class SubscriptionCarousel extends StatefulWidget  {
  const SubscriptionCarousel({super.key});

  get isSubscription => true;

  @override
  State<SubscriptionCarousel> createState() => _SubscriptionCarouselState();
}

class _SubscriptionCarouselState extends State<SubscriptionCarousel> with AutomaticKeepAliveClientMixin{
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<Subscription> _subscriptions = [];
    static List<Subscription>? _cachedSubscriptions;

  bool _isLoading = true;
  String? _error;
  bool isSubscription = true;
  
  late ResponsiveHelper responsive = ResponsiveHelper(
    context,
    BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width,
      maxHeight: MediaQuery.of(context).size.height,
    ),
  );

    late Future<List<Subscription>> _subscriptionsFuture;


    @override 
    bool get wantKeepAlive => true;


  @override
  void initState() {
    super.initState();
    
    _subscriptionsFuture = _loadSubscriptions();
  }

// In _SubscriptionCarouselState

Future<List<Subscription>> _loadSubscriptions() async {
  // ✨ MODIFICATION 2: Check the cache first
  if (_cachedSubscriptions != null) {
    return _cachedSubscriptions!;
  }

  try {
    // This network call will now only run if the cache is empty
    final response = await _subscriptionService.getSubscriptions();
    if (response['success'] == true && response['data'] != null) {
      final allSubscriptions = response['data'] as List<Subscription>;
      
      // ✨ MODIFICATION 3: Save the fetched data to the cache
      _cachedSubscriptions = allSubscriptions; 
      
      return allSubscriptions;
    } else {
      throw response['message'] ?? 'Failed to load subscriptions';
    }
  } catch (e) {
    // Clear cache on error to allow a retry on next build
    _cachedSubscriptions = null;
    throw Exception('Error fetching subscriptions: $e');
  }
}


 static void refreshSubscriptions() {
    _cachedSubscriptions = null;
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

Widget _buildDatePickerField({
  required BuildContext context,
  required String hintText,
  required DateTime? selectedDate,
  required Function() onTap,
}) {
  final Color borderColor = const Color(0xFFC4A464);
  final Color backgroundColor = const Color(0xFFFFF7E6);

  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: hintText == 'From' ? Colors.transparent : backgroundColor,
          border: Border.all(color: hintText == 'From' ? borderColor : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: borderColor, size: 12),
            const SizedBox(width: 8),
            Text(
              selectedDate != null ? DateFormat('MMM dd, yyyy').format(selectedDate) : hintText,
              style: TextStyle(
                fontSize: 12,
                color: selectedDate != null ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ⭐️ REPLACE your old _showToggleConfirmation with this new version.
void _showToggleConfirmation(Subscription subscription) {
  final isCurrentlyPaused = subscription.status == 'PAUSED';
  final maxPausesLeft = subscription.remainingPauseTimes;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  // This is for the new UI element, though the API call doesn't use it yet.
  DateTime? selectedNextDeliveryDate; 

  // --- Logic for RESUMING remains a simple dialog ---
  if (isCurrentlyPaused) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume Subscription?'),
        content: const Text('Are you sure you want to resume this subscription?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _togglePauseSubscription(subscription , selectedStartDate!, selectedEndDate!); // Pass nulls to resume
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return; // Stop here if resuming
  }

  // --- NEW custom dialog for PAUSING ---
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pause From',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // --- From/To Date Pickers ---
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
                            lastDate: DateTime.now().add(const Duration(days: 365)),
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
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => selectedEndDate = date);
                          }
                        },
                      ),
                    ],
                  ),
                  
                 
                  const SizedBox(height: 32),

                  // --- Save Button ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // --- Reusing your existing validation logic ---
                        if (maxPausesLeft <= 0) {
                          SnackBarHelper.showError(context, 'No pauses remaining.');
                          return;
                        }
                        if (selectedStartDate == null || selectedEndDate == null) {
                          SnackBarHelper.showError(context, 'Please select both start and end dates.');
                          return;
                        }
                        if (selectedEndDate!.isBefore(selectedStartDate!)) {
                          SnackBarHelper.showError(context, 'End date must be after start date.');
                          return;
                        }
                        
                        Navigator.pop(context); // Close the dialog
                        _togglePauseSubscription(subscription , selectedStartDate!, selectedEndDate!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC4A464),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
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


 @override
  Widget build(BuildContext context) {
        super.build(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final responsive = ResponsiveHelper(context, constraints);

        return FutureBuilder<List<Subscription>>(
          future: _subscriptionsFuture,
          builder: (context, snapshot) {
            // ✨ UPDATED: Show skeleton loader while waiting
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSkeletonLoader(responsive);
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(responsive.screenPadding),
                  child: Text("Couldn't load subscriptions.\n${snapshot.error}"),
                ),
              );
            }

            final subscriptions = snapshot.data ?? [];
            if (subscriptions.isEmpty) {
              return const SizedBox.shrink();
            }

            return _buildCarouselContent(subscriptions, responsive);
          },
        );
      },
    );
  }

  Widget _buildCarouselContent(
      List<Subscription> subscriptions, ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric( vertical: responsive.S, horizontal: responsive.screenPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Active Subscription",
                style: TextStyle(
                  fontSize: responsive.headline3,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                },
                child: Text(
                  "See all Plans",
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: responsive.bodyText1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.S),
        SizedBox(
          height: responsive.value(mobile: 290, tablet: 320),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              final subscription = subscriptions[index];
              return SubscriptionCard(
                subscription: subscription,
                responsive: responsive,
                onTogglePause: () =>
                    _showToggleConfirmation( subscription),
                onRepayment: () {
                  // TODO: Implement repayment logic
                },
              );
            },
          ),
        ),
         
      ],
    );
      }

  Widget _buildSkeletonLoader(ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.screenPadding),
          // Skeleton for the header text
          child: ShimmerLoading(
            isLoading: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    width: 150, height: 24, color: Colors.white),
                Container(
                    width: 80, height: 24, color: Colors.white),
              ],
            ),
          ),
        ),
        SizedBox(height: responsive.S),
        SizedBox(
          height: responsive.value(mobile: 290, tablet: 320),
          // Use a non-scrollable PageView for consistent layout
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              SubscriptionCardSkeleton(responsive: responsive),
            ],
          ),
        ),
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
        

        if (result['payment_links'] != null) {
        

          if (result['payment_links']['web'] != null) {

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
  
 @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

}










class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onTogglePause;
  final VoidCallback onRepayment;
  final ResponsiveHelper responsive;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.onTogglePause,
    required this.onRepayment,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetails(context, subscription),
      child: Container(
        margin: EdgeInsets.symmetric(
            vertical: responsive.S, horizontal: responsive.screenPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(responsive.value(mobile: 12, tablet: 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeader(),
            _buildProductDetails(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context, Subscription subscription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SubscriptionPlanDetailScreen(subscription: subscription),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            "Subscription - ${subscription.planName}",
            style:
                TextStyle(color: Colors.white, fontSize: responsive.smallText),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
    final item = subscription.items.first;
    final double discountPercent =
        ((item.price - item.discountedPrice) / item.price) * 100;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: item.imageUrl ?? '',
            height: responsive.value(mobile: 80, tablet: 100),
            width: responsive.value(mobile: 80, tablet: 100),
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child:
                  Icon(Icons.image_not_supported_outlined, color: Colors.grey[400]),
            ),
          ),
        ),
        SizedBox(width: responsive.S),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: responsive.bodyText1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "${subscription.planName} – ${item.quantity}x",
                style: TextStyle(
                    color: Colors.grey[600], fontSize: responsive.bodyText2),
              ),
              SizedBox(height: responsive.S),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "₹${item.discountedPrice}",
                    style: TextStyle(
                      fontSize: responsive.headline3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: responsive.S),
                  Text(
                    "₹${item.price}",
                    style: TextStyle(
                      fontSize: responsive.bodyText1,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  if (discountPercent > 0) ...[
                    SizedBox(width: responsive.S),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${discountPercent.toStringAsFixed(0)}% Off",
                        style: TextStyle(
                            fontSize: responsive.smallText,
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  ]
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final deliveriesLeft =
        subscription.totalDeliveries - subscription.completedDeliveries;
    final bool isPaused = subscription.status == 'PAUSED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bottonBackgroundColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 20),
              label: Text(isPaused ? "Resume" : "Pause"),
              onPressed: onTogglePause,
            ),
            SizedBox(width: responsive.S),
            Expanded(
              child: Text(
                "$deliveriesLeft/${subscription.totalDeliveries} Deliveries Left",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.bottonBackgroundColor,
                  fontSize: responsive.bodyText2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
        SizedBox(height: responsive.S),
        Text(
          "Next Delivery: ${_formatDate(subscription.nextDeliveryDate)} • ${subscription.installmentPaymentStatus}",
          style: TextStyle(
              color: Colors.grey[700], fontSize: responsive.bodyText2),
        )
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return "${months[date.month - 1]} ${date.day}";
    } catch (e) {
      return dateString;
    }
  }
}


  

 

