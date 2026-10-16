import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/rfp/data/datasources/rfp_remote_data_source.dart';
import 'package:grocery_app/features/rfp/data/datasources/rfp_mock_data_source.dart';
import 'package:grocery_app/features/rfp/data/models/rfp_batch_model.dart';
import 'package:grocery_app/features/rfp/data/models/rfp_plan_model.dart';
import 'package:grocery_app/features/rfp/data/models/rfp_plan_pricing_model.dart';
import 'package:grocery_app/features/rfp/data/models/rfp_pricing_model.dart';
import 'package:grocery_app/features/rfp/data/models/rfp_vegetable_model.dart';
import 'package:grocery_app/features/rfp/data/repositories/rfp_repository_impl.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_patch_config.dart';

class MockRfpRemoteDataSource extends Mock implements RfpRemoteDataSource {}
class MockRfpMockDataSource extends Mock implements RfpMockDataSource {}

void main() {
  late MockRfpRemoteDataSource remoteDataSource;
  late MockRfpMockDataSource mockDataSource;
  late RfpRepositoryImpl repository;

  final sampleBatch = RfpBatchModel(
    id: '1',
    batchNumber: 1,
    startDate: DateTime(2026, 10, 1),
    endDate: DateTime(2026, 12, 24),
    totalWeeks: 12,
    currentWeek: 1,
    status: 'upcoming',
    seasonLabel: 'Cohort 01',
    progressPercent: 0.1,
    plans: [
      RfpPlanModel(
        id: 'plan_1',
        name: 'Ritu Thali',
        tier: 'A',
        description: 'Seasonal Veggies',
        totalPrice: 4788.0,
        bookingAmount: 478.8,
        remainingAmount: 4309.2,
        features: const ['12 Deliveries'],
        code: 'P1',
        selectionLimit: 5,
        availableVegetables: const [
          RfpVegetableModel(
            id: '1',
            name: 'Aloo',
            description: 'Fresh Aloo',
            season: 'All-season',
          ),
          RfpVegetableModel(
            id: '2',
            name: 'Gobi',
            description: 'Fresh Gobi',
            season: 'All-season',
          ),
          RfpVegetableModel(
            id: '3',
            name: 'Palak',
            description: 'Fresh Palak',
            season: 'All-season',
          ),
        ],
        pricings: const [
          RfpPlanPricingModel(
            id: 12,
            variantName: 'SMALL',
            weightKg: 2.5,
            frequencyPerWeek: 1,
            pricePerDelivery: 319.0,
          ),
          RfpPlanPricingModel(
            id: 13,
            variantName: 'SMALL',
            weightKg: 2.5,
            frequencyPerWeek: 2,
            pricePerDelivery: 300.0,
          ),
        ],
      ),
    ],
  );

  setUp(() {
    remoteDataSource = MockRfpRemoteDataSource();
    mockDataSource = MockRfpMockDataSource();
    repository = RfpRepositoryImpl(remoteDataSource, mockDataSource);
  });

  group('RfpRepositoryImpl.getBatches', () {
    test('fetches batches from remote data source and caches them', () async {
      when(() => remoteDataSource.getActiveBatches())
          .thenAnswer((_) async => [sampleBatch]);

      final result = await repository.getBatches('loc_01');

      expect(result.length, 1);
      expect(result.first.id, '1');
      expect(result.first.seasonLabel, 'Cohort 01');
      verify(() => remoteDataSource.getActiveBatches()).called(1);
    });

    test('falls back to mock data source when remote data source fails', () async {
      when(() => remoteDataSource.getActiveBatches())
          .thenThrow(Exception('Network Error'));
      when(() => mockDataSource.getBatches('loc_01'))
          .thenAnswer((_) async => [sampleBatch]);

      final result = await repository.getBatches('loc_01');

      expect(result.length, 1);
      expect(result.first.id, '1');
      verify(() => mockDataSource.getBatches('loc_01')).called(1);
    });
  });

  group('RfpRepositoryImpl.getPatches', () {
    test('maps batch plans to agricultural patch plots correctly', () async {
      when(() => remoteDataSource.getActiveBatches())
          .thenAnswer((_) async => [sampleBatch]);

      final patches = await repository.getPatches('1');

      expect(patches.length, 1);
      expect(patches.first.id, 'plan_1');
      expect(patches.first.label, 'P1');
      expect(patches.first.name, 'Ritu Thali');
      expect(patches.first.startingPrice, 319.0);
      expect(patches.first.availableWeights, [2.5]);
    });
  });

  group('RfpRepositoryImpl.calculatePricing', () {
    test('builds payload and calls remote calculateSubscription', () async {
      when(() => remoteDataSource.getActiveBatches())
          .thenAnswer((_) async => [sampleBatch]);
      await repository.getBatches('loc_01');

      const expectedPricing = RfpPricingModel(
        basePrice: 10120.0,
        discountAmount: 500.0,
        finalPrice: 9620.0,
        bookingAmount: 920.0,
        remainingAmount: 8700.0,
        perDelivery: 400.0,
      );

      when(() => remoteDataSource.calculateSubscription(
            batchId: any(named: 'batchId'),
            deliveryDays: any(named: 'deliveryDays'),
            plans: any(named: 'plans'),
          )).thenAnswer((_) async => expectedPricing);

      final result = await repository.calculatePricing(
        planId: 'plan_1',
        patchConfigs: [
          const RfpPatchConfig(
            patchId: 'plan_1',
            patchLabel: 'P1',
            excludedVegetableIds: ['3'],
            selectedWeight: 2.5,
            deliveryFrequency: 'once_a_week',
          ),
        ],
      );

      expect(result.finalPrice, 9620.0);
      expect(result.bookingAmount, 920.0);
      verify(() => remoteDataSource.calculateSubscription(
            batchId: 1,
            deliveryDays: ['Monday'],
            plans: [
              {
                'plan_pricing_id': 12,
                'vegetable_ids': [1, 2],
              }
            ],
          )).called(1);
    });
  });

  group('RfpRepositoryImpl.createBooking', () {
    test('calls bookSubscription and returns RfpBooking with checkout url', () async {
      when(() => remoteDataSource.getActiveBatches())
          .thenAnswer((_) async => [sampleBatch]);
      await repository.getBatches('loc_01');

      when(() => remoteDataSource.bookSubscription(
            batchId: any(named: 'batchId'),
            deliveryDays: any(named: 'deliveryDays'),
            plans: any(named: 'plans'),
          )).thenAnswer((_) async => {
            'success': true,
            'subscription_id': 58,
            'merchant_transaction_id': 'TXN_SUB_58',
            'checkout_url': 'https://pay.gateway.com/checkout/58',
          });

      final booking = await repository.createBooking(
        batchId: '1',
        planId: 'plan_1',
        locationId: 'loc_01',
        patchConfigs: [
          const RfpPatchConfig(
            patchId: 'plan_1',
            patchLabel: 'P1',
            excludedVegetableIds: [],
            selectedWeight: 2.5,
            deliveryFrequency: 'twice_a_week',
          ),
        ],
        paymentMethod: 'ONLINE',
        fullName: 'Jane Doe',
        addressLine: 'Flat 402, Green Heights',
        city: 'Gurugram',
        pincode: '122001',
        phone: '9876543210',
      );

      expect(booking.id, '58');
      expect(booking.merchantTransactionId, 'TXN_SUB_58');
      expect(booking.checkoutUrl, 'https://pay.gateway.com/checkout/58');
      expect(booking.address.fullName, 'Jane Doe');
      expect(booking.deliveryDays, ['Monday', 'Thursday']);
    });
  });

  group('RfpRepositoryImpl.verifyPayment and payRemaining', () {
    test('delegates verifyPayment to remoteDataSource', () async {
      when(() => remoteDataSource.verifyPayment(merchantTransactionId: 'TXN_SUB_58'))
          .thenAnswer((_) async => {'status': 'COMPLETED'});

      final result = await repository.verifyPayment('TXN_SUB_58');
      expect(result['status'], 'COMPLETED');
      verify(() => remoteDataSource.verifyPayment(merchantTransactionId: 'TXN_SUB_58')).called(1);
    });

    test('delegates payRemaining to remoteDataSource', () async {
      when(() => remoteDataSource.payRemaining(subscriptionId: 58))
          .thenAnswer((_) async => {'success': true, 'checkout_url': 'https://pay.com'});

      final result = await repository.payRemaining(58);
      expect(result['checkout_url'], 'https://pay.com');
      verify(() => remoteDataSource.payRemaining(subscriptionId: 58)).called(1);
    });
  });

  group('RfpRepositoryImpl.getBatchDetails and getPlans', () {
    test('getBatchDetails calls remoteDataSource.getBatchDetail for numeric id', () async {
      when(() => remoteDataSource.getBatchDetail(1))
          .thenAnswer((_) async => sampleBatch);

      final result = await repository.getBatchDetails('1');
      expect(result.id, '1');
      expect((result as RfpBatchModel).plans.length, 1);
      verify(() => remoteDataSource.getBatchDetail(1)).called(1);
    });

    test('getPlans fetches batch detail if plans are empty in cached batches', () async {
      when(() => remoteDataSource.getBatchDetail(1))
          .thenAnswer((_) async => sampleBatch);

      final plans = await repository.getPlans('1');
      expect(plans.length, 1);
      expect(plans.first.name, 'Ritu Thali');
      verify(() => remoteDataSource.getBatchDetail(1)).called(1);
    });
  });
}
