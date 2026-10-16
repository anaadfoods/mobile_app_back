import '../../domain/entities/rfp_booking.dart';
import '../../domain/entities/rfp_delivery.dart';
import '../../domain/entities/rfp_patch_config.dart';
import 'rfp_patch_config_model.dart';
import 'rfp_delivery_model.dart';

class RfpBookingAddressModel extends RfpBookingAddress {
  const RfpBookingAddressModel({
    required super.fullName,
    required super.addressLine,
    required super.city,
    required super.pincode,
    required super.phone,
    super.state,
    super.locality,
  });

  factory RfpBookingAddressModel.fromJson(Map<String, dynamic> json) {
    return RfpBookingAddressModel(
      fullName: json['full_name'] as String? ?? 'Anaad Customer',
      addressLine: json['address_line'] as String? ?? '',
      city: json['city'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      state: json['state'] as String? ?? '',
      locality: json['locality'] as String? ?? json['sublocality'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'address_line': addressLine,
      'city': city,
      'pincode': pincode,
      'phone': phone,
      'state': state,
      if (locality != null) 'locality': locality,
    };
  }

  factory RfpBookingAddressModel.fromEntity(RfpBookingAddress entity) {
    return RfpBookingAddressModel(
      fullName: entity.fullName,
      addressLine: entity.addressLine,
      city: entity.city,
      pincode: entity.pincode,
      phone: entity.phone,
      state: entity.state,
      locality: entity.locality,
    );
  }
}

class RfpBookingModel extends RfpBooking {
  const RfpBookingModel({
    required super.id,
    required super.batchId,
    required super.batchNumber,
    required super.planId,
    required super.planName,
    required super.status,
    required super.startDate,
    required super.endDate,
    required super.patchConfigs,
    required super.totalAmount,
    required super.bookingAmountPaid,
    required super.remainingAmount,
    required super.bookedAt,
    required super.address,
    super.bookingPaid,
    super.remainingPaid,
    super.deliveryDays,
    super.merchantTransactionId,
    super.checkoutUrl,
    super.deliveries,
    super.generalNote,
    super.isLateBooking,
    super.deliveryState,
    super.paymentExpiresAt,
    super.discountPercentage,
    super.batchName,
    super.paymentType,
    super.cropCycleId,
  });

  factory RfpBookingModel.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    // Backend RFPSubscriptionSerializer format
    if (json.containsKey('batch_name') ||
        json.containsKey('subscription_plans') ||
        json.containsKey('delivery_recipient_name')) {
      final bkgPaid = json['booking_paid'] as bool? ?? true;
      final remPaid = json['remaining_paid'] as bool? ?? false;
      final isLate = json['is_late_booking'] as bool? ?? false;
      final discPercent =
          double.tryParse(json['discount_percentage']?.toString() ?? '') ?? 0.0;
      final paymentExpires =
          json['payment_expires_at'] != null
              ? DateTime.tryParse(json['payment_expires_at'] as String)
              : null;
      final delivState = json['delivery_state'] as String?;
      final totalBkg = parseD(json['total_booking_amount']);
      final totalRem = parseD(json['total_remaining_amount']);
      final total = totalBkg + totalRem;
      DateTime bookedAtDate;
      final rawCreatedAt = json['created_at'] as String? ?? '';
      final parsedIso = DateTime.tryParse(rawCreatedAt);
      if (parsedIso != null) {
        bookedAtDate = parsedIso;
      } else {
        try {
          final parts = rawCreatedAt.split(' ');
          final dateParts = parts[0].split('-');
          final timeParts = parts.length > 1 ? parts[1].split(':') : ['0', '0'];
          final day = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final year = int.parse(dateParts[2]);
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          bookedAtDate = DateTime(year, month, day, hour, minute);
        } catch (_) {
          bookedAtDate = DateTime.now();
        }
      }

      final deliveryDaysList =
          (json['delivery_days'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Monday'];

      final subPlans = json['subscription_plans'] as List<dynamic>? ?? const [];
      final configs = <RfpPatchConfig>[];
      String computedPlanName = json['batch_name'] as String? ?? 'RFP Plan';

      if (subPlans.isNotEmpty) {
        final planNames =
            subPlans
                .map((p) => p['plan_name']?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toSet()
                .toList();
        if (planNames.isNotEmpty) {
          computedPlanName = planNames.join(' + ');
        }

        for (int i = 0; i < subPlans.length; i++) {
          final sp = subPlans[i] as Map<String, dynamic>;
          final pricing = sp['plan_pricing'] as Map<String, dynamic>?;
          final weight = parseD(pricing?['weight_kg'], 2.5);
          final label = pricing?['variant_name'] as String? ?? 'P${i + 1}';

          configs.add(
            RfpPatchConfig(
              patchId: sp['id']?.toString() ?? 'plan_$i',
              patchLabel: label,
              excludedVegetableIds: const [],
              selectedWeight: weight,
              deliveryFrequency:
                  deliveryDaysList.length >= 2 ? 'twice_a_week' : 'once_a_week',
            ),
          );
        }
      }

      final deliveriesList =
          (json['deliveries'] as List<dynamic>?)?.asMap().entries.map((entry) {
            final dModel = RfpDeliveryModel.fromJson(
              entry.value as Map<String, dynamic>,
              batchStartDate: bookedAtDate,
              fallbackWeekNumber: (entry.key ~/ deliveryDaysList.length) + 1,
            );
            if (dModel.patches.isEmpty && configs.isNotEmpty) {
              return RfpDeliveryModel(
                id: dModel.id,
                weekNumber: dModel.weekNumber,
                date: dModel.date,
                dayOfWeek: dModel.dayOfWeek,
                status: dModel.status,
                patches:
                    configs
                        .map(
                          (c) => RfpDeliveryPatch(
                            patchId: c.patchId,
                            patchLabel: c.patchLabel,
                            weightKg: c.selectedWeight,
                          ),
                        )
                        .toList(),
                description: dModel.description,
                trackingLabel: dModel.trackingLabel,
                cancellationReason: dModel.cancellationReason,
              );
            }
            return dModel;
          }).toList() ??
          const <RfpDeliveryModel>[];

      final addressModel =
          json['address'] is Map
              ? RfpBookingAddressModel.fromJson(
                json['address'] as Map<String, dynamic>,
              )
              : RfpBookingAddressModel(
                fullName:
                    (json['delivery_recipient_name'] as String?)?.isNotEmpty ==
                            true
                        ? json['delivery_recipient_name'] as String
                        : 'Anaad Customer',
                addressLine: json['delivery_address_line'] as String? ?? '',
                city: json['delivery_city'] as String? ?? '',
                pincode: json['delivery_pincode'] as String? ?? '',
                phone: json['delivery_phone'] as String? ?? '',
                state: json['delivery_state'] as String? ?? '',
                locality:
                    json['delivery_locality'] as String? ??
                    json['locality'] as String?,
              );

      return RfpBookingModel(
        id: json['id']?.toString() ?? '',
        batchId:
            json['batch_id']?.toString() ?? json['batch']?.toString() ?? '1',
        batchNumber:
            json['batch_number'] as int? ??
            (json['batch'] is int
                ? json['batch'] as int
                : int.tryParse(json['batch']?.toString() ?? '') ?? 1),
        planId:
            subPlans.isNotEmpty ? subPlans.first['id']?.toString() ?? '1' : '1',
        planName: computedPlanName,
        status: (json['status'] as String? ?? 'active').toLowerCase(),
        startDate: bookedAtDate,
        endDate: bookedAtDate.add(const Duration(days: 84)),
        patchConfigs: configs,
        totalAmount: total,
        bookingAmountPaid: bkgPaid ? totalBkg : 0.0,
        remainingAmount: remPaid ? 0.0 : totalRem,
        bookedAt: bookedAtDate,
        address: addressModel,
        bookingPaid: bkgPaid,
        remainingPaid: remPaid,
        deliveryDays: deliveryDaysList,
        deliveries: deliveriesList,
        generalNote: json['general_note'] as String?,
        isLateBooking: isLate,
        deliveryState: delivState,
        paymentExpiresAt: paymentExpires,
        discountPercentage: discPercent,
        batchName: json['batch_name'] as String?,
        paymentType: json['payment_type'] as String? ?? 'booking',
        cropCycleId: json['crop_cycle_id'] as String?,
      );
    }

    // Legacy / Mock format
    final bkgPaid = json['booking_paid'] as bool? ?? true;
    final remPaid = json['remaining_paid'] as bool? ?? false;
    final delivDays =
        (json['delivery_days'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const ['Monday'];
    final delivList =
        (json['deliveries'] as List<dynamic>?)
            ?.map((e) => RfpDeliveryModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <RfpDeliveryModel>[];

    return RfpBookingModel(
      id: json['id']?.toString() ?? '',
      batchId: json['batch_id']?.toString() ?? json['batch']?.toString() ?? '',
      batchNumber:
          json['batch_number'] as int? ??
          (json['batch'] is int
              ? json['batch'] as int
              : int.tryParse(json['batch']?.toString() ?? '') ?? 1),
      planId: json['plan_id']?.toString() ?? '',
      planName: json['plan_name']?.toString() ?? 'RFP Plan',
      status: json['status']?.toString() ?? 'active',
      startDate:
          DateTime.tryParse(json['start_date'] as String? ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['end_date'] as String? ?? '') ??
          DateTime.now(),
      patchConfigs:
          (json['patch_configs'] as List<dynamic>?)
              ?.map(
                (e) => RfpPatchConfigModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      totalAmount: parseD(json['total_amount']),
      bookingAmountPaid: parseD(json['booking_amount_paid']),
      remainingAmount: parseD(json['remaining_amount']),
      bookedAt:
          DateTime.tryParse(
            json['booked_at'] as String? ?? json['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
      address: RfpBookingAddressModel.fromJson(
        json['address'] as Map<String, dynamic>? ?? {},
      ),
      bookingPaid: bkgPaid,
      remainingPaid: remPaid,
      deliveryDays: delivDays,
      deliveries: delivList,
      paymentType: json['payment_type'] as String? ?? 'booking',
      cropCycleId: json['crop_cycle_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'batch_number': batchNumber,
      'plan_id': planId,
      'plan_name': planName,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'patch_configs':
          patchConfigs
              .map((p) => RfpPatchConfigModel.fromEntity(p).toJson())
              .toList(),
      'total_amount': totalAmount,
      'booking_amount_paid': bookingAmountPaid,
      'remaining_amount': remainingAmount,
      'booked_at': bookedAt.toIso8601String(),
      'address': RfpBookingAddressModel.fromEntity(address).toJson(),
      'booking_paid': bookingPaid,
      'remaining_paid': remainingPaid,
      'delivery_days': deliveryDays,
      'merchant_transaction_id': merchantTransactionId,
      'checkout_url': checkoutUrl,
      'general_note': generalNote,
      'is_late_booking': isLateBooking,
      'discount_percentage': discountPercentage,
      'payment_expires_at': paymentExpiresAt?.toIso8601String(),
      'payment_type': paymentType,
      if (cropCycleId != null) 'crop_cycle_id': cropCycleId,
    };
  }

  factory RfpBookingModel.fromEntity(RfpBooking entity) {
    return RfpBookingModel(
      id: entity.id,
      batchId: entity.batchId,
      batchNumber: entity.batchNumber,
      planId: entity.planId,
      planName: entity.planName,
      status: entity.status,
      startDate: entity.startDate,
      endDate: entity.endDate,
      patchConfigs: entity.patchConfigs,
      totalAmount: entity.totalAmount,
      bookingAmountPaid: entity.bookingAmountPaid,
      remainingAmount: entity.remainingAmount,
      bookedAt: entity.bookedAt,
      address: entity.address,
      bookingPaid: entity.bookingPaid,
      remainingPaid: entity.remainingPaid,
      deliveryDays: entity.deliveryDays,
      merchantTransactionId: entity.merchantTransactionId,
      checkoutUrl: entity.checkoutUrl,
      deliveries: entity.deliveries,
      generalNote: entity.generalNote,
      isLateBooking: entity.isLateBooking,
      deliveryState: entity.deliveryState,
      paymentExpiresAt: entity.paymentExpiresAt,
      discountPercentage: entity.discountPercentage,
      paymentType: entity.paymentType,
      cropCycleId: entity.cropCycleId,
    );
  }
}
