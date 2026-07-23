import 'package:grocery_app/models/payment_status_model.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/utils/app_logger.dart';
import 'package:grocery_app/service_locator.dart';

/// Dedicated service for all payment-related operations.
///
/// Centralises status checks and polling so that [OrderService] and
/// [SubscriptionService] stay focused on their own domain.
///
/// Gateway-agnostic — works with Easebuzz today but the contract is stable
/// across future gateway swaps.
///
/// **There is one endpoint:**
/// `GET /api/payments/status/<reference>/`
/// where `<reference>` is the `order_number` or `subscription_number`.
class PaymentService {
  PaymentService._internal();
  factory PaymentService() => getIt<PaymentService>();
  static PaymentService create() => PaymentService._internal();

  // ─── configuration ────────────────────────────────────────────────
  static const int _maxPollAttempts = 15; // 30 seconds
  static const Duration _pollInterval = Duration(seconds: 2);

  /// Statuses that mean "still in flight — keep polling".
  static const Set<String> _pendingStatuses = {
    'INITIATED',
    'PENDING',
  };

  /// Single-shot fetch for `GET /api/payments/status/<reference>/`
  Future<PaymentStatusResponse> fetchStatus(String reference) async {
    final response = await ApiClient.instance.get(
      '/api/payments/status/$reference/',
    );
    return PaymentStatusResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  // ─── polling ──────────────────────────────────────────────────────

  /// Poll `GET /api/payments/status/<reference>/` until the status leaves
  /// `INITIATED` / `PENDING`, or [_maxPollAttempts] is reached.
  ///
  /// [reference] is the `order_number` or `subscription_number` returned
  /// by the create call.
  Future<PaymentStatusResponse> pollStatus(String reference) async {
    PaymentStatusResponse? last;
    for (int i = 0; i < _maxPollAttempts; i++) {
      try {
        final response = await ApiClient.instance.get(
          '/api/payments/status/$reference/',
        );
        last = PaymentStatusResponse.fromJson(
          Map<String, dynamic>.from(response.data),
        );
        if (!_pendingStatuses.contains(last.status.toUpperCase())) {
          return last;
        }
      } catch (e) {
        AppLogger.instance.log(
          'Poll attempt ${i + 1} failed for reference $reference: $e',
        );
      }
      if (i < _maxPollAttempts - 1) {
        await Future.delayed(_pollInterval);
      }
    }
    // Return whatever we got last, even if still pending.
    return last ??
        PaymentStatusResponse(
          status: 'PENDING',
          respMessage: 'Still processing',
        );
  }

  // ─── helpers ──────────────────────────────────────────────────────

  /// Whether [status] is a terminal success.
  static bool isSuccess(String status) =>
      status.toUpperCase() == 'SUCCESS';

  /// Whether [status] is still in-flight.
  static bool isPending(String status) =>
      _pendingStatuses.contains(status.toUpperCase());

  /// Whether [status] is a terminal failure / cancellation.
  static bool isFailed(String status) {
    const failedStatuses = {'FAILED', 'CANCELLED', 'ABANDONED'};
    return failedStatuses.contains(status.toUpperCase());
  }
}
