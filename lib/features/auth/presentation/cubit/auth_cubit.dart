import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/models/user_model.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_state.dart';
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
import 'package:grocery_app/utils/app_logger.dart';

class AuthCubit extends Cubit<AuthState> {
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GoogleLoginUseCase _googleLoginUseCase;
  final AppleLoginUseCase _appleLoginUseCase;
  final LogoutUseCase _logoutUseCase;
  final VerifyTokenUseCase _verifyTokenUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final UpdateAddressUseCase _updateAddressUseCase;
  final DeactivateAccountUseCase _deactivateAccountUseCase;
  final ConfirmDeactivationUseCase _confirmDeactivationUseCase;

  AuthCubit({
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required GoogleLoginUseCase googleLoginUseCase,
    required AppleLoginUseCase appleLoginUseCase,
    required LogoutUseCase logoutUseCase,
    required VerifyTokenUseCase verifyTokenUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required UpdateAddressUseCase updateAddressUseCase,
    required DeactivateAccountUseCase deactivateAccountUseCase,
    required ConfirmDeactivationUseCase confirmDeactivationUseCase,
  })  : _checkAuthStatusUseCase = checkAuthStatusUseCase,
        _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _googleLoginUseCase = googleLoginUseCase,
        _appleLoginUseCase = appleLoginUseCase,
        _logoutUseCase = logoutUseCase,
        _verifyTokenUseCase = verifyTokenUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _updateAddressUseCase = updateAddressUseCase,
        _deactivateAccountUseCase = deactivateAccountUseCase,
        _confirmDeactivationUseCase = confirmDeactivationUseCase,
        super(AuthInitial());

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final userEntity = await _checkAuthStatusUseCase();
      if (userEntity != null) {
        emit(Authenticated(UserModel.fromDomain(userEntity)));
        verifyAndRefreshToken();
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> refreshUserSilently() async {
    if (state is! Authenticated) return;
    try {
      final userEntity = await _checkAuthStatusUseCase();
      if (userEntity != null) {
        emit(Authenticated(UserModel.fromDomain(userEntity)));
      }
    } catch (_) {
      // Keep current authenticated state on failure
    }
  }

  void applyUserUpdate(UserModel user) {
    if (state is Authenticated) {
      emit(Authenticated(user));
    }
  }

  Future<void> verifyAndRefreshToken() async {
    try {
      if (state is Authenticated) {
        final isValid = await _verifyTokenUseCase();
        if (!isValid) {
          emit(Unauthenticated());
        }
      }
    } catch (_) {
      // Keep authenticated on random errors
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final userEntity = await _loginUseCase(email, password);
      emit(Authenticated(UserModel.fromDomain(userEntity)));
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('An unexpected error occurred. Please try again.'));
    }
  }

  Future<void> register(UserModel user) async {
    emit(AuthLoading());
    try {
      await _registerUseCase(user.toDomain());
      emit(AuthRegistrationSuccess());
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('An unexpected error occurred. Please try again.'));
    }
  }

  Future<void> googleLogin() async {
    emit(AuthLoading());
    try {
      final userEntity = await _googleLoginUseCase();
      emit(Authenticated(UserModel.fromDomain(userEntity)));
    } on AuthFailure catch (e) {
      if (e.type == AuthFailureType.cancelled) {
        emit(Unauthenticated());
      } else {
        emit(AuthError(e.message));
      }
    } catch (e) {
      AppLogger.instance.log('DEBUG: googleLogin error: $e');
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('canceled') || errorString.contains('cancelled') || errorString.contains('sign in canceled')) {
        emit(Unauthenticated());
      } else {
        emit(const AuthError('An unexpected error occurred. Please try again.'));
      }
    }
  }

  Future<void> appleLogin() async {
    emit(AuthLoading());
    try {
      final userEntity = await _appleLoginUseCase();
      emit(Authenticated(UserModel.fromDomain(userEntity)));
    } on AuthFailure catch (e) {
      if (e.type == AuthFailureType.cancelled) {
        emit(Unauthenticated());
      } else {
        emit(AuthError(e.message));
      }
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('canceled') || errorString.contains('cancelled') || errorString.contains('sign in canceled')) {
        emit(Unauthenticated());
      } else {
        emit(const AuthError('An unexpected error occurred. Please try again.'));
      }
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await _logoutUseCase();
      emit(Unauthenticated());
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> updateUserProfile({
    required UserModel updatedData,
    File? imageFile,
  }) async {
    UserModel? currentUser;
    if (state is Authenticated) {
      currentUser = (state as Authenticated).user;
    }

    emit(AuthLoading());
    try {
      final updatedUserEntity = await _updateProfileUseCase(
        user: updatedData.toDomain(),
        imagePath: imageFile?.path,
      );

      emit(
        AuthProfileUpdateSuccess(
          UserModel.fromDomain(updatedUserEntity),
          'Profile updated successfully!',
        ),
      );
    } on Exception catch (e) {
      emit(AuthError(e.toString()));
      if (currentUser != null) {
        emit(Authenticated(currentUser));
      } else {
        emit(Unauthenticated());
      }
    }
  }

  Future<bool> updateUserAddress(Map<String, String> addressDetails) async {
    UserModel? currentUser;
    if (state is Authenticated) {
      currentUser = (state as Authenticated).user;
    }

    try {
      final success = await _updateAddressUseCase(addressDetails);
      if (success) {
        final userEntity = await _checkAuthStatusUseCase();
        if (userEntity != null) {
          emit(
            AuthAddressUpdated(
              UserModel.fromDomain(userEntity),
              'Address updated successfully!',
            ),
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      AppLogger.instance.log('AuthCubit.updateUserAddress error: $e');
      if (currentUser != null) {
        emit(Authenticated(currentUser));
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> deactivateAccount(String password) async {
    UserModel? currentUser;
    if (state is Authenticated) {
      currentUser = (state as Authenticated).user;
    }

    emit(AuthLoading());
    try {
      await _deactivateAccountUseCase(password);
      emit(
        const AuthDeactivationOtpSent(
          'OTP has been sent to your email and phone.',
        ),
      );
      return {'success': true, 'message': 'OTP sent successfully.'};
    } on AuthFailure catch (e) {
      if (currentUser != null) {
        emit(Authenticated(currentUser));
      } else {
        emit(Unauthenticated());
      }
      return {'success': false, 'message': e.message};
    } catch (e) {
      if (currentUser != null) {
        emit(Authenticated(currentUser));
      } else {
        emit(Unauthenticated());
      }
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }

  Future<Map<String, dynamic>> confirmDeactivation(String otp) async {
    UserModel? currentUser;
    if (state is Authenticated) {
      currentUser = (state as Authenticated).user;
    }

    emit(AuthLoading());
    try {
      await _confirmDeactivationUseCase(otp);
      emit(Unauthenticated());
      return {
        'success': true,
        'message': 'Your account has been deactivated successfully.',
      };
    } on AuthFailure catch (e) {
      if (currentUser != null) {
        emit(Authenticated(currentUser));
      } else {
        emit(Unauthenticated());
      }
      return {'success': false, 'message': e.message};
    } catch (e) {
      if (currentUser != null) {
        emit(Authenticated(currentUser));
      } else {
        emit(Unauthenticated());
      }
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }
}
