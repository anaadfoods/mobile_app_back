import '../../domain/entities/rfp_plan.dart';
import 'rfp_vegetable_model.dart';
import 'rfp_plan_pricing_model.dart';

class RfpPlanModel extends RfpPlan {
  const RfpPlanModel({
    required super.id,
    required super.name,
    required super.tier,
    required super.description,
    required super.totalPrice,
    super.originalPrice,
    required super.bookingAmount,
    required super.remainingAmount,
    super.discountPercent,
    super.badge,
    required super.features,
    super.code,
    super.selectionLimit,
    super.availableVegetables,
    super.pricings,
    super.imageUrl,
    super.maxDeselectableCount,
    super.maxFamilies,
    super.bookedFamilyCount,
    super.slotsRemaining,
    super.isFull,
    super.planStatus,
  });

  factory RfpPlanModel.fromJson(Map<String, dynamic> json) {
    final pricingsList =
        (json['pricings'] as List<dynamic>?)
            ?.map(
              (e) => RfpPlanPricingModel.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        const <RfpPlanPricingModel>[];

    final vegetablesList =
        (json['available_vegetables'] as List<dynamic>?)
            ?.map((e) => RfpVegetableModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <RfpVegetableModel>[];

    final selLimit = json['selection_limit'] as int? ?? 5;
    final codeVal = json['code'] as String?;
    final imageUrl = json['image'] as String?;
    final maxDeselect = json['max_deselectable_count'] as int? ?? 0;

    // Compute prices from pricings if not directly provided
    double calculatedTotal = (json['total_price'] as num?)?.toDouble() ?? 0.0;
    double calculatedBooking =
        (json['booking_amount'] as num?)?.toDouble() ?? 0.0;
    double calculatedRemaining =
        (json['remaining_amount'] as num?)?.toDouble() ?? 0.0;

    if (calculatedTotal == 0.0 && pricingsList.isNotEmpty) {
      final first = pricingsList.first;
      final perDrop = first.pricePerDelivery;
      calculatedTotal = perDrop * 12 * first.frequencyPerWeek;
      calculatedBooking = perDrop * 2 * first.frequencyPerWeek;
      calculatedRemaining = calculatedTotal - calculatedBooking;
    }

    final featuresList =
        (json['features'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [
          '$selLimit Vegetables Per Delivery',
          if (pricingsList.isNotEmpty)
            '${pricingsList.length} Variant Sizes Available'
          else
            'Weekly Farm Harvest',
          'Direct Organic Farm Gate',
        ];

    String? derivedBadge = json['badge'] as String?;
    if (derivedBadge == null) {
      if (codeVal == 'A') {
        derivedBadge = 'CURATED STAPLE';
      } else if (codeVal == 'B') {
        derivedBadge = 'HEIRLOOM CRAFT';
      } else if (codeVal == 'C') {
        derivedBadge = 'EARTH & HEARTH';
      } else if (codeVal == 'D') {
        derivedBadge = 'SPICES & HERBS';
      }
    }

    final derivedTier =
        json['tier'] as String? ??
        ((codeVal == 'A' || codeVal == 'B') ? 'premium' : 'standard');

    final maxFam = json['max_families'] as int? ?? 50;
    final bookedFam = json['booked_family_count'] as int? ?? 0;
    final remSlots =
        json['slots_remaining'] as int? ??
        (maxFam - bookedFam > 0 ? maxFam - bookedFam : 0);
    final full = json['is_full'] as bool? ?? (bookedFam >= maxFam);
    final pStatus = json['status'] as String? ?? (full ? 'FULL' : 'AVAILABLE');

    return RfpPlanModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      tier: derivedTier,
      description: json['description'] as String? ?? '',
      totalPrice: calculatedTotal,
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      bookingAmount: calculatedBooking,
      remainingAmount: calculatedRemaining,
      discountPercent: (json['discount_percent'] as num?)?.toDouble(),
      badge: derivedBadge,
      features: featuresList,
      code: codeVal,
      selectionLimit: selLimit,
      availableVegetables: vegetablesList,
      pricings: pricingsList,
      imageUrl: imageUrl,
      maxDeselectableCount: maxDeselect,
      maxFamilies: maxFam,
      bookedFamilyCount: bookedFam,
      slotsRemaining: remSlots,
      isFull: full,
      planStatus: pStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'tier': tier,
      'description': description,
      'total_price': totalPrice,
      'original_price': originalPrice,
      'booking_amount': bookingAmount,
      'remaining_amount': remainingAmount,
      'discount_percent': discountPercent,
      'badge': badge,
      'features': features,
      'selection_limit': selectionLimit,
      'image': imageUrl,
      'max_deselectable_count': maxDeselectableCount,
      'max_families': maxFamilies,
      'booked_family_count': bookedFamilyCount,
      'slots_remaining': slotsRemaining,
      'is_full': isFull,
      'status': planStatus,
      'available_vegetables':
          availableVegetables
              .map((v) => RfpVegetableModel.fromEntity(v).toJson())
              .toList(),
      'pricings':
          pricings
              .map((p) => RfpPlanPricingModel.fromEntity(p).toJson())
              .toList(),
    };
  }

  factory RfpPlanModel.fromEntity(RfpPlan entity) {
    return RfpPlanModel(
      id: entity.id,
      name: entity.name,
      tier: entity.tier,
      description: entity.description,
      totalPrice: entity.totalPrice,
      originalPrice: entity.originalPrice,
      bookingAmount: entity.bookingAmount,
      remainingAmount: entity.remainingAmount,
      discountPercent: entity.discountPercent,
      badge: entity.badge,
      features: entity.features,
      code: entity.code,
      selectionLimit: entity.selectionLimit,
      availableVegetables: entity.availableVegetables,
      pricings: entity.pricings,
      imageUrl: entity.imageUrl,
      maxDeselectableCount: entity.maxDeselectableCount,
      maxFamilies: entity.maxFamilies,
      bookedFamilyCount: entity.bookedFamilyCount,
      slotsRemaining: entity.slotsRemaining,
      isFull: entity.isFull,
      planStatus: entity.planStatus,
    );
  }
}
