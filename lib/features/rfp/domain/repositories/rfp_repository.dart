import '../entities/rfp_location.dart';
import '../entities/rfp_batch.dart';
import '../entities/rfp_plan.dart';
import '../entities/rfp_patch.dart';
import '../entities/rfp_delivery.dart';
import '../entities/rfp_delivery_otp_status.dart';
import '../entities/rfp_booking.dart';
import '../entities/rfp_pricing.dart';
import '../entities/rfp_patch_config.dart';
import '../entities/user_address.dart';

/// Abstract repository interface for the RFP feature.
///
/// This lives in the domain layer and must be pure Dart —
/// no Flutter, Dio, GetIt, or other third-party imports.
/// Implementations live in data/repositories/.
abstract class RfpRepository {
  /// Fetch locations where RFP is available.
  Future<List<RfpLocation>> getAvailableLocations();

  /// Fetch farming batches for a location.
  Future<List<RfpBatch>> getBatches(String locationId);

  /// Fetch batch details by ID.
  Future<RfpBatch> getBatchDetails(String batchId);

  /// Fetch subscription plans for a batch.
  Future<List<RfpPlan>> getPlans(String batchId);

  /// Fetch patches available in a batch.
  Future<List<RfpPatch>> getPatches(String batchId);

  /// Fetch details for a specific patch.
  Future<RfpPatch> getPatchDetails(String patchId);

  /// Calculate pricing based on user selections.
  Future<RfpPricing> calculatePricing({
    required String planId,
    required List<RfpPatchConfig> patchConfigs,
    String? batchId,
  });

  /// Get the 12-week delivery schedule for a booking.
  Future<List<RfpDelivery>> getDeliverySchedule(String bookingId);

  /// Create a new booking.
  Future<RfpBooking> createBooking({
    required String batchId,
    required String planId,
    required String locationId,
    required List<RfpPatchConfig> patchConfigs,
    required String paymentMethod,
    required String fullName,
    required String addressLine,
    required String city,
    required String pincode,
    required String phone,
    String paymentType = 'booking',
    int? addressId,
  });

  /// Fetch details for an existing booking.
  Future<RfpBooking> getBookingDetails(String bookingId);

  /// Fetch upcoming deliveries for a booking.
  Future<List<RfpDelivery>> getUpcomingDeliveries(String bookingId);

  /// Fetch past delivery history for a booking.
  Future<List<RfpDelivery>> getDeliveryHistory(String bookingId);

  /// Get payment/billing summary for a booking.
  Future<RfpPricing> getPaymentSummary(String bookingId);

  /// Check if user has an active booking.
  Future<RfpBooking?> getActiveBooking();

  /// Fetch all subscriptions for the current user.
  Future<List<RfpBooking>> getMySubscriptions();

  /// Verify payment transaction status.
  Future<Map<String, dynamic>> verifyPayment(String merchantTransactionId);

  /// Initiate checkout session for remaining balance.
  Future<Map<String, dynamic>> payRemaining(int subscriptionId);

  /// Fetch saved delivery addresses for the user.
  Future<List<UserAddress>> getUserAddresses();

  /// Save a new delivery address for the user.
  Future<UserAddress> saveUserAddress(UserAddress address);

  /// Fetch active delivery OTP status for a delivery drop.
  Future<RfpDeliveryOtpStatus> getDeliveryOtpStatus(String deliveryId);
}
