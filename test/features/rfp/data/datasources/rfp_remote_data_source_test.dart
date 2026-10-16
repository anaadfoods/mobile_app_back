import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/features/rfp/data/datasources/rfp_remote_data_source.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late RfpRemoteDataSourceImpl dataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = RfpRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  group('RfpRemoteDataSource.getActiveBatches', () {
    test('returns parsed List<RfpBatchModel> when response status is 200', () async {
      final jsonResponse = [
        {
          'id': 1,
          'batch_number': 1,
          'season_name': 'Spring / Summer 2026',
          'status': 'OPEN',
          'start_date': '2026-03-01',
          'end_date': '2026-05-31',
          'booking_start_date': '2026-01-15',
          'booking_end_date': '2026-02-28',
          'duration_weeks': 12,
          'is_full': false,
          'notes': 'Test batch',
          'capacity_summary': {
            'total_capacity': 50,
            'booked_count': 10,
            'remaining_capacity': 40,
            'is_full': false,
          },
          'plans': [
            {
              'id': 10,
              'name': 'Ritu Thali',
              'code': 'P1',
              'description': 'Description',
              'selection_limit': 6,
              'available_vegetables': [
                {'id': 1, 'name': 'Spinach', 'image': 'https://img.png'},
              ],
              'pricings': [
                {
                  'id': 12,
                  'variant': 'SMALL',
                  'weight_kg': 5.0,
                  'frequency_per_week': 1,
                  'total_deliveries': 12,
                  'price_per_delivery': 399.0,
                  'total_price': 4788.0,
                  'booking_amount': 478.8,
                  'remaining_amount': 4309.2,
                }
              ],
            }
          ],
        }
      ];

      when(() => mockApiClient.get(ApiConfig.rfpActiveBatchesEndpoint))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: ApiConfig.rfpActiveBatchesEndpoint),
                statusCode: 200,
                data: jsonResponse,
              ));

      final result = await dataSource.getActiveBatches();

      expect(result.length, 1);
      expect(result.first.id, '1');
      expect(result.first.batchNumber, 1);
      expect(result.first.seasonLabel, 'Spring / Summer 2026');
      expect(result.first.plans.length, 1);
      expect(result.first.plans.first.code, 'P1');
      expect(result.first.plans.first.pricings.first.weightKg, 5.0);
      verify(() => mockApiClient.get(ApiConfig.rfpActiveBatchesEndpoint)).called(1);
    });

    test('throws Exception when API request fails', () async {
      when(() => mockApiClient.get(ApiConfig.rfpActiveBatchesEndpoint))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConfig.rfpActiveBatchesEndpoint),
        error: 'Network failure',
      ));

      expect(() => dataSource.getActiveBatches(), throwsA(isA<Exception>()));
    });
  });

  group('RfpRemoteDataSource.calculateSubscription', () {
    test('returns RfpPricingModel when calculation succeeds', () async {
      final jsonResponse = {
        'success': true,
        'breakdown': {
          'total_amount': 10120.0,
          'booking_amount': 920.0,
          'remaining_amount': 9200.0,
          'deliveries_count': 24,
          'price_per_delivery': 421.67,
          'discount_percentage': 5.0,
          'discount_amount': 532.63,
          'pay_now': 920.0,
          'pay_later': 9200.0,
          'total': 10120.0,
        }
      };

      when(() => mockApiClient.post(
            ApiConfig.rfpCalculateEndpoint,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConfig.rfpCalculateEndpoint),
            statusCode: 200,
            data: jsonResponse,
          ));

      final result = await dataSource.calculateSubscription(
        batchId: 1,
        deliveryDays: ['Monday'],
        plans: [{'plan_pricing_id': 12}],
      );

      expect(result.finalPrice, 10120.0);
      expect(result.bookingAmount, 920.0);
      expect(result.remainingAmount, 9200.0);
      expect(result.discountPercentage, 5.0);
      expect(result.perDelivery, 421.67);
    });

    test('throws ApiException when backend returns success: false', () async {
      final jsonResponse = {
        'success': false,
        'error_code': 'BATCH_FULL',
        'error': 'Batch capacity full',
      };

      when(() => mockApiClient.post(
            ApiConfig.rfpCalculateEndpoint,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConfig.rfpCalculateEndpoint),
            statusCode: 200,
            data: jsonResponse,
          ));

      expect(
        () => dataSource.calculateSubscription(
          batchId: 1,
          deliveryDays: ['Monday'],
          plans: [{'plan_pricing_id': 12}],
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('RfpRemoteDataSource.bookSubscription', () {
    test('returns booking map on successful POST', () async {
      final jsonResponse = {
        'success': true,
        'subscription_id': 101,
        'order_id': 'ORD_001',
        'merchant_transaction_id': 'TXN_RFP_123',
        'checkout_url': 'https://pay.gateway.com/checkout',
      };

      when(() => mockApiClient.post(
            ApiConfig.rfpBookEndpoint,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConfig.rfpBookEndpoint),
            statusCode: 201,
            data: jsonResponse,
          ));

      final result = await dataSource.bookSubscription(
        batchId: 1,
        deliveryDays: ['Monday'],
        plans: [{'plan_pricing_id': 12}],
      );

      expect(result['subscription_id'], 101);
      expect(result['merchant_transaction_id'], 'TXN_RFP_123');
      expect(result['checkout_url'], 'https://pay.gateway.com/checkout');
    });

    test('sends payment_type full and address_id in payload when provided', () async {
      final jsonResponse = {
        'success': true,
        'subscription_id': 102,
        'merchant_transaction_id': 'TXN_FULL_123',
      };

      when(() => mockApiClient.post(
            ApiConfig.rfpBookEndpoint,
            data: {
              'batch_id': 1,
              'delivery_days': ['Monday'],
              'plans': [{'plan_pricing_id': 12}],
              'payment_type': 'full',
              'address_id': 5,
            },
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConfig.rfpBookEndpoint),
            statusCode: 201,
            data: jsonResponse,
          ));

      final result = await dataSource.bookSubscription(
        batchId: 1,
        deliveryDays: ['Monday'],
        plans: [{'plan_pricing_id': 12}],
        paymentType: 'full',
        addressId: 5,
      );

      expect(result['subscription_id'], 102);
      expect(result['merchant_transaction_id'], 'TXN_FULL_123');
    });

    test('extracts PLAN_FULL error correctly on 400 rejection', () async {
      when(() => mockApiClient.post(
            ApiConfig.rfpBookEndpoint,
            data: any(named: 'data'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConfig.rfpBookEndpoint),
        response: Response(
          requestOptions: RequestOptions(path: ApiConfig.rfpBookEndpoint),
          statusCode: 400,
          data: {
            'success': false,
            'error_code': 'PLAN_FULL',
            'error': 'This plan is currently full.',
          },
        ),
      ));

      expect(
        () => dataSource.bookSubscription(
          batchId: 1,
          deliveryDays: ['Monday'],
          plans: [{'plan_pricing_id': 12}],
        ),
        throwsA(predicate((e) => e.toString().contains('PLAN_FULL'))),
      );
    });
  });

  group('RfpRemoteDataSource.verifyPayment', () {
    test('returns verification map on successful POST', () async {
      final jsonResponse = {
        'success': true,
        'status': 'COMPLETED',
        'subscription_id': 101,
      };

      when(() => mockApiClient.post(
            ApiConfig.rfpVerifyPaymentEndpoint,
            data: {'merchant_transaction_id': 'TXN_123'},
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConfig.rfpVerifyPaymentEndpoint),
            statusCode: 200,
            data: jsonResponse,
          ));

      final result = await dataSource.verifyPayment(merchantTransactionId: 'TXN_123');
      expect(result['status'], 'COMPLETED');
      expect(result['subscription_id'], 101);
    });
  });

  group('RfpRemoteDataSource.getMySubscriptions', () {
    test('returns List<RfpBookingModel> when response is 200', () async {
      final jsonResponse = [
        {
          'id': 101,
          'batch_number': 1,
          'status': 'ACTIVE',
          'total_amount': '10120.00',
          'booking_amount_paid': '920.00',
          'remaining_amount': '9200.00',
          'booking_paid': true,
          'remaining_paid': false,
          'delivery_days': ['Monday', 'Thursday'],
          'created_at': '2026-03-01T10:00:00Z',
          'deliveries': [
            {
              'id': 201,
              'delivery_number': 1,
              'scheduled_date': '2026-03-05',
              'status': 'DELIVERED',
            }
          ],
        }
      ];

      when(() => mockApiClient.get(ApiConfig.rfpMySubscriptionsEndpoint))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: ApiConfig.rfpMySubscriptionsEndpoint),
                statusCode: 200,
                data: jsonResponse,
              ));

      final result = await dataSource.getMySubscriptions();
      expect(result.length, 1);
      expect(result.first.id, '101');
      expect(result.first.status, 'ACTIVE');
      expect(result.first.totalAmount, 10120.0);
      expect(result.first.deliveries.length, 1);
      expect(result.first.deliveries.first.status, 'delivered');
    });
  });

  group('RfpRemoteDataSource.payRemaining', () {
    test('returns checkout response when initiating remaining payment', () async {
      final jsonResponse = {
        'success': true,
        'checkout_url': 'https://pay.gateway.com/pay-balance',
        'merchant_transaction_id': 'TXN_REM_999',
      };

      when(() => mockApiClient.post(ApiConfig.rfpPayRemainingEndpoint(101)))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: ApiConfig.rfpPayRemainingEndpoint(101)),
                statusCode: 200,
                data: jsonResponse,
              ));

      final result = await dataSource.payRemaining(subscriptionId: 101);
      expect(result['checkout_url'], 'https://pay.gateway.com/pay-balance');
      expect(result['merchant_transaction_id'], 'TXN_REM_999');
    });
  });

  group('RfpRemoteDataSource.getBatchDetail', () {
    test('returns parsed RfpBatchModel with plans and vegetables on status 200', () async {
      final jsonResponse = {
        'id': 2,
        'name': 'Oct-Jan 2026 Batch — Cohort 01 (Demo)',
        'start_date': '2026-09-02',
        'end_date': '2026-11-25',
        'status': 'ACTIVE',
        'plans': [
          {
            'id': 2,
            'code': 'A',
            'name': 'RITU THALI',
            'description': 'The Seasonal Plan',
            'selection_limit': 5,
            'available_vegetables': [
              {
                'id': 4,
                'name': 'Aloo',
                'is_active': true,
                'is_default_selected': true,
              },
              {
                'id': 10,
                'name': 'Baingan',
                'is_active': true,
                'is_default_selected': false,
              }
            ],
            'pricings': [
              {
                'id': 2,
                'variant_name': 'SMALL',
                'weight_kg': '2.50',
                'frequency_per_week': 1,
                'price_per_delivery': '319.00',
              }
            ],
          }
        ],
      };

      when(() => mockApiClient.get(ApiConfig.rfpBatchDetailEndpoint(2)))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: ApiConfig.rfpBatchDetailEndpoint(2)),
                statusCode: 200,
                data: jsonResponse,
              ));

      final result = await dataSource.getBatchDetail(2);
      expect(result.id, '2');
      expect(result.seasonLabel, 'Oct-Jan 2026 Batch — Cohort 01 (Demo)');
      expect(result.plans.length, 1);
      expect(result.plans.first.name, 'RITU THALI');
      expect(result.plans.first.availableVegetables.first.name, 'Aloo');
      expect(result.plans.first.availableVegetables.first.isDefaultSelected, true);
      expect(result.plans.first.pricings.first.pricePerDelivery, 319.0);
    });

    test('throws Exception on API failure', () async {
      when(() => mockApiClient.get(ApiConfig.rfpBatchDetailEndpoint(99)))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConfig.rfpBatchDetailEndpoint(99)),
        error: 'Not found',
      ));

      expect(() => dataSource.getBatchDetail(99), throwsA(isA<Exception>()));
    });
  });
}
