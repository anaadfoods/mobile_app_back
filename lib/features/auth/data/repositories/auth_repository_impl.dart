import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart' as dio;
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/failures/auth_failure.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Stream<bool> get authStateChanges => _authStateController.stream;

  @override
  Future<User> login(String email, String password) async {
    try {
      final response = await _remoteDataSource.login(email, password);
      await _localDataSource.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      await _localDataSource.saveUserData(response.user);
      _authStateController.add(true);
      return response.user.toDomain();
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> register(User user) async {
    try {
      final userModel = UserModel.fromDomain(user);
      await _remoteDataSource.register(userModel);
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<User> googleLogin() async {
    try {
      final response = await _remoteDataSource.googleLogin();
      await _localDataSource.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      await _localDataSource.saveUserData(response.user);
      _authStateController.add(true);
      return response.user.toDomain();
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<User> appleLogin() async {
    try {
      final response = await _remoteDataSource.appleLogin();
      await _localDataSource.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      await _localDataSource.saveUserData(response.user);
      _authStateController.add(true);
      return response.user.toDomain();
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _localDataSource.clearAll();
      _authStateController.add(false);
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<User?> checkAuthStatus() async {
    try {
      final accessToken = await _localDataSource.getAccessToken();
      if (accessToken == null) return null;
      final userModel = await _localDataSource.getUserData();
      return userModel?.toDomain();
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<bool> verifyAndRefreshToken() async {
    try {
      final verified = await _remoteDataSource.verifyToken();
      if (verified) return true;

      final refreshToken = await _localDataSource.getRefreshToken();
      if (refreshToken == null) return false;

      final tokens = await _remoteDataSource.refreshAccessToken(refreshToken);
      if (tokens != null) {
        await _localDataSource.saveTokens(
          accessToken: tokens['access']!,
          refreshToken: tokens['refresh']!,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<User> updateProfile(User user) async {
    try {
      final model = UserModel.fromDomain(user);
      final updatedModel = await _remoteDataSource.updateProfile(model);
      await _localDataSource.saveUserData(updatedModel);
      return updatedModel.toDomain();
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<bool> updateAddress(Map<String, String> addressDetails) async {
    try {
      final currentUser = await _localDataSource.getUserData();
      if (currentUser == null) return false;
      final success = await _remoteDataSource.updateAddress(currentUser, addressDetails);
      return success;
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<User> uploadProfileImage(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      await _remoteDataSource.uploadProfileImage(imageFile);
      final updatedModel = await _remoteDataSource.getUserProfile();
      await _localDataSource.saveUserData(updatedModel);
      return updatedModel.toDomain();
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> sendOtp(String identifier, String type) async {
    try {
      await _remoteDataSource.sendOtp(identifier, type);
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> verifyOtp(String identifier, String otp, String type) async {
    try {
      await _remoteDataSource.verifyOtp(identifier, otp, type);
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> deactivateAccount(String password) async {
    try {
      await _remoteDataSource.deactivateAccount(password);
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> confirmDeactivateAccount(String otp) async {
    try {
      await _remoteDataSource.confirmDeactivateAccount(otp);
      await _localDataSource.clearAll();
      _authStateController.add(false);
    } catch (e) {
      throw _mapException(e);
    }
  }

  AuthFailure _mapException(dynamic error) {
    if (error is dio.DioException) {
      final type = _mapDioErrorType(error);
      final message = _extractDioMessage(error);
      return AuthFailure(type: type, message: message);
    } else if (error is PlatformException) {
      final code = error.code.toLowerCase();
      if (code.contains('cancel') || code.contains('canceled') || code.contains('cancelled')) {
        return const AuthFailure(type: AuthFailureType.cancelled, message: 'Cancelled by user');
      }
      return AuthFailure(type: AuthFailureType.unknown, message: error.message ?? 'Platform error');
    } else if (error is AuthFailure) {
      return error;
    }
    final errorMsg = error.toString();
    if (errorMsg.contains('cancel') || errorMsg.contains('canceled') || errorMsg.contains('cancelled')) {
      return const AuthFailure(type: AuthFailureType.cancelled, message: 'Cancelled by user');
    }
    return AuthFailure(type: AuthFailureType.unknown, message: errorMsg);
  }

  AuthFailureType _mapDioErrorType(dio.DioException e) {
    if (e.type == dio.DioExceptionType.connectionTimeout ||
        e.type == dio.DioExceptionType.receiveTimeout ||
        e.type == dio.DioExceptionType.sendTimeout ||
        e.type == dio.DioExceptionType.connectionError) {
      return AuthFailureType.networkError;
    }
    final response = e.response;
    if (response != null) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        return AuthFailureType.unauthorized;
      }
      if (response.statusCode == 400) {
        return AuthFailureType.invalidCredentials;
      }
      if (response.statusCode != null && response.statusCode! >= 500) {
        return AuthFailureType.serverError;
      }
    }
    return AuthFailureType.unknown;
  }

  String _extractDioMessage(dio.DioException e) {
    final response = e.response;
    if (response != null && response.data != null) {
      final data = response.data;
      if (data is Map) {
        if (data['detail'] != null) return data['detail'].toString();
        if (data['message'] != null) return data['message'].toString();
        if (data['error'] != null) return data['error'].toString();
        
        final errors = <String>[];
        data.forEach((key, value) {
          if (value is List) {
            errors.add('$key: ${value.join(", ")}');
          } else {
            errors.add('$key: $value');
          }
        });
        if (errors.isNotEmpty) return errors.join('; ');
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    }
    return e.message ?? 'Network error occurred';
  }
}
