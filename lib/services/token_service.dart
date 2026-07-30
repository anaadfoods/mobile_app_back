import 'dart:async';
import 'dart:convert';
import 'package:grocery_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:grocery_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:grocery_app/features/auth/data/models/user_model.dart' as local;
import 'package:grocery_app/features/auth/domain/repositories/auth_repository.dart' as domain;
import 'package:grocery_app/models/user_model.dart';
import 'package:grocery_app/service_locator.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => getIt<TokenService>();
  
  TokenService._internal({AuthLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? getIt<AuthLocalDataSource>();

  static TokenService create({AuthLocalDataSource? localDataSource}) =>
      TokenService._internal(localDataSource: localDataSource);

  final AuthLocalDataSource _localDataSource;

  static final _authStateController = StreamController<bool>.broadcast();
  static Stream<bool> get authStateChanges => _authStateController.stream;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    if (user != null) {
      _authStateController.add(true);
    }
  }

  Future<void> saveToken(
    String accessToken,
    String refreshToken,
    Map<String, dynamic> userData,
  ) async {
    await _localDataSource.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    
    final localUserModel = local.UserModel.fromJson(userData);
    await _localDataSource.saveUserData(localUserModel);

    _currentUser = UserModel.fromJson(userData);
    _authStateController.add(true);
  }

  Future<String?> getAccessToken() async {
    return await _localDataSource.getAccessToken();
  }

  Future<String?> getRefreshToken() async {
    return await _localDataSource.getRefreshToken();
  }

  Future<UserModel?> getUserData() async {
    final localUserModel = await _localDataSource.getUserData();
    if (localUserModel != null) {
      _currentUser = UserModel.fromDomain(localUserModel.toDomain());
    }
    return _currentUser;
  }

  Future<void> clearToken() async {
    await _localDataSource.clearAll();
    _currentUser = null;
    _authStateController.add(false);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token != null) {
      if (_currentUser == null) {
        await getUserData();
      }
      return true;
    }
    return false;
  }

  Future<void> initializeAuthState() async {
    final loggedIn = await isLoggedIn();
    _authStateController.add(loggedIn);
  }

  Future<bool> verifyAndRefreshToken() async {
    try {
      final token = await getAccessToken();
      if (token == null) return false;
      return await getIt<AuthRemoteDataSource>().verifyToken();
    } catch (_) {
      return await getAccessToken() != null;
    }
  }

  Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final tokens = await getIt<AuthRemoteDataSource>().refreshAccessToken(refreshToken);
      if (tokens != null) {
        await _localDataSource.saveTokens(
          accessToken: tokens['access']!, 
          refreshToken: tokens['refresh']!,
        );
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<void> logout() async {
    await clearToken();
  }

  @Deprecated('Use AuthRepository directly')
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final user = await getIt<domain.AuthRepository>().login(email, password);
      return {'success': true, 'data': UserModel.fromDomain(user).toProfileJson()};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  @Deprecated('Use AuthRepository directly')
  Future<Map<String, dynamic>> registerUser(UserModel user) async {
    try {
      await getIt<domain.AuthRepository>().register(user.toDomain());
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
