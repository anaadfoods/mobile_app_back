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
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
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
        final userAfterImageUpload = await _authRepository.uploadProfileImage(imageFile);
        finalUpdatedUser = finalUpdatedUser.copyWith(
          profilePicture: userAfterImageUpload.profilePicture,
        );
      }

      final fullyUpdatedUser = await _authRepository.updateProfile(finalUpdatedUser);

      emit(AuthProfileUpdateSuccess(fullyUpdatedUser, 'Profile updated successfully!'));

    } on Exception catch (e) {
      emit(AuthError(e.toString()));
      if (currentUser != null) {
        emit(Authenticated(currentUser));
      } else {
        emit(Unauthenticated());
      }
    }
  }
}
