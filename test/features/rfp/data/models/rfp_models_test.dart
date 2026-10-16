import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/features/rfp/data/models/user_address_model.dart';
import 'package:grocery_app/features/rfp/data/models/rfp_pricing_model.dart';
import 'package:grocery_app/features/rfp/data/models/rfp_booking_model.dart';
import 'package:grocery_app/features/rfp/data/models/rfp_delivery_model.dart';
import 'package:grocery_app/features/rfp/data/models/rfp_delivery_otp_status_model.dart';
import 'package:grocery_app/features/rfp/data/repositories/rfp_payload_builder.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_patch_config.dart';
import 'package:grocery_app/features/rfp/domain/entities/user_address.dart';

import 'package:grocery_app/features/rfp/data/models/rfp_plan_model.dart';
import 'package:grocery_app/features/rfp/data/models/rfp_batch_model.dart';

void main() {
  group('RfpPlanModel', () {
    test('parses per-plan capacity and status from backend batches/{id}/ response', () {
      final json = {
        'id': 47,
        'code': 'D',
        'name': 'TADKA BOX',
        'description': 'The Spices, Herbs and Sides Plan',
        'selection_limit': 3,
        'max_deselectable_count': 0,
        'max_families': 50,
        'booked_family_count': 12,
        'slots_remaining': 38,
        'is_full': false,
        'status': 'AVAILABLE',
        'available_vegetables': [],
        'pricings': [],
      };

      final model = RfpPlanModel.fromJson(json);
      expect(model.id, '47');
      expect(model.code, 'D');
      expect(model.name, 'TADKA BOX');
      expect(model.maxFamilies, 50);
      expect(model.bookedFamilyCount, 12);
      expect(model.slotsRemaining, 38);
      expect(model.isFull, isFalse);
      expect(model.planStatus, 'AVAILABLE');

      final roundTrip = model.toJson();
      expect(roundTrip['max_families'], 50);
      expect(roundTrip['slots_remaining'], 38);
      expect(roundTrip['status'], 'AVAILABLE');
    });

    test('correctly handles full plan with status FULL', () {
      final json = {
        'id': 49,
        'code': 'A',
        'name': 'RITU THALI',
        'description': 'The Seasonal Plan',
        'max_families': 50,
        'booked_family_count': 50,
        'slots_remaining': 0,
        'is_full': true,
        'status': 'FULL',
      };

      final model = RfpPlanModel.fromJson(json);
      expect(model.isFull, isTrue);
      expect(model.slotsRemaining, 0);
      expect(model.planStatus, 'FULL');
    });
  });

  group('RfpBatchModel', () {
    test('parses capacity roll-up and crop_cycle_id from backend response', () {
      final json = {
        'id': 15,
        'name': 'Cohort 01',
        'start_date': '2026-10-08',
        'end_date': '2026-12-31',
        'crop_cycle_id': 'CC-2026-10',
        'capacity': {
          'max_families': 102,
          'booked_family_count': 62,
          'slots_remaining': 40,
          'is_full': false,
        },
      };

      final model = RfpBatchModel.fromJson(json);
      expect(model.id, '15');
      expect(model.seasonLabel, 'Cohort 01');
      expect(model.cropCycleId, 'CC-2026-10');
      expect(model.maxFamilies, 102);
      expect(model.bookedFamilyCount, 62);
      expect(model.slotsRemaining, 40);
      expect(model.isFull, isFalse);

      final roundTrip = model.toJson();
      expect(roundTrip['crop_cycle_id'], 'CC-2026-10');
      expect(roundTrip['capacity']['max_families'], 102);
    });
  });

  group('UserAddressModel', () {
    test('parses from backend auth/addresses JSON', () {
      final json = {
        'id': 10,
        'label': 'HOME',
        'full_name': 'Aarav Sharma',
        'phone_number': '9876543210',
        'address_line1': '102 Green Acres',
        'address_line2': 'Opp Central Mall',
        'landmark': 'Near Water Tank',
        'city': 'Jaipur',
        'state': 'Rajasthan',
        'pincode': '302001',
        'is_default': true,
      };

      final model = UserAddressModel.fromJson(json);
      expect(model.id, 10);
      expect(model.label, 'HOME');
      expect(model.fullName, 'Aarav Sharma');
      expect(model.phoneNumber, '9876543210');
      expect(model.addressLine1, '102 Green Acres');
      expect(model.city, 'Jaipur');
      expect(model.state, 'Rajasthan');
      expect(model.pincode, '302001');
      expect(model.isDefault, isTrue);

      final UserAddress entity = model;
      expect(entity.id, 10);
      expect(entity.formattedAddress, contains('102 Green Acres'));

      final roundTrip = UserAddressModel.fromEntity(entity).toJson();
      expect(roundTrip['full_name'], 'Aarav Sharma');
      expect(roundTrip['phone_number'], '9876543210');
      expect(roundTrip['pincode'], '302001');
    });
  });

  group('RfpPricingModel', () {
    test('parses calculate API response matching Django view', () {
      final json = {
        'success': true,
        'per_delivery': 650.0,
        'deliveries_count': 12,
        'booking_deliveries': 2,
        'remaining_deliveries': 10,
        'pay_now': 1300.0,
        'pay_later': 6500.0,
        'total': 7800.0,
        'discount_percentage': 10.0,
        'plan_count': 1,
      };

      final model = RfpPricingModel.fromJson(json);
      expect(model.finalPrice, 7800.0);
      expect(model.basePrice, closeTo(8666.66, 0.01));
      expect(model.bookingAmount, 1300.0);
      expect(model.remainingAmount, 6500.0);
      expect(model.discountPercentage, 10.0);
      expect(model.deliveriesCount, 12);
      expect(model.bookingDeliveries, 2);
      expect(model.remainingDeliveries, 10);
    });
  });

  group('RfpBookingModel', () {
    test('parses RFPSubscriptionSerializer with delivery address snapshot', () {
      final json = {
        'id': 42,
        'user': 1,
        'batch': 12,
        'status': 'BOOKED',
        'booking_paid': true,
        'remaining_paid': false,
        'total_amount': '7800.00',
        'total_booking_amount': '1300.00',
        'total_remaining_amount': '6500.00',
        'delivery_recipient_name': 'Ramesh Kumar',
        'delivery_phone': '9829012345',
        'delivery_address_line': 'House 14, Sector 5, Malviya Nagar',
        'delivery_city': 'Jaipur',
        'delivery_state': 'Rajasthan',
        'delivery_pincode': '302017',
        'delivery_days': ['Monday'],
        'created_at': '2026-10-01T10:00:00Z',
        'deliveries': [],
      };

      final model = RfpBookingModel.fromJson(json);
      expect(model.id, '42');
      expect(model.batchNumber, 12);
      expect(model.status, 'booked');
      expect(model.bookingPaid, isTrue);
      expect(model.remainingPaid, isFalse);
      expect(model.totalAmount, 7800.00);
      expect(model.bookingAmountPaid, 1300.00);
      expect(model.remainingAmount, 6500.00);
      expect(model.address.fullName, 'Ramesh Kumar');
      expect(model.address.phone, '9829012345');
      expect(model.address.city, 'Jaipur');
      expect(model.deliveryDays, ['Monday']);
      expect(model.paymentType, 'booking');
      expect(model.isFullPayment, isFalse);
    });

    test('parses confirmed full upfront payment subscription with crop_cycle_id', () {
      final json = {
        'id': 58,
        'batch': 15,
        'batch_name': 'Cohort 01',
        'crop_cycle_id': 'CC-2026-10',
        'status': 'ACTIVE',
        'booking_paid': true,
        'remaining_paid': true,
        'payment_type': 'full',
        'total_amount': '13035.00',
        'total_booking_amount': '1185.00',
        'total_remaining_amount': '11850.00',
        'delivery_recipient_name': 'Jane Doe',
        'delivery_phone': '9876543210',
        'delivery_address_line': 'Flat 4B, Green Meadows',
        'delivery_city': 'Pune',
        'delivery_pincode': '411001',
        'delivery_days': ['Monday'],
        'created_at': '2026-10-08T09:12:03Z',
      };

      final model = RfpBookingModel.fromJson(json);
      expect(model.id, '58');
      expect(model.batchName, 'Cohort 01');
      expect(model.cropCycleId, 'CC-2026-10');
      expect(model.paymentType, 'full');
      expect(model.isFullPayment, isTrue);
      expect(model.bookingPaid, isTrue);
      expect(model.remainingPaid, isTrue);

      final roundTrip = model.toJson();
      expect(roundTrip['payment_type'], 'full');
      expect(roundTrip['crop_cycle_id'], 'CC-2026-10');
    });
  });

  group('RfpPayloadBuilder', () {
    test('buildDeliveryDays returns Monday or Monday+Thursday depending on frequency', () {
      final onceConfig = <RfpPatchConfig>[
        const RfpPatchConfig(
          patchId: 'p1',
          patchLabel: 'Patch 1',
          selectedWeight: 5.0,
          deliveryFrequency: 'once_a_week',
          excludedVegetableIds: [],
        ),
      ];
      expect(RfpPayloadBuilder.buildDeliveryDays(onceConfig), ['Monday']);

      final twiceConfig = <RfpPatchConfig>[
        const RfpPatchConfig(
          patchId: 'p1',
          patchLabel: 'Patch 1',
          selectedWeight: 5.0,
          deliveryFrequency: 'twice_a_week',
          excludedVegetableIds: [],
        ),
      ];
      expect(RfpPayloadBuilder.buildDeliveryDays(twiceConfig), ['Monday', 'Thursday']);
    });

    test('buildPlansPayload formats plan_pricing_id and vegetable_ids', () {
      final config = <RfpPatchConfig>[
        const RfpPatchConfig(
          patchId: 'p1',
          patchLabel: 'Patch 1',
          selectedWeight: 5.0,
          deliveryFrequency: 'once_a_week',
          excludedVegetableIds: ['3'],
        ),
      ];

      final payload = RfpPayloadBuilder.buildPlansPayload('p1', config, []);
      expect(payload, isNotEmpty);
      expect(payload.first.containsKey('plan_pricing_id'), isTrue);
    });
  });

  group('RfpDeliveryOtpStatusModel', () {
    test('parses active OTP status from backend JSON', () {
      final json = {
        'state': 'ACTIVE',
        'otp': '456789',
        'expires_at': '2026-10-10T12:00:00Z',
      };
      final model = RfpDeliveryOtpStatusModel.fromJson(json);
      expect(model.state, 'ACTIVE');
      expect(model.otp, '456789');
      expect(model.isActive, isTrue);
      expect(model.expiresAt, isNotNull);

      final outJson = model.toJson();
      expect(outJson['state'], 'ACTIVE');
      expect(outJson['otp'], '456789');
    });

    test('parses inactive states correctly', () {
      final notOut = RfpDeliveryOtpStatusModel.fromJson({'state': 'NOT_OUT_FOR_DELIVERY'});
      expect(notOut.state, 'NOT_OUT_FOR_DELIVERY');
      expect(notOut.isActive, isFalse);

      final noActive = RfpDeliveryOtpStatusModel.fromJson({'state': 'NO_ACTIVE_OTP'});
      expect(noActive.state, 'NO_ACTIVE_OTP');
      expect(noActive.isActive, isFalse);
    });
  });

  group('RfpDeliveryModel with OUT_FOR_DELIVERY', () {
    test('normalizes raw OUT_FOR_DELIVERY status correctly and parses assign_delivery_to', () {
      final json = {
        'id': 101,
        'delivery_date': '2026-10-10',
        'status': 'OUT_FOR_DELIVERY',
        'patches': [],
        'assign_delivery_to': 'Ramesh Kumar',
      };
      final model = RfpDeliveryModel.fromJson(json);
      expect(model.status, 'out_for_delivery');
      expect(model.isOutForDelivery, isTrue);
      expect(model.isDelivered, isFalse);
      expect(model.trackingLabel, 'Out for Delivery');
      expect(model.assignDeliveryTo, 'Ramesh Kumar');
    });
  });
}
