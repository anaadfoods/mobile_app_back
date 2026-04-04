import 'package:flutter/material.dart';
import 'package:grocery_app/helpers/animated_transitions.dart';
import 'package:grocery_app/helpers/notification_helper.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail_single.dart';
import 'package:grocery_app/screens/checkout/webview_page.dart';
import 'package:grocery_app/services/subscription_service.dart';
// Make sure to import your other files like WebViewPage, AnimatedTransitions etc.

class SubscriptionHandler {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final BuildContext context; // Pass context in constructor for clarity

  // The handler now requires a BuildContext to perform navigation and show dialogs.
  SubscriptionHandler(this.context);

  // You would call this method from your UI.
  Future<void> processUPIRepayment(int subscriptionId) async {
    try {
      final result = await _subscriptionService.RepaymentSubscription(subscriptionId);

      // No need for mounted check if you handle context carefully
      if (result['success'] == true) {
        final paymentLink = result['payment_links']?['web'];

        if (paymentLink != null) {
          // Case 1: A payment link exists, open WebView
          await _launchSubscriptionWebView(paymentLink, result['subscription_id']);
        } else {
          // Case 2: No payment link
          _showSubscriptionFailedDialog({'message': 'We couldn\'t start the payment process. Please check your connection and try again.'});
        }
      } else {
        _showSubscriptionFailedDialog(result);
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Failed to initiate repayment: $e');
    }
  }

  // --- NEW REUSABLE METHODS ---

  /// **[REUSABLE]** Fetches details and navigates to the detail screen on success.
  Future<void> _fetchDetailsAndNavigate(dynamic subscriptionId) async {
    if (subscriptionId == null) {
        _showRepaymentSuccessMessage(); // Show generic success if ID is missing
        return;
    }

    try {
      final parsedId = int.parse(subscriptionId.toString());
      final subscriptionDetails = await _subscriptionService.getSubscriptionDetails(parsedId);

      if (subscriptionDetails['success'] == true) {
        // Successful fetch and navigation
        _showPaymentNotification(
          title: 'Payment Successful!',
          status: 'Paid',
          subscriptionId: parsedId,
        );

        Navigator.pushAndRemoveUntil(
          context,
          AnimatedTransitions.fadeScale(
            SubscriptionPlanDetailScreen(subscription: subscriptionDetails['data']),
          ),
          (route) => route.isFirst,
        );
      } else {
        // API returned success:false, show generic success message and pop back.
        Navigator.of(context).pop(); // Close WebView if it's open
        _showRepaymentSuccessMessage();
      }
    } catch (e) {
      // Failed to fetch details, but payment was likely successful.
      // Show generic success message and pop back.
      print("Error fetching details after payment: $e");
      Navigator.of(context).pop(); // Close WebView if it's open
      _showRepaymentSuccessMessage();
    }
  }

  /// **[REUSABLE]** Centralizes showing notifications.
  void _showPaymentNotification({
    required String title,
    required String status,
    required int subscriptionId,
  }) {
    NotificationHelper.showNotification(
      title: title,
      body: 'Subscription ID: $subscriptionId\nPayment Mode: UPI\nStatus: $status',
    );
  }

  // --- REFACTORED HELPER METHODS ---

  Future<void> _launchSubscriptionWebView(String paymentUrl, dynamic subscriptionId) async {
    try {
      final parsedId = int.parse(subscriptionId.toString());

      // Show a notification that payment is pending
      _showPaymentNotification(
        title: 'Repayment Initiated!',
        status: 'Pending Payment',
        subscriptionId: parsedId,
      );

      await Navigator.push(
        context,
        AnimatedTransitions.slideFromBottom(
          WebViewPage(
            url: paymentUrl,
            orderId: parsedId,
            title: 'UPI Payment',
            subID: parsedId,
            isSubscription: true,
            // NOW we just call our single reusable method!
            onPaymentSuccess: (url) async {
              await _fetchDetailsAndNavigate(parsedId);
            },
            onPaymentFailure: (url) {
              Navigator.pop(context);
              _showPaymentNotification(
                title: 'Payment Failed!',
                status: 'Failed',
                subscriptionId: parsedId,
              );
              SnackBarHelper.showError(context, 'Payment failed or cancelled');
            },
          ),
        ),
      );
    } catch (e) {
      SnackBarHelper.showError(context, 'Failed to launch payment page: $e');
    }
  }

  void _showRepaymentSuccessMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repayment Successful'),
        content: const Text('Your subscription repayment has been processed successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              // Consider if you still need the second pop here.
              // It might be better to handle navigation more explicitly.
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionFailedDialog(Map<String, dynamic> result) {
     // Your implementation for showing a failed dialog
     SnackBarHelper.showError(context, result['message'] ?? 'An unknown error occurred.');
  }
  
}