import 'package:equatable/equatable.dart';
import '../../domain/entities/rfp_booking.dart';
import '../../domain/entities/rfp_pricing.dart';
import '../../domain/entities/user_address.dart';

enum CheckoutStatus {
  initial,
  loading,
  loaded,
  submitting,
  verifying,
  success,
  error,
}

class RfpCheckoutState extends Equatable {
  final CheckoutStatus status;
  final String? error;
  final RfpPricing? pricing;
  final String selectedPaymentMethod;
  final String fullName;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final String phone;
  final RfpBooking? booking;
  final int? addressId;
  final List<UserAddress> savedAddresses;
  final bool isLoadingAddresses;
  final String? merchantTransactionId;
  final String? checkoutUrl;
  final bool isVerifyingPayment;
  final bool verificationFailed;
  final Map<String, dynamic>? verificationResponse;
  final String paymentType; // 'booking' or 'full'

  const RfpCheckoutState({
    this.status = CheckoutStatus.initial,
    this.error,
    this.pricing,
    this.selectedPaymentMethod = 'upi',
    this.fullName = '',
    this.addressLine = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.phone = '',
    this.booking,
    this.addressId,
    this.savedAddresses = const [],
    this.isLoadingAddresses = false,
    this.merchantTransactionId,
    this.checkoutUrl,
    this.isVerifyingPayment = false,
    this.verificationFailed = false,
    this.verificationResponse,
    this.paymentType = 'booking',
  });

  bool get canSubmit =>
      fullName.isNotEmpty &&
      addressLine.isNotEmpty &&
      city.isNotEmpty &&
      pincode.length >= 6 &&
      phone.length >= 10;

  bool get isBookingPaid =>
      (booking?.bookingPaid ?? false) || status == CheckoutStatus.success;
  bool get isFullPaymentSelected => paymentType == 'full';
  double get amountDueNow =>
      isFullPaymentSelected
          ? (pricing?.finalPrice ?? 0.0)
          : (pricing?.bookingAmount ?? 0.0);

  RfpCheckoutState copyWith({
    CheckoutStatus? status,
    String? error,
    RfpPricing? pricing,
    String? selectedPaymentMethod,
    String? fullName,
    String? addressLine,
    String? city,
    String? state,
    String? pincode,
    String? phone,
    RfpBooking? booking,
    int? addressId,
    bool clearAddressId = false,
    List<UserAddress>? savedAddresses,
    bool? isLoadingAddresses,
    String? merchantTransactionId,
    String? checkoutUrl,
    bool? isVerifyingPayment,
    bool? verificationFailed,
    Map<String, dynamic>? verificationResponse,
    String? paymentType,
  }) {
    return RfpCheckoutState(
      status: status ?? this.status,
      error: error,
      pricing: pricing ?? this.pricing,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      fullName: fullName ?? this.fullName,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      phone: phone ?? this.phone,
      booking: booking ?? this.booking,
      addressId: clearAddressId ? null : (addressId ?? this.addressId),
      savedAddresses: savedAddresses ?? this.savedAddresses,
      isLoadingAddresses: isLoadingAddresses ?? this.isLoadingAddresses,
      merchantTransactionId:
          merchantTransactionId ?? this.merchantTransactionId,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      isVerifyingPayment: isVerifyingPayment ?? this.isVerifyingPayment,
      verificationFailed: verificationFailed ?? this.verificationFailed,
      verificationResponse: verificationResponse ?? this.verificationResponse,
      paymentType: paymentType ?? this.paymentType,
    );
  }

  @override
  List<Object?> get props => [
    status,
    error,
    pricing,
    selectedPaymentMethod,
    fullName,
    addressLine,
    city,
    state,
    pincode,
    phone,
    booking,
    addressId,
    savedAddresses,
    isLoadingAddresses,
    merchantTransactionId,
    checkoutUrl,
    isVerifyingPayment,
    verificationFailed,
    verificationResponse,
    paymentType,
  ];
}
