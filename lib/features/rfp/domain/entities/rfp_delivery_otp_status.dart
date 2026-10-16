/// Domain entity representing the active OTP state for an RFP delivery.
///
/// Pure Dart — no Flutter imports.
class RfpDeliveryOtpStatus {
  /// Possible states: 'ACTIVE', 'NO_ACTIVE_OTP', 'NOT_OUT_FOR_DELIVERY'
  final String state;
  final String? otp;
  final DateTime? expiresAt;

  const RfpDeliveryOtpStatus({required this.state, this.otp, this.expiresAt});

  bool get isActive =>
      state.toUpperCase() == 'ACTIVE' &&
      otp != null &&
      otp!.isNotEmpty &&
      !isExpired;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
