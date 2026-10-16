import '../../domain/entities/rfp_location.dart';
import '../../domain/entities/rfp_batch.dart';
import '../../domain/entities/rfp_plan.dart';
import '../../domain/entities/rfp_patch.dart';
import '../../domain/entities/rfp_vegetable.dart';
import '../../domain/entities/rfp_delivery.dart';
import '../../domain/entities/rfp_booking.dart';
import '../../domain/entities/rfp_pricing.dart';
import '../../domain/entities/rfp_patch_config.dart';
import 'rfp_dummy_data.dart';

/// Mock data source with realistic dummy data for RFP.
class RfpMockDataSource {
  Future<T> _delayed<T>(T value, [int ms = 400]) =>
      Future.delayed(Duration(milliseconds: ms), () => value);

  // ─── Locations ───────────────────────────────────────────────────────────
  Future<List<RfpLocation>> getAvailableLocations() => _delayed([
    const RfpLocation(
      id: 'loc_01',
      name: 'Valley Sector 4',
      pincode: '122018',
      sector: 'Sector 4',
      isActive: true,
    ),
    const RfpLocation(
      id: 'loc_02',
      name: 'Green Valley Estate',
      pincode: '122019',
      sector: 'Sector 7',
      isActive: true,
    ),
    const RfpLocation(
      id: 'loc_03',
      name: 'Sunrise Farms',
      pincode: '122020',
      sector: 'Sector 12',
      isActive: false,
    ),
  ]);

