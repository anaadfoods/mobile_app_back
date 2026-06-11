import 'package:grocery_app/utils/app_logger.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/models/user_model.dart';
import 'package:grocery_app/repositories/auth_repository.dart';
import 'package:grocery_app/cubits/auth/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial());

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.checkAuthStatus();
      if (user != null) {
        emit(Authenticated(user));
        verifyAndRefreshToken();
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> verifyAndRefreshToken() async {
    try {
      if (state is Authenticated) {
        final isValid = await _authRepository.verifyAndRefreshToken();
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
      final user = await _authRepository.login(email, password);
      emit(Authenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('An unexpected error occurred. Please try again.'));
    }
  }

  Future<void> register(UserModel user) async {
    emit(AuthLoading());
    try {
      await _authRepository.register(user);
      emit(AuthRegistrationSuccess());
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('An unexpected error occurred. Please try again.'));
    }
  }

  Future<void> googleLogin() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.googleLogin();
      emit(Authenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      AppLogger.instance.log('DEBUG: googleLogin error: $e');
      emit(AuthError(e.toString().contains('canceled') 
        ? 'Google Sign-In was canceled.' 
        : 'An unexpected error occurred. Please try again.'));
    }
  }

  Future<void> appleLogin() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.appleLogin();
      emit(Authenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('An unexpected error occurred. Please try again.'));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
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
      UserModel finalUpdatedUser = updatedData;

      if (imageFile != null) {
        final userAfterImageUpload = await _authRepository.uploadProfileImage(
          imageFile,
        );
        finalUpdatedUser = finalUpdatedUser.copyWith(
          profilePicture: userAfterImageUpload.profilePicture,
        );
      }

      final fullyUpdatedUser = await _authRepository.updateProfile(
        finalUpdatedUser,
      );

      emit(
        AuthProfileUpdateSuccess(
          fullyUpdatedUser,
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

  /// Updates the user's address and emits [AuthAddressUpdated] on success.
  /// This allows screens listening to auth state to react to address changes.
  Future<bool> updateUserAddress(Map<String, String> addressDetails) async {
    UserModel? currentUser;
    if (state is Authenticated) {
      currentUser = (state as Authenticated).user;
    }

    try {
      final success = await _authRepository.updateAddress(addressDetails);
      if (success) {
        // After updateAddress, TokenService._currentUser is already updated
        // Get the fresh user data from checkAuthStatus to ensure we have latest
        final updatedUser = await _authRepository.checkAuthStatus();
        if (updatedUser != null) {
          emit(
            AuthAddressUpdated(updatedUser, 'Address updated successfully!'),
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
    // Capture user reference before emitting AuthLoading
    UserModel? currentUser;
    if (state is Authenticated) {
      currentUser = (state as Authenticated).user;
    }

    emit(AuthLoading());
    try {
      await _authRepository.deactivateAccount(password);
      emit(
        const AuthDeactivationOtpSent(
          'OTP has been sent to your email and phone.',
        ),
      );
      return {'success': true, 'message': 'OTP sent successfully.'};
    } on AuthException catch (e) {
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
    // Capture user reference before emitting AuthLoading
    UserModel? currentUser;
    if (state is Authenticated) {
      currentUser = (state as Authenticated).user;
    }

    emit(AuthLoading());
    try {
      await _authRepository.confirmDeactivateAccount(otp);
      emit(Unauthenticated());
      return {
        'success': true,
        'message': 'Your account has been deactivated successfully.',
      };
    } on AuthException catch (e) {
      if (currentUser != null) {
        // Emit back to authenticated state but keep the OTP sent state context if needed?
        // Actually, the UI usually handles the state transition.
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
