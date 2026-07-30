import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({required String accessToken, required String refreshToken});
  Future<void> saveUserData(UserModel user);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<UserModel?> getUserData();
  Future<void> clearAll();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;

  AuthLocalDataSourceImpl({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  @override
  Future<void> saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toProfileJson()));
    await prefs.setString('user_profile', jsonEncode(user.toProfileJson()));
  }

  @override
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  @override
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  @override
  Future<UserModel?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }
    return null;
  }

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await prefs.remove('user_data');
    await prefs.remove('user_profile');
  }
}
