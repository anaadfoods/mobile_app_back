import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart' as dio;
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/models/user_model.dart';
import 'package:grocery_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:grocery_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:grocery_app/features/auth/domain/repositories/auth_repository.dart' as domain;
import 'package:grocery_app/features/auth/domain/entities/user.dart';
import 'package:grocery_app/features/auth/domain/failures/auth_failure.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockApiClient extends Mock implements ApiClient {}
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockDomainAuthRepository extends Mock implements domain.AuthRepository {}

void main() {
  late TokenService tokenService;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockApiClient mockApiClient;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockDomainAuthRepository mockDomainAuthRepository;

  final testUserJson = {
    'email': 'test@example.com',
    'username': 'testuser',
    'first_name': 'Test',
    'last_name': 'User',
    'phone_number': '1234567890',
    'gender': 'Male',
  };

  final domainUser = User(
    email: 'test@example.com',
    username: 'testuser',
    firstName: 'Test',
    lastName: 'User',
    phoneNumber: '1234567890',
    gender: 'Male',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage = MockFlutterSecureStorage();
    mockApiClient = MockApiClient();
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockDomainAuthRepository = MockDomainAuthRepository();

    // Reset GetIt locator
    await getIt.reset();

    // Register mocks in GetIt
    getIt.registerLazySingleton<ApiClient>(() => mockApiClient);
    getIt.registerLazySingleton<AuthRemoteDataSource>(() => mockRemoteDataSource);
    getIt.registerLazySingleton<domain.AuthRepository>(() => mockDomainAuthRepository);
    
    // Create TokenService with mock storage and register in GetIt
    final localDataSource = AuthLocalDataSourceImpl(secureStorage: mockSecureStorage);
    tokenService = TokenService.create(localDataSource: localDataSource);
    getIt.registerLazySingleton<TokenService>(() => tokenService);
  });

  group('TokenService', () {
    group('Token CRUD Operations', () {
      test('saveToken writes access token, refresh token and user data to storage', () async {
        // Arrange
        when(() => mockSecureStorage.write(key: 'access_token', value: 'access_val'))
            .thenAnswer((_) async {});
        when(() => mockSecureStorage.write(key: 'refresh_token', value: 'refresh_val'))
            .thenAnswer((_) async {});

        // Act
        await tokenService.saveToken('access_val', 'refresh_val', testUserJson);

        // Assert
        verify(() => mockSecureStorage.write(key: 'access_token', value: 'access_val')).called(1);
        verify(() => mockSecureStorage.write(key: 'refresh_token', value: 'refresh_val')).called(1);
        
        final prefs = await SharedPreferences.getInstance();
        final savedData = jsonDecode(prefs.getString('user_data')!);
        expect(savedData['email'], 'test@example.com');
        expect(savedData['username'], 'testuser');
        expect(tokenService.currentUser?.email, 'test@example.com');
      });

      test('getAccessToken reads from secure storage', () async {
        when(() => mockSecureStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'some_access_token');

        final token = await tokenService.getAccessToken();

        expect(token, 'some_access_token');
        verify(() => mockSecureStorage.read(key: 'access_token')).called(1);
      });

      test('getRefreshToken reads from secure storage', () async {
        when(() => mockSecureStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => 'some_refresh_token');

        final token = await tokenService.getRefreshToken();

        expect(token, 'some_refresh_token');
        verify(() => mockSecureStorage.read(key: 'refresh_token')).called(1);
      });

      test('clearToken deletes tokens and user data', () async {
        when(() => mockSecureStorage.delete(key: 'access_token'))
            .thenAnswer((_) async {});
        when(() => mockSecureStorage.delete(key: 'refresh_token'))
            .thenAnswer((_) async {});

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(testUserJson));

        await tokenService.clearToken();

        verify(() => mockSecureStorage.delete(key: 'access_token')).called(1);
        verify(() => mockSecureStorage.delete(key: 'refresh_token')).called(1);
        expect(prefs.containsKey('user_data'), false);
        expect(tokenService.currentUser, null);
      });
    });

    group('isLoggedIn', () {
      test('returns true and populates user data when access token exists', () async {
        when(() => mockSecureStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'token');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(testUserJson));

        final loggedIn = await tokenService.isLoggedIn();

        expect(loggedIn, true);
        expect(tokenService.currentUser?.email, 'test@example.com');
      });

      test('returns false when no access token exists', () async {
        when(() => mockSecureStorage.read(key: 'access_token'))
            .thenAnswer((_) async => null);

        final loggedIn = await tokenService.isLoggedIn();

        expect(loggedIn, false);
      });
    });

    group('Auth API Operations', () {
      test('loginUser calls Repository, returns success: true and parses user', () async {
        when(() => mockDomainAuthRepository.login(any(), any()))
            .thenAnswer((_) async => domainUser);

        final result = await tokenService.loginUser('test@example.com', 'pass');

        expect(result['success'], true);
        expect(result['data']['email'], 'test@example.com');
        verify(() => mockDomainAuthRepository.login('test@example.com', 'pass')).called(1);
      });

      test('loginUser returns success: false on invalid credentials', () async {
        when(() => mockDomainAuthRepository.login(any(), any()))
            .thenThrow(const AuthFailure(type: AuthFailureType.invalidCredentials, message: 'Invalid credentials'));

        final result = await tokenService.loginUser('test@example.com', 'wrong');

        expect(result['success'], false);
        expect(result['message'].contains('Invalid credentials'), true);
      });

      test('verifyAndRefreshToken returns true when test token endpoint succeeds', () async {
        when(() => mockSecureStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'token');

        when(() => mockRemoteDataSource.verifyToken())
            .thenAnswer((_) async => true);

        final result = await tokenService.verifyAndRefreshToken();

        expect(result, true);
        verify(() => mockRemoteDataSource.verifyToken()).called(1);
      });
    });
  });
}
