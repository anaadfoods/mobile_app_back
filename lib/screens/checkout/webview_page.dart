import "package:grocery_app/common_widgets/global_import.dart";
import 'package:grocery_app/service_locator.dart';
import 'dart:async';

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
  final String? merchantTransactionId; // Added for explicit transaction ID tracking
  final String? reference; // Added for unified status tracking (order_number/subscription_number)

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
    this.merchantTransactionId,
    this.reference,
  });

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isHandlingPayment = false;
  Timer? _pollTimer;
  bool _isPolling = false;
  
  void _startPolling() {
    final ref = widget.reference ??
        widget.merchantTransactionId ??
        (widget.isSubscription
            ? widget.subID.toString()
            : widget.orderId.toString());

    if (ref.isEmpty || ref == '0') return;

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isPolling || _isHandlingPayment || !mounted) return;
      _isPolling = true;
      try {
        final paymentService = getIt<PaymentService>();
        final statusResponse = await paymentService.fetchStatus(ref);
        
        if (!statusResponse.isPending) {
          timer.cancel();
          if (statusResponse.isSuccess) {
            await _handlePaymentSuccess();
          } else if (statusResponse.isFailed) {
            await _handlePaymentFailure();
          }
        }
      } catch (e) {
        // ignore errors during background polling
      } finally {
        if (mounted) _isPolling = false;
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startPolling();

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

                // Detect payment completion early when page starts loading
                if (url.contains(ApiConfig.easebuzzSuccessCallback) ||
                    url.contains("${ApiConfig.baseUrl}/api/payments/success") ||
                    url.contains("${ApiConfig.baseUrl}/api/payment/success")) {
                  _handlePaymentSuccess();
                } else if (url.contains(ApiConfig.easebuzzFailureCallback) ||
                    url.contains(
                          "${ApiConfig.baseUrl}/api/payments/failure",
                        ) ||
                    url.contains("${ApiConfig.baseUrl}/api/payment/failure")) {
                  _handlePaymentFailure();
                }
              },
              onPageFinished: (String url) async {
                setState(() {
                  _isLoading = false;
                });
                widget.onUrlChanged?.call(url);
                AppLogger.instance.log(url);

                // Detect payment completion via Easebuzz callback URLs
                // or legacy callback paths for backward compatibility
                if (url.contains(ApiConfig.easebuzzSuccessCallback) ||
                    url.contains("${ApiConfig.baseUrl}/api/payments/success") ||
                    url.contains("${ApiConfig.baseUrl}/api/payment/success")) {
                  await _handlePaymentSuccess();
                } else if (url.contains(ApiConfig.easebuzzFailureCallback) ||
                    url.contains(
                          "${ApiConfig.baseUrl}/api/payments/failure",
                        ) ||
                    url.contains("${ApiConfig.baseUrl}/api/payment/failure")) {
                  await _handlePaymentFailure();
                }
              },
              onNavigationRequest: (NavigationRequest request) {
                final url = request.url;

                // Intercept callback URLs immediately to prevent loading the API endpoints in WebView
                if (url.contains(ApiConfig.easebuzzSuccessCallback) ||
                    url.contains("${ApiConfig.baseUrl}/api/payments/success") ||
                    url.contains("${ApiConfig.baseUrl}/api/payment/success")) {
                  _handlePaymentSuccess();
                  return NavigationDecision.prevent;
                } else if (url.contains(ApiConfig.easebuzzFailureCallback) ||
                    url.contains(
                          "${ApiConfig.baseUrl}/api/payments/failure",
                        ) ||
                    url.contains("${ApiConfig.baseUrl}/api/payment/failure")) {
                  _handlePaymentFailure();
                  return NavigationDecision.prevent;
                }

                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                  final uri = Uri.parse(url);
                  launchUrl(uri, mode: LaunchMode.externalApplication).catchError((e) {
                    AppLogger.instance.e("Error launching external url: $e");
                    return false;
                  });
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url), headers: widget.headers ?? const <String, String>{});
  }

  Future<void> _handlePaymentSuccess() async {
    // Guard against being called multiple times
    if (_isHandlingPayment) return;
    _isHandlingPayment = true;

    try {
      final ref = widget.reference ??
          widget.merchantTransactionId ??
          (widget.isSubscription
              ? widget.subID.toString()
              : widget.orderId.toString());

      AppLogger.instance.log("Verifying payment status for reference: $ref");

      final paymentService = getIt<PaymentService>();
      final statusResponse = await paymentService.pollStatus(ref);
      AppLogger.instance.log("Verified payment status: ${statusResponse.status}");

      // Delegate to parent
      widget.onPaymentSuccess?.call(ApiConfig.baseUrl);
    } catch (e) {
      AppLogger.instance.e("Error verifying payment: $e");
      _showDialog(
        "Error verifying payment info. Please check your dashboard.",
        false,
      );
    }
  }

  Future<void> _handlePaymentFailure() async {
    // Guard against being called multiple times
    if (_isHandlingPayment) return;
    _isHandlingPayment = true;

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

  Future<void> _confirmCancelAndVerifyStatus() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Are you sure you want to cancel the payment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Payment'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Payment'),
          ),
        ],
      ),
    );

    if (shouldPop == true) {
      if (!mounted) return;

      // Show loading spinner while verifying payment status
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.parchment),
        ),
      );

      try {
        final paymentService = getIt<PaymentService>();
        final ref = widget.reference ??
            widget.merchantTransactionId ??
            (widget.isSubscription
                ? widget.subID.toString()
                : widget.orderId.toString());
        PaymentStatusResponse statusResponse = await paymentService.pollStatus(ref);

        // Dismiss loading spinner
        if (mounted) Navigator.of(context).pop();

        if (statusResponse.isSuccess) {
          await _handlePaymentSuccess();
          return;
        }
      } catch (e) {
        AppLogger.instance.e("Error verifying payment status on cancel: $e");
        if (mounted) Navigator.of(context).pop();
      }

      if (mounted) {
        Navigator.of(context).pop(); // Exit WebView
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmCancelAndVerifyStatus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? 'Secure Payment'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _confirmCancelAndVerifyStatus();
            },
          ),
          actions: _isLoading
              ? [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.parchment,
                      ),
                    ),
                  ),
                ]
              : [],
        ),
        body: Column(
          children: [
            // Merchant Info Banner — shows Legal/DBA name & payment URL
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.parchment : AppColors.parchment,
                border: Border(
                  bottom: BorderSide(
                    color:
                        isDark
                            ? AppColors.deepSoilGreen
                            : AppColors.deepSoilGreen,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: AppColors.deepSoilGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Anaad Foods Pvt. Ltd.',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isDark
                                ? AppColors.deepSoilGreen
                                : AppColors.deepSoilGreen,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepSoilGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            size: 12,
                            color: AppColors.parchment,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Secure',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.parchment,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 14,
                      color:
                          isDark ? AppColors.rawEarth26 : AppColors.rawEarth70,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.url,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              isDark
                                  ? AppColors.rawEarth26
                                  : AppColors.rawEarth70,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // WebView content
          Expanded(
            child: Stack(
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
          ),
        ],
      ),
    ));
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
      backgroundColor: AppColors.transparent,
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
            color: isDark ? AppColors.parchment : AppColors.parchment,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.charcoal.withValues(
                  alpha: isDark ? 0.4 : 0.15,
                ),
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
                  color: AppColors.deepSoilGreen.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepSoilGreen.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppColors.deepSoilGreen,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Payment Successful!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepSoilGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.rawEarth26 : AppColors.charcoal70,
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
                    backgroundColor: AppColors.deepSoilGreen,
                    foregroundColor: AppColors.parchment,
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
