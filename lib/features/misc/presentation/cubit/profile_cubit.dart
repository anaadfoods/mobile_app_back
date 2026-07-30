import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/features/misc/domain/usecases/update_user_profile_use_case.dart';
import 'package:grocery_app/features/misc/domain/usecases/upload_profile_image_use_case.dart';
import 'package:grocery_app/features/misc/presentation/cubit/profile_state.dart';
import 'package:grocery_app/models/user_model.dart';

/// Consumers: AuthCubit
/// This Cubit handles profile updates and syncs with AuthCubit.
class ProfileCubit extends Cubit<ProfileState> {
  final UpdateUserProfileUseCase _updateUserProfileUseCase;
  final UploadProfileImageUseCase _uploadProfileImageUseCase;

  ProfileCubit({
    required UpdateUserProfileUseCase updateUserProfileUseCase,
    required UploadProfileImageUseCase uploadProfileImageUseCase,
  })  : _updateUserProfileUseCase = updateUserProfileUseCase,
        _uploadProfileImageUseCase = uploadProfileImageUseCase,
        super(const ProfileInitial());

  Future<Map<String, dynamic>> updateProfile(UserModel user) async {
    emit(const ProfileLoading());
    try {
      final result = await _updateUserProfileUseCase(user);
      if (result['success'] == true) {
        emit(ProfileSuccess(result['message'] ?? 'Profile updated', data: result['data']));
      } else {
        emit(ProfileError(result['message'] ?? 'Failed to update profile'));
      }
      return result;
    } catch (e) {
      final err = {'success': false, 'message': e.toString()};
      emit(ProfileError(e.toString()));
      return err;
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    emit(const ProfileLoading());
    try {
      final result = await _uploadProfileImageUseCase(imageFile);
      if (result['success'] == true) {
        emit(ProfileSuccess(result['message'] ?? 'Image uploaded'));
      } else {
        emit(ProfileError(result['message'] ?? 'Failed to upload image'));
      }
      return result;
    } catch (e) {
      final err = {'success': false, 'message': e.toString()};
      emit(ProfileError(e.toString()));
      return err;
    }
  }
}
