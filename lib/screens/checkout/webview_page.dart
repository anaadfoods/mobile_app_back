import "package:grocery_app/common_widgets/global_import.dart";

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
    super.key,
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
  });

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
        SnackBarHelper.showError(
          context,
          response['message'] ?? 'Failed to fetch subscriptions',
        );
      }
    } catch (e) {
      print('Error fetching subscriptions: $e');
      SnackBarHelper.showError(
        context,
        'An error occurred while fetching subscriptions',
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
                  "${ApiConfig.baseUrl}/api/payments/success/",
                )) {
                  print(url);

                  await _handlePaymentSuccess();
                } else if (url.contains(
                  "${ApiConfig.baseUrl}/api/payment/failure",
                )) {
                  await _handlePaymentFailure();
                }
              },
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.startsWith("${ApiConfig.baseUrl}/api/")) {
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

        // Fetch subscription details directly by ID instead of searching local list
        // This is more reliable as newly created subscriptions may not appear in
        // the list endpoint until their status changes from PENDING to ACTIVE
        print(
          'Fetching subscription details for id: ${subscriptionStatus.subscriptionId}',
        );

        final subscriptionResult = await _subscriptionService
            .getSubscriptionDetails(subscriptionStatus.subscriptionId);

        if (subscriptionResult['success'] != true ||
            subscriptionResult['data'] == null) {
          print(
            'Failed to fetch subscription details: ${subscriptionResult['message']}',
          );
          _showDialog(
            "Payment successful! Your subscription is being activated. Please check My Subscriptions.",
            true,
          );
          return;
        }

        final Subscription subscription =
            subscriptionResult['data'] as Subscription;

        if (subscriptionStatus.transactionStatus == 'SUCCESS') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      SubscriptionPlanDetailScreen(subscription: subscription),
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
          (_) =>
              isSuccess
                  ? _SuccessDialog(
                    message: message,
                    onDismiss: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  )
                  : ErrorDialog(
                    title: 'Payment Failed',
                    message: message,
                    icon: Icons.payment_rounded,
                    iconColor: Theme.of(context).colorScheme.error,
                    showCloseButton: false,
                    onRetry: null,
                    onDismiss: () {
                      Navigator.of(context).pop();
                    },
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

/// Themed success dialog for payment confirmation
class _SuccessDialog extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _SuccessDialog({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          );
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon with glow
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withOpacity(0.15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Payment Successful!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // OK button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

