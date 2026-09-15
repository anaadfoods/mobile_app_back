import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart' as dio;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:grocery_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:grocery_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:grocery_app/features/auth/data/models/user_model.dart' as auth_model;
import 'package:grocery_app/models/user_model.dart' as shared;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: '');
  });

  group('Auth Fixes Verification', () {
    late MockApiClient mockApiClient;
    late AuthRemoteDataSourceImpl remoteDataSource;

    setUp(() {
      mockApiClient = MockApiClient();
      remoteDataSource = AuthRemoteDataSourceImpl(apiClient: mockApiClient);
    });

    test('verifyToken returns false when server responds with 401 Unauthorized', () async {
      when(() => mockApiClient.get('/api/auth/test-token/')).thenThrow(
        dio.DioException(
          requestOptions: dio.RequestOptions(path: '/api/auth/test-token/'),
          response: dio.Response(
            requestOptions: dio.RequestOptions(path: '/api/auth/test-token/'),
            statusCode: 401,
          ),
        ),
      );

      final result = await remoteDataSource.verifyToken();
      expect(result, isFalse);
    });

    test('verifyToken returns true on network connection error to preserve session', () async {
      when(() => mockApiClient.get('/api/auth/test-token/')).thenThrow(
        dio.DioException(
          requestOptions: dio.RequestOptions(path: '/api/auth/test-token/'),
          type: dio.DioExceptionType.connectionError,
          error: 'SocketException: Connection refused',
        ),
      );

      final result = await remoteDataSource.verifyToken();
      expect(result, isTrue);
    });

    test('AuthRepositoryImpl.login syncs currentUser to TokenService', () async {
      SharedPreferences.setMockInitialValues({});
      final mockSecureStorage = MockFlutterSecureStorage();
      when(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final mockRemoteDataSource = MockAuthRemoteDataSource();
      final localDataSource = AuthLocalDataSourceImpl(secureStorage: mockSecureStorage);

      await getIt.reset();
      final tokenService = TokenService.create(localDataSource: localDataSource);
      getIt.registerLazySingleton<TokenService>(() => tokenService);

      final repository = AuthRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
        localDataSource: localDataSource,
      );

      final testUser = auth_model.UserModel(
        id: 42,
        email: 'user@test.com',
        username: 'usertest',
        password: '',
        confirmPassword: '',
        firstName: 'User',
        lastName: 'Test',
        phoneNumber: '9876543210',
        gender: 'Other',
      );

      when(() => mockRemoteDataSource.login('user@test.com', 'password123')).thenAnswer(
        (_) async => auth_model.AuthResponse(
          accessToken: 'test_access_token',
          refreshToken: 'test_refresh_token',
          user: testUser,
        ),
      );

      final user = await repository.login('user@test.com', 'password123');

      expect(user.email, 'user@test.com');
      expect(tokenService.currentUser, isNotNull);
      expect(tokenService.currentUser?.email, 'user@test.com');
      expect(tokenService.currentUser?.id, 42);
    });
  });
}
