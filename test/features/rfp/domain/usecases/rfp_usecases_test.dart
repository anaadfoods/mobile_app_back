import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_batch.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_booking.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_delivery.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_location.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_patch.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_plan.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_pricing.dart';
import 'package:grocery_app/features/rfp/domain/repositories/rfp_repository.dart';
import 'package:grocery_app/features/rfp/domain/usecases/calculate_pricing_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_batches_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_booking_details_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_delivery_schedule_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_locations_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_patches_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_plans_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/verify_rfp_payment_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/pay_remaining_use_case.dart';
import 'package:grocery_app/features/rfp/domain/entities/user_address.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_delivery_otp_status.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_user_addresses_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/save_user_address_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_delivery_otp_status_use_case.dart';

class MockRfpRepository extends Mock implements RfpRepository {}

void main() {
  late MockRfpRepository repository;

  setUp(() {
    repository = MockRfpRepository();
  });

  group('GetLocationsUseCase', () {
    test('returns list of locations from repository', () async {
      final useCase = GetLocationsUseCase(repository);
      final List<RfpLocation> expectedLocations = [
        const RfpLocation(
          id: 'loc_1',
          name: 'Valley Sector 4',
          pincode: '122018',
          sector: 'Sector 4',
          isActive: true,
        ),
      ];

      when(() => repository.getAvailableLocations())
          .thenAnswer((_) async => expectedLocations);

      final result = await useCase();
      expect(result, equals(expectedLocations));
      verify(() => repository.getAvailableLocations()).called(1);
    });
  });

  group('GetBatchesUseCase', () {
    test('returns batches for given locationId', () async {
      final useCase = GetBatchesUseCase(repository);
      final List<RfpBatch> expectedBatches = [
        RfpBatch(
          id: 'b12',
          batchNumber: 12,
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 12, 23),
          totalWeeks: 12,
          currentWeek: 4,
          status: 'open',
          progressPercent: 0.33,
        ),
      ];

      when(() => repository.getBatches('loc_1'))
          .thenAnswer((_) async => expectedBatches);

      final result = await useCase('loc_1');
      expect(result, equals(expectedBatches));
      verify(() => repository.getBatches('loc_1')).called(1);
    });
  });

  group('GetPlansUseCase', () {
    test('returns plans for given batchId', () async {
      final useCase = GetPlansUseCase(repository);
      final List<RfpPlan> expectedPlans = [
        const RfpPlan(
          id: 'plan_1',
          name: 'Plan 1',
          tier: 'standard',
          description: 'Single patch plan',
          totalPrice: 8999,
          bookingAmount: 999,
          remainingAmount: 8000,
          features: ['1 Patch', '12 Deliveries'],
        ),
      ];

      when(() => repository.getPlans('b12'))
          .thenAnswer((_) async => expectedPlans);

      final result = await useCase('b12');
      expect(result, equals(expectedPlans));
      verify(() => repository.getPlans('b12')).called(1);
    });
  });

  group('GetPatchesUseCase', () {
    test('returns patches for given batchId', () async {
      final useCase = GetPatchesUseCase(repository);
      final List<RfpPatch> expectedPatches = [
        const RfpPatch(
          id: 'p1',
          label: 'P1',
          name: 'Agricultural Box',
          vegetables: [],
          maxExclusions: 3,
          availableWeights: [2.5, 5.0, 7.5],
          startingPrice: 4999,
        ),
      ];

      when(() => repository.getPatches('b12'))
          .thenAnswer((_) async => expectedPatches);

      final result = await useCase('b12');
      expect(result, equals(expectedPatches));
      verify(() => repository.getPatches('b12')).called(1);
    });
  });

  group('CalculatePricingUseCase', () {
    test('calls repository with planId and patchConfigs', () async {
      final useCase = CalculatePricingUseCase(repository);
      const expectedPricing = RfpPricing(
        basePrice: 16999,
        discountAmount: 2000,
        discountLabel: 'Early Bird',
        finalPrice: 14999,
        bookingAmount: 1499,
        remainingAmount: 13500,
      );

      when(() => repository.calculatePricing(
            planId: 'plan_1',
            patchConfigs: const [],
          )).thenAnswer((_) async => expectedPricing);

      final result = await useCase(planId: 'plan_1', patchConfigs: const []);
      expect(result, equals(expectedPricing));
      verify(() => repository.calculatePricing(
            planId: 'plan_1',
            patchConfigs: const [],
          )).called(1);
    });
  });

  group('GetBookingDetailsUseCase and GetActiveBookingUseCase', () {
    test('returns booking details and active booking', () async {
      final detailsUseCase = GetBookingDetailsUseCase(repository);
      final activeUseCase = GetActiveBookingUseCase(repository);

      final booking = RfpBooking(
        id: 'BKG-001',
        batchId: 'b12',
        batchNumber: 12,
        planId: 'plan_1',
        planName: 'Plan 1',
        status: 'active',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 12, 23),
        patchConfigs: const [],
        totalAmount: 14999,
        bookingAmountPaid: 1499,
        remainingAmount: 13500,
        bookedAt: DateTime.now(),
        address: const RfpBookingAddress(
          fullName: 'Test User',
          addressLine: 'Street 1',
          city: 'Delhi',
          pincode: '110001',
          phone: '9999999999',
        ),
      );

      when(() => repository.getBookingDetails('BKG-001'))
          .thenAnswer((_) async => booking);
      when(() => repository.getActiveBooking())
          .thenAnswer((_) async => booking);

      final detailsResult = await detailsUseCase('BKG-001');
      final activeResult = await activeUseCase();

      expect(detailsResult.id, 'BKG-001');
      expect(activeResult?.id, 'BKG-001');
    });
  });

  group('GetDeliveryScheduleUseCase', () {
    test('returns delivery schedule', () async {
      final useCase = GetDeliveryScheduleUseCase(repository);
      final List<RfpDelivery> deliveries = [
        RfpDelivery(
          id: 'del_1',
          weekNumber: 1,
          date: DateTime(2026, 10, 6),
          dayOfWeek: 'Monday',
          status: 'upcoming',
          patches: const [],
        ),
      ];

      when(() => repository.getDeliverySchedule('BKG-001'))
          .thenAnswer((_) async => deliveries);

      final result = await useCase('BKG-001');
      expect(result.length, 1);
      expect(result.first.weekNumber, 1);
    });
  });

  group('VerifyRfpPaymentUseCase', () {
    test('calls repository.verifyPayment', () async {
      final useCase = VerifyRfpPaymentUseCase(repository);
      final expectedResult = {'status': 'COMPLETED', 'subscription_id': 1};

      when(() => repository.verifyPayment('TXN_123'))
          .thenAnswer((_) async => expectedResult);

      final result = await useCase('TXN_123');
      expect(result, equals(expectedResult));
      verify(() => repository.verifyPayment('TXN_123')).called(1);
    });
  });

  group('PayRemainingUseCase', () {
    test('calls repository.payRemaining', () async {
      final useCase = PayRemainingUseCase(repository);
      final expectedResult = {
        'status': 'INITIATED',
        'checkout_url': 'https://pay.example.com',
      };

      when(() => repository.payRemaining(101))
          .thenAnswer((_) async => expectedResult);

      final result = await useCase(101);
      expect(result, equals(expectedResult));
      verify(() => repository.payRemaining(101)).called(1);
    });
  });

  group('GetUserAddressesUseCase', () {
    test('returns addresses from repository', () async {
      final useCase = GetUserAddressesUseCase(repository);
      final addresses = [
        const UserAddress(
          id: 5,
          label: 'HOME',
          fullName: 'Jane Doe',
          phoneNumber: '9876543210',
          addressLine1: 'Flat 402, Green Heights',
          city: 'Jaipur',
          state: 'Rajasthan',
          pincode: '302001',
          isDefault: true,
        ),
      ];

      when(() => repository.getUserAddresses())
          .thenAnswer((_) async => addresses);

      final result = await useCase();
      expect(result, equals(addresses));
      verify(() => repository.getUserAddresses()).called(1);
    });
  });

  group('SaveUserAddressUseCase', () {
    test('calls repository.saveUserAddress with given entity', () async {
      final useCase = SaveUserAddressUseCase(repository);
      const input = UserAddress(
        id: 0,
        label: 'WORK',
        fullName: 'John Smith',
        phoneNumber: '9123456789',
        addressLine1: 'Tech Park Block B',
        city: 'Jaipur',
        state: 'Rajasthan',
        pincode: '302015',
      );
      const expectedSaved = UserAddress(
        id: 12,
        label: 'WORK',
        fullName: 'John Smith',
        phoneNumber: '9123456789',
        addressLine1: 'Tech Park Block B',
        city: 'Jaipur',
        state: 'Rajasthan',
        pincode: '302015',
      );

      when(() => repository.saveUserAddress(input))
          .thenAnswer((_) async => expectedSaved);

      final result = await useCase(input);
      expect(result, equals(expectedSaved));
      expect(result.id, 12);
      verify(() => repository.saveUserAddress(input)).called(1);
    });
  });

  group('GetDeliveryOtpStatusUseCase', () {
    test('returns active delivery OTP status for a delivery ID', () async {
      final useCase = GetDeliveryOtpStatusUseCase(repository);
      final expectedStatus = RfpDeliveryOtpStatus(
        state: 'ACTIVE',
        otp: '654321',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      when(() => repository.getDeliveryOtpStatus('42'))
          .thenAnswer((_) async => expectedStatus);

      final result = await useCase('42');
      expect(result.state, equals('ACTIVE'));
      expect(result.otp, equals('654321'));
      expect(result.isActive, isTrue);
      verify(() => repository.getDeliveryOtpStatus('42')).called(1);
    });
  });
}

