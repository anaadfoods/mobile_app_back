import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:grocery_app/common_widgets/error_dialog.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/utils/app_logger.dart';
import '../widgets/merchant_info_banner.dart';
import '../widgets/success_dialog.dart';
import '../../domain/usecases/poll_payment_status_use_case.dart';

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
  final String? merchantTransactionId;
  final String? reference;

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
        final pollPaymentStatusUseCase = getIt<PollPaymentStatusUseCase>();
        final statusResponse = await pollPaymentStatusUseCase(ref);

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

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            widget.onUrlChanged?.call(url);

            if (url.contains(ApiConfig.easebuzzSuccessCallback) ||
                url.contains("${ApiConfig.baseUrl}/api/payments/success") ||
                url.contains("${ApiConfig.baseUrl}/api/payment/success")) {
              _handlePaymentSuccess();
            } else if (url.contains(ApiConfig.easebuzzFailureCallback) ||
                url.contains("${ApiConfig.baseUrl}/api/payments/failure") ||
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

            if (url.contains(ApiConfig.easebuzzSuccessCallback) ||
                url.contains("${ApiConfig.baseUrl}/api/payments/success") ||
                url.contains("${ApiConfig.baseUrl}/api/payment/success")) {
              await _handlePaymentSuccess();
            } else if (url.contains(ApiConfig.easebuzzFailureCallback) ||
                url.contains("${ApiConfig.baseUrl}/api/payments/failure") ||
                url.contains("${ApiConfig.baseUrl}/api/payment/failure")) {
              await _handlePaymentFailure();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            if (url.contains(ApiConfig.easebuzzSuccessCallback) ||
                url.contains("${ApiConfig.baseUrl}/api/payments/success") ||
                url.contains("${ApiConfig.baseUrl}/api/payment/success")) {
              _handlePaymentSuccess();
              return NavigationDecision.prevent;
            } else if (url.contains(ApiConfig.easebuzzFailureCallback) ||
                url.contains("${ApiConfig.baseUrl}/api/payments/failure") ||
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
      ..loadRequest(Uri.parse(widget.url),
          headers: widget.headers ?? const <String, String>{});
  }

  Future<void> _handlePaymentSuccess() async {
    if (_isHandlingPayment) return;
    _isHandlingPayment = true;

    try {
      final ref = widget.reference ??
          widget.merchantTransactionId ??
          (widget.isSubscription
              ? widget.subID.toString()
              : widget.orderId.toString());

      AppLogger.instance.log("Verifying payment status for reference: $ref");

      final pollPaymentStatusUseCase = getIt<PollPaymentStatusUseCase>();
      final statusResponse = await pollPaymentStatusUseCase(ref);
      AppLogger.instance.log("Verified payment status: ${statusResponse.status}");

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
    if (_isHandlingPayment) return;
    _isHandlingPayment = true;

    widget.onPaymentFailure?.call("flutterpay://payment/failure");
    _showDialog("Payment Failed!", false);
  }

  void _showDialog(String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => isSuccess
          ? SuccessDialog(
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.parchment),
        ),
      );

      try {
        final pollPaymentStatusUseCase = getIt<PollPaymentStatusUseCase>();
        final ref = widget.reference ??
            widget.merchantTransactionId ??
            (widget.isSubscription
                ? widget.subID.toString()
                : widget.orderId.toString());
        final statusResponse = await pollPaymentStatusUseCase(ref);

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
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Padding(
                    padding: EdgeInsets.all(16.0),
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
            MerchantInfoBanner(url: widget.url),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    const Center(
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
      ),
    );
  }
}
