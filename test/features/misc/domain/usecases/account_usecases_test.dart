import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/misc/domain/entities/user_summary_entity.dart';
import 'package:grocery_app/features/misc/domain/repositories/account_repository.dart';
import 'package:grocery_app/features/misc/domain/usecases/fetch_user_summary_use_case.dart';
import 'package:grocery_app/features/misc/domain/usecases/sync_user_profile_use_case.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  late MockAccountRepository mockRepository;
  late FetchUserSummaryUseCase fetchUserSummaryUseCase;
  late SyncUserProfileUseCase syncUserProfileUseCase;

  setUp(() {
    mockRepository = MockAccountRepository();
    fetchUserSummaryUseCase = FetchUserSummaryUseCase(mockRepository);
    syncUserProfileUseCase = SyncUserProfileUseCase(mockRepository);
  });

  group('Account UseCases', () {
    const tUserSummary = UserSummaryEntity(
      totalOrders: 5,
      totalSpent: 250.0,
      activePlans: 2,
      totalSubscriptions: 2,
      cancelledOrders: 0,
      totalProducts: 10,
    );

    test('FetchUserSummaryUseCase returns UserSummaryEntity from repository', () async {
      when(() => mockRepository.getUserSummary())
          .thenAnswer((_) async => tUserSummary);

      final result = await fetchUserSummaryUseCase();

      expect(result, equals(tUserSummary));
      verify(() => mockRepository.getUserSummary()).called(1);
    });

    test('SyncUserProfileUseCase returns profile map from repository', () async {
      final tProfile = {'first_name': 'Test', 'email': 'test@example.com'};
      when(() => mockRepository.syncUserProfile())
          .thenAnswer((_) async => tProfile);

      final result = await syncUserProfileUseCase();

      expect(result, equals(tProfile));
      verify(() => mockRepository.syncUserProfile()).called(1);
    });
  });
}
