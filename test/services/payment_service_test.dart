import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart' as dio;
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/payment_service.dart';
import 'package:grocery_app/models/payment_status_model.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late PaymentService paymentService;
  late MockApiClient mockApiClient;

  setUp(() async {
    mockApiClient = MockApiClient();
    await getIt.reset();
    getIt.registerLazySingleton<ApiClient>(() => mockApiClient);
    
    paymentService = PaymentService.create();
    getIt.registerLazySingleton<PaymentService>(() => paymentService);
  });

  group('PaymentService', () {
    test('fetchStatus calls ApiClient.get with correct path and returns PaymentStatusResponse', () async {
      when(() => mockApiClient.get(any())).thenAnswer((_) async => dio.Response(
            requestOptions: dio.RequestOptions(path: ''),
            statusCode: 200,
            data: {'transaction_status': 'SUCCESS', 'resp_message': 'Paid'},
          ));

      final result = await paymentService.fetchStatus('ref_123');

      expect(result.status, 'SUCCESS');
      expect(result.respMessage, 'Paid');
      expect(result.isSuccess, true);
      verify(() => mockApiClient.get('/api/payments/status/ref_123/')).called(1);
    });

    test('pollStatus exits early on terminal SUCCESS state', () async {
      when(() => mockApiClient.get(any())).thenAnswer((_) async => dio.Response(
            requestOptions: dio.RequestOptions(path: ''),
            statusCode: 200,
            data: {'transaction_status': 'SUCCESS', 'resp_message': 'Paid'},
          ));

      final result = await paymentService.pollStatus('ref_123');

      expect(result.isSuccess, true);
      expect(result.status, 'SUCCESS');
      verify(() => mockApiClient.get('/api/payments/status/ref_123/')).called(1);
    });

    test('pollStatus polls multiple times if status is PENDING then exits on SUCCESS', () async {
      var callCount = 0;
      when(() => mockApiClient.get(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return dio.Response(
            requestOptions: dio.RequestOptions(path: ''),
            statusCode: 200,
            data: {'transaction_status': 'PENDING', 'resp_message': 'Pending'},
          );
        } else {
          return dio.Response(
            requestOptions: dio.RequestOptions(path: ''),
            statusCode: 200,
            data: {'transaction_status': 'SUCCESS', 'resp_message': 'Paid'},
          );
        }
      });

      // To make the test run fast, we can mock/override the pollInterval or just wait (since it only runs twice, it's 2 seconds)
      // Wait, can we mock the delay? In Flutter tests, we can use fakeAsync or just wait the 2 seconds.
      // But standard package:flutter_test runs with fake async zones if we use testWidgets, or we can just run it. 2 seconds is acceptable, but let's see.
      final result = await paymentService.pollStatus('ref_123');

      expect(result.isSuccess, true);
      expect(callCount, 2);
      verify(() => mockApiClient.get('/api/payments/status/ref_123/')).called(2);
    });

    test('isSuccess, isPending, and isFailed identify states correctly', () {
      expect(PaymentService.isSuccess('SUCCESS'), true);
      expect(PaymentService.isSuccess('FAILED'), false);

      expect(PaymentService.isPending('PENDING'), true);
      expect(PaymentService.isPending('INITIATED'), true);
      expect(PaymentService.isPending('SUCCESS'), false);

      expect(PaymentService.isFailed('FAILED'), true);
      expect(PaymentService.isFailed('CANCELLED'), true);
      expect(PaymentService.isFailed('ABANDONED'), true);
      expect(PaymentService.isFailed('PENDING'), false);
    });
  });
}
