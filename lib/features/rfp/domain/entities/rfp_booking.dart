import 'rfp_patch_config.dart';
import 'rfp_delivery.dart';

/// A confirmed RFP booking.
class RfpBooking {
  final String id;
  final String batchId;
  final int batchNumber;
  final String planId;
  final String planName;
  final String
  status; // 'active', 'completed', 'cancelled', 'PENDING_PAYMENT', etc.
  final DateTime startDate;
  final DateTime endDate;
  final List<RfpPatchConfig> patchConfigs;
  final double totalAmount;
  final double bookingAmountPaid;
  final double remainingAmount;
  final DateTime bookedAt;
  final RfpBookingAddress address;
  final bool bookingPaid;
  final bool remainingPaid;
  final List<String> deliveryDays;
  final String? merchantTransactionId;
  final String? checkoutUrl;
  final List<RfpDelivery> deliveries;
  final String? generalNote;
  final bool isLateBooking;
  final String? deliveryState;
  final DateTime? paymentExpiresAt;
  final double discountPercentage;
  final String? batchName;
  final String paymentType; // 'booking' or 'full'
  final String? cropCycleId;

  const RfpBooking({
    required this.id,
    required this.batchId,
    required this.batchNumber,
    required this.planId,
    required this.planName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.patchConfigs,
    required this.totalAmount,
    required this.bookingAmountPaid,
    required this.remainingAmount,
    required this.bookedAt,
    required this.address,
    this.batchName,
    this.bookingPaid = true,
    this.remainingPaid = false,
    this.deliveryDays = const ['Monday'],
    this.merchantTransactionId,
    this.checkoutUrl,
    this.deliveries = const [],
    this.generalNote,
    this.isLateBooking = false,
    this.deliveryState,
    this.paymentExpiresAt,
    this.discountPercentage = 0.0,
    this.paymentType = 'booking',
    this.cropCycleId,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isFullPayment => paymentType == 'full';

  RfpBooking copyWith({
    String? id,
    String? batchId,
    int? batchNumber,
    String? planId,
    String? planName,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    List<RfpPatchConfig>? patchConfigs,
    double? totalAmount,
    double? bookingAmountPaid,
    double? remainingAmount,
    DateTime? bookedAt,
    RfpBookingAddress? address,
    bool? bookingPaid,
    bool? remainingPaid,
    List<String>? deliveryDays,
    String? merchantTransactionId,
    String? checkoutUrl,
    List<RfpDelivery>? deliveries,
    String? generalNote,
    bool? isLateBooking,
    String? deliveryState,
    DateTime? paymentExpiresAt,
    double? discountPercentage,
    String? batchName,
    String? paymentType,
    String? cropCycleId,
  }) {
    return RfpBooking(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      batchNumber: batchNumber ?? this.batchNumber,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      patchConfigs: patchConfigs ?? this.patchConfigs,
      totalAmount: totalAmount ?? this.totalAmount,
      bookingAmountPaid: bookingAmountPaid ?? this.bookingAmountPaid,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      bookedAt: bookedAt ?? this.bookedAt,
      address: address ?? this.address,
      batchName: batchName ?? this.batchName,
      bookingPaid: bookingPaid ?? this.bookingPaid,
      remainingPaid: remainingPaid ?? this.remainingPaid,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      merchantTransactionId:
          merchantTransactionId ?? this.merchantTransactionId,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      deliveries: deliveries ?? this.deliveries,
      generalNote: generalNote ?? this.generalNote,
      isLateBooking: isLateBooking ?? this.isLateBooking,
      deliveryState: deliveryState ?? this.deliveryState,
      paymentExpiresAt: paymentExpiresAt ?? this.paymentExpiresAt,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      paymentType: paymentType ?? this.paymentType,
      cropCycleId: cropCycleId ?? this.cropCycleId,
    );
  }
}

/// Delivery address for an RFP booking.
class RfpBookingAddress {
  final String fullName;
  final String addressLine;
  final String city;
  final String pincode;
  final String phone;
  final String? state;
  final String? locality;

  const RfpBookingAddress({
    required this.fullName,
    required this.addressLine,
    required this.city,
    required this.pincode,
    required this.phone,
    this.state,
    this.locality,
  });
}
