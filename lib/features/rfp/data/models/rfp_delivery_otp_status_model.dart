import '../../domain/entities/rfp_delivery_otp_status.dart';

class RfpDeliveryOtpStatusModel extends RfpDeliveryOtpStatus {
  const RfpDeliveryOtpStatusModel({
    required super.state,
    super.otp,
    super.expiresAt,
  });

  factory RfpDeliveryOtpStatusModel.fromJson(Map<String, dynamic> json) {
    return RfpDeliveryOtpStatusModel(
      state: json['state'] as String? ?? 'NO_ACTIVE_OTP',
      otp: json['otp']?.toString(),
      expiresAt:
          json['expires_at'] != null
              ? DateTime.tryParse(json['expires_at'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'otp': otp,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}
