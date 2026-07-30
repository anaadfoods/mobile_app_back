import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grocery_app/features/payments/data/datasources/easebuzz_remote_data_source.dart';
import 'package:grocery_app/features/payments/data/datasources/juspay_remote_data_source.dart';
import 'package:grocery_app/features/payments/data/repositories/easebuzz_payments_repository_impl.dart';
import 'package:grocery_app/features/payments/data/repositories/juspay_payments_repository_impl.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:mocktail/mocktail.dart';

class MockJuspayRemoteDataSource extends Mock implements JuspayRemoteDataSource {}
class MockEasebuzzRemoteDataSource extends Mock implements EasebuzzRemoteDataSource {}

void main() {
  final getIt = GetIt.instance;

  setUpAll(() {
    // Register mock dependencies needed by createPaymentsRepository
    getIt.registerLazySingleton<JuspayRemoteDataSource>(() => MockJuspayRemoteDataSource());
    getIt.registerLazySingleton<EasebuzzRemoteDataSource>(() => MockEasebuzzRemoteDataSource());
  });

  tearDownAll(() async {
    await getIt.reset();
  });

  group('DI Gateway Factory Resolver Tests', () {
    test('resolves to JuspayPaymentsRepositoryImpl when flag is juspay', () {
      final repo = createPaymentsRepository('juspay');
      expect(repo, isA<JuspayPaymentsRepositoryImpl>());
    });

    test('resolves to EasebuzzPaymentsRepositoryImpl when flag is easebuzz', () {
      final repo = createPaymentsRepository('easebuzz');
      expect(repo, isA<EasebuzzPaymentsRepositoryImpl>());
    });

    test('resolves to EasebuzzPaymentsRepositoryImpl by default for unknown flags', () {
      final repo = createPaymentsRepository('unknown_gateway');
      expect(repo, isA<EasebuzzPaymentsRepositoryImpl>());
    });
  });
}