  // ─── Batches ─────────────────────────────────────────────────────────────
  Future<List<RfpBatch>> getBatches(String locationId) => _delayed([
    RfpBatch(
      id: 'batch_12',
      batchNumber: 12,
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 12, 23),
      totalWeeks: 12,
      currentWeek: 4,
      status: 'active',
      seasonLabel: 'Autumn Harvest',
      progressPercent: 33.0,
    ),
    RfpBatch(
      id: 'batch_13',
      batchNumber: 13,
      startDate: DateTime(2027, 1, 1),
      endDate: DateTime(2027, 3, 25),
      totalWeeks: 12,
      currentWeek: 0,
      status: 'upcoming',
      seasonLabel: 'Winter Harvest',
      progressPercent: 0.0,
    ),
  ]);

  Future<RfpBatch> getBatchDetails(String batchId) async {
    final batches = await getBatches('loc_01');
    return batches.firstWhere((b) => b.id == batchId);
  }

  // ─── Plans ───────────────────────────────────────────────────────────────
  Future<List<RfpPlan>> getPlans(String batchId) => _delayed([
    const RfpPlan(
      id: 'plan_standard',
      name: 'Plan 1',
      tier: 'standard',
      description: 'Bi-weekly fresh box with seasonal staples.',
      totalPrice: 14999,
      bookingAmount: 1499,
      remainingAmount: 13500,
      features: ['Seasonal vegetables', 'Standard delivery', 'Basic variety'],
    ),
    const RfpPlan(
      id: 'plan_premium',
      name: 'Plan 2',
      tier: 'premium',
      description: 'Weekly harvest + exotic produce & priority yield.',
      totalPrice: 14999,
      originalPrice: 17999,
      bookingAmount: 1499,
      remainingAmount: 13500,
      discountPercent: 17.0,
      badge: 'Best Value',
      features: [
        'Full-season verified remote yield',
        'Exotic produce included',
        'Priority harvesting',
        'Premium packaging',
      ],
    ),
  ]);

  // ─── Patches ─────────────────────────────────────────────────────────────
  Future<List<RfpPatch>> getPatches(String batchId) => _delayed([
    const RfpPatch(
      id: 'patch_p1',
      label: 'P1',
      name: 'Agricultural Box',
      vegetables: RfpDummyData.p1Vegetables,
      maxExclusions: 3,
      availableWeights: [2.5, 5.0, 7.5],
      startingPrice: 3499,
    ),
    const RfpPatch(
      id: 'patch_p2',
      label: 'P2',
      name: 'Organic Greens',
      vegetables: RfpDummyData.p2Vegetables,
      maxExclusions: 2,
      availableWeights: [2.5, 5.0],
      startingPrice: 2999,
    ),
    const RfpPatch(
      id: 'patch_p3',
      label: 'P3',
      name: 'Root Harvest',
      vegetables: RfpDummyData.p3Vegetables,
      maxExclusions: 3,
      availableWeights: [2.5, 5.0, 7.5],
      startingPrice: 3299,
    ),
    const RfpPatch(
      id: 'patch_p4',
      label: 'P4',
      name: 'Exotic Garden',
      vegetables: RfpDummyData.p4Vegetables,
      maxExclusions: 2,
      availableWeights: [2.5, 5.0],
      startingPrice: 2799,
    ),
  ]);

  Future<RfpPatch> getPatchDetails(String patchId) async {
    final patches = await getPatches('batch_12');
    return patches.firstWhere((p) => p.id == patchId);
  }

  // ─── Vegetables ──────────────────────────────────────────────────────────
  Future<List<RfpVegetable>> getVegetables(String patchId) async {
    switch (patchId) {
      case 'patch_p1':
        return RfpDummyData.p1Vegetables;
      case 'patch_p2':
        return RfpDummyData.p2Vegetables;
      case 'patch_p3':
        return RfpDummyData.p3Vegetables;
      case 'patch_p4':
        return RfpDummyData.p4Vegetables;
      default:
        return RfpDummyData.p1Vegetables;
    }
  }

  // ─── Pricing ─────────────────────────────────────────────────────────────
  Future<RfpPricing> calculatePricing({
    required String planId,
    required List<RfpPatchConfig> patchConfigs,
    String? batchId,
  }) {
    final isPremium = planId == 'plan_premium';
    final basePrice = isPremium ? 29998.0 : 14999.0;
    final discount = isPremium ? 2999.0 : 0.0;
    final finalPrice = basePrice - discount;
    const booking = 1499.0;
    return _delayed(
      RfpPricing(
        basePrice: basePrice,
        discountLabel: isPremium ? 'Seasonal Discount (Early Bird)' : null,
        discountAmount: discount,
        finalPrice: finalPrice,
        bookingAmount: booking,
        remainingAmount: finalPrice - booking,
      ),
    );
  }

  // ─── Delivery Schedule ───────────────────────────────────────────────────
  Future<List<RfpDelivery>> getDeliverySchedule(String bookingId) {
    return _delayed(RfpDummyData.generateDeliverySchedule());
  }

  Future<List<RfpDelivery>> getUpcomingDeliveries(String bookingId) async {
    final all = await getDeliverySchedule(bookingId);
    return all.where((d) => d.status == 'upcoming').toList();
  }

  Future<List<RfpDelivery>> getDeliveryHistory(String bookingId) async {
    final all = await getDeliverySchedule(bookingId);
    return all.where((d) => d.status == 'delivered').toList();
  }

  // ─── Bookings ────────────────────────────────────────────────────────────
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
  }) {
    final booking = RfpBooking(
      id: 'BKG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      batchId: batchId,
      batchNumber: 12,
      planId: planId,
      planName:
          planId == 'plan_premium' ? 'Plan 2 (Premium)' : 'Plan 1 (Standard)',
      status: 'active',
      paymentType: paymentType,
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 12, 23),
      patchConfigs: patchConfigs,
      totalAmount: 14999,
      bookingAmountPaid: 1499,
      remainingAmount: 13500,
      bookedAt: DateTime.now(),
      address: RfpBookingAddress(
        fullName: fullName,
        addressLine: addressLine,
        city: city,
        pincode: pincode,
        phone: phone,
      ),
    );
    return _delayed(booking);
  }

  Future<RfpBooking> getBookingDetails(String bookingId) => _delayed(
    RfpBooking(
      id: bookingId,
      batchId: 'batch_12',
      batchNumber: 12,
      planId: 'plan_premium',
      planName: 'Plan 2 (Premium)',
      status: 'active',
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 12, 23),
      patchConfigs: const [
        RfpPatchConfig(
          patchId: 'patch_p1',
          patchLabel: 'P1',
          excludedVegetableIds: ['v06'],
          selectedWeight: 7.5,
          deliveryFrequency: 'once_a_week',
        ),
        RfpPatchConfig(
          patchId: 'patch_p2',
          patchLabel: 'P2',
          excludedVegetableIds: [],
          selectedWeight: 5.0,
          deliveryFrequency: 'once_a_week',
        ),
      ],
      totalAmount: 14999,
      bookingAmountPaid: 1499,
      remainingAmount: 13500,
      bookedAt: DateTime(2026, 9, 15),
      address: const RfpBookingAddress(
        fullName: 'Aarav Sharma',
        addressLine: 'Villa 12B, Greenfield Expressway',
        city: 'Gurugram',
        pincode: '122018',
        phone: '+91 98765 43210',
      ),
    ),
  );

  Future<RfpBooking?> getActiveBooking() async {
    return getBookingDetails('BKG-2026-001');
  }

  Future<RfpPricing> getPaymentSummary(String bookingId) {
    return _delayed(
      const RfpPricing(
        basePrice: 16999,
        discountAmount: 2000,
        discountLabel: 'Early Bird Discount (12%)',
        finalPrice: 14999,
        bookingAmount: 1499,
        remainingAmount: 13500,
      ),
    );
  }
}
