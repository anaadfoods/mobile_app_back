import '../../domain/entities/rfp_location.dart';
import '../../domain/entities/rfp_batch.dart';
import '../../domain/entities/rfp_plan.dart';
import '../../domain/entities/rfp_patch.dart';
import '../../domain/entities/rfp_delivery.dart';
import '../../domain/entities/rfp_delivery_otp_status.dart';
import '../../domain/entities/rfp_booking.dart';
import '../../domain/entities/rfp_pricing.dart';
import '../../domain/entities/rfp_patch_config.dart';
import '../../domain/entities/user_address.dart';
import '../../domain/repositories/rfp_repository.dart';
import '../datasources/rfp_remote_data_source.dart';
import '../datasources/rfp_mock_data_source.dart';
import '../models/rfp_batch_model.dart';
import '../models/rfp_booking_model.dart';
import '../models/user_address_model.dart';
import 'rfp_payload_builder.dart';

/// Implementation of [RfpRepository] backed by [RfpRemoteDataSource].
class RfpRepositoryImpl implements RfpRepository {
  final RfpRemoteDataSource _remoteDataSource;
  final RfpMockDataSource? _mockDataSource;

  List<RfpBatchModel> _cachedBatches = [];
  RfpBooking? _cachedActiveBooking;

  RfpRepositoryImpl(this._remoteDataSource, [this._mockDataSource]);

  @override
  Future<List<RfpLocation>> getAvailableLocations() async =>
      _mockDataSource != null
          ? _mockDataSource.getAvailableLocations()
          : const [
            RfpLocation(
              id: 'loc_01',
              name: 'Valley Sector 4',
              pincode: '122018',
              sector: 'Sector 4',
              isActive: true,
            ),
            RfpLocation(
              id: 'loc_02',
              name: 'Green Valley Estate',
              pincode: '122019',
              sector: 'Sector 7',
              isActive: true,
            ),
          ];

  @override
  Future<List<RfpBatch>> getBatches(String locationId) async {
    try {
      final batches = await _remoteDataSource.getActiveBatches();
      _cachedBatches = batches;
      if (batches.isNotEmpty) return List<RfpBatch>.from(batches);
    } catch (_) {
      if (_mockDataSource != null) {
        return _mockDataSource.getBatches(locationId);
      }
      rethrow;
    }
    return _mockDataSource != null
        ? _mockDataSource.getBatches(locationId)
        : List<RfpBatch>.from(_cachedBatches);
  }

