import 'package:flutter/material.dart';
import 'package:grocery_app/models/subscription_model.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail_single.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:grocery_app/services/order_service.dart';
import 'package:grocery_app/screens/order_accepted_screen.dart';
import 'package:grocery_app/services/subscription_service.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String? title;
  final Map<String, String>? headers;
  final Function(String)? onUrlChanged;
  final Function(String)? onPaymentSuccess;
  final Function(String)? onPaymentFailure;
  final Function(Map<String, dynamic>)? onPaymentResult;
  final int orderId;
  final bool isSubscription;
  final int subID;

  const WebViewPage({
    Key? key,
    required this.url,
    required this.orderId,
    this.title,
    this.headers,
    this.onUrlChanged,
    this.onPaymentSuccess,
    this.onPaymentFailure,
    this.subID = 0,
    this.onPaymentResult,
    this.isSubscription = false,
  }) : super(key: key);

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _controller;
  bool _isLoading = true;
  final OrderService _orderService = OrderService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<Subscription> allSubscriptions = [];

  Future<void> _fetchSubscriptions() async {
    try {
      final response = await _subscriptionService.getSubscriptions();
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        setState(() {
          allSubscriptions = data.map((item) => item as Subscription).toList();
        });
      } else {
        print('Error fetching subscriptions: ${response['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Failed to fetch subscriptions',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error fetching subscriptions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while fetching subscriptions'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {},
              onPageStarted: (String url) {
                setState(() {
                  _isLoading = true;
                });
                widget.onUrlChanged?.call(url);
              },
              onPageFinished: (String url) async {
                setState(() {
                  _isLoading = false;
                });
                widget.onUrlChanged?.call(url);
                print(url);

                if (url.contains(
                  "https://app.anaadfoods.com/api/payments/success/",
                )) {
                  print(url);

                  await _handlePaymentSuccess();
                } else if (url.contains(
                  "https://app.anaadfoods.com/api/payment/failure",
                )) {
                  await _handlePaymentFailure();
                }
              },
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.startsWith("https://app.anaadfoods.com/api/")) {
                  if (request.url.contains("payment/success")) {
                    _handlePaymentSuccess();
                  } else if (request.url.contains("payment/failure")) {
                    _handlePaymentFailure();
                  }
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url), headers: widget.headers ?? {});
  }

  Future<void> _handlePaymentSuccess() async {
    try {
      if (widget.isSubscription) {
        print("Is is Subscription call ${widget.isSubscription}");
        // Subscription payment status
        print(widget.orderId);
        final debugpaymentone = await SubscriptionService()
            .fetchSubscriptionPaymentStatus(widget.subID);

        if (debugpaymentone == null) {
          print("Failed to fetch payment status");
          _showDialog("Payment verification failed!", false);
          return;
        }

        print(debugpaymentone.paymentStatus);
        await _orderService.postOrderId(debugpaymentone.merchantTransactionId);

        final subscriptionStatus = await SubscriptionService()
            .fetchSubscriptionPaymentStatus(widget.subID);

        if (subscriptionStatus == null) {
          print("Failed to fetch subscription status");
          _showDialog("Payment verification failed!", false);
          return;
        }

        print(subscriptionStatus.transactionStatus);

        // Find the first subscription with matching id
        Subscription? subscription;
        print(allSubscriptions);
        if (subscriptionStatus != null) {
          subscription = allSubscriptions.firstWhere(
            (sub) => sub.id == subscriptionStatus.subscriptionId,
            orElse: () => null as Subscription,
          );

          if (subscription == null) {
            // If not found in the list, fetch from the service
            final detailsResponse = await _subscriptionService
                .getSubscriptionsbyId(subscriptionStatus.subscriptionId);
            if (detailsResponse['success'] == true &&
                detailsResponse['data'] != null) {
              // If the API returns a list, get the first item; otherwise, use as is
              if (detailsResponse['data'] is List &&
                  detailsResponse['data'].isNotEmpty) {
                subscription = detailsResponse['data'].first;
              } else if (detailsResponse['data'] is Subscription) {
                subscription = detailsResponse['data'];
              }
            }
          }
        }

        if (subscriptionStatus.transactionStatus == 'SUCCESS' &&
            subscription != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      SubscriptionPlanDetailScreen(subscription: subscription!),
            ),
          );
        } else {
          _showDialog("Payment Failed!", false);
        }
      } else {
        // Order payment status (existing logic)
        final debugpayment = await _orderService.fetchPaymentStatus(
          widget.orderId,
        );
        await _orderService.postOrderId(debugpayment.orderNumber);
        final paymentStatus = await _orderService.fetchPaymentStatus(
          widget.orderId,
        );

        if (paymentStatus.transactionStatus == 'SUCCESS') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OrderAcceptedScreen(
                    paymentStatus: paymentStatus,
                    isSubscription: false,
                  ),
            ),
          );
        } else {
          _showDialog("Payment Failed!", false);
        }
      }
    } catch (e) {
      print("Error verifying payment: $e");
      _showDialog("Error verifying payment. Please try again.", false);
    }
  }

  Future<void> _handlePaymentFailure() async {
    widget.onPaymentFailure?.call("flutterpay://payment/failure");
    _showDialog("Payment Failed!", false);
  }

  void _showDialog(String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: Text(isSuccess ? "Success" : "Failure"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Payment Gateway'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (_) => AlertDialog(
                    title: Text('Cancel Payment?'),
                    content: Text(
                      'Are you sure you want to cancel the payment?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Continue Payment'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel Payment'),
                      ),
                    ],
                  ),
            );
          },
        ),
        actions:
            _isLoading
                ? [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ]
                : [],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading payment gateway...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
