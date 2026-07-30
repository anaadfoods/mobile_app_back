import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/auth/domain/entities/user.dart';
import 'package:grocery_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:grocery_app/features/auth/domain/usecases/check_auth_status_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/register_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/google_login_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/apple_login_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/verify_token_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/update_profile_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/update_address_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/deactivate_account_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/confirm_deactivation_use_case.dart';

class MockDomainAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockDomainAuthRepository mockRepository;
  
  final testUser = User(
    email: 'test@example.com',
    username: 'test',
    firstName: 'First',
    lastName: 'Last',
    phoneNumber: '1234567890',
  );

  setUpAll(() {
    registerFallbackValue(User(
      email: '',
      username: '',
      firstName: '',
      lastName: '',
      phoneNumber: '',
    ));
  });

  setUp(() {
    mockRepository = MockDomainAuthRepository();
  });

  group('Auth Domain Use Cases', () {
    test('CheckAuthStatusUseCase calls checkAuthStatus on repository', () async {
      final useCase = CheckAuthStatusUseCase(mockRepository);
      when(() => mockRepository.checkAuthStatus()).thenAnswer((_) async => testUser);

      final result = await useCase();

      expect(result, testUser);
      verify(() => mockRepository.checkAuthStatus()).called(1);
    });

    test('LoginUseCase calls login on repository', () async {
      final useCase = LoginUseCase(mockRepository);
      when(() => mockRepository.login(any(), any())).thenAnswer((_) async => testUser);

      final result = await useCase('email', 'pass');

      expect(result, testUser);
      verify(() => mockRepository.login('email', 'pass')).called(1);
    });

    test('RegisterUseCase calls register on repository', () async {
      final useCase = RegisterUseCase(mockRepository);
      when(() => mockRepository.register(any())).thenAnswer((_) async {});

      await useCase(testUser);

      verify(() => mockRepository.register(testUser)).called(1);
    });

    test('GoogleLoginUseCase calls googleLogin on repository', () async {
      final useCase = GoogleLoginUseCase(mockRepository);
      when(() => mockRepository.googleLogin()).thenAnswer((_) async => testUser);

      final result = await useCase();

      expect(result, testUser);
      verify(() => mockRepository.googleLogin()).called(1);
    });

    test('AppleLoginUseCase calls appleLogin on repository', () async {
      final useCase = AppleLoginUseCase(mockRepository);
      when(() => mockRepository.appleLogin()).thenAnswer((_) async => testUser);

      final result = await useCase();

      expect(result, testUser);
      verify(() => mockRepository.appleLogin()).called(1);
    });

    test('LogoutUseCase calls logout on repository', () async {
      final useCase = LogoutUseCase(mockRepository);
      when(() => mockRepository.logout()).thenAnswer((_) async {});

      await useCase();

      verify(() => mockRepository.logout()).called(1);
    });

    test('VerifyTokenUseCase calls verifyAndRefreshToken on repository', () async {
      final useCase = VerifyTokenUseCase(mockRepository);
      when(() => mockRepository.verifyAndRefreshToken()).thenAnswer((_) async => true);

      final result = await useCase();

      expect(result, true);
      verify(() => mockRepository.verifyAndRefreshToken()).called(1);
    });

    test('UpdateProfileUseCase calls uploadProfileImage and updateProfile when imagePath is provided', () async {
      final useCase = UpdateProfileUseCase(mockRepository);
      final uploadedUser = testUser.copyWith(profilePicture: 'image_url');
      final updatedUser = uploadedUser.copyWith(firstName: 'Updated');

      when(() => mockRepository.uploadProfileImage(any())).thenAnswer((_) async => uploadedUser);
      when(() => mockRepository.updateProfile(any())).thenAnswer((_) async => updatedUser);

      final result = await useCase(user: testUser, imagePath: 'local_path');

      expect(result, updatedUser);
      verify(() => mockRepository.uploadProfileImage('local_path')).called(1);
      verify(() => mockRepository.updateProfile(testUser.copyWith(profilePicture: 'image_url'))).called(1);
    });

    test('UpdateAddressUseCase calls updateAddress on repository', () async {
      final useCase = UpdateAddressUseCase(mockRepository);
      final addressData = {'address': 'address'};
      when(() => mockRepository.updateAddress(any())).thenAnswer((_) async => true);

      final result = await useCase(addressData);

      expect(result, true);
      verify(() => mockRepository.updateAddress(addressData)).called(1);
    });

    test('DeactivateAccountUseCase calls deactivateAccount on repository', () async {
      final useCase = DeactivateAccountUseCase(mockRepository);
      when(() => mockRepository.deactivateAccount(any())).thenAnswer((_) async {});

      await useCase('password');

      verify(() => mockRepository.deactivateAccount('password')).called(1);
    });

    test('ConfirmDeactivationUseCase calls confirmDeactivateAccount on repository', () async {
      final useCase = ConfirmDeactivationUseCase(mockRepository);
      when(() => mockRepository.confirmDeactivateAccount(any())).thenAnswer((_) async {});

      await useCase('otp');

      verify(() => mockRepository.confirmDeactivateAccount('otp')).called(1);
    });
  });
}
