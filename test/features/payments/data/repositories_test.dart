import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/payments/data/datasources/easebuzz_remote_data_source.dart';
import 'package:grocery_app/features/payments/data/datasources/juspay_remote_data_source.dart';
import 'package:grocery_app/features/payments/data/models/payment_status_model.dart';
import 'package:grocery_app/features/payments/data/repositories/easebuzz_payments_repository_impl.dart';
import 'package:grocery_app/features/payments/data/repositories/juspay_payments_repository_impl.dart';

class MockJuspayRemoteDataSource extends Mock implements JuspayRemoteDataSource {}
class MockEasebuzzRemoteDataSource extends Mock implements EasebuzzRemoteDataSource {}

void main() {
  late MockJuspayRemoteDataSource mockJuspayDS;
  late MockEasebuzzRemoteDataSource mockEasebuzzDS;
  late JuspayPaymentsRepositoryImpl juspayRepo;
  late EasebuzzPaymentsRepositoryImpl easebuzzRepo;

  setUp(() {
    mockJuspayDS = MockJuspayRemoteDataSource();
    mockEasebuzzDS = MockEasebuzzRemoteDataSource();

    juspayRepo = JuspayPaymentsRepositoryImpl(
      remoteDataSource: mockJuspayDS,
      pollInterval: Duration.zero, // Instant poll for tests
    );
    easebuzzRepo = EasebuzzPaymentsRepositoryImpl(
      remoteDataSource: mockEasebuzzDS,
      pollInterval: Duration.zero, // Instant poll for tests
    );
  });

  group('JuspayPaymentsRepositoryImpl', () {
    const successModel = PaymentStatusModel(status: 'SUCCESS', respMessage: 'Paid');
    const pendingModel = PaymentStatusModel(status: 'PENDING', respMessage: 'Pending');

    test('fetchStatus calls remote datasource', () async {
      when(() => mockJuspayDS.fetchStatus(any()))
          .thenAnswer((_) async => successModel);

      final result = await juspayRepo.fetchStatus('ref_123');

      expect(result, successModel);
      verify(() => mockJuspayDS.fetchStatus('ref_123')).called(1);
    });

    test('verifyPaymentResponse calls verifyJuspayResponse on remote datasource', () async {
      when(() => mockJuspayDS.verifyJuspayResponse(any()))
          .thenAnswer((_) async {});

      await juspayRepo.verifyPaymentResponse('order_123');

      verify(() => mockJuspayDS.verifyJuspayResponse('order_123')).called(1);
    });

    test('pollStatus exits early on SUCCESS', () async {
      when(() => mockJuspayDS.fetchStatus(any()))
          .thenAnswer((_) async => successModel);

      final result = await juspayRepo.pollStatus('ref_123');

      expect(result.status, 'SUCCESS');
      verify(() => mockJuspayDS.fetchStatus('ref_123')).called(1);
    });

    test('pollStatus polls up to max attempts on PENDING', () async {
      var callCount = 0;
      when(() => mockJuspayDS.fetchStatus(any())).thenAnswer((_) async {
        callCount++;
        return pendingModel;
      });

      final result = await juspayRepo.pollStatus('ref_123');

      expect(result.status, 'PENDING');
      expect(callCount, 15);
      verify(() => mockJuspayDS.fetchStatus('ref_123')).called(15);
    });
  });

  group('EasebuzzPaymentsRepositoryImpl', () {
    const successModel = PaymentStatusModel(status: 'SUCCESS', respMessage: 'Paid');

    test('fetchStatus calls remote datasource', () async {
      when(() => mockEasebuzzDS.fetchStatus(any()))
          .thenAnswer((_) async => successModel);

      final result = await easebuzzRepo.fetchStatus('ref_123');

      expect(result, successModel);
      verify(() => mockEasebuzzDS.fetchStatus('ref_123')).called(1);
    });

    test('verifyPaymentResponse is a no-op', () async {
      await easebuzzRepo.verifyPaymentResponse('order_123');
      // No failure, verify verifyJuspayResponse is not called anywhere
      verifyNever(() => mockJuspayDS.verifyJuspayResponse(any()));
    });
  });
}
