import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/payments/domain/entities/payment_status.dart';
import 'package:grocery_app/features/payments/domain/repositories/payments_repository.dart';
import 'package:grocery_app/features/payments/domain/usecases/get_payment_status_use_case.dart';
import 'package:grocery_app/features/payments/domain/usecases/poll_payment_status_use_case.dart';
import 'package:grocery_app/features/payments/domain/usecases/verify_payment_response_use_case.dart';

class MockPaymentsRepository extends Mock implements PaymentsRepository {}

void main() {
  late MockPaymentsRepository mockRepository;
  late GetPaymentStatusUseCase getPaymentStatusUseCase;
  late PollPaymentStatusUseCase pollPaymentStatusUseCase;
  late VerifyPaymentResponseUseCase verifyPaymentResponseUseCase;

  setUp(() {
    mockRepository = MockPaymentsRepository();
    getPaymentStatusUseCase = GetPaymentStatusUseCase(mockRepository);
    pollPaymentStatusUseCase = PollPaymentStatusUseCase(mockRepository);
    verifyPaymentResponseUseCase = VerifyPaymentResponseUseCase(mockRepository);
  });

  group('Payments Domain Use Cases', () {
    const testStatus = PaymentStatus(status: 'SUCCESS', respMessage: 'Paid');

    test('GetPaymentStatusUseCase calls fetchStatus on repository', () async {
      when(() => mockRepository.fetchStatus(any()))
          .thenAnswer((_) async => testStatus);

      final result = await getPaymentStatusUseCase('ref_123');

      expect(result, testStatus);
      verify(() => mockRepository.fetchStatus('ref_123')).called(1);
    });

    test('PollPaymentStatusUseCase calls pollStatus on repository', () async {
      when(() => mockRepository.pollStatus(any()))
          .thenAnswer((_) async => testStatus);

      final result = await pollPaymentStatusUseCase('ref_123');

      expect(result, testStatus);
      verify(() => mockRepository.pollStatus('ref_123')).called(1);
    });

    test('VerifyPaymentResponseUseCase calls verifyPaymentResponse on repository', () async {
      when(() => mockRepository.verifyPaymentResponse(any()))
          .thenAnswer((_) async {});

      await verifyPaymentResponseUseCase('order_123');

      verify(() => mockRepository.verifyPaymentResponse('order_123')).called(1);
    });
  });
}
