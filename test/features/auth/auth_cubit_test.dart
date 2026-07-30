import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:grocery_app/features/auth/domain/repositories/auth_repository.dart' as domain;
import 'package:grocery_app/features/auth/domain/entities/user.dart';
import 'package:grocery_app/features/auth/domain/failures/auth_failure.dart';
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
import 'package:grocery_app/models/user_model.dart';

class MockAuthRepository extends Mock implements domain.AuthRepository {}
class MockFile extends Mock implements File {}

void main() {
  late AuthCubit authCubit;
  late MockAuthRepository mockAuthRepository;

  final testUserEntity = User(
    email: 'test@example.com',
    username: 'testuser',
    firstName: 'Test',
    lastName: 'User',
    phoneNumber: '1234567890',
    gender: 'Male',
  );

  final testUserModel = UserModel.fromDomain(testUserEntity);

  setUpAll(() {
    registerFallbackValue(User(
      email: '',
      username: '',
      firstName: '',
      lastName: '',
      phoneNumber: '',
    ));
    registerFallbackValue(File(''));
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authCubit = AuthCubit(
      checkAuthStatusUseCase: CheckAuthStatusUseCase(mockAuthRepository),
      loginUseCase: LoginUseCase(mockAuthRepository),
      registerUseCase: RegisterUseCase(mockAuthRepository),
      googleLoginUseCase: GoogleLoginUseCase(mockAuthRepository),
      appleLoginUseCase: AppleLoginUseCase(mockAuthRepository),
      logoutUseCase: LogoutUseCase(mockAuthRepository),
      verifyTokenUseCase: VerifyTokenUseCase(mockAuthRepository),
      updateProfileUseCase: UpdateProfileUseCase(mockAuthRepository),
      updateAddressUseCase: UpdateAddressUseCase(mockAuthRepository),
      deactivateAccountUseCase: DeactivateAccountUseCase(mockAuthRepository),
      confirmDeactivationUseCase: ConfirmDeactivationUseCase(mockAuthRepository),
    );
  });

  tearDown(() {
    authCubit.close();
  });

  group('AuthCubit', () {
    test('initial state is AuthInitial', () {
      expect(authCubit.state, AuthInitial());
    });

    group('checkAuthStatus', () {
      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, Authenticated] and calls verifyAndRefreshToken when logged in',
        build: () {
          when(() => mockAuthRepository.checkAuthStatus())
              .thenAnswer((_) async => testUserEntity);
          when(() => mockAuthRepository.verifyAndRefreshToken())
              .thenAnswer((_) async => true);
          return authCubit;
        },
        act: (cubit) => cubit.checkAuthStatus(),
        expect: () => [
          AuthLoading(),
          isA<Authenticated>().having((a) => a.user.email, 'email', testUserModel.email),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.checkAuthStatus()).called(1);
          verify(() => mockAuthRepository.verifyAndRefreshToken()).called(1);
        },
      );

      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, Unauthenticated] when not logged in',
        build: () {
          when(() => mockAuthRepository.checkAuthStatus())
              .thenAnswer((_) async => null);
          return authCubit;
        },
        act: (cubit) => cubit.checkAuthStatus(),
        expect: () => [
          AuthLoading(),
          Unauthenticated(),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, Unauthenticated] when checkAuthStatus throws',
        build: () {
          when(() => mockAuthRepository.checkAuthStatus())
              .thenThrow(Exception('Failure'));
          return authCubit;
        },
        act: (cubit) => cubit.checkAuthStatus(),
        expect: () => [
          AuthLoading(),
          Unauthenticated(),
        ],
      );
    });

    group('login', () {
      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, Authenticated] on success',
        build: () {
          when(() => mockAuthRepository.login(any(), any()))
              .thenAnswer((_) async => testUserEntity);
          return authCubit;
        },
        act: (cubit) => cubit.login('test@example.com', 'password123'),
        expect: () => [
          AuthLoading(),
          isA<Authenticated>().having((a) => a.user.email, 'email', testUserModel.email),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, AuthError] with error message on AuthFailure',
        build: () {
          when(() => mockAuthRepository.login(any(), any()))
              .thenThrow(const AuthFailure(type: AuthFailureType.invalidCredentials, message: 'Invalid credentials'));
          return authCubit;
        },
        act: (cubit) => cubit.login('test@example.com', 'wrong'),
        expect: () => [
          AuthLoading(),
          const AuthError('Invalid credentials'),
        ],
      );
    });

    group('register', () {
      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, AuthRegistrationSuccess] on success',
        build: () {
          when(() => mockAuthRepository.register(any()))
              .thenAnswer((_) async {});
          return authCubit;
        },
        act: (cubit) => cubit.register(testUserModel),
        expect: () => [
          AuthLoading(),
          AuthRegistrationSuccess(),
        ],
      );
    });

    group('googleLogin', () {
      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, Authenticated] on success',
        build: () {
          when(() => mockAuthRepository.googleLogin())
              .thenAnswer((_) async => testUserEntity);
          return authCubit;
        },
        act: (cubit) => cubit.googleLogin(),
        expect: () => [
          AuthLoading(),
          isA<Authenticated>().having((a) => a.user.email, 'email', testUserModel.email),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, Unauthenticated] when user cancels Google Sign-In',
        build: () {
          when(() => mockAuthRepository.googleLogin())
              .thenThrow(const AuthFailure(type: AuthFailureType.cancelled, message: 'canceled'));
          return authCubit;
        },
        act: (cubit) => cubit.googleLogin(),
        expect: () => [
          AuthLoading(),
          Unauthenticated(),
        ],
      );
    });

    group('appleLogin', () {
      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, Authenticated] on success',
        build: () {
          when(() => mockAuthRepository.appleLogin())
              .thenAnswer((_) async => testUserEntity);
          return authCubit;
        },
        act: (cubit) => cubit.appleLogin(),
        expect: () => [
          AuthLoading(),
          isA<Authenticated>().having((a) => a.user.email, 'email', testUserModel.email),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, Unauthenticated] when user cancels Apple Sign-In',
        build: () {
          when(() => mockAuthRepository.appleLogin())
              .thenThrow(const AuthFailure(type: AuthFailureType.cancelled, message: 'canceled'));
          return authCubit;
        },
        act: (cubit) => cubit.appleLogin(),
        expect: () => [
          AuthLoading(),
          Unauthenticated(),
        ],
      );
    });

    group('logout', () {
      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, Unauthenticated] on success',
        build: () {
          when(() => mockAuthRepository.logout())
              .thenAnswer((_) async {});
          return authCubit;
        },
        act: (cubit) => cubit.logout(),
        expect: () => [
          AuthLoading(),
          Unauthenticated(),
        ],
      );
    });

    group('updateUserProfile', () {
      final updatedUserEntity = testUserEntity.copyWith(firstName: 'Updated');
      final updatedUserModel = UserModel.fromDomain(updatedUserEntity);

      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, AuthProfileUpdateSuccess] when profile is updated successfully without file',
        build: () {
          when(() => mockAuthRepository.updateProfile(any()))
              .thenAnswer((_) async => updatedUserEntity);
          return authCubit;
        },
        act: (cubit) => cubit.updateUserProfile(updatedData: updatedUserModel),
        expect: () => [
          AuthLoading(),
          isA<AuthProfileUpdateSuccess>().having((a) => a.user.firstName, 'firstName', 'Updated'),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, AuthError, Authenticated] on update failure when previously authenticated',
        seed: () => Authenticated(testUserModel),
        build: () {
          when(() => mockAuthRepository.updateProfile(any()))
              .thenThrow(Exception('Profile update failed'));
          return authCubit;
        },
        act: (cubit) => cubit.updateUserProfile(updatedData: updatedUserModel),
        expect: () => [
          AuthLoading(),
          const AuthError('Exception: Profile update failed'),
          isA<Authenticated>().having((a) => a.user.email, 'email', testUserModel.email),
        ],
      );
    });

    group('updateUserAddress', () {
      final updatedUserEntity = testUserEntity.copyWith(address: 'New Address');
      final updatedUserModel = UserModel.fromDomain(updatedUserEntity);

      blocTest<AuthCubit, AuthState>(
        'emits [AuthAddressUpdated] on success and checkAuthStatus returns fresh user',
        seed: () => Authenticated(testUserModel),
        build: () {
          when(() => mockAuthRepository.updateAddress(any()))
              .thenAnswer((_) async => true);
          when(() => mockAuthRepository.checkAuthStatus())
              .thenAnswer((_) async => updatedUserEntity);
          return authCubit;
        },
        act: (cubit) => cubit.updateUserAddress({'address': 'New Address'}),
        expect: () => [
          isA<AuthAddressUpdated>().having((a) => a.user.address, 'address', 'New Address'),
        ],
      );
    });

    group('deactivateAccount', () {
      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, AuthDeactivationOtpSent] on success',
        seed: () => Authenticated(testUserModel),
        build: () {
          when(() => mockAuthRepository.deactivateAccount(any()))
              .thenAnswer((_) async {});
          return authCubit;
        },
        act: (cubit) => cubit.deactivateAccount('password123'),
        expect: () => [
          AuthLoading(),
          const AuthDeactivationOtpSent('OTP has been sent to your email and phone.'),
        ],
      );
    });
  });
}