  Future<RfpBatchModel?> _fetchAndCacheBatch(String batchId) async {
    final intId = int.tryParse(batchId);
    if (intId != null) {
      try {
        final detailed = await _remoteDataSource.getBatchDetail(intId);
        final index = _cachedBatches.indexWhere((b) => b.id == batchId);
        if (index != -1) {
          _cachedBatches[index] = detailed;
        } else {
          _cachedBatches.add(detailed);
        }
        return detailed;
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<RfpBatch> getBatchDetails(String batchId) async {
    final detailed = await _fetchAndCacheBatch(batchId);
    if (detailed != null) return detailed;

    if (_cachedBatches.isEmpty) {
      await getBatches('default');
    }
    final match = _cachedBatches.where((b) => b.id == batchId);
    if (match.isNotEmpty) return match.first;
    if (_cachedBatches.isNotEmpty) return _cachedBatches.first;
    if (_mockDataSource != null) {
      return _mockDataSource.getBatchDetails(batchId);
    }
    throw Exception('Batch not found: $batchId');
  }

  @override
  Future<List<RfpPlan>> getPlans(String batchId) async {
    final match = _cachedBatches.where((b) => b.id == batchId);
    final cached = match.isNotEmpty ? match.first : null;
    if (cached != null && cached.plans.isNotEmpty) {
      return List<RfpPlan>.from(cached.plans);
    }

    final detailed = await _fetchAndCacheBatch(batchId);
    if (detailed != null && detailed.plans.isNotEmpty) {
      return List<RfpPlan>.from(detailed.plans);
    }

    if (_cachedBatches.isEmpty) {
      await getBatches('default');
    }
    final afterMatch = _cachedBatches.where((b) => b.id == batchId);
    final batch =
        afterMatch.isNotEmpty
            ? afterMatch.first
            : (_cachedBatches.isNotEmpty ? _cachedBatches.first : null);

    if (batch != null && batch.plans.isNotEmpty) {
      return List<RfpPlan>.from(batch.plans);
    }
    if (_mockDataSource != null) {
      return _mockDataSource.getPlans(batchId);
    }
    return const [];
  }

  @override
  Future<List<RfpPatch>> getPatches(String batchId) async {
    if (_cachedBatches.isEmpty) {
      await getBatches('default');
    }
    final match = _cachedBatches.where((b) => b.id == batchId);
    var batch =
        match.isNotEmpty
            ? match.first
            : (_cachedBatches.isNotEmpty ? _cachedBatches.first : null);

    if (batch == null || batch.plans.isEmpty) {
      final detailed = await _fetchAndCacheBatch(batchId);
      if (detailed != null) batch = detailed;
    }

    if (batch != null && batch.plans.isNotEmpty) {
      // Map each plan to an agricultural patch plot
      return batch.plans.map((p) {
        final codeStr = p.code ?? 'P1';
        final weights =
            p.pricings.isNotEmpty
                ? (p.pricings.map((pr) => pr.weightKg).toSet().toList()..sort())
                : const <double>[];

        final startingPrice =
            p.pricings.isNotEmpty ? p.pricings.first.pricePerDelivery : 0.0;

        final vegCount = p.availableVegetables.length;
        final maxExcl =
            (vegCount > p.selectionLimit && p.selectionLimit > 0)
                ? (vegCount - p.selectionLimit)
                : 3;

        return RfpPatch(
          id: p.id,
          label: codeStr.startsWith('P') ? codeStr : 'P$codeStr',
          name: p.name,
          vegetables: p.availableVegetables,
          maxExclusions: maxExcl,
          availableWeights: weights,
          startingPrice: startingPrice,
        );
      }).toList();
    }

    if (_mockDataSource != null) {
      return _mockDataSource.getPatches(batchId);
    }
    return const [];
  }

  @override
  Future<RfpPatch> getPatchDetails(String patchId) async {
    final patches = await getPatches('default');
    final match = patches.where((p) => p.id == patchId);
    if (match.isNotEmpty) return match.first;
    if (_mockDataSource != null) {
      return _mockDataSource.getPatchDetails(patchId);
    }
    throw Exception('Patch not found: $patchId');
  }

  @override
  Future<RfpPricing> calculatePricing({
    required String planId,
    required List<RfpPatchConfig> patchConfigs,
    String? batchId,
  }) async {
    try {
      final bId = RfpPayloadBuilder.findBatchId(
        planId,
        _cachedBatches,
        batchId,
      );
      final days = RfpPayloadBuilder.buildDeliveryDays(patchConfigs);
      final plans = RfpPayloadBuilder.buildPlansPayload(
        planId,
        patchConfigs,
        _cachedBatches,
      );

      return await _remoteDataSource.calculateSubscription(
        batchId: bId,
        deliveryDays: days,
        plans: plans,
      );
    } catch (_) {
      if (_mockDataSource != null) {
        return _mockDataSource.calculatePricing(
          planId: planId,
          patchConfigs: patchConfigs,
          batchId: batchId,
        );
      }
      rethrow;
    }
  }

  @override
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
  }) async {
    try {
      final intBatchId = int.tryParse(batchId) ?? 1;
      final days = RfpPayloadBuilder.buildDeliveryDays(patchConfigs);
      final plans = RfpPayloadBuilder.buildPlansPayload(
        planId,
        patchConfigs,
        _cachedBatches,
      );

      final result = await _remoteDataSource.bookSubscription(
        batchId: intBatchId,
        deliveryDays: days,
        plans: plans,
        paymentType: paymentType,
        addressId: addressId,
      );

      if (result.containsKey('subscription') && result['subscription'] is Map) {
        final booking = RfpBookingModel.fromJson(
          result['subscription'] as Map<String, dynamic>,
        );
        _cachedActiveBooking = booking;
        return booking;
      }

      final subId =
          result['subscription_id']?.toString() ??
          result['rfp_subscription_id']?.toString() ??
          'BKG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final bAmt =
          double.tryParse(result['amount']?.toString() ?? '') ??
          double.tryParse(result['pay_now']?.toString() ?? '') ??
          0.0;
      final tAmt = double.tryParse(result['total']?.toString() ?? '') ?? bAmt;
      final rAmt =
          double.tryParse(result['pay_later']?.toString() ?? '') ??
          (tAmt > bAmt ? tAmt - bAmt : 0.0);

      final booking = RfpBooking(
        id: subId,
        batchId: batchId,
        batchNumber: intBatchId,
        planId: planId,
        planName: 'RFP Subscription',
        status: 'pending_payment',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 84)),
        patchConfigs: patchConfigs,
        totalAmount: tAmt,
        bookingAmountPaid: bAmt,
        remainingAmount: rAmt,
        bookedAt: DateTime.now(),
        address: RfpBookingAddress(
          fullName: fullName,
          addressLine: addressLine,
          city: city,
          pincode: pincode,
          phone: phone,
        ),
        bookingPaid: false,
        remainingPaid: false,
        deliveryDays: days,
        paymentType: paymentType,
        merchantTransactionId: result['merchant_transaction_id'] as String?,
        checkoutUrl: result['checkout_url'] as String?,
        paymentExpiresAt:
            result['payment_expires_at'] != null
                ? DateTime.tryParse(result['payment_expires_at'].toString())
                : null,
      );

      _cachedActiveBooking = booking;
      return booking;
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('ALREADY_BOOKED') ||
          errStr.contains('BATCH_FULL') ||
          errStr.contains('PLAN_FULL') ||
          errStr.contains('INVALID_SELECTION')) {
        rethrow;
      }
      if (_mockDataSource != null) {
        return _mockDataSource.createBooking(
          batchId: batchId,
          planId: planId,
          locationId: locationId,
          patchConfigs: patchConfigs,
          paymentMethod: paymentMethod,
          fullName: fullName,
          addressLine: addressLine,
          city: city,
          pincode: pincode,
          phone: phone,
          paymentType: paymentType,
        );
      }
      rethrow;
    }
  }

  @override
  Future<RfpBooking?> getActiveBooking() async {
    try {
      final subs = await _remoteDataSource.getMySubscriptions();
      if (subs.isNotEmpty) {
        _cachedActiveBooking = subs.first;
        return subs.first;
      }
    } catch (_) {}
    return _cachedActiveBooking ?? _mockDataSource?.getActiveBooking();
  }

  @override
  Future<List<RfpBooking>> getMySubscriptions() async {
    try {
      final subs = await _remoteDataSource.getMySubscriptions();
      if (subs.isNotEmpty) _cachedActiveBooking = subs.first;
      return List<RfpBooking>.from(subs);
    } catch (_) {
      if (_mockDataSource != null) {
        final active = await _mockDataSource.getActiveBooking();
        return active != null ? [active] : const [];
      }
      rethrow;
    }
  }

  @override
  Future<RfpBooking> getBookingDetails(String bookingId) async {
    final active = await getActiveBooking();
    if (active != null && active.id == bookingId) return active;
    if (_mockDataSource != null) {
      return _mockDataSource.getBookingDetails(bookingId);
    }
    throw Exception('Booking not found: $bookingId');
  }

  @override
  Future<List<RfpDelivery>> getDeliverySchedule(String bookingId) async {
    final active = await getActiveBooking();
    if (active != null && active.deliveries.isNotEmpty) {
      return active.deliveries;
    }
    return _mockDataSource?.getDeliverySchedule(bookingId) ?? const [];
  }

  @override
  Future<List<RfpDelivery>> getUpcomingDeliveries(String bookingId) async =>
      (await getDeliverySchedule(bookingId))
          .where(
            (d) =>
                d.status == 'upcoming' ||
                d.status == 'scheduled' ||
                d.status == 'out_for_delivery',
          )
          .toList();

  @override
  Future<List<RfpDelivery>> getDeliveryHistory(String bookingId) async =>
      (await getDeliverySchedule(
        bookingId,
      )).where((d) => d.status == 'delivered').toList();

  @override
  Future<RfpPricing> getPaymentSummary(String bookingId) async {
    final active = await getActiveBooking();
    if (active != null) {
      return RfpPricing(
        basePrice: active.totalAmount,
        discountAmount: 0.0,
        finalPrice: active.totalAmount,
        bookingAmount: active.bookingAmountPaid,
        remainingAmount: active.remainingAmount,
      );
    }
    if (_mockDataSource != null) {
      return _mockDataSource.getPaymentSummary(bookingId);
    }
    throw Exception('Booking not found');
  }

  @override
  Future<Map<String, dynamic>> verifyPayment(String merchantTransactionId) =>
      _remoteDataSource.verifyPayment(
        merchantTransactionId: merchantTransactionId,
      );

  @override
  Future<Map<String, dynamic>> payRemaining(int subscriptionId) =>
      _remoteDataSource.payRemaining(subscriptionId: subscriptionId);

  @override
  Future<List<UserAddress>> getUserAddresses() async {
    try {
      return List<UserAddress>.from(await _remoteDataSource.getUserAddresses());
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<UserAddress> saveUserAddress(UserAddress address) => _remoteDataSource
      .createUserAddress(UserAddressModel.fromEntity(address).toJson());

  @override
  Future<RfpDeliveryOtpStatus> getDeliveryOtpStatus(String deliveryId) async {
    final cleanId = deliveryId.replaceAll(RegExp(r'[^0-9]'), '');
    final intId = int.tryParse(cleanId);
    if (intId != null) {
      try {
        return await _remoteDataSource.getDeliveryOtpStatus(intId);
      } catch (_) {}
    }
    return const RfpDeliveryOtpStatus(state: 'NO_ACTIVE_OTP');
  }
}
